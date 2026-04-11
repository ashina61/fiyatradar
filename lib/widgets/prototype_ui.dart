import 'package:flutter/material.dart';

class ProtoColors {
  static const bgPrimary = Color(0xFF1A1614);
  static const bgSecondary = Color(0xFF24201D);
  static const surface = Color(0xFF2A2522);
  static const surfaceAlt = Color(0xFF312C29);
  static const surfaceElevated = Color(0xFF3D3633);
  static const border = Color(0x663D3633);
  static const borderLight = Color(0x14F5F1ED);

  static const textPrimary = Color(0xFFF7F3EF);
  static const textSecondary = Color(0xFFAFA398);
  static const textSubtle = Color(0xFF8F8680);

  static const tan = Color(0xFFC4A57B);
  static const tanLight = Color(0xFFD4B896);
  static const tanDark = Color(0xFF9A8260);

  static const success = Color(0xFF8A9A8B);
  static const danger = Color(0xFFA67B7B);
  static const warning = Color(0xFFB58B7A);
  static const purple = Color(0xFF8A7BA6);
}

class ProtoRadius {
  static const sm = 8.0;
  static const md = 10.0;
  static const lg = 14.0;
  static const xl = 18.0;
  static const xxl = 22.0;
}

class ProtoSpacing {
  static const s = 8.0;
  static const m = 12.0;
  static const l = 16.0;
  static const xl = 24.0;
}

BoxDecoration protoSurface({double radius = ProtoRadius.xl}) => BoxDecoration(
      color: ProtoColors.surface,
      borderRadius: BorderRadius.circular(radius),
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
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 10),
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
      borderRadius: BorderRadius.circular(99),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: ProtoColors.surface,
              borderRadius: BorderRadius.circular(20),
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
                  borderRadius: BorderRadius.circular(9),
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
      margin: const EdgeInsets.fromLTRB(24, 0, 24, 16),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
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
            decoration: BoxDecoration(
              color: ProtoColors.surfaceAlt,
              borderRadius: BorderRadius.circular(10),
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
      padding: const EdgeInsets.symmetric(horizontal: 24),
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
  const ProtoCard({super.key, required this.child, this.padding = const EdgeInsets.all(14)});
  final Widget child;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    return Container(padding: padding, decoration: protoSurface(), child: child);
  }
}
