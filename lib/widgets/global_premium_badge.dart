import 'package:flutter/material.dart';

class GlobalPremiumBadge extends StatefulWidget {
  const GlobalPremiumBadge({
    super.key,
    required this.levelName,
    required this.levelColor,
    required this.showPulseAnimation,
    this.userName,
    this.showVerifiedIcon = false,
    this.leadingIcon = Icons.military_tech_rounded,
  });

  final String levelName;
  final Color levelColor;
  final bool showPulseAnimation;
  final String? userName;
  final bool showVerifiedIcon;
  final IconData leadingIcon;

  @override
  State<GlobalPremiumBadge> createState() => _GlobalPremiumBadgeState();
}

class _GlobalPremiumBadgeState extends State<GlobalPremiumBadge>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );
    if (widget.showPulseAnimation) {
      _controller.repeat(reverse: true);
    }
  }

  @override
  void didUpdateWidget(covariant GlobalPremiumBadge oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.showPulseAnimation) {
      if (!_controller.isAnimating) {
        _controller.repeat(reverse: true);
      }
    } else {
      _controller.stop();
      _controller.value = 0;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.showPulseAnimation) {
      return _buildBadge(blurRadius: 10, spreadRadius: 0);
    }

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final blurRadius = 10 + (15 * _controller.value);
        final spreadRadius = 4 * _controller.value;
        return _buildBadge(blurRadius: blurRadius, spreadRadius: spreadRadius);
      },
    );
  }

  Widget _buildBadge({
    required double blurRadius,
    required double spreadRadius,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 11),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(40),
        border: Border.all(color: widget.levelColor, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: widget.levelColor.withOpacity(0.5),
            blurRadius: blurRadius,
            spreadRadius: spreadRadius,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(widget.leadingIcon, color: widget.levelColor, size: 21),
          const SizedBox(width: 8),
          Text(
            (widget.userName ?? widget.levelName).trim(),
            style: TextStyle(
              color: widget.levelColor,
              fontSize: 19,
              fontWeight: FontWeight.w900,
            ),
          ),
          if (widget.showVerifiedIcon) ...[
            const SizedBox(width: 8),
            const Icon(Icons.verified, color: Color(0xFF1DA1F2), size: 21),
          ],
        ],
      ),
    );
  }
}
