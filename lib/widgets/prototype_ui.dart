import 'package:flutter/material.dart';

class ProtoColors {
  static const bgPrimary = Color.fromARGB(255, 26, 22, 20);
  static const bgSecondary = Color.fromARGB(255, 36, 32, 29);
  static const surface = Color.fromARGB(255, 42, 37, 34);
  static const surfaceAlt = Color.fromARGB(255, 49, 44, 41);
  static const surfaceElevated = Color.fromARGB(255, 61, 54, 51);
  static const border = Color.fromARGB(102, 61, 54, 51);
  static const borderLight = Color.fromARGB(20, 245, 241, 237);

  static const textPrimary = Color.fromARGB(255, 247, 243, 239);
  static const textSecondary = Color.fromARGB(255, 175, 163, 152);
  static const textSubtle = Color.fromARGB(255, 143, 134, 128);

  static const tan = Color.fromARGB(255, 196, 165, 123);
  static const tanLight = Color.fromARGB(255, 212, 184, 150);
  static const tanDark = Color.fromARGB(255, 154, 130, 96);

  static const success = Color.fromARGB(255, 138, 154, 139);
  static const danger = Color.fromARGB(255, 166, 123, 123);
  static const warning = Color.fromARGB(255, 181, 139, 122);
  static const purple = Color.fromARGB(255, 138, 123, 166);

  static const flashStart = Color.fromARGB(255, 139, 37, 0);
  static const flashEnd = Color.fromARGB(255, 184, 74, 26);
}

class ProtoRadius {
  static const sm = 8.0;
  static const md = 10.0;
  static const lg = 14.0;
  static const xl = 18.0;
  static const xxl = 22.0;
  static const pill = 99.0;
}

class FRRadii {
  static const sm = BorderRadius.all(Radius.circular(ProtoRadius.sm));
  static const md = BorderRadius.all(Radius.circular(ProtoRadius.md));
  static const lg = BorderRadius.all(Radius.circular(ProtoRadius.lg));
  static const xl = BorderRadius.all(Radius.circular(ProtoRadius.xl));
  static const xxl = BorderRadius.all(Radius.circular(ProtoRadius.xxl));
  static const pill = BorderRadius.all(Radius.circular(ProtoRadius.pill));

  static BorderRadius all(double value) => BorderRadius.all(Radius.circular(value));
}

class ProtoSpacing {
  static const s = 8.0;
  static const m = 12.0;
  static const l = 16.0;
  static const xl = 24.0;
}

class FRInsets {
  static const page = EdgeInsetsDirectional.fromSTEB(24, 0, 24, 90);
  static const pageTop = EdgeInsetsDirectional.fromSTEB(24, 10, 24, 90);
  static const pageTopBar = EdgeInsetsDirectional.fromSTEB(20, 12, 20, 10);
  static const pageBody = EdgeInsetsDirectional.fromSTEB(24, 10, 24, 20);
  static const pageHeader = EdgeInsetsDirectional.fromSTEB(24, 12, 24, 8);
  static const pageFooter = EdgeInsetsDirectional.fromSTEB(24, 12, 24, 20);
  static const pageBasket = EdgeInsetsDirectional.fromSTEB(16, 0, 16, 90);
  static const horizontalPage = EdgeInsetsDirectional.symmetric(horizontal: 24);
  static const horizontalM = EdgeInsetsDirectional.symmetric(horizontal: 14);
  static const verticalS = EdgeInsetsDirectional.symmetric(vertical: 10);
  static const card = EdgeInsetsDirectional.all(14);
  static const cardMd = EdgeInsetsDirectional.all(12);
  static const card10 = EdgeInsetsDirectional.all(10);
  static const cardL = EdgeInsetsDirectional.all(16);
  static const cardXl = EdgeInsetsDirectional.all(20);
  static const card22 = EdgeInsetsDirectional.all(22);
  static const cardXxl = EdgeInsetsDirectional.all(24);
  static const chip = EdgeInsetsDirectional.symmetric(horizontal: 14, vertical: 6);
  static const searchWrap = EdgeInsetsDirectional.fromSTEB(24, 0, 24, 16);
  static const searchContent = EdgeInsetsDirectional.symmetric(horizontal: 14, vertical: 12);
  static const navItem = EdgeInsetsDirectional.symmetric(horizontal: 10, vertical: 6);
  static const rightGapS = EdgeInsetsDirectional.only(end: 8);
  static const bottomGapS = EdgeInsetsDirectional.only(bottom: 10);
  static const bottomGapM = EdgeInsetsDirectional.only(bottom: 12);
  static const heroBottom = EdgeInsetsDirectional.only(bottom: 100);
}

BoxDecoration protoSurface({double radius = ProtoRadius.xl}) => BoxDecoration(
      color: ProtoColors.surface,
      borderRadius: FRRadii.all(radius),
      border: Border.all(color: ProtoColors.border),
    );

class ProtoTopBar extends StatelessWidget {
  const ProtoTopBar({
    super.key,
    required this.title,
    this.subtitle,
    this.onNotification,
    this.badge = 0,
    this.trailing,
  });

  final String title;
  final String? subtitle;
  final VoidCallback? onNotification;
  final int badge;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: FRInsets.pageTopBar,
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (subtitle != null)
                  Text(subtitle!,
                      style: const TextStyle(
                          color: ProtoColors.textSubtle,
                          fontSize: 10,
                          fontWeight: FontWeight.w600)),
                Text(title,
                    style: const TextStyle(
                        color: ProtoColors.textPrimary,
                        fontSize: 24,
                        fontWeight: FontWeight.w800)),
              ],
            ),
          ),
          if (onNotification != null)
            NotificationButton(badge: badge, onTap: onNotification!),
          if (trailing != null) ...[
            const SizedBox(width: 8),
            trailing!,
          ]
        ],
      ),
    );
  }
}

class NotificationButton extends StatelessWidget {
  const NotificationButton({super.key, required this.badge, required this.onTap});
  final int badge;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: FRRadii.pill,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: ProtoColors.surface,
              borderRadius: FRRadii.all(20),
              border: Border.all(color: ProtoColors.border),
            ),
            child: const Icon(Icons.notifications_none_rounded,
                color: ProtoColors.textSecondary),
          ),
          if (badge > 0)
            Positioned(
              right: -2,
              top: -2,
              child: Container(
                width: 18,
                height: 18,
                decoration: BoxDecoration(
                  color: ProtoColors.danger,
                  borderRadius: FRRadii.all(9),
                  border: Border.all(color: ProtoColors.bgPrimary, width: 2),
                ),
                alignment: Alignment.center,
                child: Text(
                  '$badge',
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 9,
                      fontWeight: FontWeight.w700),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class ProtoSearchField extends StatelessWidget {
  const ProtoSearchField({super.key, this.hint = 'Ürün ara...', this.onTap, this.onChanged});
  final String hint;
  final VoidCallback? onTap;
  final ValueChanged<String>? onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: FRInsets.searchWrap,
      padding: FRInsets.searchContent,
      decoration: protoSurface(),
      child: Row(
        children: [
          const Icon(Icons.search, color: ProtoColors.tan),
          const SizedBox(width: 10),
          Expanded(
            child: TextField(
              onTap: onTap,
              onChanged: onChanged,
              style: const TextStyle(color: ProtoColors.textPrimary),
              decoration: InputDecoration.collapsed(
                hintText: hint,
                hintStyle: const TextStyle(color: ProtoColors.textSubtle),
              ),
            ),
          ),
          Container(
            width: 34,
            height: 34,
            decoration: const BoxDecoration(
              color: ProtoColors.surfaceAlt,
              borderRadius: FRRadii.md,
            ),
            child: const Icon(Icons.qr_code_scanner_rounded,
                color: ProtoColors.textSecondary, size: 18),
          ),
        ],
      ),
    );
  }
}

class ProtoSectionHeader extends StatelessWidget {
  const ProtoSectionHeader(this.title, {super.key, this.action});
  final String title;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: FRInsets.horizontalPage,
      child: Row(
        children: [
          Expanded(
            child: Text(title,
                style: const TextStyle(
                    color: ProtoColors.textPrimary,
                    fontWeight: FontWeight.w700,
                    fontSize: 16)),
          ),
          if (action != null) action!,
        ],
      ),
    );
  }
}

class ProtoCard extends StatelessWidget {
  const ProtoCard({super.key, required this.child, this.padding = FRInsets.card});
  final Widget child;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    return Container(padding: padding, decoration: protoSurface(), child: child);
  }
}
