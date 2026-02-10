import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/notification_provider.dart';
import '../utils/theme.dart';
import 'add_price/add_price_screen.dart';
import 'home/home_screen.dart';
import 'notifications/notifications_screen.dart';
import 'profile/profile_screen.dart';
import 'search/search_screen.dart';

final currentTabProvider = StateProvider<int>((ref) => 0);

class MainScreen extends ConsumerStatefulWidget {
  const MainScreen({super.key});

  @override
  ConsumerState<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends ConsumerState<MainScreen>
    with TickerProviderStateMixin {
  // FAB press animation
  late final AnimationController _fabController;
  // FAB pulse glow
  late final AnimationController _fabPulseController;
  // Tab indicator slide
  late final AnimationController _indicatorController;
  // Entry animation
  late final AnimationController _entryController;

  late final Animation<double> _entrySlide;
  late final Animation<double> _entryOpacity;

  int _previousTab = 0;

  @override
  void initState() {
    super.initState();

    _fabController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
      lowerBound: 0.0,
      upperBound: 1.0,
    );

    _fabPulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2400),
    )..repeat(reverse: true);

    _indicatorController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 350),
    );

    _entryController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );

    _entrySlide = Tween<double>(begin: 60, end: 0).animate(
      CurvedAnimation(
        parent: _entryController,
        curve: Curves.easeOutCubic,
      ),
    );

    _entryOpacity = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _entryController,
        curve: const Interval(0.0, 0.6, curve: Curves.easeOut),
      ),
    );

    _entryController.forward();
  }

  @override
  void dispose() {
    _fabController.dispose();
    _fabPulseController.dispose();
    _indicatorController.dispose();
    _entryController.dispose();
    super.dispose();
  }

  void _onTabSelected(int index) {
    _previousTab = ref.read(currentTabProvider);
    ref.read(currentTabProvider.notifier).state = index;
    _indicatorController.forward(from: 0);

    HapticFeedback.selectionClick();
  }

  @override
  Widget build(BuildContext context) {
    final currentTab = ref.watch(currentTabProvider);
    final unreadCountAsync = ref.watch(unreadNotificationCountProvider);
    final unreadCount = unreadCountAsync.valueOrNull ?? 0;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final screens = const [
      HomeScreen(),
      SearchScreen(),
      AddPriceScreen(),
      NotificationsScreen(),
      ProfileScreen(),
    ];

    return Scaffold(
      body: IndexedStack(index: currentTab, children: screens),
      extendBody: true,
      bottomNavigationBar: AnimatedBuilder(
        animation: _entryController,
        builder: (context, child) {
          return Transform.translate(
            offset: Offset(0, _entrySlide.value),
            child: Opacity(
              opacity: _entryOpacity.value,
              child: child,
            ),
          );
        },
        child: _PremiumBottomBar(
          currentTab: currentTab,
          previousTab: _previousTab,
          unreadCount: unreadCount,
          onTabSelected: _onTabSelected,
          fabController: _fabController,
          fabPulseController: _fabPulseController,
          indicatorController: _indicatorController,
          isDark: isDark,
          theme: theme,
        ),
      ),
    );
  }
}

class _PremiumBottomBar extends StatelessWidget {
  final int currentTab;
  final int previousTab;
  final int unreadCount;
  final ValueChanged<int> onTabSelected;
  final AnimationController fabController;
  final AnimationController fabPulseController;
  final AnimationController indicatorController;
  final bool isDark;
  final ThemeData theme;

  const _PremiumBottomBar({
    required this.currentTab,
    required this.previousTab,
    required this.unreadCount,
    required this.onTabSelected,
    required this.fabController,
    required this.fabPulseController,
    required this.indicatorController,
    required this.isDark,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    final bottomPadding = MediaQuery.of(context).padding.bottom;

    return Container(
      margin: EdgeInsets.only(
        left: 16,
        right: 16,
        bottom: bottomPadding + 12,
      ),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.4 : 0.08),
            blurRadius: 30,
            offset: const Offset(0, 8),
            spreadRadius: 0,
          ),
          BoxShadow(
            color: AppColors.primary.withOpacity(isDark ? 0.08 : 0.04),
            blurRadius: 50,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(28),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: Container(
            height: 72,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(28),
              color: isDark
                  ? AppColors.surfaceDark.withOpacity(0.85)
                  : Colors.white.withOpacity(0.92),
              border: Border.all(
                color: isDark
                    ? AppColors.outlineDark.withOpacity(0.3)
                    : AppColors.outline.withOpacity(0.4),
                width: 0.5,
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildNavItem(
                  index: 0,
                  icon: Icons.home_outlined,
                  activeIcon: Icons.home_rounded,
                  label: 'Ana Sayfa',
                ),
                _buildNavItem(
                  index: 1,
                  icon: Icons.search_outlined,
                  activeIcon: Icons.search_rounded,
                  label: 'Ara',
                ),
                _buildFAB(),
                _buildNavItem(
                  index: 3,
                  icon: Icons.notifications_outlined,
                  activeIcon: Icons.notifications_rounded,
                  label: 'Bildirimler',
                  badgeCount: unreadCount,
                ),
                _buildNavItem(
                  index: 4,
                  icon: Icons.person_outline,
                  activeIcon: Icons.person_rounded,
                  label: 'Profil',
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem({
    required int index,
    required IconData icon,
    required IconData activeIcon,
    required String label,
    int badgeCount = 0,
  }) {
    final isSelected = currentTab == index;
    final color = isSelected
        ? AppColors.primary
        : (isDark ? AppColors.textSecondaryDark : AppColors.textTertiary);

    return GestureDetector(
      onTap: () => onTabSelected(index),
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        width: 64,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                // Active indicator background
                AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeOutCubic,
                  padding: EdgeInsets.symmetric(
                    horizontal: isSelected ? 14 : 10,
                    vertical: isSelected ? 6 : 4,
                  ),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    color: isSelected
                        ? AppColors.primary.withOpacity(isDark ? 0.15 : 0.1)
                        : Colors.transparent,
                  ),
                  child: _AnimatedTabIcon(
                    icon: icon,
                    activeIcon: activeIcon,
                    isSelected: isSelected,
                    color: color,
                  ),
                ),
                // Badge
                if (badgeCount > 0)
                  Positioned(
                    right: -2,
                    top: -4,
                    child: _AnimatedBadge(count: badgeCount),
                  ),
              ],
            ),
            const SizedBox(height: 2),
            AnimatedDefaultTextStyle(
              duration: const Duration(milliseconds: 250),
              style: TextStyle(
                fontSize: isSelected ? 10.5 : 10,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                color: color,
                letterSpacing: isSelected ? 0.1 : 0,
              ),
              child: Text(label),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFAB() {
    final isSelected = currentTab == 2;

    return GestureDetector(
      onTapDown: (_) => fabController.forward(),
      onTapUp: (_) {
        fabController.reverse();
        onTabSelected(2);
      },
      onTapCancel: () => fabController.reverse(),
      child: AnimatedBuilder(
        animation: Listenable.merge([fabController, fabPulseController]),
        builder: (context, child) {
          final pressScale = 1.0 - fabController.value * 0.1;
          final pulseValue = fabPulseController.value;

          return Transform.scale(
            scale: pressScale,
            child: Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    AppColors.primary,
                    AppColors.primaryLight,
                    AppColors.accent,
                  ],
                ),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withOpacity(
                      isSelected
                          ? 0.35 + pulseValue * 0.1
                          : 0.25 + pulseValue * 0.05,
                    ),
                    blurRadius: isSelected ? 20 + pulseValue * 6 : 14,
                    offset: const Offset(0, 4),
                    spreadRadius: isSelected ? pulseValue * 2 : 0,
                  ),
                  BoxShadow(
                    color: AppColors.accent.withOpacity(0.1),
                    blurRadius: 30,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: AnimatedRotation(
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeOutCubic,
                turns: isSelected ? 0.125 : 0,
                child: const Icon(
                  Icons.add_rounded,
                  color: Colors.white,
                  size: 28,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _AnimatedTabIcon extends StatelessWidget {
  final IconData icon;
  final IconData activeIcon;
  final bool isSelected;
  final Color color;

  const _AnimatedTabIcon({
    required this.icon,
    required this.activeIcon,
    required this.isSelected,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 280),
      switchInCurve: Curves.easeOutBack,
      switchOutCurve: Curves.easeIn,
      transitionBuilder: (child, animation) {
        return ScaleTransition(
          scale: animation,
          child: FadeTransition(
            opacity: animation,
            child: child,
          ),
        );
      },
      child: Icon(
        isSelected ? activeIcon : icon,
        key: ValueKey(isSelected),
        color: color,
        size: isSelected ? 24 : 22,
      ),
    );
  }
}

class _AnimatedBadge extends StatefulWidget {
  final int count;

  const _AnimatedBadge({required this.count});

  @override
  State<_AnimatedBadge> createState() => _AnimatedBadgeState();
}

class _AnimatedBadgeState extends State<_AnimatedBadge>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _scale = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.elasticOut),
    );
    _controller.forward();
  }

  @override
  void didUpdateWidget(covariant _AnimatedBadge oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.count != widget.count) {
      _controller.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: _scale,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
        constraints: const BoxConstraints(minWidth: 18, minHeight: 18),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFFFF4757), Color(0xFFFF6B81)],
          ),
          borderRadius: BorderRadius.circular(10),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFFFF4757).withOpacity(0.4),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        alignment: Alignment.center,
        child: Text(
          widget.count > 99 ? '99+' : '${widget.count}',
          style: const TextStyle(
            color: Colors.white,
            fontSize: 10,
            fontWeight: FontWeight.w700,
            height: 1.2,
          ),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}
