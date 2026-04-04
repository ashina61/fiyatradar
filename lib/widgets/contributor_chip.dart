import 'package:flutter/material.dart';

class ContributorChip extends StatelessWidget {
  const ContributorChip({
    super.key,
    required this.name,
    this.verified = false,
    required this.accentColor,
  });

  final String name;
  final bool verified;
  final Color accentColor;

  @override
  Widget build(BuildContext context) {
    final resolvedName = name.trim().isEmpty ? 'Katkici' : name.trim();

    return IntrinsicWidth(
      child: Container(
        constraints: const BoxConstraints(minHeight: 44, maxHeight: 44),
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.10),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: Colors.white.withOpacity(0.22)),
          boxShadow: const [
            BoxShadow(
              color: Color.fromRGBO(0, 0, 0, 0.22),
              blurRadius: 8,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.diamond_rounded, color: accentColor, size: 18),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                resolvedName,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                ),
              ),
            ),
            if (verified) ...[
              const SizedBox(width: 8),
              const Icon(Icons.verified_rounded, size: 16, color: Color(0xFF1DA1F2)),
            ],
          ],
        ),
      ),
    );
  }
}
