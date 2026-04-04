import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/special_list_item_model.dart';
import '../../models/special_list_model.dart';
import '../../providers/special_list_provider.dart';
import '../../theme/fr_colors.dart';
import '../../theme/fr_radius.dart';
import '../../theme/fr_spacing.dart';
import '../../theme/fr_typography.dart';
import '../../utils/formatters.dart';
import '../../widgets/staggered_fade_slide.dart';

class CartListDetailScreen extends ConsumerWidget {
  const CartListDetailScreen({
    super.key,
    required this.listId,
    this.onBack,
    this.onShare,
    this.onCompare,
  });

  final String listId;
  final VoidCallback? onBack;
  final VoidCallback? onShare;
  final VoidCallback? onCompare;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final detailState = ref.watch(specialListDetailProvider(listId));

    return Scaffold(
      backgroundColor: FRColors.backgroundWarm,
      body: SafeArea(
        bottom: false,
        child: detailState.isLoading
            ? const Center(child: CircularProgressIndicator())
            : detailState.error != null
                ? _StatusState(
                    icon: Icons.cloud_off,
                    message: 'Liste verisi alınamadı. Lütfen tekrar deneyin.',
                    onBack: onBack ?? () => Navigator.of(context).maybePop(),
                  )
                : _buildContent(context, detailState),
      ),
    );
  }

  Widget _buildContent(BuildContext context, SpecialListDetailState detailState) {
    final list = detailState.list.valueOrNull;
    final items = detailState.items.valueOrNull ?? const <SpecialListItemModel>[];

    if (list == null || !list.isActive) {
      return _StatusState(
        icon: Icons.inbox_outlined,
        message: 'Liste bulunamadı',
        onBack: onBack ?? () => Navigator.of(context).maybePop(),
      );
    }

    final ctaEnabled = items.isNotEmpty && list.ctaActionType != SpecialListCtaActionType.none;
    return Stack(
      children: [
        SingleChildScrollView(
          padding: FRSpaceInsets.fromLTRB(
            FRSpacing.lg,
            FRSpacing.smPlus,
            FRSpacing.lg,
            120,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _TopBar(
                title: list.subtitle.isNotEmpty ? list.subtitle : 'Liste Detayı',
                onBack: onBack ?? () => Navigator.of(context).maybePop(),
                onShare: onShare,
              ),
              const SizedBox(height: 10),
              StaggeredFadeSlide(index: 0, offsetY: 14, child: _SummaryCard(list: list, itemCount: items.length)),
              const SizedBox(height: 24),
              _ListHeader(itemCount: items.length),
              const SizedBox(height: 12),
              if (items.isEmpty)
                const _EmptyItemsState()
              else
                for (var i = 0; i < items.length; i++)
                  Padding(
                    padding: FRSpaceInsets.bottomSmPlus,
                    child: StaggeredFadeSlide(
                      index: i + 1,
                      offsetY: 12,
                      baseDelayMs: 80,
                      stepDelayMs: 80,
                      child: _BasketItemRow(item: items[i]),
                    ),
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
              text: list.ctaText.isEmpty ? 'Devam Et' : list.ctaText,
              enabled: ctaEnabled,
              onTap: () => _handleCta(context, list),
            ),
          ),
        ),
      ],
    );
  }

  void _handleCta(BuildContext context, SpecialListModel list) {
    switch (list.ctaActionType) {
      case SpecialListCtaActionType.compareCart:
        if (onCompare != null) {
          onCompare!.call();
          return;
        }
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Sepet kıyaslama yakında.')));
      case SpecialListCtaActionType.none:
        return;
      case SpecialListCtaActionType.openProductList:
      case SpecialListCtaActionType.openCampaign:
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Bu aksiyon henüz aktif değil.')));
    }
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
      padding: FRSpaceInsets.fromLTRB(
        FRSpacing.xs,
        FRSpacing.sm,
        FRSpacing.xs,
        0,
      ),
      child: Row(
        children: [
          _IconButtonShell(icon: Icons.chevron_left_rounded, onTap: onBack, iconSize: 24),
          Expanded(
            child: Text(
              title,
              textAlign: TextAlign.center,
              style: _t(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: FRColors.espresso,
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
  const _SummaryCard({required this.list, required this.itemCount});

  final SpecialListModel list;
  final int itemCount;

  @override
  Widget build(BuildContext context) {
    final savingText = list.savingsAmount > 0
        ? '${formatTRY(list.savingsAmount, withDecimals: false)} ${list.savingsLabel.isEmpty ? 'Daha Ucuz' : list.savingsLabel}'
        : list.savingsLabel;
    final totalLabel = list.title.isEmpty ? 'En İyi Eşleşme (Toplam)' : '${list.title} (Toplam)';

    return Container(
      decoration: BoxDecoration(
        borderRadius: FRRadius.xxlRadius,
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [FRColors.espresso, FRColors.espressoSoft],
        ),
        boxShadow: [BoxShadow(color: FRColors.espresso.withOpacity(0.20), blurRadius: 30, offset: const Offset(0, 12))],
      ),
      child: ClipRRect(
        borderRadius: FRRadius.xxlRadius,
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
                  gradient: RadialGradient(colors: [FRColors.camel.withOpacity(0.2), Colors.transparent]),
                ),
              ),
            ),
            Padding(
              padding: FRSpaceInsets.allXxl,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: FRSpaceInsets.symmetric(
                      horizontal: FRSpacing.smPlus,
                      vertical: FRSpacing.xs,
                    ),
                    decoration: BoxDecoration(
                      color: FRColors.camel.withOpacity(0.2),
                      borderRadius: FRRadius.smRadius,
                      border: Border.all(color: FRColors.camel.withOpacity(0.30)),
                    ),
                    child: Text(
                      list.badgeText,
                      style: _t(
                        fontSize: 10,
                        color: FRColors.camel,
                        fontWeight: FontWeight.w800,
                        letterSpacing: .5,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    list.title,
                    style: _serif(
                      fontSize: 24,
                      height: 1.1,
                      color: FRColors.white,
                      letterSpacing: -.5,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    list.description,
                    style: _t(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: FRColors.white.withOpacity(0.6),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Container(
                    padding: FRSpaceInsets.allLg,
                    decoration: BoxDecoration(
                      color: FRColors.white.withOpacity(0.05),
                      borderRadius: FRRadius.lgRadius,
                      border: Border.all(color: FRColors.white.withOpacity(0.10)),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                totalLabel,
                                style: _t(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: FRColors.white.withOpacity(0.60),
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                formatTRY(list.totalPrice),
                                style: _serif(
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
                              padding: FRSpaceInsets.symmetric(
                                horizontal: FRSpacing.sm,
                                vertical: FRSpacing.xs,
                              ),
                              decoration: BoxDecoration(
                                color: FRColors.successBg(0.15),
                                borderRadius: FRRadius.xsRadius,
                              ),
                              child: Text(
                                savingText,
                                style: _t(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w800,
                                  color: FRColors.success,
                                ),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${list.bestMarketName}${itemCount > 0 ? ' • $itemCount Ürün' : ''}',
                              style: _t(
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
          style: _t(
            fontSize: 16,
            fontWeight: FontWeight.w800,
            color: FRColors.espresso,
          ),
        ),
        const Spacer(),
        Text(
          '$itemCount Ürün',
          style: _t(
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
    final tags = [if (item.quantityLabel.isNotEmpty) item.quantityLabel, if (item.tagLabel.isNotEmpty) item.tagLabel];

    return Container(
      padding: FRSpaceInsets.allMd,
      decoration: BoxDecoration(
        color: FRColors.surfaceSoft,
        borderRadius: FRRadius.lgRadius,
        border: Border.all(color: FRColors.border),
        boxShadow: [BoxShadow(color: FRColors.espressoOverlay(0.02), blurRadius: 12, offset: const Offset(0, 4))],
      ),
      child: Row(
        children: [
          Container(
            width: 56,
            height: 56,
            padding: FRSpaceInsets.all(FRSpacing.xsPlus),
            decoration: BoxDecoration(
              color: FRColors.studio,
              borderRadius: FRRadius.mdRadius,
            ),
            child: item.productImageUrlSnapshot.isNotEmpty
                ? Image.network(item.productImageUrlSnapshot, fit: BoxFit.contain, filterQuality: FilterQuality.medium)
                : const Icon(Icons.image_not_supported_outlined),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.productBrandSnapshot.toUpperCase(),
                  style: _t(
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
                  style: _t(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: FRColors.espresso,
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
                        padding: FRSpaceInsets.symmetric(
                          horizontal: FRSpacing.xsPlus,
                          vertical: FRSpacing.xxs,
                        ),
                        decoration: BoxDecoration(
                          color: FRColors.backgroundWarm,
                          borderRadius: FRRadius.xsRadius,
                          border: Border.all(color: FRColors.border),
                        ),
                        child: Text(
                          tag,
                          style: _t(
                            fontSize: 9,
                            fontWeight: FontWeight.w800,
                            color: FRColors.camelDeep,
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
                formatTRY(item.selectedPrice),
                style: _serif(
                  fontSize: 18,
                  height: 1,
                  color: FRColors.espresso,
                ),
              ),
              const SizedBox(height: 4),
              Container(
                padding: FRSpaceInsets.symmetric(
                  horizontal: FRSpacing.xsPlus,
                  vertical: 3,
                ),
                decoration: BoxDecoration(
                  color: FRColors.border,
                  borderRadius: FRRadius.xsRadius,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(width: 6, height: 6, decoration: BoxDecoration(color: item.marketColor, shape: BoxShape.circle)),
                    const SizedBox(width: 4),
                    Text(
                      item.selectedStoreNameSnapshot,
                      style: _t(
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        color: FRColors.espresso,
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
  const _BottomCompareButton({required this.text, required this.enabled, this.onTap});

  final String text;
  final bool enabled;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: enabled ? 1 : 0.5,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: enabled ? onTap : null,
          borderRadius: FRRadius.lgPlusRadius,
          child: Ink(
            height: 58,
            decoration: BoxDecoration(
              color: FRColors.camel,
              borderRadius: FRRadius.lgPlusRadius,
              boxShadow: [BoxShadow(color: FRColors.camel.withOpacity(0.4), blurRadius: 32, offset: const Offset(0, 16))],
            ),
            child: Center(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.shopping_cart_outlined, color: FRColors.espresso, size: 22),
                  const SizedBox(width: 10),
                  Text(
                    text,
                    style: _t(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: FRColors.espresso,
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

class _IconButtonShell extends StatelessWidget {
  const _IconButtonShell({required this.icon, required this.onTap, this.iconSize = 20});

  final IconData icon;
  final VoidCallback? onTap;
  final double iconSize;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: FRRadius.mdRadius,
      onTap: onTap,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: FRColors.surfaceSoft,
          borderRadius: FRRadius.mdRadius,
          border: Border.all(color: FRColors.border),
          boxShadow: [BoxShadow(color: FRColors.espressoOverlay(0.03), blurRadius: 10, offset: const Offset(0, 4))],
        ),
        child: Icon(icon, size: iconSize, color: FRColors.espresso),
      ),
    );
  }
}

class _StatusState extends StatelessWidget {
  const _StatusState({required this.icon, required this.message, required this.onBack});

  final IconData icon;
  final String message;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: FRSpaceInsets.allXxl,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 42, color: FRColors.camelDeep),
            const SizedBox(height: 12),
            Text(
              message,
              textAlign: TextAlign.center,
              style: _t(fontSize: 15, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 12),
            TextButton(onPressed: onBack, child: const Text('Geri Dön')),
          ],
        ),
      ),
    );
  }
}

class _EmptyItemsState extends StatelessWidget {
  const _EmptyItemsState();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: FRSpaceInsets.all(FRSpacing.lgPlus),
      decoration: BoxDecoration(
        color: FRColors.surfaceSoft,
        borderRadius: FRRadius.lgRadius,
        border: Border.all(color: FRColors.border),
      ),
      child: Text(
        'Bu listede henüz ürün yok.',
        style: _t(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: FRColors.camelDeep,
        ),
      ),
    );
  }
}

TextStyle _t({
  required double fontSize,
  FontWeight? fontWeight,
  Color? color,
  double? height,
  double? letterSpacing,
}) {
  return TextStyle(
    fontFamily: FRTypography.fontFamily,
    fontSize: fontSize,
    fontWeight: fontWeight,
    color: color ?? FRColors.textPrimary,
    height: height,
    letterSpacing: letterSpacing,
  );
}

TextStyle _serif({
  required double fontSize,
  FontWeight? fontWeight,
  Color? color,
  double? height,
  double? letterSpacing,
}) {
  return TextStyle(
    fontFamily: FRTypography.serifFamily,
    fontSize: fontSize,
    fontWeight: fontWeight,
    color: color ?? FRColors.textPrimary,
    height: height,
    letterSpacing: letterSpacing,
  );
}
