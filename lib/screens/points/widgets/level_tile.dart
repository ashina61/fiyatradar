import 'package:flutter/material.dart';

import '../models/points_models.dart';

class LevelTile extends StatelessWidget {
  const LevelTile({super.key, required this.level});

  final LevelItem level;

  @override
  Widget build(BuildContext context) {
    final isCurrent = level.status == LevelStatus.current;
    final isLocked = level.status == LevelStatus.locked;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: isLocked ? const Color(0xFFF9FAFB) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isCurrent ? const Color(0xFF8FD5A6) : const Color(0x11000000),
          width: isCurrent ? 1.4 : 1,
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        level.name,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: isLocked ? const Color(0xFF98A2AD) : const Color(0xFF21262D),
                        ),
                      ),
                    ),
                    if (isCurrent) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: const Color(0xFFEAF9EF),
                          borderRadius: BorderRadius.circular(999),
                          border: Border.all(color: const Color(0xFFC8EFD5)),
                        ),
                        child: const Text('Mevcut', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Color(0xFF2D9A51))),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  '${level.requiredPoints} puan',
                  style: TextStyle(fontSize: 12, color: isLocked ? const Color(0xFFAEB5BD) : const Color(0xFF6E7782)),
                ),
              ],
            ),
          ),
          _buildTrailing(level.status),
        ],
      ),
    );
  }

  Widget _buildTrailing(LevelStatus status) {
    switch (status) {
      case LevelStatus.achieved:
        return const Icon(Icons.check_circle_rounded, color: Color(0xFF3BA55D));
      case LevelStatus.current:
        return const Icon(Icons.check_circle_rounded, color: Color(0xFFF39A3C));
      case LevelStatus.locked:
        return const Icon(Icons.lock_rounded, color: Color(0xFFB2B9C2));
    }
  }
}
