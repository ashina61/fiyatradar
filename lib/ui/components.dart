import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import '../services/ads_service.dart';
import 'tokens.dart';

/// Resimler için ortak yumuşak fade-in. `Image.network` ve `Image` widget'ları
/// `frameBuilder` parametresine bunu vererek ağdan ilk kareye doğru rahat bir
/// geçiş elde eder; aksi halde resim aniden "pop" eder ve geç yüklenmiş gibi
/// hissedilir.
Widget frFadeFrameBuilder(
  BuildContext context,
  Widget child,
  int? frame,
  bool wasSyncLoaded,
) {
  if (wasSyncLoaded) return child;
  return AnimatedOpacity(
    opacity: frame == null ? 0 : 1,
    duration: const Duration(milliseconds: 180),
    curve: Curves.easeOutCubic,
    child: child,
  );
}

// ─── Animated entry ──────────────────────────────────────────────────────────

/// Fades + slides content into view on first build. Use [delay] to stagger
/// rows in a list so they cascade into place. Cheap, GPU-friendly, and
/// deterministic — re-running with the same key won't re-animate.
class FRFadeSlideIn extends StatefulWidget {
  const FRFadeSlideIn({
    super.key,
    required this.child,
    this.delay = Duration.zero,
    this.duration = const Duration(milliseconds: 360),
    this.offset = const Offset(0, 0.06),
  });
  final Widget child;
  final Duration delay;
  final Duration duration;
  final Offset offset;

  @override
  State<FRFadeSlideIn> createState() => _FRFadeSlideInState();
}

class _FRFadeSlideInState extends State<FRFadeSlideIn>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c =
      AnimationController(vsync: this, duration: widget.duration);
  late final Animation<double> _fade =
      CurvedAnimation(parent: _c, curve: Curves.easeOutCubic);
  late final Animation<Offset> _slide = Tween<Offset>(
    begin: widget.offset,
    end: Offset.zero,
  ).animate(_fade);

  @override
  void initState() {
    super.initState();
    if (widget.delay == Duration.zero) {
      _c.forward();
    } else {
      Future.delayed(widget.delay, () {
        if (mounted) _c.forward();
      });
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fade,
      child: SlideTransition(position: _slide, child: widget.child),
    );
  }
}

// ─── Page header ─────────────────────────────────────────────────────────────

class FRPageHeader extends StatelessWidget {
  const FRPageHeader({
    super.key,
    required this.overline,
    required this.title,
    this.italicTail,
    this.trailing,
  });
  final String overline;
  final String title;
  final String? italicTail;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    Widget titleW;
    if (italicTail != null) {
      titleW = RichText(
        text: TextSpan(
          text: title,
          style: frDisplay(40, FontWeight.w700),
          children: [
            TextSpan(text: italicTail, style: frSerifItalic(40, FontWeight.w400, color: FR.ink3)),
          ],
        ),
      );
    } else {
      titleW = Text(title, style: frDisplay(40, FontWeight.w700));
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(overline, style: frOverline()),
              const SizedBox(height: 6),
              titleW,
            ],
          ),
        ),
        if (trailing != null) trailing!,
      ],
    );
  }
}

class FRSectionHead extends StatelessWidget {
  const FRSectionHead({super.key, required this.title, this.eyebrow, this.action});
  final String? eyebrow;
  final String title;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (eyebrow != null) Text(eyebrow!, style: frOverline()),
              const SizedBox(height: 2),
              Text(title, style: frDisplay(22, FontWeight.w700)),
            ],
          ),
        ),
        if (action != null) action!,
      ],
    );
  }
}

// ─── Icon chip (top bar icon buttons) ────────────────────────────────────────

class FRIconChip extends StatelessWidget {
  const FRIconChip({
    super.key,
    required this.icon,
    this.onTap,
    this.active = false,
    this.badge = 0,
    this.size = 42,
  });
  final IconData icon;
  final VoidCallback? onTap;
  final bool active;
  final int badge;
  final double size;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: FRRad.all(14),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              color: active ? FR.gold.withOpacity(.15) : FR.surface,
              borderRadius: FRRad.all(14),
              border: Border.all(color: active ? FR.gold : FR.hairline),
            ),
            child: Icon(icon, size: 19, color: active ? FR.gold : FR.ink2),
          ),
          if (badge > 0)
            Positioned(
              right: -4,
              top: -4,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                decoration: BoxDecoration(
                  color: FR.bad,
                  borderRadius: FRRad.all(999),
                  border: Border.all(color: FR.bg, width: 1.5),
                ),
                child: Text(
                  badge > 9 ? '9+' : '$badge',
                  style: frText(9, FontWeight.w800, color: FR.bg),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// ─── Price ───────────────────────────────────────────────────────────────────

class FRPriceText extends StatelessWidget {
  const FRPriceText(this.value, {super.key, this.size = 22, this.color});
  final double? value;
  final double size;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final v = value;
    final text = v == null
        ? '—'
        : v >= 1000
            ? '${v.toStringAsFixed(0)} ₺'
            : v >= 100
                ? '${v.toStringAsFixed(0)} ₺'
                : '${v.toStringAsFixed(2)} ₺';
    return Text(text, style: frPrice(size, color: color ?? FR.ink));
  }
}

// ─── Trend pill (-%12 / +%4) ────────────────────────────────────────────────

class FRTrendPill extends StatelessWidget {
  const FRTrendPill({super.key, required this.pct, this.dense = false});
  final double pct;
  final bool dense;

  @override
  Widget build(BuildContext context) {
    final down = pct < 0;
    final color = down ? FR.good : FR.bad;
    return Container(
      padding: EdgeInsets.symmetric(horizontal: dense ? 8 : 10, vertical: dense ? 3 : 5),
      decoration: BoxDecoration(
        color: color.withOpacity(.14),
        borderRadius: FRRad.all(999),
        border: Border.all(color: color.withOpacity(.35)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(down ? Icons.trending_down_rounded : Icons.trending_up_rounded,
              size: dense ? 12 : 14, color: color),
          const SizedBox(width: 4),
          Text(
            '%${pct.abs().toStringAsFixed(pct.abs() < 10 ? 1 : 0)}',
            style: frText(dense ? 10 : 11, FontWeight.w800, color: color),
          ),
        ],
      ),
    );
  }
}

// ─── Store badge ─────────────────────────────────────────────────────────────

class FRStoreBadge extends StatelessWidget {
  const FRStoreBadge(this.store, {super.key, this.filled = false});
  final String store;
  final bool filled;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: filled ? FR.gold : FR.bgElev,
        borderRadius: FRRad.all(6),
        border: Border.all(color: filled ? FR.gold : FR.hairline),
      ),
      child: Text(
        store,
        style: frText(10.5, FontWeight.w800,
            color: filled ? FR.onGold : FR.ink, letter: .3),
      ),
    );
  }
}

// ─── Category / filter chip ──────────────────────────────────────────────────

class FRFilterChip extends StatelessWidget {
  const FRFilterChip(this.label,
      {super.key, this.active = false, this.onTap, this.leading});
  final String label;
  final bool active;
  final VoidCallback? onTap;
  final Widget? leading;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: FRRad.all(999),
      child: Container(
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: active ? FR.gold : FR.surface,
          borderRadius: FRRad.all(999),
          border: Border.all(color: active ? FR.gold : FR.hairline),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (leading != null) ...[
              IconTheme.merge(
                data: IconThemeData(color: active ? FR.onGold : FR.ink2),
                child: leading!,
              ),
              const SizedBox(width: 6),
            ],
            Text(
              label,
              style: frText(12.5, FontWeight.w700, color: active ? FR.onGold : FR.ink2),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── CTA ─────────────────────────────────────────────────────────────────────

class FRCta extends StatefulWidget {
  const FRCta({
    super.key,
    required this.label,
    required this.onTap,
    this.icon,
    this.filled = true,
    this.height = 54,
  });
  final String label;
  final VoidCallback? onTap;
  final IconData? icon;
  final bool filled;
  final double height;

  @override
  State<FRCta> createState() => _FRCtaState();
}

class _FRCtaState extends State<FRCta> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final filled = widget.filled;
    final enabled = widget.onTap != null;
    final bg = filled ? FR.gold : Colors.transparent;
    final fg = filled ? FR.onGold : FR.ink;
    return AnimatedScale(
      scale: _pressed && enabled ? 0.97 : 1.0,
      duration: const Duration(milliseconds: 120),
      curve: Curves.easeOut,
      child: AnimatedOpacity(
        opacity: enabled ? 1 : 0.55,
        duration: const Duration(milliseconds: 180),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: widget.onTap,
            onHighlightChanged: (v) {
              if (mounted) setState(() => _pressed = v);
            },
            borderRadius: FRRad.all(999),
            child: Container(
              height: widget.height,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: bg,
                borderRadius: FRRad.all(999),
                border: Border.all(color: filled ? FR.gold : FR.hairline),
                boxShadow: filled ? frGoldGlow() : null,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (widget.icon != null) ...[
                    Icon(widget.icon, size: 18, color: fg),
                    const SizedBox(width: 8),
                  ],
                  Text(widget.label,
                      style: frText(14, FontWeight.w800, color: fg)),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Surface card ────────────────────────────────────────────────────────────

class FRCard extends StatelessWidget {
  const FRCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(14),
    this.radius = FRRad.l,
    this.onTap,
    this.highlight = false,
  });
  final Widget child;
  final EdgeInsetsGeometry padding;
  final double radius;
  final VoidCallback? onTap;
  final bool highlight;

  @override
  Widget build(BuildContext context) {
    final deco = BoxDecoration(
      color: FR.surface,
      borderRadius: FRRad.all(radius),
      border: Border.all(color: highlight ? FR.gold.withOpacity(.5) : FR.hairline),
    );
    final body = Container(padding: padding, decoration: deco, child: child);
    if (onTap == null) return body;
    return InkWell(
      onTap: onTap,
      borderRadius: FRRad.all(radius),
      child: body,
    );
  }
}

// ─── Live dot ────────────────────────────────────────────────────────────────

class FRLiveDot extends StatelessWidget {
  const FRLiveDot({super.key, this.color, this.size = 7});
  final Color? color;
  final double size;

  @override
  Widget build(BuildContext context) {
    final c = color ?? FR.good;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: c,
        shape: BoxShape.circle,
        boxShadow: [BoxShadow(color: c.withOpacity(.55), blurRadius: 6)],
      ),
    );
  }
}

// ─── Dock nav button ─────────────────────────────────────────────────────────

class FRDockItem extends StatelessWidget {
  const FRDockItem({
    super.key,
    required this.icon,
    required this.label,
    required this.active,
    required this.onTap,
  });
  final IconData icon;
  final String label;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: FRRad.all(16),
      child: SizedBox(
        width: 58,
        height: 52,
        child: Stack(
          alignment: Alignment.center,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 220),
              curve: Curves.easeOutCubic,
              width: active ? 46 : 0,
              height: active ? 32 : 0,
              decoration: BoxDecoration(
                color: FR.gold.withOpacity(.14),
                borderRadius: FRRad.all(14),
              ),
            ),
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0, end: active ? 1 : 0),
                  duration: const Duration(milliseconds: 220),
                  curve: Curves.easeOutCubic,
                  builder: (_, t, __) {
                    final color = Color.lerp(FR.ink3, FR.gold, t)!;
                    return Transform.scale(
                      scale: 1 + t * 0.08,
                      child: Icon(icon, color: color, size: 20),
                    );
                  },
                ),
                const SizedBox(height: 3),
                AnimatedDefaultTextStyle(
                  duration: const Duration(milliseconds: 220),
                  style: frText(9.5, FontWeight.w800,
                      color: active ? FR.gold : FR.ink3, letter: .1),
                  child: Text(label),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class FRDockFab extends StatelessWidget {
  const FRDockFab({super.key, required this.active, required this.onTap});
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: FRRad.all(999),
      child: Container(
        width: 54,
        height: 54,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: active
                ? [FR.goldHi, FR.gold]
                : [FR.gold, FR.goldDeep],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          shape: BoxShape.circle,
          border: Border.all(color: FR.goldHi.withOpacity(.3), width: 2),
          boxShadow: [BoxShadow(color: FR.gold.withOpacity(.4), blurRadius: 16, offset: const Offset(0, 6))],
        ),
        child: Icon(Icons.add_rounded, size: 26, color: FR.onGold),
      ),
    );
  }
}

// ─── Freshness chip ─────────────────────────────────────────────────────────

class FRFreshChip extends StatelessWidget {
  const FRFreshChip({super.key, required this.date});
  final DateTime? date;

  String _ago(DateTime d) {
    final diff = DateTime.now().difference(d);
    if (diff.inDays > 7) return '${(diff.inDays / 7).floor()}h';
    if (diff.inDays > 0) return '${diff.inDays}g';
    if (diff.inHours > 0) return '${diff.inHours}sa';
    if (diff.inMinutes > 0) return '${diff.inMinutes}dk';
    return 'az önce';
  }

  @override
  Widget build(BuildContext context) {
    if (date == null) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
        decoration: BoxDecoration(
          color: FR.bgElev,
          borderRadius: FRRad.all(8),
          border: Border.all(color: FR.hairline),
        ),
        child: Text('fiyat yok', style: frText(10, FontWeight.w700, color: FR.ink3)),
      );
    }
    final fresh = DateTime.now().difference(date!).inHours < 48;
    final color = fresh ? FR.good : FR.ink3;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(.12),
        borderRadius: FRRad.all(999),
        border: Border.all(color: color.withOpacity(.28)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (fresh) ...[
            FRLiveDot(color: color, size: 6),
            const SizedBox(width: 5),
          ],
          Text(_ago(date!), style: frText(10, FontWeight.w800, color: color)),
        ],
      ),
    );
  }
}

// ─── Sparkline ───────────────────────────────────────────────────────────────

class FRSparkline extends StatelessWidget {
  const FRSparkline({super.key, required this.values, this.height = 48, this.color});
  final List<double> values;
  final double height;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      width: double.infinity,
      child: CustomPaint(painter: _SparkPainter(values, color ?? FR.gold)),
    );
  }
}

class _SparkPainter extends CustomPainter {
  _SparkPainter(this.values, this.color);
  final List<double> values;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    if (values.length < 2) return;
    final minV = values.reduce((a, b) => a < b ? a : b);
    final maxV = values.reduce((a, b) => a > b ? a : b);
    final range = (maxV - minV) == 0 ? 1.0 : (maxV - minV);

    final path = Path();
    for (var i = 0; i < values.length; i++) {
      final x = (i / (values.length - 1)) * size.width;
      final y = size.height - ((values[i] - minV) / range) * (size.height - 8) - 4;
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    final fill = Path.from(path)
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();
    canvas.drawPath(fill, Paint()..color = color.withOpacity(.14));
    canvas.drawPath(
      path,
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.2
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );
    final lastY =
        size.height - ((values.last - minV) / range) * (size.height - 8) - 4;
    canvas.drawCircle(
      Offset(size.width - 1, lastY),
      3.4,
      Paint()..color = color,
    );
    canvas.drawCircle(
      Offset(size.width - 1, lastY),
      6,
      Paint()..color = color.withOpacity(.22),
    );
  }

  @override
  bool shouldRepaint(covariant _SparkPainter old) =>
      old.values != values || old.color != color;
}

// ─── Verification badge ─────────────────────────────────────────────────────

/// Compact status chip derived from a [PriceStatus]-equivalent state.
/// Kept UI-only so the widget layer doesn't depend on the model enum name.
class FRVerifyBadge extends StatelessWidget {
  const FRVerifyBadge({
    super.key,
    required this.label,
    required this.tone,
    this.trustPercent,
    this.dense = false,
  });

  /// Build from semantics — prefer this over picking a tone manually.
  factory FRVerifyBadge.status({
    Key? key,
    required String status, // 'community_verified' | 'disputed' | 'rejected' | 'pending'
    required int trustPercent,
    bool dense = false,
  }) {
    String label;
    FRVerifyTone tone;
    switch (status) {
      case 'community_verified':
        label = 'Doğrulandı';
        tone = FRVerifyTone.good;
        break;
      case 'disputed':
        label = 'İhtilaflı';
        tone = FRVerifyTone.warn;
        break;
      case 'rejected':
        label = 'Reddedildi';
        tone = FRVerifyTone.bad;
        break;
      default:
        label = trustPercent >= 60 ? 'İncelemede' : 'Yeni';
        tone = FRVerifyTone.neutral;
    }
    return FRVerifyBadge(
      key: key,
      label: label,
      tone: tone,
      trustPercent: trustPercent,
      dense: dense,
    );
  }

  final String label;
  final FRVerifyTone tone;
  final int? trustPercent;
  final bool dense;

  @override
  Widget build(BuildContext context) {
    final c = switch (tone) {
      FRVerifyTone.good => FR.good,
      FRVerifyTone.warn => FR.warn,
      FRVerifyTone.bad => FR.bad,
      FRVerifyTone.neutral => FR.ink3,
    };
    final icon = switch (tone) {
      FRVerifyTone.good => Icons.verified_rounded,
      FRVerifyTone.warn => Icons.help_outline_rounded,
      FRVerifyTone.bad => Icons.block_rounded,
      FRVerifyTone.neutral => Icons.schedule_rounded,
    };
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: dense ? 7 : 9,
        vertical: dense ? 3 : 4,
      ),
      decoration: BoxDecoration(
        color: c.withOpacity(.14),
        borderRadius: FRRad.all(999),
        border: Border.all(color: c.withOpacity(.35)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: dense ? 11 : 13, color: c),
          const SizedBox(width: 4),
          Text(
            label,
            style: frText(dense ? 9.5 : 10.5, FontWeight.w800, color: c),
          ),
          if (trustPercent != null) ...[
            const SizedBox(width: 6),
            Container(width: 1, height: dense ? 8 : 10, color: c.withOpacity(.3)),
            const SizedBox(width: 6),
            Text('%$trustPercent',
                style: frText(dense ? 9.5 : 10.5, FontWeight.w800, color: c)),
          ],
        ],
      ),
    );
  }
}

enum FRVerifyTone { good, warn, bad, neutral }

/// Horizontal bar summarising up/down votes for a price entry.
class FRVoteBar extends StatelessWidget {
  const FRVoteBar({
    super.key,
    required this.up,
    required this.down,
  });
  final int up;
  final int down;

  @override
  Widget build(BuildContext context) {
    final total = up + down;
    final upPct = total == 0 ? 0.5 : up / total;
    return Row(
      children: [
        Icon(Icons.thumb_up_alt_rounded, size: 12, color: FR.good),
        const SizedBox(width: 4),
        Text('$up', style: frText(11, FontWeight.w800, color: FR.good)),
        const SizedBox(width: 8),
        Expanded(
          child: ClipRRect(
            borderRadius: FRRad.all(999),
            child: Stack(
              children: [
                Container(height: 6, color: FR.bad.withOpacity(.2)),
                FractionallySizedBox(
                  widthFactor: upPct.clamp(0.0, 1.0).toDouble(),
                  child: Container(height: 6, color: FR.good.withOpacity(.75)),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 8),
        Text('$down', style: frText(11, FontWeight.w800, color: FR.bad)),
        const SizedBox(width: 4),
        Icon(Icons.thumb_down_alt_rounded, size: 12, color: FR.bad),
      ],
    );
  }
}

/// Twin vote buttons (up / down). Disabled states and tones reflect the
/// user's current vote or whether they're allowed to vote at all.
class FRVoteButtons extends StatelessWidget {
  const FRVoteButtons({
    super.key,
    required this.currentVote, // 'up' | 'down' | null
    required this.disabledReason, // null when allowed
    required this.onUp,
    required this.onDown,
  });
  final String? currentVote;
  final String? disabledReason;
  final VoidCallback onUp;
  final VoidCallback onDown;

  @override
  Widget build(BuildContext context) {
    final locked = disabledReason != null;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _btn(
          icon: Icons.thumb_up_rounded,
          label: 'Doğru',
          tone: FR.good,
          active: currentVote == 'up',
          disabled: locked,
          onTap: locked ? null : onUp,
        ),
        const SizedBox(width: 8),
        _btn(
          icon: Icons.thumb_down_rounded,
          label: 'Yanlış',
          tone: FR.bad,
          active: currentVote == 'down',
          disabled: locked,
          onTap: locked ? null : onDown,
        ),
      ],
    );
  }

  Widget _btn({
    required IconData icon,
    required String label,
    required Color tone,
    required bool active,
    required bool disabled,
    required VoidCallback? onTap,
  }) {
    final bg = active
        ? tone.withOpacity(.18)
        : (disabled ? FR.surfaceLo : FR.surface);
    final fg = active
        ? tone
        : (disabled ? FR.ink4 : FR.ink2);
    final border = active
        ? tone.withOpacity(.55)
        : (disabled ? FR.hairlineSoft : FR.hairline);
    return InkWell(
      onTap: onTap,
      borderRadius: FRRad.all(999),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: FRRad.all(999),
          border: Border.all(color: border),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 13, color: fg),
            const SizedBox(width: 5),
            Text(label, style: frText(11, FontWeight.w800, color: fg)),
          ],
        ),
      ),
    );
  }
}

/// Premium shimmer skeleton — `CircularProgressIndicator`'ın yerine ana
/// ekranlarda kullanılır. Yumuşak geçişli gradient bir bantı sürekli
/// kaydırarak "yükleniyor ama içerik şekli belli" hissi verir.
///
/// Kullanım: tek-satır kart için `FRSkeleton(height: 56)`, çoklu satır
/// için `FRSkeletonList(count: 4, itemHeight: 64)`.
class FRSkeleton extends StatefulWidget {
  const FRSkeleton({
    super.key,
    this.width = double.infinity,
    this.height = 16,
    this.radius = 10,
  });
  final double width;
  final double height;
  final double radius;

  @override
  State<FRSkeleton> createState() => _FRSkeletonState();
}

class _FRSkeletonState extends State<FRSkeleton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (_, __) {
        // -1 (sol-dış) → 1 (sağ-dış) hareketli highlight noktası.
        final t = _ctrl.value * 2 - 1;
        return ClipRRect(
          borderRadius: BorderRadius.circular(widget.radius),
          child: SizedBox(
            width: widget.width,
            height: widget.height,
            child: ShaderMask(
              blendMode: BlendMode.srcATop,
              shaderCallback: (bounds) {
                return LinearGradient(
                  begin: Alignment(t - 1, 0),
                  end: Alignment(t + 1, 0),
                  colors: [
                    FR.surface,
                    FR.surfaceHi,
                    FR.surface,
                  ],
                  stops: const [0.0, 0.5, 1.0],
                ).createShader(bounds);
              },
              child: Container(color: FR.surface),
            ),
          ),
        );
      },
    );
  }
}

/// Pro kullanıcı için no-op, ücretsiz kullanıcı için gerçek AdMob banner.
///
/// Banner yüklenirken (veya hata aldığında) "Pro al, reklamsız" CTA
/// fallback gösterilir — kullanıcı asla boş yer görmez. Pro kullanıcı
/// `isPremium=true` ile hiçbir şey render etmez.
class FRAdSlot extends StatelessWidget {
  const FRAdSlot({
    super.key,
    required this.isPremium,
    this.onUpgradeTap,
  });
  final bool isPremium;
  final VoidCallback? onUpgradeTap;

  @override
  Widget build(BuildContext context) {
    if (isPremium) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: FRInlineBannerAd(
        isPremium: false,
        fallback: _AdUpsellFallback(onUpgradeTap: onUpgradeTap),
      ),
    );
  }
}

class _AdUpsellFallback extends StatelessWidget {
  const _AdUpsellFallback({this.onUpgradeTap});
  final VoidCallback? onUpgradeTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onUpgradeTap,
      borderRadius: FRRad.all(FRRad.m),
      child: Container(
        height: 64,
        padding: const EdgeInsets.symmetric(horizontal: 14),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: FR.surfaceLo,
          borderRadius: FRRad.all(FRRad.m),
          border: Border.all(color: FR.hairline),
        ),
        child: Row(
          children: [
            Icon(Icons.workspace_premium_rounded, color: FR.gold, size: 18),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                'Reklamsız deneyim için Pro\'ya geç',
                style: frText(12, FontWeight.w800, color: FR.ink2),
              ),
            ),
            Icon(Icons.arrow_forward_rounded, color: FR.gold, size: 16),
          ],
        ),
      ),
    );
  }
}

/// Inline banner reklam — feed listeleri arasına yerleştirilir.
/// Pro değilse gerçek bir AdMob banner yükler; yüklenene kadar (veya
/// load fail olursa) `fallback` render edilir. Pro ise no-op.
///
/// Kullanım:
///   ```dart
///   FRInlineBannerAd(isPremium: state.premium.isActive)
///   ```
/// `fallback` opsiyonel — verilmezse skeleton bir kapsül gösterir.
class FRInlineBannerAd extends StatefulWidget {
  const FRInlineBannerAd({
    super.key,
    required this.isPremium,
    this.fallback,
  });
  final bool isPremium;
  final Widget? fallback;

  @override
  State<FRInlineBannerAd> createState() => _FRInlineBannerAdState();
}

class _FRInlineBannerAdState extends State<FRInlineBannerAd> {
  BannerAd? _bannerAd;
  bool _loaded = false;
  bool _failed = false;

  @override
  void initState() {
    super.initState();
    if (!widget.isPremium) {
      _load();
    }
  }

  void _load() {
    final ad = BannerAd(
      adUnitId: AdsService.instance.bannerAdUnitId,
      size: AdSize.banner,
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (_) {
          if (!mounted) return;
          setState(() => _loaded = true);
        },
        onAdFailedToLoad: (ad, error) {
          ad.dispose();
          if (!mounted) return;
          setState(() {
            _failed = true;
            _bannerAd = null;
          });
        },
      ),
    );
    _bannerAd = ad;
    ad.load();
  }

  @override
  void dispose() {
    _bannerAd?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.isPremium) return const SizedBox.shrink();
    if (_loaded && _bannerAd != null) {
      return SizedBox(
        width: _bannerAd!.size.width.toDouble(),
        height: _bannerAd!.size.height.toDouble(),
        child: AdWidget(ad: _bannerAd!),
      );
    }
    // Yükleniyor veya başarısız oldu → fallback. Boş yer bırakmıyoruz
    // ki kullanıcı titreşim hissetmesin.
    if (widget.fallback != null) return widget.fallback!;
    return Container(
      height: 60,
      decoration: BoxDecoration(
        color: FR.surfaceLo,
        borderRadius: FRRad.all(FRRad.m),
        border: Border.all(color: FR.hairline),
      ),
      alignment: Alignment.center,
      child: Text(
        _failed ? 'Reklam yüklenemedi' : 'Reklam yükleniyor…',
        style: frText(11, FontWeight.w700, color: FR.ink3),
      ),
    );
  }
}

/// `FRSkeleton`'ı dikey listede tekrarlar — "X kart yükleniyor" görünümü.
class FRSkeletonList extends StatelessWidget {
  const FRSkeletonList({
    super.key,
    this.count = 3,
    this.itemHeight = 76,
    this.spacing = 10,
    this.radius = 16,
  });
  final int count;
  final double itemHeight;
  final double spacing;
  final double radius;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: List.generate(count, (i) {
        return Padding(
          padding: EdgeInsets.only(bottom: i == count - 1 ? 0 : spacing),
          child: FRSkeleton(
            height: itemHeight,
            radius: radius,
          ),
        );
      }),
    );
  }
}

// ─── Premium / trust badges ─────────────────────────────────────────────────

/// Küçük altın "PRO" rozeti. FiyatRadar Pro aboneliği aktif olan kullanıcıları
/// yorum, fiyat raporu, profil ve liderlik tablosunda işaretlemek için kullanılır.
/// `compact=true` ile yalnız "PRO" yazısı, `compact=false` ile yıldız ikonlu
/// daha belirgin bir kapsül döner.
class FRProBadge extends StatelessWidget {
  const FRProBadge({super.key, this.compact = true});
  final bool compact;

  @override
  Widget build(BuildContext context) {
    if (compact) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2), // LEGACY_EXCEPTION: reason=token_migration owner=codex remove_by=2026-06-30
        decoration: BoxDecoration(
          gradient: LinearGradient(colors: [FR.goldHi, FR.goldDeep]),
          borderRadius: FRRad.all(999),
          boxShadow: frGoldGlow(opacity: .25),
        ),
        child: Text(
          'PRO',
          style: frOverline(color: FR.onGold, size: 9.5),
        ),
      );
    }
    return Container(
      padding: const EdgeInsetsDirectional.fromSTEB(8, 3, 9, 3),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [FR.goldHi, FR.goldDeep]),
        borderRadius: FRRad.all(999),
        boxShadow: frGoldGlow(opacity: .25),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.workspace_premium_rounded, size: 12, color: FR.onGold),
          const SizedBox(width: 4),
          Text(
            'PRO',
            style: frOverline(color: FR.onGold, size: 10),
          ),
        ],
      ),
    );
  }
}

/// Kullanıcının güvenirlik (trust) seviyesini gösteren küçük kapsül.
/// `percent` 0..100 aralığında. <30 = kırmızı, 30-69 = nötr, 70+ = yeşil.
/// Üst tarafta küçük bir kalkan ikonuyla "%X güven" formatında basar.
class FRTrustPill extends StatelessWidget {
  const FRTrustPill({super.key, required this.percent, this.dense = false});
  final int percent;
  final bool dense;

  Color get _tone {
    if (percent >= 70) return FR.good;
    if (percent < 30) return FR.bad;
    return FR.ink2;
  }

  @override
  Widget build(BuildContext context) {
    final tone = _tone;
    final clamped = percent.clamp(0, 100);
    return Container(
      padding: dense
          ? const EdgeInsets.symmetric(horizontal: 6, vertical: 2) // LEGACY_EXCEPTION: reason=token_migration owner=codex remove_by=2026-06-30
          : const EdgeInsets.symmetric(horizontal: 8, vertical: 3), // LEGACY_EXCEPTION: reason=token_migration owner=codex remove_by=2026-06-30
      decoration: BoxDecoration(
        color: tone.withOpacity(.10),
        borderRadius: FRRad.all(999),
        border: Border.all(color: tone.withOpacity(.45)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.verified_user_rounded,
              size: dense ? 10 : 12, color: tone),
          const SizedBox(width: 4),
          Text(
            '%$clamped güven',
            style: frText(dense ? 10 : 10.5, FontWeight.w800, color: tone),
          ),
        ],
      ),
    );
  }
}
