import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'screens/login_screen.dart';
import 'screens/main_screen.dart';
import 'screens/onboarding_screen.dart';
import 'state/app_state.dart';
import 'ui/fr_theme.dart';
import 'ui/tokens.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(const FiyatRadarApp());
}

class FiyatRadarApp extends StatefulWidget {
  const FiyatRadarApp({super.key});

  @override
  State<FiyatRadarApp> createState() => _FiyatRadarAppState();
}

class _FiyatRadarAppState extends State<FiyatRadarApp> {
  final AppState _state = AppState();
  late final Future<_Init> _initFuture = _boot();

  Future<_Init> _boot() async {
    await _state.init();
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
      child: MaterialApp(
        title: 'FiyatRadar',
        debugShowCheckedModeBanner: false,
        theme: buildFRTheme(),
        home: FutureBuilder<_Init>(
          future: _initFuture,
          builder: (context, snap) {
            if (snap.connectionState != ConnectionState.done) {
              return const _SplashScreen();
            }
            if (snap.hasError) {
              return _ErrorScreen(error: '${snap.error}');
            }
            if (snap.data!.showOnboarding) return const OnboardingScreen();
            final user = _state.user;
            if (user == null || user.isAnonymous) return const LoginScreen();
            return const MainScreen();
          },
        ),
      ),
    );
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
                gradient: const LinearGradient(
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
              child: Text('FR', style: frDisplay(30, FontWeight.w800, color: FR.bg)),
            ),
            const SizedBox(height: 22),
            Text('FiyatRadar', style: frDisplay(26, FontWeight.w700)),
            const SizedBox(height: 4),
            Text(
              'Market fiyatları · canlı takip',
              style: frText(12.5, FontWeight.w600, color: FR.ink3, letter: .4),
            ),
            const SizedBox(height: 36),
            const SizedBox(
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
              const Icon(Icons.wifi_off_rounded, color: FR.bad, size: 46),
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
