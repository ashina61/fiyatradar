import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../models/product_model.dart';
import '../theme/fr_colors.dart';
import '../utils/formatters.dart';
import 'lux_product_card.dart';

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
    final marketName = (product.lastStore ?? '').trim().isNotEmpty
        ? product.lastStore!.trim()
        : 'Mağaza bilgisi yok';
    final badgeValue = trendPercent?.abs().round();

    return SizedBox(
      width: width,
      child: LuxProductCard(
        brand: product.brand,
        title: product.name,
        priceLabel: hasPrice ? formatTRY(product.lastPrice ?? 0) : 'Fiyat bekleniyor',
        imageUrl: product.effectiveImage,
        storeName: showStore ? marketName : 'Fiyat Radar',
        storeColor: _storeColor(marketName),
        badgeLabel: badgeValue == null || badgeValue == 0 ? null : '%$badgeValue',
        badgeColor: isPriceRising ? FRColors.danger : FRColors.success,
        badgeBackgroundColor: (isPriceRising ? FRColors.danger : FRColors.success)
            .withOpacity(isPriceRising ? 0.10 : 0.12),
        badgeIcon: isPriceRising ? Icons.south_east_rounded : Icons.north_east_rounded,
        isFavorite: isSaved,
        onTap: onTap,
        footerTrailing: showStore && product.preferredAffiliateUrl != null
            ? GestureDetector(
                onTap: _openAffiliateLink,
                child: const Icon(
                  Icons.open_in_new_rounded,
                  size: 13,
                  color: FRColors.textMuted,
                ),
              )
            : null,
      ),
    );
  }
}

Color _storeColor(String storeName) {
  final normalized = storeName.trim().toLowerCase();
  if (normalized.contains('migros')) return const Color(0xFFFF8A00);
  if (normalized.contains('a101')) return const Color(0xFF1565C0);
  if (normalized.contains('bim')) return const Color(0xFFE53935);
  if (normalized.contains('şok') || normalized.contains('sok')) return const Color(0xFF7B1FA2);
  if (normalized.contains('carrefour')) return const Color(0xFF0097A7);
  if (normalized.contains('trendyol')) return const Color(0xFFF57C00);
  return FRColors.camelStrong;
}
