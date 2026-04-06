import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../providers/auth_provider.dart';
import '../../providers/product_provider.dart';
import '../../models/user_model.dart';
import '../../theme/fr_colors.dart';
import '../../utils/formatters.dart';
import '../../utils/constants.dart';
import '../../utils/elite_level_engine.dart';
import '../../utils/level_config.dart';
import '../../utils/theme.dart';
import '../auth/login_screen.dart';
import '../points/points_screen.dart';
import '../settings/settings_screen.dart';
import 'favorites_screen.dart';
import 'my_prices_screen.dart';
import 'price_alarms_screen.dart';
import 'update_history_screen.dart';

// ─── Constants ────────────────────────────────────────────────────────────────
const _kPad = 24.0;
const _kCardR = 20.0;
const _kShadow = BoxShadow(color: Color(0x0A211510), blurRadius: 12, offset: Offset(0, 3));

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  int _reloadKey = 0;

  @override
  Widget build(BuildContext context) {
    final userAsync = ref.watch(userModelStreamProvider);

    return userAsync.when(
      loading: () => const Scaffold(
        backgroundColor: FRColors.backgroundWarm,
        body: Center(child: CircularProgressIndicator()),
      ),
      error: (_, __) => Scaffold(
        backgroundColor: FRColors.backgroundWarm,
        body: _ErrorState(onRetry: () => setState(() => _reloadKey++)),
      ),
      data: (liveUser) {
        final uid = liveUser?.uid;
        if (uid == null) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            Navigator.of(context).pushAndRemoveUntil(
              MaterialPageRoute(builder: (_) => const LoginScreen()),
              (route) => false,
            );
          });
          return const Scaffold(
            backgroundColor: FRColors.backgroundWarm,
            body: Center(child: CircularProgressIndicator()),
          );
        }

        return Scaffold(
          backgroundColor: FRColors.backgroundWarm,
          body: FutureBuilder<_ProfileData>(
            key: ValueKey(_reloadKey),
            future: _loadProfile(liveUser!),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (snapshot.hasError || !snapshot.hasData) {
                return _ErrorState(onRetry: () => setState(() => _reloadKey++));
              }

              final data = snapshot.data!;
              return RefreshIndicator(
                color: FRColors.tan,
                backgroundColor: FRColors.surface,
                onRefresh: () async => setState(() => _reloadKey++),
                child: CustomScrollView(
                  physics: const AlwaysScrollableScrollPhysics(
                    parent: BouncingScrollPhysics(),
                  ),
                  slivers: [
                    // Identity header
                    SliverToBoxAdapter(
                      child: _IdentityHeader(
                        data: data,
                        onSettingsTap: () async {
                          await Navigator.of(context).push(
                            CupertinoPageRoute(
                              builder: (_) => SettingsScreen(isAdmin: data.isAdmin),
                            ),
                          );
                          if (mounted) setState(() => _reloadKey++);
                        },
                      ),
                    ),
                    // Impact trio
                    SliverToBoxAdapter(child: _ImpactTrio(data: data)),
                    // Quick action grid
                    SliverToBoxAdapter(child: _QuickActions(data: data, uid: uid)),
                    // Account section
                    SliverToBoxAdapter(child: _AccountSection(data: data, uid: uid)),
                    const SliverToBoxAdapter(child: SizedBox(height: 120)),
                  ],
                ),
              );
            },
          ),
        );
      },
    );
  }

  Future<_ProfileData> _loadProfile(UserModel userModel) async {
    final uid = userModel.uid;
    Map<String, dynamic> trustProfile = const <String, dynamic>{};
    try {
      trustProfile = await ref.read(firestoreServiceProvider).getUserTrustProfile(uid);
    } catch (_) {
      trustProfile = const <String, dynamic>{};
    }

    final totalPoints = userModel.totalPoints;
    final trustTotalVotes = (trustProfile['trustTotalVotes'] as num?)?.toInt() ?? userModel.trustTotalVotes;
    final trustPercent = (trustProfile['trustScorePercent'] as num?)?.toInt() ?? userModel.trustScorePercent;
    final finalLevel = EliteLevelEngine.getFinalLevel(totalPoints, trustPercent, trustTotalVotes);
    final finalLevelName = EliteLevelEngine.getLevelStyle(finalLevel).label;
    final userCity = (userModel.cityName ?? userModel.city ?? '').trim();
    final cityRank = await _resolveCityRank(uid: uid, cityName: userCity);

    final addedPricesCount = userModel.priceEntries;
    final pendingPricesCount = await _resolvePendingPrices(uid);
    final alertsCount = await _countUserSubcollection(uid, 'watchlist');
    final favoritesCount = await _countUserSubcollection(uid, 'favorites');

    return _ProfileData(
      displayName: _resolveDisplayName(userModel),
      username: userModel.username,
      photoUrl: userModel.photoUrl ?? '',
      roleTitle: (userModel.role ?? '').trim(),
      isVerified: false,
      isAdmin: userModel.isAdmin,
      totalPoints: totalPoints,
      cityRank: cityRank,
      pointsLevelName: finalLevelName,
      trustScore: trustPercent.toDouble(),
      trustTotalVotes: trustTotalVotes,
      addedPricesCount: addedPricesCount,
      pendingPricesCount: pendingPricesCount,
      alertsCount: alertsCount,
      favoritesCount: favoritesCount,
      nextLeagueRemaining: _nextLeagueRemaining(totalPoints),
    );
  }

  String _resolveDisplayName(UserModel userModel) {
    if (userModel.username.trim().isNotEmpty) return userModel.username.trim();
    if (userModel.name.trim().isNotEmpty) return userModel.name.trim();
    return userModel.emailPrefix;
  }

  Future<int?> _countUserSubcollection(String uid, String path) async {
    final ref = FirebaseFirestore.instance.collection('users').doc(uid).collection(path);
    try {
      final snap = await ref.count().get();
      return snap.count;
    } catch (_) {
      try {
        final snap = await ref.get();
        return snap.docs.length;
      } catch (_) {
        return null;
      }
    }
  }

  Future<int?> _resolvePendingPrices(String uid) async {
    try {
      final snap = await FirebaseFirestore.instance
          .collection('priceReports')
          .where('createdByUid', isEqualTo: uid)
          .where('status', isEqualTo: 'pending')
          .count()
          .get();
      return snap.count;
    } catch (_) {
      try {
        final snap = await FirebaseFirestore.instance
            .collection('priceReports')
            .where('createdByUid', isEqualTo: uid)
            .where('status', isEqualTo: 'pending')
            .get();
        return snap.docs.length;
      } catch (_) {
        return null;
      }
    }
  }

  int? _nextLeagueRemaining(int totalPoints) {
    final levels = LevelConfig.levels;
    for (final level in levels) {
      if (level.minPoints > totalPoints) {
        return level.minPoints - totalPoints;
      }
    }
    return null;
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

// ─── Identity header ──────────────────────────────────────────────────────────
class _IdentityHeader extends StatelessWidget {
  const _IdentityHeader({required this.data, required this.onSettingsTap});

  final _ProfileData data;
  final VoidCallback onSettingsTap;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      bottom: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(_kPad, 18, _kPad, 0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top row: title + settings
            Row(
              children: [
                const Text(
                  'Profil',
                  style: TextStyle(
                    fontFamily: 'Outfit',
                    fontSize: 28,
                    fontWeight: FontWeight.w900,
                    color: FRColors.espresso,
                    height: 1,
                  ),
                ),
                const Spacer(),
                GestureDetector(
                  onTap: onSettingsTap,
                  child: Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: FRColors.surface,
                      borderRadius: BorderRadius.circular(13),
                      border: Border.all(color: FRColors.border),
                      boxShadow: const [_kShadow],
                    ),
                    child: const Icon(CupertinoIcons.settings, size: 18, color: FRColors.textPrimary),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 22),
            // Identity card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(22),
              decoration: BoxDecoration(
                color: FRColors.surface,
                borderRadius: BorderRadius.circular(_kCardR),
                border: Border.all(color: FRColors.border),
                boxShadow: const [_kShadow],
              ),
              child: Row(
                children: [
                  // Avatar
                  _ProfileAvatar(url: data.photoUrl, name: data.displayName, size: 64),
                  const SizedBox(width: 16),
                  // Name + level
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                data.displayName,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontFamily: 'Outfit',
                                  fontSize: 18,
                                  fontWeight: FontWeight.w800,
                                  color: FRColors.espresso,
                                ),
                              ),
                            ),
                            if (data.isAdmin) ...[
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: FRColors.espresso,
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: const Text(
                                  'ADMIN',
                                  style: TextStyle(fontSize: 9, fontWeight: FontWeight.w900, color: FRColors.tan),
                                ),
                              ),
                            ],
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          data.pointsLevelName,
                          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: FRColors.textMuted),
                        ),
                        if (data.roleTitle.isNotEmpty) ...[
                          const SizedBox(height: 2),
                          Text(
                            data.roleTitle,
                            style: const TextStyle(fontSize: 11, color: FRColors.textSubtle),
                          ),
                        ],
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            Text(
                              formatCompactCount(data.totalPoints),
                              style: const TextStyle(
                                fontFamily: 'Outfit',
                                fontSize: 22,
                                fontWeight: FontWeight.w900,
                                color: FRColors.espresso,
                                height: 1,
                              ),
                            ),
                            const SizedBox(width: 4),
                            const Text(
                              'PT',
                              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: FRColors.tan),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Impact trio ──────────────────────────────────────────────────────────────
class _ImpactTrio extends StatelessWidget {
  const _ImpactTrio({required this.data});
  final _ProfileData data;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(_kPad, 20, _kPad, 0),
      child: Row(
        children: [
          _StatCell(
            value: data.addedPricesCount == null ? '—' : '${data.addedPricesCount}',
            label: 'Eklenen\nFiyat',
          ),
          _VertDivider(),
          _StatCell(
            value: data.trustScore > 0 ? '%${data.trustScore.round()}' : '—',
            label: 'Güven\nSkoru',
            accent: data.trustScore >= 80,
          ),
          _VertDivider(),
          _StatCell(
            value: data.cityRank == null ? '—' : '#${data.cityRank}',
            label: 'Şehir\nSırası',
          ),
        ],
      ),
    );
  }
}

class _StatCell extends StatelessWidget {
  const _StatCell({required this.value, required this.label, this.accent = false});
  final String value;
  final String label;
  final bool accent;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: FRColors.surface,
          borderRadius: BorderRadius.circular(_kCardR),
          border: Border.all(color: FRColors.border),
          boxShadow: const [_kShadow],
        ),
        child: Column(
          children: [
            Text(
              value,
              style: TextStyle(
                fontFamily: 'Outfit',
                fontSize: 22,
                fontWeight: FontWeight.w900,
                color: accent ? FRColors.success : FRColors.espresso,
                height: 1,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: FRColors.textMuted, height: 1.3),
            ),
          ],
        ),
      ),
    );
  }
}

class _VertDivider extends StatelessWidget {
  @override
  Widget build(BuildContext context) => const SizedBox(width: 8);
}

// ─── Quick actions ────────────────────────────────────────────────────────────
class _QuickActions extends StatelessWidget {
  const _QuickActions({required this.data, required this.uid});
  final _ProfileData data;
  final String uid;

  @override
  Widget build(BuildContext context) {
    final actions = [
      (Icons.notifications_active_rounded, 'Alarmlarım',
          data.alertsCount != null ? '${data.alertsCount}' : null,
          () => Navigator.push(context, MaterialPageRoute(builder: (_) => WatchlistScreen(userId: uid)))),
      (Icons.bookmark_rounded, 'Favorilerim',
          data.favoritesCount != null ? '${data.favoritesCount}' : null,
          () => Navigator.push(context, MaterialPageRoute(builder: (_) => FavoritesScreen(userId: uid)))),
      (Icons.fact_check_rounded, 'Fiyatlarım',
          data.addedPricesCount != null ? '${data.addedPricesCount}' : null,
          () => Navigator.push(context, MaterialPageRoute(builder: (_) => MyPricesScreen(userId: uid)))),
      (Icons.emoji_events_rounded, 'Liderlik', null,
          () => Navigator.push(context, MaterialPageRoute(builder: (_) => const PointsScreen()))),
    ];

    return Padding(
      padding: const EdgeInsets.fromLTRB(_kPad, 20, _kPad, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'HIZLI ERİŞİM',
            style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: FRColors.textMuted, letterSpacing: 1.4),
          ),
          const SizedBox(height: 12),
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
            childAspectRatio: 2.2,
            children: actions.map((a) => _ActionTile(
              icon: a.$1,
              label: a.$2,
              badge: a.$3,
              onTap: a.$4,
            )).toList(),
          ),
        ],
      ),
    );
  }
}

class _ActionTile extends StatelessWidget {
  const _ActionTile({required this.icon, required this.label, required this.onTap, this.badge});
  final IconData icon;
  final String label;
  final String? badge;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: FRColors.surface,
          borderRadius: BorderRadius.circular(_kCardR),
          border: Border.all(color: FRColors.border),
          boxShadow: const [_kShadow],
        ),
        child: Row(
          children: [
            Icon(icon, size: 22, color: FRColors.tan),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: FRColors.textPrimary),
              ),
            ),
            if (badge != null) ...[
              const SizedBox(width: 4),
              Text(badge!, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: FRColors.textMuted)),
            ],
          ],
        ),
      ),
    );
  }
}

// ─── Account section ──────────────────────────────────────────────────────────
class _AccountSection extends StatelessWidget {
  const _AccountSection({required this.data, required this.uid});
  final _ProfileData data;
  final String uid;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(_kPad, 24, _kPad, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'HESAP',
            style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: FRColors.textMuted, letterSpacing: 1.4),
          ),
          const SizedBox(height: 12),
          Container(
            decoration: BoxDecoration(
              color: FRColors.surface,
              borderRadius: BorderRadius.circular(_kCardR),
              border: Border.all(color: FRColors.border),
              boxShadow: const [_kShadow],
            ),
            child: Column(
              children: [
                _AccountRow(
                  icon: Icons.update_rounded,
                  label: 'Güncelleme Geçmişi',
                  onTap: () => Navigator.push(context,
                      MaterialPageRoute(builder: (_) => const UpdateHistoryScreen())),
                ),
                const Divider(height: 1, indent: 56, endIndent: 16, color: Color(0x07211510)),
                _AccountRow(
                  icon: Icons.help_outline_rounded,
                  label: 'Yardım ve SSS',
                  onTap: () => Navigator.push(context,
                      MaterialPageRoute(builder: (_) => const ProfileHelpScreen())),
                ),
                const Divider(height: 1, indent: 56, endIndent: 16, color: Color(0x07211510)),
                _AccountRow(
                  icon: Icons.logout_rounded,
                  label: 'Çıkış Yap',
                  danger: true,
                  onTap: () => Navigator.of(context).pushAndRemoveUntil(
                    MaterialPageRoute(builder: (_) => const LoginScreen()),
                    (route) => false,
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

class _AccountRow extends StatelessWidget {
  const _AccountRow({required this.icon, required this.label, required this.onTap, this.danger = false});
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool danger;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(_kCardR),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: danger ? FRColors.dangerSurface : FRColors.backgroundWarm,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, size: 17, color: danger ? FRColors.danger : FRColors.textMuted),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: danger ? FRColors.danger : FRColors.textPrimary,
                ),
              ),
            ),
            if (!danger) const Icon(Icons.chevron_right_rounded, size: 18, color: FRColors.textSubtle),
          ],
        ),
      ),
    );
  }
}

// ─── Profile avatar ───────────────────────────────────────────────────────────
class _ProfileAvatar extends StatelessWidget {
  const _ProfileAvatar({required this.url, required this.name, required this.size});
  final String url;
  final String name;
  final double size;

  @override
  Widget build(BuildContext context) {
    if (url.isNotEmpty) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(size / 3),
        child: CachedNetworkImage(
          imageUrl: url,
          width: size,
          height: size,
          fit: BoxFit.cover,
          errorWidget: (_, __, ___) => _fallback(),
        ),
      );
    }
    return _fallback();
  }

  Widget _fallback() => Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: FRColors.tan.withOpacity(0.18),
          borderRadius: BorderRadius.circular(size / 3),
          border: Border.all(color: FRColors.tan.withOpacity(0.3)),
        ),
        child: Center(
          child: Text(
            name.isNotEmpty ? name[0].toUpperCase() : 'U',
            style: TextStyle(fontSize: size * 0.38, fontWeight: FontWeight.w800, color: FRColors.tan),
          ),
        ),
      );
}


// ---------- Sub-Screens (unchanged logic, refreshed styling) ----------

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
    required this.roleTitle,
    required this.pointsLevelName,
    required this.isVerified,
    required this.isAdmin,
    required this.trustScore,
    required this.trustTotalVotes,
    required this.totalPoints,
    required this.cityRank,
    required this.addedPricesCount,
    required this.pendingPricesCount,
    required this.alertsCount,
    required this.favoritesCount,
    required this.nextLeagueRemaining,
  });

  final String displayName;
  final String photoUrl;
  final String username;
  final String roleTitle;
  final String pointsLevelName;
  final bool isVerified;
  final bool isAdmin;
  final double trustScore;
  final int trustTotalVotes;
  final int totalPoints;
  final int? cityRank;
  final int? addedPricesCount;
  final int? pendingPricesCount;
  final int? alertsCount;
  final int? favoritesCount;
  final int? nextLeagueRemaining;
}
