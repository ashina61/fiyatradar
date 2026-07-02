import 'dart:async';

import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart' hide AppState;
import 'package:shared_preferences/shared_preferences.dart';

import 'core/ads/consent_manager.dart';
import 'l10n/app_strings.dart';
import 'screens/login_screen.dart';
import 'screens/main_screen.dart';
import 'screens/onboarding_screen.dart';
import 'screens/verify_email_screen.dart';
import 'services/ads_service.dart';
import 'services/firebase_service.dart';
import 'services/messaging_service.dart';
import 'services/premium_service.dart';
import 'services/session_diagnostics.dart';
import 'state/app_state.dart';
import 'ui/fr_theme.dart';
import 'ui/tokens.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  Object? bootError;
  try {
    await Firebase.initializeApp();
    // Firebase Auth e-posta dilini Türkçe'ye zorla. Doğrulama ve şifre
    // sıfırlama mailleri Firebase'in default şablonuyla gider (gövde tam
    // özelleştirilemez), ama bu çağrı dili mümkün olduğunca Türkçe yapar.
    // Verification / reset çağrı noktaları ayrıca kendi öncesinde de
    // setLanguageCode('tr') çağırır (idempotent).
    try {
      await FirebaseAuth.instance.setLanguageCode('tr');
    } catch (_) {
      // Dil ayarı best-effort; başarısız olsa da auth akışı çalışmaya devam.
    }
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
    // UMP consent → MobileAds.initialize sıralaması zorunlu: consent formu
    // gerektiğinde MobileAds init'inden ÖNCE yanıt alınmalı ki ilk reklam
    // isteği TCF string'iyle çıksın. Hata yiyince akışı bloklamıyoruz —
    // reklam katmanı boot path'inin geri kalanını batırmamalı.
    try {
      await ConsentManager.instance.gatherConsent();
      await MobileAds.instance.initialize();
    } catch (e, st) {
      debugPrint('Ads bootstrap failed (continuing without ads): $e\n$st');
    }
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
    // Satın alma/restore sonrası premium entitlement yazıldığında AppState'i
    // explicit tazele (Firestore listener zaten otomatik günceller; bu, akışın
    // görünür refresh adımı).
    PremiumService.instance.onEntitlementChanged =
        _state.refreshPremiumEntitlement;
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

/// Cold-start oturum geri-yükleme kontrolcüsü.
///
/// Force close sonrası en kritik akış: Firebase.initializeApp() döndükten
/// sonra Auth, diskteki kalıcı oturumu ASENKRON geri yükler. Bu kısa pencerede
/// currentUser bir an için null görünebilir — kayıtlı kullanıcı olsa bile.
/// Bu kontrolcü, restore tamamlanana (ya da timeout'a) kadar `restoring=true`
/// kalır; AuthGate bu sürede Splash gösterir ve LoginScreen'i ASLA göstermez.
///
/// Restore tamamlandıktan sonra da authStateChanges'i dinlemeye devam eder;
/// böylece sonraki giriş/çıkışlarda route otomatik güncellenir.
class _AuthRestoreController extends ChangeNotifier {
  _AuthRestoreController() {
    _start();
  }

  /// Spesifikasyon: currentUser 5-10 sn boyunca poll edilir. AuthGate'in
  /// kendi beklemesi nadiren tetiklenir (AppState.init zaten restoreSession
  /// ile beklemeyi yapar); bu yine de bağımsız bir emniyet ağı.
  static const Duration _restoreTimeout = Duration(seconds: 8);

  bool _restoring = true;
  bool get restoring => _restoring;

  User? user;
  String? routeReason;

  bool _resolved = false;
  StreamSubscription<User?>? _sub;
  Timer? _poll;
  Timer? _deadline;

  Future<void> _start() async {
    final initial = FirebaseAuth.instance.currentUser;
    debugPrint(
      'AUTH_RESTORE_CURRENT_USER_INITIAL: uid=${initial?.uid} '
      'anon=${initial?.isAnonymous}',
    );

    // authStateChanges'i KALICI dinle — restore sonrası login/logout da buradan
    // gelir. Bu yüzden _resolved sonrası da abonelik açık kalır.
    _sub = FirebaseAuth.instance.authStateChanges().listen(
      _onAuthEvent,
      onError: (_) {/* stream hatası restore'u engellemesin */},
    );

    if (initial != null) {
      _resolveUser(initial, 'restored');
      return;
    }

    // currentUser null. İki hızlı çıkış yolu (gereksiz beklemeyi atla):
    //  1. Kullanıcı manuel çıkış yapmış/hesap silmişse → beklemeden login.
    //  2. Cold-start restore beklemesi AppState.init içinde zaten yapıldıysa
    //     (fresh install / logout sonrası) → tekrar bekleme, login göster.
    final explicit = await SessionDiagnostics.isExplicitLogout();
    if (_resolved) return; // bu arada stream user getirmiş olabilir.
    if (explicit) {
      debugPrint('AUTH_RESTORE_TIMEOUT_NO_USER: explicitLogout=true (beklenmeden login)');
      _resolveLogin('explicit_logout');
      return;
    }
    if (FirebaseService.instance.restoreAlreadyAttempted) {
      debugPrint('AUTH_RESTORE_TIMEOUT_NO_USER: restore zaten denendi (beklenmeden login)');
      _resolveLogin('no_user_after_restore');
      return;
    }

    // Aksi halde restore'u poll + stream ile bekle.
    debugPrint('AUTH_RESTORE_WAITING');
    _poll = Timer.periodic(const Duration(milliseconds: 250), (_) {
      final u = FirebaseAuth.instance.currentUser;
      if (u != null) _resolveUser(u, 'restored_poll');
    });
    _deadline = Timer(_restoreTimeout, () {
      if (_resolved) return;
      final u = FirebaseAuth.instance.currentUser;
      if (u != null) {
        _resolveUser(u, 'restored_late');
      } else {
        debugPrint('AUTH_RESTORE_TIMEOUT_NO_USER');
        _resolveLogin('timeout');
      }
    });
  }

  void _onAuthEvent(User? u) {
    if (!_resolved) {
      if (u != null) {
        _resolveUser(u, 'restored_event');
      } else {
        // Restore sürerken gelen null EVENT'i YOK SAY — kalıcı oturum hâlâ
        // geri yükleniyor olabilir; login'e erken düşmeyi engeller.
        debugPrint('AUTH_RESTORE_NULL_EVENT_IGNORED');
      }
      return;
    }
    // Restore tamamlandıktan SONRAKİ değişimler gerçek login/logout'tur.
    user = u;
    if (u == null) {
      routeReason = 'auth_signed_out';
    } else {
      routeReason = 'auth_changed';
      unawaited(SessionDiagnostics.recordAuthSeen(u));
    }
    notifyListeners();
  }

  void _resolveUser(User u, String reason) {
    if (_resolved) return;
    _resolved = true;
    _restoring = false;
    user = u;
    routeReason = reason;
    _poll?.cancel();
    _deadline?.cancel();
    debugPrint(
      'AUTH_RESTORE_USER_FOUND: uid=${u.uid} anon=${u.isAnonymous} '
      'reason=$reason',
    );
    unawaited(SessionDiagnostics.recordRestoreResult('user_found:$reason'));
    unawaited(SessionDiagnostics.recordAuthSeen(u));
    notifyListeners();
  }

  void _resolveLogin(String reason) {
    if (_resolved) return;
    _resolved = true;
    _restoring = false;
    user = null;
    routeReason = reason;
    _poll?.cancel();
    _deadline?.cancel();
    unawaited(SessionDiagnostics.recordRestoreResult('no_user:$reason'));
    notifyListeners();
  }

  @override
  void dispose() {
    _poll?.cancel();
    _deadline?.cancel();
    unawaited(_sub?.cancel());
    super.dispose();
  }
}

/// Reactive auth gate. Üç fazlıdır:
///  1. `initFuture` beklenirken → Splash.
///  2. Onboarding tamamlanmamışsa → Onboarding.
///  3. Oturum geri-yükleme ([_AuthRestoreController]) + [AppState] sinyallerine
///     göre route: restore sürerken Splash, tamamlanınca route tablosu.
///
/// LoginScreen yalnızca restore TAMAMLANDIKTAN ve route sebebi belirlendikten
/// sonra gösterilir — restore beklenirken ASLA gösterilmez.
class _AuthGate extends StatefulWidget {
  const _AuthGate({required this.state, required this.initFuture});
  final AppState state;
  final Future<_Init> initFuture;

  @override
  State<_AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<_AuthGate> {
  final _AuthRestoreController _restore = _AuthRestoreController();

  @override
  void dispose() {
    _restore.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<_Init>(
      future: widget.initFuture,
      builder: (context, snap) {
        if (snap.connectionState != ConnectionState.done) {
          debugPrint('ROUTE_TO_SPLASH: init/bootstrap devam ediyor');
          return const _SplashScreen();
        }
        if (snap.hasError) {
          return _ErrorScreen(error: '${snap.error}');
        }
        if (snap.data!.showOnboarding) return const OnboardingScreen();
        return AnimatedBuilder(
          animation: Listenable.merge([_restore, widget.state]),
          builder: (_, __) {
            if (_restore.restoring) {
              debugPrint('ROUTE_TO_SPLASH: oturum geri-yükleme bekleniyor');
              return const _SplashScreen();
            }
            final user = _restore.user ?? widget.state.user;
            final route = _routeFor(user, widget.state, _restore.routeReason);
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
              child: KeyedSubtree(key: ValueKey(route.key), child: route.screen),
            );
          },
        );
      },
    );
  }

  ({Widget screen, String key}) _routeFor(
    User? user,
    AppState state,
    String? restoreReason,
  ) {
    if (user == null) {
      final reason = restoreReason ?? 'no_user';
      debugPrint('ROUTE_TO_LOGIN');
      debugPrint('ROUTE_TO_LOGIN_REASON: $reason');
      unawaited(SessionDiagnostics.recordRoute('login', reason));
      return (screen: const LoginScreen(), key: 'login');
    }
    // guestAcknowledged YALNIZCA anonim kullanıcı için geçerli. Gerçek
    // kullanıcı bu bayrak false olsa bile ASLA login'e atılmaz.
    if (user.isAnonymous && !state.guestAcknowledged) {
      debugPrint('ROUTE_TO_LOGIN');
      debugPrint('ROUTE_TO_LOGIN_REASON: guest_not_acknowledged');
      unawaited(SessionDiagnostics.recordRoute('login', 'guest_not_acknowledged'));
      return (screen: const LoginScreen(), key: 'login');
    }
    if (state.isBanned) {
      unawaited(SessionDiagnostics.recordRoute('banned', 'banned'));
      return (
        screen: _BannedScreen(reason: state.banReason),
        key: 'banned:${user.uid}',
      );
    }
    // E-posta/şifre ile kayıtlı ama doğrulanmamış kullanıcı katkı
    // yapamasın — uygulamaya girmeden önce mail kutusundaki linke
    // tıklamalı. Google ile gelenler zaten verified=true gelir.
    if (!user.isAnonymous && !user.emailVerified) {
      unawaited(SessionDiagnostics.recordRoute('verify_email', 'email_not_verified'));
      return (screen: const VerifyEmailScreen(), key: 'verify:${user.uid}');
    }
    debugPrint('ROUTE_TO_HOME: uid=${user.uid} anon=${user.isAnonymous}');
    unawaited(SessionDiagnostics.recordRoute(
      'home',
      user.isAnonymous ? 'guest' : 'authenticated',
    ));
    return (screen: const MainScreen(), key: 'main:${user.uid}');
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
    // background. Tema koyu ise koyu paleti kullan — eskiden her zaman
    // açık krem geliyordu ve dark mode kullanıcısı açılışta beyaz flaş
    // görüyordu.
    final bg = FRThemeController.instance.isDark
        ? FRPalette.dark.bg
        : FRPalette.light.bg;
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
