import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'firebase_options.dart';
import 'persistence/firestore_persistence_store.dart';
import 'persistence/persistence_store.dart';
import 'persistence/shared_preferences_persistence_store.dart';
import 'constants/app_info.dart';
import 'theme/app_theme.dart';
import 'screens/auth/splash_onboarding_screen.dart';
import 'state/app_state.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  AppState.configurePersistenceStore(await _createStore());
  await AppState().initialize();
  runApp(const DolpApp());
}

/// Uses Firestore when Firebase is set up for this platform, otherwise the
/// on-device store, so desktop builds without Firebase config still run.
Future<PersistenceStore> _createStore() async {
  final local = SharedPreferencesPersistenceStore();
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    // Firestore rules only admit signed-in clients. dolp's own login is still
    // a mock, so each install signs in anonymously to prove it is the app.
    final auth = FirebaseAuth.instance;
    if (auth.currentUser == null) await auth.signInAnonymously();
    return FirestorePersistenceStore(
      firestore: FirebaseFirestore.instance,
      local: local,
    );
  } catch (error) {
    debugPrint('Firebase unavailable, using local storage: $error');
    return local;
  }
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
