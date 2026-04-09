import 'package:flutter/material.dart';

import '../../models/product.dart';
import '../../state/app_state.dart';
import '../../theme.dart';
import '../../widgets/design.dart';
import '../product_detail_screen.dart';

class AlertsScreen extends StatelessWidget {
  const AlertsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = AppStateScope.of(context);
    final alertEntries = state.productAlerts.entries.toList()
      ..sort((a, b) => b.value.createdAt.compareTo(a.value.createdAt));
    final activeAlerts = <MapEntry<Product, double>>[];
    for (final entry in alertEntries) {
      final product = state.findById(entry.key);
      if (product == null) continue;
      activeAlerts.add(MapEntry(product, entry.value.targetPrice));
    }

    return Scaffold(
      backgroundColor: CoffeeColors.cream,
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Fiyat Alarmlarım'),
            if (activeAlerts.isNotEmpty)
              Text(
                '${activeAlerts.length} aktif alarm',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: CoffeeColors.cocoa,
                ),
              ),
          ],
        ),
      ),
      body: activeAlerts.isEmpty
          ? const _EmptyAlerts()
          : ListView(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 40),
              children: [
                Container(
                  padding: const EdgeInsets.all(14),
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: CoffeeColors.caramel.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: CoffeeColors.caramel.withOpacity(0.3),
                    ),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.info_outline,
                          color: CoffeeColors.caramel, size: 18),
                      SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Hedef fiyat alarmın ürün detayındaki Alarm Kur akışından yönetilir.',
                          style: TextStyle(
                            color: CoffeeColors.darkRoast,
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                ...activeAlerts.map((e) {
                  final p = e.key;
                  return GestureDetector(
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ProductDetailScreen(product: p),
                      ),
                    ),
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 10),
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(
                          color: CoffeeColors.caramel.withOpacity(0.4),
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
                            child: Text(
                              p.emoji,
                              style: const TextStyle(fontSize: 24),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  p.name,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w800,
                                    color: CoffeeColors.espresso,
                                    fontSize: 14,
                                  ),
                                ),
                                const SizedBox(height: 3),
                                Text(
                                  'Hedef fiyat: ₺${e.value.toStringAsFixed(2)}',
                                  style: const TextStyle(
                                    color: CoffeeColors.caramel,
                                    fontWeight: FontWeight.w700,
                                    fontSize: 12,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Row(
                                  children: [
                                    PriceText(p.lowestPrice, size: 14),
                                    if (p.cheapestStore != null) ...[
                                      const Text(
                                        ' · ',
                                        style: TextStyle(color: CoffeeColors.crema),
                                      ),
                                      Text(
                                        p.cheapestStore!,
                                        style: const TextStyle(
                                          color: CoffeeColors.cocoa,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: CoffeeColors.espresso,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.notifications_active,
                                  size: 16,
                                  color: CoffeeColors.caramel,
                                ),
                                SizedBox(width: 4),
                                Text(
                                  'Açık',
                                  style: TextStyle(
                                    color: CoffeeColors.caramel,
                                    fontWeight: FontWeight.w700,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }),
              ],
            ),
    );
  }
}

class _EmptyAlerts extends StatelessWidget {
  const _EmptyAlerts();

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
            child: const Icon(
              Icons.notifications_none,
              color: CoffeeColors.caramel,
              size: 36,
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Henüz alarm yok',
            style: TextStyle(
              color: CoffeeColors.espresso,
              fontSize: 17,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Ürün detayında hedef fiyat belirleyerek\nalarm oluşturabilirsin',
            textAlign: TextAlign.center,
            style: TextStyle(color: CoffeeColors.cocoa, fontSize: 13),
          ),
        ],
      ),
    );
  }
}
