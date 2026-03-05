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
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Container(
          constraints: const BoxConstraints(maxWidth: 460),
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24), border: Border.all(color: const Color(0xFF6B4226).withOpacity(0.05))),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.auto_graph_rounded, size: 52, color: Color(0xFF6B4226)),
              const SizedBox(height: 16),
              const Text('Sonuçları görmek için Hesapla', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF2A1A10))),
              const SizedBox(height: 8),
              const Text('Market bazlı toplamları premium karşılaştırma görünümünde görmek için hesaplamayı başlat.', textAlign: TextAlign.center, style: TextStyle(color: Color(0xFF9E8E82))),
              const SizedBox(height: 20),
              FilledButton.icon(
                onPressed: () { HapticFeedback.mediumImpact(); onCalculate(); },
                icon: const Icon(Icons.calculate_rounded),
                label: const Text('Hesapla'),
                style: FilledButton.styleFrom(backgroundColor: const Color(0xFF6B4226)),
              ),
              TextButton(onPressed: onGoToCart, child: const Text('Sepete dön', style: TextStyle(color: Color(0xFF6B4226)))),
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
        final shimmer = const Color(0xFF6B4226).withOpacity(alpha * 0.5);
        Widget block({double height = 16, double? width}) {
          return Container(width: width, height: height, decoration: BoxDecoration(color: shimmer, borderRadius: BorderRadius.circular(14)));
        }
        return ListView(
          padding: const EdgeInsets.all(16),
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
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 120), // Alt bar için boşluk
        children: [
          TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: 1),
            duration: const Duration(milliseconds: 420),
            curve: Curves.easeOutCubic,
            builder: (context, value, child) => Opacity(opacity: value, child: Transform.translate(offset: Offset(0, 14 * (1 - value)), child: child)),
            child: _HeroCard(best: best, totalProducts: state.missingProducts.length + best.lines.length, scrollFactor: _scrollOffset, nearest: nearest),
          ),
          const SizedBox(height: 25),
          const Text('Alternatif Marketler', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: Color(0xFF2A1A10))),
          if (widget.selectedStoreNames.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text('Seçili mağazalar: ${widget.selectedStoreNames.join(', ')}', style: const TextStyle(color: Color(0xFF9E8E82), fontSize: 12)),
          ],
          const SizedBox(height: 15),
          Container(
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24), border: Border.all(color: const Color(0xFF6B4226).withOpacity(0.05))),
            child: Column(
              children: markets.asMap().entries.map((entry) {
                  return TweenAnimationBuilder<double>(
                    tween: Tween(begin: 0, end: 1),
                    duration: Duration(milliseconds: 320 + (entry.key * 40)),
                    curve: Curves.easeOutCubic,
                    builder: (context, value, child) => Opacity(opacity: value, child: Transform.translate(offset: Offset(0, (1 - value) * 12), child: child)),
                    child: _PremiumMarketRowCard(market: entry.value, rank: entry.key + 1, minTotal: minTotal, maxTotal: maxTotal),
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
                  icon: const Icon(Icons.content_copy_rounded, color: Color(0xFF6B4226)),
                  label: const Text('Kopyala', style: TextStyle(color: Color(0xFF6B4226))),
                  style: OutlinedButton.styleFrom(side: const BorderSide(color: Color(0xFF6B4226))),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: FilledButton.icon(
                  onPressed: () => Share.share(_buildShareText(markets.take(3).toList())),
                  icon: const Icon(Icons.share_rounded),
                  label: const Text('Paylaş'),
                  style: FilledButton.styleFrom(backgroundColor: const Color(0xFF6B4226)),
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
// V15 NEFES ALAN ROZET
// ─────────────────────────────────────────────────────────────────────────────
class _PulseSavingsBadge extends StatefulWidget {
  final String text;
  const _PulseSavingsBadge({required this.text});
  @override
  State<_PulseSavingsBadge> createState() => _PulseSavingsBadgeState();
}
class _PulseSavingsBadgeState extends State<_PulseSavingsBadge> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(seconds: 2))..repeat(reverse: true);
  }
  @override
  void dispose() { _controller.dispose(); super.dispose(); }
  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.white, borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFC89B7B), width: 2),
            boxShadow: [BoxShadow(color: Colors.white.withOpacity(0.4), blurRadius: 10 + (_controller.value * 15))],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.savings_outlined, color: Color(0xFFC89B7B), size: 18),
              const SizedBox(width: 6),
              Text(widget.text, style: const TextStyle(color: Color(0xFF2A1A10), fontWeight: FontWeight.w800, fontSize: 13)),
            ],
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
  const _HeroCard({required this.best, required this.totalProducts, required this.scrollFactor, required this.nearest});
  final CartMarketResultSummary best;
  final int totalProducts;
  final double scrollFactor;
  final CartMarketResultSummary? nearest;

  @override
  Widget build(BuildContext context) {
    final parallaxY = scrollFactor * 0.15;
    final scale = scrollFactor > 80 ? 0.96 : 1 - ((scrollFactor / 80) * 0.04);
    
    // Nearest ile Best arasındaki fark, tasarrufu verir
    final saving = nearest != null && nearest!.storeId != best.storeId 
        ? nearest!.totalPrice - best.totalPrice 
        : 5.0; // Mock default

    return Transform.translate(
      offset: Offset(0, parallaxY),
      child: Transform.scale(
        scale: scale,
        alignment: Alignment.topCenter,
        child: Container(
          padding: const EdgeInsets.all(25),
          decoration: BoxDecoration(
            gradient: const LinearGradient(colors: [Color(0xFF2A1A10), Color(0xFF6B4226)], begin: Alignment.topLeft, end: Alignment.bottomRight),
            borderRadius: BorderRadius.circular(32),
            boxShadow: [BoxShadow(color: const Color(0xFF2A1A10).withOpacity(0.2), blurRadius: 40, offset: const Offset(0, 20))],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(color: const Color(0xFFC89B7B), borderRadius: BorderRadius.circular(10)),
                    child: const Row(children: [Icon(Icons.star_rounded, size: 14, color: Color(0xFF2A1A10)), SizedBox(width: 6), Text('EN UYGUN', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: Color(0xFF2A1A10)))]),
                  ),
                  _PulseSavingsBadge(text: "${formatTRY(saving)} KAZANÇ"), 
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
                      Text(best.storeName, style: const TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.w800)),
                      Text(best.missingCount > 0 ? '${best.missingCount} ürün eksik' : 'Tüm ürünler var', style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 13)),
                    ],
                  ),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(best.totalPrice.toInt().toString(), style: const TextStyle(color: Colors.white, fontSize: 42, fontWeight: FontWeight.w800, height: 1)),
                      const Padding(padding: EdgeInsets.only(left: 2, top: 4), child: Text("₺", style: TextStyle(color: Color(0xFFC89B7B), fontSize: 20, fontWeight: FontWeight.w600))),
                    ],
                  )
                ],
              ),
              const SizedBox(height: 25),
              ElevatedButton(
                onPressed: () {}, // TODO: Markete git rotası
                style: ElevatedButton.styleFrom(backgroundColor: Colors.white, foregroundColor: const Color(0xFF2A1A10), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)), padding: const EdgeInsets.symmetric(vertical: 14), minimumSize: const Size(double.infinity, 50)),
                child: const Row(mainAxisAlignment: MainAxisAlignment.center, children: [Text("Markete Git", style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)), SizedBox(width: 8), Icon(Icons.directions_walk_rounded, size: 20)]),
              )
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
  const _PremiumMarketRowCard({required this.market, required this.rank, required this.minTotal, required this.maxTotal});
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
    final isError = widget.market.missingCount > 0;
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 20),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Color(0x0F6B4226))),
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
                      decoration: BoxDecoration(color: isError ? const Color(0x1AA33333) : (widget.rank == 1 ? const Color(0xFFC89B7B) : const Color(0x0F6B4226)), borderRadius: BorderRadius.circular(10)),
                      child: Center(child: Text(isError ? '!' : '${widget.rank}', style: TextStyle(fontWeight: FontWeight.w800, fontSize: isError ? 16 : 14, color: isError ? const Color(0xFFA33333) : (widget.rank == 1 ? const Color(0xFF2A1A10) : const Color(0xFF9E8E82))))),
                    ),
                    const SizedBox(width: 14),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(widget.market.storeName, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16, color: Color(0xFF2A1A10))),
                        Text(isError ? '${widget.market.missingCount} Eksik' : '${widget.market.distanceKm?.toStringAsFixed(1) ?? "0.5"} km • Eksik Yok', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: isError ? const Color(0xFFA33333) : const Color(0xFF9E8E82))),
                      ],
                    ),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(formatTRY(widget.market.totalPrice), style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 18, color: Color(0xFF2A1A10))),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(color: isError ? const Color(0x1AA33333) : const Color(0x1FB58461), borderRadius: BorderRadius.circular(8)),
                      child: Text(isError ? 'Stok Yok' : '+${formatTRY(widget.market.totalPrice - widget.minTotal)} Fark', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: isError ? const Color(0xFFA33333) : const Color(0xFFB58461))),
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
              padding: const EdgeInsets.only(top: 15, left: 46),
              child: Column(
                children: widget.market.lines.map((line) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(child: Text('${line.quantity}x ${line.productName}', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: Color(0xFF2A1A10)))),
                        const SizedBox(width: 10),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(color: const Color(0x14A33333), borderRadius: BorderRadius.circular(8)),
                          child: Text(formatTRY(line.lineTotal), style: const TextStyle(color: Color(0xFFA33333), fontWeight: FontWeight.w800, fontSize: 12)),
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
      padding: const EdgeInsets.all(24),
      children: [
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), border: Border.all(color: const Color(0xFF6B4226).withOpacity(0.05))),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Yeterli fiyat verisi yok', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF2A1A10))),
              const SizedBox(height: 8),
              if (state.missingProducts.isNotEmpty) ...[
                const Text('Fiyatı olmayan ürünler:', style: TextStyle(color: Color(0xFFA33333))),
                const SizedBox(height: 8),
                ...state.missingProducts.take(5).map((name) => Padding(padding: const EdgeInsets.only(bottom: 6), child: Text('• $name', style: const TextStyle(color: Color(0xFF9E8E82))))),
              ],
              const SizedBox(height: 15),
              Wrap(
                spacing: 8,
                children: [
                  FilledButton.icon(
                    onPressed: onAddPrice,
                    icon: const Icon(Icons.add_business_rounded),
                    label: const Text('Fiyat Ekle'),
                    style: FilledButton.styleFrom(backgroundColor: const Color(0xFF6B4226)),
                  ),
                  OutlinedButton.icon(
                    onPressed: onSelectStores,
                    icon: const Icon(Icons.store_mall_directory_rounded, color: Color(0xFF6B4226)),
                    label: const Text('Mağaza Seç', style: TextStyle(color: Color(0xFF6B4226))),
                    style: OutlinedButton.styleFrom(side: const BorderSide(color: Color(0xFF6B4226))),
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
        padding: const EdgeInsets.all(24),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(color: const Color(0x1AA33333), borderRadius: BorderRadius.circular(20)),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline_rounded, color: Color(0xFFA33333), size: 36),
              const SizedBox(height: 10),
              Text(state.errorMessage ?? 'Bir hata oluştu.', textAlign: TextAlign.center, style: const TextStyle(color: Color(0xFFA33333))),
              const SizedBox(height: 10),
              FilledButton(onPressed: onRetry, style: FilledButton.styleFrom(backgroundColor: const Color(0xFFA33333)), child: const Text('Tekrar Dene')),
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
