import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../providers/auth_provider.dart';
import '../../providers/product_provider.dart';
import '../../providers/theme_provider.dart';
import '../../models/product_model.dart';
import '../../utils/formatters.dart';
import '../../utils/elite_level_engine.dart';
import '../../utils/level_style.dart';
import '../../utils/theme.dart';
import '../../widgets/premium_scaffold_shell.dart';
import '../../services/firestore_service.dart';
import '../admin/admin_panel_screen.dart';
import '../auth/login_screen.dart';
import '../notifications/notifications_screen.dart';
import '../points/points_screen.dart';
import '../product/product_detail_screen.dart';
import 'edit_profile_screen.dart';
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
      appBar: AppBar(title: const Text('Profil')),
      body: PremiumScaffoldShell(
        child: userAsync.when(
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
              if (snapshot.hasError) {
                return _ErrorState(onRetry: () => setState(() => _reloadKey++));
              }
              final data = snapshot.data;
              if (data == null) {
                return _ErrorState(onRetry: () => setState(() => _reloadKey++));
              }

              return RefreshIndicator(
                onRefresh: () async => setState(() => _reloadKey++),
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                  children: [
                    _PremiumHeaderCard(
                      displayName: data.displayName,
                      username: data.username,
                      avatarUrl: data.photoUrl,
                      trustScore: data.trustScore,
                      trustTotalVotes: data.trustTotalVotes,
                      levelName: data.levelName,
                      totalPoints: data.totalPoints,
                      isAdmin: userModel?.isAdmin == true,
                      onPointsTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const PointsScreen())),
                      onEdit: () async {
                        await Navigator.of(context).push(MaterialPageRoute(builder: (_) => const EditProfileScreen()));
                        if (mounted) setState(() => _reloadKey++);
                      },
                    ),
                    const SizedBox(height: 14),
                    _QuickBar(uid: uid),
                    const SizedBox(height: 14),
                    _SettingsList(
                      isAdmin: userModel?.isAdmin == true,
                      onReload: () => setState(() => _reloadKey++),
                    ),
                  ],
                ),
              );
            },
          );
        },
        ),
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
        'levelName': 'Standart',
        'monthlySavings': '₺0',
        'topMarket': 'Henüz yok',
        'totalPoints': 0,
        'weeklyPoints': 0,
        'streakDays': 0,
        'createdAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    }

    final data = (await userRef.get()).data() ?? <String, dynamic>{};
    final trustProfile = await ref.read(firestoreServiceProvider).getUserTrustProfile(uid);
    final totalPoints = (data['totalPoints'] as num?)?.toInt() ?? (data['pointsTotal'] as num?)?.toInt() ?? (data['points'] as num?)?.toInt() ?? 0;
    final trustTotalVotes = (trustProfile['trustTotalVotes'] as num?)?.toInt() ?? 0;
    final trustPercent = (trustProfile['trustScorePercent'] as num?)?.toInt() ?? 0;
    final finalLevel = EliteLevelEngine.getFinalLevel(totalPoints, trustPercent, trustTotalVotes);

    return _ProfileData(
      displayName: (data['displayName'] ?? data['name'] ?? 'Kullanıcı').toString(),
      username: (data['username'] ?? '').toString(),
      photoUrl: (data['photoURL'] ?? data['photoUrl'] ?? '').toString(),
      totalPoints: totalPoints,
      levelName: EliteLevelEngine.getLevelStyle(finalLevel).label,
      trustScore: trustPercent.toDouble(),
      trustTotalVotes: trustTotalVotes,
    );
  }
}

class _PremiumHeaderCard extends StatelessWidget {
  const _PremiumHeaderCard({
    required this.displayName,
    required this.avatarUrl,
    required this.username,
    required this.trustScore,
    required this.levelName,
    required this.trustTotalVotes,
    required this.totalPoints,
    required this.isAdmin,
    required this.onPointsTap,
    required this.onEdit,
  });

  final String displayName;
  final String avatarUrl;
  final String username;
  final double trustScore;
  final String levelName;
  final int trustTotalVotes;
  final int totalPoints;
  final bool isAdmin;
  final VoidCallback onPointsTap;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    final level = LevelStyle.fromLevelLabel(levelName, fallbackTotalPoints: totalPoints);
    final badgeEmoji = level.emoji;
    final badgeLabel = level.label;
    final shownUsername = username.trim().isEmpty ? displayName : username.trim();

    return Container(
      padding: const EdgeInsets.fromLTRB(18, 20, 18, 16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(26),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFFFF7EA), Color(0xFFF3E4CC)],
        ),
        border: Border.all(color: const Color(0xFFE3CCA2)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFB47C2C).withOpacity(0.15),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        children: [
          Align(
            alignment: Alignment.topRight,
            child: IconButton(onPressed: onEdit, icon: const Icon(Icons.edit_rounded, size: 20)),
          ),
          _Avatar(avatarUrl: avatarUrl, displayName: displayName, size: 110),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Flexible(
                child: Text(
                  shownUsername,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF3C280A),
                  ),
                ),
              ),
              if (isAdmin) ...[
                const SizedBox(width: 6),
                const Icon(Icons.verified_rounded, size: 20, color: Color(0xFF0059D6)),
              ],
            ],
          ),
          const SizedBox(height: 10),
          _TrustMiniCard(score: trustScore, totalVotes: trustTotalVotes),
          const SizedBox(height: 10),
          InkWell(
            onTap: onPointsTap,
            borderRadius: BorderRadius.circular(999),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.8),
                borderRadius: BorderRadius.circular(999),
                border: Border.all(color: const Color(0xFFE4D1AC)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.stars_rounded, size: 16, color: Color(0xFFB8863B)),
                  const SizedBox(width: 6),
                  Text('$totalPoints Puan', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: Color(0xFF4B360F))),
                ],
              ),
            ),
          ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: level.badgeBackground,
              borderRadius: BorderRadius.circular(999),
              border: Border.all(color: level.badgeBorder),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(badgeEmoji, style: const TextStyle(fontSize: 16)),
                const SizedBox(width: 6),
                Text(
                  badgeLabel,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: level.badgeForeground,
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
                child: Text(displayName.isEmpty ? 'K' : displayName[0].toUpperCase(), style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: Color(0xFF3D2A00))),
              )
            : CachedNetworkImage(
                imageUrl: avatarUrl,
                fit: BoxFit.cover,
                memCacheWidth: 220,
                memCacheHeight: 220,
                errorWidget: (_, __, ___) => Container(
                  color: const Color(0xFFFFE8B7),
                  alignment: Alignment.center,
                  child: Text(displayName.isEmpty ? 'K' : displayName[0].toUpperCase(), style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: Color(0xFF3D2A00))),
                ),
              ),
      ),
    );
  }
}

class _MetricChip extends StatelessWidget {
  const _MetricChip({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 11),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.76),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE7CF9B)),
      ),
      child: Column(
        children: [
          Text(value, style: const TextStyle(fontWeight: FontWeight.w800, color: Color(0xFF503300))),
          const SizedBox(height: 2),
          Text(label, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 11, color: Color(0xFF6D5733))),
        ],
      ),
    );
  }
}

class _TrustMiniCard extends StatelessWidget {
  const _TrustMiniCard({required this.score, required this.totalVotes});

  final double score;
  final int totalVotes;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.75),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE4D1AC)),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 46,
            height: 46,
            child: Stack(
              fit: StackFit.expand,
              children: [
                CircularProgressIndicator(
                  value: (score / 100).clamp(0, 1),
                  strokeWidth: 5,
                  backgroundColor: const Color(0xFFEADAC1),
                  valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFFB8863B)),
                ),
                Center(
                  child: Text('%${score.round()}', style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: Color(0xFF3F2C0A))),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('Güven Skoru', style: TextStyle(fontWeight: FontWeight.w700, color: Color(0xFF3D2D0E))),
                Text('Toplam oy: $totalVotes', style: const TextStyle(fontSize: 11, color: Color(0xFF6D5733), fontWeight: FontWeight.w600)),
              ],
            ),
          ),
          IconButton(
            onPressed: () {
              showModalBottomSheet<void>(
                context: context,
                showDragHandle: true,
                builder: (_) => const Padding(
                  padding: EdgeInsets.fromLTRB(16, 8, 16, 24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Güven nasıl hesaplanır?', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
                      SizedBox(height: 10),
                      Text('• Doğrulanan fiyat katkıları puanı yükseltir.'),
                      Text('• Hatalı fiyat geri bildirimleri puanı düşürür.'),
                      Text('• Son katkı performansı daha yüksek etkidedir.'),
                    ],
                  ),
                ),
              );
            },
            icon: const Icon(Icons.info_outline_rounded),
          ),
        ],
      ),
    );
  }
}

class _QuickBar extends StatelessWidget {
  const _QuickBar({required this.uid});

  final String uid;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        color: Theme.of(context).colorScheme.surface,
        border: Border.all(color: AppColors.outlineVariant.withOpacity(0.6)),
      ),
      child: Row(
        children: [
          _QuickItem(title: 'Fiyatlarım', icon: Icons.sell_rounded, onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => MyPricesScreen(userId: uid)))),
          _QuickItem(title: 'Fişlerim', icon: Icons.receipt_long_rounded, onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => ReceiptsScreen(userId: uid)))),
          _QuickItem(title: 'Favoriler', icon: Icons.favorite_rounded, onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => FavoritesScreen(userId: uid)))),
          _QuickItem(title: 'Bildirimler', icon: Icons.notifications_active_rounded, onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const NotificationsScreen()))),
        ],
      ),
    );
  }
}

class _QuickItem extends StatelessWidget {
  const _QuickItem({required this.title, required this.icon, required this.onTap});

  final String title;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Column(
            children: [
              Icon(icon, color: AppColors.primaryDark),
              const SizedBox(height: 4),
              Text(title, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600)),
            ],
          ),
        ),
      ),
    );
  }
}

class _MaterialCodePointIcon extends StatelessWidget {
  const _MaterialCodePointIcon({
    required this.codePoint,
    this.size,
    this.color,
  });

  final int codePoint;
  final double? size;
  final Color? color;

  static const _materialSymbolsFallback = [
    Icons.workspace_premium,
    Icons.military_tech,
    Icons.auto_awesome_rounded,
    Icons.lock_rounded,
  ];

  @override
  Widget build(BuildContext context) {
    final icon = _materialSymbolsFallback.firstWhere(
      (candidate) => candidate.codePoint == codePoint,
      orElse: () => Icons.workspace_premium,
    );

    return Icon(icon, size: size, color: color);
  }
}

class _SettingsList extends ConsumerWidget {
  const _SettingsList({required this.isAdmin, required this.onReload});

  final bool isAdmin;
  final VoidCallback onReload;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeProvider);
    return Column(
      children: [
        _MenuTile(
          icon: Icons.edit_rounded,
          title: 'Profili Düzenle',
          onTap: () async {
            await Navigator.push(context, MaterialPageRoute(builder: (_) => const EditProfileScreen()));
            onReload();
          },
        ),
        Container(
          margin: const EdgeInsets.only(bottom: 8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.outlineVariant.withOpacity(0.6)),
          ),
          child: SwitchListTile.adaptive(
            value: themeMode == ThemeMode.dark,
            onChanged: (_) => ref.read(themeModeProvider.notifier).toggleDarkMode(),
            title: const Text('Karanlık Mod'),
            secondary: const Icon(Icons.dark_mode_rounded),
          ),
        ),
        if (isAdmin)
          _MenuTile(
            icon: Icons.admin_panel_settings_rounded,
            title: 'Admin Paneli',
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AdminPanelScreen())),
          ),
        _MenuTile(
          icon: Icons.info_outline_rounded,
          title: 'Hakkında',
          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AboutScreen())),
        ),
        _MenuTile(
          icon: Icons.history_rounded,
          title: 'Güncelleme Geçmişi',
          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const UpdateHistoryScreen())),
        ),
        _MenuTile(
          icon: Icons.logout_rounded,
          title: 'Çıkış Yap',
          onTap: () async {
            await ref.read(authServiceProvider).signOut();
            if (!context.mounted) return;
            Navigator.of(context).pushAndRemoveUntil(MaterialPageRoute(builder: (_) => const LoginScreen()), (route) => false);
          },
        ),
      ],
    );
  }
}

class _MenuTile extends StatelessWidget {
  const _MenuTile({required this.icon, required this.title, required this.onTap});

  final IconData icon;
  final String title;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.outlineVariant.withOpacity(0.6)),
      ),
      child: ListTile(
        onTap: onTap,
        leading: Icon(icon),
        title: Text(title),
        trailing: const Icon(Icons.chevron_right_rounded),
      ),
    );
  }
}

class MyPricesScreen extends StatelessWidget {
  const MyPricesScreen({super.key, required this.userId});

  final String userId;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Fiyatlarım')),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: FirebaseFirestore.instance.collection('priceReports').where('createdByUid', isEqualTo: userId).snapshots(),
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
                subtitle: Text('${(data['storeName'] ?? 'Market').toString()} • $formattedDate'),
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
                  color: Theme.of(context).colorScheme.surfaceVariant,
                ),
                child: const Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.favorite_border, size: 42),
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
      appBar: AppBar(title: const Text('Fişlerim')),
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
                subtitle: Text((data['note'] ?? 'Fiş').toString()),
                trailing: Text(formatTRY((data['total'] ?? 0) as num)),
              );
            },
          );
        },
      ),
    );
  }
}

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Hakkında')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              gradient: const LinearGradient(
                colors: [Color(0xFFF2F7FF), Color(0xFFEAF2FF)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              border: Border.all(color: const Color(0xFFD6E4FA)),
            ),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('FiyatRadar', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: Color(0xFF1D3F6E))),
                SizedBox(height: 4),
                Text('Sürüm 1.5.0 • FiyatRadar Ekibi', style: TextStyle(color: Color(0xFF45628A), fontWeight: FontWeight.w600)),
              ],
            ),
          ),
          const SizedBox(height: 10),
          ListTile(
            title: const Text('Gizlilik Politikası'),
            trailing: const Icon(Icons.open_in_new_rounded),
            onTap: () => launchUrl(Uri.parse('https://fiyatradar.app/privacy')),
          ),
          ListTile(
            title: const Text('Kullanım Şartları'),
            trailing: const Icon(Icons.open_in_new_rounded),
            onTap: () => launchUrl(Uri.parse('https://fiyatradar.app/terms')),
          ),
          ListTile(
            title: const Text('Güncelleme Geçmişi'),
            trailing: const Icon(Icons.chevron_right_rounded),
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const UpdateHistoryScreen())),
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
          const Text('Profil verisi yüklenemedi.'),
          const SizedBox(height: 8),
          OutlinedButton(onPressed: onRetry, child: const Text('Tekrar dene')),
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
          const Text('Veriler alınamadı.'),
          const SizedBox(height: 8),
          OutlinedButton(onPressed: onRetry, child: const Text('Tekrar dene')),
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
    required this.levelName,
    required this.trustScore,
    required this.trustTotalVotes,
    required this.totalPoints,
  });

  final String displayName;
  final String photoUrl;
  final String username;
  final String levelName;
  final double trustScore;
  final int trustTotalVotes;
  final int totalPoints;
}
