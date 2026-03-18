import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../providers/auth_provider.dart';
import '../../providers/product_provider.dart';
import '../../models/product_model.dart';
import '../../models/user_model.dart';
import '../../utils/formatters.dart';
import '../../utils/constants.dart';
import '../../utils/elite_level_engine.dart';
import '../../utils/level_config.dart';
import '../../utils/theme.dart';
import '../../services/firestore_service.dart';
import '../auth/login_screen.dart';
import '../points/points_screen.dart';
import '../product/product_detail_screen.dart';
import '../settings/settings_screen.dart';
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
      backgroundColor: const Color(0xFFF5F3F0),
      body: userAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, __) => _ErrorState(onRetry: () => setState(() => _reloadKey++)),
        data: (userModel) {
          return FutureBuilder<_ProfileData>(
            key: ValueKey(_reloadKey),
            future: _loadProfile(uid, userModel),
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
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _ProfilePremiumHeader(
                        data: data,
                        onSettingsTap: () async {
                          await Navigator.of(context).push(
                            CupertinoPageRoute(builder: (_) => SettingsScreen(isAdmin: data.isAdmin)),
                          );
                          if (mounted) setState(() => _reloadKey++);
                        },
                      ),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(24, 24, 24, 120),
                        child: _ProfileSections(
                          data: data,
                          uid: uid,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  Future<_ProfileData> _loadProfile(String uid, UserModel? userModel) async {
    final userRef = FirebaseFirestore.instance.collection('users').doc(uid);
    final data = (await userRef.get()).data() ?? <String, dynamic>{};
    Map<String, dynamic> trustProfile = const <String, dynamic>{};
    try {
      trustProfile = await ref.read(firestoreServiceProvider).getUserTrustProfile(uid);
    } catch (_) {
      trustProfile = const <String, dynamic>{};
    }
    final totalPoints =
        (data['totalPoints'] as num?)?.toInt() ??
        (data['pointsTotal'] as num?)?.toInt() ??
        (data['points'] as num?)?.toInt() ??
        userModel?.points ??
        0;
    final trustTotalVotes =
        (trustProfile['trustTotalVotes'] as num?)?.toInt() ?? userModel?.trustTotalVotes ?? 0;
    final trustPercent =
        (trustProfile['trustScorePercent'] as num?)?.toInt() ?? userModel?.trustScorePercent ?? 0;
    // Profildeki seviye etiketi puan ekranı ve ürün detayındakiyle birebir aynı
    // hesaplamayı kullanır: puan + güven bazlı final seviye.
    final finalLevel = EliteLevelEngine.getFinalLevel(totalPoints, trustPercent, trustTotalVotes);
    final finalLevelName = EliteLevelEngine.getLevelStyle(finalLevel).label;
    final userCity = (data['cityName'] ?? data['city'] ?? '').toString().trim();
    final cityRank = await _resolveCityRank(uid: uid, cityName: userCity);

    final addedPricesCount =
        (data['priceEntries'] as num?)?.toInt() ?? userModel?.priceEntries;
    final pendingPricesCount = await _resolvePendingPrices(uid);
    final alertsCount = await _countCollection(userRef.collection('watchlist'));
    final favoritesCount = await _countCollection(userRef.collection('favorites'));

    return _ProfileData(
      displayName: (data['username'] ?? data['displayName'] ?? data['name'] ?? userModel?.username ?? 'Kullanıcı').toString(),
      username: (data['username'] ?? data['userName'] ?? userModel?.username ?? '').toString(),
      photoUrl: (data['photoURL'] ?? data['photoUrl'] ?? userModel?.photoUrl ?? '').toString(),
      roleTitle: (data['role'] ?? userModel?.role ?? '').toString().trim(),
      isVerified: (data['verifiedBadge'] as bool?) ?? (data['verified'] as bool?) ?? false,
      isAdmin: (data['isAdmin'] as bool?) ?? userModel?.isAdmin == true,
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

  Future<int?> _countCollection(CollectionReference<Map<String, dynamic>> ref) async {
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


class _ProfilePremiumHeader extends StatelessWidget {
  const _ProfilePremiumHeader({required this.data, required this.onSettingsTap});

  final _ProfileData data;
  final VoidCallback onSettingsTap;

  @override
  Widget build(BuildContext context) {
    final role = data.roleTitle.trim();

    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFF211510),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(32),
          bottomRight: Radius.circular(32),
        ),
        boxShadow: [
          BoxShadow(
            color: Color.fromRGBO(33, 21, 16, 0.35),
            blurRadius: 30,
            offset: Offset(0, 16),
          ),
        ],
      ),
      padding: const EdgeInsets.fromLTRB(24, 56, 24, 28),
      child: Column(
        children: [
          Row(
            children: [
              const Text(
                'Profil',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -0.4,
                ),
              ),
              const Spacer(),
              Material(
                color: const Color.fromRGBO(255, 255, 255, 0.08),
                borderRadius: BorderRadius.circular(12),
                child: InkWell(
                  borderRadius: BorderRadius.circular(12),
                  onTap: onSettingsTap,
                  child: const SizedBox(
                    width: 40,
                    height: 40,
                    child: Icon(CupertinoIcons.settings, color: Color(0xFFC29B78), size: 19),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Stack(
            clipBehavior: Clip.none,
            alignment: Alignment.bottomCenter,
            children: [
              Container(
                width: 118,
                height: 118,
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: const Color(0xFF2D1E17),
                  borderRadius: BorderRadius.circular(30),
                  border: Border.all(color: const Color(0xFFC29B78), width: 2.5),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(24),
                  child: _Avatar(
                    avatarUrl: data.photoUrl,
                    displayName: data.displayName,
                    size: 110,
                  ),
                ),
              ),
              if (data.isAdmin)
                Positioned(
                  bottom: -10,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFFC29B78),
                      borderRadius: BorderRadius.circular(999),
                      border: Border.all(color: const Color(0xFF211510), width: 2),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.local_police_rounded, size: 12, color: Color(0xFF211510)),
                        SizedBox(width: 4),
                        Text(
                          'ADMIN',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w900,
                            color: Color(0xFF211510),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 18),
          Text(
            data.displayName,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w900,
              color: Colors.white,
              letterSpacing: -0.4,
            ),
          ),
          if (role.isNotEmpty)
            Text(
              role,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: Color.fromRGBO(255, 255, 255, 0.62),
                letterSpacing: 0.5,
              ),
            ),
        ],
      ),
    );
  }
}

class _ProfileSections extends StatelessWidget {
  const _ProfileSections({
    required this.data,
    required this.uid,
  });

  final _ProfileData data;
  final String uid;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _ImpactCard(data: data),
        const SizedBox(height: 24),
        _MenuGroup(
          title: 'KOLEKSİYONLAR',
          items: [
            _MenuGroupItem(
              icon: Icons.notifications_active_rounded,
              title: 'Fiyat Alarmlarım',
              badge: data.alertsCount == null ? null : '${data.alertsCount} Aktif',
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => WatchlistScreen(userId: uid)),
              ),
            ),
            _MenuGroupItem(
              icon: Icons.bookmark_rounded,
              title: 'Koleksiyonlarım (Favoriler)',
              badge: data.favoritesCount == null ? null : '${data.favoritesCount}',
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => FavoritesScreen(userId: uid)),
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),
        _MenuGroup(
          title: 'LİDERLİK & AV',
          items: [
            _MenuGroupItem(
              icon: Icons.fact_check_rounded,
              title: 'Eklenen Fiyatlar',
              subtitle: data.pendingPricesCount == null
                  ? null
                  : (data.pendingPricesCount! > 0
                      ? 'Son eklenen ${data.pendingPricesCount} fiyat bekliyor'
                      : 'Bekleyen fiyatın bulunmuyor'),
              trailingLabel: data.addedPricesCount == null ? null : '${data.addedPricesCount}',
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => MyPricesScreen(userId: uid)),
              ),
            ),
            _MenuGroupItem(
              icon: Icons.emoji_events_rounded,
              title: 'Liderlik Tablosu & Ligler',
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const PointsScreen()),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _ImpactCard extends StatelessWidget {
  const _ImpactCard({required this.data});

  final _ProfileData data;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(22, 20, 22, 16),
      decoration: BoxDecoration(
        color: const Color(0xFF211510),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color.fromRGBO(194, 155, 120, 0.24)),
        boxShadow: const [
          BoxShadow(
            color: Color.fromRGBO(33, 21, 16, 0.22),
            blurRadius: 28,
            offset: Offset(0, 14),
          ),
        ],
      ),
      child: Column(
        children: [
          const Row(
            children: [
              Expanded(
                child: Text(
                  'TOPLAM RADAR PUANI',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1,
                    color: Color.fromRGBO(255, 255, 255, 0.55),
                  ),
                ),
              ),
              Icon(Icons.stars_rounded, color: Color(0xFFC29B78)),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                formatCompactCount(data.totalPoints),
                style: const TextStyle(
                  fontSize: 36,
                  height: 1,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -1,
                  color: Colors.white,
                ),
              ),
              const SizedBox(width: 8),
              const Padding(
                padding: EdgeInsets.only(bottom: 4),
                child: Text(
                  'PT',
                  style: TextStyle(
                    color: Color(0xFFC29B78),
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          if (data.nextLeagueRemaining != null) ...[
            const SizedBox(height: 6),
            Text(
              'Bir sonraki lig için ${formatCompactCount(data.nextLeagueRemaining!)} PT kaldı',
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w500,
                color: Color.fromRGBO(255, 255, 255, 0.6),
              ),
            ),
          ],
          if (data.addedPricesCount != null || data.trustTotalVotes > 0) ...[
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: const Color.fromRGBO(255, 255, 255, 0.06),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Row(
                children: [
                  if (data.addedPricesCount != null)
                    _ImpactStat(value: '${data.addedPricesCount}', label: 'Onaylı Fiyat'),
                  if (data.addedPricesCount != null && data.trustTotalVotes > 0)
                    const SizedBox(
                      height: 24,
                      child: VerticalDivider(color: Color.fromRGBO(255, 255, 255, 0.14), width: 22),
                    ),
                  if (data.trustTotalVotes > 0)
                    _ImpactStat(
                      value: '%${data.trustScore.round()}',
                      label: 'Doğruluk Skoru',
                      success: true,
                    ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _ImpactStat extends StatelessWidget {
  const _ImpactStat({required this.value, required this.label, this.success = false});

  final String value;
  final String label;
  final bool success;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w900,
              color: success ? const Color(0xFF4CAF50) : Colors.white,
            ),
          ),
          Text(
            label,
            style: const TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: Color.fromRGBO(255, 255, 255, 0.55),
            ),
          ),
        ],
      ),
    );
  }
}

class _MenuGroup extends StatelessWidget {
  const _MenuGroup({required this.title, required this.items});

  final String title;
  final List<_MenuGroupItem> items;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 8, bottom: 10),
          child: Text(
            title,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w800,
              color: Color(0xFF948A82),
              letterSpacing: 1,
            ),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color.fromRGBO(33, 21, 16, 0.05)),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          child: Column(
            children: [
              for (var i = 0; i < items.length; i++) ...[
                items[i],
                if (i != items.length - 1)
                  const Divider(height: 1, color: Color.fromRGBO(33, 21, 16, 0.05)),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _MenuGroupItem extends StatelessWidget {
  const _MenuGroupItem({
    required this.icon,
    required this.title,
    required this.onTap,
    this.badge,
    this.subtitle,
    this.trailingLabel,
    this.emphasize = false,
  });

  final IconData icon;
  final String title;
  final String? badge;
  final String? subtitle;
  final String? trailingLabel;
  final bool emphasize;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 14),
        child: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: emphasize ? const Color(0xFF211510) : const Color(0xFFEBE5DF),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, size: 20, color: emphasize ? const Color(0xFFC29B78) : const Color(0xFF948A82)),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: emphasize ? FontWeight.w800 : FontWeight.w700,
                      color: const Color(0xFF211510),
                    ),
                  ),
                  if (subtitle != null)
                    Text(
                      subtitle!,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 11,
                        color: Color(0xFF948A82),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  if (badge != null)
                    Container(
                      margin: const EdgeInsets.only(top: 2),
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFF3E0),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        badge!,
                        style: const TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFFE65100),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            if (trailingLabel != null)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                decoration: BoxDecoration(
                  color: emphasize ? const Color(0xFF211510) : const Color(0xFFF3EEEA),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  trailingLabel!,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    color: emphasize ? const Color(0xFFC29B78) : const Color(0xFF6E6158),
                  ),
                ),
              )
            else
              const Icon(Icons.chevron_right_rounded, color: Color(0xFFC2BBB5)),
          ],
        ),
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
    return SizedBox(
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
    );
  }
}

// ---------- Sub-Screens (unchanged logic, refreshed styling) ----------

class WatchlistScreen extends StatelessWidget {
  const WatchlistScreen({super.key, required this.userId});

  final String userId;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Fiyat Alarmlarım')),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: FirebaseFirestore.instance
            .collection('users')
            .doc(userId)
            .collection('watchlist')
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
            return const Center(child: Text('Aktif fiyat alarmın bulunmuyor.'));
          }

          return ListView.separated(
            itemCount: docs.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final data = docs[index].data();
              final productName = (data['productName'] ?? '').toString().trim();
              final title = productName.isEmpty ? 'Ürün' : productName;
              final targetPrice = (data['targetPrice'] as num?)?.toDouble();

              return ListTile(
                leading: const Icon(Icons.notifications_active_rounded),
                title: Text(title),
                subtitle: targetPrice == null ? null : Text('Hedef fiyat: ${formatTRY(targetPrice)}'),
                trailing: IconButton(
                  icon: const Icon(Icons.delete_outline_rounded),
                  onPressed: () async {
                    await docs[index].reference.delete();
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
