import 'package:get_it/get_it.dart';
import '../../domain/repositories/i_hazard_repository.dart';
import '../../domain/repositories/i_ride_log_repository.dart';
import '../../domain/repositories/i_rider_settings_repository.dart';
import '../../domain/repositories/i_route_repository.dart';
import '../../domain/repositories/i_search_repository.dart';
import '../../domain/repositories/i_weather_repository.dart';
import '../../infrastructure/repositories/sqlite_hazard_repository.dart';
import '../../infrastructure/repositories/sqlite_ride_log_repository.dart';
import '../../infrastructure/repositories/sqlite_rider_settings_repository.dart';
import '../../infrastructure/repositories/sqlite_route_repository.dart';
import '../../infrastructure/repositories/sqlite_search_repository.dart';
import '../../infrastructure/repositories/sqlite_weather_repository.dart';
import '../../core/offline/connectivity_monitor.dart';
import '../../core/offline/tile_cache_manager.dart';
import '../../core/battery/battery_saver.dart';
import '../../services/ai/gemini_service.dart';
import '../../services/ai/llm_service.dart';
import '../../services/ai/model_download_manager.dart';
import '../../services/crash_detector.dart';
import '../../services/fatigue_monitor.dart';
import '../../services/navigation_provider.dart';
import '../../services/night_mode_provider.dart';
import '../../services/route_hazard_monitor.dart';
import '../../services/speed_monitor.dart';
import '../../services/theme_provider.dart';
import '../../services/voice_command_service.dart';
import '../../services/weather_service.dart';

final sl = GetIt.instance;

Future<void> initServiceLocator() async {
  // ── Repositories (abstractions) ──
  sl.registerLazySingleton<IRiderSettingsRepository>(
      () => SqliteRiderSettingsRepository());
  sl.registerLazySingleton<IHazardRepository>(
      () => SqliteHazardRepository());
  sl.registerLazySingleton<IRideLogRepository>(
      () => SqliteRideLogRepository());
  sl.registerLazySingleton<IRouteRepository>(
      () => SqliteRouteRepository());
  sl.registerLazySingleton<IWeatherRepository>(
      () => SqliteWeatherRepository());
  sl.registerLazySingleton<ISearchRepository>(
      () => SqliteSearchRepository());

  // ── Core Infrastructure ──
  await TileCacheManager.initBackend();

  final themeProvider = ThemeProvider();
  await themeProvider.init();
  sl.registerSingleton<ThemeProvider>(themeProvider);

  final connectivity = ConnectivityMonitor();
  await connectivity.init();
  sl.registerSingleton<ConnectivityMonitor>(connectivity);

  final tileCache = TileCacheManager();
  await tileCache.init();
  sl.registerSingleton<TileCacheManager>(tileCache);

  // ── AI Services ──
  final downloadManager = ModelDownloadManager();
  downloadManager.updateConnectivity(connectivity);
  await downloadManager.init();
  sl.registerSingleton<ModelDownloadManager>(downloadManager);

  final llmService = LlmService(downloadManager: downloadManager);
  sl.registerSingleton<LlmService>(llmService);

  final geminiService = GeminiService(connectivity: connectivity);
  sl.registerSingleton<GeminiService>(geminiService);

  // ── Voice ──
  final voiceCommand = VoiceCommandService();
  await voiceCommand.init();
  sl.registerSingleton<VoiceCommandService>(voiceCommand);

  // ── Weather ──
  final weatherService = WeatherService();
  weatherService.updateConnectivity(connectivity);
  sl.registerSingleton<WeatherService>(weatherService);

  // ── Navigation & Safety ──
  final battery = BatterySaver()..start();
  sl.registerSingleton<BatterySaver>(battery);

  final navProvider = NavigationProvider();
  sl.registerSingleton<NavigationProvider>(navProvider);

  final crashDetector = CrashDetector()..start();
  sl.registerSingleton<CrashDetector>(crashDetector);

  final speedMonitor = SpeedMonitor(navProvider.navEngine);
  sl.registerSingleton<SpeedMonitor>(speedMonitor);

  final fatigueMonitor = FatigueMonitor(navProvider);
  sl.registerSingleton<FatigueMonitor>(fatigueMonitor);

  final nightMode = NightModeProvider();
  sl.registerSingleton<NightModeProvider>(nightMode);

  final hazardMonitor = RouteHazardMonitor(navProvider);
  sl.registerSingleton<RouteHazardMonitor>(hazardMonitor);

  // ── Wire cross-cutting safety deps ──
  voiceCommand.setSafetyDependencies(
    speedMonitor: speedMonitor,
    fatigueMonitor: fatigueMonitor,
    crashDetector: crashDetector,
    nightMode: nightMode,
  );
}
