import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'screens/auth/forgot_password_screen.dart';
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
        pageBuilder: (context, state) => _fadePage(
          state,
          OnboardingScreen(
            onComplete: () async {
              final prefs = await SharedPreferences.getInstance();
              await prefs.setBool('onboarding_complete', true);
            },
          ),
        ),
      ),
      GoRoute(
        path: '/start',
        builder: (context, state) => const AppStartGate(),
      ),
      GoRoute(
        path: '/login',
        builder: (context, state) => const AppStartGate(),
      ),
      GoRoute(
        path: '/register',
        pageBuilder: (context, state) => _fadePage(state, const RegisterScreen()),
      ),
      GoRoute(
        path: '/forgot-password',
        pageBuilder: (context, state) => _fadePage(state, const ForgotPasswordScreen()),
      ),
      GoRoute(
        path: '/main',
        builder: (context, state) => const MainScreen(),
      ),
    ],
  );
}

CustomTransitionPage<void> _fadePage(GoRouterState state, Widget child) {
  return CustomTransitionPage<void>(
    key: state.pageKey,
    child: child,
    transitionDuration: const Duration(milliseconds: 280),
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      final tween = Tween(begin: const Offset(0.04, 0.0), end: Offset.zero);
      return FadeTransition(
        opacity: animation,
        child: SlideTransition(position: animation.drive(tween), child: child),
      );
    },
  );
}
