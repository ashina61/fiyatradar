import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../models/product_model.dart';
import '../../theme/fr_colors.dart';
import '../../utils/formatters.dart';
import 'market_badge.dart';
import 'premium_pressable.dart';

class HomeProductCard extends StatelessWidget {
  final ProductModel product;
  final VoidCallback onTap;
  final double width;
  final bool showStore;
  final Widget? bottomSection;

  const HomeProductCard({
    super.key,
    required this.product,
    required this.onTap,
    this.width = 155,
    this.showStore = true,
    this.bottomSection,
  });

  Future<void> _openAffiliateLink() async {
    final rawUrl = product.preferredAffiliateUrl?.trim();
    if (rawUrl == null || rawUrl.isEmpty) return;
    final uri = Uri.tryParse(rawUrl);
    if (uri == null) return;
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  @override
  Widget build(BuildContext context) {
    // Veritabanından gelen gerçek veriler
    final title = product.name;
    final brand = (product.brand ?? 'MARKA').toUpperCase();
    final priceStr =
        product.lastPrice != null ? formatTRY(product.lastPrice!) : '---';
    
    // Gerçek projede modelden hesaplanacak değerler
    final isDrop = true; 
    final marketName = (product.lastStore ?? "").trim().isNotEmpty ? product.lastStore!.trim() : "Market bilgisi yok"; 
    final affiliateUrl = product.preferredAffiliateUrl;

    return PremiumPressable(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        width: width,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04), 
              blurRadius: 10, 
              offset: const Offset(0, 4)
            )
          ],
        ),
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. Resim Stüdyosu (TAŞMA İMKANSIZ)
            Stack(
              children: [
                Container(
                  height: 110,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF3EBE4), // Nutella arkasındaki bej
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0), // Resim sınırları
                    child: CachedNetworkImage(
                      imageUrl: product.imageUrl ?? '',
                      fit: BoxFit.contain,
                      colorBlendMode: BlendMode.multiply,
                      color: Colors.white.withOpacity(0.01),
                      errorWidget: (_, __, ___) => const Icon(Icons.image_not_supported, color: Colors.grey),
                    ),
                  ),
                ),
                // Trend Rozeti
                Positioned(
                  top: 8, left: 8,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                    decoration: BoxDecoration(
                      color: isDrop ? const Color(0xFFE8F5E9) : const Color(0xFFFFEBEE), 
                      borderRadius: BorderRadius.circular(6)
                    ),
                    child: Row(
                      children: [
                        Icon(isDrop ? Icons.south_east_rounded : Icons.north_east_rounded, 
                             color: isDrop ? const Color(0xFF2E7D32) : const Color(0xFFC62828), size: 10),
                        const SizedBox(width: 2),
                        Text('%18', style: TextStyle(color: isDrop ? const Color(0xFF2E7D32) : const Color(0xFFC62828), fontSize: 9, fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ),
                ),
                // Kalp İkonu
                const Positioned(
                  top: 8, right: 8,
                  child: Icon(Icons.favorite_border, color: Colors.grey, size: 18),
                ),
              ],
            ),
            const SizedBox(height: 12),
            
            // 2. Metinler
            Text(brand, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey, letterSpacing: 0.5), maxLines: 1, overflow: TextOverflow.ellipsis),
            const SizedBox(height: 4),
            Text(title, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF2A1A10), height: 1.2)),
            const Spacer(),
            
            // 3. Fiyat ve Market (RESİMDEKİ BİREBİR YAPI)
            if (bottomSection != null)
              bottomSection!
            else
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Ort: 40,00₺', style: TextStyle(fontSize: 10, color: Colors.grey, decoration: TextDecoration.lineThrough)),
                      Text(priceStr, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF2A1A10))),
                    ],
                  ),
                  if (showStore)
                    Flexible(
                      child: Align(
                        alignment: Alignment.bottomRight,
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          alignment: Alignment.centerRight,
                          child: MarketBadge(
                            label: marketName,
                            compact: true,
                            onTap: affiliateUrl == null ? null : _openAffiliateLink,
                          ),
                        ),
                      ),
                    )
                ],
              )
          ],
        ),
      ),
    );
  }
}
