import 'package:flutter/material.dart';
import '../theme.dart';

/// Shared, premium design primitives reused across all screens.
/// Goal: enforce consistent hierarchy, density, and "data-first" feel
/// without changing the warm coffee design language.
class FR {
  static const double radiusXl = 22;
  static const double radiusL = 18;
  static const double radiusM = 14;
  static const double radiusS = 10;

  static List<BoxShadow> softShadow = [
    BoxShadow(
      color: const Color(0xFF2B1810).withOpacity(0.05),
      blurRadius: 18,
      offset: const Offset(0, 6),
    ),
  ];

  static const tabularPrice = TextStyle(
    fontFeatures: [FontFeature.tabularFigures()],
    fontWeight: FontWeight.w800,
    letterSpacing: -0.3,
    color: CoffeeColors.espresso,
  );
}

/// Compact price label using tabular figures, so prices in lists line up.
class PriceText extends StatelessWidget {
  const PriceText(
    this.value, {
    super.key,
    this.size = 16,
    this.color = CoffeeColors.accent,
    this.bold = true,
  });

  final double? value;
  final double size;
  final Color color;
  final bool bold;

  @override
  Widget build(BuildContext context) {
    return Text(
      value == null ? '–' : '₺${value!.toStringAsFixed(2)}',
      style: TextStyle(
        color: color,
        fontSize: size,
        fontWeight: bold ? FontWeight.w800 : FontWeight.w700,
        letterSpacing: -0.3,
        fontFeatures: const [FontFeature.tabularFigures()],
      ),
    );
  }
}

/// Tiny "EYALET" style label used over hero numbers.
class EyebrowLabel extends StatelessWidget {
  const EyebrowLabel(this.text,
      {super.key, this.color = CoffeeColors.caramel});
  final String text;
  final Color color;
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.18),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.32)),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.w800,
          letterSpacing: 1.2,
        ),
      ),
    );
  }
}

/// Live data dot used to imply "fresh" / "now".
class LiveDot extends StatelessWidget {
  const LiveDot({super.key, this.color = CoffeeColors.success});
  final Color color;
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 8,
      height: 8,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(color: color.withOpacity(0.5), blurRadius: 6),
        ],
      ),
    );
  }
}

/// Freshness chip: how long ago the latest data point arrived.
class FreshnessChip extends StatelessWidget {
  const FreshnessChip({super.key, required this.date});
  final DateTime? date;

  String _ago(DateTime d) {
    final diff = DateTime.now().difference(d);
    if (diff.inDays > 7) return '${(diff.inDays / 7).floor()}h önce';
    if (diff.inDays > 0) return '${diff.inDays}g önce';
    if (diff.inHours > 0) return '${diff.inHours}sa önce';
    if (diff.inMinutes > 0) return '${diff.inMinutes}dk önce';
    return 'az önce';
  }

  bool _isFresh(DateTime d) =>
      DateTime.now().difference(d).inHours < 48;

  @override
  Widget build(BuildContext context) {
    if (date == null) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: CoffeeColors.foam,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: CoffeeColors.crema),
        ),
        child: const Text(
          'fiyat yok',
          style: TextStyle(
              color: CoffeeColors.cocoa,
              fontSize: 10,
              fontWeight: FontWeight.w700),
        ),
      );
    }
    final fresh = _isFresh(date!);
    final color = fresh ? CoffeeColors.success : CoffeeColors.cocoa;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(0.10),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.25)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (fresh) ...[
            LiveDot(color: color),
            const SizedBox(width: 4),
          ],
          Text(
            _ago(date!),
            style: TextStyle(
              color: color,
              fontSize: 10,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

/// Generic premium surface card.
class PremiumCard extends StatelessWidget {
  const PremiumCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.elevated = false,
  });
  final Widget child;
  final EdgeInsetsGeometry padding;
  final bool elevated;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(FR.radiusL),
        border: Border.all(color: CoffeeColors.crema),
        boxShadow: elevated ? FR.softShadow : null,
      ),
      child: child,
    );
  }
}

/// Section header reused across screens.
class SectionHeader extends StatelessWidget {
  const SectionHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.trailing,
  });
  final String title;
  final String? subtitle;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                  color: CoffeeColors.espresso,
                  letterSpacing: -0.3,
                ),
              ),
              if (subtitle != null) ...[
                const SizedBox(height: 2),
                Text(
                  subtitle!,
                  style: const TextStyle(
                    color: CoffeeColors.cocoa,
                    fontSize: 12,
                  ),
                ),
              ],
            ],
          ),
        ),
        if (trailing != null) trailing!,
      ],
    );
  }
}

/// Inline price-change pill (-12% / +4%).
class TrendPill extends StatelessWidget {
  const TrendPill({super.key, required this.pct, this.dense = false});
  final double pct;
  final bool dense;

  @override
  Widget build(BuildContext context) {
    final down = pct < 0;
    final color = down ? const Color(0xFF2E7D32) : const Color(0xFFC62828);
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: dense ? 6 : 8,
        vertical: dense ? 2 : 4,
      ),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            down ? Icons.trending_down : Icons.trending_up,
            color: color,
            size: dense ? 11 : 13,
          ),
          const SizedBox(width: 3),
          Text(
            '${down ? '' : '+'}${pct.toStringAsFixed(1)}%',
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w800,
              fontSize: dense ? 10 : 12,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
        ],
      ),
    );
  }
}

/// Sparkline painter for tiny price-history charts.
class Sparkline extends StatelessWidget {
  const Sparkline({
    super.key,
    required this.values,
    this.height = 56,
    this.color = CoffeeColors.caramel,
  });
  final List<double> values;
  final double height;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      width: double.infinity,
      child: CustomPaint(painter: _SparkPainter(values, color)),
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
      final y = size.height - ((values[i] - minV) / range) * (size.height - 6) - 3;
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }

    // Fill area
    final fillPath = Path.from(path)
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();
    canvas.drawPath(
      fillPath,
      Paint()..color = color.withOpacity(0.12),
    );

    // Stroke
    canvas.drawPath(
      path,
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.2
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );

    // End dot
    final lastX = size.width;
    final lastY =
        size.height - ((values.last - minV) / range) * (size.height - 6) - 3;
    canvas.drawCircle(
      Offset(lastX, lastY),
      3.2,
      Paint()..color = color,
    );
    canvas.drawCircle(
      Offset(lastX, lastY),
      5.5,
      Paint()..color = color.withOpacity(0.18),
    );
  }

  @override
  bool shouldRepaint(covariant _SparkPainter oldDelegate) =>
      oldDelegate.values != values || oldDelegate.color != color;
}

/// Source / store badge — small inline tag.
class StoreBadge extends StatelessWidget {
  const StoreBadge(this.store, {super.key, this.dark = true});
  final String store;
  final bool dark;
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: dark ? CoffeeColors.espresso : CoffeeColors.foam,
        borderRadius: BorderRadius.circular(8),
        border: dark ? null : Border.all(color: CoffeeColors.crema),
      ),
      child: Text(
        store,
        style: TextStyle(
          color: dark ? CoffeeColors.cream : CoffeeColors.darkRoast,
          fontSize: 10,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.2,
        ),
      ),
    );
  }
}
