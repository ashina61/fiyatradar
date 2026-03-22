import 'dart:ui' as ui;

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
            ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(22)),
              child: Container(
                height: 148,
                decoration: BoxDecoration(
                  color: imageBackgroundColor,
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(22)),
                ),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    _BlurredImageBackdrop(
                      imageUrl: imageUrl,
                      cacheKey: 'lux_card_backdrop_${storeName}_$title',
                      tintColor: imageBackgroundColor,
                    ),
                    Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.white.withOpacity(0.10),
                            imageBackgroundColor.withOpacity(0.08),
                            imageBackgroundColor.withOpacity(0.26),
                          ],
                        ),
                      ),
                    ),
                    Positioned.fill(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(14, 28, 14, 12),
                        child: Align(
                          alignment: Alignment.bottomCenter,
                          child: AppNetworkImage(
                            imageUrl: imageUrl,
                            cacheKey: 'lux_card_${storeName}_$title',
                            fit: BoxFit.contain,
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                      ),
                    ),
                    if (badgeLabel != null && badgeLabel!.trim().isNotEmpty)
                      Positioned(
                        top: 10,
                        left: 10,
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
                      top: 10,
                      right: 10,
                      child: Container(
                        width: 30,
                        height: 30,
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
                          size: 16,
                          color: isFavorite ? FRColors.danger : FRColors.textMuted,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 13, 14, 0),
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
                  const SizedBox(height: 4),
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
                  const SizedBox(height: 8),
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
                  const SizedBox(height: 10),
                ],
              ),
            ),
            const Spacer(),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
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

class _BlurredImageBackdrop extends StatelessWidget {
  const _BlurredImageBackdrop({
    required this.imageUrl,
    required this.cacheKey,
    required this.tintColor,
  });

  final String? imageUrl;
  final String cacheKey;
  final Color tintColor;

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        Transform.scale(
          scale: 1.45,
          child: AppNetworkImage(
            imageUrl: imageUrl,
            cacheKey: cacheKey,
            fit: BoxFit.cover,
            borderRadius: BorderRadius.zero,
          ),
        ),
        BackdropFilter(
          filter: ui.ImageFilter.blur(sigmaX: 18, sigmaY: 18),
          child: Container(color: tintColor.withOpacity(0.18)),
        ),
      ],
    );
  }
}
