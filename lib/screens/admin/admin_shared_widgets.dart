import 'package:flutter/material.dart';

import '../../ui/components.dart';
import '../../ui/tokens.dart';

class AdminLoading extends StatelessWidget {
  const AdminLoading({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 28),
      child: Center(
        child: SizedBox(
          width: 22,
          height: 22,
          child: CircularProgressIndicator(strokeWidth: 2.4, color: FR.gold),
        ),
      ),
    );
  }
}

Widget adminEmpty(String label) {
  return Container(
    padding: const EdgeInsets.all(20),
    decoration: frSurface(radius: FRRad.l),
    alignment: Alignment.center,
    child: Text(label, style: frText(12.5, FontWeight.w600, color: FR.ink3)),
  );
}

Widget adminRowList(List<Widget> rows) {
  return Column(
    children: [
      for (var i = 0; i < rows.length; i++) ...[
        rows[i],
        if (i < rows.length - 1) const SizedBox(height: 10),
      ],
    ],
  );
}

class AdminCrudScaffold extends StatelessWidget {
  const AdminCrudScaffold({
    required this.title,
    required this.child,
    this.onAdd,
  });
  final String title;
  final Widget child;
  final VoidCallback? onAdd;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: FR.bg,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 0), // LEGACY_EXCEPTION: reason=token_migration owner=codex remove_by=2026-06-30
              child: Row(
                children: [
                  FRIconChip(
                    icon: Icons.arrow_back_rounded,
                    onTap: () => Navigator.pop(context),
                  ),
                  const Spacer(),
                  if (onAdd != null)
                    FRIconChip(icon: Icons.add_rounded, onTap: onAdd),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 14, 20, 0), // LEGACY_EXCEPTION: reason=token_migration owner=codex remove_by=2026-06-30
              child: FRPageHeader(overline: 'ADMIN', title: title),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 24), // LEGACY_EXCEPTION: reason=token_migration owner=codex remove_by=2026-06-30
                children: [child],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class CrudRow extends StatelessWidget {
  const CrudRow({
    required this.title,
    required this.subtitle,
    required this.onEdit,
    required this.onDelete,
    this.onToggleActive,
    this.editLabel = 'Düzenle',
    this.deleteLabel = 'Sil',
  });
  final String title;
  final String subtitle;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback? onToggleActive;
  final String editLabel;
  final String deleteLabel;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12), // LEGACY_EXCEPTION: reason=token_migration owner=codex remove_by=2026-06-30
      decoration: BoxDecoration(
        color: FR.surface,
        borderRadius: FRRad.all(FRRad.l),
        border: Border.all(color: FR.hairline),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: frText(13, FontWeight.w800)),
          const SizedBox(height: 2),
          Text(subtitle, style: frText(11.5, FontWeight.w600, color: FR.ink3)),
          const SizedBox(height: 10),
          Row(
            children: [
              if (onToggleActive != null) ...[
                Expanded(
                  child: FRCta(
                    label: 'Aktif/Pasif',
                    filled: false,
                    onTap: onToggleActive,
                  ),
                ),
                const SizedBox(width: 8),
              ],
              Expanded(
                child: FRCta(
                  label: editLabel,
                  filled: false,
                  onTap: onEdit,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: FRCta(
                  label: deleteLabel,
                  icon: Icons.delete_outline_rounded,
                  onTap: onDelete,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

