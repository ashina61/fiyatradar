import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'screens/auth/login_screen.dart';
import 'screens/auth/register_screen.dart';
import 'screens/main_screen.dart';
import 'screens/onboarding/onboarding_screen.dart';
import 'main.dart';

GoRouter buildAppRouter({required bool showOnboarding}) {
  return GoRouter(
    initialLocation: showOnboarding ? '/onboarding' : '/start',
    routes: [
      GoRoute(
        path: '/onboarding',
        builder: (context, state) => OnboardingScreen(
          onComplete: () async {
            final prefs = await SharedPreferences.getInstance();
            await prefs.setBool('onboarding_complete', true);
            if (context.mounted) {
              context.go('/start');
            }
          },
        ),
      ),
      GoRoute(
        path: '/start',
        builder: (context, state) => const AppStartGate(),
      ),
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/register',
        builder: (context, state) => const RegisterScreen(),
      ),
      GoRoute(
        path: '/main',
        builder: (context, state) => const MainScreen(),
      ),
    ],
  );
}
