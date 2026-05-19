import 'package:flutter/material.dart';

import '../../models/product.dart';
import '../../state/app_state.dart';
import '../../ui/components.dart';
import '../../ui/tokens.dart';
import 'admin_shared_widgets.dart';

/// Admin moderation queue for community-submitted product photos.
/// Lists every doc in `product_image_submissions` with status `pending`
/// and exposes approve / reject actions per row.
class AdminProductImageSubmissionsScreen extends StatelessWidget {
  const AdminProductImageSubmissionsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = AppStateScope.of(context);
    if (!state.isAdmin) {
      return Scaffold(
        backgroundColor: FR.bg,
        body: Center(
          child: Text(
            'Bu sayfaya erişim için admin yetkisi gerekiyor.',
            style: frText(13, FontWeight.w800, color: FR.ink2),
          ),
        ),
      );
    }
    return Scaffold(
      backgroundColor: FR.bg,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
              child: Row(
                children: [
                  FRIconChip(
                    icon: Icons.arrow_back_rounded,
                    onTap: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
            const Padding(
              padding: EdgeInsets.fromLTRB(20, 14, 20, 0),
              child: FRPageHeader(
                overline: 'TOPLULUK FOTOĞRAFLARI',
                title: 'Görsel',
                italicTail: ' onayları',
              ),
            ),
            const SizedBox(height: 14),
            Expanded(
              child: StreamBuilder<List<ProductImageSubmission>>(
                stream: state.watchPendingProductImageSubmissions(),
                builder: (context, snap) {
                  if (snap.connectionState == ConnectionState.waiting &&
                      !snap.hasData) {
                    return Center(
                      child: CircularProgressIndicator(color: FR.gold),
                    );
                  }
                  if (snap.hasError) {
                    return Padding(
                      padding: const EdgeInsets.all(20),
                      child: Text(
                        'Liste yüklenemedi: ${snap.error}',
                        style:
                            frText(12.5, FontWeight.w700, color: FR.bad),
                      ),
                    );
                  }
                  final items = snap.data ?? const [];
                  if (items.isEmpty) {
                    return Padding(
                      padding: const EdgeInsets.all(20),
                      child: adminEmpty(
                          'Onay bekleyen görsel önerisi yok.'),
                    );
                  }
                  return ListView.separated(
                    padding: const EdgeInsets.fromLTRB(20, 4, 20, 20),
                    itemCount: items.length,
                    separatorBuilder: (_, __) =>
                        const SizedBox(height: 10),
                    itemBuilder: (_, i) =>
                        _SubmissionTile(submission: items[i]),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SubmissionTile extends StatefulWidget {
  const _SubmissionTile({required this.submission});
  final ProductImageSubmission submission;

  @override
  State<_SubmissionTile> createState() => _SubmissionTileState();
}

class _SubmissionTileState extends State<_SubmissionTile> {
  bool _busy = false;

  Future<void> _approve(AppState state) async {
    if (_busy) return;
    setState(() => _busy = true);
    final messenger = ScaffoldMessenger.of(context);
    try {
      await state.approveProductImageSubmission(widget.submission);
      messenger.showSnackBar(
        const SnackBar(content: Text('Görsel onaylandı ve yayınlandı.')),
      );
    } catch (e) {
      messenger.showSnackBar(
        SnackBar(content: Text('Onaylanamadı: $e')),
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _reject(AppState state) async {
    if (_busy) return;
    final ctrl = TextEditingController();
    final reason = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: FR.surface,
        title: Text('Görseli reddet',
            style: frDisplay(18, FontWeight.w700)),
        content: TextField(
          controller: ctrl,
          maxLines: 3,
          autofocus: true,
          decoration: const InputDecoration(
            hintText: 'Kısa gerekçe (opsiyonel)',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Vazgeç',
                style: frText(12.5, FontWeight.w800, color: FR.ink3)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, ctrl.text.trim()),
            child: Text('Reddet',
                style: frText(12.5, FontWeight.w800, color: FR.bad)),
          ),
        ],
      ),
    );
    ctrl.dispose();
    if (reason == null) return;
    setState(() => _busy = true);
    final messenger = ScaffoldMessenger.of(context);
    try {
      await state.rejectProductImageSubmission(
        widget.submission,
        reason: reason,
      );
      messenger.showSnackBar(
        const SnackBar(content: Text('Görsel reddedildi.')),
      );
    } catch (e) {
      messenger.showSnackBar(
        SnackBar(content: Text('Reddedilemedi: $e')),
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = AppStateScope.of(context);
    final s = widget.submission;
    return Container(
      decoration: BoxDecoration(
        color: FR.surface,
        borderRadius: FRRad.all(FRRad.l),
        border: Border.all(color: FR.hairline),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AspectRatio(
            aspectRatio: 1.4,
            child: Container(
              color: FR.surfaceHi,
              child: Image.network(
                s.imageUrl,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Center(
                  child: Icon(Icons.broken_image_outlined,
                      color: FR.ink3, size: 32),
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(s.productName,
                    style: frText(14, FontWeight.w800)),
                const SizedBox(height: 4),
                Text(
                  'Öneren · ${s.submittedByName}',
                  style: frText(11.5, FontWeight.w700, color: FR.ink3),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: InkWell(
                        onTap: _busy ? null : () => _reject(state),
                        borderRadius: FRRad.all(12),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: FR.bad.withOpacity(.1),
                            borderRadius: FRRad.all(12),
                            border:
                                Border.all(color: FR.bad.withOpacity(.4)),
                          ),
                          child: Text('Reddet',
                              style: frText(12.5, FontWeight.w800,
                                  color: FR.bad)),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: InkWell(
                        onTap: _busy ? null : () => _approve(state),
                        borderRadius: FRRad.all(12),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: FR.gold,
                            borderRadius: FRRad.all(12),
                            boxShadow: frGoldGlow(opacity: .2),
                          ),
                          child: _busy
                              ? SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: FR.onGold,
                                  ),
                                )
                              : Text(
                                  'Onayla ve yayınla',
                                  style: frText(12.5, FontWeight.w800,
                                      color: FR.onGold),
                                ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
