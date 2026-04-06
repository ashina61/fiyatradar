// lib/screens/product/product_detail_screen.dart
// GREENFIELD v2 — "Quiet Intelligence" product dossier page.
// Full rewrite. Rejected: 2000-line tabbed legacy layout with fl_chart hero,
// colored cards, rating rings and dense footer.
// UX goal: a calm product dossier. Title → image plate → hero best-price →
// market list → stats line → comments → one sticky CTA.

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';

import '../../providers/product_detail_provider.dart';
import '../../theme/fr_ink.dart';
import '../../utils/formatters.dart';
import '../add_price/add_price_screen.dart';

class ProductDetailScreen extends ConsumerStatefulWidget {
  const ProductDetailScreen({
    super.key,
    required this.productId,
    this.highlightedCommentId,
    this.highlightedPriceId,
  });

  final String productId;
  final String? highlightedCommentId;
  final String? highlightedPriceId;

  @override
  ConsumerState<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends ConsumerState<ProductDetailScreen> {
  final _commentCtrl = TextEditingController();

  @override
  void dispose() {
    _commentCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(productDetailProvider(widget.productId));

    return Scaffold(
      backgroundColor: FRInk.paper,
      body: SafeArea(
        bottom: false,
        child: state.isLoading
            ? const _Loading()
            : state.error != null
                ? _Error(message: state.error!, onRetry: () => ref.read(productDetailProvider(widget.productId).notifier).load())
                : state.data == null
                    ? const _Error(message: 'Ürün bulunamadı.')
                    : _Content(
                        data: state.data!,
                        commentCtrl: _commentCtrl,
                        onPostComment: () async {
                          final text = _commentCtrl.text.trim();
                          if (text.isEmpty) return;
                          final ok = await ref
                              .read(productDetailProvider(widget.productId).notifier)
                              .postComment(text);
                          if (ok) _commentCtrl.clear();
                        },
                        onAddPrice: () => Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => AddPriceScreen(initialProductId: widget.productId),
                          ),
                        ),
                      ),
      ),
    );
  }
}

// ── Content ──────────────────────────────────────────────────────────────────
class _Content extends StatelessWidget {
  const _Content({
    required this.data,
    required this.commentCtrl,
    required this.onPostComment,
    required this.onAddPrice,
  });

  final dynamic data; // ProductDetailResponse
  final TextEditingController commentCtrl;
  final VoidCallback onPostComment;
  final VoidCallback onAddPrice;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            SliverToBoxAdapter(child: _TopBar(title: data.title)),
            SliverToBoxAdapter(child: _TitleBlock(title: data.title, categories: data.categories)),
            SliverToBoxAdapter(child: _ImagePlate(url: data.imageUrl)),
            SliverToBoxAdapter(child: _HeroPrice(best: data.bestPrice, stats: data.stats)),
            const SliverToBoxAdapter(child: _Label('PİYASA')),
            SliverToBoxAdapter(child: _MarketList(entries: data.marketPrices)),
            const SliverToBoxAdapter(child: SizedBox(height: 28)),
            const SliverToBoxAdapter(child: _Label('GÜVEN')),
            SliverToBoxAdapter(child: _TrustLine(trust: data.trust, viewCount: data.viewCount, entryCount: data.priceEntryCount)),
            const SliverToBoxAdapter(child: SizedBox(height: 28)),
            const SliverToBoxAdapter(child: _Label('YORUMLAR')),
            SliverToBoxAdapter(child: _Comments(comments: data.comments)),
            SliverToBoxAdapter(
              child: _CommentComposer(ctrl: commentCtrl, onPost: onPostComment),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 140)),
          ],
        ),
        Positioned(
          left: 0, right: 0, bottom: 0,
          child: _StickyAdd(onTap: onAddPrice),
        ),
      ],
    );
  }
}

class _TopBar extends StatelessWidget {
  const _TopBar({required this.title});
  final String title;
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(FRInk.gutter, 14, FRInk.gutter, 6),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.of(context).maybePop(),
            child: const Icon(Icons.arrow_back_rounded, size: 24, color: FRInk.ink),
          ),
          const Spacer(),
          const Text('ÜRÜN', style: FRType.micro),
          const Spacer(),
          GestureDetector(
            onTap: () => Share.share('FiyatRadar · $title'),
            child: const Icon(Icons.ios_share_rounded, size: 22, color: FRInk.ink),
          ),
        ],
      ),
    );
  }
}

class _TitleBlock extends StatelessWidget {
  const _TitleBlock({required this.title, required this.categories});
  final String title;
  final List<dynamic> categories;

  @override
  Widget build(BuildContext context) {
    final cat = categories.isNotEmpty ? categories.first.toString().toUpperCase() : null;
    return Padding(
      padding: const EdgeInsets.fromLTRB(FRInk.gutter, 22, FRInk.gutter, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (cat != null) ...[
            Text(cat, style: FRType.micro),
            const SizedBox(height: 8),
          ],
          Text(title, style: FRType.title),
        ],
      ),
    );
  }
}

class _ImagePlate extends StatelessWidget {
  const _ImagePlate({required this.url});
  final String url;
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(FRInk.gutter, 24, FRInk.gutter, 0),
      child: AspectRatio(
        aspectRatio: 1.2,
        child: Container(
          decoration: BoxDecoration(
            color: FRInk.paperDeep,
            borderRadius: BorderRadius.circular(18),
          ),
          clipBehavior: Clip.hardEdge,
          child: url.isEmpty
              ? const Icon(Icons.image_not_supported_outlined, color: FRInk.inkFaint, size: 40)
              : CachedNetworkImage(
                  imageUrl: url,
                  fit: BoxFit.contain,
                  errorWidget: (_, __, ___) => const Icon(Icons.broken_image_outlined, color: FRInk.inkFaint),
                ),
        ),
      ),
    );
  }
}

class _HeroPrice extends StatelessWidget {
  const _HeroPrice({required this.best, required this.stats});
  final dynamic best;
  final dynamic stats;
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(FRInk.gutter, 30, FRInk.gutter, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('EN DÜŞÜK', style: FRType.micro),
          const SizedBox(height: 6),
          Text(formatTRY(best.price as double), style: FRType.display.copyWith(fontSize: 56)),
          const SizedBox(height: 6),
          Text(
            '${best.store} · ${best.createdAtLabel}',
            style: FRType.body.copyWith(color: FRInk.inkMute),
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              _MiniStat(label: 'ORT.', value: formatTRY(stats.average as double)),
              Container(width: 1, height: 30, color: FRInk.hairline),
              _MiniStat(label: 'MAKS.', value: formatTRY(stats.highest as double)),
            ],
          ),
        ],
      ),
    );
  }
}

class _MiniStat extends StatelessWidget {
  const _MiniStat({required this.label, required this.value});
  final String label;
  final String value;
  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: FRType.micro),
          const SizedBox(height: 4),
          Text(value, style: FRType.numeral.copyWith(fontSize: 18)),
        ],
      ),
    );
  }
}

class _Label extends StatelessWidget {
  const _Label(this.text);
  final String text;
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(FRInk.gutter, 32, FRInk.gutter, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(text, style: FRType.micro),
          const SizedBox(height: 10),
          const FRHairline(),
        ],
      ),
    );
  }
}

class _MarketList extends StatelessWidget {
  const _MarketList({required this.entries});
  final List<dynamic> entries;
  @override
  Widget build(BuildContext context) {
    if (entries.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(horizontal: FRInk.gutter, vertical: 20),
        child: Text('Henüz başka market fiyatı yok.', style: FRType.body),
      );
    }
    return Column(
      children: [
        for (var i = 0; i < entries.length; i++) ...[
          _MarketRow(e: entries[i]),
          if (i != entries.length - 1) const FRHairline(indent: FRInk.gutter),
        ],
      ],
    );
  }
}

class _MarketRow extends StatelessWidget {
  const _MarketRow({required this.e});
  final dynamic e;
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: FRInk.gutter, vertical: 16),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(e.storeName as String, style: FRType.bodyStrong, maxLines: 1, overflow: TextOverflow.ellipsis),
                const SizedBox(height: 3),
                Text(
                  '${e.timeAgo} · ${e.userName}',
                  style: FRType.body.copyWith(color: FRInk.inkMute, fontSize: 13),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Text(formatTRY(e.price as double), style: FRType.numeral),
        ],
      ),
    );
  }
}

class _TrustLine extends StatelessWidget {
  const _TrustLine({required this.trust, required this.viewCount, required this.entryCount});
  final dynamic trust;
  final int viewCount;
  final int entryCount;
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: FRInk.gutter),
      child: Row(
        children: [
          _TrustCol(label: 'GÜVEN', value: '${trust.scorePercent}%'),
          Container(width: 1, height: 38, color: FRInk.hairline),
          _TrustCol(label: 'BİLDİRİM', value: '$entryCount'),
          Container(width: 1, height: 38, color: FRInk.hairline),
          _TrustCol(label: 'GÖRÜNTÜ', value: formatCompactCount(viewCount)),
        ],
      ),
    );
  }
}

class _TrustCol extends StatelessWidget {
  const _TrustCol({required this.label, required this.value});
  final String label;
  final String value;
  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 14),
        child: Column(
          children: [
            Text(value, style: FRType.title.copyWith(fontSize: 22)),
            const SizedBox(height: 4),
            Text(label, style: FRType.micro),
          ],
        ),
      ),
    );
  }
}

class _Comments extends StatelessWidget {
  const _Comments({required this.comments});
  final List<dynamic> comments;
  @override
  Widget build(BuildContext context) {
    if (comments.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(horizontal: FRInk.gutter, vertical: 16),
        child: Text('İlk yorumu sen yaz.', style: FRType.body),
      );
    }
    return Column(
      children: [
        for (var i = 0; i < comments.length; i++) ...[
          _CommentRow(c: comments[i]),
          if (i != comments.length - 1) const FRHairline(indent: FRInk.gutter),
        ],
      ],
    );
  }
}

class _CommentRow extends StatelessWidget {
  const _CommentRow({required this.c});
  final dynamic c;
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: FRInk.gutter, vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(c.author as String, style: FRType.bodyStrong),
              const SizedBox(width: 8),
              Text(c.timeAgo as String, style: FRType.body.copyWith(color: FRInk.inkMute, fontSize: 12)),
            ],
          ),
          const SizedBox(height: 6),
          Text(c.text as String, style: FRType.body),
        ],
      ),
    );
  }
}

class _CommentComposer extends StatelessWidget {
  const _CommentComposer({required this.ctrl, required this.onPost});
  final TextEditingController ctrl;
  final VoidCallback onPost;
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(FRInk.gutter, 16, FRInk.gutter, 0),
      child: Row(
        children: [
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: FRInk.paperDeep,
                borderRadius: BorderRadius.circular(14),
              ),
              child: TextField(
                controller: ctrl,
                cursorColor: FRInk.ink,
                style: FRType.body.copyWith(color: FRInk.ink),
                decoration: const InputDecoration(
                  isCollapsed: true,
                  border: InputBorder.none,
                  hintText: 'Yorum yaz…',
                  hintStyle: TextStyle(color: FRInk.inkFaint, fontFamily: FRType.family, fontSize: 15),
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          GestureDetector(
            onTap: onPost,
            child: Container(
              width: 44, height: 44,
              alignment: Alignment.center,
              decoration: const BoxDecoration(color: FRInk.ink, shape: BoxShape.circle),
              child: const Icon(Icons.arrow_upward_rounded, size: 20, color: FRInk.paper),
            ),
          ),
        ],
      ),
    );
  }
}

class _StickyAdd extends StatelessWidget {
  const _StickyAdd({required this.onTap});
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(FRInk.gutter, 12, FRInk.gutter, 18),
      decoration: const BoxDecoration(
        color: FRInk.paper,
        border: Border(top: BorderSide(color: FRInk.hairline)),
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 54,
          width: double.infinity,
          child: Material(
            color: FRInk.ink,
            borderRadius: BorderRadius.circular(14),
            child: InkWell(
              borderRadius: BorderRadius.circular(14),
              onTap: onTap,
              child: const Center(
                child: Text(
                  'Bu ürüne fiyat bildir',
                  style: TextStyle(
                    fontFamily: FRType.family,
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: FRInk.paper,
                    letterSpacing: 0.2,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _Loading extends StatelessWidget {
  const _Loading();
  @override
  Widget build(BuildContext context) => const Center(
        child: SizedBox(
          width: 18, height: 18,
          child: CircularProgressIndicator(strokeWidth: 1.5, color: FRInk.ink),
        ),
      );
}

class _Error extends StatelessWidget {
  const _Error({required this.message, this.onRetry});
  final String message;
  final VoidCallback? onRetry;
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(FRInk.gutter),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('HATA', style: FRType.micro),
          const SizedBox(height: 6),
          Text(message, style: FRType.body),
          if (onRetry != null) ...[
            const SizedBox(height: 16),
            GestureDetector(
              onTap: onRetry,
              child: const Text('Tekrar dene',
                  style: TextStyle(
                    fontFamily: FRType.family, fontSize: 14,
                    fontWeight: FontWeight.w700, color: FRInk.saffron,
                    decoration: TextDecoration.underline,
                  )),
            ),
          ],
        ],
      ),
    );
  }
}
