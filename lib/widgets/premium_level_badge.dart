import 'package:flutter/material.dart';

class PremiumLevelBadge extends StatefulWidget {
  const PremiumLevelBadge({
    super.key,
    required this.levelName,
    this.displayText,
    this.showVerifiedIcon = false,
  });

  final String levelName;
  final String? displayText;
  final bool showVerifiedIcon;

  @override
  State<PremiumLevelBadge> createState() => _PremiumLevelBadgeState();
}

class _PremiumLevelBadgeState extends State<PremiumLevelBadge>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  _PremiumBadgeLevelInfo get levelInfo => _resolveLevelInfo();

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    );
    _animation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );

    if (levelInfo.hasPulseAnimation) {
      _controller.repeat(reverse: true);
    }
  }

  @override
  void didUpdateWidget(covariant PremiumLevelBadge oldWidget) {
    super.didUpdateWidget(oldWidget);

    final shouldAnimate = levelInfo.hasPulseAnimation;
    if (shouldAnimate) {
      if (!_controller.isAnimating) {
        _controller.repeat(reverse: true);
      }
    } else {
      _controller.stop();
      _controller.value = 0.0;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final info = levelInfo;
    final resolvedText = (widget.displayText?.trim().isNotEmpty == true)
        ? widget.displayText!.trim()
        : info.levelName;

    // 1. Rozetin ortak içeriği
    final Widget badgeLabel = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(info.icon, color: info.contentColor, size: 20),
        const SizedBox(width: 6),
        Text(
          resolvedText,
          style: TextStyle(
            color: info.contentColor,
            fontWeight: FontWeight.w900,
            fontSize: 14,
          ),
        ),
        if (widget.showVerifiedIcon) ...[
          const SizedBox(width: 6),
          Icon(
            Icons.verified_rounded,
            size: 14,
            color: info.contentColor,
          ),
        ],
      ],
    );

    // 2. Ortak kenarlık ve arka plan stili
    final BoxDecoration baseDecoration = BoxDecoration(
      color: info.levelColor.withOpacity(0.1),
      borderRadius: BorderRadius.circular(50),
      border: Border.all(
        color: info.levelColor.withOpacity(0.8),
        width: 1.5,
      ),
    );

    // 3. Duruma göre render
    if (info.hasPulseAnimation) {
      // Lord / Efsane gibi animasyonlu seviyeler
      return AnimatedBuilder(
        animation: _animation,
        builder: (context, child) {
          final double pulse = _animation.value;
          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: baseDecoration.copyWith(
              boxShadow: [
                BoxShadow(
                  color: info.levelColor.withOpacity(0.2 + (pulse * 0.4)),
                  blurRadius: 8.0 + (pulse * 15.0),
                  spreadRadius: 1.0 + (pulse * 4.0),
                ),
              ],
            ),
            child: child,
          );
        },
        child: badgeLabel,
      );
    }

    // Gözlemci / Avcı gibi statik seviyeler
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: baseDecoration,
      child: badgeLabel,
    );
  }

  _PremiumBadgeLevelInfo _resolveLevelInfo() {
    switch (widget.levelName.trim()) {
      case 'Avcı':
        return const _PremiumBadgeLevelInfo(
          levelName: 'Avcı',
          levelColor: Color(0xFFF4511E),
          contentColor: Color(0xFFF4511E),
          icon: Icons.gps_fixed_rounded,
        );
      case 'Tasarrufçu':
        return const _PremiumBadgeLevelInfo(
          levelName: 'Tasarrufçu',
          levelColor: Color(0xFF1E88E5),
          contentColor: Color(0xFF1E88E5),
          icon: Icons.savings_rounded,
        );
      case 'Market Ustası':
        return const _PremiumBadgeLevelInfo(
          levelName: 'Market Ustası',
          levelColor: Color(0xFFFFB300),
          contentColor: Color(0xFFFFB300),
          icon: Icons.storefront_rounded,
        );
      case 'Fiyat Lordu':
        return const _PremiumBadgeLevelInfo(
          levelName: 'Fiyat Lordu',
          levelColor: Color(0xFFE040FB),
          contentColor: Color(0xFFE040FB),
          icon: Icons.workspace_premium_rounded,
          hasPulseAnimation: true,
        );
      case 'Radar Efsanesi':
        return const _PremiumBadgeLevelInfo(
          levelName: 'Radar Efsanesi',
          levelColor: Color(0xFF00E5FF),
          contentColor: Color(0xFF0097A7),
          icon: Icons.diamond_rounded,
          hasPulseAnimation: true,
        );
      case 'Gözlemci':
      default:
        return const _PremiumBadgeLevelInfo(
          levelName: 'Gözlemci',
          levelColor: Color(0xFF8C7A6B),
          contentColor: Color(0xFF8C7A6B),
          icon: Icons.visibility_rounded,
        );
    }
  }
}

class _PremiumBadgeLevelInfo {
  const _PremiumBadgeLevelInfo({
    required this.levelName,
    required this.levelColor,
    required this.contentColor,
    required this.icon,
    this.hasPulseAnimation = false,
  });

  final String levelName;
  final Color levelColor;
  final Color contentColor;
  final IconData icon;
  final bool hasPulseAnimation;
}
