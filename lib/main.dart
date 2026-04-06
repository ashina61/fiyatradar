import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app_router.dart';
import 'providers/app_start_provider.dart';
import 'providers/firebase_init_provider.dart';
import 'providers/notification_provider.dart';
import 'theme/fr_colors.dart';
import 'theme/fr_ink.dart';
import 'screens/auth/login_screen.dart';
import 'screens/main_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('tr_TR', null);

  Object? firebaseInitError;

  try {
    await Firebase.initializeApp();
    await FirebaseAuth.instance.setLanguageCode('tr');
    firebaseInitializedNotifier.value = true;
  } catch (error, stackTrace) {
    firebaseInitializedNotifier.value = false;
    firebaseInitError = error;
    debugPrint('Firebase initialization failed: $error');
    FlutterError.reportError(
      FlutterErrorDetails(
        exception: error,
        stack: stackTrace,
        library: 'main',
        context: ErrorDescription('while initializing Firebase'),
      ),
    );
  }

  final prefs = await SharedPreferences.getInstance();
  final onboardingComplete = prefs.getBool('onboarding_complete') ?? false;

  runApp(
    ProviderScope(
      child: FiyatRadarApp(
        showOnboarding: !onboardingComplete,
        firebaseInitError: firebaseInitError,
      ),
    ),
  );
}

class FiyatRadarApp extends StatefulWidget {
  const FiyatRadarApp({
    super.key,
    required this.showOnboarding,
    this.firebaseInitError,
  });

  final bool showOnboarding;
  final Object? firebaseInitError;

  @override
  State<FiyatRadarApp> createState() => _FiyatRadarAppState();
}

class _FiyatRadarAppState extends State<FiyatRadarApp> {
  late final GoRouter _router =
      buildAppRouter(showOnboarding: widget.showOnboarding);

  @override
  Widget build(BuildContext context) {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: FRColors.camel,
      brightness: Brightness.light,
      primary: FRColors.camel,
      secondary: FRColors.espresso,
      surface: FRColors.surfaceSoft,
      error: FRColors.danger,
    ).copyWith(
      onPrimary: FRColors.white,
      onSecondary: FRColors.white,
      onSurface: FRColors.textPrimary,
      surface: FRColors.surfaceSoft,
    );

    final theme = ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      primaryColor: FRInk.dark,
      scaffoldBackgroundColor: FRInk.paper,
      canvasColor: FRInk.paperSoft,
      cardColor: FRInk.paperSoft,
      fontFamily: 'Outfit',
      dividerColor: FRInk.hairline,
      appBarTheme: const AppBarTheme(
        backgroundColor: FRInk.paper,
        surfaceTintColor: Colors.transparent,
        foregroundColor: FRInk.ink,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: FRInk.paperSoft,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
      ),
      cardTheme: CardTheme(
        color: FRInk.paperSoft,
        surfaceTintColor: Colors.transparent,
        shadowColor: const Color(0x12000000),
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      ),
    );

    if (widget.firebaseInitError != null) {
      return MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'Fiyat Radar',
        theme: theme,
        home: const FirebaseInitErrorScreen(),
      );
    }

    return MaterialApp.router(
      debugShowCheckedModeBanner: false,
      title: 'Fiyat Radar',
      theme: theme,
      routerConfig: _router,
    );
  }
}

class AppStartGate extends ConsumerWidget {
  const AppStartGate({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(notificationBootstrapProvider);
    final appStartState = ref.watch(appStartStateProvider);

    switch (appStartState) {
      case AppStartState.loading:
        return const _ExecutiveSplashScreen();
      case AppStartState.login:
        return const LoginScreen();
      case AppStartState.authenticated:
        return const MainScreen();
    }
  }
}


class _ExecutiveSplashScreen extends StatelessWidget {
  const _ExecutiveSplashScreen();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: FRColors.background,
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [FRColors.backgroundWarm, FRColors.background],
          ),
        ),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 88,
                height: 88,
                decoration: BoxDecoration(
                  color: FRColors.surface,
                  borderRadius: BorderRadius.circular(28),
                  border: Border.all(color: FRColors.camel.withOpacity(0.22)),
                  boxShadow: [
                    BoxShadow(
                      color: FRColors.espresso.withOpacity(0.08),
                      blurRadius: 28,
                      offset: const Offset(0, 12),
                    ),
                  ],
                ),
                child: const Padding(
                  padding: EdgeInsets.all(24),
                  child: CircularProgressIndicator(
                    strokeWidth: 3,
                    valueColor: AlwaysStoppedAnimation<Color>(FRColors.gold),
                  ),
                ),
              ),
              const SizedBox(height: 18),
              const Text(
                'FiyatRadar hazırlanıyor',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: FRColors.espresso,
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                'Veriler yükleniyor, lütfen bekleyin.',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: FRColors.textMuted,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class FirebaseInitErrorScreen extends StatelessWidget {
  const FirebaseInitErrorScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Text(
            'Sunucu bağlantı hatası, lütfen tekrar deneyin.',
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }
}
