import 'package:flutter/material.dart';
import 'constants/app_info.dart';
import 'theme/app_theme.dart';
import 'screens/auth/splash_onboarding_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MoorMarketApp());
}

class MoorMarketApp extends StatelessWidget {
  const MoorMarketApp({super.key});

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
