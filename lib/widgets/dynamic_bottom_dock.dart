// FILE: lib/widgets/dynamic_bottom_dock.dart
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

class DynamicBottomDock extends StatefulWidget {
  final ValueChanged<int>? onTabChanged;
  final VoidCallback? onCenterAction;
  final int initialIndex;

  const DynamicBottomDock({
    super.key,
    this.onTabChanged,
    this.onCenterAction,
    this.initialIndex = 0,
  });

  @override
  State<DynamicBottomDock> createState() => _DynamicBottomDockState();
}

class _DynamicBottomDockState extends State<DynamicBottomDock> {
  // Tasarım sabitleri: CSS değerlerini birebir korumak için tek yerde tanımlı.
  static const Color _activeColor = Color(0xFF6B4226);
  static const Color _inactiveColor = Color(0xFFA38671);
  static const Color _dockBackground = Colors.white;
  static const Duration _itemDuration = Duration(milliseconds: 400);
  static const Duration _centerDuration = Duration(milliseconds: 200);
  static const Curve _itemCurve = Curves.easeInOut;

  late int _currentIndex;
  bool _isCenterPressed = false;

  final List<Map<String, dynamic>> _navItems = const [
    {'icon': Icons.home_rounded, 'label': 'Ana Sayfa'},
    {'icon': Icons.explore_rounded, 'label': 'Keşfet'},
    {'icon': Icons.shopping_bag_rounded, 'label': 'Sepet'},
    {'icon': Icons.person_rounded, 'label': 'Profil'},
  ];

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex.clamp(0, _navItems.length - 1);
  }

  @override
  void didUpdateWidget(covariant DynamicBottomDock oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initialIndex != widget.initialIndex) {
      _currentIndex = widget.initialIndex.clamp(0, _navItems.length - 1);
    }
  }

  void _onNavTap(int index) {
    if (_currentIndex == index) return;
    HapticFeedback.lightImpact();
    setState(() => _currentIndex = index);
    widget.onTabChanged?.call(index);
  }

  void _onCenterTapDown(TapDownDetails _) {
    setState(() => _isCenterPressed = true);
  }

  void _onCenterTapEnd() {
    if (!_isCenterPressed) return;
    setState(() => _isCenterPressed = false);
  }

  void _onCenterTap() {
    HapticFeedback.lightImpact();
    widget.onCenterAction?.call();
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.paddingOf(context).bottom;

    return Container(
      decoration: BoxDecoration(
        color: _dockBackground,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
        boxShadow: [
          BoxShadow(
            color: _activeColor.withOpacity(0.05),
            blurRadius: 25,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      padding: EdgeInsets.fromLTRB(16, 12, 16, 24 + bottomInset),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _buildNavItem(index: 0),
          _buildNavItem(index: 1),
          _buildCenterAction(),
          _buildNavItem(index: 2),
          _buildNavItem(index: 3),
        ],
      ),
    );
  }

  Widget _buildNavItem({required int index}) {
    final item = _navItems[index];
    final bool isActive = _currentIndex == index;

    return Semantics(
      button: true,
      selected: isActive,
      label: item['label'] as String,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => _onNavTap(index),
        child: AnimatedContainer(
          duration: _itemDuration,
          curve: _itemCurve,
          padding: isActive
              ? const EdgeInsets.symmetric(horizontal: 20, vertical: 12)
              : const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: isActive ? _activeColor.withOpacity(0.10) : Colors.transparent,
            borderRadius: BorderRadius.circular(100),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                item['icon'] as IconData,
                size: 26,
                color: isActive ? _activeColor : _inactiveColor,
              ),
              AnimatedSwitcher(
                duration: _itemDuration,
                switchInCurve: _itemCurve,
                switchOutCurve: _itemCurve,
                transitionBuilder: (child, animation) {
                  return FadeTransition(
                    opacity: animation,
                    child: SizeTransition(
                      sizeFactor: animation,
                      axis: Axis.horizontal,
                      axisAlignment: -1,
                      child: child,
                    ),
                  );
                },
                child: isActive
                    ? Padding(
                        key: ValueKey<String>('label_$index'),
                        padding: const EdgeInsets.only(left: 8),
                        child: Text(
                          item['label'] as String,
                          style: GoogleFonts.outfit(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: _activeColor,
                          ),
                        ),
                      )
                    : const SizedBox.shrink(key: ValueKey<String>('empty')),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCenterAction() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Transform.translate(
        offset: const Offset(0, -12),
        child: GestureDetector(
          onTapDown: _onCenterTapDown,
          onTapUp: (_) => _onCenterTapEnd(),
          onTapCancel: _onCenterTapEnd,
          onTap: _onCenterTap,
          child: AnimatedScale(
            duration: _centerDuration,
            curve: Curves.easeOut,
            scale: _isCenterPressed ? 0.92 : 1,
            child: Transform.rotate(
              angle: 45 * math.pi / 180,
              child: Container(
                width: 54,
                height: 54,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color(0xFF8C5938), Color(0xFF4A2E1B)],
                  ),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: _activeColor.withOpacity(0.25),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                alignment: Alignment.center,
                child: Transform.rotate(
                  angle: -45 * math.pi / 180,
                  child: const Icon(
                    Icons.add_rounded,
                    color: Colors.white,
                    size: 30,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
