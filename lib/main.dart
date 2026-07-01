import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'config/theme/malate_theme.dart';
import 'config/app_config.dart';
import 'core/di/service_locator.dart';
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

  await initServiceLocator();

  final connectivity = sl<ConnectivityMonitor>();
  final syncEngine = SyncEngine(connectivity: connectivity);
  if (connectivity.isOnline) {
    syncEngine.syncAll();
  }

  runApp(const ArangkadaApp());
}

class ArangkadaApp extends StatelessWidget {
  const ArangkadaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: sl<ConnectivityMonitor>()),
        ChangeNotifierProvider.value(value: sl<BatterySaver>()),
        ChangeNotifierProvider.value(value: sl<ThemeProvider>()),
        ChangeNotifierProvider.value(value: sl<TileCacheManager>()),
        ChangeNotifierProvider.value(value: sl<ModelDownloadManager>()),
        ChangeNotifierProvider.value(value: sl<LlmService>()),
        Provider.value(value: sl<GeminiService>()),
        ChangeNotifierProvider.value(value: sl<WeatherService>()),
        ChangeNotifierProvider.value(value: sl<NavigationProvider>()),
        ChangeNotifierProvider.value(value: sl<CrashDetector>()),
        ChangeNotifierProvider.value(value: sl<SpeedMonitor>()),
        ChangeNotifierProvider.value(value: sl<FatigueMonitor>()),
        ChangeNotifierProvider.value(value: sl<NightModeProvider>()),
        ChangeNotifierProvider.value(value: sl<RouteHazardMonitor>()),
        ChangeNotifierProvider(create: (_) => RideLogger()..init()),
        ChangeNotifierProxyProvider2<RideLogger, ConnectivityMonitor,
            AiAssistant>(
          create: (_) => AiAssistant(),
          update: (_, rideLogger, connectivity, ai) {
            ai!.updateDependencies(
              rideLogger: rideLogger,
              connectivity: connectivity,
            );
            ai.setLlmService(sl<LlmService>());
            ai.setGeminiService(sl<GeminiService>());
            return ai;
          },
        ),
        ChangeNotifierProxyProvider3<NavigationProvider, RideLogger,
            AiAssistant, VoiceCommandService>(
          create: (_) => sl<VoiceCommandService>(),
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
