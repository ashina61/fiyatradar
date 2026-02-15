import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/auth_provider.dart';
import '../../utils/constants.dart';
import '../../utils/theme.dart';
import '../auth/login_screen.dart';

class PointsScreen extends ConsumerWidget {
  const PointsScreen({super.key});

  String _levelName(int points) {
    if (points >= 5000) {
      return 'Elmas Uye';
    } else if (points >= 2000) {
      return 'Platin Uye';
    } else if (points >= 500) {
      return 'Altin Uye';
    } else if (points >= 100) {
      return 'Gumus Uye';
    }
    return 'Bronz Uye';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userAsync = ref.watch(userModelStreamProvider);

    return userAsync.when(
      data: (user) {
        if (user == null) {
          return Scaffold(
            appBar: AppBar(title: const Text('Puanlar')),
            body: Center(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.lock_outline, size: 48, color: AppColors.textSecondary),
                    const SizedBox(height: AppSpacing.sm),
                    const Text('Puanlar icin giris yapmalisiniz.'),
                    const SizedBox(height: AppSpacing.sm),
                    ElevatedButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const LoginScreen()),
                        );
                      },
                      child: const Text('Giris Yap'),
                    ),
                  ],
                ),
              ),
            ),
          );
        }

        final points = user.points;
        final levelName = _levelName(points);

        return Scaffold(
          appBar: AppBar(title: const Text('Puanlar')),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [AppColors.accent, Color(0xFFFF8C00)],
                    ),
                    borderRadius: BorderRadius.circular(AppRadius.lg),
                  ),
                  child: Column(
                    children: [
                      const Icon(Icons.stars, color: Colors.white, size: 48),
                      const SizedBox(height: AppSpacing.sm),
                      Text(
                        '$points Puan',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Seviye: $levelName',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.9),
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                LinearProgressIndicator(
                  value: ((points % 500) / 500).clamp(0, 1),
                  minHeight: 8,
                  borderRadius: BorderRadius.circular(999),
                ),
                const SizedBox(height: 8),
                Text('Bir sonraki seviyeye ${500 - (points % 500)} puan kaldı'),
                const SizedBox(height: AppSpacing.lg),
                const Text(
                  'Son Puan Hareketleri',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                  stream: FirebaseFirestore.instance.collection('users').doc(user.uid).collection('points_log').orderBy('createdAt', descending: true).limit(10).snapshots(),
                  builder: (context, snapshot) {
                    final docs = snapshot.data?.docs ?? const [];
                    if (docs.isEmpty) return const Text('Henüz puan hareketi yok.');
                    return Column(
                      children: docs.map((doc) {
                        final data = doc.data();
                        return ListTile(
                          dense: true,
                          contentPadding: EdgeInsets.zero,
                          leading: const Icon(Icons.bolt, size: 18),
                          title: Text((data['type'] ?? 'puan').toString()),
                          trailing: Text('+${data['points'] ?? 0}'),
                        );
                      }).toList(),
                    );
                  },
                ),
                const SizedBox(height: AppSpacing.lg),
                const Text(
                  'Puan Kazanma Yollari',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: AppSpacing.md),
                _PointRow(
                  icon: Icons.add_shopping_cart,
                  title: 'Fiyat Ekleme',
                  points: '+${AppConstants.pointsForPriceEntry} Puan',
                  description: 'Her yeni fiyat girisi icin',
                  color: AppColors.primary,
                ),
                _PointRow(
                  icon: Icons.camera_alt,
                  title: 'Fotografli Fiyat',
                  points: '+${AppConstants.pointsForPriceEntryWithPhoto} Puan',
                  description: 'Fotograf ile fiyat ekleme',
                  color: AppColors.secondary,
                ),
                _PointRow(
                  icon: Icons.verified,
                  title: 'Fiyat Dogrulama',
                  points: '+${AppConstants.pointsForValidation} Puan',
                  description: 'Baskalarinin fiyatlarini dogrulama',
                  color: AppColors.success,
                ),
                _PointRow(
                  icon: Icons.comment,
                  title: 'Yorum Yazma',
                  points: '+${AppConstants.pointsForComment} Puan',
                  description: 'Urun hakkinda yorum birakma',
                  color: AppColors.info,
                ),
                _PointRow(
                  icon: Icons.report,
                  title: 'Yanlis Fiyat Bildirme',
                  points: '+${AppConstants.pointsForReportPrice} Puan',
                  description: 'Yanlis fiyatlari raporlama',
                  color: AppColors.error,
                ),
                _PointRow(
                  icon: Icons.person_add,
                  title: 'Arkadas Davet Etme',
                  points: '+${AppConstants.pointsForInvite} Puan',
                  description: 'Davet kodu ile yeni uye',
                  color: AppColors.accent,
                ),
              ],
            ),
          ),
        );
      },
      loading: () => const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (_, __) => const Scaffold(body: Center(child: Text('Puan bilgisi yuklenemedi'))),
    );
  }
}

class _PointRow extends StatelessWidget {
  final IconData icon;
  final String title;
  final String points;
  final String description;
  final Color color;

  const _PointRow({
    required this.icon,
    required this.title,
    required this.points,
    required this.description,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: color.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                Text(
                  description,
                  style: TextStyle(color: Theme.of(context).hintColor, fontSize: 12),
                ),
              ],
            ),
          ),
          Text(
            points,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
