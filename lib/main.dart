import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'config/theme/malate_theme.dart';
import 'config/app_config.dart';
import 'core/offline/connectivity_monitor.dart';
import 'core/offline/sync_engine.dart';
import 'core/offline/tile_cache_manager.dart';
import 'core/battery/battery_saver.dart';
import 'services/navigation_provider.dart';
import 'services/ai/ai_assistant.dart';
import 'services/ai/llm_service.dart';
import 'services/ai/model_download_manager.dart';
import 'services/ride_logger.dart';
import 'services/theme_provider.dart';
import 'screens/splash_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.light,
  ));

  await TileCacheManager.initBackend();

  final themeProvider = ThemeProvider();
  await themeProvider.init();

  final connectivity = ConnectivityMonitor();
  await connectivity.init();

  final tileCache = TileCacheManager();
  await tileCache.init();

  final downloadManager = ModelDownloadManager();
  downloadManager.updateConnectivity(connectivity);
  await downloadManager.init();

  final llmService = LlmService(downloadManager: downloadManager);

  final syncEngine = SyncEngine(connectivity: connectivity);
  final battery = BatterySaver()..start();

  if (connectivity.isOnline) {
    syncEngine.syncAll();
  }

  runApp(ArangkadaApp(
    connectivity: connectivity,
    battery: battery,
    themeProvider: themeProvider,
    tileCache: tileCache,
    downloadManager: downloadManager,
    llmService: llmService,
  ));
}

class ArangkadaApp extends StatelessWidget {
  final ConnectivityMonitor connectivity;
  final BatterySaver battery;
  final ThemeProvider themeProvider;
  final TileCacheManager tileCache;
  final ModelDownloadManager downloadManager;
  final LlmService llmService;

  const ArangkadaApp({
    super.key,
    required this.connectivity,
    required this.battery,
    required this.themeProvider,
    required this.tileCache,
    required this.downloadManager,
    required this.llmService,
  });

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: connectivity),
        ChangeNotifierProvider.value(value: battery),
        ChangeNotifierProvider.value(value: themeProvider),
        ChangeNotifierProvider.value(value: tileCache),
        ChangeNotifierProvider.value(value: downloadManager),
        ChangeNotifierProvider.value(value: llmService),
        ChangeNotifierProvider(create: (_) => NavigationProvider()),
        ChangeNotifierProvider(create: (_) => RideLogger()..init()),
        ChangeNotifierProxyProvider2<RideLogger, ConnectivityMonitor,
            AiAssistant>(
          create: (_) => AiAssistant(),
          update: (_, rideLogger, connectivity, ai) {
            ai!.updateDependencies(
              rideLogger: rideLogger,
              connectivity: connectivity,
            );
            ai.setLlmService(llmService);
            return ai;
          },
        ),
      ],
      child: Consumer<ThemeProvider>(
        builder: (context, theme, _) => MaterialApp(
          title: AppConfig.appName,
          debugShowCheckedModeBanner: false,
          theme: MalateTheme.lightTheme,
          darkTheme: MalateTheme.darkTheme,
          themeMode: theme.themeMode,
          home: const SplashScreen(),
        ),
      ),
    );
  }
}
