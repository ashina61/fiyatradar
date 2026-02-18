import '../../utils/formatters.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';

import '../../features/basket/cart_comparison_state.dart';

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
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Container(
          constraints: const BoxConstraints(maxWidth: 460),
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: cs.surfaceContainerHigh,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: cs.outlineVariant.withOpacity(0.6)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.auto_graph_rounded, size: 52, color: cs.primary),
              const SizedBox(height: 16),
              Text('Sonuçları görmek için Hesapla', style: theme.textTheme.headlineSmall),
              const SizedBox(height: 8),
              Text(
                'Market bazlı toplamları premium karşılaştırma görünümünde görmek için hesaplamayı başlat.',
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium?.copyWith(color: cs.onSurfaceVariant),
              ),
              const SizedBox(height: 18),
              FilledButton.icon(
                onPressed: () {
                  HapticFeedback.mediumImpact();
                  onCalculate();
                },
                icon: const Icon(Icons.calculate_rounded),
                label: const Text('Hesapla'),
              ),
              TextButton(onPressed: onGoToCart, child: const Text('Sepete dön')),
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
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1100),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return AnimatedBuilder(
      animation: _controller,
      builder: (_, __) {
        final alpha = 0.16 + (0.22 * _controller.value);
        final shimmer = cs.surfaceContainerHighest.withOpacity(alpha);
        Widget block({double height = 16, double? width}) {
          return Container(
            width: width,
            height: height,
            decoration: BoxDecoration(color: shimmer, borderRadius: BorderRadius.circular(14)),
          );
        }

        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            block(height: 170),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(child: block(height: 96)),
                const SizedBox(width: 10),
                Expanded(child: block(height: 96)),
              ],
            ),
            const SizedBox(height: 18),
            block(height: 20, width: 190),
            const SizedBox(height: 10),
            block(height: 84),
            const SizedBox(height: 8),
            block(height: 84),
            const SizedBox(height: 8),
            block(height: 84),
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

    final nearest = state.nearestMarket;
    final minTotal = markets.map((e) => e.totalPrice).reduce((a, b) => a < b ? a : b);
    final maxTotal = markets.map((e) => e.totalPrice).reduce((a, b) => a > b ? a : b);

    return NotificationListener<ScrollNotification>(
      onNotification: (notification) {
        if (notification.metrics.axis == Axis.vertical) {
          setState(() => _scrollOffset = notification.metrics.pixels.clamp(0, 220));
        }
        return false;
      },
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
        children: [
          TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: 1),
            duration: const Duration(milliseconds: 420),
            curve: Curves.easeOutCubic,
            builder: (context, value, child) => Opacity(
              opacity: value,
              child: Transform.translate(offset: Offset(0, 14 * (1 - value)), child: child),
            ),
            child: _HeroCard(
              best: best,
              totalProducts: state.missingProducts.length + best.lines.length,
              scrollFactor: _scrollOffset,
            ),
          ),
          const SizedBox(height: 10),
          _MiniInsights(best: best, nearest: nearest),
          const SizedBox(height: 18),
          Text('Market Karşılaştırma', style: Theme.of(context).textTheme.titleLarge),
          Text(
            'Sepetin toplamı markete göre değişebilir.',
            style: Theme.of(context)
                .textTheme
                .bodyMedium
                ?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant),
          ),
          if (widget.selectedStoreNames.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              'Seçili mağazalar: ${widget.selectedStoreNames.join(', ')}',
              style: Theme.of(context)
                  .textTheme
                  .bodySmall
                  ?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant),
            ),
          ],
          const SizedBox(height: 10),
          ...markets.asMap().entries.map(
                (entry) => Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: TweenAnimationBuilder<double>(
                    tween: Tween(begin: 0, end: 1),
                    duration: Duration(milliseconds: 320 + (entry.key * 40)),
                    curve: Curves.easeOutCubic,
                    builder: (context, value, child) => Opacity(
                      opacity: value,
                      child: Transform.translate(offset: Offset(0, (1 - value) * 12), child: child),
                    ),
                    child: _PremiumMarketRowCard(
                      market: entry.value,
                      rank: entry.key + 1,
                      minTotal: minTotal,
                      maxTotal: maxTotal,
                    ),
                  ),
                ),
              ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () async {
                    final text = _buildShareText(markets.take(3).toList());
                    await Clipboard.setData(ClipboardData(text: text));
                    if (!context.mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Sonuç panoya kopyalandı.')),
                    );
                  },
                  icon: const Icon(Icons.content_copy_rounded),
                  label: const Text('Kopyala'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: FilledButton.icon(
                  onPressed: () => Share.share(_buildShareText(markets.take(3).toList())),
                  icon: const Icon(Icons.share_rounded),
                  label: const Text('Paylaş'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _HeroCard extends StatelessWidget {
  const _HeroCard({required this.best, required this.totalProducts, required this.scrollFactor});

  final CartMarketResultSummary best;
  final int totalProducts;
  final double scrollFactor;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final parallaxY = scrollFactor * 0.15;
    final scale = scrollFactor > 80 ? 0.96 : 1 - ((scrollFactor / 80) * 0.04);
    final glowOpacity = (0.08 + (scrollFactor / 220) * 0.12).clamp(0.08, 0.2);

    return Transform.translate(
      offset: Offset(0, parallaxY),
      child: Transform.scale(
        scale: scale,
        alignment: Alignment.topCenter,
        child: Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: cs.surfaceContainerHigh,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: cs.outlineVariant.withOpacity(0.45)),
            boxShadow: [
              BoxShadow(
                color: cs.primary.withOpacity(glowOpacity),
                blurRadius: 24,
                spreadRadius: 1,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text('En Uygun Market', style: Theme.of(context).textTheme.titleSmall),
                  const Spacer(),
                  Icon(Icons.workspace_premium_rounded, color: cs.primary),
                ],
              ),
              const SizedBox(height: 8),
              Text(best.storeName, style: Theme.of(context).textTheme.headlineSmall),
              const SizedBox(height: 6),
              Text(_formatCurrency(best.totalPrice), style: Theme.of(context).textTheme.displaySmall),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _Pill(
                    text: '$totalProducts ürün • Eksik ${best.missingCount}',
                    color: cs.secondaryContainer,
                    fg: cs.onSecondaryContainer,
                  ),
                  if (best.distanceKm != null)
                    _Pill(
                      text: '${best.distanceKm!.toStringAsFixed(1)} km',
                      color: cs.tertiaryContainer,
                      fg: cs.onTertiaryContainer,
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MiniInsights extends StatelessWidget {
  const _MiniInsights({required this.best, required this.nearest});

  final CartMarketResultSummary best;
  final CartMarketResultSummary? nearest;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final sameMarket = nearest != null && nearest!.storeId == best.storeId;
    final saving = nearest != null ? (nearest!.totalPrice - best.totalPrice) : null;

    return Row(
      children: [
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: cs.surfaceContainer,
              borderRadius: BorderRadius.circular(16),
            ),
            child: nearest == null
                ? Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('EN YAKIN', style: Theme.of(context).textTheme.labelLarge),
                      const SizedBox(height: 6),
                      Text('Konum izni kapalı', style: Theme.of(context).textTheme.bodyMedium),
                      const SizedBox(height: 8),
                      OutlinedButton(
                        onPressed: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Konum izni için cihaz ayarlarını açın.')),
                          );
                        },
                        child: const Text('Konum izni ver'),
                      ),
                    ],
                  )
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('EN YAKIN', style: Theme.of(context).textTheme.labelLarge),
                      const SizedBox(height: 4),
                      Text(nearest!.storeName, maxLines: 1, overflow: TextOverflow.ellipsis),
                      Text(
                        '${nearest!.distanceKm?.toStringAsFixed(1) ?? '-'} km',
                        style: Theme.of(context)
                            .textTheme
                            .bodySmall
                            ?.copyWith(color: cs.onSurfaceVariant),
                      ),
                      const SizedBox(height: 8),
                      Text(_formatCurrency(nearest!.totalPrice), style: Theme.of(context).textTheme.titleMedium),
                    ],
                  ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: cs.surfaceContainer,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('TASARRUF', style: Theme.of(context).textTheme.labelLarge),
                const SizedBox(height: 6),
                Text(
                  nearest == null
                      ? 'Konum verisi yok'
                      : sameMarket
                          ? 'En yakın = en uygun 🎉'
                          : 'En yakına göre',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 8),
                Text(
                  nearest == null
                      ? '—'
                      : sameMarket
                          ? 'Harika seçim'
                          : _formatCurrency(saving ?? 0),
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

/// Returns a brand-specific background/foreground color pair and abbreviation
/// for a store name, so each chain is visually distinct.
({Color bg, Color fg, String abbr}) _storeBrand(String name) {
  final n = name.trim().toUpperCase();
  if (n.contains('BİM') || n == 'BIM') {
    return (bg: const Color(0xFFE53935), fg: Colors.white, abbr: 'BİM');
  } else if (n.contains('A-101') || n.contains('A101')) {
    return (bg: const Color(0xFFE65100), fg: Colors.white, abbr: 'A101');
  } else if (n.contains('ŞOK') || n.contains('SOK')) {
    return (bg: const Color(0xFF1565C0), fg: Colors.white, abbr: 'ŞOK');
  } else if (n.contains('CARREFOUR') || n.contains('CARREFOURSA')) {
    return (bg: const Color(0xFF0D47A1), fg: Colors.white, abbr: 'CAR');
  } else if (n.contains('MİGROS') || n.contains('MIGROS')) {
    return (bg: const Color(0xFFF57C00), fg: Colors.white, abbr: 'MİG');
  } else if (n.contains('İMECE') || n.contains('IMECE')) {
    return (bg: const Color(0xFF388E3C), fg: Colors.white, abbr: 'İME');
  } else if (n.contains('FILE') || n.contains('FİLE')) {
    return (bg: const Color(0xFF6A1B9A), fg: Colors.white, abbr: 'FİL');
  }
  // Generic fallback — first 3 chars of the name
  final abbr = name.length >= 3 ? name.substring(0, 3).toUpperCase() : name.toUpperCase();
  return (bg: const Color(0xFF546E7A), fg: Colors.white, abbr: abbr);
}

class _PremiumMarketRowCard extends StatefulWidget {
  const _PremiumMarketRowCard({
    required this.market,
    required this.rank,
    required this.minTotal,
    required this.maxTotal,
  });

  final CartMarketResultSummary market;
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
    final cs = Theme.of(context).colorScheme;
    final market = widget.market;
    final hideBar = widget.maxTotal == widget.minTotal;
    final normalized = hideBar
        ? 0.0
        : ((market.totalPrice - widget.minTotal) / (widget.maxTotal - widget.minTotal)).clamp(0.0, 1.0);
    final rankLabel = widget.rank == 1 ? '#1 En Uygun' : '#${widget.rank}';

    return Container(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 10),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: cs.outlineVariant.withOpacity(0.5)),
      ),
      child: Column(
        children: [
          InkWell(
            borderRadius: BorderRadius.circular(14),
            onTap: () {
              HapticFeedback.selectionClick();
              setState(() => _expanded = !_expanded);
            },
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                children: [
                  Builder(builder: (_) {
                    final brand = _storeBrand(market.storeName);
                    return CircleAvatar(
                      radius: 18,
                      backgroundColor: brand.bg,
                      child: Text(
                        brand.abbr.length > 3 ? brand.abbr.substring(0, 3) : brand.abbr,
                        style: TextStyle(
                          color: brand.fg,
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    );
                  }),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(market.storeName, style: Theme.of(context).textTheme.titleMedium),
                        const SizedBox(height: 2),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: widget.rank == 1 ? cs.secondaryContainer : cs.surfaceContainerHighest,
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (widget.rank == 1) Icon(Icons.workspace_premium_rounded, size: 14, color: cs.primary),
                              if (widget.rank == 1) const SizedBox(width: 4),
                              Text(rankLabel, style: Theme.of(context).textTheme.labelMedium),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(_formatCurrency(market.totalPrice), style: Theme.of(context).textTheme.titleLarge),
                      Text(
                        market.distanceKm != null ? '${market.distanceKm!.toStringAsFixed(1)} km' : '-',
                        style: Theme.of(context)
                            .textTheme
                            .bodySmall
                            ?.copyWith(color: cs.onSurfaceVariant),
                      ),
                      AnimatedRotation(
                        turns: _expanded ? 0.5 : 0,
                        duration: const Duration(milliseconds: 280),
                        curve: Curves.easeOutBack,
                        child: const Icon(Icons.expand_more_rounded, size: 20),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          if (market.missingCount > 0)
            Align(
              alignment: Alignment.centerLeft,
              child: Padding(
                padding: const EdgeInsets.only(top: 6, bottom: 8),
                child: _Pill(
                  text: 'Eksik ${market.missingCount} ürün',
                  color: cs.errorContainer,
                  fg: cs.onErrorContainer,
                ),
              ),
            ),
          if (!hideBar)
            Padding(
              padding: const EdgeInsets.only(top: 2, bottom: 4),
              child: Row(
                children: [
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(999),
                      child: Container(
                        height: 7,
                        color: cs.surfaceContainerHighest,
                        child: Align(
                          alignment: Alignment.centerLeft,
                          child: LayoutBuilder(
                            builder: (context, constraints) => TweenAnimationBuilder<double>(
                              tween: Tween(begin: 0, end: 0.2 + (normalized * 0.55)),
                              duration: const Duration(milliseconds: 420),
                              curve: Curves.easeOutCubic,
                              builder: (context, value, _) => Container(
                                width: constraints.maxWidth * value,
                                decoration: BoxDecoration(
                                  color: widget.rank == 1 ? cs.primary : cs.secondary,
                                  borderRadius: BorderRadius.circular(999),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    widget.rank == 1 ? 'En iyi' : '+${_formatCurrency(market.totalPrice - widget.minTotal)}',
                    style: Theme.of(context).textTheme.labelMedium,
                  ),
                ],
              ),
            ),
          AnimatedSize(
            duration: const Duration(milliseconds: 320),
            curve: Curves.easeOutBack,
            child: AnimatedOpacity(
              duration: const Duration(milliseconds: 220),
              opacity: _expanded ? 1 : 0,
              child: !_expanded
                  ? const SizedBox.shrink()
                  : Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Column(
                        children: [
                          for (final line in market.lines)
                            ListTile(
                              dense: true,
                              contentPadding: EdgeInsets.zero,
                              title: Text(line.productName),
                              subtitle: Text('${line.quantity} adet × ${_formatCurrency(line.unitPrice)}'),
                              trailing: Text(_formatCurrency(line.lineTotal)),
                            ),
                          if (market.missingCount > 0)
                            for (var index = 0; index < market.missingCount; index++)
                              ListTile(
                                dense: true,
                                contentPadding: EdgeInsets.zero,
                                title: Text(
                                  'Ürün #${index + 1}',
                                  style: TextStyle(color: cs.onSurfaceVariant),
                                ),
                                trailing: Text(
                                  'Fiyat yok',
                                  style: TextStyle(color: cs.onSurfaceVariant),
                                ),
                              ),
                        ],
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}

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
    final cs = Theme.of(context).colorScheme;
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: cs.surfaceContainerHigh,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: cs.outlineVariant.withOpacity(0.5)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Yeterli fiyat verisi yok', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),
              if (state.missingProducts.isNotEmpty) ...[
                Text('Fiyatı olmayan ürünler', style: Theme.of(context).textTheme.labelLarge),
                const SizedBox(height: 8),
                ...state.missingProducts.take(5).map(
                      (name) => Padding(
                        padding: const EdgeInsets.only(bottom: 6),
                        child: Text('• $name'),
                      ),
                    ),
              ],
              if (selectedStoreNames.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  'Seçili mağazalar: ${selectedStoreNames.join(', ')}',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(color: cs.onSurfaceVariant),
                ),
              ],
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                children: [
                  FilledButton.icon(
                    onPressed: onAddPrice,
                    icon: const Icon(Icons.add_business_rounded),
                    label: const Text('Fiyat Ekle'),
                  ),
                  OutlinedButton.icon(
                    onPressed: onSelectStores,
                    icon: const Icon(Icons.store_mall_directory_rounded),
                    label: const Text('Mağaza Seç'),
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

String _buildShareText(List<CartMarketResultSummary> markets) {
  final rows = markets.map((m) => '${m.storeName} ${_formatCurrency(m.totalPrice)}').join(' | ');
  return 'FiyatSepeti Sonuç: $rows';
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.state, required this.onRetry});

  final CartComparisonState state;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: cs.errorContainer,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.error_outline_rounded, color: cs.onErrorContainer, size: 36),
              const SizedBox(height: 10),
              Text(
                state.errorMessage ?? 'Bir hata oluştu.',
                textAlign: TextAlign.center,
                style: TextStyle(color: cs.onErrorContainer),
              ),
              const SizedBox(height: 10),
              FilledButton(onPressed: onRetry, child: const Text('Tekrar Dene')),
            ],
          ),
        ),
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  const _Pill({required this.text, required this.color, required this.fg});

  final String text;
  final Color color;
  final Color fg;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(999)),
      child: Text(text, style: Theme.of(context).textTheme.labelMedium?.copyWith(color: fg)),
    );
  }
}

String _formatCurrency(num value) => formatTRY(value);
