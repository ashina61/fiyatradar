import 'package:flutter/material.dart';

import '../profile_screen.dart';

class LevelCard extends StatelessWidget {
  const LevelCard({super.key, required this.stats});

  final ProfileStats stats;

  @override
  Widget build(BuildContext context) {
    final progress = (stats.puan / stats.puanMax).clamp(0, 1).toDouble();

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF111827), Color(0xFF1F2937)],
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x2B0F172A),
            blurRadius: 24,
            offset: Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFFFACC15).withOpacity(0.18),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  'SEVİYE ${stats.seviye}',
                  style: const TextStyle(
                    color: Color(0xFFFDE68A),
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
              const Spacer(),
              const Icon(Icons.diamond_rounded, color: Color(0xFF93C5FD), size: 20),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            '${stats.puan}/${stats.puanMax} puan',
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Bir üst elite seviyeye ilerliyorsun',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: Color(0xFFCBD5E1),
            ),
          ),
          const SizedBox(height: 16),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 10,
              backgroundColor: const Color(0xFF334155),
              valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF22D3EE)),
            ),
          ),
        ],
      ),
    );
  }
}
