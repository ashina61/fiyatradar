import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import 'controllers/points_controller.dart';
import 'models/points_models.dart';
import 'widgets/porsche_points_widgets.dart';
import 'widgets/radar_kingdom_leaderboard_view.dart';

final pointsTabProvider = StateProvider<int>((ref) => 0);

class PointsScreen extends ConsumerWidget {
  const PointsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pointsAsync = ref.watch(pointsStateProvider);
    final selectedTab = ref.watch(pointsTabProvider);

    return Theme(
      data: Theme.of(context).copyWith(
        textTheme: GoogleFonts.plusJakartaSansTextTheme(Theme.of(context).textTheme),
      ),
      child: Scaffold(
        backgroundColor: AppColors.bgApp,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          title: const Text('Performans & Puanlar', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14, letterSpacing: 0.8)),
        ),
        body: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 10),
              child: SegmentedTabs(
                selectedTab: selectedTab,
                onChanged: (value) => ref.read(pointsTabProvider.notifier).state = value,
              ),
            ),
            Expanded(
              child: selectedTab == 0
                  ? pointsAsync.when(
                      data: (state) => _OverviewTab(state: state),
                      loading: () => const Center(child: CircularProgressIndicator()),
                      error: (_, __) => const Center(child: Text('Puan verisi yüklenemedi')),
                    )
                  : const RadarKingdomLeaderboardView(),
            ),
          ],
        ),
      ),
    );
  }
}

class _OverviewTab extends StatelessWidget {
  const _OverviewTab({required this.state});

  final PointsState state;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 30),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          BentoGridCard(state: state),
          const SizedBox(height: 12),
          RankPodium(state: state),
          const SizedBox(height: 18),
          const Text('Ayrıcalıkların', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, letterSpacing: -0.5)),
          const SizedBox(height: 12),
          SizedBox(
            height: 132,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: const [
                PrivilegeCard(title: 'Temel Fiyat Bildirimi', unlocked: true, icon: Icons.sell_rounded),
                SizedBox(width: 10),
                PrivilegeCard(title: 'Özel Market Alarmları', unlocked: true, icon: Icons.notifications_active_rounded),
                SizedBox(width: 10),
                PrivilegeCard(title: 'Geçmiş Fiyat Analizi', unlocked: false, icon: Icons.history_rounded),
              ],
            ),
          ),
          const SizedBox(height: 18),
          const Text('Puan Kazan', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, letterSpacing: -0.5)),
          const SizedBox(height: 12),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: state.dailyGoals.length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              mainAxisSpacing: 10,
              crossAxisSpacing: 10,
              childAspectRatio: 1.45,
            ),
            itemBuilder: (context, index) => MissionBox(goal: state.dailyGoals[index]),
          ),
        ],
      ),
    );
  }
}
