import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../services/firebase_service.dart';
import '../theme.dart';
import '../widgets/design.dart';

class AdminScreen extends StatefulWidget {
  const AdminScreen({super.key});

  @override
  State<AdminScreen> createState() => _AdminScreenState();
}

class _AdminScreenState extends State<AdminScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController = TabController(length: 4, vsync: this);

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: CoffeeColors.cream,
      appBar: AppBar(
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: CoffeeColors.caramel.withOpacity(0.18),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: CoffeeColors.caramel.withOpacity(0.35)),
              ),
              child: const Text(
                'ADMIN',
                style: TextStyle(
                  color: CoffeeColors.caramel,
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.2,
                ),
              ),
            ),
            const SizedBox(width: 10),
            const Text('Yönetim Paneli'),
          ],
        ),
        leading: const BackButton(),
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          tabAlignment: TabAlignment.start,
          labelColor: CoffeeColors.espresso,
          unselectedLabelColor: CoffeeColors.cocoa,
          labelStyle: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13),
          unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
          indicatorColor: CoffeeColors.caramel,
          indicatorWeight: 3,
          indicatorSize: TabBarIndicatorSize.tab,
          dividerColor: CoffeeColors.crema,
          tabs: const [
            Tab(text: 'Genel Bakış'),
            Tab(text: 'İçerik'),
            Tab(text: 'Kullanıcılar'),
            Tab(text: 'Bildirimler'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _OverviewTab(
            onGoContent: () => _tabController.animateTo(1),
            onGoUsers: () => _tabController.animateTo(2),
            onGoAnnouncements: () => _tabController.animateTo(3),
          ),
          const _ContentTab(),
          const _UsersTab(),
          const _NotificationsTab(),
        ],
      ),
    );
  }
}

class _OverviewTab extends StatelessWidget {
  const _OverviewTab({
    required this.onGoContent,
    required this.onGoUsers,
    required this.onGoAnnouncements,
  });

  final VoidCallback onGoContent;
  final VoidCallback onGoUsers;
  final VoidCallback onGoAnnouncements;

  @override
  Widget build(BuildContext context) {
    final svc = FirebaseService.instance;

    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: svc.products.snapshots(),
      builder: (context, productsSnap) {
        return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
          stream: svc.users.snapshots(),
          builder: (context, usersSnap) {
            return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: svc.db.collection('adminAnnouncements').snapshots(),
              builder: (context, announcementsSnap) {
                final products = productsSnap.data?.docs ?? const [];
                final users = usersSnap.data?.docs ?? const [];
                final announcements = announcementsSnap.data?.docs ?? const [];

                int pendingProducts = 0;
                int hiddenProducts = 0;
                int featuredProducts = 0;
                int todayPriceEntries = 0;
                int flaggedUsers = 0;
                int draftAnnouncements = 0;
                final now = DateTime.now();
                final dayStart = DateTime(now.year, now.month, now.day);

                for (final p in products) {
                  final data = p.data();
                  final status = (data['adminStatus'] as String?) ?? 'active';
                  if (status == 'pending') pendingProducts++;
                  if (data['isHidden'] == true) hiddenProducts++;
                  if (data['isFeatured'] == true) featuredProducts++;
                  final history = (data['priceHistory'] as List?) ?? const [];
                  for (final h in history) {
                    final m = Map<String, dynamic>.from(h as Map);
                    final ts = m['date'];
                    final dt = ts is Timestamp ? ts.toDate() : null;
                    if (dt != null && dt.isAfter(dayStart)) {
                      todayPriceEntries++;
                    }
                  }
                }

                for (final u in users) {
                  final trustStatus = (u.data()['trustStatus'] as String?) ?? 'active';
                  if (trustStatus == 'flagged') flaggedUsers++;
                }

                for (final a in announcements) {
                  final status = (a.data()['status'] as String?) ?? 'draft';
                  if (status == 'draft' || status == 'scheduled') {
                    draftAnnouncements++;
                  }
                }

                return ListView(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 48),
                  children: [
                    _AdminHeroCard(
                      productCount: products.length,
                      userCount: users.length,
                      todayPriceEntries: todayPriceEntries,
                    ),
                    const SizedBox(height: 20),
                    const _SectionHeader(
                      title: 'Kritik Kuyruklar',
                      subtitle: 'Gerçek koleksiyonlardan anlık sayılar',
                    ),
                    const SizedBox(height: 12),
                    _QueueCard(
                      icon: Icons.inventory_2_outlined,
                      title: 'Onay Bekleyen Ürünler',
                      count: pendingProducts,
                      accentColor: CoffeeColors.caramel,
                      onTap: onGoContent,
                    ),
                    const SizedBox(height: 8),
                    _QueueCard(
                      icon: Icons.visibility_off_outlined,
                      title: 'Gizlenen Ürünler',
                      count: hiddenProducts,
                      accentColor: CoffeeColors.danger,
                      onTap: onGoContent,
                    ),
                    const SizedBox(height: 8),
                    _QueueCard(
                      icon: Icons.flag_outlined,
                      title: 'Bayraklı Kullanıcılar',
                      count: flaggedUsers,
                      accentColor: CoffeeColors.danger,
                      onTap: onGoUsers,
                    ),
                    const SizedBox(height: 8),
                    _QueueCard(
                      icon: Icons.campaign_outlined,
                      title: 'Taslak/Planlı Duyuru',
                      count: draftAnnouncements,
                      accentColor: CoffeeColors.success,
                      onTap: onGoAnnouncements,
                    ),
                    const SizedBox(height: 12),
                    _QueueCard(
                      icon: Icons.star_outline,
                      title: 'Öne Çıkan Ürünler',
                      count: featuredProducts,
                      accentColor: CoffeeColors.accent,
                      onTap: onGoContent,
                    ),
                  ],
                );
              },
            );
          },
        );
      },
    );
  }
}

class _AdminHeroCard extends StatelessWidget {
  const _AdminHeroCard({
    required this.productCount,
    required this.userCount,
    required this.todayPriceEntries,
  });

  final int productCount;
  final int userCount;
  final int todayPriceEntries;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(22, 20, 22, 20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [CoffeeColors.espresso, CoffeeColors.darkRoast],
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: CoffeeColors.espresso.withOpacity(0.25),
            blurRadius: 28,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const EyebrowLabel('YÖNETİM PANELİ'),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                decoration: BoxDecoration(
                  color: CoffeeColors.success.withOpacity(0.20),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: CoffeeColors.success.withOpacity(0.35)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    LiveDot(color: CoffeeColors.success),
                    const SizedBox(width: 5),
                    const Text(
                      'CANLI VERİ',
                      style: TextStyle(
                        color: CoffeeColors.success,
                        fontSize: 9,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.0,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Text(
            'FiyatRadar',
            style: TextStyle(
              color: CoffeeColors.cream,
              fontSize: 26,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.6,
              height: 1,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Admin Kontrol Merkezi',
            style: TextStyle(color: CoffeeColors.latte, fontSize: 13),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              _HeroStatChip(label: 'kullanıcı', value: '$userCount'),
              const SizedBox(width: 8),
              _HeroStatChip(label: 'ürün', value: '$productCount'),
              const SizedBox(width: 8),
              _HeroStatChip(label: 'bugün fiyat', value: '$todayPriceEntries'),
            ],
          ),
        ],
      ),
    );
  }
}

class _HeroStatChip extends StatelessWidget {
  const _HeroStatChip({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.07),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.white.withOpacity(0.10)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            value,
            style: const TextStyle(
              color: CoffeeColors.cream,
              fontSize: 16,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.3,
            ),
          ),
          Text(label, style: const TextStyle(color: CoffeeColors.latte, fontSize: 10)),
        ],
      ),
    );
  }
}

class _QueueCard extends StatelessWidget {
  const _QueueCard({
    required this.icon,
    required this.title,
    required this.count,
    required this.accentColor,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final int count;
  final Color accentColor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isUrgent = count > 10;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isUrgent ? accentColor.withOpacity(0.35) : CoffeeColors.crema,
            width: isUrgent ? 1.5 : 1,
          ),
          boxShadow: FR.softShadow,
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: accentColor.withOpacity(0.12),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: accentColor.withOpacity(0.22)),
              ),
              child: Icon(icon, color: accentColor, size: 20),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                title,
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  color: CoffeeColors.espresso,
                  fontSize: 14,
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: accentColor.withOpacity(isUrgent ? 1.0 : 0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                '$count',
                style: TextStyle(
                  color: isUrgent ? Colors.white : accentColor,
                  fontWeight: FontWeight.w800,
                  fontSize: 14,
                ),
              ),
            ),
            const SizedBox(width: 8),
            const Icon(Icons.chevron_right, color: CoffeeColors.cocoa, size: 18),
          ],
        ),
      ),
    );
  }
}

class _ContentTab extends StatefulWidget {
  const _ContentTab();

  @override
  State<_ContentTab> createState() => _ContentTabState();
}

class _ContentTabState extends State<_ContentTab> {
  String _contentFilter = 'Tümü';
  final _filters = const ['Tümü', 'Onay Bekleyen', 'Aktif', 'Gizlenen'];

  @override
  Widget build(BuildContext context) {
    final svc = FirebaseService.instance;

    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: svc.products.snapshots(),
      builder: (context, snapshot) {
        final docs = snapshot.data?.docs ?? const [];
        final filtered = docs.where((d) {
          final m = d.data();
          final status = (m['adminStatus'] as String?) ?? 'active';
          final isHidden = m['isHidden'] == true;
          if (_contentFilter == 'Onay Bekleyen') return status == 'pending';
          if (_contentFilter == 'Aktif') return status == 'active' && !isHidden;
          if (_contentFilter == 'Gizlenen') return isHidden;
          return true;
        }).toList();

        final priceRows = _extractPriceRows(docs);

        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
              child: SizedBox(
                height: 36,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: _filters.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 8),
                  itemBuilder: (context, i) {
                    final f = _filters[i];
                    final selected = f == _contentFilter;
                    return GestureDetector(
                      onTap: () => setState(() => _contentFilter = f),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 160),
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                        decoration: BoxDecoration(
                          color: selected ? CoffeeColors.espresso : Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: selected ? CoffeeColors.espresso : CoffeeColors.crema,
                          ),
                        ),
                        child: Text(
                          f,
                          style: TextStyle(
                            color: selected ? CoffeeColors.cream : CoffeeColors.darkRoast,
                            fontWeight: FontWeight.w700,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 48),
                children: [
                  const _SectionHeader(
                    title: 'Ürün Yönetimi',
                    subtitle: 'Gerçek ürün dokümanları',
                  ),
                  const SizedBox(height: 12),
                  ...filtered.map((doc) => Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: _ProductAdminRow(productDoc: doc),
                      )),
                  const SizedBox(height: 16),
                  const _SectionHeader(
                    title: 'Fiyat Kayıtları',
                    subtitle: 'Ürün priceHistory akışından',
                  ),
                  const SizedBox(height: 12),
                  ...priceRows.map((row) => Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: _PriceReportRow(row: row),
                      )),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  List<_PriceRow> _extractPriceRows(List<QueryDocumentSnapshot<Map<String, dynamic>>> docs) {
    final rows = <_PriceRow>[];
    for (final d in docs) {
      final data = d.data();
      final history = (data['priceHistory'] as List?) ?? const [];
      for (var i = 0; i < history.length; i++) {
        final m = Map<String, dynamic>.from(history[i] as Map);
        final ts = m['date'];
        rows.add(
          _PriceRow(
            productDocId: d.id,
            productName: (data['name'] as String?) ?? '-',
            entryIndex: i,
            store: (m['store'] as String?) ?? '-',
            price: ((m['price'] as num?) ?? 0).toDouble(),
            reportedBy: (m['reportedBy'] as String?) ?? '-',
            date: ts is Timestamp ? ts.toDate() : null,
          ),
        );
      }
    }
    rows.sort((a, b) {
      final ad = a.date ?? DateTime.fromMillisecondsSinceEpoch(0);
      final bd = b.date ?? DateTime.fromMillisecondsSinceEpoch(0);
      return bd.compareTo(ad);
    });
    return rows.take(30).toList();
  }
}

class _PriceRow {
  const _PriceRow({
    required this.productDocId,
    required this.productName,
    required this.entryIndex,
    required this.store,
    required this.price,
    required this.reportedBy,
    required this.date,
  });

  final String productDocId;
  final String productName;
  final int entryIndex;
  final String store;
  final double price;
  final String reportedBy;
  final DateTime? date;
}

class _ProductAdminRow extends StatelessWidget {
  const _ProductAdminRow({required this.productDoc});

  final QueryDocumentSnapshot<Map<String, dynamic>> productDoc;

  @override
  Widget build(BuildContext context) {
    final product = productDoc.data();
    final status = (product['adminStatus'] as String?) ?? 'active';
    final isHidden = product['isHidden'] == true;
    final isFeatured = product['isFeatured'] == true;

    final statusColor = switch (status) {
      'active' => CoffeeColors.success,
      'pending' => CoffeeColors.caramel,
      'rejected' => CoffeeColors.danger,
      _ => CoffeeColors.cocoa,
    };

    return Container(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: status == 'pending' ? CoffeeColors.caramel.withOpacity(0.35) : CoffeeColors.crema,
          width: status == 'pending' ? 1.5 : 1,
        ),
        boxShadow: FR.softShadow,
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  (product['name'] as String?) ?? '-',
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    color: CoffeeColors.espresso,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  '${(product['category'] as String?) ?? '-'} · ${((product['priceHistory'] as List?) ?? const []).length} kayıt',
                  style: const TextStyle(color: CoffeeColors.cocoa, fontSize: 11),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: statusColor.withOpacity(0.12),
              borderRadius: BorderRadius.circular(9),
              border: Border.all(color: statusColor.withOpacity(0.25)),
            ),
            child: Text(
              isHidden ? 'Gizli' : status,
              style: TextStyle(color: statusColor, fontSize: 11, fontWeight: FontWeight.w700),
            ),
          ),
          const SizedBox(width: 8),
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert, color: CoffeeColors.cocoa, size: 18),
            color: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            onSelected: (val) => _handleProductAction(context, val, productDoc),
            itemBuilder: (_) => [
              if (status == 'pending')
                const PopupMenuItem(value: 'approve', child: Text('Onayla')),
              if (status == 'pending')
                const PopupMenuItem(value: 'reject', child: Text('Reddet')),
              PopupMenuItem(
                value: isHidden ? 'unhide' : 'hide',
                child: Text(isHidden ? 'Gizlemeyi Kaldır' : 'Gizle'),
              ),
              PopupMenuItem(
                value: isFeatured ? 'unfeature' : 'feature',
                child: Text(isFeatured ? 'Öne Çıkarmayı Kaldır' : 'Öne Çıkar'),
              ),
              const PopupMenuItem(value: 'delete', child: Text('Sil')),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _handleProductAction(
    BuildContext context,
    String action,
    QueryDocumentSnapshot<Map<String, dynamic>> doc,
  ) async {
    final ref = FirebaseService.instance.products.doc(doc.id);
    if (action == 'approve') {
      await ref.set({'adminStatus': 'active', 'moderatedAt': FieldValue.serverTimestamp()}, SetOptions(merge: true));
    } else if (action == 'reject') {
      await ref.set({
        'adminStatus': 'rejected',
        'isHidden': true,
        'moderatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } else if (action == 'hide') {
      await ref.set({'isHidden': true, 'moderatedAt': FieldValue.serverTimestamp()}, SetOptions(merge: true));
    } else if (action == 'unhide') {
      await ref.set({'isHidden': false, 'moderatedAt': FieldValue.serverTimestamp()}, SetOptions(merge: true));
    } else if (action == 'feature') {
      await ref.set({'isFeatured': true, 'featuredAt': FieldValue.serverTimestamp()}, SetOptions(merge: true));
    } else if (action == 'unfeature') {
      await ref.set({'isFeatured': false}, SetOptions(merge: true));
    } else if (action == 'delete') {
      await ref.delete();
    }

    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Ürün aksiyonu uygulandı.'),
        backgroundColor: CoffeeColors.darkRoast,
      ),
    );
  }
}

class _PriceReportRow extends StatelessWidget {
  const _PriceReportRow({required this.row});

  final _PriceRow row;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: CoffeeColors.crema),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  row.productName,
                  style: const TextStyle(fontWeight: FontWeight.w700, color: CoffeeColors.espresso, fontSize: 13),
                ),
                Text(
                  '${row.store} · ₺${row.price.toStringAsFixed(2)} · ${row.reportedBy}',
                  style: const TextStyle(color: CoffeeColors.cocoa, fontSize: 11),
                ),
                if (row.date != null)
                  Text(
                    '${row.date}',
                    style: const TextStyle(color: CoffeeColors.cocoa, fontSize: 10),
                  ),
              ],
            ),
          ),
          TextButton(
            onPressed: () => _rejectPriceReport(context),
            child: const Text('Reddet'),
          ),
        ],
      ),
    );
  }

  Future<void> _rejectPriceReport(BuildContext context) async {
    final ref = FirebaseService.instance.products.doc(row.productDocId);
    final snap = await ref.get();
    final data = snap.data();
    if (data == null) return;
    final history = List<Map<String, dynamic>>.from(
      ((data['priceHistory'] as List?) ?? const []).map((e) => Map<String, dynamic>.from(e as Map)),
    );
    if (row.entryIndex < 0 || row.entryIndex >= history.length) return;
    history.removeAt(row.entryIndex);
    await ref.update({
      'priceHistory': history,
      'moderatedAt': FieldValue.serverTimestamp(),
    });
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Fiyat kaydı kaldırıldı.'), backgroundColor: CoffeeColors.darkRoast),
    );
  }
}

class _UsersTab extends StatelessWidget {
  const _UsersTab();

  @override
  Widget build(BuildContext context) {
    final svc = FirebaseService.instance;

    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: svc.users.snapshots(),
      builder: (context, usersSnap) {
        final users = usersSnap.data?.docs ?? const [];
        int active = 0;
        int flagged = 0;
        int suspended = 0;
        for (final u in users) {
          final s = (u.data()['trustStatus'] as String?) ?? 'active';
          if (s == 'flagged') {
            flagged++;
          } else if (s == 'suspended') {
            suspended++;
          } else {
            active++;
          }
        }

        return ListView(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 48),
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: CoffeeColors.crema),
                boxShadow: FR.softShadow,
              ),
              child: Row(
                children: [
                  _TrustStat(label: 'Aktif', value: '$active', color: CoffeeColors.success),
                  _vDivider(),
                  _TrustStat(label: 'Bayraklı', value: '$flagged', color: CoffeeColors.danger),
                  _vDivider(),
                  _TrustStat(label: 'Askıda', value: '$suspended', color: CoffeeColors.cocoa),
                ],
              ),
            ),
            const SizedBox(height: 20),
            const _SectionHeader(title: 'Kullanıcı Listesi', subtitle: 'Gerçek kullanıcı belgeleri'),
            const SizedBox(height: 12),
            ...users.map((u) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: _UserAdminRow(userDoc: u),
                )),
          ],
        );
      },
    );
  }

  Widget _vDivider() => Container(width: 1, height: 36, color: CoffeeColors.crema);
}

class _TrustStat extends StatelessWidget {
  const _TrustStat({required this.label, required this.value, required this.color});

  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Text(value, style: TextStyle(color: color, fontWeight: FontWeight.w800, fontSize: 18)),
          Text(label, style: const TextStyle(color: CoffeeColors.cocoa, fontSize: 11)),
        ],
      ),
    );
  }
}

class _UserAdminRow extends StatelessWidget {
  const _UserAdminRow({required this.userDoc});

  final QueryDocumentSnapshot<Map<String, dynamic>> userDoc;

  @override
  Widget build(BuildContext context) {
    final user = userDoc.data();
    final trustStatus = (user['trustStatus'] as String?) ?? 'active';
    final isFlagged = trustStatus == 'flagged';
    final isSuspended = trustStatus == 'suspended';

    final trustColor = switch (trustStatus) {
      'suspended' => CoffeeColors.cocoa,
      'flagged' => CoffeeColors.danger,
      _ => CoffeeColors.success,
    };

    final displayName = (user['displayName'] as String?) ?? 'Anonim Kullanıcı';
    final username = (user['username'] as String?) ?? '@anon';
    final points = ((user['points'] as num?) ?? 0).toInt();

    return Container(
      padding: const EdgeInsets.fromLTRB(14, 12, 12, 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isFlagged ? CoffeeColors.danger.withOpacity(0.3) : CoffeeColors.crema,
          width: isFlagged ? 1.5 : 1,
        ),
        boxShadow: FR.softShadow,
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: isFlagged ? CoffeeColors.danger.withOpacity(0.10) : CoffeeColors.foam,
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: Icon(
              isFlagged ? Icons.flag_outlined : Icons.person_outline,
              color: isFlagged ? CoffeeColors.danger : CoffeeColors.darkRoast,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  displayName,
                  style: const TextStyle(fontWeight: FontWeight.w700, color: CoffeeColors.espresso, fontSize: 14),
                ),
                Text(
                  '$username · $points puan',
                  style: const TextStyle(color: CoffeeColors.cocoa, fontSize: 11),
                ),
              ],
            ),
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert, color: CoffeeColors.cocoa, size: 18),
            color: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            onSelected: (val) => _handleUserAction(context, val),
            itemBuilder: (_) => [
              if (!isFlagged)
                const PopupMenuItem(value: 'flag', child: Text('Bayrakla')),
              if (isFlagged)
                const PopupMenuItem(value: 'resolve', child: Text('Bayrağı Kaldır')),
              if (!isSuspended)
                const PopupMenuItem(value: 'suspend', child: Text('Askıya Al')),
              if (isSuspended)
                const PopupMenuItem(value: 'activate', child: Text('Aktifleştir')),
            ],
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: trustColor.withOpacity(0.12),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              trustStatus,
              style: TextStyle(color: trustColor, fontSize: 10, fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _handleUserAction(BuildContext context, String action) async {
    final ref = FirebaseService.instance.users.doc(userDoc.id);
    if (action == 'flag') {
      await ref.set({'trustStatus': 'flagged', 'moderatedAt': FieldValue.serverTimestamp()}, SetOptions(merge: true));
    } else if (action == 'resolve') {
      await ref.set({'trustStatus': 'active', 'moderatedAt': FieldValue.serverTimestamp()}, SetOptions(merge: true));
    } else if (action == 'suspend') {
      await ref.set({
        'trustStatus': 'suspended',
        'disabledAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } else if (action == 'activate') {
      await ref.set({'trustStatus': 'active', 'disabledAt': FieldValue.delete()}, SetOptions(merge: true));
    }
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Kullanıcı aksiyonu uygulandı.'), backgroundColor: CoffeeColors.darkRoast),
    );
  }
}

class _NotificationsTab extends StatefulWidget {
  const _NotificationsTab();

  @override
  State<_NotificationsTab> createState() => _NotificationsTabState();
}

class _NotificationsTabState extends State<_NotificationsTab> {
  bool _sending = false;

  @override
  Widget build(BuildContext context) {
    final svc = FirebaseService.instance;

    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: svc.db.collection('adminAnnouncements').orderBy('createdAt', descending: true).snapshots(),
      builder: (context, snap) {
        final docs = snap.data?.docs ?? const [];
        final sent = docs.where((d) => (d.data()['status'] as String?) == 'sent').toList();

        return ListView(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 48),
          children: [
            GestureDetector(
              onTap: _sending ? null : () => _showCreateAnnouncementDialog(context),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [CoffeeColors.espresso, CoffeeColors.darkRoast],
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.add_alert_outlined, color: CoffeeColors.caramel, size: 22),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Yeni Bildirim Oluştur',
                            style: TextStyle(color: CoffeeColors.cream, fontWeight: FontWeight.w800, fontSize: 15),
                          ),
                          Text(
                            'Gerçek duyuru dokümanı oluşturur',
                            style: TextStyle(color: CoffeeColors.latte, fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                    _sending
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2, color: CoffeeColors.caramel),
                          )
                        : const Icon(Icons.arrow_forward_ios, color: CoffeeColors.caramel, size: 16),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            const _SectionHeader(title: 'Planlanmış & Taslak', subtitle: 'adminAnnouncements'),
            const SizedBox(height: 12),
            ...docs.where((d) {
              final s = (d.data()['status'] as String?) ?? 'draft';
              return s == 'draft' || s == 'scheduled';
            }).map((d) => Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: _AnnouncementCard(doc: d),
                )),
            const SizedBox(height: 24),
            const _SectionHeader(title: 'Gönderim Geçmişi', subtitle: 'status = sent'),
            const SizedBox(height: 12),
            ...sent.map((d) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: _SentAnnouncementRow(doc: d),
                )),
          ],
        );
      },
    );
  }

  Future<void> _showCreateAnnouncementDialog(BuildContext context) async {
    final titleController = TextEditingController();
    final bodyController = TextEditingController();
    String status = 'draft';
    String audience = 'all';

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: const Text('Yeni Duyuru'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: titleController,
                  decoration: const InputDecoration(labelText: 'Başlık'),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: bodyController,
                  maxLines: 3,
                  decoration: const InputDecoration(labelText: 'Mesaj'),
                ),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  value: status,
                  items: const [
                    DropdownMenuItem(value: 'draft', child: Text('Taslak')),
                    DropdownMenuItem(value: 'scheduled', child: Text('Planlı')),
                    DropdownMenuItem(value: 'sent', child: Text('Hemen Gönder')),
                  ],
                  onChanged: (v) => setDialogState(() => status = v ?? 'draft'),
                  decoration: const InputDecoration(labelText: 'Durum'),
                ),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  value: audience,
                  items: const [
                    DropdownMenuItem(value: 'all', child: Text('Tüm Kullanıcılar')),
                    DropdownMenuItem(value: 'active', child: Text('Aktif Kullanıcılar')),
                  ],
                  onChanged: (v) => setDialogState(() => audience = v ?? 'all'),
                  decoration: const InputDecoration(labelText: 'Hedef Kitle'),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('İptal')),
            ElevatedButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Kaydet')),
          ],
        ),
      ),
    );

    if (confirmed != true) return;
    final title = titleController.text.trim();
    final body = bodyController.text.trim();
    if (title.isEmpty || body.isEmpty) return;

    setState(() => _sending = true);
    final svc = FirebaseService.instance;
    final doc = await svc.db.collection('adminAnnouncements').add({
      'title': title,
      'body': body,
      'status': status,
      'audience': audience,
      'createdAt': FieldValue.serverTimestamp(),
    });

    if (status == 'sent') {
      final usersSnap = await svc.users.limit(200).get();
      final batch = svc.db.batch();
      for (final u in usersSnap.docs) {
        batch.set(svc.userNotifications(u.id).doc(), {
          'title': title,
          'body': body,
          'createdAt': FieldValue.serverTimestamp(),
          'source': 'admin',
          'announcementId': doc.id,
        });
      }
      await batch.commit();
    }

    if (!mounted) return;
    setState(() => _sending = false);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Duyuru kaydedildi.'), backgroundColor: CoffeeColors.darkRoast),
    );
  }
}

class _AnnouncementCard extends StatelessWidget {
  const _AnnouncementCard({required this.doc});

  final QueryDocumentSnapshot<Map<String, dynamic>> doc;

  @override
  Widget build(BuildContext context) {
    final d = doc.data();
    final status = (d['status'] as String?) ?? 'draft';
    final color = status == 'scheduled' ? CoffeeColors.success : CoffeeColors.caramel;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.3)),
        boxShadow: FR.softShadow,
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  (d['title'] as String?) ?? '-',
                  style: const TextStyle(fontWeight: FontWeight.w700, color: CoffeeColors.espresso, fontSize: 14),
                ),
                const SizedBox(height: 3),
                Text(
                  '${(d['audience'] as String?) ?? '-'} · $status',
                  style: const TextStyle(color: CoffeeColors.cocoa, fontSize: 11),
                ),
              ],
            ),
          ),
          TextButton(
            onPressed: () async {
              await doc.reference.set({'status': 'sent', 'sentAt': FieldValue.serverTimestamp()}, SetOptions(merge: true));
              if (!context.mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Duyuru gönderime alındı.'), backgroundColor: CoffeeColors.darkRoast),
              );
            },
            child: const Text('Gönder'),
          ),
        ],
      ),
    );
  }
}

class _SentAnnouncementRow extends StatelessWidget {
  const _SentAnnouncementRow({required this.doc});

  final QueryDocumentSnapshot<Map<String, dynamic>> doc;

  @override
  Widget build(BuildContext context) {
    final d = doc.data();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: CoffeeColors.crema),
      ),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(color: CoffeeColors.foam, borderRadius: BorderRadius.circular(10)),
            child: const Icon(Icons.check_circle_outline, color: CoffeeColors.success, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  (d['title'] as String?) ?? '-',
                  style: const TextStyle(fontWeight: FontWeight.w700, color: CoffeeColors.espresso, fontSize: 13),
                ),
                Text(
                  (d['audience'] as String?) ?? '-',
                  style: const TextStyle(color: CoffeeColors.cocoa, fontSize: 11),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title, this.subtitle});

  final String title;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.baseline,
      textBaseline: TextBaseline.alphabetic,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w800,
            color: CoffeeColors.espresso,
            letterSpacing: -0.2,
          ),
        ),
        if (subtitle != null) ...[
          const SizedBox(width: 8),
          Text(subtitle!, style: const TextStyle(color: CoffeeColors.cocoa, fontSize: 12)),
        ],
      ],
    );
  }
}
