import 'package:flutter/material.dart';
import '../../state/app_state.dart';
import '../../theme.dart';
import '../../widgets/design.dart';
import '../product_detail_screen.dart';

class AlertsScreen extends StatefulWidget {
  const AlertsScreen({super.key});

  @override
  State<AlertsScreen> createState() => _AlertsScreenState();
}

class _AlertsScreenState extends State<AlertsScreen> {
  // Local alert state (in a real app this would be in AppState / Firestore)
  final Map<String, bool> _alertsEnabled = {};

  @override
  Widget build(BuildContext context) {
    final state = AppStateScope.of(context);
    // Show alerts for favorited products
    final favProducts = state.products
        .where((p) => state.isFavorite(p.id))
        .toList();

    return Scaffold(
      backgroundColor: CoffeeColors.cream,
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Fiyat Alarmlarım'),
            if (favProducts.isNotEmpty)
              Text(
                '${_alertsEnabled.values.where((v) => v).length} aktif alarm',
                style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: CoffeeColors.cocoa),
              ),
          ],
        ),
      ),
      body: favProducts.isEmpty
          ? _EmptyAlerts()
          : ListView(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 40),
              children: [
                // Info callout
                Container(
                  padding: const EdgeInsets.all(14),
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: CoffeeColors.caramel.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                        color: CoffeeColors.caramel.withOpacity(0.3)),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.info_outline,
                          color: CoffeeColors.caramel, size: 18),
                      SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Kayıtlı ürünlerin fiyatı düştüğünde bildirim gönderilir.',
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

                // Alert tiles
                ...favProducts.map((p) {
                  final enabled = _alertsEnabled[p.id] ?? false;
                  return GestureDetector(
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) =>
                              ProductDetailScreen(product: p)),
                    ),
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 10),
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(
                          color: enabled
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
                                colors: [
                                  CoffeeColors.foam,
                                  CoffeeColors.crema
                                ],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              borderRadius: BorderRadius.circular(13),
                            ),
                            alignment: Alignment.center,
                            child: Text(p.emoji,
                                style: const TextStyle(fontSize: 24)),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment:
                                  CrossAxisAlignment.start,
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
                                Row(
                                  children: [
                                    PriceText(p.lowestPrice, size: 14),
                                    if (p.cheapestStore != null) ...[
                                      const Text(' · ',
                                          style: TextStyle(
                                              color: CoffeeColors.crema)),
                                      Text(
                                        p.cheapestStore!,
                                        style: const TextStyle(
                                            color: CoffeeColors.cocoa,
                                            fontSize: 12),
                                      ),
                                    ],
                                  ],
                                ),
                              ],
                            ),
                          ),
                          // Toggle
                          GestureDetector(
                            onTap: () {
                              setState(() {
                                _alertsEnabled[p.id] = !enabled;
                              });
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(enabled
                                      ? 'Alarm kapatıldı'
                                      : '${p.name} için alarm kuruldu'),
                                  backgroundColor:
                                      CoffeeColors.darkRoast,
                                  behavior: SnackBarBehavior.floating,
                                  margin: const EdgeInsets.fromLTRB(
                                      16, 0, 16, 80),
                                ),
                              );
                            },
                            child: AnimatedContainer(
                              duration:
                                  const Duration(milliseconds: 200),
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 8),
                              decoration: BoxDecoration(
                                color: enabled
                                    ? CoffeeColors.espresso
                                    : CoffeeColors.foam,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: enabled
                                      ? CoffeeColors.espresso
                                      : CoffeeColors.crema,
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    enabled
                                        ? Icons.notifications_active
                                        : Icons.notifications_none,
                                    size: 16,
                                    color: enabled
                                        ? CoffeeColors.caramel
                                        : CoffeeColors.cocoa,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    enabled ? 'Açık' : 'Kapat',
                                    style: TextStyle(
                                      color: enabled
                                          ? CoffeeColors.caramel
                                          : CoffeeColors.cocoa,
                                      fontWeight: FontWeight.w700,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
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
            child: const Icon(Icons.notifications_none,
                color: CoffeeColors.caramel, size: 36),
          ),
          const SizedBox(height: 16),
          const Text(
            'Henüz alarm yok',
            style: TextStyle(
                color: CoffeeColors.espresso,
                fontSize: 17,
                fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 6),
          const Text(
            'Önce ürünleri favorile, ardından\nalarm kurabilirsin',
            textAlign: TextAlign.center,
            style: TextStyle(color: CoffeeColors.cocoa, fontSize: 13),
          ),
        ],
      ),
    );
  }
}
