import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'screens/main_screen.dart';
import 'screens/onboarding_screen.dart';
import 'state/app_state.dart';
import 'theme.dart';

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
  late final Future<_InitResult> _initFuture = _buildInit();

  Future<_InitResult> _buildInit() async {
    await _state.init();
    final prefs = await SharedPreferences.getInstance();
    final onboardingDone = prefs.getBool('onboarding_done') ?? false;
    return _InitResult(showOnboarding: !onboardingDone);
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
        theme: buildCoffeeTheme(),
        home: FutureBuilder<_InitResult>(
          future: _initFuture,
          builder: (context, snap) {
            if (snap.connectionState != ConnectionState.done) {
              return const _SplashScreen();
            }
            if (snap.hasError) {
              return _ErrorScreen(error: '${snap.error}');
            }
            if (snap.data!.showOnboarding) {
              return const OnboardingScreen();
            }
            return const MainScreen();
          },
        ),
      ),
    );
  }
}

class _InitResult {
  final bool showOnboarding;
  const _InitResult({required this.showOnboarding});
}

// ─── Splash ───────────────────────────────────────────────────────────────────

class _SplashScreen extends StatelessWidget {
  const _SplashScreen();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: CoffeeColors.espresso,
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: CoffeeColors.caramel,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: CoffeeColors.caramel.withOpacity(0.3),
                    blurRadius: 32,
                    offset: const Offset(0, 12),
                  ),
                ],
              ),
              alignment: Alignment.center,
              child: const Text('☕', style: TextStyle(fontSize: 38)),
            ),
            const SizedBox(height: 20),
            const Text(
              'FiyatRadar',
              style: TextStyle(
                color: CoffeeColors.cream,
                fontWeight: FontWeight.w800,
                fontSize: 24,
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'Topluluk fiyat platformu',
              style: TextStyle(
                color: CoffeeColors.latte,
                fontSize: 13,
              ),
            ),
            const SizedBox(height: 40),
            const SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(
                strokeWidth: 2.5,
                color: CoffeeColors.caramel,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Error ────────────────────────────────────────────────────────────────────

class _ErrorScreen extends StatelessWidget {
  const _ErrorScreen({required this.error});
  final String error;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: CoffeeColors.cream,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.wifi_off_rounded,
                  color: CoffeeColors.cocoa, size: 48),
              const SizedBox(height: 16),
              const Text(
                'Bağlantı hatası',
                style: TextStyle(
                    color: CoffeeColors.espresso,
                    fontWeight: FontWeight.w800,
                    fontSize: 18),
              ),
              const SizedBox(height: 8),
              Text(
                error,
                textAlign: TextAlign.center,
                style: const TextStyle(
                    color: CoffeeColors.cocoa, fontSize: 13),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
