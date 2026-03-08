import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/banner_provider.dart';
import '../../providers/product_provider.dart';
import '../../providers/user_provider.dart';
import '../../utils/theme.dart';

// --- PREMIUM RENK PALETİ ---
const Color pBrandBrown = Color(0xFF6A442A);
const Color pBrandBrownLight = Color(0x266A442A); // %15 Opacity
const Color pBgApp = Color(0xFFF8F6F4);
const Color pSurface = Color(0xFFFFFFFF);
const Color pStudio = Color(0xFFEBE5DF);
const Color pGold = Color(0xFFC29B78);
const Color pGoldLight = Color(0x33C29B78); // %20 Opacity
const Color pTextMain = Color(0xFF211510);
const Color pTextMuted = Color(0xFF8C7B70);
const Color pAlert = Color(0xFFFF3B30);
const Color pAlertLight = Color(0x1AFF3B30); // %10 Opacity
const Color pSuccess = Color(0xFF34C759);
const Color pBorder = Color(0x1F6A442A); // %12 Opacity

class AdminStatisticsTab extends ConsumerStatefulWidget {
  const AdminStatisticsTab({super.key});

  @override
  ConsumerState<AdminStatisticsTab> createState() => _AdminStatisticsTabState();
}

class _AdminStatisticsTabState extends ConsumerState<AdminStatisticsTab> {
  bool _isPriceStatusMigrating = false;
  int _migrationUpdated = 0;
  int _migrationScanned = 0;

  Future<void> _runPriceStatusMigration() async {
    if (_isPriceStatusMigrating) return;
    setState(() {
      _isPriceStatusMigrating = true;
      _migrationUpdated = 0;
      _migrationScanned = 0;
    });

    try {
      final result = await ref.read(firestoreServiceProvider).migrateMissingPriceStatus(
            batchSize: 300,
            onProgress: (updated, scanned) {
              if (!mounted) return;
              setState(() {
                _migrationUpdated = updated;
                _migrationScanned = scanned;
              });
            },
          );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Migration tamamlandı: ${result.updatedCount} fiyat güncellendi.', style: const TextStyle(color: pSurface)),
          behavior: SnackBarBehavior.floating,
          backgroundColor: pBrandBrown,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Migration hatası: $e', style: const TextStyle(color: pSurface)),
          behavior: SnackBarBehavior.floating,
          backgroundColor: pAlert,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isPriceStatusMigrating = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final productsAsync = ref.watch(allProductsProvider);
    final storesAsync = ref.watch(allStoresStreamProvider);
    final brandsAsync = ref.watch(allBrandsProvider);
    final categoriesAsync = ref.watch(categoriesProvider);
    final bannersAsync = ref.watch(allBannersProvider);
    final usersAsync = ref.watch(allUsersProvider);
    final reportsAsync = ref.watch(reportsProvider);
    final maintenanceAsync = ref.watch(maintenanceModeProvider);
    
    final badgeLogsStream = FirebaseFirestore.instance
        .collection('badge_unlock_logs')
        .orderBy('date', descending: true)
        .limit(20)
        .snapshots();

    // Veri Hesaplamaları
    final productCount = productsAsync.valueOrNull?.length ?? 0;
    final storeCount = storesAsync.valueOrNull?.length ?? 0;
    final brandCount = brandsAsync.valueOrNull?.length ?? 0;
    final categoryCount = categoriesAsync.valueOrNull?.length ?? 0;
    final bannerCount = bannersAsync.valueOrNull?.length ?? 0;
    final userCount = usersAsync.valueOrNull?.length ?? 0;
    
    // Raporları hesapla (Sadece pending/bekleyen olanları almak daha doğru olabilir)
    final allReports = reportsAsync.valueOrNull ?? [];
    final openReportCount = allReports.where((r) => r['status'] == 'pending').length;

    final users = usersAsync.valueOrNull ?? [];
    int totalPriceEntries = 0;
    int totalPoints = 0;
    for (final user in users) {
      totalPriceEntries += user.priceEntries;
      totalPoints += user.points;
    }

    final maintenanceEnabled = maintenanceAsync.valueOrNull ?? false;
    final maintenanceBusy = maintenanceAsync.isLoading;

    // Progress barlar için maksimum değeri bulalım (Kullanıcı sayısını dışarıda tutuyoruz çünkü o çok büyük olabilir, grafiği bozar)
    final statsForBars = [
      _ProgressData('Toplam Fiyat Girişi', totalPriceEntries),
      _ProgressData('Toplam Ürün', productCount),
      _ProgressData('Toplam Şube', storeCount),
    ];
    final maxValForBars = statsForBars.map((s) => s.value).fold(1, (a, b) => a > b ? a : b).toDouble();

    return Container(
      color: pBgApp,
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 24, 20, 100),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            
            // 💥 1. SİSTEM KONTROL MERKEZİ 💥
            const _SectionTitle(title: 'Sistem Kontrolü'),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: pSurface,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: pBorder),
                boxShadow: const [BoxShadow(color: Color(0x0A6A442A), blurRadius: 15, offset: Offset(0, 4))],
              ),
              child: Column(
                children: [
                  // Bakım Modu Switch
                  Row(
                    children: [
                      Container(
                        width: 44, height: 44,
                        decoration: BoxDecoration(color: maintenanceEnabled ? pAlertLight : pStudio, borderRadius: BorderRadius.circular(12)),
                        child: Icon(Icons.build_circle, color: maintenanceEnabled ? pAlert : pTextMuted, size: 22),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Bakım Modu', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: maintenanceEnabled ? pAlert : pTextMain)),
                            const SizedBox(height: 2),
                            Text(maintenanceEnabled ? 'Sistem bakımda! (Tehlikeli)' : 'Sistem aktif ve yayında', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: maintenanceEnabled ? pAlert : pTextMuted)),
                          ],
                        ),
                      ),
                      Switch.adaptive(
                        value: maintenanceEnabled,
                        activeColor: pSurface,
                        activeTrackColor: pAlert, // Tehlikeli işlem olduğu için kırmızı
                        inactiveThumbColor: pSurface,
                        inactiveTrackColor: pStudio,
                        onChanged: maintenanceBusy ? null : (value) => ref.read(adminModerationDomainServiceProvider).setMaintenanceMode(value),
                      ),
                    ],
                  ),
                  
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    child: Container(height: 1, color: pBorder.withOpacity(0.5)),
                  ),

                  // Migration Butonu
                  GestureDetector(
                    onTap: _isPriceStatusMigrating ? null : _runPriceStatusMigration,
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      decoration: BoxDecoration(
                        color: _isPriceStatusMigrating ? pBrandBrownLight : pSurface,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: _isPriceStatusMigrating ? Colors.transparent : pBrandBrown),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          if (_isPriceStatusMigrating)
                            const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: pBrandBrown, strokeWidth: 2))
                          else
                            const Icon(Icons.auto_fix_high, color: pBrandBrown, size: 18),
                          const SizedBox(width: 8),
                          Text(
                            _isPriceStatusMigrating ? 'Güncelleniyor...' : 'Fiyat Status Migration Başlat',
                            style: const TextStyle(color: pBrandBrown, fontSize: 13, fontWeight: FontWeight.w800),
                          ),
                        ],
                      ),
                    ),
                  ),
                  if (_isPriceStatusMigrating || _migrationScanned > 0)
                    Padding(
                      padding: const EdgeInsets.only(top: 12),
                      child: Text(
                        'Tarandı: $_migrationScanned • Güncellendi: $_migrationUpdated',
                        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: pTextMuted),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // 💥 2. İSTATİSTİK GRID (Lüks Widgetlar) 💥
            const _SectionTitle(title: 'Özet Veriler'),
            
            // Full Width: Toplam Kullanıcı
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: pBrandBrown,
                borderRadius: BorderRadius.circular(20),
                boxShadow: const [BoxShadow(color: Color(0x4D6A442A), blurRadius: 15, offset: Offset(0, 6))],
              ),
              child: Row(
                children: [
                  Container(
                    width: 48, height: 48,
                    decoration: BoxDecoration(color: pSurface.withOpacity(0.2), borderRadius: BorderRadius.circular(14)),
                    child: const Icon(Icons.people, color: pSurface, size: 24),
                  ),
                  const SizedBox(width: 16),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(userCount.toString(), style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w900, color: pSurface, height: 1.1)),
                      Text('Toplam Kullanıcı', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: pSurface.withOpacity(0.8))),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            
            // 2'li Gridler
            Row(
              children: [
                Expanded(child: _PremiumStatWidget(label: 'Toplam Ürün', value: productCount, icon: Icons.inventory_2)),
                const SizedBox(width: 12),
                Expanded(child: _PremiumStatWidget(label: 'Fiyat Girişi', value: totalPriceEntries, icon: Icons.price_change)),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(child: _PremiumStatWidget(label: 'Açık Rapor', value: openReportCount, icon: Icons.flag, isAlert: true)),
                const SizedBox(width: 12),
                Expanded(child: _PremiumStatWidget(label: 'Dağıtılan Puan', value: totalPoints, icon: Icons.stars, isGold: true)),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(child: _PremiumStatWidget(label: 'Zincir / Marka', value: brandCount, icon: Icons.business)),
                const SizedBox(width: 12),
                Expanded(child: _PremiumStatWidget(label: 'Kategoriler', value: categoryCount, icon: Icons.category)),
              ],
            ),

            const SizedBox(height: 24),

            // 💥 3. GENEL BAKIŞ ORANLARI (Progress Bars) 💥
            const _SectionTitle(title: 'Genel Bakış Oranları'),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: pSurface,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: pBorder),
                boxShadow: const [BoxShadow(color: Color(0x0A6A442A), blurRadius: 15, offset: Offset(0, 4))],
              ),
              child: Column(
                children: statsForBars.map((stat) {
                  final ratio = maxValForBars > 0 ? (stat.value / maxValForBars).clamp(0.0, 1.0) : 0.0;
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(stat.label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: pTextMuted)),
                            Text(stat.value.toString(), style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w900, color: pTextMain)),
                          ],
                        ),
                        const SizedBox(height: 6),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(100),
                          child: Stack(
                            children: [
                              Container(height: 8, width: double.infinity, color: pStudio),
                              FractionallySizedBox(
                                widthFactor: ratio,
                                child: Container(
                                  height: 8,
                                  decoration: const BoxDecoration(
                                    gradient: LinearGradient(colors: [pGold, pBrandBrown]),
                                    borderRadius: BorderRadius.all(Radius.circular(100)),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ),

            const SizedBox(height: 24),

            // 💥 4. ROZET KAZANIMLARI LOGU 💥
            const _SectionTitle(title: 'Son Rozet Kazanımları'),
            Container(
              decoration: BoxDecoration(
                color: pSurface,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: pBorder),
                boxShadow: const [BoxShadow(color: Color(0x0A6A442A), blurRadius: 15, offset: Offset(0, 4))],
              ),
              child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                stream: badgeLogsStream,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Padding(padding: EdgeInsets.all(20), child: Center(child: CircularProgressIndicator(color: pGold)));
                  }
                  final docs = snapshot.data?.docs ?? const [];
                  if (docs.isEmpty) {
                    return const Padding(
                      padding: EdgeInsets.all(20),
                      child: Text('Henüz rozet kazanım kaydı yok.', style: TextStyle(color: pTextMuted, fontWeight: FontWeight.w600)),
                    );
                  }

                  return ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: docs.length,
                    separatorBuilder: (context, index) => Container(height: 1, color: pBorder.withOpacity(0.5)),
                    itemBuilder: (context, index) {
                      final data = docs[index].data();
                      final username = (data['username'] ?? data['userName'] ?? 'Kullanıcı').toString();
                      final badge = (data['badge'] ?? data['badgeName'] ?? 'Rozet').toString();
                      final dt = data['date'];
                      String dateText = 'Tarih yok';
                      if (dt is Timestamp) {
                        final d = dt.toDate();
                        dateText = '${d.day.toString().padLeft(2, '0')}.${d.month.toString().padLeft(2, '0')}.${d.year}';
                      }

                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                        child: Row(
                          children: [
                            Container(
                              width: 40, height: 40,
                              decoration: BoxDecoration(color: pGoldLight, borderRadius: BorderRadius.circular(12)),
                              child: const Icon(Icons.workspace_premium, color: pGold, size: 20),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(username, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: pTextMain)),
                                  const SizedBox(height: 2),
                                  Text('$badge • $dateText', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: pTextMuted)),
                                ],
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  );
                },
              ),
            ),

          ],
        ),
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// PREMIUM WIDGETLAR
// -----------------------------------------------------------------------------

class _SectionTitle extends StatelessWidget {
  final String title;
  const _SectionTitle({required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12, left: 4),
      child: Text(title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: pBrandBrown)),
    );
  }
}

class _PremiumStatWidget extends StatelessWidget {
  final String label;
  final int value;
  final IconData icon;
  final bool isAlert;
  final bool isGold;

  const _PremiumStatWidget({
    required this.label,
    required this.value,
    required this.icon,
    this.isAlert = false,
    this.isGold = false,
  });

  @override
  Widget build(BuildContext context) {
    Color iconBg = pStudio;
    Color iconColor = pBrandBrown;
    Color valColor = pTextMain;

    if (isAlert) {
      iconBg = pAlertLight;
      iconColor = pAlert;
      valColor = pAlert;
    } else if (isGold) {
      iconBg = pGoldLight;
      iconColor = pTextMain;
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: pSurface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: pBorder),
        boxShadow: const [BoxShadow(color: Color(0x0A6A442A), blurRadius: 10, offset: Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36, height: 36,
            decoration: BoxDecoration(color: iconBg, borderRadius: BorderRadius.circular(10)),
            child: Icon(icon, color: iconColor, size: 18),
          ),
          const SizedBox(height: 12),
          Text(value.toString(), style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: valColor, height: 1)),
          const SizedBox(height: 4),
          Text(label, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: pTextMuted)),
        ],
      ),
    );
  }
}

// İlerleme çubukları için veri modeli
class _ProgressData {
  final String label;
  final int value;
  _ProgressData(this.label, this.value);
}
