import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:image_picker/image_picker.dart';

import '../features/admin/illustration_picker/illustration_manifest_service.dart';
import '../features/admin/models/illustration_asset.dart';
import '../models/price_reporting.dart';
import '../models/product.dart';
import '../state/app_state.dart';
import '../ui/components.dart';
import '../ui/tokens.dart';
import 'main_screen.dart';
import 'paywall_screen.dart';
import 'widgets/product_comments_section.dart';
import 'widgets/product_visual.dart';

class ProductDetailScreen extends StatefulWidget {
  const ProductDetailScreen({super.key, required this.product});
  final Product product;

  @override
  State<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen> {
  final ScrollController _scroll = ScrollController();

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = AppStateScope.of(context);
    // Yorum/oy gibi yazma akışları AppState'i bildirir; ekranı sabit constructor
    // referansına bağlı tutarsak (widget.product) durum değişiklikleri (oy
    // sayısı, status, vs.) ancak ekrandan çıkıp tekrar girince görünür.
    // En güncel kopyayı her build'de katalogdan çek.
    final product = state.findById(widget.product.id) ?? widget.product;
    final sorted = [...product.priceHistory]
      ..sort((a, b) => b.date.compareTo(a.date));
    final best = product.bestValueEntry;
    final isFav = state.isFavorite(product.id);
    final alert = state.alertForProduct(product.id);

    return Scaffold(
      backgroundColor: FR.bg,
      // _Actions zaten kendi bottom safe area'sını ekliyor, bu nedenle
      // SafeArea bottom çift-padding üretmemeli; aksi halde ListView
      // aşağıdan kapanıp scroll'un en altı görünmüyor ve geri çıkamıyor.
      body: SafeArea(
        bottom: false,
        child: GestureDetector(
          // Comments composer veya rapor dialog'undan dönerken kalan focus
          // listview'in scroll gesture'ını yutuyordu — boş alana dokunulunca
          // klavyeyi/odağı bırak.
          behavior: HitTestBehavior.translucent,
          onTap: () => FocusScope.of(context).unfocus(),
          child: Column(
            children: [
              _DetailTopBar(
                isFav: isFav,
                onBack: () => Navigator.pop(context),
                onFav: () => state.toggleFavorite(product.id),
              ),
              Expanded(
                child: ListView(
                  controller: _scroll,
                  // `onDrag` davranışı klavyeyi aniden kapatıp layout'u
                  // değiştirdiği için kullanıcı yorum kutusunun yakınındayken
                  // aşağı/yukarı kaydırma sırasında scroll metric'leri sıçrıyor,
                  // pratikte "takılıyor" gibi hissediliyordu. `manual` ile
                  // GestureDetector'daki onTap → unfocus akışı zaten klavyeyi
                  // bırakıyor; scroll artık sıçramıyor.
                  keyboardDismissBehavior:
                      ScrollViewKeyboardDismissBehavior.manual,
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(20, 6, 20, 20),
                  children: [
                    _DetailTitleBlock(product: product),
                    const SizedBox(height: 16),
                    _DetailHero(product: product),
                    // Onaylı fotoğrafı olan ürünlerde "fotoğraf öner" çağrısı
                    // gizlenir; yalnızca henüz admin onaylı görseli olmayan
                    // ürünlerde topluluk öneri kartı gösterilir.
                    if (!product.hasApprovedImage) ...[
                      const SizedBox(height: 14),
                      _CommunityImageCta(product: product),
                    ],
                    const SizedBox(height: 20),
                    _DetailHeadlinePrice(product: product, state: state),
                    const SizedBox(height: 24),
                    _RegionalPriceSections(
                        product: product, state: state, legacyBest: best),
                  // Free planda son 7 gün, Pro'da son 12 ay (365 gün)
                  // fiyat geçmişi gösterilir. Daha önce eyebrow "Son 30
                  // gün" diyordu ama kod aslında tüm validEntries'i
                  // kullanıyordu — hem yalancı hem gate'siz. Şimdi metin
                  // ve veri tutarlı.
                  _PriceHistorySection(product: product, state: state),
                  const SizedBox(height: 24),
                  const FRSectionHead(
                      eyebrow: 'TOPLULUK DOĞRULAMASI',
                      title: 'Son katkılar'),
                  const SizedBox(height: 6),
                  Text(
                    'Oy ver, topluluğun güveni şekillendir. Kendi girdiğine ya da aynı girdiye tekrar oy veremezsin.',
                    style: frText(11.5, FontWeight.w600,
                        color: FR.ink3, height: 1.5),
                  ),
                  const SizedBox(height: 12),
                  if (sorted.isEmpty)
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: frSurface(radius: FRRad.l),
                      child: Text(
                        'Henüz katkı yok — ilk fiyatı sen ekle.',
                        style: frText(12.5, FontWeight.w600, color: FR.ink3),
                      ),
                    )
                  else
                    ...sorted.take(6).map((e) => Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: _ContributionRow(
                            product: product,
                            entry: e,
                            state: state,
                          ),
                        )),
                  const SizedBox(height: 24),
                  ProductCommentsSection(productId: product.id),
                ],
              ),
            ),
              _Actions(
                isAlertActive: alert != null,
                alertTarget: alert?.targetPrice,
                onAlert: () =>
                    _openAlert(context, state, product, alert?.targetPrice),
                onAdd: () {
                  // Ürün detaydan fiyat eklemeye geçerken ürünü Fiyat Ekle
                  // ekranına seçili taşı — kullanıcı yeniden aramasın.
                  debugPrint(
                    'ADD_PRICE_FROM_PRODUCT_DETAIL: productId=${product.id}',
                  );
                  try {
                    state.setAddPricePreset(productId: product.id);
                    debugPrint(
                      'ADD_PRICE_PREFILL_PRODUCT_SUCCESS: productId=${product.id}',
                    );
                  } catch (e) {
                    debugPrint(
                      'ADD_PRICE_PREFILL_PRODUCT_FAILED: productId=${product.id} '
                      'error=$e',
                    );
                  }
                  Navigator.of(context).pushReplacement(
                    MaterialPageRoute(
                        builder: (_) => const MainScreen(initialIndex: 2)),
                  );
                },
                onCart: () {
                  state.addToCart(product);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('${product.name} sepete eklendi.')),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _openAlert(
    BuildContext context,
    AppState state,
    Product product,
    double? current,
  ) async {
    debugPrint('PRICE_ALERT_DIALOG_OPENED: productId=${product.id}');
    final existing = state.alertForProduct(product.id);
    final res = await showDialog<_AlertDialogResult>(
      context: context,
      builder: (_) => _PriceAlertDialog(
        product: product,
        currentTarget: current ?? existing?.targetPrice,
        currentMode: existing?.mode ?? ProductAlertMode.belowTarget,
        freeUsage: state.productAlerts.length,
        isPremium: state.premium.isActive,
      ),
    );
    if (res == null) return;
    debugPrint(
      'PRICE_ALERT_MODE_SELECTED: mode=${productAlertModeToValue(res.mode)}',
    );
    try {
      await state.setProductAlert(
        productId: product.id,
        mode: res.mode,
        targetPrice: res.targetPrice,
      );
      if (!context.mounted) return;
      final messenger = ScaffoldMessenger.of(context);
      String successText;
      switch (res.mode) {
        case ProductAlertMode.belowTarget:
          successText =
              'Fiyat alarmın aktif edildi. ₺${(res.targetPrice ?? 0).toStringAsFixed(2)} altına düşünce haberin olacak.';
          break;
        case ProductAlertMode.priceDrop:
          successText =
              'Fiyat alarmın aktif edildi. Ürün için daha düşük fiyat bulunduğunda haberdar olacaksın.';
          break;
        case ProductAlertMode.anyNewPrice:
          successText =
              'Bu ürün için yeni fiyat eklendiğinde bildirim alacaksın.';
          break;
      }
      messenger.showSnackBar(SnackBar(content: Text(successText)));
    } on AlertLimitExceededException catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString()),
          action: SnackBarAction(
            label: 'Pro\'ya geç',
            textColor: FR.gold,
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const PaywallScreen()),
            ),
          ),
        ),
      );
    } on StateError catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message)),
      );
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Fiyat alarmı kurulamadı: $e'),
        ),
      );
    }
  }
}

class _AlertDialogResult {
  const _AlertDialogResult({required this.mode, this.targetPrice});
  final ProductAlertMode mode;
  final double? targetPrice;
}

class _PriceAlertDialog extends StatefulWidget {
  const _PriceAlertDialog({
    required this.product,
    required this.currentTarget,
    required this.currentMode,
    required this.freeUsage,
    required this.isPremium,
  });
  final Product product;
  final double? currentTarget;
  final ProductAlertMode currentMode;
  final int freeUsage;
  final bool isPremium;

  @override
  State<_PriceAlertDialog> createState() => _PriceAlertDialogState();
}

class _PriceAlertDialogState extends State<_PriceAlertDialog> {
  late ProductAlertMode _mode = widget.currentMode;
  late final TextEditingController _ctrl = TextEditingController(
    text: (widget.currentTarget ?? widget.product.lowestPrice ?? 0)
        .toStringAsFixed(2),
  );
  String? _error;

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final needsTarget = _mode == ProductAlertMode.belowTarget;
    return AlertDialog(
      backgroundColor: FR.surface,
      title: Text('Fiyat alarmı kur', style: frDisplay(20, FontWeight.w700)),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Bu ürün için nasıl bildirim almak istiyorsun?',
              style: frText(12.5, FontWeight.w600, color: FR.ink3),
            ),
            if (!widget.isPremium) ...[
              const SizedBox(height: 8),
              Text(
                'Ücretsiz planda '
                '${widget.freeUsage}/${AppState.kFreeProductAlertLimit} '
                'alarm kullanıldı. Sınırsız alarm Premium’da.',
                style: frText(11.5, FontWeight.w700, color: FR.ink2),
              ),
            ],
            const SizedBox(height: 12),
            _ModeRadio(
              value: ProductAlertMode.belowTarget,
              group: _mode,
              title: 'Hedef fiyatın altına düşünce',
              subtitle: 'Belirlediğin tutarın altına düşen her yeni fiyatta '
                  'bildirim al.',
              onChanged: (v) => setState(() => _mode = v),
            ),
            _ModeRadio(
              value: ProductAlertMode.priceDrop,
              group: _mode,
              title: 'Fiyat düşünce',
              subtitle: 'Bu ürün için bilinen fiyatın altına bir teklif '
                  'geldiğinde bildirim al.',
              onChanged: (v) => setState(() => _mode = v),
            ),
            _ModeRadio(
              value: ProductAlertMode.anyNewPrice,
              group: _mode,
              title: 'Her yeni fiyat geldiğinde',
              subtitle: 'Bu ürüne her yeni fiyat eklendiğinde bildirim alırsın.',
              onChanged: (v) => setState(() => _mode = v),
            ),
            if (needsTarget) ...[
              const SizedBox(height: 14),
              TextField(
                controller: _ctrl,
                autofocus: true,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                style: frPrice(20),
                cursorColor: FR.gold,
                decoration: InputDecoration(
                  prefixText: '₺ ',
                  prefixStyle:
                      TextStyle(color: FR.gold, fontWeight: FontWeight.w800),
                  errorText: _error,
                ),
                onChanged: (_) {
                  if (_error != null) setState(() => _error = null);
                },
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text('İptal',
              style: frText(13, FontWeight.w800, color: FR.ink3)),
        ),
        TextButton(
          onPressed: () {
            if (_mode == ProductAlertMode.belowTarget) {
              final v = double.tryParse(_ctrl.text.replaceAll(',', '.'));
              if (v == null || v <= 0) {
                setState(() => _error = 'Geçerli bir fiyat gir.');
                return;
              }
              Navigator.pop(
                context,
                _AlertDialogResult(mode: _mode, targetPrice: v),
              );
              return;
            }
            Navigator.pop(
              context,
              _AlertDialogResult(mode: _mode),
            );
          },
          child: Text('Kaydet',
              style: frText(13, FontWeight.w800, color: FR.gold)),
        ),
      ],
    );
  }
}

class _ModeRadio extends StatelessWidget {
  const _ModeRadio({
    required this.value,
    required this.group,
    required this.title,
    required this.subtitle,
    required this.onChanged,
  });
  final ProductAlertMode value;
  final ProductAlertMode group;
  final String title;
  final String subtitle;
  final ValueChanged<ProductAlertMode> onChanged;

  @override
  Widget build(BuildContext context) {
    final selected = group == value;
    return InkWell(
      onTap: () => onChanged(value),
      borderRadius: FRRad.all(FRRad.m),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6), // LEGACY_EXCEPTION: reason=token_migration owner=codex remove_by=2026-06-30
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 2), // LEGACY_EXCEPTION: reason=token_migration owner=codex remove_by=2026-06-30
              child: Icon(
                selected
                    ? Icons.radio_button_checked
                    : Icons.radio_button_off,
                color: selected ? FR.gold : FR.ink3,
                size: 18,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: frText(13, FontWeight.w800,
                          color: selected ? FR.ink : FR.ink2)),
                  const SizedBox(height: 2),
                  Text(subtitle,
                      style: frText(11.5, FontWeight.w600, color: FR.ink3)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Top bar ─────────────────────────────────────────────────────────────────

class _DetailTopBar extends StatelessWidget {
  const _DetailTopBar({
    required this.isFav,
    required this.onBack,
    required this.onFav,
  });
  final bool isFav;
  final VoidCallback onBack;
  final VoidCallback onFav;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
      child: Row(
        children: [
          FRIconChip(icon: Icons.arrow_back_rounded, onTap: onBack),
          const Spacer(),
          FRIconChip(
            icon: isFav
                ? Icons.favorite_rounded
                : Icons.favorite_outline_rounded,
            active: isFav,
            onTap: onFav,
          ),
        ],
      ),
    );
  }
}

// ─── Title block (page entry rhythm: eyebrow + page title) ──────────────────

class _DetailTitleBlock extends StatelessWidget {
  const _DetailTitleBlock({required this.product});
  final Product product;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '${product.category.toUpperCase()} · ${product.brand.toUpperCase()}',
          style: frOverline(color: FR.ink3),
        ),
        const SizedBox(height: 6),
        Text(product.name,
            style: frDisplay(28, FontWeight.w700, height: 1.1)),
        const SizedBox(height: 6),
        Row(
          children: [
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
              decoration: BoxDecoration(
                color: FR.gold.withOpacity(.14),
                borderRadius: FRRad.all(999),
                border: Border.all(color: FR.gold.withOpacity(.4)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.verified_rounded, color: FR.gold, size: 12),
                  const SizedBox(width: 5),
                  Text('Katalog ürünü',
                      style: frText(10.5, FontWeight.w800, color: FR.gold)),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Flexible(
              child: Text(product.unit,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: frText(12.5, FontWeight.w700, color: FR.ink3)),
            ),
          ],
        ),
      ],
    );
  }
}

// ─── Hero image (clean Soft Surface, no competing gold border) ───────────────

class _DetailHero extends StatelessWidget {
  const _DetailHero({required this.product});
  final Product product;

  @override
  Widget build(BuildContext context) {
    final hasImage = product.hasApprovedImage;
    return Container(
      height: 220,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [FR.surfaceHi, FR.surfaceLo],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: FRRad.all(FRRad.xxl),
        border: Border.all(color: FR.hairline),
      ),
      child: Stack(
        fit: StackFit.expand,
        children: [
          if (hasImage)
            Image.network(
              product.imageUrl!,
              fit: BoxFit.cover,
              cacheWidth: 1200,
              cacheHeight: 1200,
              filterQuality: FilterQuality.medium,
              frameBuilder: frFadeFrameBuilder,
              errorBuilder: (_, __, ___) =>
                  _CategoryIllustrationFallback(product: product),
            )
          else
            _CategoryIllustrationFallback(product: product),
          // Onaylı bir ürün fotoğrafı varsa köşede küçük bir "Onaylı
          // fotoğraf" rozeti göster; illüstrasyon fallback'inde gösterilmez.
          if (hasImage)
            const Positioned(
              left: 10,
              bottom: 10,
              child: _ApprovedPhotoBadge(),
            ),
        ],
      ),
    );
  }
}

/// Küçük "Onaylı fotoğraf" rozeti — yalnızca admin onaylı gerçek ürün
/// fotoğrafı olan ürün kahramanında (hero) gösterilir.
class _ApprovedPhotoBadge extends StatelessWidget {
  const _ApprovedPhotoBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: FR.bg.withOpacity(.74),
        borderRadius: FRRad.all(999),
        border: Border.all(color: FR.gold.withOpacity(.45)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.verified_rounded, size: 12, color: FR.gold),
          const SizedBox(width: 5),
          Text('Onaylı fotoğraf',
              style: frText(10, FontWeight.w800, color: FR.gold)),
        ],
      ),
    );
  }
}

/// Renders the brand-agnostic illustration assigned to the product by an
/// admin. Falls back to a quiet container with an inline icon when no
/// illustration is set so the product hero still feels intentional.
class _CategoryIllustrationFallback extends StatelessWidget {
  const _CategoryIllustrationFallback({required this.product});
  final Product product;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<IllustrationManifest>(
      future: IllustrationManifestService.load(),
      builder: (context, snap) {
        final manifest = snap.data;
        if (manifest == null) return const SizedBox.shrink();
        final asset = resolveProductIllustration(manifest, product);
        if (asset == null) return const SizedBox.shrink();
        return Padding(
          padding: const EdgeInsets.all(28),
          child: SvgPicture.asset(
            asset.assetPath,
            fit: BoxFit.contain,
            semanticsLabel: asset.label,
          ),
        );
      },
    );
  }
}

// ─── Headline price (the single dominant emphasis block) ─────────────────────

class _DetailHeadlinePrice extends StatelessWidget {
  const _DetailHeadlinePrice({required this.product, required this.state});
  final Product product;
  final AppState state;

  @override
  Widget build(BuildContext context) {
    final lowest = product.lowestPrice;
    final pct = product.priceChangePct;
    final store = product.cheapestStore;
    final verified = product.verifiedCount;
    final trust = product.aggregateTrustPercent;
    final dataPoints = product.validEntries.length;

    if (lowest == null) {
      return Container(
        padding: const EdgeInsets.all(18),
        decoration: frSurface(radius: FRRad.xl),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: FR.bgElev,
                borderRadius: FRRad.all(14),
                border: Border.all(color: FR.hairline),
              ),
              child: Icon(Icons.timer_outlined, color: FR.ink3, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Fiyat bekleniyor',
                      style: frText(14, FontWeight.w800, color: FR.ink)),
                  const SizedBox(height: 2),
                  Text('Topluluktan ilk fiyatı sen ekleyebilirsin.',
                      style:
                          frText(11.5, FontWeight.w600, color: FR.ink3)),
                ],
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [FR.surfaceHi, FR.surfaceLo],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: FRRad.all(FRRad.xxl),
        border: Border.all(color: FR.goldDeep.withOpacity(.4)),
        boxShadow: frGoldGlow(opacity: .14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Flexible(
                child: Text('TOPLULUKTAN EN İYİ FİYAT', style: frOverline()),
              ),
              const SizedBox(width: 6),
              InkWell(
                onTap: () => showTrustInfoSheet(context),
                borderRadius: FRRad.all(999),
                child: Padding(
                  padding: const EdgeInsets.all(2), // LEGACY_EXCEPTION: reason=token_migration owner=codex remove_by=2026-06-30
                  child: Icon(Icons.info_outline_rounded,
                      size: 14, color: FR.ink3),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              FRPriceText(lowest, size: 38, color: FR.gold),
              const SizedBox(width: 10),
              if (pct != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: FRTrendPill(pct: pct),
                ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              if (store != null) FRStoreBadge(store, filled: true),
              if (verified > 0)
                FRVerifyBadge(
                  label: '$verified doğrulandı',
                  tone: FRVerifyTone.good,
                  trustPercent: trust,
                  dense: true,
                )
              else
                FRVerifyBadge(
                  label: trust >= 50 ? 'İncelemede' : 'Yeni',
                  tone: FRVerifyTone.neutral,
                  trustPercent: trust,
                  dense: true,
                ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                decoration: BoxDecoration(
                  color: FR.bgElev,
                  borderRadius: FRRad.all(999),
                  border: Border.all(color: FR.hairline),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.bar_chart_rounded, size: 12, color: FR.ink2),
                    const SizedBox(width: 4),
                    Text('$dataPoints veri noktası',
                        style: frText(10.5, FontWeight.w800, color: FR.ink2)),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// "Güven yüzdesi nedir?" açıklaması — kullanıcı dostu, teknik formül yok.
/// Headline fiyat kartındaki info ikonu bunu açar.
void showTrustInfoSheet(BuildContext context) {
  showModalBottomSheet<void>(
    context: context,
    backgroundColor: FR.surface,
    showDragHandle: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(FRRad.xl)),
    ),
    builder: (ctx) => Padding(
      padding: EdgeInsets.fromLTRB( // LEGACY_EXCEPTION: reason=token_migration owner=codex remove_by=2026-06-30
          22, 4, 22, 24 + MediaQuery.of(ctx).padding.bottom),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.verified_rounded, color: FR.gold, size: 22),
              const SizedBox(width: 10),
              Text('Güven yüzdesi nedir?',
                  style: frDisplay(20, FontWeight.w800)),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            'Bu oran; fiyatın doğrulanma sayısı, ekleyen kullanıcının güven '
            'skoru, fotoğraf kanıtı ve topluluk geri bildirimleri gibi '
            'sinyallerle hesaplanır.',
            style: frText(13, FontWeight.w600, color: FR.ink2, height: 1.55),
          ),
          const SizedBox(height: 12),
          Text(
            'Daha yüksek güven, fiyatın daha güncel ve doğrulanmış olma '
            'ihtimalinin yüksek olduğunu gösterir.',
            style: frText(13, FontWeight.w600, color: FR.ink2, height: 1.55),
          ),
          const SizedBox(height: 12),
          Text(
            'Yanlış veya güncel olmayan bir fiyat görürsen “Yanlış fiyat '
            'bildir” ile topluluğa bildirebilirsin.',
            style: frText(12.5, FontWeight.w600, color: FR.ink3, height: 1.5),
          ),
        ],
      ),
    ),
  );
}

// ─── Regional price sections ────────────────────────────────────────────────

class _RegionalPriceSections extends StatefulWidget {
  const _RegionalPriceSections({
    required this.product,
    required this.state,
    required this.legacyBest,
  });

  final Product product;
  final AppState state;
  final PriceEntry? legacyBest;

  @override
  State<_RegionalPriceSections> createState() => _RegionalPriceSectionsState();
}

class _RegionalPriceSectionsState extends State<_RegionalPriceSections> {
  // Bölgesel fiyat grubu stream'i, sorgu anahtarına göre cache'lenir. Ürün
  // detay ekranı `AppStateScope` (InheritedNotifier) dinlediği için her oy /
  // yorum / Firestore güncellemesinde build yeniden çalışır. Stream inline
  // kurulursa her build YENİ bir stream üretir; StreamBuilder aboneliği
  // yenileyip iskelet (124px×3) durumuna düşer, sonra dolu kartlara döner —
  // bu yükseklik salınımı scroll pozisyonunu yukarıda zıplatıp "yukarı
  // çıkamıyorum / sonsuz döngü" hissine yol açar. Aynı ürün/bölge için
  // stream'i tekrar kullan; yalnız anahtar değişince yeniden oluştur.
  Stream<List<PriceGroupModel>>? _groupStream;
  String? _groupKey;

  Stream<List<PriceGroupModel>> _groupsFor(
    AppState state, {
    required String productId,
    required String city,
    required String district,
  }) {
    final key = '$productId|$city|$district';
    if (_groupKey != key || _groupStream == null) {
      _groupKey = key;
      _groupStream = state.watchRegionalPriceGroups(
        productId: productId,
        city: city,
        district: district,
      );
    }
    return _groupStream!;
  }

  @override
  Widget build(BuildContext context) {
    final product = widget.product;
    final state = widget.state;
    final legacyBest = widget.legacyBest;
    final city = (state.cityName ?? '').trim();
    final district = (state.districtName ?? '').trim();
    final hasRegion = city.isNotEmpty && district.isNotEmpty;
    if (!hasRegion) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const FRSectionHead(
              eyebrow: 'BÖLGENDEKİ FİYATLAR',
              title: 'Önce bölgeni belirt'),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: frSurface(radius: FRRad.l),
            child: Row(
              children: [
                Icon(Icons.location_on_outlined, color: FR.ink3, size: 18),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Bölgesel fiyatları görmek için anasayfadan il ve ilçe seç.',
                    style: frText(12, FontWeight.w600,
                        color: FR.ink3, height: 1.4),
                  ),
                ),
              ],
            ),
          ),
        ],
      );
    }

    return StreamBuilder<List<PriceGroupModel>>(
      stream: _groupsFor(
        state,
        productId: product.id,
        city: city,
        district: district,
      ),
      builder: (context, snap) {
        // Snapshot data gelmediyse skeleton göster — kısa "yok" yanılsaması
        // yerine "yükleniyor" hissini ver. (Audit: empty/loading karışıyordu.)
        if (snap.connectionState == ConnectionState.waiting &&
            !snap.hasData) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              FRSectionHead(
                eyebrow: 'BÖLGENDEKİ FİYATLAR',
                title: '$district / $city',
              ),
              const SizedBox(height: 12),
              const FRSkeletonList(count: 3, itemHeight: 124, radius: 18),
            ],
          );
        }
        final groups = snap.data ?? const <PriceGroupModel>[];
        if (groups.isEmpty) {
          // Bölgemde fiyat grubu yok → kullanıcıya pasif "yok" yerine
          // motive edici bir CTA ver: "ilk fiyatı sen ekle" + (varsa)
          // legacy referans + Türkiye genelinde son fiyat referansı
          // (eğer eklenmişse "diğer bölgelerde nasıl?" hissi).
          return _RegionalEmptyCta(
            product: product,
            district: district,
            city: city,
            legacyBest: legacyBest,
            state: state,
          );
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            FRSectionHead(
              eyebrow: 'BÖLGENDEKİ FİYATLAR',
              title: '$district / $city',
              action: Text(
                '${groups.length} market',
                style: frText(11, FontWeight.w800, color: FR.ink3),
              ),
            ),
            const SizedBox(height: 12),
            ...groups.take(4).map((g) => Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: _RegionalGroupCard(group: g, product: product),
                )),
          ],
        );
      },
    );
  }
}

class _RegionalGroupCard extends StatelessWidget {
  const _RegionalGroupCard({required this.group, required this.product});

  final PriceGroupModel group;
  final Product product;

  String _relative(DateTime? date) {
    if (date == null) return 'Tarih yok';
    final days = DateTime.now().difference(date).inDays;
    if (days <= 0) return 'Bugün bildirildi';
    if (days == 1) return 'Dün bildirildi';
    return '$days gün önce';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: frSurface(radius: FRRad.l),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(group.chainName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: frText(13.5, FontWeight.w800)),
                    const SizedBox(height: 2),
                    Text(
                      '${group.districtName} / ${group.cityName}',
                      style: frText(11, FontWeight.w700, color: FR.ink3),
                    ),
                  ],
                ),
              ),
              FRPriceText(
                group.preferredPrice ?? group.latestPrice,
                size: 18,
                color: FR.gold,
              ),
            ],
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              _MetaPill(
                icon: Icons.schedule_rounded,
                label: _relative(group.lastReportedAt),
              ),
              _MetaPill(
                icon: Icons.shield_outlined,
                label: confidenceLabelTr(group.confidence),
              ),
              _MetaPill(
                icon: Icons.people_outline_rounded,
                label: '${group.reportCount} bildirim',
              ),
              if (group.verifiedCount > 0)
                _MetaPill(
                  icon: Icons.verified_rounded,
                  label: '${group.verifiedCount} doğrulama',
                  tone: FR.good,
                ),
              if (group.hasPhotoEvidence)
                _MetaPill(
                  icon: Icons.photo_camera_rounded,
                  label: '${group.photoReportCount} fotoğraflı',
                ),
            ],
          ),
          const SizedBox(height: 12),
          Builder(builder: (ctx) {
            final state = AppStateScope.of(ctx);
            // Region-mismatch'te sessizce fail bırakmak yerine butonu disable
            // edip sebebini badge olarak göster — kullanıcı baştan görsün.
            final blockReason = state.canVerifyRegionalPrice(
              city: group.cityName,
              district: group.districtName,
            );
            return Row(
              children: [
                Expanded(
                  child: _TinyAction(
                    icon: Icons.thumb_up_alt_outlined,
                    label: blockReason == null
                        ? 'Ben de gördüm'
                        : 'Bölgen değil',
                    enabled: blockReason == null,
                    onTap: () async {
                      try {
                        await state.verifyRegionalPriceSeen(
                          productId: product.id,
                          chainId: group.chainId,
                          price: group.preferredPrice ??
                              group.latestPrice ??
                              0,
                          city: group.cityName,
                          district: group.districtName,
                        );
                        if (!ctx.mounted) return;
                        ScaffoldMessenger.of(ctx).showSnackBar(
                          const SnackBar(
                              content: Text('Doğrulaman kaydedildi.')),
                        );
                      } catch (e) {
                        if (!ctx.mounted) return;
                        ScaffoldMessenger.of(ctx).showSnackBar(
                          SnackBar(content: Text('$e')),
                        );
                      }
                    },
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _TinyAction(
                    icon: Icons.edit_outlined,
                    label: 'Farklı fiyat',
                    onTap: () async {
                      // Eskiden bölgeyi sessizce karşı gruba çekiyorduk —
                      // Adana'daki kullanıcı Ankara grubunda "farklı fiyat"
                      // deyince home/feed'i Ankara'ya kayıyordu. Artık
                      // kullanıcıya "kendi bölgen mi, grup bölgesi mi?"
                      // diye soruyoruz.
                      final myCity = (state.cityName ?? '').trim();
                      final myDistrict = (state.districtName ?? '').trim();
                      final regionDiffers = myCity.toLowerCase() !=
                              group.cityName.trim().toLowerCase() ||
                          myDistrict.toLowerCase() !=
                              group.districtName.trim().toLowerCase();
                      if (regionDiffers) {
                        final useGroupRegion = await showDialog<bool>(
                          context: ctx,
                          builder: (_) => AlertDialog(
                            title: const Text(
                                'Bölgeyi değiştirmek ister misin?'),
                            content: Text(
                              'Bu fiyat ${group.districtName} / ${group.cityName} için. '
                              'Senin bölgen ${myDistrict.isEmpty ? "—" : "$myDistrict / $myCity"}. '
                              'Farklı fiyatı hangi bölgeye ekleyelim?',
                            ),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(ctx, false),
                                child: Text(myDistrict.isEmpty
                                    ? 'Önce bölgemi seç'
                                    : 'Kendi bölgem'),
                              ),
                              TextButton(
                                onPressed: () => Navigator.pop(ctx, true),
                                child: Text(
                                    '${group.districtName} / ${group.cityName}'),
                              ),
                            ],
                          ),
                        );
                        if (useGroupRegion == null) return;
                        if (useGroupRegion) {
                          await state.updateRegionSettings(
                            cityName: group.cityName,
                            districtName: group.districtName,
                          );
                        }
                      }
                      state.setAddPricePreset(
                        productId: product.id,
                        chainId: group.chainId,
                        chainName: group.chainName,
                      );
                      if (!ctx.mounted) return;
                      Navigator.of(ctx).pushReplacement(
                        MaterialPageRoute(
                            builder: (_) =>
                                const MainScreen(initialIndex: 2)),
                      );
                    },
                  ),
                ),
              ],
            );
          }),
        ],
      ),
    );
  }
}

/// Bölgemde fiyat grubu yokken görünen "ilk fiyatı sen ekle" CTA'sı.
/// Eskiden tek satırlık pasif text vardı — kullanıcıyı action'a yönlendiren
/// premium bir kart aslında 0 katkıdan ilk katkıyı bu kullanıcıdan
/// almak için en güçlü tetikleyici.
class _RegionalEmptyCta extends StatelessWidget {
  const _RegionalEmptyCta({
    required this.product,
    required this.district,
    required this.city,
    required this.legacyBest,
    required this.state,
  });
  final Product product;
  final String district;
  final String city;
  final PriceEntry? legacyBest;
  final AppState state;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        FRSectionHead(
          eyebrow: 'BÖLGENDEKİ FİYATLAR',
          title: '$district / $city',
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [FR.surfaceHi, FR.surfaceLo],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: FRRad.all(FRRad.xl),
            border: Border.all(color: FR.goldDeep.withOpacity(.4)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(children: [
                Container(
                  width: 38,
                  height: 38,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: FR.gold.withOpacity(.16),
                    borderRadius: FRRad.all(12),
                    border: Border.all(color: FR.gold.withOpacity(.45)),
                  ),
                  child: Icon(Icons.radar_rounded,
                      color: FR.gold, size: 19),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text('İlk fiyatı sen ekleyebilirsin',
                      style: frDisplay(18, FontWeight.w700)),
                ),
              ]),
              const SizedBox(height: 10),
              Text(
                legacyBest == null
                    ? '$district / $city için henüz bildirilen fiyat yok. '
                        'Topluluğun bu bölgedeki radarını sen aç.'
                    : '$district / $city için bölgesel grup yok. '
                        'Son topluluk fiyatı: ₺${legacyBest!.price.toStringAsFixed(2)} · '
                        '${legacyBest!.store}.',
                style: frText(12, FontWeight.w600,
                    color: FR.ink3, height: 1.5),
              ),
              const SizedBox(height: 14),
              FRCta(
                label: 'Bu ürüne fiyat ekle · +10 PT',
                icon: Icons.add_rounded,
                onTap: () {
                  debugPrint(
                    'ADD_PRICE_FROM_PRODUCT_DETAIL: productId=${product.id}',
                  );
                  try {
                    state.setAddPricePreset(productId: product.id);
                    debugPrint(
                      'ADD_PRICE_PREFILL_PRODUCT_SUCCESS: productId=${product.id}',
                    );
                  } catch (e) {
                    debugPrint(
                      'ADD_PRICE_PREFILL_PRODUCT_FAILED: productId=${product.id} '
                      'error=$e',
                    );
                  }
                  Navigator.of(context).pushReplacement(
                    MaterialPageRoute(
                        builder: (_) => const MainScreen(initialIndex: 2)),
                  );
                },
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _MetaPill extends StatelessWidget {
  const _MetaPill({required this.icon, required this.label, this.tone});
  final IconData icon;
  final String label;
  final Color? tone;

  @override
  Widget build(BuildContext context) {
    final c = tone ?? FR.ink2;
    final bg = tone == null ? FR.bgElev : tone!.withOpacity(.12);
    final border = tone == null ? FR.hairline : tone!.withOpacity(.35);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: FRRad.all(999),
        border: Border.all(color: border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 11, color: c),
          const SizedBox(width: 4),
          Text(label, style: frText(10.5, FontWeight.w800, color: c)),
        ],
      ),
    );
  }
}

class _TinyAction extends StatelessWidget {
  const _TinyAction({
    required this.label,
    required this.onTap,
    this.icon,
    this.enabled = true,
  });

  final String label;
  final IconData? icon;
  final VoidCallback onTap;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final color = enabled ? FR.ink2 : FR.ink3;
    return InkWell(
      onTap: enabled ? onTap : null,
      borderRadius: FRRad.all(12),
      child: Opacity(
        opacity: enabled ? 1 : 0.55,
        child: Container(
          height: 38,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: FR.bgElev,
            borderRadius: FRRad.all(12),
            border: Border.all(color: FR.hairline),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (icon != null) ...[
                Icon(icon, size: 13, color: color),
                const SizedBox(width: 6),
              ],
              Flexible(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: frText(11, FontWeight.w800, color: color),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Ürün detayında "Fiyat geçmişi" bölümü. Pencere genişliği plana bağlı:
/// Free → son 7 gün, Pro → son 12 ay. Pencerede en az iki veri noktası
/// yoksa hiçbir şey çizmiyoruz (sparkline tek noktayla anlamlı değil).
class _PriceHistorySection extends StatelessWidget {
  const _PriceHistorySection({required this.product, required this.state});
  final Product product;
  final AppState state;

  @override
  Widget build(BuildContext context) {
    final isPro = state.premium.isActive;
    final windowDays = isPro ? 365 : 7;
    final cutoff = DateTime.now().subtract(Duration(days: windowDays));
    final windowEntries = product.validEntries
        .where((e) => e.date.isAfter(cutoff))
        .toList();
    if (windowEntries.length < 2) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 24),
        FRSectionHead(
          eyebrow: 'FİYAT GEÇMİŞİ',
          title: isPro ? 'Son 12 ay' : 'Son 7 gün',
        ),
        const SizedBox(height: 12),
        _PriceHistoryCard(entries: windowEntries),
        if (!isPro) ...[
          const SizedBox(height: 10),
          _PriceHistoryUpsell(),
        ],
      ],
    );
  }
}

class _PriceHistoryCard extends StatelessWidget {
  const _PriceHistoryCard({required this.entries});
  final List<PriceEntry> entries;

  @override
  Widget build(BuildContext context) {
    final sorted = [...entries]..sort((a, b) => a.date.compareTo(b.date));
    final values = sorted.map((e) => e.price).toList();
    final high = values.reduce((a, b) => a > b ? a : b);
    final low = values.reduce((a, b) => a < b ? a : b);
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: frSurface(radius: FRRad.xl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text('${values.length} veri noktası',
                  style: frText(11, FontWeight.w800, color: FR.ink3)),
              const Spacer(),
              Text('FARK · ₺${(high - low).toStringAsFixed(2)}',
                  style: frText(11, FontWeight.w800,
                      color: FR.goldDeep, letter: .8)),
            ],
          ),
          const SizedBox(height: 12),
          FRSparkline(values: values, height: 64),
          const SizedBox(height: 12),
          Row(
            children: [
              _hl('EN DÜŞÜK', '₺${low.toStringAsFixed(2)}', FR.good),
              const SizedBox(width: 10),
              _hl('EN YÜKSEK', '₺${high.toStringAsFixed(2)}', FR.bad),
              const SizedBox(width: 10),
              _hl('ORTALAMA',
                  '₺${(values.reduce((a, b) => a + b) / values.length).toStringAsFixed(2)}',
                  FR.gold),
            ],
          ),
        ],
      ),
    );
  }

  Widget _hl(String l, String v, Color c) => Expanded(
        child: Container(
          padding:
              const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          decoration: BoxDecoration(
            color: FR.bgElev,
            borderRadius: FRRad.all(10),
            border: Border.all(color: FR.hairline),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(l, style: frOverline(color: FR.ink3, size: 9)),
              const SizedBox(height: 2),
              Text(v, style: frPrice(14, color: c)),
            ],
          ),
        ),
      );
}

/// Free kullanıcıya 7 günlük geçmiş kartının altında gösterilen tek-satırlık
/// upsell. Pro'da 12 ay penceresi ve trend açılır.
class _PriceHistoryUpsell extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const PaywallScreen()),
      ),
      borderRadius: FRRad.all(FRRad.m),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10), // LEGACY_EXCEPTION: reason=token_migration owner=codex remove_by=2026-06-30
        decoration: BoxDecoration(
          color: FR.gold.withOpacity(.10),
          borderRadius: FRRad.all(FRRad.m),
          border: Border.all(color: FR.gold.withOpacity(.4)),
        ),
        child: Row(children: [
          Icon(Icons.show_chart_rounded, size: 16, color: FR.gold),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              '12 aylık grafik ve trend için Pro',
              style: frText(12, FontWeight.w800, color: FR.ink, height: 1.3),
            ),
          ),
          const FRProBadge(compact: true),
          const SizedBox(width: 6),
          Icon(Icons.arrow_forward_rounded, size: 14, color: FR.gold),
        ]),
      ),
    );
  }
}

class _ContributionRow extends StatefulWidget {
  const _ContributionRow({
    required this.product,
    required this.entry,
    required this.state,
  });
  final Product product;
  final PriceEntry entry;
  final AppState state;

  @override
  State<_ContributionRow> createState() => _ContributionRowState();
}

class _ContributionRowState extends State<_ContributionRow> {
  bool _busy = false;

  Future<void> _report() async {
    final ctrl = TextEditingController();
    final reason = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: FR.surface,
        title: Text('Yanlış fiyat bildir', style: frDisplay(20, FontWeight.w700)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Bu fiyat güncel değilse veya hatalıysa, topluluğun güvenini '
              'korumak için bize bildirebilirsin.',
              style: frText(12.5, FontWeight.w600, color: FR.ink3, height: 1.45),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: ctrl,
              maxLines: 3,
              decoration: InputDecoration(
                hintText: 'Kısa not (opsiyonel)',
                hintStyle: frText(12, FontWeight.w600, color: FR.ink3),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('İptal',
                style: frText(12.5, FontWeight.w800, color: FR.ink3)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, ctrl.text.trim()),
            child: Text('Raporla',
                style: frText(12.5, FontWeight.w800, color: FR.gold)),
          ),
        ],
      ),
    );
    ctrl.dispose();
    if (reason == null) return;
    try {
      await widget.state.reportPriceEntry(
        product: widget.product,
        entry: widget.entry,
        reason: reason,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Fiyat raporu iletildi.')),
      );
    } on StateError catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message)),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Rapor gönderilemedi, tekrar dene.')),
      );
    }
  }

  Future<void> _cast(VoteKind kind) async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      await widget.state.voteOnPrice(
        product: widget.product,
        entry: widget.entry,
        kind: kind,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(kind == VoteKind.up
              ? 'Oyunu kaydettik · +1 PT'
              : 'Yanlış olarak işaretlendi · +1 PT'),
        ),
      );
    } on StateError catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message)),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Oy gönderilemedi, tekrar dene.')),
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final entry = widget.entry;
    final state = widget.state;
    final uid = state.user?.uid ?? '';
    final myVote = entry.voteOf(uid);
    final disabledReason = state.canVoteOn(widget.product, entry);

    // Two-tier layout — top row carries the price + identity, bottom row
    // is reserved for the vote/report action set. The previous version
    // crammed everything into a single block of mixed-priority chips.
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 12, 8, 12),
      decoration: frSurface(radius: FRRad.l),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        FRPriceText(entry.price, size: 20, color: FR.ink),
                        const SizedBox(width: 8),
                        FRFreshChip(date: entry.date),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Flexible(child: FRStoreBadge(entry.store)),
                        const SizedBox(width: 6),
                        FRVerifyBadge.status(
                          status: statusToString(entry.status),
                          trustPercent: entry.trustPercent,
                          dense: true,
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            entry.reportedBy,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: frText(11.5, FontWeight.w700,
                                color: FR.ink3),
                          ),
                        ),
                        if (entry.reporterIsPro) ...[
                          const SizedBox(width: 6),
                          const FRProBadge(),
                        ],
                        if (entry.reporterTrustPercent != null) ...[
                          const SizedBox(width: 6),
                          FRTrustPill(
                            percent: entry.reporterTrustPercent!,
                            dense: true,
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed: _busy ? null : _report,
                icon: Icon(Icons.flag_outlined, size: 18, color: FR.ink3),
                tooltip: 'Yanlış fiyat bildir',
                visualDensity: VisualDensity.compact,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
              ),
            ],
          ),
          if (entry.note.isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(
              entry.note,
              style: frText(12, FontWeight.w600, color: FR.ink2, height: 1.4),
            ),
          ],
          const SizedBox(height: 10),
          Container(height: 1, color: FR.hairlineSoft),
          const SizedBox(height: 10),
          Padding(
            padding: const EdgeInsets.only(right: 6),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    _subtitle(entry, disabledReason, myVote),
                    style: frText(10.5, FontWeight.w700,
                        color: FR.ink3, height: 1.4),
                  ),
                ),
                if (_busy)
                  SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: FR.gold),
                  )
                else
                  FRVoteButtons(
                    currentVote: myVote,
                    disabledReason: disabledReason,
                    onUp: () => _cast(VoteKind.up),
                    onDown: () => _cast(VoteKind.down),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _subtitle(PriceEntry e, String? disabledReason, String? myVote) {
    if (disabledReason != null) return disabledReason;
    final tally = '${e.verifiedByCount} onay · ${e.rejectedByCount} itiraz';
    if (myVote != null) {
      return 'Oyun: ${myVote == 'up' ? 'doğru' : 'yanlış'} · $tally';
    }
    return tally;
  }
}

// ─── Sticky bottom actions ───────────────────────────────────────────────────

class _Actions extends StatelessWidget {
  const _Actions({
    required this.isAlertActive,
    required this.alertTarget,
    required this.onAlert,
    required this.onAdd,
    required this.onCart,
  });
  final bool isAlertActive;
  final double? alertTarget;
  final VoidCallback onAlert;
  final VoidCallback onAdd;
  final VoidCallback onCart;

  @override
  Widget build(BuildContext context) {
    final safe = MediaQuery.of(context).viewPadding.bottom;
    return Container(
      padding: EdgeInsets.fromLTRB(20, 12, 20, 12 + safe),
      decoration: BoxDecoration(
        color: FR.bgElev,
        border: Border(top: BorderSide(color: FR.hairline)),
      ),
      child: Row(
        children: [
          _SquareIconAction(
            icon: isAlertActive
                ? Icons.notifications_active_rounded
                : Icons.notifications_none_rounded,
            label: isAlertActive
                ? '₺${alertTarget!.toStringAsFixed(0)}'
                : null,
            active: isAlertActive,
            onTap: onAlert,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: FRCta(
              label: 'Sepete ekle',
              icon: Icons.shopping_basket_outlined,
              onTap: onCart,
            ),
          ),
          const SizedBox(width: 10),
          _SquareIconAction(
            icon: Icons.add_rounded,
            active: false,
            filled: true,
            onTap: onAdd,
          ),
        ],
      ),
    );
  }
}

class _SquareIconAction extends StatelessWidget {
  const _SquareIconAction({
    required this.icon,
    required this.onTap,
    this.label,
    this.active = false,
    this.filled = false,
  });
  final IconData icon;
  final String? label;
  final bool active;
  final bool filled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final bg = filled
        ? FR.gold
        : active
            ? FR.gold.withOpacity(.14)
            : FR.surface;
    final border = filled
        ? FR.gold
        : active
            ? FR.gold.withOpacity(.55)
            : FR.hairline;
    final fg = filled ? FR.onGold : (active ? FR.gold : FR.ink2);
    return InkWell(
      onTap: onTap,
      borderRadius: FRRad.all(16),
      child: Container(
        height: 54,
        padding: const EdgeInsets.symmetric(horizontal: 14),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: bg,
          borderRadius: FRRad.all(16),
          border: Border.all(color: border),
          boxShadow: filled ? frGoldGlow(opacity: .22) : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 20, color: fg),
            if (label != null) ...[
              const SizedBox(width: 6),
              Text(label!,
                  style: frText(12, FontWeight.w800, color: fg)),
            ],
          ],
        ),
      ),
    );
  }
}

// ─── Community photo submission CTA ─────────────────────────────────────────

/// Soft prompt under the hero image inviting verified users to submit a
/// better product photo. Submissions land in `product_image_submissions`
/// with status `pending` until an admin promotes the bytes to the
/// canonical `product_images/{productId}/...` path.
class _CommunityImageCta extends StatefulWidget {
  const _CommunityImageCta({required this.product});
  final Product product;

  @override
  State<_CommunityImageCta> createState() => _CommunityImageCtaState();
}

class _CommunityImageCtaState extends State<_CommunityImageCta> {
  bool _busy = false;

  Future<void> _submit(AppState state) async {
    if (_busy) return;
    final blockReason = _blockReason(state);
    if (blockReason != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(blockReason)),
      );
      return;
    }
    try {
      final picker = ImagePicker();
      final x = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1600,
        imageQuality: 88,
      );
      if (x == null) return;
      final bytes = await x.readAsBytes();
      if (!mounted) return;
      setState(() => _busy = true);
      await state.submitProductImage(
        product: widget.product,
        bytes: bytes,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Görsel önerin alındı, admin onayı sonrası yayınlanacak. Teşekkürler!',
          ),
        ),
      );
    } on StateError catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message)),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Görsel gönderilemedi: $e')),
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  String? _blockReason(AppState state) {
    final uid = state.user?.uid ?? '';
    if (uid.isEmpty) return 'Görsel önermek için giriş yap.';
    if (state.isGuestUser) {
      return 'Görsel önermek için ücretsiz hesap aç.';
    }
    if (state.needsEmailVerification) {
      return 'Görsel önermek için e-posta adresini doğrula.';
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final state = AppStateScope.of(context);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: FR.surface,
        borderRadius: FRRad.all(FRRad.l),
        border: Border.all(color: FR.gold.withOpacity(.32)),
        boxShadow: frGoldGlow(opacity: .08),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: FR.gold.withOpacity(.14),
              borderRadius: FRRad.all(12),
              border: Border.all(color: FR.gold.withOpacity(.4)),
            ),
            child: Icon(Icons.add_a_photo_outlined,
                color: FR.gold, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Bu ürüne fotoğraf ekle',
                  style: frText(13.5, FontWeight.w800),
                ),
                const SizedBox(height: 2),
                Text(
                  'Net, profesyonel bir çekim öner — admin onayından sonra bu üründe yayınlanır.',
                  style: frText(11.5, FontWeight.w600,
                      color: FR.ink3, height: 1.4),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          InkWell(
            onTap: _busy ? null : () => _submit(state),
            borderRadius: FRRad.all(12),
            child: Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: FR.gold,
                borderRadius: FRRad.all(12),
                boxShadow: frGoldGlow(opacity: .18),
              ),
              child: _busy
                  ? SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: FR.onGold,
                      ),
                    )
                  : Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.upload_rounded,
                            color: FR.onGold, size: 16),
                        const SizedBox(width: 6),
                        Text(
                          'Öner',
                          style: frText(12, FontWeight.w800,
                              color: FR.onGold),
                        ),
                      ],
                    ),
            ),
          ),
        ],
      ),
    );
  }
}
