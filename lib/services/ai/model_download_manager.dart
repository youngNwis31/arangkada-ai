import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import '../../core/offline/connectivity_monitor.dart';
import '../../config/app_config.dart';
import 'package:http/http.dart' as http;

enum DownloadState { idle, downloading, paused, verifying, done, error }

class ModelDownloadManager extends ChangeNotifier {
  DownloadState _state = DownloadState.idle;
  double _progress = 0;
  int _downloadedBytes = 0;
  int _totalBytes = 0;
  String? _errorMessage;
  String? _modelPath;
  ConnectivityMonitor? _connectivity;
  bool _cancelRequested = false;

  DownloadState get state => _state;
  double get progress => _progress;
  int get downloadedBytes => _downloadedBytes;
  int get totalBytes => _totalBytes;
  String? get errorMessage => _errorMessage;
  String? get modelPath => _modelPath;
  bool get isModelDownloaded => _modelPath != null && File(_modelPath!).existsSync();

  String get downloadedSizeMB => (_downloadedBytes / 1024 / 1024).toStringAsFixed(0);
  String get totalSizeMB => (_totalBytes / 1024 / 1024).toStringAsFixed(0);

  void updateConnectivity(ConnectivityMonitor connectivity) {
    _connectivity = connectivity;
  }

  Future<void> init() async {
    final dir = await _modelDir();
    final file = File(p.join(dir.path, AppConfig.gemmaModelFilename));
    if (file.existsSync()) {
      _modelPath = file.path;
      _state = DownloadState.done;
      _progress = 1.0;
      notifyListeners();
    }
  }

  Future<void> startDownload() async {
    if (_state == DownloadState.downloading) return;

    if (_connectivity != null && !_connectivity!.isOnline) {
      _errorMessage = 'No internet connection. Connect to WiFi to download.';
      _state = DownloadState.error;
      notifyListeners();
      return;
    }

    _cancelRequested = false;
    _state = DownloadState.downloading;
    _errorMessage = null;
    notifyListeners();

    try {
      final dir = await _modelDir();
      final filePath = p.join(dir.path, AppConfig.gemmaModelFilename);
      final tempPath = '$filePath.tmp';
      final tempFile = File(tempPath);

      // Check for partial download (resume support)
      int startByte = 0;
      if (tempFile.existsSync()) {
        startByte = tempFile.lengthSync();
        _downloadedBytes = startByte;
      }

      final client = http.Client();
      final request = http.Request('GET', Uri.parse(AppConfig.gemmaModelUrl));
      if (startByte > 0) {
        request.headers['Range'] = 'bytes=$startByte-';
      }

      final response = await client.send(request);

      if (response.statusCode != 200 && response.statusCode != 206) {
        throw Exception('Download failed: HTTP ${response.statusCode}');
      }

      _totalBytes = (response.contentLength ?? 0) + startByte;
      if (_totalBytes == 0) {
        _totalBytes = AppConfig.gemmaModelSizeBytes;
      }

      final sink = tempFile.openWrite(mode: startByte > 0 ? FileMode.append : FileMode.write);

      await for (final chunk in response.stream) {
        if (_cancelRequested) {
          await sink.close();
          client.close();
          _state = DownloadState.idle;
          notifyListeners();
          return;
        }

        if (_connectivity != null && _connectivity!.isOffline) {
          await sink.close();
          client.close();
          _state = DownloadState.paused;
          _errorMessage = 'Download paused — waiting for connection';
          notifyListeners();
          return;
        }

        sink.add(chunk);
        _downloadedBytes += chunk.length;
        _progress = _totalBytes > 0 ? _downloadedBytes / _totalBytes : 0;
        notifyListeners();
      }

      await sink.close();
      client.close();

      // Move temp to final
      await tempFile.rename(filePath);
      _modelPath = filePath;
      _state = DownloadState.done;
      _progress = 1.0;
      notifyListeners();
    } catch (e) {
      _state = DownloadState.error;
      _errorMessage = 'Download failed: ${e.toString().split('\n').first}';
      notifyListeners();
    }
  }

  void cancelDownload() {
    _cancelRequested = true;
  }

  Future<void> deleteModel() async {
    if (_modelPath != null) {
      final file = File(_modelPath!);
      if (file.existsSync()) await file.delete();

      // Also delete temp file
      final tempFile = File('$_modelPath.tmp');
      if (tempFile.existsSync()) await tempFile.delete();
    }
    _modelPath = null;
    _state = DownloadState.idle;
    _progress = 0;
    _downloadedBytes = 0;
    _totalBytes = 0;
    _errorMessage = null;
    notifyListeners();
  }

  Future<int> get modelFileSizeBytes async {
    if (_modelPath == null) return 0;
    final file = File(_modelPath!);
    return file.existsSync() ? file.lengthSync() : 0;
  }

  Future<Directory> _modelDir() async {
    final appDir = Directory('/tmp/arangkada_models');
    if (!appDir.existsSync()) {
      appDir.createSync(recursive: true);
    }
    return appDir;
  }
}
