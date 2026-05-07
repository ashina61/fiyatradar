import 'dart:async';

import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:local_auth/local_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'screens/login_screen.dart';
import 'screens/main_screen.dart';
import 'screens/onboarding_screen.dart';
import 'services/messaging_service.dart';
import 'state/app_state.dart';
import 'ui/components.dart';
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
    // FCM wiring is best-effort — a failure here must not block the splash.
    unawaited(MessagingService.instance.init());
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
        animation: FRThemeController.instance,
        builder: (context, _) {
          return MaterialApp(
            title: 'FiyatRadar',
            debugShowCheckedModeBanner: false,
            theme: buildFRTheme(palette: FRPalette.light),
            darkTheme: buildFRTheme(palette: FRPalette.dark),
            themeMode: FRThemeController.instance.isDark
                ? ThemeMode.dark
                : ThemeMode.light,
            // App is Turkish-only today. Material/Cupertino/Widgets delegates
            // are still required so Material widgets (e.g. TextField, time
            // picker, toolbar tooltips) render localized strings instead of
            // falling back to English.
            locale: const Locale('tr'),
            supportedLocales: const [Locale('tr'), Locale('en')],
            localizationsDelegates: const [
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
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
    if (_securityGateRequired(state) && !state.securitySessionUnlocked) {
      return _SecurityGateScreen(state: state);
    }
    return const MainScreen();
  }

  String _routeKey(User? user, AppState state) {
    if (user == null) return 'login';
    if (user.isAnonymous && !state.guestAcknowledged) return 'login';
    if (state.isBanned) return 'banned:${user.uid}';
    if (_securityGateRequired(state) && !state.securitySessionUnlocked) {
      return 'security:${user.uid}';
    }
    return 'main:${user.uid}';
  }

  bool _securityGateRequired(AppState state) {
    final hasPin = (state.twoFactorPin ?? '').trim().length >= 4;
    final pinGate = state.twoFactorEnabled && hasPin;
    return state.biometricEnabled || pinGate;
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
    return Scaffold(
      backgroundColor: FR.bg,
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 78,
              height: 78,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [FR.goldHi, FR.goldDeep],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: FRRad.all(22),
                boxShadow: [
                  BoxShadow(color: FR.gold.withOpacity(.3), blurRadius: 28, offset: const Offset(0, 12)),
                ],
              ),
              alignment: Alignment.center,
              child: Text('FR', style: frDisplay(30, FontWeight.w800, color: FR.onGold)),
            ),
            const SizedBox(height: 22),
            Text('FiyatRadar', style: frDisplay(26, FontWeight.w700)),
            const SizedBox(height: 4),
            Text(
              'Market fiyatları · canlı takip',
              style: frText(12.5, FontWeight.w600, color: FR.ink3, letter: .4),
            ),
            const SizedBox(height: 36),
            SizedBox(
              width: 22,
              height: 22,
              child: CircularProgressIndicator(strokeWidth: 2.2, color: FR.gold),
            ),
          ],
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

class _SecurityGateScreen extends StatefulWidget {
  const _SecurityGateScreen({required this.state});
  final AppState state;

  @override
  State<_SecurityGateScreen> createState() => _SecurityGateScreenState();
}

class _SecurityGateScreenState extends State<_SecurityGateScreen> {
  final LocalAuthentication _localAuth = LocalAuthentication();
  final TextEditingController _pinCtrl = TextEditingController();
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _pinCtrl.dispose();
    super.dispose();
  }

  Future<void> _verifyBiometric() async {
    if (_busy) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final isSupported = await _localAuth.isDeviceSupported();
      if (!isSupported) {
        setState(() => _error = 'Bu cihazda biyometri kullanılamıyor.');
        return;
      }
      final ok = await _localAuth.authenticate(
        localizedReason: 'FiyatRadar güvenlik doğrulaması',
        options: const AuthenticationOptions(
          biometricOnly: false,
          stickyAuth: true,
        ),
      );
      if (ok) {
        widget.state.markSecuritySessionUnlocked(true);
      } else {
        setState(() => _error = 'Doğrulama iptal edildi.');
      }
    } catch (e) {
      setState(() => _error = 'Biyometrik doğrulama yapılamadı: $e');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _verifyPin() {
    final pin = _pinCtrl.text.trim();
    final expected = widget.state.twoFactorPin?.trim() ?? '';
    if (pin.length < 4) {
      setState(() => _error = 'Lütfen güvenlik kodunu gir.');
      return;
    }
    if (expected.isEmpty) {
      setState(() => _error = '2FA kodu bulunamadı. Profilden yeniden kur.');
      return;
    }
    if (pin != expected) {
      setState(() => _error = 'Kod hatalı.');
      return;
    }
    widget.state.markSecuritySessionUnlocked(true);
  }

  @override
  Widget build(BuildContext context) {
    final useBiometric = widget.state.biometricEnabled;
    final usePin = widget.state.twoFactorEnabled;
    return Scaffold(
      backgroundColor: FR.bg,
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: FR.surface,
                borderRadius: FRRad.all(FRRad.xl),
                border: Border.all(color: FR.hairline),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text('Güvenlik doğrulaması', style: frDisplay(24, FontWeight.w700)),
                  const SizedBox(height: 6),
                  Text(
                    'Hesaba devam etmek için kimliğini doğrula.',
                    style: frText(12.5, FontWeight.w600, color: FR.ink3),
                  ),
                  if (useBiometric) ...[
                    const SizedBox(height: 16),
                    FRCta(
                      label: _busy ? 'Doğrulanıyor…' : 'Biyometri ile doğrula',
                      icon: Icons.fingerprint_rounded,
                      onTap: _busy ? null : _verifyBiometric,
                    ),
                  ],
                  if (usePin) ...[
                    const SizedBox(height: 12),
                    TextField(
                      controller: _pinCtrl,
                      keyboardType: TextInputType.number,
                      obscureText: true,
                      maxLength: 6,
                      decoration: const InputDecoration(
                        hintText: '2FA kodu',
                        counterText: '',
                      ),
                    ),
                    const SizedBox(height: 8),
                    FRCta(
                      label: 'Kodu doğrula',
                      filled: false,
                      onTap: _verifyPin,
                    ),
                  ],
                  if (_error != null) ...[
                    const SizedBox(height: 10),
                    Text(_error!, style: frText(12, FontWeight.w700, color: FR.bad)),
                  ],
                ],
              ),
            ),
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
