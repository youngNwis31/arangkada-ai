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
import 'services/ai/gemini_service.dart';
import 'services/ai/llm_service.dart';
import 'services/ai/model_download_manager.dart';
import 'services/crash_detector.dart';
import 'services/fatigue_monitor.dart';
import 'services/night_mode_provider.dart';
import 'services/route_hazard_monitor.dart';
import 'services/speed_monitor.dart';
import 'services/ride_logger.dart';
import 'services/theme_provider.dart';
import 'services/voice_command_service.dart';
import 'services/weather_service.dart';
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
  final geminiService = GeminiService(connectivity: connectivity);

  final voiceCommand = VoiceCommandService();
  await voiceCommand.init();

  final weatherService = WeatherService();
  weatherService.updateConnectivity(connectivity);

  final syncEngine = SyncEngine(connectivity: connectivity);
  final battery = BatterySaver()..start();
  final navProvider = NavigationProvider();
  final crashDetector = CrashDetector()..start();
  final speedMonitor = SpeedMonitor(navProvider.navEngine);
  final fatigueMonitor = FatigueMonitor(navProvider);
  final nightMode = NightModeProvider();
  final hazardMonitor = RouteHazardMonitor(navProvider);

  voiceCommand.setSafetyDependencies(
    speedMonitor: speedMonitor,
    fatigueMonitor: fatigueMonitor,
    crashDetector: crashDetector,
    nightMode: nightMode,
  );

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
    geminiService: geminiService,
    voiceCommand: voiceCommand,
    weatherService: weatherService,
    navProvider: navProvider,
    crashDetector: crashDetector,
    speedMonitor: speedMonitor,
    fatigueMonitor: fatigueMonitor,
    nightMode: nightMode,
    hazardMonitor: hazardMonitor,
  ));
}

class ArangkadaApp extends StatelessWidget {
  final ConnectivityMonitor connectivity;
  final BatterySaver battery;
  final ThemeProvider themeProvider;
  final TileCacheManager tileCache;
  final ModelDownloadManager downloadManager;
  final LlmService llmService;
  final GeminiService geminiService;
  final VoiceCommandService voiceCommand;
  final WeatherService weatherService;
  final NavigationProvider navProvider;
  final CrashDetector crashDetector;
  final SpeedMonitor speedMonitor;
  final FatigueMonitor fatigueMonitor;
  final NightModeProvider nightMode;
  final RouteHazardMonitor hazardMonitor;

  const ArangkadaApp({
    super.key,
    required this.connectivity,
    required this.battery,
    required this.themeProvider,
    required this.tileCache,
    required this.downloadManager,
    required this.llmService,
    required this.geminiService,
    required this.voiceCommand,
    required this.weatherService,
    required this.navProvider,
    required this.crashDetector,
    required this.speedMonitor,
    required this.fatigueMonitor,
    required this.nightMode,
    required this.hazardMonitor,
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
        Provider.value(value: geminiService),
        ChangeNotifierProvider.value(value: weatherService),
        ChangeNotifierProvider.value(value: navProvider),
        ChangeNotifierProvider.value(value: crashDetector),
        ChangeNotifierProvider.value(value: speedMonitor),
        ChangeNotifierProvider.value(value: fatigueMonitor),
        ChangeNotifierProvider.value(value: nightMode),
        ChangeNotifierProvider.value(value: hazardMonitor),
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
            ai.setGeminiService(geminiService);
            return ai;
          },
        ),
        ChangeNotifierProxyProvider3<NavigationProvider, RideLogger,
            AiAssistant, VoiceCommandService>(
          create: (_) => voiceCommand,
          update: (_, nav, rideLogger, ai, voice) {
            voice!.setDependencies(
              nav: nav,
              rideLogger: rideLogger,
              aiAssistant: ai,
            );
            return voice;
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
