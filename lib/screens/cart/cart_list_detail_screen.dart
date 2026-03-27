import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../models/special_list_item_model.dart';
import '../../models/special_list_model.dart';
import '../../providers/special_list_provider.dart';
import '../../theme/fr_colors.dart';
import '../../utils/formatters.dart';
import '../../widgets/staggered_fade_slide.dart';

class CartListDetailScreen extends ConsumerWidget {
  const CartListDetailScreen({
    super.key,
    required this.listId,
    this.onBack,
    this.onShare,
  });

  final String listId;
  final VoidCallback? onBack;
  final VoidCallback? onShare;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final detailState = ref.watch(specialListDetailProvider(listId));

    return Scaffold(
      backgroundColor: const Color(0xFFEDEAE3),
      body: SafeArea(
        bottom: false,
        child: detailState.list.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (_, __) => _StatusState(
            title: 'Bir hata oluştu',
            subtitle: 'Liste verisi yüklenirken bir sorun oluştu. Lütfen tekrar deneyin.',
          ),
          data: (list) {
            if (list == null || !list.isActive) {
              return const _StatusState(
                title: 'Liste bulunamadı',
                subtitle: 'Bu liste kaldırılmış olabilir veya artık aktif değil.',
              );
            }
            return _Content(
              list: list,
              itemsAsync: detailState.items,
              onBack: onBack ?? () => Navigator.of(context).maybePop(),
              onShare: onShare,
              onCtaTap: () => _handleCtaAction(context, list),
            );
          },
        ),
      ),
    );
  }

  void _handleCtaAction(BuildContext context, SpecialListModel list) {
    switch (list.ctaActionType) {
      case SpecialListCtaActionType.compareCart:
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Sepet kıyaslama yakında açılıyor.')));
        break;
      case SpecialListCtaActionType.none:
        break;
      case SpecialListCtaActionType.openProductList:
      case SpecialListCtaActionType.openCampaign:
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Bu aksiyon henüz desteklenmiyor.')));
        break;
    }
  }
}

class _Content extends StatelessWidget {
  const _Content({
    required this.list,
    required this.itemsAsync,
    required this.onBack,
    this.onShare,
    required this.onCtaTap,
  });

  final SpecialListModel list;
  final AsyncValue<List<SpecialListItemModel>> itemsAsync;
  final VoidCallback onBack;
  final VoidCallback? onShare;
  final VoidCallback onCtaTap;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 120),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _TopBar(title: list.title, onBack: onBack, onShare: onShare),
              const SizedBox(height: 10),
              StaggeredFadeSlide(index: 0, offsetY: 14, child: _SummaryCard(data: list)),
              const SizedBox(height: 24),
              itemsAsync.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (_, __) => const _StatusState(
                  title: 'Ürünler yüklenemedi',
                  subtitle: 'Lütfen daha sonra tekrar deneyin.',
                ),
                data: (items) {
                  if (items.isEmpty) {
                    return const _StatusState(
                      title: 'Bu listede ürün yok',
                      subtitle: 'Admin panelinden ürün eklenince burada görünecek.',
                    );
                  }
                  return Column(
                    children: [
                      _ListHeader(itemCount: items.length),
                      const SizedBox(height: 12),
                      for (var i = 0; i < items.length; i++)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: StaggeredFadeSlide(
                            index: i + 1,
                            offsetY: 12,
                            baseDelayMs: 80,
                            stepDelayMs: 80,
                            child: _BasketItemRow(item: items[i]),
                          ),
                        ),
                    ],
                  );
                },
              ),
            ],
          ),
        ),
        Positioned(
          left: 20,
          right: 20,
          bottom: 24,
          child: SafeArea(
            top: false,
            child: _BottomCompareButton(
              text: list.ctaText.trim().isEmpty ? 'Devam Et' : list.ctaText,
              onTap: itemsAsync.valueOrNull?.isEmpty == true || list.ctaActionType == SpecialListCtaActionType.none
                  ? null
                  : onCtaTap,
            ),
          ),
        ),
      ],
    );
  }
}

class _TopBar extends StatelessWidget {
  const _TopBar({required this.title, required this.onBack, this.onShare});

  final String title;
  final VoidCallback onBack;
  final VoidCallback? onShare;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 8, 4, 0),
      child: Row(
        children: [
          _IconButtonShell(icon: Icons.chevron_left_rounded, onTap: onBack, iconSize: 24),
          Expanded(
            child: Text(
              title.trim().isEmpty ? 'Liste Detayı' : title,
              textAlign: TextAlign.center,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: const Color(0xFF18100A),
              ),
            ),
          ),
          _IconButtonShell(icon: Icons.share_outlined, onTap: onShare, iconSize: 18),
        ],
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({required this.data});

  final SpecialListModel data;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF18100A), Color(0xFF2A1A0B)],
        ),
        boxShadow: [
          BoxShadow(
            color: FRColors.espresso.withOpacity(0.20),
            blurRadius: 30,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Stack(
          children: [
            Positioned(
              right: -30,
              top: -30,
              child: Container(
                width: 150,
                height: 150,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [FRColors.camel.withOpacity(0.2), Colors.transparent],
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: FRColors.camel.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: FRColors.camel.withOpacity(0.30)),
                    ),
                    child: Text(
                      data.badgeText,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 10,
                        color: FRColors.camel,
                        fontWeight: FontWeight.w800,
                        letterSpacing: .5,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    data.heroTitle,
                    style: GoogleFonts.dmSerifDisplay(
                      fontSize: 24,
                      height: 1.1,
                      color: FRColors.white,
                      letterSpacing: -.5,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    data.description,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: FRColors.white.withOpacity(0.6),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: FRColors.white.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: FRColors.white.withOpacity(0.10)),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'En İyi Eşleşme (Toplam)',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: FRColors.white.withOpacity(0.60),
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                formatTRY(data.totalPrice, keepTrailingZeros: true),
                                style: GoogleFonts.dmSerifDisplay(
                                  fontSize: 32,
                                  height: 1,
                                  color: FRColors.white,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: const Color(0xFF27A85A).withOpacity(0.15),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                '${formatTRY(data.savingsAmount, keepTrailingZeros: false)} ${data.savingsLabel}'.trim(),
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w800,
                                  color: const Color(0xFF1E8E3E),
                                ),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${data.bestMarketName} Sepeti ile',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                                color: FRColors.white.withOpacity(0.5),
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
          ],
        ),
      ),
    );
  }
}

class _ListHeader extends StatelessWidget {
  const _ListHeader({required this.itemCount});

  final int itemCount;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          'Sepet İçeriği',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 16,
            fontWeight: FontWeight.w800,
            color: const Color(0xFF18100A),
          ),
        ),
        const Spacer(),
        Text(
          '$itemCount Ürün',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: FRColors.camel,
          ),
        ),
      ],
    );
  }
}

class _BasketItemRow extends StatelessWidget {
  const _BasketItemRow({required this.item});

  final SpecialListItemModel item;

  @override
  Widget build(BuildContext context) {
    final tags = [if (item.quantityLabel.trim().isNotEmpty) item.quantityLabel, if (item.tagLabel.trim().isNotEmpty) item.tagLabel];

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFFAFAF8),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0x1418100A)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x05000000),
            blurRadius: 12,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 56,
            height: 56,
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: const Color(0xFFF8F4EE),
              borderRadius: BorderRadius.circular(12),
            ),
            child: item.productImageUrlSnapshot?.isNotEmpty == true
                ? Image.network(
                    item.productImageUrlSnapshot!,
                    fit: BoxFit.contain,
                    filterQuality: FilterQuality.medium,
                    errorBuilder: (_, __, ___) => const Icon(Icons.image_not_supported_outlined),
                  )
                : const Icon(Icons.inventory_2_outlined),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.productBrandSnapshot,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 9,
                    height: 1,
                    color: FRColors.camel,
                    fontWeight: FontWeight.w900,
                    letterSpacing: .5,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  item.productNameSnapshot,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF18100A),
                    height: 1.2,
                  ),
                ),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 6,
                  runSpacing: 4,
                  children: [
                    for (final tag in tags)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: const Color(0xFFEDEAE3),
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(color: const Color(0x1418100A)),
                        ),
                        child: Text(
                          tag,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 9,
                            fontWeight: FontWeight.w800,
                            color: const Color(0xFF5E4A38),
                          ),
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                formatTRY(item.selectedPrice, keepTrailingZeros: true),
                style: GoogleFonts.dmSerifDisplay(
                  fontSize: 18,
                  height: 1,
                  color: const Color(0xFF18100A),
                ),
              ),
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0x0D18100A),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      decoration: BoxDecoration(color: item.marketColor, shape: BoxShape.circle),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      item.selectedStoreNameSnapshot,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        color: const Color(0xFF18100A),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _BottomCompareButton extends StatelessWidget {
  const _BottomCompareButton({required this.text, this.onTap});

  final String text;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: onTap == null ? 0.55 : 1,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(18),
          child: Ink(
            height: 58,
            decoration: BoxDecoration(
              color: FRColors.camel,
              borderRadius: BorderRadius.circular(18),
              boxShadow: [
                BoxShadow(
                  color: FRColors.camel.withOpacity(0.4),
                  blurRadius: 32,
                  offset: const Offset(0, 16),
                ),
              ],
            ),
            child: Center(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.shopping_cart_outlined, color: Color(0xFF18100A), size: 22),
                  const SizedBox(width: 10),
                  Text(
                    text,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: const Color(0xFF18100A),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _StatusState extends StatelessWidget {
  const _StatusState({required this.title, required this.subtitle});

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              title,
              textAlign: TextAlign.center,
              style: GoogleFonts.plusJakartaSans(fontSize: 18, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: GoogleFonts.plusJakartaSans(fontSize: 13, color: const Color(0xFF6E5A49)),
            ),
          ],
        ),
      ),
    );
  }
}

class _IconButtonShell extends StatelessWidget {
  const _IconButtonShell({
    required this.icon,
    required this.onTap,
    this.iconSize = 20,
  });

  final IconData icon;
  final VoidCallback? onTap;
  final double iconSize;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: onTap,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: const Color(0xFFFAFAF8),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0x1418100A)),
          boxShadow: const [
            BoxShadow(
              color: Color(0x08000000),
              blurRadius: 10,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: Icon(icon, size: iconSize, color: const Color(0xFF18100A)),
      ),
    );
  }
}
