import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../providers/auth_provider.dart';
import '../../providers/product_provider.dart';
import '../../providers/theme_provider.dart';
import '../../models/product_model.dart';
import '../../utils/formatters.dart';
import '../../utils/constants.dart';
import '../../utils/elite_level_engine.dart';
import '../../utils/level_system.dart';
import '../../utils/theme.dart';
import '../../services/firestore_service.dart';
import '../admin/admin_panel_screen.dart';
import '../auth/login_screen.dart';
import '../notifications/notifications_screen.dart';
import '../product/product_detail_screen.dart';
import '../../widgets/premium_level_badge.dart';
import 'fiyatradar_settings.dart'; 
import 'update_history_screen.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  int _reloadKey = 0;

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const LoginScreen()),
          (route) => false,
        );
      });
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final userAsync = ref.watch(userModelStreamProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFFDFBF9),
      appBar: AppBar(
        backgroundColor: const Color(0xFFFDFBF9),
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
        titleSpacing: 20,
        title: Row(
          children: [
            Container(
              width: 4,
              height: 24,
              decoration: BoxDecoration(
                color: const Color(0xFFAF6B3E),
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            const SizedBox(width: 12),
            const Text(
              'Profil',
              style: TextStyle(
                color: Color(0xFF3A2B24),
                fontSize: 20,
                fontWeight: FontWeight.w900,
                letterSpacing: -0.5,
              ),
            ),
          ],
        ),
      ),
      body: userAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, __) => _ErrorState(onRetry: () => setState(() => _reloadKey++)),
        data: (userModel) {
          return FutureBuilder<_ProfileData>(
            key: ValueKey(_reloadKey),
            future: _loadProfile(uid),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (snapshot.hasError || !snapshot.hasData) {
                return _ErrorState(onRetry: () => setState(() => _reloadKey++));
              }

              final data = snapshot.data!;
              return RefreshIndicator(
                color: const Color(0xFF955427),
                onRefresh: () async => setState(() => _reloadKey++),
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 4),
                        _BossHeroCard(
                          data: data,
                          onEdit: () async {
                            await Navigator.of(context).push(
                              CupertinoPageRoute(builder: (_) => const FiyatRadarSettingsScreen()),
                            );
                            if (mounted) setState(() => _reloadKey++);
                          },
                        ),
                        const SizedBox(height: 16),
                        _StatsRow(totalPoints: data.totalPoints, cityRank: data.cityRank),
                        const SizedBox(height: 12),
                        _QuickActionsGrid(uid: uid),
                        const SizedBox(height: 16),
                        const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 10),
                          child: Text(
                            'Hesap Yönetimi',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.8,
                              color: Color(0xFF8C7A6B),
                            ),
                          ),
                        ),
                        const SizedBox(height: 10),
                        _MenuSection(
                          isAdmin: userModel?.isAdmin == true,
                          onReload: () => setState(() => _reloadKey++),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  Future<_ProfileData> _loadProfile(String uid) async {
    final userRef = FirebaseFirestore.instance.collection('users').doc(uid);
    final userDoc = await userRef.get();
    if (!userDoc.exists) {
      await userRef.set({
        'displayName': 'Kullanıcı',
        'photoUrl': '',
        'photoURL': '',
        'verified': false,
        'trustScore': 0,
        'levelName': 'Gözlemci',
        'monthlySavings': '₺0',
        'topMarket': 'Henüz yok',
        'totalPoints': 0,
        'weeklyPoints': 0,
        'streakDays': 0,
        'createdAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    }

    final data = (await userRef.get()).data() ?? <String, dynamic>{};
    Map<String, dynamic> trustProfile = const <String, dynamic>{};
    try {
      trustProfile = await ref.read(firestoreServiceProvider).getUserTrustProfile(uid);
    } catch (_) {
      trustProfile = const <String, dynamic>{};
    }
    final totalPoints =
        (data['totalPoints'] as num?)?.toInt() ?? (data['pointsTotal'] as num?)?.toInt() ?? (data['points'] as num?)?.toInt() ?? 0;
    final trustTotalVotes = (trustProfile['trustTotalVotes'] as num?)?.toInt() ?? 0;
    final trustPercent = (trustProfile['trustScorePercent'] as num?)?.toInt() ?? 0;
    final pointsLevel = EliteLevelEngine.getPointsLevel(totalPoints);
    final pointsLevelName = EliteLevelEngine.getLevelStyle(pointsLevel).label;
    final userCity = (data['cityName'] ?? data['city'] ?? '').toString().trim();
    final cityRank = await _resolveCityRank(uid: uid, cityName: userCity);

    return _ProfileData(
      displayName: (data['name'] ?? data['displayName'] ?? 'Kullanıcı').toString(),
      username: (data['username'] ?? data['userName'] ?? '').toString(),
      photoUrl: (data['photoURL'] ?? data['photoUrl'] ?? '').toString(),
      totalPoints: totalPoints,
      cityRank: cityRank,
      pointsLevelName: pointsLevelName,
      trustScore: trustPercent.toDouble(),
      trustTotalVotes: trustTotalVotes,
    );
  }

  Future<int?> _resolveCityRank({required String uid, required String cityName}) async {
    if (cityName.isEmpty) return null;

    try {
      final byCityName = await FirebaseFirestore.instance.collection('users').where('cityName', isEqualTo: cityName).get();
      final cityNameRank = _findRank(_sortByPoints(byCityName.docs), uid);
      if (cityNameRank != null) return cityNameRank;

      final byCity = await FirebaseFirestore.instance.collection('users').where('city', isEqualTo: cityName).get();
      return _findRank(_sortByPoints(byCity.docs), uid);
    } catch (_) {
      return null;
    }
  }

  List<QueryDocumentSnapshot<Map<String, dynamic>>> _sortByPoints(List<QueryDocumentSnapshot<Map<String, dynamic>>> docs) {
    final sorted = [...docs];
    sorted.sort((a, b) {
      final aPoints = (a.data()['totalPoints'] as num?)?.toInt() ??
          (a.data()['pointsTotal'] as num?)?.toInt() ??
          (a.data()['points'] as num?)?.toInt() ??
          0;
      final bPoints = (b.data()['totalPoints'] as num?)?.toInt() ??
          (b.data()['pointsTotal'] as num?)?.toInt() ??
          (b.data()['points'] as num?)?.toInt() ??
          0;
      return bPoints.compareTo(aPoints);
    });
    return sorted;
  }

  int? _findRank(List<QueryDocumentSnapshot<Map<String, dynamic>>> docs, String uid) {
    for (var i = 0; i < docs.length; i++) {
      if (docs[i].id == uid) return i + 1;
    }
    return null;
  }
}

class _BossHeroCard extends StatelessWidget {
  const _BossHeroCard({required this.data, required this.onEdit});

  final _ProfileData data;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    final levelStyle = EliteLevelEngine.getLevelStyle(
      EliteLevelEngine.parseLevelLabel(data.pointsLevelName),
    );
    final currentLevelColor = levelStyle.borderColor;
    final nameTextColor = currentLevelColor.computeLuminance() > 0.55 ? const Color(0xFF3E2723) : Colors.white;
    final trustRatio = (data.trustScore / 100).clamp(0.0, 1.0);

    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFAF6B3E), Color(0xFF955427)],
        ),
        borderRadius: BorderRadius.circular(34),
        boxShadow: const [
          BoxShadow(
            color: Color.fromRGBO(149, 84, 39, 0.30),
            blurRadius: 28,
            offset: Offset(0, 14),
          ),
        ],
      ),
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 20),
      child: Column(
        children: [
          Align(
            alignment: Alignment.topRight,
            child: IconButton(
              onPressed: onEdit,
              style: IconButton.styleFrom(
                backgroundColor: Colors.white.withOpacity(0.18),
              ),
              icon: const Icon(Icons.edit_rounded, color: Colors.white),
            ),
          ),
          Center(
            child: Container(
              width: 140,
              height: 140,
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: currentLevelColor.withOpacity(0.5),
                    blurRadius: 20,
                    spreadRadius: 5,
                  ),
                ],
              ),
              child: _Avatar(avatarUrl: data.photoUrl, displayName: data.displayName, size: 128),
            ),
          ),
          const SizedBox(height: 18),
          IntrinsicWidth(
            child: Container(
              constraints: const BoxConstraints(maxWidth: 300),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: currentLevelColor,
                borderRadius: BorderRadius.circular(999),
                border: Border.all(color: Colors.white.withOpacity(0.22)),
              ),
              child: Text(
                data.displayName,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: nameTextColor,
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  height: 1.15,
                ),
              ),
            ),
          ),
          if (data.username.trim().isNotEmpty) ...[
            const SizedBox(height: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: currentLevelColor.withOpacity(0.2),
                borderRadius: BorderRadius.circular(999),
                border: Border.all(color: currentLevelColor.withOpacity(0.65)),
              ),
              child: Text(
                '@${data.username.trim()}',
                style: TextStyle(
                  color: nameTextColor.withOpacity(0.92),
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                ),
              ),
            ),
          ],
          const SizedBox(height: 16),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.1),
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: Colors.white.withOpacity(0.2)),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    const Text(
                      'Sistem Güven Endeksi',
                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 13),
                    ),
                    const Spacer(),
                    Text(
                      '%${data.trustScore.round()} (Elit)',
                      style: const TextStyle(
                        color: Color(0xFF00E676),
                        fontWeight: FontWeight.w800,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Container(
                  height: 10,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  alignment: Alignment.centerLeft,
                  child: FractionallySizedBox(
                    widthFactor: trustRatio,
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(20),
                        gradient: const LinearGradient(
                          colors: [Color(0xFF00BFA5), Color(0xFF00E676)],
                        ),
                        boxShadow: const [BoxShadow(color: Color.fromRGBO(0, 230, 118, 0.6), blurRadius: 10)],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Avatar extends StatelessWidget {
  const _Avatar({required this.avatarUrl, required this.displayName, this.size = 52});

  final String avatarUrl;
  final String displayName;
  final double size;

  @override
  Widget build(BuildContext context) {
    return ClipOval(
      child: SizedBox(
        width: size,
        height: size,
        child: avatarUrl.isEmpty
            ? Container(
                color: const Color(0xFFFFE8B7),
                alignment: Alignment.center,
                child: Text(
                  displayName.isEmpty ? 'K' : displayName[0].toUpperCase(),
                  style: TextStyle(
                    fontSize: size * 0.35,
                    fontWeight: FontWeight.w800,
                    color: const Color(0xFF3D2A00),
                  ),
                ),
              )
            : CachedNetworkImage(
                imageUrl: avatarUrl,
                fit: BoxFit.cover,
                memCacheWidth: 220,
                memCacheHeight: 220,
                errorWidget: (_, __, ___) => Container(
                  color: const Color(0xFFFFE8B7),
                  alignment: Alignment.center,
                  child: Text(
                    displayName.isEmpty ? 'K' : displayName[0].toUpperCase(),
                    style: TextStyle(
                      fontSize: size * 0.35,
                      fontWeight: FontWeight.w800,
                      color: const Color(0xFF3D2A00),
                    ),
                  ),
                ),
              ),
      ),
    );
  }
}

class _StatsRow extends StatelessWidget {
  const _StatsRow({required this.totalPoints, required this.cityRank});

  final int totalPoints;
  final int? cityRank;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _StatCard(value: '${(totalPoints / 1000).toStringAsFixed(1)}K', label: 'Radar Puanı'),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _StatCard(value: cityRank == null ? '-' : '#$cityRank', label: 'Şehir Sırası'),
        ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({required this.value, required this.label});

  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFF5EFEB)),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: Color(0xFF3A2B24)),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w800,
              color: Color(0xFF8C7A6B),
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }
}

class _QuickActionsGrid extends StatelessWidget {
  const _QuickActionsGrid({required this.uid});
  final String uid;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _QuickActionCard(
          icon: Icons.sell,
          label: 'Fiyatlarım',
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => MyPricesScreen(userId: uid)),
          ),
        ),
        const SizedBox(width: 10),
        _QuickActionCard(
          icon: Icons.favorite_border,
          label: 'Favoriler',
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => FavoritesScreen(userId: uid)),
          ),
        ),
        const SizedBox(width: 10),
        _QuickActionCard(
          icon: Icons.notifications_none,
          label: 'Bildirimler',
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const NotificationsScreen()),
          ),
        ),
      ],
    );
  }
}

class _QuickActionCard extends StatelessWidget {
  const _QuickActionCard({required this.icon, required this.label, required this.onTap});

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0xFFF5EFEB)),
          ),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8F4F0),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(icon, size: 23, color: const Color(0xFF8C7A6B)),
              ),
              const SizedBox(height: 8),
              Text(
                label,
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF3A2B24)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MenuSection extends ConsumerWidget {
  const _MenuSection({required this.isAdmin, required this.onReload});

  final bool isAdmin;
  final VoidCallback onReload;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeProvider);

    return Column(
      children: [
        _MenuTile(
          icon: Icons.edit_rounded,
          title: 'Hesap & Ayarlar',
          onTap: () async {
            await Navigator.push(
              context,
              CupertinoPageRoute(builder: (_) => const FiyatRadarSettingsScreen()),
            );
            onReload();
          },
        ),
        const SizedBox(height: 10),
        _MenuTile(
          icon: Icons.dark_mode_rounded,
          title: 'Karanlık Mod',
          trailing: Switch(
            value: themeMode == ThemeMode.dark,
            onChanged: (_) => ref.read(themeModeProvider.notifier).toggleDarkMode(),
          ),
          onTap: () => ref.read(themeModeProvider.notifier).toggleDarkMode(),
        ),
        if (isAdmin) ...[
          const SizedBox(height: 10),
          _MenuTile(
            icon: Icons.admin_panel_settings_rounded,
            iconBackground: const Color(0xFFFFB300),
            title: 'Admin Paneli',
            badge: const _AdminBadge(),
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const AdminPanelScreen()),
            ),
          ),
        ],
        const SizedBox(height: 10),
        _MenuTile(
          icon: Icons.logout_rounded,
          title: 'Çıkış Yap',
          textColor: Colors.red.shade400,
          iconColor: Colors.red.shade400,
          iconBackground: Colors.red.shade50,
          background: const Color(0xFFFFF7F7),
          showChevron: false,
          onTap: () async {
            await ref.read(authServiceProvider).signOut();
            if (!context.mounted) return;
            Navigator.of(context).pushAndRemoveUntil(
              MaterialPageRoute(builder: (_) => const LoginScreen()),
              (route) => false,
            );
          },
        ),
      ],
    );
  }
}

class _MenuTile extends StatelessWidget {
  const _MenuTile({
    required this.icon,
    required this.title,
    required this.onTap,
    this.trailing,
    this.showChevron = true,
    this.badge,
    this.background = Colors.white,
    this.iconBackground,
    this.iconColor = const Color(0xFF8C7A6B),
    this.textColor = const Color(0xFF3A2B24),
  });

  final IconData icon;
  final String title;
  final VoidCallback onTap;
  final Widget? trailing;
  final bool showChevron;
  final Widget? badge;
  final Color background;
  final Color? iconBackground;
  final Color iconColor;
  final Color textColor;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: background,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0xFFF5EFEB)),
          ),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: iconBackground ?? const Color(0xFFF8F4F0),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: iconColor),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                    color: textColor,
                  ),
                ),
              ),
              if (badge != null) ...[badge!, const SizedBox(width: 10)],
              if (trailing != null) trailing! else if (showChevron) const Icon(Icons.chevron_right_rounded, color: Color(0xFFD1C4B9)),
            ],
          ),
        ),
      ),
    );
  }
}

class _AdminBadge extends StatelessWidget {
  const _AdminBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: const Color.fromRGBO(255, 179, 0, 0.15),
        borderRadius: BorderRadius.circular(8),
      ),
      child: const Text(
        'YETKİLİ',
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w800,
          color: Color(0xFFF57F17),
        ),
      ),
    );
  }
}

// ---------- Sub-Screens (unchanged logic, refreshed styling) ----------

class MyPricesScreen extends StatelessWidget {
  const MyPricesScreen({super.key, required this.userId});

  final String userId;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Fiyatlarim')),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: FirebaseFirestore.instance
            .collection('priceReports')
            .where('createdByUid', isEqualTo: userId)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return _ListError(onRetry: () => (context as Element).markNeedsBuild());
          }
          final docs = (snapshot.data?.docs ?? const [])
              .where((doc) => (doc.data()['status'] ?? '').toString() == 'active')
              .toList()
            ..sort((a, b) {
              final aTs = a.data()['createdAt'] as Timestamp?;
              final bTs = b.data()['createdAt'] as Timestamp?;
              final aDt = aTs?.toDate() ?? DateTime.fromMillisecondsSinceEpoch(0);
              final bDt = bTs?.toDate() ?? DateTime.fromMillisecondsSinceEpoch(0);
              return bDt.compareTo(aDt);
            });
          if (docs.isEmpty) {
            return const Center(child: Text('Henüz fiyat eklemedin.'));
          }
          return ListView.separated(
            itemCount: docs.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final data = docs[index].data();
              final ts = data['createdAt'];
              final date = ts is Timestamp ? ts.toDate() : null;
              final productName = (data['productName'] ?? data['urunAdi'] ?? data['name'] ?? data['title'] ?? '').toString().trim();
              final displayName = productName.isEmpty ? 'İsimsiz Ürün' : productName;
              final formattedDate = date == null ? 'Tarih yok' : '${date.day}.${date.month}.${date.year}';
              return ListTile(
                title: Text(displayName),
                subtitle: Text('${(data['storeName'] ?? 'Market').toString()} - $formattedDate'),
                trailing: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(formatTRY((data['price'] ?? 0) as num), style: const TextStyle(fontWeight: FontWeight.w700)),
                    if (data['verified'] == true)
                      const Text('Doğrulandı', style: TextStyle(fontSize: 11, color: Colors.green)),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class FavoritesScreen extends StatefulWidget {
  const FavoritesScreen({super.key, required this.userId});

  final String userId;

  @override
  State<FavoritesScreen> createState() => _FavoritesScreenState();
}

class _FavoritesScreenState extends State<FavoritesScreen> {
  final Map<String, ProductModel> _productCache = <String, ProductModel>{};
  Set<String> _loadingIds = <String>{};

  Future<void> _ensureProducts(List<String> productIds) async {
    final missing = productIds.where((id) => id.isNotEmpty && !_productCache.containsKey(id)).toSet();
    if (missing.isEmpty) return;
    if (_loadingIds.containsAll(missing)) return;

    setState(() => _loadingIds = {..._loadingIds, ...missing});
    try {
      final products = await FirestoreService().getProductsByIds(missing.toList());
      if (!mounted) return;
      setState(() {
        for (final product in products) {
          _productCache[product.id] = product;
        }
      });
    } finally {
      if (mounted) {
        setState(() => _loadingIds = _loadingIds.difference(missing));
      }
    }
  }

  Future<void> _removeFavorite(String productId) async {
    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.userId)
          .collection('favorites')
          .doc(productId)
          .delete();
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Favoriler güncellenemedi. Tekrar dene.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Favoriler')),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: FirebaseFirestore.instance
            .collection('users')
            .doc(widget.userId)
            .collection('favorites')
            .orderBy('createdAt', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return _ListError(onRetry: () => (context as Element).markNeedsBuild());
          }

          final docs = snapshot.data?.docs ?? const [];
          if (docs.isEmpty) {
            return Center(
              child: Container(
                margin: const EdgeInsets.all(24),
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(18),
                  color: AppColors.surfaceVariant,
                ),
                child: const Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.favorite_border, size: 42, color: AppColors.textTertiary),
                    SizedBox(height: 8),
                    Text('Henüz favori ürünün yok.'),
                  ],
                ),
              ),
            );
          }

          final productIds = docs
              .map((doc) => (doc.data()['productId'] ?? '').toString())
              .where((id) => id.isNotEmpty)
              .toList();
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _ensureProducts(productIds);
          });

          return ListView.builder(
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final data = docs[index].data();
              final productId = (data['productId'] ?? '').toString();
              final product = _productCache[productId];
              final title = product?.name ?? (data['productName'] ?? 'Ürün').toString();
              final subtitle = product?.brand ?? 'Ürün';
              final image = product?.effectiveImage;

              return Dismissible(
                key: ValueKey('fav-$productId'),
                direction: DismissDirection.endToStart,
                background: Container(
                  color: Colors.red.withOpacity(0.12),
                  alignment: Alignment.centerRight,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: const Icon(Icons.delete_outline, color: Colors.red),
                ),
                onDismissed: (_) => _removeFavorite(productId),
                child: ListTile(
                  leading: image == null
                      ? const Icon(Icons.favorite, color: Colors.red)
                      : ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.network(image, width: 44, height: 44, fit: BoxFit.cover, errorBuilder: (_, __, ___) => const Icon(Icons.favorite, color: Colors.red)),
                        ),
                  title: Text(title),
                  subtitle: Text(subtitle),
                  trailing: IconButton(
                    icon: const Icon(Icons.favorite, color: Colors.red),
                    onPressed: () => _removeFavorite(productId),
                  ),
                  onTap: () {
                    if (productId.isEmpty) return;
                    Navigator.of(context).push(MaterialPageRoute(builder: (_) => ProductDetailScreen(productId: productId)));
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class ReceiptsScreen extends StatelessWidget {
  const ReceiptsScreen({super.key, required this.userId});

  final String userId;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Fislerim')),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: FirebaseFirestore.instance.collection('users').doc(userId).collection('receipts').orderBy('createdAt', descending: true).snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return _ListError(onRetry: () => (context as Element).markNeedsBuild());
          }
          final docs = snapshot.data?.docs ?? const [];
          if (docs.isEmpty) {
            return const Center(child: Text('Henüz fiş eklemedin.'));
          }
          return ListView.builder(
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final data = docs[index].data();
              return ListTile(
                leading: const Icon(Icons.receipt_long_rounded),
                title: Text((data['market'] ?? 'Market').toString()),
                subtitle: Text((data['note'] ?? 'Fis').toString()),
                trailing: Text(formatTRY((data['total'] ?? 0) as num)),
              );
            },
          );
        },
      ),
    );
  }
}


class ProfileHelpScreen extends StatelessWidget {
  const ProfileHelpScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Yardım ve SSS')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: const [
          _HelpSectionCard(
            title: 'Sıkça Sorulan Sorular',
            icon: Icons.quiz_outlined,
            children: [
              _FaqItem(
                question: 'Puan sistemi nasıl çalışır?',
                answer:
                    'Fiyat ekleme, doğrulama ve topluluk etkileşimlerinden puan kazanırsınız. Puanlar seviyenizi, rozetlerinizi ve liderlik tablosundaki sıralamanızı etkiler.',
              ),
              _FaqItem(
                question: 'Güven puanı nasıl kazanılır?',
                answer:
                    'Eklediğiniz fiyatlar diğer kullanıcılar ve sistem kontrolleri tarafından doğru bulunduğunda güven puanınız artar. Hatalı veya yanıltıcı girişlerde güven puanı düşebilir.',
              ),
              _FaqItem(
                question: 'Hesabımı nasıl silerim?',
                answer:
                    'Profil > Ayarlar > Güvenlik menüsünden hesap kapatma talebi oluşturabilirsiniz. Güvenlik doğrulaması sonrası hesap kalıcı olarak silinir.',
              ),
              _FaqItem(
                question: 'Fiyat nasıl eklerim?',
                answer:
                    'Ana ekrandaki + butonuna dokunun, ürün/market/fiyat bilgilerini girin ve kaydedin. Fotoğraf eklerseniz katkınız daha hızlı doğrulanır.',
              ),
              _FaqItem(
                question: 'Fiyatın güvenilir olduğunu nasıl anlarım?',
                answer:
                    'Ürün detayındaki doğrulama oranına, son güncelleme zamanına ve katkı yapan kullanıcının güven göstergesine bakın. Birden fazla yeni doğrulama varsa fiyat daha güvenilirdir.',
              ),
            ],
          ),
          SizedBox(height: 16),
          _HelpSectionCard(
            title: 'Puan Toplama Sistemi',
            icon: Icons.stars_rounded,
            children: [
              _BulletText('Her fiyat girişi +${AppConstants.pointsForPriceEntry} puan kazandırır.'),
              _BulletText('Fotoğraf eklenen fiyat girişi +${AppConstants.pointsForPriceEntryWithPhoto} puan kazandırır.'),
              _BulletText('Doğrulanan katkılarda güven puanınız yükselir, hatalı bildirimlerde düşebilir.'),
              _BulletText('Puanlar rozetleri, seviye ilerlemesini ve liderlik tablosundaki sıranızı etkiler.'),
            ],
          ),
        ],
      ),
    );
  }
}

class _HelpSectionCard extends StatelessWidget {
  const _HelpSectionCard({
    required this.title,
    required this.icon,
    required this.children,
  });

  final String title;
  final IconData icon;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.outline.withOpacity(0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: AppColors.primary),
              const SizedBox(width: 8),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...children,
        ],
      ),
    );
  }
}

class _FaqItem extends StatelessWidget {
  const _FaqItem({required this.question, required this.answer});

  final String question;
  final String answer;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            question,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            answer,
            style: const TextStyle(
              fontSize: 13,
              height: 1.35,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

class _BulletText extends StatelessWidget {
  const _BulletText(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('• ', style: TextStyle(fontSize: 14, color: AppColors.textPrimary)),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                fontSize: 13,
                height: 1.35,
                color: AppColors.textSecondary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SettingsTile extends StatelessWidget {
  const _SettingsTile({
    required this.icon,
    required this.title,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.outline.withOpacity(0.5)),
          ),
          child: Row(
            children: [
              Icon(icon, color: AppColors.primary),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              const Icon(
                Icons.chevron_right_rounded,
                color: AppColors.textSecondary,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Hakkinda')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              gradient: const LinearGradient(
                colors: [Color(0xFFFFF8EF), Color(0xFFF8EDDB)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              border: Border.all(color: const Color(0xFFE8D5B8)),
            ),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'FiyatRadar',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                    color: AppColors.textPrimary,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'Surum 1.5.0 - FiyatRadar Ekibi',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          _SettingsTile(
            icon: Icons.privacy_tip_outlined,
            title: 'Gizlilik Politikasi',
            onTap: () => launchUrl(Uri.parse('https://fiyatradar.app/privacy')),
          ),
          const SizedBox(height: 8),
          _SettingsTile(
            icon: Icons.description_outlined,
            title: 'Kullanim Sartlari',
            onTap: () => launchUrl(Uri.parse('https://fiyatradar.app/terms')),
          ),
          const SizedBox(height: 8),
          _SettingsTile(
            icon: Icons.auto_awesome_rounded,
            title: 'Güncellemeler',
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const UpdateHistoryScreen()),
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.outline.withOpacity(0.5)),
            ),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.history_rounded, color: AppColors.primary),
                    SizedBox(width: 8),
                    Text(
                      'Son Yapilanlar',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 12),
                _BulletText('Fiyat Ekle ekrani Material 3 stiline gore yenilendi.'),
                _BulletText('Fiyat Sepeti ekraninda aksiyonlar sadeleştirildi ve sticky alt bar iyileştirildi.'),
                _BulletText('Profil ekranina Yardım ve SSS bolumu eklendi.'),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline_rounded, size: 48, color: AppColors.textTertiary),
          const SizedBox(height: 12),
          const Text(
            'Profil verisi yüklenemedi.',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh_rounded),
            label: const Text('Tekrar dene'),
          ),
        ],
      ),
    );
  }
}

class _ListError extends StatelessWidget {
  const _ListError({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.cloud_off_rounded, size: 48, color: AppColors.textTertiary),
          const SizedBox(height: 12),
          const Text(
            'Veriler alinamadi.',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh_rounded),
            label: const Text('Tekrar dene'),
          ),
        ],
      ),
    );
  }
}

class _ProfileData {
  const _ProfileData({
    required this.displayName,
    required this.photoUrl,
    required this.username,
    required this.pointsLevelName,
    required this.trustScore,
    required this.trustTotalVotes,
    required this.totalPoints,
    required this.cityRank,
  });

  final String displayName;
  final String photoUrl;
  final String username;
  final String pointsLevelName;
  final double trustScore;
  final int trustTotalVotes;
  final int totalPoints;
  final int? cityRank;
}
