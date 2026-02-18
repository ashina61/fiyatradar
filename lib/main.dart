import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_core/firebase_core.dart';

// import 'firebase_options.dart'; // Bu satırı kaldırdık, artık JSON dosyasını okuyacak.

import 'utils/theme.dart';
import 'providers/theme_provider.dart';
import 'providers/auth_provider.dart';
import 'providers/firebase_init_provider.dart';
import 'screens/auth/login_screen.dart';
import 'screens/onboarding/onboarding_screen.dart';
import 'screens/main_screen.dart';
import 'services/auth_service.dart';
import 'l10n/app_localizations.dart';

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
    // DEĞİŞİKLİK BURADA:
    // Parantez içini boş bıraktık. Böylece Android otomatik olarak
    // 'android/app/google-services.json' dosyasındaki ayarları kullanacak.
    await Firebase.initializeApp();
    firebaseInitialized = true;
    debugPrint('Firebase başarıyla başlatıldı! 🚀');
  } catch (e) {
    debugPrint('Firebase başlatılamadı, hata: $e');
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
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [Locale('tr')],
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
    // Firebase başlamadıysa veya kullanıcı yoksa giriş ekranına at
    return const LoginScreen();
  }
}
