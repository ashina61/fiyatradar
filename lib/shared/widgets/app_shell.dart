import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_radius.dart';
import '../../core/constants/app_spacing.dart';

class AppShell extends StatelessWidget {
  const AppShell({super.key, required this.child});

  final Widget child;

  static const _tabs = ['/home', '/search', '/add-price', '/profile'];

  int _currentIndex(String location) {
    final index = _tabs.indexWhere((tab) => location.startsWith(tab));
    return index >= 0 ? index : 0;
  }

  @override
  Widget build(BuildContext context) {
    final location = GoRouterState.of(context).uri.toString();

    return Scaffold(
      body: child,
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(AppRadius.xl),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: AppSpacing.md, sigmaY: AppSpacing.md),
            child: BottomNavigationBar(
              currentIndex: _currentIndex(location),
              onTap: (index) => context.go(_tabs[index]),
              items: const [
                BottomNavigationBarItem(icon: Icon(Icons.home_rounded), label: 'Ana Sayfa'),
                BottomNavigationBarItem(icon: Icon(Icons.search_rounded), label: 'Ara'),
                BottomNavigationBarItem(icon: Icon(Icons.add_circle_rounded), label: 'Ekle'),
                BottomNavigationBarItem(icon: Icon(Icons.person_rounded), label: 'Profil'),
              ],
            ),
          ),
        ),
      ),
      backgroundColor: AppColors.bgPrimary,
    );
  }
}
