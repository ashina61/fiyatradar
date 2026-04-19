// Visual audit of the executive design system.
// HTML ref: reference/designprototype — compare palette/typography/radius
// side-by-side with this screen.
// Not linked from main navigation; run via `flutter run -t lib/main_preview.dart`.

import 'package:flutter/material.dart';

import '../../theme/tokens.dart';
import '../../theme/typography.dart';

class ThemePreviewScreen extends StatelessWidget {
  const ThemePreviewScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ExecutiveColors.bg,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 24, 20, 40),
          children: [
            _sectionLabel('COLOR · SURFACES'),
            _swatchGrid(const [
              ('bg', ExecutiveColors.bg),
              ('bgSoft', ExecutiveColors.bgSoft),
              ('bgDeep', ExecutiveColors.bgDeep),
              ('surface', ExecutiveColors.surface),
              ('surface2', ExecutiveColors.surface2),
            ]),
            const SizedBox(height: 20),
            _sectionLabel('COLOR · ESPRESSO'),
            _swatchGrid(const [
              ('espresso', ExecutiveColors.espresso),
              ('espresso2', ExecutiveColors.espresso2),
              ('espresso3', ExecutiveColors.espresso3),
            ]),
            const SizedBox(height: 20),
            _sectionLabel('COLOR · GOLD'),
            _swatchGrid(const [
              ('gold', ExecutiveColors.gold),
              ('goldSoft', ExecutiveColors.goldSoft),
              ('goldDeep', ExecutiveColors.goldDeep),
              ('goldWash', ExecutiveColors.goldWash),
            ]),
            const SizedBox(height: 20),
            _sectionLabel('COLOR · INK'),
            _swatchGrid(const [
              ('ink', ExecutiveColors.ink),
              ('ink2', ExecutiveColors.ink2),
              ('ink3', ExecutiveColors.ink3),
              ('ink4', ExecutiveColors.ink4),
            ]),
            const SizedBox(height: 20),
            _sectionLabel('COLOR · SEMANTIC'),
            _swatchGrid(const [
              ('positive', ExecutiveColors.positive),
              ('positiveSoft', ExecutiveColors.positiveSoft),
              ('negative', ExecutiveColors.negative),
              ('negativeSoft', ExecutiveColors.negativeSoft),
              ('neutral', ExecutiveColors.neutral),
            ]),
            const SizedBox(height: 32),
            _sectionLabel('TYPOGRAPHY'),
            const SizedBox(height: 12),
            Text('Display', style: FRType.display(size: 40)),
            const SizedBox(height: 8),
            Text('Heading 1 · Fiyat Radar', style: FRType.h1()),
            const SizedBox(height: 8),
            _italicAccent('Trend', 'ürünler', FRType.h2(), 30),
            const SizedBox(height: 8),
            _italicAccent('Canlı', 'akış', FRType.h3(), 22),
            const SizedBox(height: 8),
            Text('Heading 4 · Bugünün özeti', style: FRType.h4()),
            const SizedBox(height: 12),
            Text(
              'Body · FiyatRadar executive market intelligence platformu.'
              ' Soft krem zemin üzerinde espresso hiyerarşi, altın accent'
              ' premium anların eşlikçisi.',
              style: FRType.body(),
            ),
            const SizedBox(height: 8),
            Text('caption · 12d önce · Kadıköy', style: FRType.caption()),
            const SizedBox(height: 8),
            Text('GÜNÜN NABZI', style: FRType.overline()),
            const SizedBox(height: 6),
            Text('GOLD OVERLINE',
                style: FRType.overline(color: ExecutiveColors.goldDeep)),
            const SizedBox(height: 16),
            Row(
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Text('₺1.284', style: FRType.numeric(size: 36)),
                const SizedBox(width: 6),
                Text('TL', style: FRType.body(size: 14, color: ExecutiveColors.ink3)),
              ],
            ),
            const SizedBox(height: 32),
            _sectionLabel('RADIUS'),
            const SizedBox(height: 12),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: const [
                _RadiusTile(label: 'sm 10', radius: FRRadius.sm),
                _RadiusTile(label: 'md 16', radius: FRRadius.md),
                _RadiusTile(label: 'lg 22', radius: FRRadius.lg),
                _RadiusTile(label: 'xl 28', radius: FRRadius.xl),
                _RadiusTile(label: 'xxl 34', radius: FRRadius.xxl),
                _RadiusTile(label: 'pill', radius: FRRadius.pill),
              ],
            ),
            const SizedBox(height: 32),
            _sectionLabel('SHADOW'),
            const SizedBox(height: 12),
            Row(
              children: const [
                _ShadowTile(label: 'sm', shadow: FRShadows.sm),
                SizedBox(width: 12),
                _ShadowTile(label: 'md', shadow: FRShadows.md),
                SizedBox(width: 12),
                _ShadowTile(label: 'lg', shadow: FRShadows.lg),
                SizedBox(width: 12),
                _ShadowTile(
                  label: 'gold',
                  shadow: FRShadows.gold,
                  tint: ExecutiveColors.gold,
                ),
              ],
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  static Widget _sectionLabel(String text) =>
      Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Text(text, style: FRType.overline(color: ExecutiveColors.goldDeep)),
      );

  static Widget _swatchGrid(List<(String, Color)> items) => Wrap(
        spacing: 10,
        runSpacing: 10,
        children: [
          for (final (name, c) in items) _Swatch(name: name, color: c),
        ],
      );

  static Widget _italicAccent(String lead, String em, TextStyle base, double size) {
    return Text.rich(
      TextSpan(
        style: base,
        children: [
          TextSpan(text: '$lead '),
          TextSpan(text: em, style: FRType.emAccent(size: size)),
        ],
      ),
    );
  }
}

class _Swatch extends StatelessWidget {
  const _Swatch({required this.name, required this.color});
  final String name;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 96,
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: ExecutiveColors.surface,
        borderRadius: FRRadius.rSm,
        border: Border.all(color: ExecutiveColors.borderOnLight),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 48,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: ExecutiveColors.borderOnLight),
            ),
          ),
          const SizedBox(height: 6),
          Text(name, style: FRType.caption()),
        ],
      ),
    );
  }
}

class _RadiusTile extends StatelessWidget {
  const _RadiusTile({required this.label, required this.radius});
  final String label;
  final double radius;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 92,
      height: 56,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: ExecutiveColors.surface,
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(color: ExecutiveColors.borderOnLight),
        boxShadow: FRShadows.sm,
      ),
      child: Text(label, style: FRType.caption(color: ExecutiveColors.ink)),
    );
  }
}

class _ShadowTile extends StatelessWidget {
  const _ShadowTile({required this.label, required this.shadow, this.tint});
  final String label;
  final List<BoxShadow> shadow;
  final Color? tint;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        height: 64,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: tint ?? ExecutiveColors.surface,
          borderRadius: FRRadius.rMd,
          boxShadow: shadow,
        ),
        child: Text(
          label,
          style: FRType.button(
            color: tint == null ? ExecutiveColors.ink : ExecutiveColors.espresso,
          ),
        ),
      ),
    );
  }
}
