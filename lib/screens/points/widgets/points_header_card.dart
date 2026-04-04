import 'package:flutter/material.dart';

import '../models/points_models.dart';

class PointsHeaderCard extends StatelessWidget {
  const PointsHeaderCard({super.key, required this.summary});

  final PointsSummary summary;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFFF9F43), Color(0xFFF28C3A)],
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x22000000),
            blurRadius: 14,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.24),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.star_rounded, color: Colors.white, size: 30),
            ),
          ),
          const SizedBox(height: 12),
          Center(
            child: Text(
              '${summary.totalPoints}',
              style: const TextStyle(fontSize: 42, color: Colors.white, fontWeight: FontWeight.w800),
            ),
          ),
          const SizedBox(height: 4),
          const Center(
            child: Text('Toplam Puan', style: TextStyle(fontSize: 13, color: Colors.white70, fontWeight: FontWeight.w600)),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: Text(
                  'Seviye ${summary.level} - ${summary.levelName}',
                  style: const TextStyle(fontSize: 12, color: Colors.white, fontWeight: FontWeight.w600),
                ),
              ),
              Text(
                '${summary.nextLevelRemaining} puan sonraki seviye',
                style: const TextStyle(fontSize: 11, color: Colors.white, fontWeight: FontWeight.w500),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: summary.progress,
              minHeight: 7,
              backgroundColor: Colors.white30,
              valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFFFFE7C4)),
            ),
          ),
        ],
      ),
    );
  }
}
