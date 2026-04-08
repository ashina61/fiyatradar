import 'package:flutter/material.dart';
import '../theme.dart';
import '../widgets/design.dart';

// ─── Admin screen ─────────────────────────────────────────────────────────────

class AdminScreen extends StatefulWidget {
  const AdminScreen({super.key});

  @override
  State<AdminScreen> createState() => _AdminScreenState();
}

class _AdminScreenState extends State<AdminScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

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
              padding:
                  const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: CoffeeColors.caramel.withOpacity(0.18),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                    color: CoffeeColors.caramel.withOpacity(0.35)),
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
          labelStyle: const TextStyle(
            fontWeight: FontWeight.w800,
            fontSize: 13,
          ),
          unselectedLabelStyle: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 13,
          ),
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
        children: const [
          _OverviewTab(),
          _ContentTab(),
          _UsersTab(),
          _NotificationsTab(),
        ],
      ),
    );
  }
}

// ─── Overview tab ─────────────────────────────────────────────────────────────

class _OverviewTab extends StatelessWidget {
  const _OverviewTab();

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 48),
      children: [
        // ── Status summary ────────────────────────────────────────
        _AdminHeroCard(),
        const SizedBox(height: 20),

        // ── Critical queues ───────────────────────────────────────
        const _SectionHeader(
          title: 'Kritik Kuyruklar',
          subtitle: 'Aksiyon bekleyen öğeler',
        ),
        const SizedBox(height: 12),
        _QueueCard(
          icon: Icons.price_check_outlined,
          title: 'Onay Bekleyen Fiyatlar',
          count: 14,
          accentColor: CoffeeColors.caramel,
          onTap: () {},
        ),
        const SizedBox(height: 8),
        _QueueCard(
          icon: Icons.flag_outlined,
          title: 'Raporlanan İçerikler',
          count: 3,
          accentColor: CoffeeColors.danger,
          onTap: () {},
        ),
        const SizedBox(height: 8),
        _QueueCard(
          icon: Icons.inventory_2_outlined,
          title: 'Yönetim Gerektiren Ürünler',
          count: 7,
          accentColor: CoffeeColors.accent,
          onTap: () {},
        ),
        const SizedBox(height: 8),
        _QueueCard(
          icon: Icons.campaign_outlined,
          title: 'Bildirim Taslakları',
          count: 2,
          accentColor: CoffeeColors.success,
          onTap: () {},
        ),
        const SizedBox(height: 24),

        // ── Platform metrics ──────────────────────────────────────
        const _SectionHeader(
          title: 'Platform Durumu',
          subtitle: 'Son 7 gün',
        ),
        const SizedBox(height: 12),
        _MetricsGrid(),
        const SizedBox(height: 24),

        // ── Quick actions ─────────────────────────────────────────
        const _SectionHeader(
          title: 'Hızlı Erişim',
          subtitle: 'Sık kullanılan yönetim aksiyonları',
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _QuickActionTile(
                icon: Icons.add_box_outlined,
                label: 'Ürün Ekle',
                onTap: () {},
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _QuickActionTile(
                icon: Icons.bar_chart_outlined,
                label: 'Rapor Al',
                onTap: () {},
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _QuickActionTile(
                icon: Icons.send_outlined,
                label: 'Bildirim',
                onTap: () {},
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _AdminHeroCard extends StatelessWidget {
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
                padding:
                    const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                decoration: BoxDecoration(
                  color: CoffeeColors.success.withOpacity(0.20),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                      color: CoffeeColors.success.withOpacity(0.35)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    LiveDot(color: CoffeeColors.success),
                    const SizedBox(width: 5),
                    const Text(
                      'ÇALIŞIYOR',
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
            'Admin Kontrol Merkezi · v1.0.0',
            style: TextStyle(color: CoffeeColors.latte, fontSize: 13),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              _HeroStatChip(
                  label: 'aktif kullanıcı', value: '1.2K'),
              const SizedBox(width: 8),
              _HeroStatChip(label: 'ürün', value: '248'),
              const SizedBox(width: 8),
              _HeroStatChip(label: 'bugün kayıt', value: '87'),
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
          Text(
            label,
            style: const TextStyle(
                color: CoffeeColors.latte, fontSize: 10),
          ),
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
            color: isUrgent
                ? accentColor.withOpacity(0.35)
                : CoffeeColors.crema,
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
                border: Border.all(
                    color: accentColor.withOpacity(0.22)),
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
              padding: const EdgeInsets.symmetric(
                  horizontal: 10, vertical: 5),
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
            const Icon(Icons.chevron_right,
                color: CoffeeColors.cocoa, size: 18),
          ],
        ),
      ),
    );
  }
}

class _MetricsGrid extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: CoffeeColors.crema),
        boxShadow: FR.softShadow,
      ),
      child: Column(
        children: [
          _MetricRow(
            icon: Icons.people_alt_outlined,
            label: 'Yeni Kayıt',
            value: '+124',
            sub: 'son 7 gün',
            trend: '+18%',
            positive: true,
            showDivider: true,
          ),
          _MetricRow(
            icon: Icons.add_circle_outline,
            label: 'Fiyat Katkısı',
            value: '1.847',
            sub: 'son 7 gün',
            trend: '+34%',
            positive: true,
            showDivider: true,
          ),
          _MetricRow(
            icon: Icons.flag_outlined,
            label: 'Raporlama',
            value: '11',
            sub: 'son 7 gün',
            trend: '-5%',
            positive: false,
            showDivider: false,
          ),
        ],
      ),
    );
  }
}

class _MetricRow extends StatelessWidget {
  const _MetricRow({
    required this.icon,
    required this.label,
    required this.value,
    required this.sub,
    required this.trend,
    required this.positive,
    required this.showDivider,
  });
  final IconData icon;
  final String label;
  final String value;
  final String sub;
  final String trend;
  final bool positive;
  final bool showDivider;

  @override
  Widget build(BuildContext context) {
    final trendColor =
        positive ? CoffeeColors.success : CoffeeColors.danger;
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(
              horizontal: 16, vertical: 13),
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: CoffeeColors.foam,
                  borderRadius: BorderRadius.circular(10),
                ),
                child:
                    Icon(icon, color: CoffeeColors.darkRoast, size: 18),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: const TextStyle(
                        color: CoffeeColors.espresso,
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                      ),
                    ),
                    Text(
                      sub,
                      style: const TextStyle(
                          color: CoffeeColors.cocoa, fontSize: 11),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    value,
                    style: const TextStyle(
                      color: CoffeeColors.espresso,
                      fontWeight: FontWeight.w800,
                      fontSize: 16,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: trendColor.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      trend,
                      style: TextStyle(
                        color: trendColor,
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        if (showDivider)
          const Divider(height: 1, indent: 64, color: CoffeeColors.crema),
      ],
    );
  }
}

class _QuickActionTile extends StatelessWidget {
  const _QuickActionTile(
      {required this.icon, required this.label, required this.onTap});
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: CoffeeColors.crema),
          boxShadow: FR.softShadow,
        ),
        child: Column(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: CoffeeColors.espresso,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon,
                  color: CoffeeColors.caramel, size: 20),
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: const TextStyle(
                color: CoffeeColors.espresso,
                fontWeight: FontWeight.w700,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Content tab ─────────────────────────────────────────────────────────────

class _ContentTab extends StatefulWidget {
  const _ContentTab();

  @override
  State<_ContentTab> createState() => _ContentTabState();
}

class _ContentTabState extends State<_ContentTab> {
  String _contentFilter = 'Tümü';
  final _filters = ['Tümü', 'Onay Bekleyen', 'Aktif', 'Arşiv'];

  static const _products = [
    _AdminProduct(
        name: 'Filiz Eriştesi 500g',
        category: 'Makarna',
        entries: 24,
        status: 'active'),
    _AdminProduct(
        name: 'Pınar Süt 1L',
        category: 'Süt Ürünleri',
        entries: 18,
        status: 'pending'),
    _AdminProduct(
        name: 'Ülker Çikolata 60g',
        category: 'Atıştırmalık',
        entries: 31,
        status: 'active'),
    _AdminProduct(
        name: 'Elidor Şampuan 400ml',
        category: 'Kişisel Bakım',
        entries: 9,
        status: 'pending'),
    _AdminProduct(
        name: 'Aytemiz Zeytinyağı',
        category: 'Yağ',
        entries: 0,
        status: 'archive'),
  ];

  @override
  Widget build(BuildContext context) {
    final filtered = _contentFilter == 'Tümü'
        ? _products
        : _products.where((p) {
            if (_contentFilter == 'Onay Bekleyen') {
              return p.status == 'pending';
            } else if (_contentFilter == 'Aktif') {
              return p.status == 'active';
            } else {
              return p.status == 'archive';
            }
          }).toList();

    return Column(
      children: [
        // Filter chips
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
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: selected
                          ? CoffeeColors.espresso
                          : Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                          color: selected
                              ? CoffeeColors.espresso
                              : CoffeeColors.crema),
                    ),
                    child: Text(
                      f,
                      style: TextStyle(
                        color: selected
                            ? CoffeeColors.cream
                            : CoffeeColors.darkRoast,
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

        // Product list
        Expanded(
          child: ListView.separated(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 48),
            itemCount: filtered.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (context, i) =>
                _ProductAdminRow(product: filtered[i]),
          ),
        ),
      ],
    );
  }
}

class _AdminProduct {
  final String name;
  final String category;
  final int entries;
  final String status;
  const _AdminProduct({
    required this.name,
    required this.category,
    required this.entries,
    required this.status,
  });
}

class _ProductAdminRow extends StatelessWidget {
  const _ProductAdminRow({required this.product});
  final _AdminProduct product;

  Color get _statusColor => switch (product.status) {
        'active' => CoffeeColors.success,
        'pending' => CoffeeColors.caramel,
        _ => CoffeeColors.cocoa,
      };

  String get _statusLabel => switch (product.status) {
        'active' => 'Aktif',
        'pending' => 'Bekliyor',
        _ => 'Arşiv',
      };

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: product.status == 'pending'
              ? CoffeeColors.caramel.withOpacity(0.35)
              : CoffeeColors.crema,
          width: product.status == 'pending' ? 1.5 : 1,
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
                  product.name,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    color: CoffeeColors.espresso,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 3),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: CoffeeColors.foam,
                        borderRadius: BorderRadius.circular(5),
                      ),
                      child: Text(
                        product.category,
                        style: const TextStyle(
                          color: CoffeeColors.cocoa,
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      '${product.entries} kayıt',
                      style: const TextStyle(
                          color: CoffeeColors.cocoa, fontSize: 11),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          // Status chip
          Container(
            padding: const EdgeInsets.symmetric(
                horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: _statusColor.withOpacity(0.12),
              borderRadius: BorderRadius.circular(9),
              border: Border.all(
                  color: _statusColor.withOpacity(0.25)),
            ),
            child: Text(
              _statusLabel,
              style: TextStyle(
                color: _statusColor,
                fontSize: 11,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(width: 8),
          // Actions
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert,
                color: CoffeeColors.cocoa, size: 18),
            color: Colors.white,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14)),
            elevation: 4,
            onSelected: (val) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('$val: ${product.name}'),
                  backgroundColor: CoffeeColors.darkRoast,
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
            itemBuilder: (_) => [
              const PopupMenuItem(
                value: 'Düzenle',
                child: Text('Düzenle',
                    style: TextStyle(
                        color: CoffeeColors.espresso,
                        fontSize: 14)),
              ),
              if (product.status == 'pending')
                const PopupMenuItem(
                  value: 'Onayla',
                  child: Text('Onayla',
                      style: TextStyle(
                          color: CoffeeColors.success,
                          fontWeight: FontWeight.w700,
                          fontSize: 14)),
                ),
              const PopupMenuItem(
                value: 'Arşivle',
                child: Text('Arşivle',
                    style: TextStyle(
                        color: CoffeeColors.cocoa, fontSize: 14)),
              ),
              const PopupMenuItem(
                value: 'Sil',
                child: Text('Sil',
                    style: TextStyle(
                        color: CoffeeColors.danger,
                        fontWeight: FontWeight.w700,
                        fontSize: 14)),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ─── Users tab ────────────────────────────────────────────────────────────────

class _UsersTab extends StatelessWidget {
  const _UsersTab();

  static const _users = [
    _AdminUser(
        name: 'Ayşe K.',
        username: '@ayse_k',
        contributions: 48,
        trustScore: 94,
        status: 'active'),
    _AdminUser(
        name: 'Mehmet D.',
        username: '@mehmetd',
        contributions: 22,
        trustScore: 78,
        status: 'active'),
    _AdminUser(
        name: 'Zeynep A.',
        username: '@zeynep_a',
        contributions: 3,
        trustScore: 45,
        status: 'flagged'),
    _AdminUser(
        name: 'Burak Y.',
        username: '@burakyy',
        contributions: 67,
        trustScore: 99,
        status: 'active'),
    _AdminUser(
        name: 'Anonim Kullanıcı',
        username: '@anon_01xk',
        contributions: 0,
        trustScore: 20,
        status: 'flagged'),
  ];

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 48),
      children: [
        // Trust stats summary
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
              _TrustStat(
                  label: 'Aktif', value: '1.184', color: CoffeeColors.success),
              _vDivider(),
              _TrustStat(
                  label: 'Bayraklı', value: '23', color: CoffeeColors.danger),
              _vDivider(),
              _TrustStat(
                  label: 'Askıya Alınan', value: '5', color: CoffeeColors.cocoa),
            ],
          ),
        ),
        const SizedBox(height: 20),

        const _SectionHeader(
          title: 'Kullanıcı Listesi',
          subtitle: 'Katkı ve güven skoru',
        ),
        const SizedBox(height: 12),

        ..._users.map((u) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: _UserAdminRow(user: u),
            )),
      ],
    );
  }

  Widget _vDivider() =>
      Container(width: 1, height: 36, color: CoffeeColors.crema);
}

class _AdminUser {
  final String name;
  final String username;
  final int contributions;
  final int trustScore;
  final String status;
  const _AdminUser({
    required this.name,
    required this.username,
    required this.contributions,
    required this.trustScore,
    required this.status,
  });
}

class _TrustStat extends StatelessWidget {
  const _TrustStat(
      {required this.label, required this.value, required this.color});
  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Text(
            value,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w800,
              fontSize: 18,
            ),
          ),
          Text(
            label,
            style: const TextStyle(
                color: CoffeeColors.cocoa, fontSize: 11),
          ),
        ],
      ),
    );
  }
}

class _UserAdminRow extends StatelessWidget {
  const _UserAdminRow({required this.user});
  final _AdminUser user;

  @override
  Widget build(BuildContext context) {
    final isFlagged = user.status == 'flagged';
    final trustColor = user.trustScore >= 80
        ? CoffeeColors.success
        : user.trustScore >= 50
            ? CoffeeColors.caramel
            : CoffeeColors.danger;

    return Container(
      padding: const EdgeInsets.fromLTRB(14, 12, 12, 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isFlagged
              ? CoffeeColors.danger.withOpacity(0.3)
              : CoffeeColors.crema,
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
              color: isFlagged
                  ? CoffeeColors.danger.withOpacity(0.10)
                  : CoffeeColors.foam,
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: Icon(
              isFlagged
                  ? Icons.flag_outlined
                  : Icons.person_outline,
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
                  user.name,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    color: CoffeeColors.espresso,
                    fontSize: 14,
                  ),
                ),
                Text(
                  '${user.username} · ${user.contributions} katkı',
                  style: const TextStyle(
                      color: CoffeeColors.cocoa, fontSize: 11),
                ),
              ],
            ),
          ),
          // Trust score
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${user.trustScore}',
                style: TextStyle(
                  color: trustColor,
                  fontWeight: FontWeight.w800,
                  fontSize: 16,
                ),
              ),
              Text(
                'güven',
                style: TextStyle(color: trustColor.withOpacity(0.7), fontSize: 10),
              ),
            ],
          ),
          const SizedBox(width: 8),
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert,
                color: CoffeeColors.cocoa, size: 18),
            color: Colors.white,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14)),
            elevation: 4,
            onSelected: (val) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('$val: ${user.name}'),
                  backgroundColor: CoffeeColors.darkRoast,
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
            itemBuilder: (_) => [
              const PopupMenuItem(
                value: 'Profili Gör',
                child: Text('Profili Gör',
                    style: TextStyle(
                        color: CoffeeColors.espresso, fontSize: 14)),
              ),
              if (isFlagged)
                const PopupMenuItem(
                  value: 'Temizle',
                  child: Text('Bayrağı Kaldır',
                      style: TextStyle(
                          color: CoffeeColors.success,
                          fontWeight: FontWeight.w700,
                          fontSize: 14)),
                ),
              const PopupMenuItem(
                value: 'Askıya Al',
                child: Text('Askıya Al',
                    style: TextStyle(
                        color: CoffeeColors.danger,
                        fontWeight: FontWeight.w700,
                        fontSize: 14)),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ─── Notifications tab ────────────────────────────────────────────────────────

class _NotificationsTab extends StatelessWidget {
  const _NotificationsTab();

  static const _drafts = [
    _NotifDraft(
        title: 'Haftalık Fiyat Özeti',
        audience: 'Tüm Kullanıcılar',
        scheduledFor: 'Pazartesi 09:00',
        status: 'scheduled'),
    _NotifDraft(
        title: 'Yeni Ürün: Tarım Kredi Fiyatları',
        audience: 'Aktif Kullanıcılar',
        scheduledFor: 'Taslak',
        status: 'draft'),
  ];

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 48),
      children: [
        // New notification CTA
        GestureDetector(
          onTap: () {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Yeni bildirim oluşturuluyor…'),
                backgroundColor: CoffeeColors.darkRoast,
                behavior: SnackBarBehavior.floating,
              ),
            );
          },
          child: Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [CoffeeColors.espresso, CoffeeColors.darkRoast],
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Row(
              children: [
                Icon(Icons.add_alert_outlined,
                    color: CoffeeColors.caramel, size: 22),
                SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Yeni Bildirim Oluştur',
                        style: TextStyle(
                          color: CoffeeColors.cream,
                          fontWeight: FontWeight.w800,
                          fontSize: 15,
                        ),
                      ),
                      Text(
                        'Tüm veya segment kullanıcılara gönder',
                        style: TextStyle(
                            color: CoffeeColors.latte, fontSize: 12),
                      ),
                    ],
                  ),
                ),
                Icon(Icons.arrow_forward_ios,
                    color: CoffeeColors.caramel, size: 16),
              ],
            ),
          ),
        ),
        const SizedBox(height: 24),

        const _SectionHeader(
          title: 'Planlanmış & Taslak',
          subtitle: 'Bekleyen bildirimler',
        ),
        const SizedBox(height: 12),

        ..._drafts.map((d) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: _NotifDraftCard(draft: d),
            )),

        const SizedBox(height: 24),

        const _SectionHeader(
          title: 'Gönderim Geçmişi',
          subtitle: 'Son 30 gün',
        ),
        const SizedBox(height: 12),

        _SentNotifRow(
          title: 'BİM fiyatları güncellendi',
          sentAt: '4 Nis · 10:23',
          reach: '2.1K',
        ),
        const SizedBox(height: 8),
        _SentNotifRow(
          title: 'Yeni ürün: Ayçiçek Yağı',
          sentAt: '2 Nis · 14:05',
          reach: '1.8K',
        ),
        const SizedBox(height: 8),
        _SentNotifRow(
          title: 'Haftalık fiyat özeti #14',
          sentAt: '1 Nis · 09:00',
          reach: '3.2K',
        ),
      ],
    );
  }
}

class _NotifDraft {
  final String title;
  final String audience;
  final String scheduledFor;
  final String status;
  const _NotifDraft({
    required this.title,
    required this.audience,
    required this.scheduledFor,
    required this.status,
  });
}

class _NotifDraftCard extends StatelessWidget {
  const _NotifDraftCard({required this.draft});
  final _NotifDraft draft;

  @override
  Widget build(BuildContext context) {
    final isScheduled = draft.status == 'scheduled';
    final statusColor =
        isScheduled ? CoffeeColors.success : CoffeeColors.caramel;
    final statusLabel = isScheduled ? 'Planlandı' : 'Taslak';

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isScheduled
              ? CoffeeColors.success.withOpacity(0.3)
              : CoffeeColors.crema,
          width: isScheduled ? 1.5 : 1,
        ),
        boxShadow: FR.softShadow,
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: statusColor.withOpacity(0.12),
              borderRadius: BorderRadius.circular(11),
            ),
            child: Icon(
              isScheduled
                  ? Icons.schedule_outlined
                  : Icons.edit_note_outlined,
              color: statusColor,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  draft.title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    color: CoffeeColors.espresso,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  '${draft.audience} · ${draft.scheduledFor}',
                  style: const TextStyle(
                      color: CoffeeColors.cocoa, fontSize: 11),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
            decoration: BoxDecoration(
              color: statusColor.withOpacity(0.12),
              borderRadius: BorderRadius.circular(8),
              border:
                  Border.all(color: statusColor.withOpacity(0.25)),
            ),
            child: Text(
              statusLabel,
              style: TextStyle(
                color: statusColor,
                fontSize: 11,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SentNotifRow extends StatelessWidget {
  const _SentNotifRow({
    required this.title,
    required this.sentAt,
    required this.reach,
  });
  final String title;
  final String sentAt;
  final String reach;

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
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: CoffeeColors.foam,
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.check_circle_outline,
                color: CoffeeColors.success, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    color: CoffeeColors.espresso,
                    fontSize: 13,
                  ),
                ),
                Text(
                  sentAt,
                  style: const TextStyle(
                      color: CoffeeColors.cocoa, fontSize: 11),
                ),
              ],
            ),
          ),
          Row(
            children: [
              const Icon(Icons.people_alt_outlined,
                  size: 13, color: CoffeeColors.caramel),
              const SizedBox(width: 4),
              Text(
                reach,
                style: const TextStyle(
                  color: CoffeeColors.cocoa,
                  fontWeight: FontWeight.w700,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ─── Shared components ────────────────────────────────────────────────────────

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
          Text(
            subtitle!,
            style: const TextStyle(
                color: CoffeeColors.cocoa, fontSize: 12),
          ),
        ],
      ],
    );
  }
}
