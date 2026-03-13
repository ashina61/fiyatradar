import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import 'controllers/points_controller.dart';
import 'widgets/performance_leaderboard_tab.dart';
import 'widgets/performance_overview_tab.dart';
import 'widgets/points_palette.dart';

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
        backgroundColor: PointsPalette.bgApp,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          title: const Text(
            'Performans & Puanlar',
            style: TextStyle(
              fontWeight: FontWeight.w800,
              fontSize: 14,
              letterSpacing: 0.8,
            ),
          ),
        ),
        body: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 14),
              child: _SegmentedTabs(
                selectedTab: selectedTab,
                onChanged: (value) => ref.read(pointsTabProvider.notifier).state = value,
              ),
            ),
            Expanded(
              child: selectedTab == 0
                  ? pointsAsync.when(
                      data: (state) => PerformanceOverviewTab(state: state),
                      loading: () => const Center(child: CircularProgressIndicator()),
                      error: (_, __) => const Center(child: Text('Puan verisi yüklenemedi')),
                    )
                  : const PerformanceLeaderboardTab(),
            ),
          ],
        ),
      ),
    );
  }
}

class _SegmentedTabs extends StatelessWidget {
  const _SegmentedTabs({required this.selectedTab, required this.onChanged});

  final int selectedTab;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: PointsPalette.espresso.withOpacity(0.06),
        borderRadius: BorderRadius.circular(999),
      ),
      padding: const EdgeInsets.all(4),
      child: Row(
        children: [
          _tab('Genel Bakış', 0),
          _tab('Zirvedekiler', 1),
        ],
      ),
    );
  }

  Widget _tab(String text, int index) {
    final active = index == selectedTab;
    return Expanded(
      child: InkWell(
        borderRadius: BorderRadius.circular(999),
        onTap: () => onChanged(index),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOutCubic,
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: active ? PointsPalette.espresso : Colors.transparent,
            borderRadius: BorderRadius.circular(999),
            boxShadow: active
                ? const [
                    BoxShadow(
                      color: Color(0x4D1A120E),
                      blurRadius: 12,
                      offset: Offset(0, 4),
                    ),
                  ]
                : null,
          ),
          child: Text(
            text,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w800,
              color: active ? Colors.white : PointsPalette.textMuted,
            ),
          ),
        ),
      ),
    );
  }
}
