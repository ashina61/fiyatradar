import 'package:flutter/material.dart';

import '../components/fr_section_header.dart';
import '../components/fr_surface_card.dart';
import '../tokens/spacing.dart';

class FRAccountShortcutsSection extends StatelessWidget {
  const FRAccountShortcutsSection({required this.title, required this.children, super.key, this.eyebrow});

  final String title;
  final String? eyebrow;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        FRSectionHeader(title: title, eyebrow: eyebrow),
        const SizedBox(height: FRDsSpacing.space12),
        FRSurfaceCard(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: children),
        ),
      ],
    );
  }
}
