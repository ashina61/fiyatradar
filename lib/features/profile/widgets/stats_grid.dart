import 'package:flutter/material.dart';

import '../profile_screen.dart';

class StatsGrid extends StatelessWidget {
  const StatsGrid({super.key, required this.stats});

  final ProfileStats stats;

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      childAspectRatio: 1,
      children: [
        _StatGridCard(
          value: '${stats.katki}',
          label: 'Fiyat Bildirimi',
          icon: Icons.sell_rounded,
          iconColor: const Color(0xFF10B981),
          iconBackground: const Color(0xFFEAFBF5),
        ),
        _StatGridCard(
          value: '${stats.dogrulama}',
          label: 'Doğrulama',
          icon: Icons.done_all_rounded,
          iconColor: const Color(0xFF60A5FA),
          iconBackground: const Color(0xFFEFF6FF),
        ),
        _StatGridCard(
          value: '${stats.puan}',
          label: 'Toplam Puan',
          icon: Icons.star_rounded,
          iconColor: const Color(0xFFF59E0B),
          iconBackground: const Color(0xFFFFF7E8),
        ),
        _StatGridCard(
          value: '${stats.earnedBadgeCount}',
          label: 'Rozet',
          icon: Icons.workspace_premium_rounded,
          iconColor: const Color(0xFF6366F1),
          iconBackground: const Color(0xFFEEF0FF),
        ),
      ],
    );
  }
}

class _StatGridCard extends StatelessWidget {
  const _StatGridCard({
    required this.value,
    required this.label,
    required this.icon,
    required this.iconColor,
    required this.iconBackground,
  });

  final String value;
  final String label;
  final IconData icon;
  final Color iconColor;
  final Color iconBackground;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE5E7EB)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0D000000),
            offset: Offset(0, 4),
            blurRadius: 12,
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 68,
            height: 68,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: iconBackground,
            ),
            child: Icon(icon, color: iconColor, size: 34),
          ),
          const SizedBox(height: 14),
          Text(
            value,
            style: const TextStyle(
              color: Color(0xFF0F172A),
              fontSize: 30 / 1.5,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            label,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Color(0xFF9CA3AF),
              fontSize: 15,
            ),
          ),
        ],
      ),
    );
  }
}
