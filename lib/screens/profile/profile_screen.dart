import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../providers/auth_provider.dart';
import '../../providers/theme_provider.dart';
import '../../utils/theme.dart';
import '../admin/admin_panel_screen.dart';
import '../auth/login_screen.dart';
import '../notifications/notifications_screen.dart';
import 'edit_profile_screen.dart';

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
                      avatarUrl: data.photoUrl,
                      trustScore: data.trustScore,
                      levelName: data.levelName,
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
    );
  }

  Future<_ProfileData> _loadProfile(String uid) async {
    final userRef = FirebaseFirestore.instance.collection('users').doc(uid);
    final userDoc = await userRef.get();
    if (!userDoc.exists) {
      await userRef.set({
        'displayName': 'Kullanıcı',
        'photoUrl': '',
        'verified': false,
        'trustScore': 0,
        'levelName': 'Elmas seviyesi',
        'streakDays': 0,
        'monthlySavings': '₺0',
        'topMarket': 'Henüz yok',
        'createdAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    }

    final data = (await userRef.get()).data() ?? <String, dynamic>{};

    return _ProfileData(
      displayName: (data['displayName'] ?? data['name'] ?? 'Kullanıcı').toString(),
      photoUrl: (data['photoUrl'] ?? '').toString(),
      levelName: (data['levelName'] ?? 'Elmas seviyesi').toString(),
      trustScore: ((data['trustScore'] ?? 0) as num).toDouble().clamp(0, 100)
    );
  }
}

class _PremiumHeaderCard extends StatelessWidget {
  const _PremiumHeaderCard({
    required this.displayName,
    required this.avatarUrl,
    required this.trustScore,
    required this.levelName,
    required this.onEdit,
  });

  final String displayName;
  final String avatarUrl;
  final double trustScore;
  final String levelName;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        gradient: const LinearGradient(
          colors: [Color(0xFFF6E7C8), Color(0xFFE6BF6D)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(color: Colors.amber.withOpacity(0.2), blurRadius: 22, offset: const Offset(0, 12)),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 38,
                backgroundImage: avatarUrl.isNotEmpty ? NetworkImage(avatarUrl) : null,
                child: avatarUrl.isEmpty
                    ? Text(displayName.isEmpty ? 'K' : displayName[0].toUpperCase(), style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w700))
                    : null,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Row(
                  children: [
                    Flexible(
                      child: Text(
                        displayName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
                      ),
                    ),
                    const SizedBox(width: 4),
                    const Icon(Icons.verified_rounded, size: 18, color: Colors.blue),
                  ],
                ),
              ),
              IconButton.filled(
                onPressed: onEdit,
                icon: const Icon(Icons.edit_rounded),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Align(
            alignment: Alignment.centerLeft,
            child: Chip(
              label: Text(levelName),
              backgroundColor: Colors.white70,
              side: BorderSide.none,
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              _TrustRing(score: trustScore),
              const SizedBox(width: 12),
              const Expanded(
                child: Text('Güven skoru topluluk doğrulamalarına göre hesaplanır.'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _TrustRing extends StatelessWidget {
  const _TrustRing({required this.score});

  final double score;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 70,
      height: 70,
      child: Stack(
        alignment: Alignment.center,
        children: [
          CircularProgressIndicator(
            value: score / 100,
            strokeWidth: 6,
            backgroundColor: Colors.white60,
          ),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('%${score.round()}', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
              const Text('Güven', style: TextStyle(fontSize: 10)),
            ],
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
        stream: FirebaseFirestore.instance.collection('prices').where('userId', isEqualTo: userId).orderBy('createdAt', descending: true).snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return _ListError(onRetry: () => (context as Element).markNeedsBuild());
          }
          final docs = snapshot.data?.docs ?? const [];
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
              return ListTile(
                title: Text((data['productName'] ?? 'Ürün').toString()),
                subtitle: Text('${(data['storeName'] ?? 'Market').toString()} • ${date == null ? 'Tarih yok' : '${date.day}.${date.month}.${date.year}'}'),
                trailing: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text('₺${((data['price'] ?? 0) as num).toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.w700)),
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

class FavoritesScreen extends StatelessWidget {
  const FavoritesScreen({super.key, required this.userId});

  final String userId;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Favoriler')),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: FirebaseFirestore.instance.collection('users').doc(userId).collection('favorites').orderBy('createdAt', descending: true).snapshots(),
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
          return ListView.builder(
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final data = docs[index].data();
              return ListTile(
                leading: const Icon(Icons.favorite, color: Colors.red),
                title: Text((data['productName'] ?? 'Ürün').toString()),
                subtitle: Text((data['storeName'] ?? 'Market').toString()),
                onTap: () {
                  final productId = (data['productId'] ?? '').toString();
                  if (productId.isEmpty) return;
                  Navigator.of(context).push(MaterialPageRoute(builder: (_) => ProductDetailScreen(productId: productId)));
                },
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
                trailing: Text('₺${((data['total'] ?? 0) as num).toStringAsFixed(2)}'),
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
          const ListTile(title: Text('Uygulama sürümü'), subtitle: Text('1.0.0')),
          const ListTile(title: Text('Geliştirici'), subtitle: Text('FiyatRadar Ekibi')),
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
    required this.levelName,
    required this.trustScore,
  });

  final String displayName;
  final String photoUrl;
  final String levelName;
  final double trustScore;
}
