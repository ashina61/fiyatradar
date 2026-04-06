import 'package:flutter/material.dart';

import 'fr_surface_card.dart';
import '../tokens/typography.dart';

class FRInfoRowCard extends StatelessWidget {
  const FRInfoRowCard({required this.title, super.key, this.subtitle, this.leading, this.trailing, this.onTap});

  final String title;
  final String? subtitle;
  final Widget? leading;
  final Widget? trailing;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return FRSurfaceCard(
      child: ListTile(
        onTap: onTap,
        contentPadding: EdgeInsets.zero,
        leading: leading,
        title: Text(title, style: FRDsTypography.titleMedium),
        subtitle: subtitle == null ? null : Text(subtitle!, style: FRDsTypography.bodyMedium),
        trailing: trailing ?? const Icon(Icons.chevron_right),
      ),
    );
  }
}
