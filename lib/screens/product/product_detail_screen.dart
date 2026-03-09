import 'dart:math' as math;

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../models/product_detail_api_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/product_detail_provider.dart';
import '../../providers/product_provider.dart';
import '../../services/watchlist_service.dart';
import '../add_price/add_price_screen.dart';

const Color pxDarkHeader = Color(0xFF1A110D);
const Color pxDarkBtn = Color(0xFF2A1C14);
const Color pxBg = Color(0xFFF4F2EE);
const Color pxWhite = Colors.white;
const Color pxCaramel = Color(0xFF6A442A);
const Color pxGold = Color(0xFFC29B78);
const Color pxTextMain = Color(0xFF211510);
const Color pxTextMuted = Color(0xFF8C7B70);
const Color pxSuccess = Color(0xFF2F855A);
const Color pxAlert = Color(0xFFC53030);

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
  final _commentController = TextEditingController();
  final WatchlistService _watchlistService = WatchlistService();

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _openAddPrice() async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => AddPriceScreen(initialProductId: widget.productId),
      ),
    );
    if (!mounted) return;
    await ref.read(productDetailProvider(widget.productId).notifier).load();
  }

  Future<void> _toggleFavorite(ProductDetailResponse data) async {
    final user = ref.read(authStateProvider).valueOrNull;
    if (user == null) return;
    await ref.read(firestoreServiceProvider).toggleFavorite(
      uid: user.uid,
      productId: data.id,
      payload: {'productName': data.title, 'imageUrl': data.imageUrl},
    );
  }

  Future<void> _toggleWatch(ProductDetailResponse data, bool isWatching) async {
    final user = ref.read(authStateProvider).valueOrNull;
    if (user == null) return;
    if (isWatching) {
      await _watchlistService.removeFromWatchlist(user.uid, data.id);
    } else {
      await _watchlistService.addToWatchlist(
        user.uid,
        data.id,
        data.title,
        data.bestPrice.price,
      );
    }
  }

  Future<void> _openStoreMap(BestPrice bestPrice) async {
    final coords = await ref
        .read(productDetailApiServiceProvider)
        .resolveStoreCoordinates(bestPrice);
    Uri? uri;
    if (coords != null) {
      uri = Uri.parse(
        'https://www.google.com/maps/search/?api=1&query=${coords.latitude},${coords.longitude}',
      );
    } else if (bestPrice.storeLocation.trim().isNotEmpty) {
      uri = Uri.parse(
        'https://www.google.com/maps/search/?api=1&query=${Uri.encodeComponent(bestPrice.storeLocation)}',
      );
    }
    if (uri != null) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  Future<void> _share(ProductDetailResponse data) async {
    await Share.share('${data.title} - FiyatRadar\nÜrün ID: ${data.id}');
  }

  Future<void> _openRejectSheet(ProductDetailState state) async {
    final data = state.data;
    final user = ref.read(authStateProvider).valueOrNull;
    if (data == null || user == null || data.bestPrice.id.isEmpty) return;

    final reasons = <String>['Stokta Yok', 'Fiyat Değişmiş', 'Yanlış Ürün', 'Mağaza Kapalı'];
    final selected = <String>{};
    final detailController = TextEditingController();

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Container(
              padding: EdgeInsets.only(
                left: 20,
                right: 20,
                top: 20,
                bottom: 20 + MediaQuery.of(context).viewInsets.bottom,
              ),
              decoration: const BoxDecoration(
                color: pxWhite,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Expanded(
                        child: Text(
                          'Neden Hatalı?',
                          style: TextStyle(
                            color: pxAlert,
                            fontWeight: FontWeight.w800,
                            fontSize: 20,
                          ),
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.close),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Bu fiyatın neden yanlış veya geçersiz olduğunu belirtin.',
                    style: TextStyle(color: pxTextMuted),
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: reasons
                        .map(
                          (reason) => FilterChip(
                            selected: selected.contains(reason),
                            label: Text(reason),
                            onSelected: (value) {
                              setModalState(() {
                                if (value) {
                                  selected.add(reason);
                                } else {
                                  selected.remove(reason);
                                }
                              });
                            },
                          ),
                        )
                        .toList(),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: detailController,
                    minLines: 3,
                    maxLines: 5,
                    decoration: const InputDecoration(
                      hintText: 'Ekstra detay ekleyebilirsiniz...',
                      filled: true,
                      fillColor: pxBg,
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  FilledButton(
                    style: FilledButton.styleFrom(
                      minimumSize: const Size.fromHeight(50),
                      backgroundColor: pxAlert,
                    ),
                    onPressed: () async {
                      final reasonText = [
                        ...selected,
                        if (detailController.text.trim().isNotEmpty)
                          detailController.text.trim(),
                      ].join(' | ');
                      if (reasonText.trim().isEmpty) return;

                      await ref.read(firestoreServiceProvider).reportPrice(
                            priceId: data.bestPrice.id,
                            userId: user.uid,
                            reason: reasonText,
                            contextId: data.id,
                          );
                      await ref
                          .read(productDetailProvider(widget.productId).notifier)
                          .votePrice(priceId: data.bestPrice.id, isApproved: false);
                      if (!mounted) return;
                      Navigator.pop(context);
                    },
                    child: const Text('İTİRAZI GÖNDER'),
                  ),
                ],
              ),
            );
          },
        );
      },
    );

    detailController.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(productDetailProvider(widget.productId));
    final notifier = ref.read(productDetailProvider(widget.productId).notifier);
    final user = ref.watch(authStateProvider).valueOrNull;
    final favoriteStream = user == null
        ? const Stream<bool>.empty()
        : ref.watch(firestoreServiceProvider).isFavoriteStream(
              uid: user.uid,
              productId: widget.productId,
            );
    final watchStream = user == null
        ? const Stream<bool>.empty()
        : _watchlistService.isWatchlisted(user.uid, widget.productId);

    return Scaffold(
      backgroundColor: pxBg,
      body: state.isLoading
          ? const Center(child: CircularProgressIndicator())
          : state.error != null
              ? Center(child: Text(state.error!))
              : _Body(
                  data: state.data!,
                  history: state.history,
                  commentController: _commentController,
                  state: state,
                  notifier: notifier,
                  favoriteStream: favoriteStream,
                  watchStream: watchStream,
                  onBack: () => Navigator.of(context).pop(),
                  onToggleFavorite: () => _toggleFavorite(state.data!),
                  onToggleWatch: (isWatching) => _toggleWatch(state.data!, isWatching),
                  onShare: () => _share(state.data!),
                  onOpenMap: () => _openStoreMap(state.data!.bestPrice),
                  onOpenReject: () => _openRejectSheet(state),
                ),
      bottomNavigationBar: SafeArea(
        top: false,
        child: Container(
          color: pxBg,
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
          child: SizedBox(
            height: 54,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: pxCaramel,
                foregroundColor: pxWhite,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
              onPressed: _openAddPrice,
              icon: const Icon(Icons.add),
              label: const Text('YENİ FİYAT EKLE'),
            ),
          ),
        ),
      ),
    );
  }
}

class _Body extends ConsumerWidget {
  const _Body({
    required this.data,
    required this.history,
    required this.commentController,
    required this.state,
    required this.notifier,
    required this.favoriteStream,
    required this.watchStream,
    required this.onBack,
    required this.onToggleFavorite,
    required this.onToggleWatch,
    required this.onShare,
    required this.onOpenMap,
    required this.onOpenReject,
  });

  final ProductDetailResponse data;
  final List<PriceHistoryPoint> history;
  final TextEditingController commentController;
  final ProductDetailState state;
  final ProductDetailNotifier notifier;
  final Stream<bool> favoriteStream;
  final Stream<bool> watchStream;
  final VoidCallback onBack;
  final VoidCallback onToggleFavorite;
  final ValueChanged<bool> onToggleWatch;
  final VoidCallback onShare;
  final VoidCallback onOpenMap;
  final VoidCallback onOpenReject;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final hasBestPrice = data.bestPrice.id.isNotEmpty;
    final trust = data.trust;
    final voteStream = ref.watch(authStateProvider).valueOrNull == null || !hasBestPrice
        ? const Stream<String?>.empty()
        : ref.read(firestoreServiceProvider).streamUserVoteValue(
              data.bestPrice.id,
              ref.watch(authStateProvider).valueOrNull!.uid,
            );

    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: Container(
            decoration: const BoxDecoration(
              color: pxDarkHeader,
              borderRadius: BorderRadius.vertical(bottom: Radius.circular(24)),
            ),
            padding: EdgeInsets.only(
              left: 16,
              right: 16,
              top: MediaQuery.of(context).padding.top + 8,
              bottom: 16,
            ),
            child: Row(
              children: [
                _HeaderBtn(icon: Icons.arrow_back_ios_new, onTap: onBack),
                const Expanded(
                  child: Center(
                    child: Text(
                      'Ürün Detayı',
                      style: TextStyle(color: pxWhite, fontWeight: FontWeight.w800),
                    ),
                  ),
                ),
                StreamBuilder<bool>(
                  stream: watchStream,
                  builder: (context, snap) {
                    final isWatching = snap.data ?? false;
                    return _HeaderBtn(
                      icon: isWatching ? Icons.notifications_active : Icons.notifications_none,
                      onTap: () => onToggleWatch(isWatching),
                    );
                  },
                ),
                const SizedBox(width: 6),
                StreamBuilder<bool>(
                  stream: favoriteStream,
                  builder: (context, snap) {
                    final isFav = snap.data ?? false;
                    return _HeaderBtn(
                      icon: isFav ? Icons.favorite : Icons.favorite_border,
                      color: isFav ? pxAlert : pxWhite,
                      onTap: onToggleFavorite,
                    );
                  },
                ),
                const SizedBox(width: 6),
                _HeaderBtn(icon: Icons.share, onTap: onShare),
              ],
            ),
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 120),
          sliver: SliverList(
            delegate: SliverChildListDelegate([
              _module(
                child: Column(
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(14),
                          child: Container(
                            width: 96,
                            height: 96,
                            color: const Color(0xFFF8F6F4),
                            child: data.imageUrl.trim().isEmpty
                                ? const Icon(Icons.image_not_supported, color: pxTextMuted)
                                : Image.network(
                                    data.imageUrl,
                                    fit: BoxFit.cover,
                                    errorBuilder: (_, __, ___) => const Icon(
                                      Icons.broken_image,
                                      color: pxTextMuted,
                                    ),
                                  ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                data.categories.join(' • '),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: pxTextMuted,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 11,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                data.title,
                                maxLines: 3,
                                overflow: TextOverflow.ellipsis,
                                style: GoogleFonts.outfit(
                                  fontWeight: FontWeight.w800,
                                  color: pxTextMain,
                                  fontSize: 20,
                                  height: 1.1,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                '${data.viewCount} görüntüleme',
                                style: const TextStyle(color: pxTextMuted, fontSize: 12),
                              ),
                            ],
                          ),
                        )
                      ],
                    ),
                    const Divider(height: 24),
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  const Icon(Icons.circle, size: 8, color: pxSuccess),
                                  const SizedBox(width: 6),
                                  Expanded(
                                    child: Text(
                                      data.bestPrice.store,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        color: pxSuccess,
                                        fontWeight: FontWeight.w800,
                                      ),
                                    ),
                                  ),
                                  IconButton(
                                    onPressed: hasBestPrice ? onOpenMap : null,
                                    icon: const Icon(Icons.map, color: pxCaramel),
                                  )
                                ],
                              ),
                              Text(
                                data.bestPrice.createdAtLabel.trim().isEmpty
                                    ? '-'
                                    : '${data.bestPrice.createdAtLabel} eklendi',
                                style: const TextStyle(fontSize: 11, color: pxTextMuted),
                              ),
                            ],
                          ),
                        ),
                        Text(
                          hasBestPrice ? '${data.bestPrice.price.toStringAsFixed(2)}₺' : '-',
                          style: GoogleFonts.dmSans(
                            fontWeight: FontWeight.w700,
                            fontSize: 28,
                            color: pxTextMain,
                          ),
                        ),
                      ],
                    )
                  ],
                ),
              ),
              const SizedBox(height: 14),
              if (hasBestPrice)
                _module(
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 20,
                        backgroundColor: pxGold.withOpacity(0.3),
                        child: Text(
                          data.bestPrice.userName.isEmpty
                              ? '?'
                              : data.bestPrice.userName.characters.first.toUpperCase(),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('FİYATI EKLEYEN', style: TextStyle(fontSize: 10, color: pxTextMuted, fontWeight: FontWeight.w700)),
                            Row(
                              children: [
                                Flexible(
                                  child: Text(
                                    data.bestPrice.userName,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(fontWeight: FontWeight.w800),
                                  ),
                                ),
                                if (data.bestPrice.userTrustScore > 0) ...[
                                  const SizedBox(width: 6),
                                  const Icon(Icons.verified, size: 16, color: Colors.blue),
                                ],
                              ],
                            ),
                            if (data.bestPrice.userTier.trim().isNotEmpty)
                              Text(data.bestPrice.userTier, style: const TextStyle(color: pxTextMuted, fontSize: 12)),
                          ],
                        ),
                      ),
                      IconButton(onPressed: onOpenReject, icon: const Icon(Icons.outlined_flag, color: pxAlert)),
                    ],
                  ),
                ),
              const SizedBox(height: 14),
              _module(
                child: Column(
                  children: [
                    Row(
                      children: [
                        Expanded(child: _stat('En Düşük', data.stats.lowest, pxSuccess)),
                        Expanded(child: _stat('Ortalama', data.stats.average, pxTextMain)),
                        Expanded(child: _stat('En Yüksek', data.stats.highest, pxAlert)),
                      ],
                    ),
                    if (history.isNotEmpty) ...[
                      const Divider(height: 24),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Fiyat Trendi', style: TextStyle(fontWeight: FontWeight.w800)),
                          Text('Son ${history.length} giriş', style: const TextStyle(color: pxTextMuted, fontSize: 11)),
                        ],
                      ),
                      const SizedBox(height: 10),
                      SizedBox(
                        height: 120,
                        child: BarChart(
                          BarChartData(
                            gridData: const FlGridData(show: false),
                            borderData: FlBorderData(show: false),
                            titlesData: const FlTitlesData(show: false),
                            barGroups: history.asMap().entries.map((entry) {
                              final maxPrice = history.map((e) => e.price).reduce(math.max);
                              final h = maxPrice <= 0 ? 0.0 : entry.value.price / maxPrice;
                              return BarChartGroupData(
                                x: entry.key,
                                barRods: [
                                  BarChartRodData(
                                    toY: (h * 100).clamp(0, 100),
                                    color: entry.key == history.length - 1 ? pxDarkHeader : pxGold,
                                    width: 14,
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                ],
                              );
                            }).toList(),
                            minY: 0,
                            maxY: 100,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 14),
              if (hasBestPrice)
                _module(
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Topluluk Onayı', style: TextStyle(fontWeight: FontWeight.w800)),
                          if (trust.approveCount + trust.rejectCount > 0)
                            Text('%${trust.scorePercent} Güvenilir', style: const TextStyle(color: pxSuccess, fontWeight: FontWeight.w700)),
                        ],
                      ),
                      const SizedBox(height: 12),
                      StreamBuilder<String?>(
                        stream: voteStream,
                        builder: (context, snapshot) {
                          final vote = snapshot.data;
                          return Row(
                            children: [
                              Expanded(
                                child: _voteButton(
                                  icon: Icons.thumb_up,
                                  title: 'Fiyat Doğru',
                                  subtitle: '${trust.approveCount} Onay',
                                  active: vote == 'yes',
                                  color: pxSuccess,
                                  onTap: () => notifier.votePrice(priceId: data.bestPrice.id, isApproved: true),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: _voteButton(
                                  icon: Icons.warning_amber,
                                  title: 'Hatalı',
                                  subtitle: '${trust.rejectCount} İtiraz',
                                  active: vote == 'no',
                                  color: pxAlert,
                                  onTap: onOpenReject,
                                ),
                              ),
                            ],
                          );
                        },
                      ),
                    ],
                  ),
                ),
              const SizedBox(height: 14),
              _module(
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Yorumlar', style: TextStyle(fontWeight: FontWeight.w800)),
                        Text('${data.comments.length} yorum', style: const TextStyle(fontSize: 12, color: pxTextMuted)),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: commentController,
                            decoration: const InputDecoration(
                              hintText: 'Fiyat hakkında yorum yap...',
                              filled: true,
                              fillColor: pxBg,
                              border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(24))),
                              isDense: true,
                            ),
                          ),
                        ),
                        IconButton(
                          onPressed: state.isSubmittingComment
                              ? null
                              : () async {
                                  final text = commentController.text.trim();
                                  if (text.isEmpty) return;
                                  final ok = await notifier.postComment(text);
                                  if (ok) commentController.clear();
                                },
                          icon: state.isSubmittingComment
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(strokeWidth: 2),
                                )
                              : const Icon(Icons.send),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    if (data.comments.isEmpty)
                      const Align(
                        alignment: Alignment.centerLeft,
                        child: Text('Henüz yorum yok.', style: TextStyle(color: pxTextMuted)),
                      )
                    else
                      ...data.comments.map((c) {
                        final name = c.author.trim().isEmpty ? 'Kullanıcı' : c.author;
                        final leading = name.characters.first.toUpperCase();
                        return Padding(
                          padding: const EdgeInsets.only(top: 12),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              CircleAvatar(backgroundColor: const Color(0xFFE6DED6), child: Text(leading)),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Expanded(
                                          child: Text(
                                            name,
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: const TextStyle(fontWeight: FontWeight.w700),
                                          ),
                                        ),
                                        Text(c.timeAgo, style: const TextStyle(fontSize: 11, color: pxTextMuted)),
                                      ],
                                    ),
                                    const SizedBox(height: 4),
                                    Text(c.text),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        );
                      }),
                  ],
                ),
              ),
            ]),
          ),
        ),
      ],
    );
  }

  Widget _module({required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: pxWhite,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0x14000000)),
      ),
      child: child,
    );
  }

  Widget _stat(String label, double value, Color color) {
    final valid = value > 0;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: pxTextMuted, fontSize: 11)),
        const SizedBox(height: 3),
        Text(valid ? '${value.toStringAsFixed(2)}₺' : '-', style: TextStyle(color: color, fontWeight: FontWeight.w800)),
      ],
    );
  }

  Widget _voteButton({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool active,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: active ? color.withOpacity(0.1) : pxBg,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: active ? color.withOpacity(0.4) : const Color(0x22000000)),
        ),
        child: Row(
          children: [
            Icon(icon, color: active ? color : pxTextMuted),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: TextStyle(fontWeight: FontWeight.w700, color: active ? color : pxTextMain)),
                  Text(subtitle, style: const TextStyle(fontSize: 11, color: pxTextMuted)),
                ],
              ),
            )
          ],
        ),
      ),
    );
  }
}

class _HeaderBtn extends StatelessWidget {
  const _HeaderBtn({required this.icon, required this.onTap, this.color = pxWhite});

  final IconData icon;
  final VoidCallback onTap;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        width: 38,
        height: 38,
        decoration: BoxDecoration(
          color: pxDarkBtn,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: color, size: 20),
      ),
    );
  }
}
