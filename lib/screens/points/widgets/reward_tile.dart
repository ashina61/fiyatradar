import 'package:flutter/material.dart';

import '../models/points_models.dart';

class RewardTile extends StatelessWidget {
  const RewardTile({super.key, required this.reward, required this.onTap});

  final RewardItem reward;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Ink(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: const Color(0xFFF4F5F6),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFE8EAED)),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(reward.title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: Color(0xFF5B636D))),
                    const SizedBox(height: 2),
                    Text(reward.subtitle, style: const TextStyle(fontSize: 12, color: Color(0xFF9AA2AB))),
                  ],
                ),
              ),
              Row(
                children: [
                  const Icon(Icons.star_rounded, size: 16, color: Color(0xFFB6BDC5)),
                  const SizedBox(width: 4),
                  Text('${reward.cost}', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xFF8A929C))),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
