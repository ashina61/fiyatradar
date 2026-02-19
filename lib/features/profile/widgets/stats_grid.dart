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
      childAspectRatio: 1.25,
      children: [
        _StatGridCard(
          value: '${stats.katki}',
          label: 'Fiyat Katkısı',
          icon: Icons.sell_rounded,
          color: const Color(0xFF059669),
        ),
        _StatGridCard(
          value: '${stats.dogrulama}',
          label: 'Doğrulama',
          icon: Icons.task_alt_rounded,
          color: const Color(0xFF2563EB),
        ),
        _StatGridCard(
          value: '${stats.earnedBadgeCount}',
          label: 'Elite Rozet',
          icon: Icons.workspace_premium_rounded,
          color: const Color(0xFF7C3AED),
        ),
        _StatGridCard(
          value: '${stats.seriGun}',
          label: 'Seri Gün',
          icon: Icons.local_fire_department_rounded,
          color: const Color(0xFFEF4444),
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
    required this.color,
  });

  final String value;
  final String label;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: color.withOpacity(0.12),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: const TextStyle(
                    color: Color(0xFF0F172A),
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  label,
                  style: const TextStyle(
                    color: Color(0xFF64748B),
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
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
