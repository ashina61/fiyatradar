import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/banner_provider.dart';
import '../../providers/product_provider.dart';
import '../../providers/user_provider.dart';
import '../../utils/theme.dart';

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
          content: Text('Migration tamamlandı: ${result.updatedCount} fiyat güncellendi.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Migration hatası: $e'),
          behavior: SnackBarBehavior.floating,
          backgroundColor: AppColors.error,
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
    final theme = Theme.of(context);
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

    final productCount = productsAsync.valueOrNull?.length ?? 0;
    final storeCount = storesAsync.valueOrNull?.length ?? 0;
    final brandCount = brandsAsync.valueOrNull?.length ?? 0;
    final categoryCount = categoriesAsync.valueOrNull?.length ?? 0;
    final bannerCount = bannersAsync.valueOrNull?.length ?? 0;
    final userCount = usersAsync.valueOrNull?.length ?? 0;
    final reportCount = reportsAsync.valueOrNull?.length ?? 0;

    final users = usersAsync.valueOrNull ?? [];
    int totalPriceEntries = 0;
    int totalPoints = 0;
    for (final user in users) {
      totalPriceEntries += user.priceEntries;
      totalPoints += user.points;
    }

    final stats = [
      _AdminStatItem('Toplam Urun', productCount, Icons.inventory_2_outlined, AppColors.primary),
      _AdminStatItem('Toplam Zincir', brandCount, Icons.business_outlined, AppColors.secondary),
      _AdminStatItem('Toplam Sube', storeCount, Icons.store_outlined, AppColors.accent),
      _AdminStatItem('Toplam Kategori', categoryCount, Icons.category_outlined, const Color(0xFF6366F1)),
      _AdminStatItem('Toplam Kullanici', userCount, Icons.people_outlined, AppColors.info),
      _AdminStatItem('Toplam Fiyat Girisi', totalPriceEntries, Icons.price_change_outlined, const Color(0xFF10B981)),
      _AdminStatItem('Toplam Rapor', reportCount, Icons.flag_outlined, AppColors.error),
      _AdminStatItem('Toplam Banner', bannerCount, Icons.view_carousel_outlined, const Color(0xFF8B5CF6)),
      _AdminStatItem('Toplam Puan', totalPoints, Icons.stars, const Color(0xFFF59E0B)),
    ];

    final maxVal = stats.map((s) => s.value).fold(1, (a, b) => a > b ? a : b).toDouble();
    final maintenanceEnabled = maintenanceAsync.valueOrNull ?? false;
    final maintenanceBusy = maintenanceAsync.isLoading;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Column(
                children: [
                  Row(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: AppColors.error.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(AppRadius.sm),
                        ),
                        child: const Icon(Icons.build_circle_outlined, color: AppColors.error),
                      ),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Bakim Modu', style: TextStyle(fontWeight: FontWeight.w600)),
                            Text(
                              maintenanceEnabled ? 'Sistem bakim modunda' : 'Sistem aktif',
                              style: TextStyle(fontSize: 12, color: theme.hintColor),
                            ),
                          ],
                        ),
                      ),
                      Switch(
                        value: maintenanceEnabled,
                        onChanged: maintenanceBusy
                            ? null
                            : (value) => ref.read(adminModerationDomainServiceProvider).setMaintenanceMode(value),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: _isPriceStatusMigrating ? null : _runPriceStatusMigration,
                          icon: _isPriceStatusMigrating
                              ? const SizedBox(
                                  width: 14,
                                  height: 14,
                                  child: CircularProgressIndicator(strokeWidth: 2),
                                )
                              : const Icon(Icons.auto_fix_high),
                          label: const Text('Fiyat Status Migration'),
                        ),
                      ),
                    ],
                  ),
                  if (_isPriceStatusMigrating || _migrationScanned > 0) ...[
                    const SizedBox(height: AppSpacing.sm),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'Tarandı: $_migrationScanned • Güncellendi: $_migrationUpdated',
                        style: TextStyle(fontSize: 12, color: theme.hintColor),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Wrap(
                spacing: AppSpacing.md,
                runSpacing: AppSpacing.md,
                children: stats.map((stat) {
                  return SizedBox(
                    width: 170,
                    child: Container(
                      padding: const EdgeInsets.all(AppSpacing.md),
                      decoration: BoxDecoration(
                        color: stat.color.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(AppRadius.md),
                        border: Border.all(color: stat.color.withOpacity(0.2)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(stat.icon, color: stat.color),
                          const SizedBox(height: 8),
                          Text(
                            stat.value.toString(),
                            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: stat.color),
                          ),
                          const SizedBox(height: 4),
                          Text(stat.label, style: TextStyle(fontSize: 11, color: theme.hintColor), maxLines: 1, overflow: TextOverflow.ellipsis),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Genel Bakis', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                  const SizedBox(height: AppSpacing.md),
                  ...stats.map((stat) {
                    final ratio = maxVal > 0 ? stat.value / maxVal : 0.0;
                    return Padding(
                      padding: const EdgeInsets.only(bottom: AppSpacing.md),
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                          Flexible(child: Text(stat.label, style: TextStyle(fontSize: 12, color: theme.hintColor), overflow: TextOverflow.ellipsis)),
                          Text(stat.value.toString(), style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: stat.color)),
                        ]),
                        const SizedBox(height: 6),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(AppRadius.full),
                          child: Stack(children: [
                            Container(height: 10, width: double.infinity, color: theme.colorScheme.surfaceVariant),
                            FractionallySizedBox(
                              widthFactor: ratio,
                              child: Container(
                                height: 10,
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(colors: [stat.color.withOpacity(0.7), stat.color]),
                                  borderRadius: BorderRadius.circular(AppRadius.full),
                                ),
                              ),
                            ),
                          ]),
                        ),
                      ]),
                    );
                  }),
                ],
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Rozet Kazanımları', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                  const SizedBox(height: AppSpacing.sm),
                  StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                    stream: badgeLogsStream,
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Padding(
                          padding: EdgeInsets.all(AppSpacing.md),
                          child: Center(child: CircularProgressIndicator()),
                        );
                      }
                      final docs = snapshot.data?.docs ?? const [];
                      if (docs.isEmpty) {
                        return const Padding(
                          padding: EdgeInsets.all(AppSpacing.sm),
                          child: Text('Henüz rozet kazanım kaydı yok.'),
                        );
                      }

                      return Column(
                        children: docs.map((doc) {
                          final data = doc.data();
                          final username = (data['username'] ?? data['userName'] ?? 'Kullanıcı').toString();
                          final badge = (data['badge'] ?? data['badgeName'] ?? 'Rozet').toString();
                          final dt = data['date'];
                          String dateText = 'Tarih yok';
                          if (dt is Timestamp) {
                            final d = dt.toDate();
                            dateText = '${d.day}.${d.month}.${d.year}';
                          }

                          return ListTile(
                            dense: true,
                            contentPadding: EdgeInsets.zero,
                            leading: const Icon(Icons.workspace_premium_rounded, color: Color(0xFFD4AF37)),
                            title: Text(username),
                            subtitle: Text('$badge • $dateText'),
                          );
                        }).toList(growable: false),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AdminStatItem {
  final String label;
  final int value;
  final IconData icon;
  final Color color;
  const _AdminStatItem(this.label, this.value, this.icon, this.color);
}
