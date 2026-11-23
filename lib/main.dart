import 'package:flutter/material.dart';
import 'persistence/shared_preferences_persistence_store.dart';
import 'constants/app_info.dart';
import 'theme/app_theme.dart';
import 'screens/auth/splash_onboarding_screen.dart';
import 'state/app_state.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  AppState.configurePersistenceStore(SharedPreferencesPersistenceStore());
  await AppState().initialize();
  runApp(const DolpApp());
}

class DolpApp extends StatelessWidget {
  const DolpApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: appName,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      home: const SplashOnboardingScreen(),
    );
  }
}
