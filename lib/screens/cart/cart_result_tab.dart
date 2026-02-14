import 'package:flutter/material.dart';

import '../../features/basket/cart_comparison_state.dart';
import '../../utils/formatters.dart';

class CartResultTab extends StatelessWidget {
  const CartResultTab({
    super.key,
    required this.state,
    required this.onCalculate,
    required this.onGoToCart,
    required this.onAddPrice,
    required this.onRetry,
  });

  final CartComparisonState state;
  final VoidCallback onCalculate;
  final VoidCallback onGoToCart;
  final VoidCallback onAddPrice;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    switch (state.status) {
      case CartComparisonStatus.idle:
        return _IdleState(onCalculate: onCalculate, onGoToCart: onGoToCart);
      case CartComparisonStatus.loading:
        return const _LoadingState();
      case CartComparisonStatus.success:
        return _SuccessState(state: state);
      case CartComparisonStatus.empty:
        return _EmptyState(state: state, onAddPrice: onAddPrice, onCalculate: onCalculate);
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
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.analytics_outlined, size: 52, color: theme.colorScheme.primary),
            const SizedBox(height: 12),
            Text('Sonuçları görmek için hesapla', style: theme.textTheme.headlineSmall),
            const SizedBox(height: 8),
            Text(
              'Sepete ürün ekle, Hesapla’ya bas',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
            ),
            const SizedBox(height: 16),
            FilledButton.icon(onPressed: onCalculate, icon: const Icon(Icons.calculate), label: const Text('Hesapla')),
            const SizedBox(height: 8),
            TextButton(onPressed: onGoToCart, child: const Text('Sepete dön')),
          ],
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
    duration: const Duration(milliseconds: 1000),
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
        final alpha = 0.18 + (0.24 * _controller.value);
        final color = cs.surfaceContainerHighest.withOpacity(alpha);
        Widget block({double h = 16, double? w}) => Container(
              height: h,
              width: w,
              decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(12)),
            );

        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            block(h: 160),
            const SizedBox(height: 12),
            Row(children: [Expanded(child: block(h: 88)), const SizedBox(width: 10), Expanded(child: block(h: 88))]),
            const SizedBox(height: 16),
            block(h: 18, w: 180),
            const SizedBox(height: 10),
            block(h: 68),
            const SizedBox(height: 8),
            block(h: 68),
            const SizedBox(height: 8),
            block(h: 68),
          ],
        );
      },
    );
  }
}

class _SuccessState extends StatelessWidget {
  const _SuccessState({required this.state});

  final CartComparisonState state;

  @override
  Widget build(BuildContext context) {
    final best = state.bestMarket;
    if (best == null) return const SizedBox.shrink();
    final nearest = state.nearestMarket;
    final secondBest = state.topMarkets.length > 1 ? state.topMarkets[1] : null;
    final savings = (nearest != null) ? (nearest.totalPrice - best.totalPrice) : null;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _HeroCard(best: best),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: _MiniInfoCard(
                title: 'En Yakın',
                subtitle: nearest?.storeName ?? 'Konum yok',
                trailing: nearest != null ? '${nearest.distanceKm?.toStringAsFixed(1) ?? '-'} km' : '-',
                value: nearest != null ? formatTRY(nearest.totalPrice) : '—',
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _MiniInfoCard(
                title: savings != null ? 'Tasarruf' : '2. En İyi',
                subtitle: savings != null ? 'En yakına göre' : (secondBest?.storeName ?? 'Veri yok'),
                trailing: '',
                value: savings != null ? formatTRY(savings) : (secondBest != null ? formatTRY(secondBest.totalPrice) : '—'),
              ),
            ),
          ],
        ),
        const SizedBox(height: 18),
        Text('En Düşük Marketler', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        ...state.topMarkets.map((market) => _MarketBreakdownTile(market: market)),
        const SizedBox(height: 8),
        Text(
          'Fiyatlar kullanıcı bildirimi olabilir.',
          style: Theme.of(context)
              .textTheme
              .bodySmall
              ?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant),
        ),
      ],
    );
  }
}

class _HeroCard extends StatelessWidget {
  const _HeroCard({required this.best});

  final CartMarketResultSummary best;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: LinearGradient(
          colors: [cs.primaryContainer, cs.secondaryContainer],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('En Uygun Market', style: Theme.of(context).textTheme.titleSmall?.copyWith(color: cs.primary)),
          const SizedBox(height: 6),
          Text(best.storeName, style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: 8),
          Text(formatTRY(best.totalPrice), style: Theme.of(context).textTheme.displaySmall),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              if (best.missingCount > 0)
                _Badge(text: '${best.missingCount} eksik ürün', bg: cs.errorContainer, fg: cs.onErrorContainer),
              if (best.distanceKm != null)
                _Badge(text: '${best.distanceKm!.toStringAsFixed(1)} km', bg: cs.surface, fg: cs.onSurface),
            ],
          ),
        ],
      ),
    );
  }
}

class _MarketBreakdownTile extends StatelessWidget {
  const _MarketBreakdownTile({required this.market});

  final CartMarketResultSummary market;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ExpansionTile(
        tilePadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
        title: Text(market.storeName),
        subtitle: market.missingCount > 0
            ? Text('${market.missingCount} eksik ürün', style: TextStyle(color: cs.error))
            : const Text('Tüm ürünler mevcut'),
        trailing: Text(formatTRY(market.totalPrice), style: Theme.of(context).textTheme.titleMedium),
        children: market.lines
            .map(
              (line) => ListTile(
                dense: true,
                title: Text(line.productName),
                subtitle: Text('${line.quantity} adet • ${formatTRY(line.unitPrice)}'),
                trailing: Text(formatTRY(line.lineTotal)),
              ),
            )
            .toList(),
      ),
    );
  }
}

class _MiniInfoCard extends StatelessWidget {
  const _MiniInfoCard({
    required this.title,
    required this.subtitle,
    required this.trailing,
    required this.value,
  });

  final String title;
  final String subtitle;
  final String trailing;
  final String value;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: cs.surfaceContainerHigh,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: Theme.of(context).textTheme.labelLarge),
          const SizedBox(height: 2),
          Text(subtitle, maxLines: 1, overflow: TextOverflow.ellipsis),
          if (trailing.isNotEmpty)
            Text(trailing, style: Theme.of(context).textTheme.bodySmall?.copyWith(color: cs.onSurfaceVariant)),
          const SizedBox(height: 8),
          Text(value, style: Theme.of(context).textTheme.titleMedium),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.state, required this.onAddPrice, required this.onCalculate});

  final CartComparisonState state;
  final VoidCallback onAddPrice;
  final VoidCallback onCalculate;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Bu sepet için yeterli fiyat verisi yok', style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 8),
                Text(state.emptyReason ?? 'Lütfen farklı ürünler deneyin ya da fiyat ekleyin.'),
                const SizedBox(height: 12),
                if (state.missingProducts.isNotEmpty) ...[
                  Text('Fiyatı olmayan ürünler', style: Theme.of(context).textTheme.titleSmall),
                  const SizedBox(height: 8),
                  ...state.missingProducts.take(5).map((name) => ListTile(
                        contentPadding: EdgeInsets.zero,
                        dense: true,
                        leading: const Icon(Icons.info_outline),
                        title: Text(name),
                      )),
                ],
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  children: [
                    FilledButton.icon(onPressed: onAddPrice, icon: const Icon(Icons.add_chart), label: const Text('Fiyat Ekle')),
                    OutlinedButton(onPressed: onCalculate, child: const Text('Tekrar Hesapla')),
                  ],
                ),
              ],
            ),
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
    final cs = Theme.of(context).colorScheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Card(
          color: cs.errorContainer,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.error_outline, color: cs.onErrorContainer, size: 36),
                const SizedBox(height: 10),
                Text(
                  state.errorMessage ?? 'Bir hata oluştu.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: cs.onErrorContainer),
                ),
                const SizedBox(height: 12),
                FilledButton(onPressed: onRetry, child: const Text('Tekrar Dene')),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  const _Badge({required this.text, required this.bg, required this.fg});

  final String text;
  final Color bg;
  final Color fg;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(999)),
      child: Text(text, style: Theme.of(context).textTheme.labelMedium?.copyWith(color: fg)),
    );
  }
}
