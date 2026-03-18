import 'dart:async';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../screens/campaign/campaign_detail_screen.dart';

import '../models/banner_model.dart';
import '../providers/banner_provider.dart';
import '../theme/fr_colors.dart';

class PremiumBannerSection extends ConsumerStatefulWidget {
  const PremiumBannerSection({super.key});
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
    _timer = Timer.periodic(const Duration(seconds: 5), (timer) {
      final banners = ref.read(bannersProvider).valueOrNull ?? [];
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
    final bannersAsync = ref.watch(bannersProvider);

    return bannersAsync.when(
      data: (banners) {
        final activeBanners = banners.where((b) => b.isActive).toList();
        if (activeBanners.isEmpty) return const SizedBox.shrink();

        return Padding(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
          child: SizedBox(
            height: 190,
            child: PageView.builder(
              controller: _pageController,
              itemCount: activeBanners.length,
              onPageChanged: (index) => setState(() => _currentPage = index),
              itemBuilder: (context, index) {
                final banner = activeBanners[index];
                return Padding(
                  padding: EdgeInsets.only(right: activeBanners.length > 1 ? 8.0 : 0),
                  child: _PorscheBannerCard(banner: banner),
                );
              },
            ),
          ),
        );
      },
      loading: () => const SizedBox(
        height: 190,
        child: Center(
          child: CircularProgressIndicator(color: FRColors.camel),
        ),
      ),
      error: (_, __) => const SizedBox.shrink(),
    );
  }
}

class _PorscheBannerCard extends StatelessWidget {
  final BannerModel banner;

  const _PorscheBannerCard({required this.banner});

  Future<void> _handleTap(BuildContext context) async {
    final targetType = (banner.targetType ?? '').trim();
    final targetId = (banner.targetId ?? '').trim();
    if ((targetType == 'campaign' || targetType == 'weekly_event') && targetId.isNotEmpty) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => CampaignDetailScreen(campaignId: targetId)),
      );
      return;
    }

    final linkUrl = (banner.linkUrl ?? '').trim();
    if (linkUrl.isEmpty) return;
    final url = Uri.tryParse(linkUrl);
    if (url == null) return;
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    final hasImage = banner.imageUrl != null && banner.imageUrl!.isNotEmpty;
    final isSponsor = banner.isSponsor;

    return GestureDetector(
      onTap: () => _handleTap(context),
      child: Container(
        width: double.infinity,
        child: PhysicalShape(
          color: FRColors.espresso,
          clipper: ShapeBorderClipper(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
          ),
          elevation: 20,
          shadowColor: Colors.black.withOpacity(0.15),
          clipBehavior: Clip.antiAliasWithSaveLayer,
          child: Stack(
            children: [
              if (hasImage)
                Positioned.fill(
                  child: CachedNetworkImage(
                    imageUrl: banner.imageUrl!,
                    fit: BoxFit.cover,
                    errorWidget: (c, u, e) => const SizedBox.shrink(),
                  ),
                ),
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
              Positioned(
                top: -60,
                right: -40,
                child: Container(
                  width: 200,
                  height: 200,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [FRColors.camel.withOpacity(0.35), Colors.transparent],
                      stops: const [0.0, 0.7],
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (banner.badgeText != null && banner.badgeText!.isNotEmpty)
                      Container(
                        margin: const EdgeInsets.only(bottom: 10),
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: isSponsor ? FRColors.camel.withOpacity(0.25) : FRColors.camel.withOpacity(0.15),
                          border: Border.all(color: isSponsor ? FRColors.camel : FRColors.camel.withOpacity(0.3)),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (isSponsor)
                              const Icon(Icons.star, color: FRColors.ivory, size: 12)
                            else
                              Container(
                                width: 6,
                                height: 6,
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
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          banner.buttonText.toUpperCase(),
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w800,
                            color: FRColors.camel,
                            letterSpacing: 0.5,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          width: 28,
                          height: 28,
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
                          child: const Icon(Icons.arrow_forward, color: FRColors.espresso, size: 16),
                        ),
                      ],
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
