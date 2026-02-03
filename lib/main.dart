import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_core/firebase_core.dart';

import 'firebase_options.dart';
import 'utils/theme.dart';
import 'providers/theme_provider.dart';
import 'screens/auth/login_screen.dart';
import 'screens/onboarding/onboarding_screen.dart';
import 'screens/main_screen.dart';
import 'services/auth_service.dart';

/// Whether Firebase was successfully initialized.
bool firebaseInitialized = false;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
    ),
  );

  // Initialize Firebase
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    firebaseInitialized = true;
  } catch (e) {
    debugPrint('Firebase initialization failed: $e');
    firebaseInitialized = false;
  }

  // Load saved preferences
  final prefs = await SharedPreferences.getInstance();
  final onboardingComplete = prefs.getBool('onboarding_complete') ?? false;
  final savedThemeMode = await ThemeModeNotifier.loadSavedThemeMode();

  runApp(
    ProviderScope(
      child: FiyatRadarApp(
        showOnboarding: !onboardingComplete,
        initialThemeMode: savedThemeMode,
      ),
    ),
  );
}

class FiyatRadarApp extends ConsumerStatefulWidget {
  final bool showOnboarding;
  final ThemeMode initialThemeMode;

  const FiyatRadarApp({
    super.key,
    required this.showOnboarding,
    required this.initialThemeMode,
  });

  @override
  ConsumerState<FiyatRadarApp> createState() => _FiyatRadarAppState();
}

class _FiyatRadarAppState extends ConsumerState<FiyatRadarApp> {
  @override
  void initState() {
    super.initState();
    // Set initial theme mode from saved preferences
    Future.microtask(() {
      ref.read(themeModeProvider.notifier).setThemeMode(widget.initialThemeMode);
    });
  }

  @override
  Widget build(BuildContext context) {
    final themeMode = ref.watch(themeModeProvider);

    return MaterialApp(
      title: 'FiyatRadar',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: themeMode,
      home: widget.showOnboarding
          ? OnboardingScreen(
              onComplete: () async {
                final prefs = await SharedPreferences.getInstance();
                await prefs.setBool('onboarding_complete', true);
              },
            )
          : _buildHomeScreen(),
    );
  }

  Widget _buildHomeScreen() {
    // If Firebase is initialized, check auth state
    if (firebaseInitialized) {
      final authService = AuthService();
      if (authService.currentUser != null) {
        return const MainScreen();
      }
    }
    return const LoginScreen();
  }
}
