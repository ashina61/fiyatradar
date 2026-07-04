import 'package:flutter/material.dart';

import '../../models/comment.dart';
import '../../state/app_state.dart';
import '../../ui/components.dart';
import '../../ui/tokens.dart';
import 'profile_avatar.dart';

/// Lists comments for a product with an inline composer at the bottom.
/// Uses `state.watchProductComments(productId)` so updates are live.
class ProductCommentsSection extends StatefulWidget {
  const ProductCommentsSection({super.key, required this.productId});
  final String productId;

  @override
  State<ProductCommentsSection> createState() => _ProductCommentsSectionState();
}

class _ProductCommentsSectionState extends State<ProductCommentsSection> {
  final TextEditingController _controller = TextEditingController();
  bool _busy = false;
  bool _showAllComments = false;
  String? _error;

  // Yorum stream'ini productId'ye göre cache'le. Ekran `AppStateScope`
  // (InheritedNotifier) dinlediği için her oy/yorum/Firestore güncellemesinde
  // build yeniden çalışır; stream inline kurulursa her seferinde YENİ stream
  // üretir, StreamBuilder yükleme spinner'ına düşüp tekrar listeye döner ve bu
  // yükseklik salınımı ana scroll'u zıplatır. Stream tek kez kurulur.
  Stream<List<ProductComment>>? _commentsStream;
  String? _commentsKey;

  Stream<List<ProductComment>> _commentsFor(AppState state, String productId) {
    if (_commentsKey != productId || _commentsStream == null) {
      _commentsKey = productId;
      _commentsStream = state.watchProductComments(productId);
    }
    return _commentsStream!;
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _submit(AppState state) async {
    final txt = _controller.text.trim();
    if (txt.length < 2) {
      setState(() => _error = 'Yorum çok kısa.');
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await state.addProductComment(productId: widget.productId, text: txt);
      _controller.clear();
    } catch (e) {
      setState(() => _error = e.toString().replaceFirst('Bad state: ', ''));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = AppStateScope.of(context);
    final uid = state.user?.uid ?? '';
    final isAnonymous = state.user?.isAnonymous != false;
    final canPost = uid.isNotEmpty && !isAnonymous && state.isEmailVerified;
    final needsVerification = !isAnonymous && state.needsEmailVerification;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const FRSectionHead(eyebrow: 'TOPLULUK YORUMLARI', title: 'Yorumlar'),
        const SizedBox(height: 6),
        Text(
          'Ürünle ilgili deneyimini paylaş. Saygılı ol — moderasyon kuralları geçerli.',
          style: frText(11.5, FontWeight.w600, color: FR.ink3, height: 1.5),
        ),
        const SizedBox(height: 12),
        StreamBuilder<List<ProductComment>>(
          stream: _commentsFor(state, widget.productId),
          builder: (context, snap) {
            if (snap.connectionState == ConnectionState.waiting &&
                !snap.hasData) {
              return Container(
                padding: const EdgeInsets.all(16),
                decoration: frSurface(radius: FRRad.l),
                alignment: Alignment.center,
                child: SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                      strokeWidth: 2, color: FR.gold),
                ),
              );
            }
            if (snap.hasError) {
              return Container(
                padding: const EdgeInsets.all(16),
                decoration: frSurface(radius: FRRad.l),
                child: Text(
                  'Yorumlar yüklenemedi.',
                  style: frText(12.5, FontWeight.w600, color: FR.bad),
                ),
              );
            }
            final list = snap.data ?? const <ProductComment>[];
            if (list.isEmpty) {
              return Container(
                padding: const EdgeInsets.all(16),
                decoration: frSurface(radius: FRRad.l),
                child: Text(
                  'İlk yorumu sen yaz.',
                  style: frText(12.5, FontWeight.w600, color: FR.ink3),
                ),
              );
            }
            final visible = _showAllComments ? list : list.take(3).toList();
            return Column(
              children: [
                if (list.length > 3) ...[
                  Row(
                    children: [
                      Text(
                        _showAllComments
                            ? 'Tüm yorumlar gösteriliyor'
                            : 'Son 3 yorum',
                        style: frText(11.5, FontWeight.w800, color: FR.ink3),
                      ),
                      const Spacer(),
                      _CommentsTogglePill(
                        label: _showAllComments
                            ? 'Son 3'
                            : 'Tümü ${list.length}',
                        onTap: () => setState(
                          () => _showAllComments = !_showAllComments,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                ],
                for (final c in visible) ...[
                  _CommentTile(
                    comment: c,
                    isOwn: c.isOwnedBy(uid),
                    isAdmin: state.isAdmin,
                    onEdit: () => _editComment(state, c),
                    onDelete: () => _confirmDelete(state, c),
                    onLike: uid.isEmpty
                        ? null
                        : () => _toggleLike(state, c),
                    likedByMe: uid.isNotEmpty && c.isLikedBy(uid),
                  ),
                  const SizedBox(height: 10),
                ],
              ],
            );
          },
        ),
        const SizedBox(height: 8),
        if (!canPost)
          Container(
            padding: const EdgeInsets.all(14),
            decoration: frSurface(radius: FRRad.l),
            child: Text(
              needsVerification
                  ? 'Yorum yazmak için önce e-posta adresini doğrula.'
                  : 'Yorum yazmak için kayıtlı bir hesapla giriş yap.',
              style: frText(12.5, FontWeight.w700, color: FR.ink3),
            ),
          )
        else
          Container(
            padding: const EdgeInsets.fromLTRB(14, 6, 6, 6),
            decoration: frSurface(radius: FRRad.l),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    minLines: 1,
                    maxLines: 4,
                    enabled: !_busy,
                    style: frText(13.5, FontWeight.w600),
                    cursorColor: FR.gold,
                    decoration: InputDecoration(
                      border: InputBorder.none,
                      hintText: 'Yorumunu yaz…',
                      hintStyle:
                          frText(13, FontWeight.w600, color: FR.ink3),
                    ),
                  ),
                ),
                IconButton(
                  onPressed: _busy ? null : () => _submit(state),
                  icon: _busy
                      ? SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: FR.gold),
                        )
                      : Icon(Icons.send_rounded, color: FR.gold),
                ),
              ],
            ),
          ),
        if (_error != null) ...[
          const SizedBox(height: 8),
          Text(_error!,
              style: frText(11.5, FontWeight.w700, color: FR.bad)),
        ],
      ],
    );
  }

  Future<void> _toggleLike(AppState state, ProductComment c) async {
    frHaptic();
    try {
      await state.toggleCommentLike(c.id);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Beğeni kaydedilemedi: $e')),
      );
    }
  }

  Future<void> _editComment(AppState state, ProductComment c) async {
    final ctrl = TextEditingController(text: c.text);
    final next = await showDialog<String>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: FR.surface,
        title: Text('Yorumu düzenle', style: frDisplay(18, FontWeight.w700)),
        content: TextField(
          controller: ctrl,
          autofocus: true,
          maxLines: 5,
          minLines: 2,
          style: frText(14, FontWeight.w600),
          cursorColor: FR.gold,
          decoration: const InputDecoration(border: OutlineInputBorder()),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('İptal',
                style: frText(13, FontWeight.w800, color: FR.ink3)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, ctrl.text),
            child: Text('Kaydet',
                style: frText(13, FontWeight.w800, color: FR.gold)),
          ),
        ],
      ),
    );
    if (next == null) return;
    try {
      await state.updateProductComment(commentId: c.id, text: next);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Düzenleme başarısız: $e')),
      );
    }
  }

  Future<void> _confirmDelete(AppState state, ProductComment c) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: FR.surface,
        title:
            Text('Yorumu sil', style: frDisplay(18, FontWeight.w700)),
        content: Text(
          'Bu yorumu kaldırmak istediğine emin misin?',
          style: frText(13, FontWeight.w600, color: FR.ink2),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Vazgeç',
                style: frText(13, FontWeight.w800, color: FR.ink3)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text('Sil',
                style: frText(13, FontWeight.w800, color: FR.bad)),
          ),
        ],
      ),
    );
    if (ok != true) return;
    try {
      await state.deleteProductComment(c.id);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Silinemedi: $e')),
      );
    }
  }
}

class _CommentsTogglePill extends StatelessWidget {
  const _CommentsTogglePill({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: FRRad.all(999),
      child: Container(
        padding: const EdgeInsetsDirectional.fromSTEB(
          FRSpace.m,
          FRSpace.s,
          FRSpace.m,
          FRSpace.s,
        ),
        decoration: BoxDecoration(
          color: FR.surfaceLo,
          borderRadius: FRRad.all(999),
          border: Border.all(color: FR.gold.withOpacity(.38)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: frText(11.5, FontWeight.w800, color: FR.gold),
            ),
            const SizedBox(width: 4),
            Icon(Icons.chevron_right_rounded, color: FR.gold, size: 16),
          ],
        ),
      ),
    );
  }
}

class _CommentTile extends StatelessWidget {
  const _CommentTile({
    required this.comment,
    required this.isOwn,
    required this.isAdmin,
    required this.likedByMe,
    this.onEdit,
    this.onDelete,
    this.onLike,
  });

  final ProductComment comment;
  final bool isOwn;
  final bool isAdmin;
  final bool likedByMe;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;
  final VoidCallback? onLike;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 10),
      decoration: frSurface(radius: FRRad.l),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ProfileAvatarImage(
                imageUrl: comment.authorAvatar,
                displayName: (comment.authorName ?? '').trim().isEmpty
                    ? 'Topluluk üyesi'
                    : comment.authorName!.trim(),
                size: 32,
                radius: 10,
                cacheWidth: 96,
                initialStyle:
                    frText(13, FontWeight.w800, color: FR.gold),
                fallbackColor: FR.gold.withOpacity(.15),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            isOwn
                                ? 'Sen'
                                : (comment.authorName?.trim().isNotEmpty == true
                                    ? comment.authorName!.trim()
                                    : 'Topluluk üyesi'),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: frText(12.5, FontWeight.w800),
                          ),
                        ),
                        if (comment.authorIsPro) ...[
                          const SizedBox(width: 6),
                          const FRProBadge(),
                        ],
                      ],
                    ),
                    if (comment.authorTrustPercent != null) ...[
                      const SizedBox(height: 4),
                      FRTrustPill(
                        percent: comment.authorTrustPercent!,
                        dense: true,
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Text(
                _ago(comment.createdAt) +
                    (comment.isEdited ? ' · düzenlendi' : ''),
                style: frText(10.5, FontWeight.w700, color: FR.ink3),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            comment.text,
            style: frText(13.5, FontWeight.w600, height: 1.45),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              InkWell(
                onTap: onLike,
                borderRadius: FRRad.all(999),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 6, vertical: 4),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        likedByMe
                            ? Icons.favorite_rounded
                            : Icons.favorite_outline_rounded,
                        size: 16,
                        color: likedByMe ? FR.gold : FR.ink3,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${comment.likes}',
                        style: frText(11.5, FontWeight.w800,
                            color: likedByMe ? FR.gold : FR.ink3),
                      ),
                    ],
                  ),
                ),
              ),
              const Spacer(),
              if (isOwn && onEdit != null)
                _SmallAction(label: 'Düzenle', onTap: onEdit!),
              if ((isOwn || isAdmin) && onDelete != null) ...[
                const SizedBox(width: 6),
                _SmallAction(
                  label: 'Sil',
                  destructive: true,
                  onTap: onDelete!,
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  static String _ago(DateTime d) {
    final diff = DateTime.now().difference(d);
    if (diff.inMinutes < 1) return 'şimdi';
    if (diff.inMinutes < 60) return '${diff.inMinutes}dk';
    if (diff.inHours < 24) return '${diff.inHours}sa';
    if (diff.inDays < 7) return '${diff.inDays}g';
    return '${diff.inDays ~/ 7}h';
  }
}

class _SmallAction extends StatelessWidget {
  const _SmallAction({
    required this.label,
    required this.onTap,
    this.destructive = false,
  });
  final String label;
  final VoidCallback onTap;
  final bool destructive;

  @override
  Widget build(BuildContext context) {
    final color = destructive ? FR.bad : FR.ink2;
    return InkWell(
      onTap: onTap,
      borderRadius: FRRad.all(999),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: Text(
          label,
          style: frText(11.5, FontWeight.w800, color: color),
        ),
      ),
    );
  }
}
