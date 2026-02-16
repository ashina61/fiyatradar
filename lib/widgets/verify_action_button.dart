import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class VerifyActionButton extends StatefulWidget {
  const VerifyActionButton({
    super.key,
    required this.label,
    required this.count,
    required this.color,
    required this.icon,
    required this.successIcon,
    required this.onTap,
    required this.successSignal,
    required this.isPositive,
  });

  final String label;
  final int count;
  final Color color;
  final IconData icon;
  final IconData successIcon;
  final VoidCallback onTap;
  final ValueListenable<int> successSignal;
  final bool isPositive;

  @override
  State<VerifyActionButton> createState() => _VerifyActionButtonState();
}

class _VerifyActionButtonState extends State<VerifyActionButton> with SingleTickerProviderStateMixin {
  bool _isPressed = false;
  bool _showSuccessIcon = false;
  double _glowOpacity = 0;
  double _scaleX = 1;
  double _pulseOpacity = 0;
  late final AnimationController _shakeController;

  @override
  void initState() {
    super.initState();
    _shakeController = AnimationController(vsync: this, duration: const Duration(milliseconds: 160));
    widget.successSignal.addListener(_onSuccess);
  }

  @override
  void didUpdateWidget(covariant VerifyActionButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.successSignal != widget.successSignal) {
      oldWidget.successSignal.removeListener(_onSuccess);
      widget.successSignal.addListener(_onSuccess);
    }
  }

  @override
  void dispose() {
    widget.successSignal.removeListener(_onSuccess);
    _shakeController.dispose();
    super.dispose();
  }

  Future<void> _onSuccess() async {
    if (!mounted) return;
    if (widget.isPositive) {
      HapticFeedback.lightImpact();
      setState(() {
        _showSuccessIcon = true;
        _scaleX = 1.08;
        _glowOpacity = 0.18;
      });
      await Future<void>.delayed(const Duration(milliseconds: 220));
      if (!mounted) return;
      setState(() {
        _scaleX = 1;
        _glowOpacity = 0;
      });
      await Future<void>.delayed(const Duration(milliseconds: 220));
      if (!mounted) return;
      setState(() {
        _showSuccessIcon = false;
      });
      return;
    }

    setState(() {
      _pulseOpacity = 0.18;
    });
    _shakeController.forward(from: 0);
    await Future<void>.delayed(const Duration(milliseconds: 200));
    if (!mounted) return;
    setState(() {
      _pulseOpacity = 0;
    });
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _shakeController,
      builder: (context, child) {
        final shake = widget.isPositive ? 0.0 : math.sin(_shakeController.value * math.pi * 6) * 4;
        return Transform.translate(offset: Offset(shake, 0), child: child);
      },
      child: GestureDetector(
        onTapDown: (_) => setState(() => _isPressed = true),
        onTapCancel: () => setState(() => _isPressed = false),
        onTapUp: (_) => setState(() => _isPressed = false),
        onTap: widget.onTap,
        child: AnimatedScale(
          scale: _isPressed ? 0.96 : 1,
          duration: const Duration(milliseconds: 90),
          curve: Curves.easeOut,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            curve: Curves.easeOut,
            transform: Matrix4.identity()..scale(_scaleX, 1.0),
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
            decoration: BoxDecoration(
              color: widget.color.withOpacity(0.08),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: widget.color.withOpacity(0.35)),
              boxShadow: [
                BoxShadow(color: widget.color.withOpacity(_glowOpacity), blurRadius: 20, spreadRadius: 2),
              ],
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                AnimatedOpacity(
                  opacity: _pulseOpacity,
                  duration: const Duration(milliseconds: 120),
                  child: Container(
                    decoration: BoxDecoration(
                      color: widget.color,
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(_showSuccessIcon ? widget.successIcon : widget.icon, color: widget.color),
                    const SizedBox(width: 8),
                    Text(widget.label, style: TextStyle(color: widget.color, fontWeight: FontWeight.w700)),
                    const SizedBox(width: 8),
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 120),
                      transitionBuilder: (child, animation) {
                        final offset = Tween<Offset>(begin: const Offset(0, 0.25), end: Offset.zero).animate(animation);
                        return FadeTransition(opacity: animation, child: SlideTransition(position: offset, child: child));
                      },
                      child: Text(
                        '${widget.count}',
                        key: ValueKey<int>(widget.count),
                        style: TextStyle(color: widget.color, fontWeight: FontWeight.w800),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
