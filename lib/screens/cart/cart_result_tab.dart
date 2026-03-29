import '../../utils/formatters.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';

import '../../features/basket/cart_comparison_state.dart';
import '../../theme/fr_colors.dart';
import '../../theme/fr_radius.dart';
import '../../theme/fr_spacing.dart';
import '../../theme/fr_typography.dart';

class CartResultTab extends StatelessWidget {
  const CartResultTab({
    super.key,
    required this.state,
    required this.onCalculate,
    required this.onGoToCart,
    required this.onAddPrice,
    required this.onRetry,
    required this.onSelectStores,
    required this.selectedStoreNames,
  });

  final CartComparisonState state;
  final VoidCallback onCalculate;
  final VoidCallback onGoToCart;
  final VoidCallback onAddPrice;
  final VoidCallback onRetry;
  final VoidCallback onSelectStores;
  final List<String> selectedStoreNames;

  @override
  Widget build(BuildContext context) {
    switch (state.status) {
      case CartComparisonStatus.idle:
        return _IdleState(onCalculate: onCalculate, onGoToCart: onGoToCart);
      case CartComparisonStatus.loading:
        return const _LoadingState();
      case CartComparisonStatus.success:
        return _SuccessState(state: state, selectedStoreNames: selectedStoreNames);
      case CartComparisonStatus.empty:
        return _EmptyState(
          state: state,
          onAddPrice: onAddPrice,
          onCalculate: onCalculate,
          onSelectStores: onSelectStores,
          selectedStoreNames: selectedStoreNames,
        );
      case CartComparisonStatus.error:
        return _ErrorState(state: state, onRetry: onRetry);
    }
  }
}

class _IdleState extends StatelessWidget {
  const _IdleState({required this.onCalculate, required this.onGoToCart});
  final VoidCallback onCalculate;
  final VoidCallback onGoToCart;

  @override
  Widget build(BuildContext context) {
        return Center(
      child: Padding(
        padding: FRSpaceInsets.all(FRSpacing.xl),
        child: Container(
          constraints: const BoxConstraints(maxWidth: 460),
          padding: FRSpaceInsets.allXxl,
          decoration: BoxDecoration(
            color: FRColors.white,
            borderRadius: FRRadius.xxlRadius,
            border: Border.all(color: FRColors.camelDeep.withOpacity(0.05)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.auto_graph_rounded, size: 52, color: FRColors.camelDeep),
              const SizedBox(height: 16),
              Text(
                'Sonuçları görmek için Hesapla',
                style: _t(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: FRColors.espressoSoft,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Market bazlı toplamları premium karşılaştırma görünümünde görmek için hesaplamayı başlat.',
                textAlign: TextAlign.center,
                style: _t(color: FRColors.textMuted),
              ),
              const SizedBox(height: 20),
              FilledButton.icon(
                onPressed: () { HapticFeedback.mediumImpact(); onCalculate(); },
                icon: const Icon(Icons.calculate_rounded),
                label: const Text('Hesapla'),
                style: FilledButton.styleFrom(backgroundColor: FRColors.camelDeep),
              ),
              TextButton(
                onPressed: onGoToCart,
                child: Text(
                  'Sepete dön',
                  style: _t(color: FRColors.camelDeep),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LoadingState extends StatefulWidget {
  const _LoadingState();
  @override
  State<_LoadingState> createState() => _LoadingStateState();
}
class _LoadingStateState extends State<_LoadingState> with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 1100))..repeat(reverse: true);
  @override
  void dispose() { _controller.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (_, __) {
        final alpha = 0.16 + (0.22 * _controller.value);
        final shimmer = FRColors.camelDeep.withOpacity(alpha * 0.5);
        Widget block({double height = 16, double? width}) {
          return Container(
            width: width,
            height: height,
            decoration: BoxDecoration(
              color: shimmer,
              borderRadius: FRRadius.mdPlusRadius,
            ),
          );
        }
        return ListView(
          padding: FRSpaceInsets.allLg,
          children: [
            block(height: 170),
            const SizedBox(height: 12),
            Row(children: [Expanded(child: block(height: 96)), const SizedBox(width: 10), Expanded(child: block(height: 96))]),
            const SizedBox(height: 20),
            block(height: 20, width: 190),
            const SizedBox(height: 10),
            block(height: 84), const SizedBox(height: 8), block(height: 84), const SizedBox(height: 8), block(height: 84),
          ],
        );
      },
    );
  }
}

class _SuccessState extends StatefulWidget {
  const _SuccessState({required this.state, required this.selectedStoreNames});
  final CartComparisonState state;
  final List<String> selectedStoreNames;

  @override
  State<_SuccessState> createState() => _SuccessStateState();
}

class _SuccessStateState extends State<_SuccessState> {
  double _scrollOffset = 0;

  @override
  Widget build(BuildContext context) {
    final state = widget.state;
    final best = state.bestMarket;
    if (best == null) return const SizedBox.shrink();

    final markets = [...state.topMarkets]
      ..sort((a, b) {
        if (a.missingCount != b.missingCount) {
          if (a.missingCount == 0) return -1;
          if (b.missingCount == 0) return 1;
        }
        return a.totalPrice.compareTo(b.totalPrice);
      });

    final minTotal = markets.map((e) => e.totalPrice).reduce((a, b) => a < b ? a : b);
    final maxTotal = markets.map((e) => e.totalPrice).reduce((a, b) => a > b ? a : b);

    // KAZANÇ HESAPLAMASI: İkinci sıradaki market ile birinci sıradaki marketin farkı
    double calculatedSaving = 0;
    if (markets.length > 1) {
      calculatedSaving = markets[1].totalPrice - best.totalPrice;
    } else {
      calculatedSaving = maxTotal - best.totalPrice;
    }

    return NotificationListener<ScrollNotification>(
      onNotification: (notification) {
        if (notification.metrics.axis == Axis.vertical) {
          setState(() => _scrollOffset = notification.metrics.pixels.clamp(0, 220));
        }
        return false;
      },
      child: ListView(
        padding: FRSpaceInsets.fromLTRB(FRSpacing.xxl, FRSpacing.lg, FRSpacing.xxl, 120), // Alt bar için boşluk
        children: [
          TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: 1),
            duration: const Duration(milliseconds: 420),
            curve: Curves.easeOutCubic,
            builder: (context, value, child) => Opacity(opacity: value, child: Transform.translate(offset: Offset(0, 14 * (1 - value)), child: child)),
            child: _HeroCard(
              best: best, 
              totalProducts: state.missingProducts.length + best.lines.length, 
              scrollFactor: _scrollOffset, 
              savingAmount: calculatedSaving, // Dinamik kazanç gönderiliyor
            ),
          ),
          const SizedBox(height: 25),
          Text(
            'Alternatif Marketler',
            style: _t(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: FRColors.espressoSoft,
            ),
          ),
          if (widget.selectedStoreNames.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              'Seçili mağazalar: ${widget.selectedStoreNames.join(', ')}',
              style: _t(
                color: FRColors.textMuted,
                fontSize: 12,
              ),
            ),
          ],
          const SizedBox(height: 15),
          Container(
            decoration: BoxDecoration(
              color: FRColors.white,
              borderRadius: FRRadius.xxlRadius,
              border: Border.all(color: FRColors.camelDeep.withOpacity(0.05)),
            ),
            child: Column(
              children: markets.asMap().entries.map((entry) {
                  return TweenAnimationBuilder<double>(
                    tween: Tween(begin: 0, end: 1),
                    duration: Duration(milliseconds: 320 + (entry.key * 40)),
                    curve: Curves.easeOutCubic,
                    builder: (context, value, child) => Opacity(opacity: value, child: Transform.translate(offset: Offset(0, (1 - value) * 12), child: child)),
                    child: _PremiumMarketRowCard(
                      market: entry.value, 
                      bestMarket: best, // Ürün kıyaslaması için Şampiyon marketi gönderiyoruz
                      rank: entry.key + 1, 
                      minTotal: minTotal, 
                      maxTotal: maxTotal
                    ),
                  );
              }).toList(),
            ),
          ),
          const SizedBox(height: 25),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () async {
                    final text = _buildShareText(markets.take(3).toList());
                    await Clipboard.setData(ClipboardData(text: text));
                    if (!context.mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Sonuç panoya kopyalandı.')));
                  },
                  icon: const Icon(Icons.content_copy_rounded, color: FRColors.camelDeep),
                  label: Text('Kopyala', style: _t(color: FRColors.camelDeep)),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: FRColors.camelDeep),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: FilledButton.icon(
                  onPressed: () => Share.share(_buildShareText(markets.take(3).toList())),
                  icon: const Icon(Icons.share_rounded),
                  label: const Text('Paylaş'),
                  style: FilledButton.styleFrom(backgroundColor: FRColors.camelDeep),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// V15 NEFES ALAN AGRESİF ROZET
// ─────────────────────────────────────────────────────────────────────────────
class _PulseSavingsBadge extends StatefulWidget {
  final String text;
  const _PulseSavingsBadge({required this.text});
  @override
  State<_PulseSavingsBadge> createState() => _PulseSavingsBadgeState();
}
class _PulseSavingsBadgeState extends State<_PulseSavingsBadge> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  
  @override
  void initState() {
    super.initState();
    // Animasyonu daha dikkat çekici hale getirdik
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 1200))..repeat(reverse: true);
    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.06).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }
  @override
  void dispose() { _controller.dispose(); super.dispose(); }
  
  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
            child: Container(
            padding: FRSpaceInsets.symmetric(
              horizontal: FRSpacing.mdPlus,
              vertical: FRSpacing.sm,
            ),
            decoration: BoxDecoration(
              color: FRColors.white, borderRadius: FRRadius.mdRadius,
              border: Border.all(color: FRColors.camelStrong, width: 2),
              // Gölgeyi çok daha agresif, parlayan bir Gold yaptık
              boxShadow: [BoxShadow(color: FRColors.camelStrong.withOpacity(0.6), blurRadius: 15 + (_controller.value * 25), spreadRadius: _controller.value * 4)],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.savings_outlined, color: FRColors.camelStrong, size: 18),
                const SizedBox(width: 6),
                Text(
                  widget.text,
                  style: _t(
                    color: FRColors.espressoSoft,
                    fontWeight: FontWeight.w900,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// V15 ŞAMPİYON KART (_HeroCard)
// ─────────────────────────────────────────────────────────────────────────────
class _HeroCard extends StatelessWidget {
  const _HeroCard({required this.best, required this.totalProducts, required this.scrollFactor, required this.savingAmount});
  final CartMarketResultSummary best;
  final int totalProducts;
  final double scrollFactor;
  final double savingAmount;

  @override
  Widget build(BuildContext context) {
    final parallaxY = scrollFactor * 0.15;
    final scale = scrollFactor > 80 ? 0.96 : 1 - ((scrollFactor / 80) * 0.04);

    return Transform.translate(
      offset: Offset(0, parallaxY),
      child: Transform.scale(
        scale: scale,
        alignment: Alignment.topCenter,
        child: Container(
          padding: FRSpaceInsets.all(FRSpacing.xxl + 1),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [FRColors.espressoSoft, FRColors.camelDeep],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: FRRadius.heroRadius,
            boxShadow: [BoxShadow(color: FRColors.espressoSoft.withOpacity(0.2), blurRadius: 40, offset: const Offset(0, 20))],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: FRSpaceInsets.symmetric(
                      horizontal: FRSpacing.md,
                      vertical: FRSpacing.xsPlus,
                    ),
                    decoration: BoxDecoration(color: FRColors.camelStrong, borderRadius: FRRadius.smPlusRadius),
                    child: Row(
                      children: [
                        const Icon(Icons.star_rounded, size: 14, color: FRColors.espressoSoft),
                        const SizedBox(width: 6),
                        Text(
                          'EN UYGUN',
                          style: _t(
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            color: FRColors.espressoSoft,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (savingAmount > 0)
                    _PulseSavingsBadge(text: "${formatTRY(savingAmount)} KAZANÇ"), 
                ],
              ),
              const SizedBox(height: 25),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        best.storeName,
                        style: _t(color: FRColors.white, fontSize: 28, fontWeight: FontWeight.w800),
                      ),
                      Text(
                        best.missingCount > 0 ? '${best.missingCount} ürün eksik' : 'Tüm ürünler var',
                        style: _t(color: FRColors.white.withOpacity(0.7), fontSize: 13),
                      ),
                    ],
                  ),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        best.totalPrice.toInt().toString(),
                        style: _t(color: FRColors.white, fontSize: 42, fontWeight: FontWeight.w800, height: 1),
                      ),
                      Padding(
                        padding: FRSpaceInsets.only(left: FRSpacing.xxs, top: FRSpacing.xs),
                        child: Text(
                          '₺',
                          style: _t(color: FRColors.camelStrong, fontSize: 20, fontWeight: FontWeight.w600),
                        ),
                      ),
                    ],
                  )
                ],
              ),
              const SizedBox(height: 25),
              Text(
                'Karşılaştırma sonuçları market zinciri bazında gösterilir.',
                style: _t(color: FRColors.white.withOpacity(0.78), fontSize: 12),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// V15 ALTERNATİF MARKET AKORDEONU (_PremiumMarketRowCard)
// ─────────────────────────────────────────────────────────────────────────────
class _PremiumMarketRowCard extends StatefulWidget {
  const _PremiumMarketRowCard({required this.market, required this.bestMarket, required this.rank, required this.minTotal, required this.maxTotal});
  final CartMarketResultSummary market;
  final CartMarketResultSummary bestMarket; 
  final int rank;
  final double minTotal;
  final double maxTotal;
  @override
  State<_PremiumMarketRowCard> createState() => _PremiumMarketRowCardState();
}

class _PremiumMarketRowCardState extends State<_PremiumMarketRowCard> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final isError = widget.market.missingCount > 0;
    return Container(
      padding: FRSpaceInsets.symmetric(vertical: 15, horizontal: FRSpacing.xl),
      decoration: const BoxDecoration(
        color: FRColors.white,
        border: Border(bottom: BorderSide(color: FRColors.border)),
      ),
      child: Column(
        children: [
          InkWell(
            onTap: () { HapticFeedback.selectionClick(); setState(() => _expanded = !_expanded); },
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      width: 32, height: 32,
                      decoration: BoxDecoration(
                        color: isError
                            ? FRColors.dangerBg(0.10)
                            : (widget.rank == 1 ? FRColors.camelStrong : FRColors.border),
                        borderRadius: FRRadius.smPlusRadius,
                      ),
                      child: Center(
                        child: Text(
                          isError ? '!' : '${widget.rank}',
                          style: _t(
                            fontWeight: FontWeight.w800,
                            fontSize: isError ? 16 : 14,
                            color: isError
                                ? FRColors.danger
                                : (widget.rank == 1 ? FRColors.espressoSoft : FRColors.textMuted),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.market.storeName,
                          style: _t(
                            fontWeight: FontWeight.w700,
                            fontSize: 16,
                            color: FRColors.espressoSoft,
                          ),
                        ),
                        Text(
                          isError ? '${widget.market.missingCount} Eksik' : 'Eksik Yok',
                          style: _t(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: isError ? FRColors.danger : FRColors.textMuted,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      formatTRY(widget.market.totalPrice),
                      style: _t(
                        fontWeight: FontWeight.w800,
                        fontSize: 18,
                        color: FRColors.espressoSoft,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Container(
                      padding: FRSpaceInsets.symmetric(
                        horizontal: FRSpacing.sm,
                        vertical: FRSpacing.xs,
                      ),
                      decoration: BoxDecoration(
                        color: isError ? FRColors.dangerBg(0.10) : FRColors.camelOverlay(0.12),
                        borderRadius: FRRadius.smRadius,
                      ),
                      child: Text(
                        isError ? 'Stok Yok' : '+${formatTRY(widget.market.totalPrice - widget.minTotal)} Fark',
                        style: _t(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: isError ? FRColors.danger : FRColors.camelDeep,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          AnimatedSize(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOutCubic,
            child: !_expanded ? const SizedBox.shrink() : Padding(
              padding: FRSpaceInsets.only(top: 15, left: 46),
              child: Column(
                children: widget.market.lines.map((line) {
                  
                  // Fiyat Farkı Hesaplama (En ucuz marketle bu ürünü kıyasla)
                  double diff = 0;
                  try {
                    final bestLine = widget.bestMarket.lines.firstWhere((l) => l.productName == line.productName);
                    diff = line.lineTotal - bestLine.lineTotal;
                  } catch (e) {
                    diff = 0;
                  }

                  return Padding(
                    padding: FRSpaceInsets.bottomSmPlus,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            '${line.quantity}x ${line.productName}',
                            style: _t(
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                              color: FRColors.espressoSoft,
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        
                        Row(
                          children: [
                            if (diff > 0) ...[
                              Text(
                                '(+${formatTRY(diff)})',
                                style: _t(
                                  color: FRColors.danger,
                                  fontWeight: FontWeight.w800,
                                  fontSize: 11,
                                ),
                              ),
                              const SizedBox(width: 4),
                            ],
                            Container(
                              padding: FRSpaceInsets.symmetric(
                                horizontal: FRSpacing.sm,
                                vertical: FRSpacing.xs,
                              ),
                              decoration: BoxDecoration(
                                color: diff > 0 ? FRColors.dangerBg(0.08) : FRColors.espressoOverlay(0.08),
                                borderRadius: FRRadius.smRadius,
                              ),
                              child: Text(
                                formatTRY(line.lineTotal),
                                style: _t(
                                  color: diff > 0 ? FRColors.danger : FRColors.espressoSoft,
                                  fontWeight: FontWeight.w800,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Boş, Hata vs State'leri
// ─────────────────────────────────────────────────────────────────────────────
class _EmptyState extends StatelessWidget {
  const _EmptyState({
    required this.state,
    required this.onAddPrice,
    required this.onCalculate,
    required this.onSelectStores,
    required this.selectedStoreNames,
  });

  final CartComparisonState state;
  final VoidCallback onAddPrice;
  final VoidCallback onCalculate;
  final VoidCallback onSelectStores;
  final List<String> selectedStoreNames;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: FRSpaceInsets.allXxl,
      children: [
        Container(
          padding: FRSpaceInsets.all(FRSpacing.xl),
          decoration: BoxDecoration(
            color: FRColors.white,
            borderRadius: FRRadius.xlRadius,
            border: Border.all(color: FRColors.camelDeep.withOpacity(0.05)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Yeterli fiyat verisi yok',
                style: _t(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: FRColors.espressoSoft,
                ),
              ),
              const SizedBox(height: 8),
              if (state.missingProducts.isNotEmpty) ...[
                Text(
                  'Fiyatı olmayan ürünler:',
                  style: _t(color: FRColors.danger),
                ),
                const SizedBox(height: 8),
                ...state.missingProducts.take(5).map(
                  (name) => Padding(
                    padding: FRSpaceInsets.only(bottom: FRSpacing.xsPlus),
                    child: Text('• $name', style: _t(color: FRColors.textMuted)),
                  ),
                ),
              ],
              const SizedBox(height: 15),
              Wrap(
                spacing: 8,
                children: [
                  FilledButton.icon(
                    onPressed: onAddPrice,
                    icon: const Icon(Icons.add_business_rounded),
                    label: const Text('Fiyat Ekle'),
                    style: FilledButton.styleFrom(backgroundColor: FRColors.camelDeep),
                  ),
                  OutlinedButton.icon(
                    onPressed: onSelectStores,
                    icon: const Icon(Icons.store_mall_directory_rounded, color: FRColors.camelDeep),
                    label: Text('Mağaza Seç', style: _t(color: FRColors.camelDeep)),
                    style: OutlinedButton.styleFrom(side: const BorderSide(color: FRColors.camelDeep)),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.state, required this.onRetry});
  final CartComparisonState state;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: FRSpaceInsets.allXxl,
        child: Container(
          padding: FRSpaceInsets.all(FRSpacing.xl),
          decoration: BoxDecoration(color: FRColors.dangerBg(0.10), borderRadius: FRRadius.xlRadius),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline_rounded, color: FRColors.danger, size: 36),
              const SizedBox(height: 10),
              Text(
                state.errorMessage ?? 'Bir hata oluştu.',
                textAlign: TextAlign.center,
                style: _t(color: FRColors.danger),
              ),
              const SizedBox(height: 10),
              FilledButton(
                onPressed: onRetry,
                style: FilledButton.styleFrom(backgroundColor: FRColors.danger),
                child: const Text('Tekrar Dene'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

String _buildShareText(List<CartMarketResultSummary> markets) {
  final rows = markets.map((m) => '${m.storeName} ${_formatCurrency(m.totalPrice)}').join(' | ');
  return 'FiyatRadar Sonuç: $rows';
}

String _formatCurrency(num value) => formatTRY(value);

TextStyle _t({
  double fontSize = 14,
  FontWeight? fontWeight,
  Color? color,
  double? height,
}) {
  return TextStyle(
    fontFamily: FRTypography.fontFamily,
    fontSize: fontSize,
    fontWeight: fontWeight,
    color: color ?? FRColors.textPrimary,
    height: height,
  );
}
