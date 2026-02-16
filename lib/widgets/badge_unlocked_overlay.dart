import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/material.dart';

import '../utils/theme.dart';

class BadgeUnlockedOverlay extends StatefulWidget {
  const BadgeUnlockedOverlay({
    super.key,
    required this.badgeTitle,
    required this.badgeDescription,
    required this.onAcknowledge,
  });

  final String badgeTitle;
  final String badgeDescription;
  final Future<void> Function() onAcknowledge;

  @override
  State<BadgeUnlockedOverlay> createState() => _BadgeUnlockedOverlayState();
}

class _BadgeUnlockedOverlayState extends State<BadgeUnlockedOverlay> with TickerProviderStateMixin {
  late final AnimationController _scaleController;
  late final AnimationController _ringController;

  @override
  void initState() {
    super.initState();
    _scaleController = AnimationController(vsync: this, duration: const Duration(milliseconds: 260))..forward();
    _ringController = AnimationController(vsync: this, duration: const Duration(milliseconds: 1800))..repeat();
  }

  @override
  void dispose() {
    _scaleController.dispose();
    _ringController.dispose();
    super.dispose();
  }

  Future<void> _close() async {
    await widget.onAcknowledge();
    if (!mounted) return;
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _close,
      child: Material(
        color: Colors.black45,
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
          child: Center(
            child: GestureDetector(
              onTap: () {},
              child: ScaleTransition(
                scale: Tween<double>(begin: 0.8, end: 1).animate(CurvedAnimation(parent: _scaleController, curve: Curves.easeOutBack)),
                child: Container(
                  width: 320,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(24),
                    color: AppColors.surface.withOpacity(0.88),
                    border: Border.all(
                      width: 1.2,
                      color: const Color(0xFFE9C46A).withOpacity(0.8),
                    ),
                    boxShadow: [
                      BoxShadow(color: const Color(0xFFE9C46A).withOpacity(0.22), blurRadius: 24, spreadRadius: 2),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      AnimatedBuilder(
                        animation: _ringController,
                        builder: (context, _) {
                          final wave = 0.7 + (math.sin(_ringController.value * math.pi * 2) * 0.3);
                          return Container(
                            width: 92,
                            height: 92,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: const LinearGradient(colors: [Color(0xFFF4D06F), Color(0xFFE9C46A)]),
                              boxShadow: [
                                BoxShadow(color: AppColors.success.withOpacity((0.14 * wave).clamp(0, 0.18)), blurRadius: 22, spreadRadius: 4),
                              ],
                            ),
                            alignment: Alignment.center,
                            child: const Text('🏆', style: TextStyle(fontSize: 38)),
                          );
                        },
                      ),
                      const SizedBox(height: 16),
                      const Text('🎉 Rozet Kazandın!', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800)),
                      const SizedBox(height: 8),
                      Text(widget.badgeTitle, textAlign: TextAlign.center, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
                      const SizedBox(height: 8),
                      Text(widget.badgeDescription, textAlign: TextAlign.center, style: const TextStyle(color: AppColors.textSecondary)),
                      const SizedBox(height: 20),
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton(
                          onPressed: _close,
                          child: const Text('TAMAM'),
                        ),
                      ),
                    ],
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
