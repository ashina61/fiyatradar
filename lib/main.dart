import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app_router.dart';
import 'providers/app_start_provider.dart';
import 'providers/firebase_init_provider.dart';
import 'screens/auth/login_screen.dart';
import 'screens/main_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await Firebase.initializeApp();
    firebaseInitializedNotifier.value = true;
  } catch (_) {
    firebaseInitializedNotifier.value = false;
  }

  final prefs = await SharedPreferences.getInstance();
  final onboardingComplete = prefs.getBool('onboarding_complete') ?? false;

  runApp(
    ProviderScope(
      child: FiyatRadarApp(showOnboarding: !onboardingComplete),
    ),
  );
}

class FiyatRadarApp extends StatefulWidget {
  const FiyatRadarApp({super.key, required this.showOnboarding});

  final bool showOnboarding;

  @override
  State<FiyatRadarApp> createState() => _FiyatRadarAppState();
}

class _FiyatRadarAppState extends State<FiyatRadarApp> {
  late final GoRouter _router =
      buildAppRouter(showOnboarding: widget.showOnboarding);

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      debugShowCheckedModeBanner: false,
      title: 'Fiyat Radar',
      theme: ThemeData(
        primaryColor: const Color(0xFF6B4226),
        fontFamily: 'Outfit',
      ),
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
      case AppStartState.login:
        return const LoginScreen();
      case AppStartState.authenticated:
        return const MainScreen();
    }
  }
}
