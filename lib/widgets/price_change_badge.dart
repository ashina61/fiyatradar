import 'package:flutter/material.dart';

import '../utils/theme.dart';

class PriceChangeBadge extends StatelessWidget {
  final double percent;

  const PriceChangeBadge({
    super.key,
    required this.percent,
  });

  @override
  Widget build(BuildContext context) {
    final isUp = percent > 0;
    final color = isUp ? AppColors.error : AppColors.success;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(0.9),
        borderRadius: BorderRadius.circular(AppRadius.xs),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isUp ? Icons.trending_up : Icons.trending_down,
            color: Colors.white,
            size: 12,
          ),
          const SizedBox(width: 3),
          Text(
            '${percent.abs().toStringAsFixed(1)}%',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 9,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
