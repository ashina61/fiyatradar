import 'package:flutter/material.dart';

import '../utils/level_system.dart';
import 'level_badge.dart';

@immutable
class UserLevelBadgeProfile {
  const UserLevelBadgeProfile({
    required this.userName,
    required this.level,
    this.trustScorePercent,
  });

  final String userName;
  final UserLevel level;
  final int? trustScorePercent;
}

class UserLevelBadgePill extends StatelessWidget {
  const UserLevelBadgePill({
    super.key,
    required this.userProfile,
    this.compact = true,
    this.showCompactTrust = false,
  });

  final UserLevelBadgeProfile userProfile;
  final bool compact;
  final bool showCompactTrust;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 6,
      runSpacing: 6,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        LevelBadge(
          level: userProfile.level,
          compact: compact,
          withEmoji: false,
          uppercase: false,
        ),
        if (showCompactTrust && userProfile.trustScorePercent != null)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: const Color(0xFFF5EDE4),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFFE7D6C8)),
            ),
            child: Text(
              'Güven %${userProfile.trustScorePercent}',
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: Color(0xFF795548),
              ),
            ),
          ),
      ],
    );
  }
}
