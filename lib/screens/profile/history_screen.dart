import 'package:flutter/material.dart';
import '../../models/product.dart';
import '../../state/app_state.dart';
import '../../theme.dart';
import '../../widgets/design.dart';
import '../product_detail_screen.dart';

class HistoryScreen extends StatelessWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = AppStateScope.of(context);
    final userName = state.user?.displayName ?? 'Sen';

    // Collect all price entries by this user
    final entries = <_HistoryEntry>[];
    for (final p in state.products) {
      for (final e in p.priceHistory) {
        if (e.reportedBy == userName || e.reportedBy == 'Sen') {
          entries.add(_HistoryEntry(product: p, entry: e));
        }
      }
    }
    entries.sort((a, b) => b.entry.date.compareTo(a.entry.date));

    return Scaffold(
      backgroundColor: CoffeeColors.cream,
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Geçmiş Eklemeler'),
            if (entries.isNotEmpty)
              Text(
                '${entries.length} katkı · +${entries.length * 10} puan',
                style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: CoffeeColors.cocoa),
              ),
          ],
        ),
      ),
      body: entries.isEmpty
          ? _EmptyHistory()
          : ListView.builder(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 40),
              itemCount: entries.length,
              itemBuilder: (context, i) =>
                  _HistoryRow(entry: entries[i]),
            ),
    );
  }
}

class _HistoryEntry {
  final Product product;
  final PriceEntry entry;
  const _HistoryEntry({required this.product, required this.entry});
}

class _EmptyHistory extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: CoffeeColors.foam,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: CoffeeColors.crema),
            ),
            alignment: Alignment.center,
            child: const Icon(Icons.add_chart,
                color: CoffeeColors.caramel, size: 36),
          ),
          const SizedBox(height: 16),
          const Text(
            'Henüz katkın yok',
            style: TextStyle(
                color: CoffeeColors.espresso,
                fontSize: 17,
                fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 6),
          const Text(
            'Fiyat Ekle sekmesinden ilk katkını yap\nve puan kazan',
            textAlign: TextAlign.center,
            style: TextStyle(color: CoffeeColors.cocoa, fontSize: 13),
          ),
        ],
      ),
    );
  }
}

class _HistoryRow extends StatelessWidget {
  const _HistoryRow({required this.entry});
  final _HistoryEntry entry;

  @override
  Widget build(BuildContext context) {
    final isLowest = entry.product.lowestPrice != null &&
        entry.entry.price <= entry.product.lowestPrice!;

    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
            builder: (_) =>
                ProductDetailScreen(product: entry.product)),
      ),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: isLowest
                ? CoffeeColors.caramel.withOpacity(0.4)
                : CoffeeColors.crema,
          ),
          boxShadow: FR.softShadow,
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [CoffeeColors.foam, CoffeeColors.crema],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(13),
              ),
              alignment: Alignment.center,
              child: Text(entry.product.emoji,
                  style: const TextStyle(fontSize: 24)),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    entry.product.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      color: CoffeeColors.espresso,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Row(
                    children: [
                      StoreBadge(entry.entry.store, dark: false),
                      const SizedBox(width: 6),
                      FreshnessChip(date: entry.entry.date),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                PriceText(
                  entry.entry.price,
                  size: 16,
                  color: isLowest
                      ? CoffeeColors.success
                      : CoffeeColors.espresso,
                ),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: CoffeeColors.caramel.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text(
                    '+10 puan',
                    style: TextStyle(
                      color: CoffeeColors.caramel,
                      fontWeight: FontWeight.w800,
                      fontSize: 10,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
