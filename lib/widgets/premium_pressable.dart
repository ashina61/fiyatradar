import 'package:flutter/material.dart';

class PremiumPressable extends StatefulWidget {
  const PremiumPressable({
    super.key,
    required this.child,
    required this.onTap,
    this.borderRadius,
    this.pressedScale = 0.97,
    this.pressedOpacity = 0.94,
    this.duration = const Duration(milliseconds: 160),
  });

  final Widget child;
  final VoidCallback? onTap;
  final BorderRadius? borderRadius;
  final double pressedScale;
  final double pressedOpacity;
  final Duration duration;

  @override
  State<PremiumPressable> createState() => _PremiumPressableState();
}

class _PremiumPressableState extends State<PremiumPressable> {
  bool _pressed = false;

  void _setPressed(bool value) {
    if (_pressed == value) return;
    setState(() => _pressed = value);
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _setPressed(true),
      onTapUp: (_) => _setPressed(false),
      onTapCancel: () => _setPressed(false),
      onTap: widget.onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedScale(
        duration: widget.duration,
        curve: Curves.easeOutCubic,
        scale: _pressed ? widget.pressedScale : 1,
        child: AnimatedOpacity(
          duration: widget.duration,
          curve: Curves.easeOutCubic,
          opacity: _pressed ? widget.pressedOpacity : 1,
          child: ClipRRect(
            borderRadius: widget.borderRadius ?? BorderRadius.zero,
            child: widget.child,
          ),
        ),
      ),
    );
  }
}
