import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../models/product_model.dart';
import '../theme/fr_colors.dart';
import '../utils/formatters.dart';

class HomeProductCard extends StatelessWidget {
  const HomeProductCard({
    super.key,
    required this.product,
    required this.onTap,
    this.width = 174,
    this.showStore = true,
    this.trendPercent,
    this.isPriceRising = false,
    this.isSaved = false,
  });

  final ProductModel product;
  final VoidCallback onTap;
  final double width;
  final bool showStore;
  final double? trendPercent;
  final bool isPriceRising;
  final bool isSaved;

  Future<void> _openAffiliateLink() async {
    final rawUrl = product.preferredAffiliateUrl?.trim();
    if (rawUrl == null || rawUrl.isEmpty) return;
    final uri = Uri.tryParse(rawUrl);
    if (uri == null) return;
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  @override
  Widget build(BuildContext context) {
    final hasPrice = (product.lastPrice ?? 0) > 0;
    final marketName = (product.lastStore ?? '').trim().isNotEmpty ? product.lastStore!.trim() : 'Market';
    final badgeValue = trendPercent?.abs().round() ?? 0;
    final imageUrl = product.effectiveImage;

    return SizedBox(
      width: width,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          decoration: BoxDecoration(
            color: FRColors.surface,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: FRColors.borderLight),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                height: 150,
                decoration: const BoxDecoration(
                  color: Color(0xFFF8F4EE),
                  borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
                ),
                child: Stack(
                  children: [
                    Positioned.fill(
                      child: Padding(
                        padding: const EdgeInsets.all(14),
                        child: imageUrl == null || imageUrl.isEmpty
                            ? const Icon(Icons.inventory_2_rounded, color: FRColors.textMuted, size: 54)
                            : Image.network(
                                imageUrl,
                                fit: BoxFit.contain,
                                errorBuilder: (_, __, ___) => const Icon(Icons.broken_image_rounded, color: FRColors.textMuted, size: 42),
                              ),
                      ),
                    ),
                    Positioned(
                      top: 8,
                      left: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: (isPriceRising ? FRColors.danger : FRColors.success).withOpacity(0.12),
                          borderRadius: BorderRadius.circular(9),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              isPriceRising ? Icons.arrow_upward_rounded : Icons.arrow_downward_rounded,
                              size: 10,
                              color: isPriceRising ? FRColors.danger : FRColors.success,
                            ),
                            if (badgeValue > 0) ...[
                              const SizedBox(width: 3),
                              Text(
                                '%$badgeValue',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                  color: isPriceRising ? FRColors.danger : FRColors.success,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                    Positioned(
                      top: 8,
                      right: 8,
                      child: Icon(
                        isSaved ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                        size: 16,
                        color: isSaved ? FRColors.danger : FRColors.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(10, 9, 10, 6),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(product.brand.toUpperCase(), maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: FRColors.camelStrong)),
                    const SizedBox(height: 3),
                    Text(product.name, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: FRColors.textPrimary)),
                    const SizedBox(height: 4),
                    Text(hasPrice ? formatTRY(product.lastPrice ?? 0) : 'Fiyat bekleniyor', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: FRColors.textPrimary)),
                  ],
                ),
              ),
              const Spacer(),
              if (showStore)
                Padding(
                  padding: const EdgeInsets.fromLTRB(10, 0, 10, 10),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(marketName, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: FRColors.textMuted)),
                      ),
                      if (product.preferredAffiliateUrl != null)
                        InkWell(
                          onTap: _openAffiliateLink,
                          child: const Padding(
                            padding: EdgeInsets.only(left: 4),
                            child: Icon(Icons.open_in_new_rounded, size: 13, color: FRColors.textMuted),
                          ),
                        ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
