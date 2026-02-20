import 'package:flutter/material.dart';

class AddPriceHeaderBanner extends StatelessWidget {
  const AddPriceHeaderBanner({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFF5EDE4),
        borderRadius: BorderRadius.circular(14),
      ),
      child: const Row(
        children: [
          Icon(Icons.workspace_premium_rounded, color: Color(0xFFC8956C), size: 20),
          SizedBox(width: 10),
          Expanded(
            child: Text(
              'Katkınla tasarrufa yön ver...',
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 15,
                color: Color(0xFF5D4037),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
