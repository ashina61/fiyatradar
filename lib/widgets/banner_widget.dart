import 'dart:async';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// Kendi projendeki doğru yolları (path) buraya yaz kanka
import '../models/banner_model.dart';
import '../providers/banner_provider.dart';
import '../theme/fr_colors.dart';

class PremiumBannerSection extends ConsumerStatefulWidget {
  const PremiumBannerSection({super.key, this.onBannerTap});
  final void Function(BannerModel banner)? onBannerTap;

  @override
  ConsumerState<PremiumBannerSection> createState() => _PremiumBannerSectionState();
}

class _PremiumBannerSectionState extends ConsumerState<PremiumBannerSection> {
  final PageController _pageController = PageController(viewportFraction: 1.0);
  Timer? _timer;
  int _currentPage = 0;

  @override
  void initState() {
    super.initState();
    // Bannerlar arası 5 saniyede bir otomatik geçiş
    _timer = Timer.periodic(const Duration(seconds: 5), (timer) {
      final banners = ref.read(activeBannersProvider).valueOrNull ?? [];
      final activeBanners = banners.where((b) => b.isActive).toList();
      if (activeBanners.length < 2 || !_pageController.hasClients) return;
      
      final next = (_currentPage + 1) % activeBanners.length;
      _pageController.animateToPage(
        next, 
        duration: const Duration(milliseconds: 500), 
        curve: Curves.easeOutQuart,
      );
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bannersAsync = ref.watch(activeBannersProvider);

    return bannersAsync.when(
      data: (banners) {
        final activeBanners = banners.where((b) => b.isActive).toList();
        if (activeBanners.isEmpty) return const SizedBox.shrink();

        return Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
          child: SizedBox(
            height: 190, // Tasarımın jilet gibi oturacağı ideal yükseklik
            child: PageView.builder(
              controller: _pageController,
              itemCount: activeBanners.length,
              onPageChanged: (index) => setState(() => _currentPage = index),
              itemBuilder: (context, index) {
                final banner = activeBanners[index];
                return Padding(
                  padding: EdgeInsets.only(right: activeBanners.length > 1 ? 8.0 : 0),
                  child: _PorscheBannerCard(
                    banner: banner,
                    onTap: () => widget.onBannerTap?.call(banner),
                  ),
                );
              },
            ),
          ),
        );
      },
      loading: () => const Padding(
        padding: EdgeInsets.fromLTRB(20, 16, 20, 0),
        child: SizedBox(
          height: 190, 
          child: Center(child: CircularProgressIndicator(color: FRColors.camel)),
        ),
      ),
      error: (_, __) => const SizedBox.shrink(),
    );
  }
}

class _PorscheBannerCard extends StatelessWidget {
  final BannerModel banner;
  final VoidCallback? onTap;

  const _PorscheBannerCard({required this.banner, this.onTap});

  @override
  Widget build(BuildContext context) {
    final hasImage = banner.imageUrl != null && banner.imageUrl!.isNotEmpty;
    // Modelinde isSponsor bool yoksa burayı false yap geç
    final isSponsor = banner.isSponsor ?? false; 
    

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        // HATA 1 ÇÖZÜMÜ: Köşe sızmalarını engeller
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          color: FRColors.espresso,
          borderRadius: BorderRadius.circular(28),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 24,
              offset: const Offset(0, 12),
            ),
          ],
        ),
        child: Stack(
          children: [
            // 1. Resim Katmanı
            if (hasImage)
              Positioned.fill(
                child: CachedNetworkImage(
                  imageUrl: banner.imageUrl!,
                  fit: BoxFit.cover,
                  errorWidget: (context, url, error) => const SizedBox.shrink(),
                ),
              ),

            // 2. Linear Gradient (Soldan sağa kararır, yazıları öne çıkarır)
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      FRColors.espresso.withOpacity(0.95),
                      FRColors.espresso.withOpacity(hasImage ? 0.3 : 0.95),
                    ],
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                  ),
                ),
              ),
            ),

            // 3. Sağ Üst Radial Parlama
            Positioned(
              top: -60,
              right: -40,
              child: Container(
                width: 200,
                height: 200,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      FRColors.camel.withOpacity(0.35),
                      Colors.transparent,
                    ],
                    stops: const [0.0, 0.7],
                  ),
                ),
              ),
            ),

            // 4. İçerik Katmanı
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                // HATA 2 ÇÖZÜMÜ: Butonu dibe itmez, yazının peşinden sürükler
                mainAxisSize: MainAxisSize.min, 
                children: [
                  // Dinamik Rozet
                  if (banner.badgeText != null && banner.badgeText!.isNotEmpty)
                    Container(
                      margin: const EdgeInsets.bottom: 10,
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: isSponsor ? FRColors.camel.withOpacity(0.25) : FRColors.camel.withOpacity(0.15),
                        border: Border.all(
                          color: isSponsor ? FRColors.camel : FRColors.camel.withOpacity(0.3),
                        ),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (isSponsor)
                            const Icon(Icons.star, color: FRColors.ivory, size: 12)
                          else
                            Container(
                              width: 6, height: 6,
                              decoration: const BoxDecoration(
                                color: FRColors.camel,
                                shape: BoxShape.circle,
                              ),
                            ),
                          const SizedBox(width: 6),
                          Text(
                            banner.badgeText!.toUpperCase(),
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                              color: isSponsor ? FRColors.ivory : FRColors.camel,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ],
                      ),
                    ),

                  // Başlık
                  Text(
                    banner.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                      color: FRColors.white,
                      height: 1.2,
                      letterSpacing: -0.5,
                    ),
                  ),

                  // Açıklama
                  if (banner.description != null && banner.description!.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Text(
                      banner.description!,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: Colors.white.withOpacity(0.6),
                        height: 1.4,
                      ),
                    ),
                  ],

                  const SizedBox(height: 14),

                  // Lüks Buton
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        (banner.ctaText ?? 'KEŞFET').toUpperCase(),
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                          color: FRColors.camel,
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        width: 28, height: 28,
                        decoration: BoxDecoration(
                          color: FRColors.camel,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: FRColors.camel.withOpacity(0.3),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.arrow_forward,
                          color: FRColors.espresso,
                          size: 16,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
