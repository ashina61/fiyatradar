import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/auth_provider.dart';
import '../../utils/constants.dart';
import '../../utils/theme.dart';
import '../auth/login_screen.dart';

class PointsScreen extends ConsumerStatefulWidget {
  const PointsScreen({super.key});

  @override
  ConsumerState<PointsScreen> createState() => _PointsScreenState();
}

class _PointsScreenState extends ConsumerState<PointsScreen> {
  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _badgeSubscription;
  final List<DocumentSnapshot<Map<String, dynamic>>> _badgeQueue = [];
  bool _isShowingBadgeDialog = false;
  String? _lastBadgeEventId;

  @override
  void dispose() {
    _badgeSubscription?.cancel();
    super.dispose();
  }

  String _levelName(int points) {
    if (points >= 5000) return 'Elmas Üye';
    if (points >= 2000) return 'Platin Üye';
    if (points >= 500) return 'Altın Üye';
    if (points >= 100) return 'Gümüş Üye';
    return 'Bronz Üye';
  }

  int _levelStep(int points) {
    if (points >= 5000) return 10000;
    if (points >= 2000) return 5000;
    if (points >= 500) return 2000;
    if (points >= 100) return 500;
    return 100;
  }

  void _listenBadgeEvents(String uid) {
    _badgeSubscription?.cancel();
    _badgeSubscription = FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('badgeEvents')
        .where('seen', isEqualTo: false)
        .orderBy('createdAt')
        .limit(10)
        .snapshots()
        .listen((snapshot) {
      if (!mounted || snapshot.docs.isEmpty) return;
      for (final doc in snapshot.docs) {
        if (_badgeQueue.any((queued) => queued.id == doc.id)) continue;
        if (_lastBadgeEventId == doc.id) continue;
        _badgeQueue.add(doc);
      }
      _drainBadgeQueue();
    });
  }

  Future<void> _drainBadgeQueue() async {
    if (_isShowingBadgeDialog || _badgeQueue.isEmpty || !mounted) return;
    _isShowingBadgeDialog = true;
    final doc = _badgeQueue.removeAt(0);
    _lastBadgeEventId = doc.id;
    final data = doc.data() ?? <String, dynamic>{};

    await showDialog<void>(
      context: context,
      barrierDismissible: true,
      builder: (context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(24),
              gradient: const LinearGradient(
                colors: [Color(0xFFFFF3CD), Color(0xFFFFE08A)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              boxShadow: [
                BoxShadow(color: Colors.amber.withOpacity(0.3), blurRadius: 24, offset: const Offset(0, 10)),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('🎉 Yeni Rozet Kazandın!', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800)),
                const SizedBox(height: 12),
                const Icon(Icons.auto_awesome, size: 56, color: Colors.amber),
                const SizedBox(height: 10),
                Text((data['badgeName'] ?? 'Özel Rozet').toString(), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
                const SizedBox(height: 6),
                Text((data['description'] ?? 'Katkın için teşekkür ederiz.').toString(), textAlign: TextAlign.center),
                const SizedBox(height: 14),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Harika!')),
                ),
              ],
            ),
          ),
        );
      },
    );

    await doc.reference.update({'seen': true, 'seenAt': FieldValue.serverTimestamp()});
    _isShowingBadgeDialog = false;
    if (_badgeQueue.isNotEmpty) {
      unawaited(_drainBadgeQueue());
    }
  }

  @override
  Widget build(BuildContext context) {
    final userAsync = ref.watch(userModelStreamProvider);

    return userAsync.when(
      data: (user) {
        if (user == null) {
          return Scaffold(
            appBar: AppBar(title: const Text('Puanlar')),
            body: Center(
              child: FilledButton(
                onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const LoginScreen())),
                child: const Text('Giriş Yap'),
              ),
            ),
          );
        }

        _listenBadgeEvents(user.uid);

        final points = user.points;
        final levelName = _levelName(points);
        final nextStep = _levelStep(points);
        final remaining = (nextStep - points).clamp(0, nextStep);

        // Firestore docs: users/{uid}/points_log, users/{uid}/badges, users/{uid}/badgeEvents, points_rules.
        return Scaffold(
          appBar: AppBar(title: const Text('Puanlar')),
          body: ListView(
            padding: const EdgeInsets.all(AppSpacing.md),
            children: [
              Container(
                padding: const EdgeInsets.all(AppSpacing.lg),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(AppRadius.lg),
                  gradient: const LinearGradient(colors: [AppColors.accent, Color(0xFFFF8C00)]),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('$points Puan', style: const TextStyle(color: Colors.white, fontSize: 30, fontWeight: FontWeight.bold)),
                    Text('Seviye: $levelName', style: TextStyle(color: Colors.white.withOpacity(0.95))),
                    const SizedBox(height: 10),
                    LinearProgressIndicator(value: (points / nextStep).clamp(0, 1), minHeight: 8, borderRadius: BorderRadius.circular(999)),
                    const SizedBox(height: 6),
                    Text('Bir sonraki seviyeye $remaining puan kaldı', style: const TextStyle(color: Colors.white)),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              const Text('Puan Kazanma Yolları', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
              const SizedBox(height: 8),
              StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                stream: FirebaseFirestore.instance.collection('points_rules').where('isActive', isEqualTo: true).orderBy('order').snapshots(),
                builder: (context, snapshot) {
                  final docs = snapshot.data?.docs ?? const [];
                  if (docs.isEmpty) {
                    return const _PointRow(icon: Icons.add_shopping_cart, title: 'Fiyat Ekleme', points: '+5 Puan', description: 'Her fiyat girişinde puan', color: AppColors.primary);
                  }
                  return Column(
                    children: docs.map((doc) {
                      final d = doc.data();
                      return _PointRow(
                        icon: Icons.bolt,
                        title: (d['title'] ?? 'Katkı').toString(),
                        points: '+${d['points'] ?? AppConstants.pointsForPriceEntry} Puan',
                        description: (d['description'] ?? 'Topluluk katkısı').toString(),
                        color: AppColors.primary,
                      );
                    }).toList(),
                  );
                },
              ),
              const SizedBox(height: AppSpacing.lg),
              const Text('Rozet Sineması', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
              const SizedBox(height: 8),
              SizedBox(
                height: 130,
                child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                  stream: FirebaseFirestore.instance.collection('badges').limit(12).snapshots(),
                  builder: (context, allBadgesSnapshot) {
                    final badges = allBadgesSnapshot.data?.docs ?? const [];
                    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                      stream: FirebaseFirestore.instance.collection('users').doc(user.uid).collection('badges').snapshots(),
                      builder: (context, userBadgesSnapshot) {
                        final unlockedIds = userBadgesSnapshot.data?.docs.map((e) => e.id).toSet() ?? <String>{};
                        return ListView.separated(
                          scrollDirection: Axis.horizontal,
                          itemCount: badges.length,
                          separatorBuilder: (_, __) => const SizedBox(width: 8),
                          itemBuilder: (context, index) {
                            final badge = badges[index].data();
                            final unlocked = unlockedIds.contains(badges[index].id);
                            return Container(
                              width: 170,
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(16),
                                color: unlocked ? const Color(0xFFFFF3CD) : Theme.of(context).colorScheme.surfaceVariant,
                                border: Border.all(color: unlocked ? Colors.amber : AppColors.outlineVariant),
                              ),
                              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                Row(children: [Icon(unlocked ? Icons.workspace_premium : Icons.lock_outline), const Spacer(), if (unlocked) const Icon(Icons.auto_awesome, color: Colors.amber)]),
                                const SizedBox(height: 8),
                                Text((badge['name'] ?? 'Rozet').toString(), maxLines: 1, overflow: TextOverflow.ellipsis),
                                Text((badge['description'] ?? '').toString(), maxLines: 2, overflow: TextOverflow.ellipsis, style: Theme.of(context).textTheme.bodySmall),
                              ]),
                            );
                          },
                        );
                      },
                    );
                  },
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              const Text('Son Aktivite', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
              StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                stream: FirebaseFirestore.instance.collection('users').doc(user.uid).collection('points_log').orderBy('createdAt', descending: true).limit(10).snapshots(),
                builder: (context, snapshot) {
                  final docs = snapshot.data?.docs ?? const [];
                  if (docs.isEmpty) return const Padding(padding: EdgeInsets.only(top: 8), child: Text('Henüz aktivite yok.'));
                  return Column(children: docs.map((doc) {
                    final data = doc.data();
                    return ListTile(
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(Icons.history),
                      title: Text((data['type'] ?? 'Aktivite').toString()),
                      trailing: Text('+${data['points'] ?? 0}'),
                    );
                  }).toList());
                },
              ),
            ],
          ),
        );
      },
      loading: () => const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (_, __) => const Scaffold(body: Center(child: Text('Puan bilgisi yüklenemedi'))),
    );
  }
}

class _PointRow extends StatelessWidget {
  final IconData icon;
  final String title;
  final String points;
  final String description;
  final Color color;

  const _PointRow({required this.icon, required this.title, required this.points, required this.description, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(color: color.withOpacity(0.08), borderRadius: BorderRadius.circular(AppRadius.md)),
      child: Row(children: [
        Icon(icon, color: color),
        const SizedBox(width: AppSpacing.sm),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(title), Text(description, style: Theme.of(context).textTheme.bodySmall)])),
        Text(points, style: TextStyle(color: color, fontWeight: FontWeight.bold)),
      ]),
    );
  }
}
