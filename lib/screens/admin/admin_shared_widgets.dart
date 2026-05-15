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

/// Admin "kalıcı silme" onay diyaloğu. Geri-alınamaz aksiyonları (ürün/
/// mağaza/zincir doğrudan silme) sarmak için. `confirmLabel` default
/// "Sil"; çağıran isterse override edebilir.
///
/// Dönüş `true` ise kullanıcı onayladı; bu noktada arayan tarafın asıl
/// `delete` çağrısını yapması beklenir. SnackBar / hata gösterimi de
/// çağıranın sorumluluğu.
Future<bool> showAdminConfirmDeleteDialog(
  BuildContext context, {
  required String title,
  required String message,
  String confirmLabel = 'Sil',
}) async {
  final ok = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      backgroundColor: FR.surface,
      title: Text(title, style: frDisplay(20, FontWeight.w700)),
      content: Text(
        message,
        style: frText(13, FontWeight.w600, color: FR.ink2, height: 1.5),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx, false),
          child: Text('İptal',
              style: frText(12.5, FontWeight.w800, color: FR.ink3)),
        ),
        TextButton(
          onPressed: () => Navigator.pop(ctx, true),
          child: Text(confirmLabel,
              style: frText(12.5, FontWeight.w800, color: FR.bad)),
        ),
      ],
    ),
  );
  return ok == true;
}

Future<void> showAdminTextEditSheet(
  BuildContext context, {
  required String title,
  String initial = '',
  required Future<void> Function(String value) onSave,
}) async {
  final ctrl = TextEditingController(text: initial);
  final ok = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      backgroundColor: FR.surface,
      title: Text(title, style: frDisplay(20, FontWeight.w700)),
      content: TextField(
        controller: ctrl,
        decoration: InputDecoration(
          hintText: 'Ad',
          hintStyle: frText(12, FontWeight.w600, color: FR.ink3),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx, false),
          child: Text('İptal',
              style: frText(12.5, FontWeight.w800, color: FR.ink3)),
        ),
        TextButton(
          onPressed: () => Navigator.pop(ctx, true),
          child: Text('Kaydet',
              style: frText(12.5, FontWeight.w800, color: FR.gold)),
        ),
      ],
    ),
  );
  if (ok == true && ctrl.text.trim().isNotEmpty) {
    try {
      await onSave(ctrl.text.trim());
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('$e')),
      );
    }
  }
  ctrl.dispose();
}

class AdminCrudScaffold extends StatelessWidget {
  const AdminCrudScaffold({
    super.key,
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
    super.key,
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

