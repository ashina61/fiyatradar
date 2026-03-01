import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app_router.dart';
import 'firebase_options.dart';
import 'l10n/app_localizations.dart';
import 'providers/app_start_provider.dart';
import 'providers/firebase_init_provider.dart';
import 'providers/theme_provider.dart';
import 'screens/auth/login_screen.dart';
import 'screens/main_screen.dart';
import 'services/notification_service.dart';
import 'utils/theme.dart';

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  if (kDebugMode) {
    debugPrint('Handling a background message: ${message.messageId}');
  }
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  FlutterError.onError = (FlutterErrorDetails details) {
    final exception = details.exceptionAsString();
    if (exception.contains('Unable to load asset')) {
      if (kDebugMode) debugPrint('Asset yükleme hatası yakalandı: $exception');
    }
    FlutterError.presentError(details);
  };

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
    final app = await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    firebaseInitializedNotifier.value = true;
    if (kDebugMode) debugPrint('Firebase başarıyla başlatıldı! app=${app.name}');
  } catch (e) {
    if (kDebugMode) debugPrint('Firebase initializeApp(options) başarısız: $e');
    try {
      final fallbackApp = await Firebase.initializeApp();
      firebaseInitializedNotifier.value = true;
      if (kDebugMode) {
        debugPrint('Firebase varsayılan konfigürasyon ile başlatıldı: ${fallbackApp.name}');
      }
    } catch (inner) {
      if (kDebugMode) debugPrint('Firebase başlatılamadı, hata: $inner');
      firebaseInitializedNotifier.value = false;
    }
  }

  FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
  await NotificationService.initializeLocalNotifications();
  await NotificationService.requestNotificationPermissions();

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
  late final _router = buildAppRouter(showOnboarding: widget.showOnboarding);
  final NotificationService _notificationService = NotificationService();

  @override
  void initState() {
    super.initState();
    // Set initial theme mode from saved preferences
    Future.microtask(() {
      ref.read(themeModeProvider.notifier).setThemeMode(widget.initialThemeMode);
    });

    Future.microtask(() async {
      final token = await _notificationService.getFCMToken();
      if (token == null || token.isEmpty) {
        final cachedToken = await _notificationService.getCachedFCMToken();
        if (kDebugMode) {
          debugPrint('Cached FCM Token: $cachedToken');
        }
      }
      await _notificationService.setupForegroundNotifications();
      _notificationService.setupNotificationOpenedApp();
    });
  }

  @override
  Widget build(BuildContext context) {
    final themeMode = ref.watch(themeModeProvider);

    return MaterialApp.router(
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
      routerConfig: _router,
    );
  }
}

class AppStartGate extends ConsumerWidget {
  const AppStartGate({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final appStartState = ref.watch(appStartStateProvider);
    switch (appStartState) {
      case AppStartState.loading:
        return const Scaffold(
          body: Center(child: CircularProgressIndicator()),
        );
      case AppStartState.authenticated:
        return const MainScreen();
      case AppStartState.login:
        return const LoginScreen();
    }
  }
}
