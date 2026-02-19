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
                'Rozetler',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF111827),
                ),
              ),
            ),
            Text(
              '$earnedCount/${badges.length}',
              style: const TextStyle(
                fontSize: 18,
                color: Color(0xFF9CA3AF),
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        for (final badge in badges) ...[
          _BadgeTile(badge: badge),
          const SizedBox(height: 12),
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
    final textColor = badge.earned ? const Color(0xFF111827) : const Color(0xFFC4C8CF);
    final subtitleColor = badge.earned ? const Color(0xFF9CA3AF) : const Color(0xFFD1D5DB);

    return Opacity(
      opacity: badge.earned ? 1 : 0.75,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
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
        child: Row(
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(color: badge.iconBackground, shape: BoxShape.circle),
              child: Icon(badge.icon, color: badge.iconColor, size: 30),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    badge.title,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: textColor,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    badge.description,
                    style: TextStyle(
                      fontSize: 15,
                      color: subtitleColor,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Icon(
              badge.earned ? Icons.check_circle : Icons.lock,
              color: badge.earned ? const Color(0xFF10B981) : const Color(0xFFD1D5DB),
              size: 30,
            ),
          ],
        ),
      ),
    );
  }
}
