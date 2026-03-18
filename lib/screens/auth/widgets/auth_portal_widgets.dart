import 'package:flutter/material.dart';

import '../../../theme/fr_colors.dart';
import 'package:google_fonts/google_fonts.dart';

const authBg = FRColors.backgroundWarm;
const authEspresso = FRColors.espresso;
const authCamel = FRColors.camel;
const authWhite = FRColors.surfaceSoft;
const authMuted = FRColors.textMuted;

TextStyle authText({
  double size = 14,
  FontWeight weight = FontWeight.w600,
  Color color = authEspresso,
  double? letterSpacing,
  double? height,
}) {
  return GoogleFonts.plusJakartaSans(
    fontSize: size,
    fontWeight: weight,
    color: color,
    letterSpacing: letterSpacing,
    height: height,
  );
}

class AuthSurface extends StatelessWidget {
  const AuthSurface({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: authBg,
      body: Container(
        decoration: const BoxDecoration(
          color: authBg,
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 20),
            child: child,
          ),
        ),
      ),
    );
  }
}

class AuthTopBackButton extends StatelessWidget {
  const AuthTopBackButton({super.key, required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(999),
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: authEspresso.withOpacity(.1)),
        ),
        child: const Icon(Icons.arrow_back_ios_new_rounded, size: 18, color: authEspresso),
      ),
    );
  }
}

class AuthHeaderTexts extends StatelessWidget {
  const AuthHeaderTexts({super.key, required this.title, required this.subtitle});

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: authText(size: 32, weight: FontWeight.w900, letterSpacing: -1.1, height: 1.1)),
        const SizedBox(height: 8),
        Text(subtitle, style: authText(size: 14, weight: FontWeight.w600, color: authMuted, height: 1.45)),
      ],
    );
  }
}

class AuthInputField extends StatelessWidget {
  const AuthInputField({
    super.key,
    required this.label,
    required this.hint,
    required this.icon,
    this.controller,
    this.obscureText = false,
    this.suffix,
    this.keyboardType,
    this.readOnly = false,
    this.onTap,
    this.validator,
    this.textInputAction,
    this.onFieldSubmitted,
  });

  final String label;
  final String hint;
  final IconData icon;
  final TextEditingController? controller;
  final bool obscureText;
  final Widget? suffix;
  final TextInputType? keyboardType;
  final bool readOnly;
  final VoidCallback? onTap;
  final String? Function(String?)? validator;
  final TextInputAction? textInputAction;
  final ValueChanged<String>? onFieldSubmitted;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 6),
          child: Text(label.toUpperCase(), style: authText(size: 11, weight: FontWeight.w800, letterSpacing: .5)),
        ),
        Container(
          height: 64,
          decoration: BoxDecoration(
            color: authWhite,
            borderRadius: BorderRadius.circular(20),
            boxShadow: const [
              BoxShadow(color: Color.fromRGBO(28, 17, 8, .05), blurRadius: 18, offset: Offset(0, 6)),
            ],
          ),
          child: TextFormField(
            controller: controller,
            obscureText: obscureText,
            keyboardType: keyboardType,
            readOnly: readOnly,
            onTap: onTap,
            validator: validator,
            textInputAction: textInputAction,
            onFieldSubmitted: onFieldSubmitted,
            style: authText(size: 15, weight: FontWeight.w600),
            decoration: InputDecoration(
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(20),
                borderSide: BorderSide.none,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(20),
                borderSide: BorderSide.none,
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(20),
                borderSide: const BorderSide(color: authCamel, width: 2),
              ),
              hintText: hint,
              hintStyle: authText(size: 15, weight: FontWeight.w500, color: FRColors.textHint),
              prefixIcon: Icon(icon, color: authMuted, size: 20),
              suffixIcon: suffix,
            ),
          ),
        ),
      ],
    );
  }
}

class MassivePrimaryButton extends StatelessWidget {
  const MassivePrimaryButton({super.key, required this.label, required this.onPressed, this.loading = false, this.icon});

  final String label;
  final VoidCallback? onPressed;
  final bool loading;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 64,
      child: ElevatedButton(
        onPressed: loading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          elevation: 0,
          shadowColor: const Color(0x00000000),
          backgroundColor: authEspresso,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        ),
        child: loading
            ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2.2, color: Colors.white))
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(label, style: authText(size: 16, weight: FontWeight.w800, color: Colors.white)),
                  if (icon != null) ...[
                    const SizedBox(width: 8),
                    Icon(icon, size: 20, color: Colors.white),
                  ],
                ],
              ),
      ),
    );
  }
}

class SocialDivider extends StatelessWidget {
  const SocialDivider({super.key, this.text = 'Veya Şununla'});
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(child: Container(height: 1, color: authEspresso.withOpacity(.1))),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Text(text.toUpperCase(), style: authText(size: 11, weight: FontWeight.w700, color: authMuted, letterSpacing: .5)),
        ),
        Expanded(child: Container(height: 1, color: authEspresso.withOpacity(.1))),
      ],
    );
  }
}

class SocialButton extends StatelessWidget {
  const SocialButton({super.key, required this.label, required this.onPressed, required this.badgeText, this.disabled = false});

  final String label;
  final VoidCallback? onPressed;
  final String badgeText;
  final bool disabled;

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: disabled ? .5 : 1,
      child: SizedBox(
        height: 56,
        child: OutlinedButton(
          onPressed: disabled ? null : onPressed,
          style: OutlinedButton.styleFrom(
            side: BorderSide(color: authEspresso.withOpacity(.06)),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            backgroundColor: authWhite,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 20,
                height: 20,
                decoration: BoxDecoration(color: badgeText == '' ? Colors.black : const Color(0xFFEA4335), shape: BoxShape.circle),
                alignment: Alignment.center,
                child: Text(badgeText, style: authText(size: 11, weight: FontWeight.w900, color: Colors.white)),
              ),
              const SizedBox(width: 8),
              Text(label, style: authText(size: 13, weight: FontWeight.w800)),
            ],
          ),
        ),
      ),
    );
  }
}

class RememberMeCheckbox extends StatelessWidget {
  const RememberMeCheckbox({super.key, required this.value, required this.onChanged});

  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => onChanged(!value),
      borderRadius: BorderRadius.circular(8),
      child: Row(
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            width: 18,
            height: 18,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(6),
              color: value ? authEspresso : Colors.transparent,
              border: Border.all(color: value ? authEspresso : const Color(0xFFC4B9B1), width: 2),
            ),
            child: value ? const Icon(Icons.check, size: 13, color: Colors.white) : null,
          ),
          const SizedBox(width: 8),
          Text('Beni Hatırla', style: authText(size: 13, weight: FontWeight.w600)),
        ],
      ),
    );
  }
}
