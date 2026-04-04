import 'package:flutter/material.dart';

import '../theme/fr_colors.dart';
import 'premium_pressable.dart';

class MarketBadge extends StatelessWidget {
  const MarketBadge({
    super.key,
    required this.label,
    this.onTap,
    this.compact = false,
    this.icon = Icons.storefront_rounded,
  });

  final String label;
  final VoidCallback? onTap;
  final bool compact;
  final IconData icon;

  bool get _isInteractive => onTap != null;

  @override
  Widget build(BuildContext context) {
    final badge = Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 10 : 12,
        vertical: compact ? 6 : 7,
      ),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            FRColors.goldGlowSoft,
            FRColors.camelStrong,
          ],
        ),
        borderRadius: BorderRadius.circular(compact ? 11 : 13),
        border: Border.all(
          color: Colors.white.withOpacity(0.16),
        ),
        boxShadow: const [
          BoxShadow(
            color: FRColors.shadowMedium,
            blurRadius: 16,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: compact ? 12 : 14,
            color: FRColors.espressoSoft,
          ),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.fade,
              softWrap: false,
              style: TextStyle(
                fontSize: compact ? 10.5 : 11,
                fontWeight: FontWeight.w900,
                color: FRColors.espressoSoft,
                letterSpacing: 0.15,
                height: 1,
              ),
            ),
          ),
          if (_isInteractive) ...[
            const SizedBox(width: 6),
            Icon(
              Icons.open_in_new_rounded,
              size: compact ? 11 : 12,
              color: FRColors.espressoSoft,
            ),
          ],
        ],
      ),
    );

    if (!_isInteractive) return badge;

    return PremiumPressable(
      onTap: onTap,
      borderRadius: BorderRadius.circular(compact ? 11 : 13),
      child: badge,
    );
  }
}
