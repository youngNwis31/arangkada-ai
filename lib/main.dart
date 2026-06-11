import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'config/theme/malate_theme.dart';
import 'config/theme/malate_colors.dart';
import 'config/app_config.dart';
import 'core/offline/connectivity_monitor.dart';
import 'core/offline/sync_engine.dart';
import 'core/battery/battery_saver.dart';
import 'services/navigation_provider.dart';
import 'services/ai/ai_assistant.dart';
import 'services/ride_logger.dart';
import 'screens/splash_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.light,
    systemNavigationBarColor: MalateColors.midnight,
    systemNavigationBarIconBrightness: Brightness.light,
  ));

  final connectivity = ConnectivityMonitor();
  await connectivity.init();

  final syncEngine = SyncEngine(connectivity: connectivity);
  final battery = BatterySaver()..start();

  // Trigger sync on app launch if online
  if (connectivity.isOnline) {
    syncEngine.syncAll();
  }

  runApp(ArangkadaApp(
    connectivity: connectivity,
    battery: battery,
  ));
}

class ArangkadaApp extends StatelessWidget {
  final ConnectivityMonitor connectivity;
  final BatterySaver battery;

  const ArangkadaApp({
    super.key,
    required this.connectivity,
    required this.battery,
  });

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: connectivity),
        ChangeNotifierProvider.value(value: battery),
        ChangeNotifierProvider(create: (_) => NavigationProvider()),
        ChangeNotifierProvider(create: (_) => AiAssistant()),
        ChangeNotifierProvider(create: (_) => RideLogger()..init()),
      ],
      child: MaterialApp(
        title: AppConfig.appName,
        debugShowCheckedModeBanner: false,
        theme: MalateTheme.darkTheme,
        home: const SplashScreen(),
      ),
    );
  }
}
