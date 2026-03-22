import 'package:flutter/material.dart';

import '../theme/fr_colors.dart';
import 'app_network_image.dart';
import 'premium_pressable.dart';

class LuxProductCard extends StatelessWidget {
  const LuxProductCard({
    super.key,
    required this.brand,
    required this.title,
    required this.priceLabel,
    required this.imageUrl,
    required this.storeName,
    required this.onTap,
    this.badgeLabel,
    this.badgeColor,
    this.badgeBackgroundColor,
    this.badgeIcon,
    this.storeColor,
    this.isFavorite = false,
    this.backgroundColor = Colors.white,
    this.imageBackgroundColor = const Color(0xFFF3EBE4),
    this.footerTrailing,
  });

  final String brand;
  final String title;
  final String priceLabel;
  final String? imageUrl;
  final String storeName;
  final VoidCallback onTap;
  final String? badgeLabel;
  final Color? badgeColor;
  final Color? badgeBackgroundColor;
  final IconData? badgeIcon;
  final Color? storeColor;
  final bool isFavorite;
  final Color backgroundColor;
  final Color imageBackgroundColor;
  final Widget? footerTrailing;

  @override
  Widget build(BuildContext context) {
    final resolvedBadgeColor = badgeColor ?? FRColors.success;
    final resolvedBadgeBackgroundColor =
        badgeBackgroundColor ?? resolvedBadgeColor.withOpacity(0.12);

    return PremiumPressable(
      onTap: onTap,
      borderRadius: BorderRadius.circular(22),
      child: Container(
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(22),
          boxShadow: const [
            BoxShadow(
              color: Color(0x171C1108),
              blurRadius: 14,
              offset: Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              height: 124,
              decoration: BoxDecoration(
                color: imageBackgroundColor,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(22)),
              ),
              child: Stack(
                children: [
                  if (badgeLabel != null && badgeLabel!.trim().isNotEmpty)
                    Positioned(
                      top: 9,
                      left: 9,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: resolvedBadgeBackgroundColor,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (badgeIcon != null) ...[
                              Icon(badgeIcon, size: 11, color: resolvedBadgeColor),
                              const SizedBox(width: 3),
                            ],
                            Text(
                              badgeLabel!,
                              style: TextStyle(
                                fontSize: 9,
                                fontWeight: FontWeight.w900,
                                color: resolvedBadgeColor,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  Positioned(
                    top: 9,
                    right: 9,
                    child: Container(
                      width: 28,
                      height: 28,
                      decoration: const BoxDecoration(
                        color: Color(0xF2FFFFFF),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Color(0x1F1C1108),
                            blurRadius: 8,
                            offset: Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Icon(
                        isFavorite ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                        size: 15,
                        color: isFavorite ? FRColors.danger : FRColors.textMuted,
                      ),
                    ),
                  ),
                  Positioned.fill(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(8, 12, 8, 8),
                      child: AppNetworkImage(
                        imageUrl: imageUrl,
                        cacheKey: 'lux_card_${storeName}_$title',
                        fit: BoxFit.contain,
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(13, 11, 13, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    brand.trim().isEmpty ? 'MARKA' : brand.toUpperCase(),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFFBF9470),
                      letterSpacing: 0.2,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      color: FRColors.espressoSoft,
                      height: 1.3,
                    ),
                  ),
                  const SizedBox(height: 5),
                  ShaderMask(
                    shaderCallback: (bounds) => const LinearGradient(
                      colors: [
                        FRColors.espressoSoft,
                        Color(0xFFBF9470),
                        FRColors.espressoSoft,
                      ],
                    ).createShader(bounds),
                    child: Text(
                      priceLabel,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const Spacer(),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 9),
              decoration: BoxDecoration(
                border: Border(top: BorderSide(color: FRColors.espresso.withOpacity(0.07))),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Row(
                      children: [
                        Container(
                          width: 7,
                          height: 7,
                          decoration: BoxDecoration(
                            color: storeColor ?? FRColors.camelStrong,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            storeName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF5E4A38),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (footerTrailing != null) ...[
                    const SizedBox(width: 6),
                    footerTrailing!,
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
