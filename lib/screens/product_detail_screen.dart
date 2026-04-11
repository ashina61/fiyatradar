import 'dart:ui';

import 'package:flutter/material.dart';

import '../models/product.dart';
import '../state/app_state.dart';
import '../theme.dart';
import '../widgets/design.dart';

class ProductDetailScreen extends StatelessWidget {
  const ProductDetailScreen({super.key, required this.product});

  final Product product;

  @override
  Widget build(BuildContext context) {
    final state = AppStateScope.of(context);
    final isFav = state.isFavorite(product.id);
    final alert = state.alertForProduct(product.id);

    final history = [...product.priceHistory]..sort((a, b) => b.date.compareTo(a.date));
    final ascHistory = history.reversed.toList();
    final lowest = product.lowestPrice;
    final latest = product.latestPrice;
    final changePct = product.priceChangePct;
    final hasDrop = changePct != null && changePct < 0;

    final contributors = history.map((e) => e.reportedBy).toSet().length;
    final lastDate = history.isNotEmpty ? history.first.date : null;

    final Map<String, PriceEntry> bestPerStore = {};
    final Map<String, PriceEntry> latestPerStore = {};
    final Map<String, int> storeEntryCount = {};
    for (final e in history) {
      final best = bestPerStore[e.store];
      if (best == null || e.price < best.price) bestPerStore[e.store] = e;
      latestPerStore.putIfAbsent(e.store, () => e);
      storeEntryCount[e.store] = (storeEntryCount[e.store] ?? 0) + 1;
    }

    final perStoreSorted = bestPerStore.values.toList()..sort((a, b) => a.price.compareTo(b.price));

    return Scaffold(
      backgroundColor: CoffeeColors.cream,
      appBar: AppBar(
        title: const Text('Ürün Detay'),
      ),
      body: Stack(
        children: [
          ListView(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 168),
            children: [
              _ProductHeroCard(
                product: product,
                isFavorite: isFav,
                changePct: changePct,
                lastDate: lastDate,
                historyCount: history.length,
                onFavorite: () => state.toggleFavorite(product.id),
                onShare: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Paylaşım yakında aktif olacak.')),
                  );
                },
              ),
              const SizedBox(height: 16),
              _BestPricePanel(
                lowest: lowest,
                cheapestStore: product.cheapestStore,
                latest: latest,
                lastSeen: lastDate,
                changePct: changePct,
                hasDrop: hasDrop,
                isSinglePrice: history.length == 1,
                limitedMarket: perStoreSorted.length <= 1,
              ),
              const SizedBox(height: 18),
              const SectionHeader(
                title: 'Market Teklifleri',
                subtitle: 'Market bazında en iyi fiyat, kayıt ve zaman bilgisi',
              ),
              const SizedBox(height: 10),
              if (perStoreSorted.isEmpty)
                const _SimpleEmptyCard(
                  title: 'Market verisi yok',
                  subtitle: 'Henüz bu ürün için market bazlı kayıt bulunmuyor.',
                )
              else
                ...List.generate(perStoreSorted.length, (index) {
                  final best = perStoreSorted[index];
                  final latestEntry = latestPerStore[best.store] ?? best;
                  return _MarketOfferCard(
                    rank: index + 1,
                    isBest: index == 0,
                    best: best,
                    latest: latestEntry,
                    entryCount: storeEntryCount[best.store] ?? 1,
                    lowest: lowest,
                  );
                }),
              const SizedBox(height: 20),
              const SectionHeader(
                title: 'Fiyat Geçmişi',
                subtitle: 'Trend ve zaman akışı',
              ),
              const SizedBox(height: 10),
              _PriceHistoryPanel(
                history: history,
                ascHistory: ascHistory,
                lowest: lowest,
                latest: latest,
                changePct: changePct,
              ),
              const SizedBox(height: 20),
              _TrustMetaPanel(
                contributors: contributors,
                entries: history.length,
                markets: perStoreSorted.length,
                lastDate: lastDate,
                alarmSet: alert != null,
              ),
            ],
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: _StickyActionBar(product: product),
          ),
        ],
      ),
    );
  }
}

class _ProductHeroCard extends StatelessWidget {
  const _ProductHeroCard({
    required this.product,
    required this.isFavorite,
    required this.changePct,
    required this.lastDate,
    required this.historyCount,
    required this.onFavorite,
    required this.onShare,
  });

  final Product product;
  final bool isFavorite;
  final double? changePct;
  final DateTime? lastDate;
  final int historyCount;
  final VoidCallback onFavorite;
  final VoidCallback onShare;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [CoffeeColors.espresso, CoffeeColors.darkRoast],
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: CoffeeColors.espresso.withOpacity(0.24),
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              EyebrowLabel(product.category.toUpperCase()),
              const Spacer(),
              _HeroActionButton(
                icon: isFavorite ? Icons.favorite_rounded : Icons.favorite_border,
                color: isFavorite ? CoffeeColors.caramel : CoffeeColors.latte,
                onTap: onFavorite,
              ),
              const SizedBox(width: 8),
              _HeroActionButton(
                icon: Icons.share_outlined,
                color: CoffeeColors.latte,
                onTap: onShare,
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Container(
                width: 78,
                height: 78,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.white.withOpacity(0.1)),
                ),
                alignment: Alignment.center,
                child: Text(product.emoji, style: const TextStyle(fontSize: 44)),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      product.name,
                      style: const TextStyle(
                        color: CoffeeColors.cream,
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.4,
                        height: 1.2,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      product.brand,
                      style: const TextStyle(
                        color: CoffeeColors.latte,
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: [
                        _HeroMetaChip(icon: Icons.inventory_2_outlined, label: product.unit),
                        _HeroMetaChip(icon: Icons.history, label: '$historyCount kayıt'),
                        _HeroMetaChip(
                          icon: Icons.schedule,
                          label: lastDate == null ? 'veri yok' : _agoShort(lastDate!),
                        ),
                        if (changePct != null) TrendPill(pct: changePct!),
                      ],
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

class _HeroActionButton extends StatelessWidget {
  const _HeroActionButton({required this.icon, required this.color, required this.onTap});

  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 34,
        height: 34,
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.08),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Colors.white.withOpacity(0.12)),
        ),
        alignment: Alignment.center,
        child: Icon(icon, size: 18, color: color),
      ),
    );
  }
}

class _HeroMetaChip extends StatelessWidget {
  const _HeroMetaChip({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.08),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.white.withOpacity(0.12)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: CoffeeColors.latte),
          const SizedBox(width: 4),
          Text(
            label,
            style: const TextStyle(color: CoffeeColors.latte, fontSize: 11, fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }
}

class _BestPricePanel extends StatelessWidget {
  const _BestPricePanel({
    required this.lowest,
    required this.cheapestStore,
    required this.latest,
    required this.lastSeen,
    required this.changePct,
    required this.hasDrop,
    required this.isSinglePrice,
    required this.limitedMarket,
  });

  final double? lowest;
  final String? cheapestStore;
  final double? latest;
  final DateTime? lastSeen;
  final double? changePct;
  final bool hasDrop;
  final bool isSinglePrice;
  final bool limitedMarket;

  @override
  Widget build(BuildContext context) {
    if (lowest == null || cheapestStore == null) {
      return const _SimpleEmptyCard(
        title: 'En düşük fiyat henüz yok',
        subtitle: 'Bu ürün için fiyat kaydı oluştuğunda en iyi market burada net olarak görünecek.',
      );
    }

    final lowestValue = lowest!;
    final latestValue = latest;
    final advantage = (latestValue != null && latestValue > lowestValue) ? latestValue - lowestValue : null;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: CoffeeColors.crema),
        boxShadow: FR.softShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const EyebrowLabel('EN DÜŞÜK FİYAT'),
              const Spacer(),
              if (isSinglePrice)
                const _InlineStatusPill(label: 'TEK KAYIT')
              else if (limitedMarket)
                const _InlineStatusPill(label: 'SINIRLI MARKET'),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '₺${lowestValue.toStringAsFixed(2)}',
                style: const TextStyle(
                  color: CoffeeColors.espresso,
                  fontSize: 34,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.8,
                  fontFeatures: [FontFeature.tabularFigures()],
                ),
              ),
              const SizedBox(width: 8),
              const Padding(
                padding: EdgeInsets.only(bottom: 6),
                child: Text('en iyi değer', style: TextStyle(color: CoffeeColors.cocoa, fontSize: 11)),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: CoffeeColors.foam,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: CoffeeColors.crema),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.storefront_outlined, size: 14, color: CoffeeColors.darkRoast),
                    const SizedBox(width: 6),
                    Text(
                      cheapestStore!,
                      style: const TextStyle(color: CoffeeColors.darkRoast, fontWeight: FontWeight.w800, fontSize: 12),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Text(
                lastSeen == null ? 'zaman yok' : 'son: ${_agoShort(lastSeen!)}',
                style: const TextStyle(color: CoffeeColors.cocoa, fontSize: 11),
              ),
            ],
          ),
          if (hasDrop && changePct != null) ...[
            const SizedBox(height: 10),
            Text(
              '${changePct!.toStringAsFixed(1)}% düşüş trendi',
              style: const TextStyle(color: CoffeeColors.success, fontSize: 12, fontWeight: FontWeight.w700),
            ),
          ],
          if (advantage != null && advantage > 0) ...[
            const SizedBox(height: 6),
            Text(
              'Son fiyata göre ₺${advantage.toStringAsFixed(2)} avantaj',
              style: const TextStyle(color: CoffeeColors.accent, fontSize: 12, fontWeight: FontWeight.w700),
            ),
          ],
        ],
      ),
    );
  }
}

class _InlineStatusPill extends StatelessWidget {
  const _InlineStatusPill({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
      decoration: BoxDecoration(
        color: CoffeeColors.foam,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: CoffeeColors.crema),
      ),
      child: Text(
        label,
        style: const TextStyle(color: CoffeeColors.cocoa, fontSize: 10, fontWeight: FontWeight.w800),
      ),
    );
  }
}

class _MarketOfferCard extends StatelessWidget {
  const _MarketOfferCard({
    required this.rank,
    required this.isBest,
    required this.best,
    required this.latest,
    required this.entryCount,
    required this.lowest,
  });

  final int rank;
  final bool isBest;
  final PriceEntry best;
  final PriceEntry latest;
  final int entryCount;
  final double? lowest;

  @override
  Widget build(BuildContext context) {
    final contributedByUser = best.reportedBy.trim().toLowerCase() == 'sen';
    final diffFromBest = (lowest != null && best.price > lowest!) ? best.price - lowest! : 0.0;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isBest ? CoffeeColors.caramel.withOpacity(0.4) : CoffeeColors.crema,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 30,
            height: 30,
            decoration: BoxDecoration(
              color: isBest ? CoffeeColors.caramel : CoffeeColors.foam,
              borderRadius: BorderRadius.circular(9),
            ),
            alignment: Alignment.center,
            child: Text(
              '$rank',
              style: TextStyle(
                color: isBest ? CoffeeColors.espresso : CoffeeColors.cocoa,
                fontWeight: FontWeight.w800,
                fontSize: 12,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      best.store,
                      style: const TextStyle(color: CoffeeColors.espresso, fontSize: 13, fontWeight: FontWeight.w800),
                    ),
                    if (isBest) ...[
                      const SizedBox(width: 6),
                      const EyebrowLabel('EN İYİ'),
                    ],
                    if (contributedByUser) ...[
                      const SizedBox(width: 6),
                      const _InlineStatusPill(label: 'SENİN KAYDIN'),
                    ],
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  '${entryCount} kayıt · güncel ${_agoShort(latest.date)}',
                  style: const TextStyle(color: CoffeeColors.cocoa, fontSize: 11),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              PriceText(
                best.price,
                size: 16,
                color: isBest ? CoffeeColors.success : CoffeeColors.espresso,
              ),
              if (diffFromBest > 0)
                Text(
                  '+₺${diffFromBest.toStringAsFixed(2)}',
                  style: const TextStyle(
                    color: CoffeeColors.danger,
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    fontFeatures: [FontFeature.tabularFigures()],
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _PriceHistoryPanel extends StatelessWidget {
  const _PriceHistoryPanel({
    required this.history,
    required this.ascHistory,
    required this.lowest,
    required this.latest,
    required this.changePct,
  });

  final List<PriceEntry> history;
  final List<PriceEntry> ascHistory;
  final double? lowest;
  final double? latest;
  final double? changePct;

  @override
  Widget build(BuildContext context) {
    if (history.isEmpty) {
      return const _SimpleEmptyCard(
        title: 'Fiyat geçmişi yok',
        subtitle: 'İlk fiyat kaydı ile bu alan trend görünümüne dönüşecek.',
      );
    }

    if (history.length == 1) {
      final first = history.first;
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: CoffeeColors.crema),
        ),
        child: Row(
          children: [
            const Icon(Icons.timeline, color: CoffeeColors.caramel),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                'Tek fiyat kaydı mevcut: ${first.store} · ${_agoShort(first.date)}',
                style: const TextStyle(color: CoffeeColors.darkRoast, fontSize: 12, fontWeight: FontWeight.w700),
              ),
            ),
            PriceText(first.price, size: 15),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: CoffeeColors.crema),
        boxShadow: FR.softShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              PriceText(latest, size: 22),
              const SizedBox(width: 8),
              if (changePct != null) TrendPill(pct: changePct!),
              const Spacer(),
              Text(
                '${history.length} kayıt',
                style: const TextStyle(color: CoffeeColors.cocoa, fontSize: 11),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Sparkline(values: ascHistory.map((e) => e.price).toList(), height: 72),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(_agoShort(ascHistory.first.date), style: const TextStyle(color: CoffeeColors.cocoa, fontSize: 10)),
              Text(
                lowest == null ? 'min yok' : 'min ₺${lowest!.toStringAsFixed(2)}',
                style: const TextStyle(color: CoffeeColors.success, fontSize: 10, fontWeight: FontWeight.w700),
              ),
              const Text('şimdi', style: TextStyle(color: CoffeeColors.cocoa, fontSize: 10)),
            ],
          ),
          const SizedBox(height: 12),
          ...history.take(4).map((e) => _HistoryRow(entry: e, lowest: lowest)),
        ],
      ),
    );
  }
}

class _HistoryRow extends StatelessWidget {
  const _HistoryRow({required this.entry, required this.lowest});

  final PriceEntry entry;
  final double? lowest;

  @override
  Widget build(BuildContext context) {
    final isLowest = lowest != null && entry.price <= lowest!;

    return Container(
      margin: const EdgeInsets.only(top: 6),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: CoffeeColors.foam,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              '${entry.store} · ${entry.reportedBy}',
              style: const TextStyle(color: CoffeeColors.darkRoast, fontSize: 11, fontWeight: FontWeight.w700),
            ),
          ),
          Text(_agoShort(entry.date), style: const TextStyle(color: CoffeeColors.cocoa, fontSize: 10)),
          const SizedBox(width: 8),
          Text(
            '₺${entry.price.toStringAsFixed(2)}',
            style: TextStyle(
              color: isLowest ? CoffeeColors.success : CoffeeColors.espresso,
              fontWeight: FontWeight.w800,
              fontSize: 12,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
        ],
      ),
    );
  }
}

class _TrustMetaPanel extends StatelessWidget {
  const _TrustMetaPanel({
    required this.contributors,
    required this.entries,
    required this.markets,
    required this.lastDate,
    required this.alarmSet,
  });

  final int contributors;
  final int entries;
  final int markets;
  final DateTime? lastDate;
  final bool alarmSet;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: CoffeeColors.foam,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: CoffeeColors.crema),
      ),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          _MetaPill(icon: Icons.people_alt_outlined, label: '$contributors katkıcı'),
          _MetaPill(icon: Icons.receipt_long_outlined, label: '$entries kayıt'),
          _MetaPill(icon: Icons.storefront_outlined, label: '$markets market'),
          _MetaPill(
            icon: alarmSet ? Icons.notifications_active : Icons.notifications_none,
            label: alarmSet ? 'Alarm kurulu' : 'Alarm kurulu değil',
          ),
          _MetaPill(
            icon: Icons.update,
            label: lastDate == null ? 'Güncelleme yok' : 'Son güncelleme ${_agoShort(lastDate!)}',
          ),
        ],
      ),
    );
  }
}

class _MetaPill extends StatelessWidget {
  const _MetaPill({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: CoffeeColors.crema),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: CoffeeColors.cocoa),
          const SizedBox(width: 6),
          Text(label, style: const TextStyle(color: CoffeeColors.darkRoast, fontSize: 11, fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }
}

class _SimpleEmptyCard extends StatelessWidget {
  const _SimpleEmptyCard({required this.title, required this.subtitle});

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: CoffeeColors.crema),
      ),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: CoffeeColors.foam,
              borderRadius: BorderRadius.circular(10),
            ),
            alignment: Alignment.center,
            child: const Icon(Icons.info_outline, color: CoffeeColors.caramel, size: 18),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(color: CoffeeColors.espresso, fontWeight: FontWeight.w800, fontSize: 13),
                ),
                const SizedBox(height: 2),
                Text(subtitle, style: const TextStyle(color: CoffeeColors.cocoa, fontSize: 11, height: 1.35)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

String _agoShort(DateTime d) {
  final diff = DateTime.now().difference(d);
  if (diff.inDays > 7) return '${(diff.inDays / 7).floor()}h önce';
  if (diff.inDays > 0) return '${diff.inDays}g önce';
  if (diff.inHours > 0) return '${diff.inHours}sa önce';
  if (diff.inMinutes > 0) return '${diff.inMinutes}dk önce';
  return 'az önce';
}

class _StickyActionBar extends StatefulWidget {
  const _StickyActionBar({required this.product});

  final Product product;

  @override
  State<_StickyActionBar> createState() => _StickyActionBarState();
}

class _StickyActionBarState extends State<_StickyActionBar> {
  bool _addingToCompare = false;

  Future<void> _openTargetPriceDialog(AppState state) async {
    final existing = state.alertForProduct(widget.product.id);
    final ctrl = TextEditingController(
      text: existing == null ? '' : existing.targetPrice.toStringAsFixed(2),
    );
    final target = await showDialog<double>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Hedef fiyat'),
          content: TextField(
            controller: ctrl,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: const InputDecoration(
              hintText: 'Örn: 49,90',
              prefixText: '₺ ',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Vazgeç'),
            ),
            ElevatedButton(
              onPressed: () {
                final raw = ctrl.text.trim().replaceAll(',', '.');
                final parsed = double.tryParse(raw);
                if (parsed == null || parsed <= 0) return;
                Navigator.pop(context, parsed);
              },
              child: const Text('Kaydet'),
            ),
          ],
        );
      },
    );
    ctrl.dispose();
    if (target == null) return;
    await state.setProductAlert(
      productId: widget.product.id,
      targetPrice: target,
    );
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${widget.product.name} için hedef fiyat ₺${target.toStringAsFixed(2)} kaydedildi'),
        backgroundColor: CoffeeColors.darkRoast,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 80),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = AppStateScope.of(context);
    final alert = state.alertForProduct(widget.product.id);
    final alarmSet = alert != null;

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 24),
      decoration: BoxDecoration(
        color: CoffeeColors.cream.withOpacity(0.97),
        border: const Border(top: BorderSide(color: CoffeeColors.crema, width: 1.5)),
        boxShadow: [
          BoxShadow(
            color: CoffeeColors.espresso.withOpacity(0.06),
            blurRadius: 20,
            offset: const Offset(0, -6),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => _openTargetPriceDialog(state),
                icon: Icon(
                  alarmSet ? Icons.notifications_active : Icons.notifications_none,
                  size: 18,
                ),
                label: Text(alarmSet ? 'Alarm Güncelle' : 'Alarm Kur'),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size(0, 52),
                  foregroundColor: CoffeeColors.darkRoast,
                  side: BorderSide(color: alarmSet ? CoffeeColors.espresso : CoffeeColors.crema),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: ElevatedButton.icon(
                onPressed: _addingToCompare
                    ? null
                    : () async {
                        setState(() => _addingToCompare = true);
                        await state.addToCart(widget.product);
                        await Future.delayed(const Duration(milliseconds: 360));
                        if (!mounted) return;
                        setState(() => _addingToCompare = false);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('${widget.product.name} karşılaştırmaya eklendi'),
                            backgroundColor: CoffeeColors.darkRoast,
                            behavior: SnackBarBehavior.floating,
                            margin: const EdgeInsets.fromLTRB(16, 0, 16, 80),
                          ),
                        );
                      },
                icon: _addingToCompare
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2, color: CoffeeColors.cream),
                      )
                    : const Icon(Icons.balance_outlined, size: 18),
                label: const Text('Karşılaştırmaya Ekle'),
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(0, 52),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
