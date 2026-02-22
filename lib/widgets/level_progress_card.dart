import 'package:flutter/material.dart';

class UserLevelBadge extends StatelessWidget {
  const UserLevelBadge({super.key, required this.levelName});

  final String levelName;

  Color _levelColor() {
    switch (levelName) {
      case 'Gözlemci':
        return const Color(0xFFD4C4B7);
      case 'Avcı':
        return const Color(0xFFFF9800);
      case 'Tasarrufçu':
        return const Color(0xFF90CAF9);
      case 'Market Ustası':
        return const Color(0xFFFFEB3B);
      case 'Fiyat Lordu':
        return const Color(0xFFE040FB);
      case 'Radar Efsanesi':
        return const Color(0xFF00E5FF);
      default:
        return const Color(0xFFD4C4B7);
    }
  }

  IconData _levelIcon() {
    switch (levelName) {
      case 'Gözlemci':
        return Icons.visibility;
      case 'Avcı':
        return Icons.my_location;
      case 'Tasarrufçu':
        return Icons.savings;
      case 'Market Ustası':
        return Icons.storefront;
      case 'Fiyat Lordu':
        return Icons.military_tech;
      case 'Radar Efsanesi':
        return Icons.diamond;
      default:
        return Icons.visibility;
    }
  }

  @override
  Widget build(BuildContext context) {
    final glowColor = _levelColor();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: ShapeDecoration(
        shape: StadiumBorder(
          side: BorderSide(color: glowColor.withOpacity(0.9), width: 1.2),
        ),
        color: Colors.transparent,
        shadows: [
          BoxShadow(
            color: glowColor.withOpacity(0.25),
            blurRadius: 12,
            spreadRadius: 0.2,
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(_levelIcon(), size: 16, color: glowColor),
          const SizedBox(width: 7),
          Text(
            levelName,
            style: TextStyle(
              color: glowColor,
              fontWeight: FontWeight.w700,
              fontSize: 13,
              letterSpacing: 0.15,
            ),
          ),
        ],
      ),
    );
  }
}

class LevelProgressCard extends StatelessWidget {
  const LevelProgressCard({
    super.key,
    required this.currentLevelName,
    required this.nextLevelName,
    required this.currentScore,
    required this.targetScore,
    required this.currentTrustPercentage,
    required this.targetTrustPercentage,
  });

  final String currentLevelName;
  final String nextLevelName;
  final int currentScore;
  final int targetScore;
  final double currentTrustPercentage;
  final double targetTrustPercentage;

  Color _levelColor() {
    switch (currentLevelName) {
      case 'Gözlemci':
        return const Color(0xFFD4C4B7);
      case 'Avcı':
        return const Color(0xFFFF9800);
      case 'Tasarrufçu':
        return const Color(0xFF90CAF9);
      case 'Market Ustası':
        return const Color(0xFFFFEB3B);
      case 'Fiyat Lordu':
        return const Color(0xFFE040FB);
      case 'Radar Efsanesi':
        return const Color(0xFF00E5FF);
      default:
        return const Color(0xFFD4C4B7);
    }
  }

  @override
  Widget build(BuildContext context) {
    final levelColor = _levelColor();
    const darkBrown = Color(0xFF4E342E);
    const mutedBrown = Color(0xFF6D4C41);
    const trackBeige = Color(0xFFEDE2D6);

    final scoreProgress = targetScore <= 0 ? 0.0 : (currentScore / targetScore).clamp(0.0, 1.0);

    final trustProgress = targetTrustPercentage <= 0
        ? 1.0
        : (currentTrustPercentage / targetTrustPercentage).clamp(0.0, 1.0);

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFFFFAF4), Color(0xFFF6EEDF)],
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x1A000000),
            blurRadius: 16,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Seviye İlerlemen',
                  style: const TextStyle(
                    color: darkBrown,
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              UserLevelBadge(levelName: currentLevelName),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            'Sonraki seviye: $nextLevelName',
            style: const TextStyle(
              color: mutedBrown,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Puan',
            style: const TextStyle(
              color: darkBrown,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              minHeight: 8,
              value: scoreProgress,
              backgroundColor: trackBeige,
              valueColor: AlwaysStoppedAnimation<Color>(levelColor),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            '$currentScore / $targetScore',
            style: const TextStyle(
              color: mutedBrown,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 14),
          Text(
            'Güven Yüzdesi',
            style: const TextStyle(
              color: darkBrown,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              minHeight: 8,
              value: trustProgress,
              backgroundColor: trackBeige,
              valueColor: AlwaysStoppedAnimation<Color>(levelColor),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            '%${(currentTrustPercentage * 100).toStringAsFixed(0)} / '
            '%${(targetTrustPercentage * 100).toStringAsFixed(0)}',
            style: const TextStyle(
              color: mutedBrown,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
