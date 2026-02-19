import 'package:flutter/material.dart';

class CtaBanner extends StatelessWidget {
  const CtaBanner({super.key, required this.points});

  final int points;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: const LinearGradient(
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
          colors: [Color(0xFFF59E0B), Color(0xFFEA8B00)],
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x33111827),
            offset: Offset(0, 10),
            blurRadius: 20,
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: const BoxDecoration(color: Color(0x33FFFFFF), shape: BoxShape.circle),
            child: const Icon(Icons.star_rounded, color: Colors.white, size: 38),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$points Puan',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 40 / 1.5,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 2),
                const Text(
                  'Görevler, ödüller ve seviyeler',
                  style: TextStyle(
                    color: Color(0xFFFDF5E8),
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          const Icon(Icons.chevron_right_rounded, color: Colors.white, size: 34),
        ],
      ),
    );
  }
}
