import 'package:flutter/material.dart';

import '../utils/elite_level_engine.dart';

class GlobalPremiumBadge extends StatefulWidget {
  const GlobalPremiumBadge({
    super.key,
    required this.levelName,
    this.userName,
    this.showVerifiedIcon = false,
    this.leadingIcon,
    this.levelColor,
    this.showPulseAnimation,
  });

  final String levelName;
  final Color? levelColor;
  final bool? showPulseAnimation;
  final String? userName;
  final bool showVerifiedIcon;
  final IconData? leadingIcon;

  @override
  State<GlobalPremiumBadge> createState() => _GlobalPremiumBadgeState();
}

class _GlobalPremiumBadgeState extends State<GlobalPremiumBadge>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  late EliteLevelStyle _style;

  bool get _resolvedPulse {
    if (widget.showPulseAnimation != null) return widget.showPulseAnimation!;
    final normalized = widget.levelName.trim().toLowerCase();
    return normalized == 'fiyat lordu' || normalized == 'radar efsanesi';
  }

  Color get _resolvedColor => widget.levelColor ?? _style.badgeBorder;

  IconData get _resolvedIcon => widget.leadingIcon ?? _style.icon;

  @override
  void initState() {
    super.initState();
    _style = EliteLevelEngine.getLevelStyle(
      EliteLevelEngine.parseLevelLabel(widget.levelName),
    );
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );
    if (_resolvedPulse) {
      _controller.repeat(reverse: true);
    }
  }

  @override
  void didUpdateWidget(covariant GlobalPremiumBadge oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.levelName != widget.levelName) {
      _style = EliteLevelEngine.getLevelStyle(
        EliteLevelEngine.parseLevelLabel(widget.levelName),
      );
    }

    if (_resolvedPulse) {
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
    if (!_resolvedPulse) {
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
        border: Border.all(color: _resolvedColor, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: _resolvedColor.withOpacity(0.5),
            blurRadius: blurRadius,
            spreadRadius: spreadRadius,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(_resolvedIcon, color: _resolvedColor, size: 21),
          const SizedBox(width: 8),
          Text(
            (widget.userName ?? widget.levelName).trim(),
            style: TextStyle(
              color: _resolvedColor,
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
