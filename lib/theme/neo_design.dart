import 'package:flutter/material.dart';

class NeoDesign {
  static const Color bg = Color(0xFF0B1020);
  static const Color panel = Color(0xFF141B34);
  static const Color panelSoft = Color(0xFF1B2446);
  static const Color text = Color(0xFFF4F7FF);
  static const Color muted = Color(0xFF9AA7CF);
  static const Color primary = Color(0xFF6C8CFF);
  static const Color secondary = Color(0xFF35D0BA);
  static const Color warning = Color(0xFFFFB867);

  static BoxDecoration pageGradient() {
    return const BoxDecoration(
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFF090E1D), Color(0xFF131B36), Color(0xFF0A1123)],
      ),
    );
  }

  static BoxDecoration glassCard({bool highlighted = false}) {
    return BoxDecoration(
      color: highlighted ? panelSoft : panel,
      borderRadius: BorderRadius.circular(20),
      border: Border.all(
        color: highlighted ? primary.withOpacity(0.6) : Colors.white.withOpacity(0.08),
      ),
      boxShadow: const [
        BoxShadow(color: Colors.black26, blurRadius: 20, offset: Offset(0, 10)),
      ],
    );
  }

  static TextStyle title([double size = 26]) => TextStyle(
        color: text,
        fontSize: size,
        fontWeight: FontWeight.w800,
        letterSpacing: -0.4,
      );

  static TextStyle body({Color? color}) => TextStyle(
        color: color ?? muted,
        fontSize: 14,
        fontWeight: FontWeight.w600,
      );

  static InputDecoration input(String hint, {IconData? icon}) => InputDecoration(
        hintText: hint,
        hintStyle: body(),
        filled: true,
        fillColor: panelSoft,
        prefixIcon: icon == null ? null : Icon(icon, color: muted),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: Colors.white.withOpacity(0.1)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: Colors.white.withOpacity(0.1)),
        ),
      );
}

class NeoScaffold extends StatelessWidget {
  const NeoScaffold({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: NeoDesign.pageGradient(),
      child: SafeArea(child: child),
    );
  }
}
