import 'package:flutter/material.dart';

class TrustScoreCard extends StatelessWidget {
  const TrustScoreCard({super.key, required this.score});

  final int score;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
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
        children: [
          Container(
            width: 86,
            height: 86,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: const Color(0xFF10B981), width: 4),
            ),
            alignment: Alignment.center,
            child: Text(
              '$score',
              style: const TextStyle(
                fontSize: 36 / 1.5,
                fontWeight: FontWeight.w800,
                color: Color(0xFF10B981),
              ),
            ),
          ),
          const SizedBox(height: 10),
          const Text(
            'Yüksek',
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w700,
              color: Color(0xFF10B981),
            ),
          ),
          const SizedBox(height: 2),
          const Text(
            'Güven Skoru',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              color: Color(0xFF9CA3AF),
            ),
          ),
        ],
      ),
    );
  }
}
