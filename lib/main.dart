import 'dart:async';

import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'l10n/app_strings.dart';
import 'screens/login_screen.dart';
import 'screens/main_screen.dart';
import 'screens/onboarding_screen.dart';
import 'services/ads_service.dart';
import 'services/messaging_service.dart';
import 'services/premium_service.dart';
import 'state/app_state.dart';
import 'ui/fr_theme.dart';
import 'ui/tokens.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  Object? bootError;
  try {
    await Firebase.initializeApp();
    await FRThemeController.instance.load();
    // Crashlytics: debug build'lerde göndermiyoruz (kullanıcı self-test
    // yaparken false-pozitif yığmasın). Release/profile build'lerde
    // otomatik açık. FlutterError.onError ile uncaught Flutter hatalarını,
    // PlatformDispatcher.onError ile native zone error'larını yakalıyoruz.
    final crashlytics = FirebaseCrashlytics.instance;
    await crashlytics.setCrashlyticsCollectionEnabled(!kDebugMode);
    FlutterError.onError = crashlytics.recordFlutterFatalError;
    PlatformDispatcher.instance.onError = (error, stack) {
      crashlytics.recordError(error, stack, fatal: true);
      return true;
    };
    // Analytics: ekran/aksiyon log'u gerektiğinde
    // FirebaseAnalytics.instance.log... ile çağırıyoruz; default config
    // yeterli olduğu için burada extra setup yok.
    FirebaseAnalytics.instance.setAnalyticsCollectionEnabled(!kDebugMode);
  } catch (e, st) {
    // Surface to logs but keep the app alive — `_AuthGate` will render the
    // error screen so the user gets actionable feedback instead of a white
    // crash on hot reload / network blips.
    debugPrint('FiyatRadar boot failed: $e\n$st');
    bootError = e;
  }
  runApp(FiyatRadarApp(bootError: bootError));
}

class FiyatRadarApp extends StatefulWidget {
  const FiyatRadarApp({super.key, this.bootError});
  final Object? bootError;

  @override
  State<FiyatRadarApp> createState() => _FiyatRadarAppState();
}

class _FiyatRadarAppState extends State<FiyatRadarApp> {
  final AppState _state = AppState();
  late final Future<_Init> _initFuture = _boot();

  Future<_Init> _boot() async {
    if (widget.bootError != null) {
      throw widget.bootError!;
    }
    await _state.init();
    // FCM + IAP wiring is best-effort — bir başlatma hatası splash'ı
    // bloklamasın. PremiumService Play Billing yoksa silently no-op olur.
    unawaited(MessagingService.instance.init());
    unawaited(PremiumService.instance.init());
    unawaited(AdsService.instance.init());
    final prefs = await SharedPreferences.getInstance();
    return _Init(showOnboarding: !(prefs.getBool('onboarding_done') ?? false));
  }

  @override
  void dispose() {
    _state.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AppStateScope(
      state: _state,
      child: AnimatedBuilder(
        // Hem tema değişikliği hem dil değişikliği MaterialApp'i
        // rebuild etmeli — Listenable.merge'le iki source'u tek
        // AnimatedBuilder altında birleştiriyoruz.
        animation: Listenable.merge([FRThemeController.instance, _state]),
        builder: (context, _) {
          return MaterialApp(
            title: 'FiyatRadar',
            debugShowCheckedModeBanner: false,
            theme: buildFRTheme(palette: FRPalette.light),
            darkTheme: buildFRTheme(palette: FRPalette.dark),
            themeMode: FRThemeController.instance.isDark
                ? ThemeMode.dark
                : ThemeMode.light,
            locale: _state.locale,
            supportedLocales: AppStrings.supportedLocales,
            localizationsDelegates: const [
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            builder: (context, child) {
              return AppStringsScope(
                strings: AppStrings(_state.locale),
                child: child ?? const SizedBox.shrink(),
              );
            },
            home: _AuthGate(
              state: _state,
              initFuture: _initFuture,
            ),
          );
        },
      ),
    );
  }
}

/// Reactive auth gate: subscribes directly to [FirebaseAuth.authStateChanges]
/// AND to [AppState] (for the guest-acknowledged flag). Either signal causes
/// the gate to re-evaluate which screen to render, so a successful email
/// sign-in immediately swaps the [LoginScreen] for the [MainScreen] without
/// requiring an app restart.
class _AuthGate extends StatelessWidget {
  const _AuthGate({required this.state, required this.initFuture});
  final AppState state;
  final Future<_Init> initFuture;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<_Init>(
      future: initFuture,
      builder: (context, snap) {
        if (snap.connectionState != ConnectionState.done) {
          return const _SplashScreen();
        }
        if (snap.hasError) {
          return _ErrorScreen(error: '${snap.error}');
        }
        if (snap.data!.showOnboarding) return const OnboardingScreen();
        return StreamBuilder<User?>(
          stream: FirebaseAuth.instance.authStateChanges(),
          initialData: FirebaseAuth.instance.currentUser,
          builder: (_, authSnap) {
            return AnimatedBuilder(
              animation: state,
              builder: (_, __) {
                final user = authSnap.data ?? state.user;
                final tree = _routeFor(user, state);
                return AnimatedSwitcher(
                  duration: const Duration(milliseconds: 320),
                  switchInCurve: Curves.easeOutCubic,
                  switchOutCurve: Curves.easeInCubic,
                  transitionBuilder: (child, animation) => FadeTransition(
                    opacity: animation,
                    child: SlideTransition(
                      position: Tween<Offset>(
                        begin: const Offset(0, 0.04),
                        end: Offset.zero,
                      ).animate(animation),
                      child: child,
                    ),
                  ),
                  child: KeyedSubtree(
                    key: ValueKey(_routeKey(user, state)),
                    child: tree,
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  Widget _routeFor(User? user, AppState state) {
    if (user == null) return const LoginScreen();
    if (user.isAnonymous && !state.guestAcknowledged) {
      return const LoginScreen();
    }
    if (state.isBanned) {
      return _BannedScreen(reason: state.banReason);
    }
    return const MainScreen();
  }

  String _routeKey(User? user, AppState state) {
    if (user == null) return 'login';
    if (user.isAnonymous && !state.guestAcknowledged) return 'login';
    if (state.isBanned) return 'banned:${user.uid}';
    return 'main:${user.uid}';
  }
}

class _Init {
  final bool showOnboarding;
  const _Init({required this.showOnboarding});
}

class _SplashScreen extends StatelessWidget {
  const _SplashScreen();

  @override
  Widget build(BuildContext context) {
    // Keep Flutter boot visually continuous with the native launch
    // background: warm cream field, restrained premium wordmark.
    final bg = FRPalette.light.bg;
    return Scaffold(
      backgroundColor: bg,
      body: Center(
        child: Image.asset(
          'assets/images/fiyatradar_logo.png',
          width: 286,
          height: 244,
          fit: BoxFit.contain,
          filterQuality: FilterQuality.medium,
        ),
      ),
    );
  }
}

class _ErrorScreen extends StatelessWidget {
  const _ErrorScreen({required this.error});
  final String error;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: FR.bg,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.wifi_off_rounded, color: FR.bad, size: 46),
              const SizedBox(height: 14),
              Text('Bağlantı hatası', style: frDisplay(20, FontWeight.w700)),
              const SizedBox(height: 6),
              Text(
                error,
                textAlign: TextAlign.center,
                style: frText(12, FontWeight.w500, color: FR.ink3),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BannedScreen extends StatelessWidget {
  const _BannedScreen({this.reason});
  final String? reason;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: FR.bg,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 440),
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: FR.surface,
                borderRadius: FRRad.all(FRRad.xl),
                border: Border.all(color: FR.bad.withOpacity(.45)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.block_rounded, color: FR.bad, size: 44),
                  const SizedBox(height: 12),
                  Text('Hesabın askıya alındı', style: frDisplay(22, FontWeight.w700)),
                  const SizedBox(height: 8),
                  Text(
                    reason?.trim().isNotEmpty == true
                        ? reason!
                        : 'Destek ekibiyle iletişime geçerek detay alabilirsin.',
                    textAlign: TextAlign.center,
                    style: frText(12.5, FontWeight.w600, color: FR.ink3, height: 1.5),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
