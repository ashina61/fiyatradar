import 'package:flutter/material.dart';

import '../profile_screen.dart';

class BadgesList extends StatelessWidget {
  const BadgesList({super.key, required this.badges});

  final List<BadgeItem> badges;

  @override
  Widget build(BuildContext context) {
    final earnedCount = badges.where((item) => item.earned).length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Expanded(
              child: Text(
                'Rozet Koleksiyonu',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF0F172A),
                ),
              ),
            ),
            Text(
              '$earnedCount/${badges.length}',
              style: const TextStyle(
                fontSize: 15,
                color: Color(0xFF475569),
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        for (final badge in badges) ...[
          _BadgeTile(badge: badge),
          const SizedBox(height: 10),
        ],
      ],
    );
  }
}

class _BadgeTile extends StatelessWidget {
  const _BadgeTile({required this.badge});

  final BadgeItem badge;

  @override
  Widget build(BuildContext context) {
    final titleColor = badge.earned ? const Color(0xFF0F172A) : const Color(0xFF64748B);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: badge.earned ? const Color(0xFFCFFAFE) : const Color(0xFFE2E8F0),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: badge.iconBackground,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(badge.icon, color: badge.iconColor, size: 24),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        badge.title,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: titleColor,
                        ),
                      ),
                    ),
                    Icon(
                      badge.earned ? Icons.check_circle : Icons.lock_outline_rounded,
                      color: badge.earned ? const Color(0xFF06B6D4) : const Color(0xFF94A3B8),
                      size: 20,
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  badge.description,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF64748B),
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(999),
                  child: LinearProgressIndicator(
                    value: badge.progress.clamp(0, 1),
                    minHeight: 6,
                    backgroundColor: const Color(0xFFE2E8F0),
                    valueColor: AlwaysStoppedAnimation<Color>(
                      badge.earned ? const Color(0xFF06B6D4) : const Color(0xFF94A3B8),
                    ),
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
