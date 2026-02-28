import 'package:flutter/material.dart';

class AnimatedFloatingInput extends StatefulWidget {
  final String label;
  final TextEditingController controller;
  final bool isPassword;

  const AnimatedFloatingInput({
    super.key,
    required this.label,
    required this.controller,
    this.isPassword = false,
  });

  @override
  State<AnimatedFloatingInput> createState() => _AnimatedFloatingInputState();
}

class _AnimatedFloatingInputState extends State<AnimatedFloatingInput> {
  final FocusNode _focusNode = FocusNode();
  bool _isFocused = false;

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(() {
      setState(() {
        _isFocused = _focusNode.hasFocus;
      });
    });
  }

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // İçinde yazı varsa veya inputa tıklanmışsa etiket yukarı kayar
    final bool isFloating = _isFocused || widget.controller.text.isNotEmpty;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: Stack(
        alignment: Alignment.centerLeft,
        children: [
          // Animasyonlu Yüzen Etiket
          AnimatedPositioned(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeInOut,
            top: isFloating ? 0 : 16, // Tıklanınca yukarı çıkar
            left: 0,
            child: AnimatedDefaultTextStyle(
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeInOut,
              style: TextStyle(
                color: isFloating ? const Color(0xFF8B4D22) : const Color(0xFF8E8A86), // Odaklanınca Karamel olur
                fontSize: isFloating ? 12 : 16,
                fontWeight: isFloating ? FontWeight.bold : FontWeight.w500,
              ),
              child: Text(widget.label),
            ),
          ),
          // Gerçek Input Alanı
          Container(
            padding: const EdgeInsets.only(top: 16), // Etikete yer açmak için üstten boşluk
            child: TextField(
              controller: widget.controller,
              focusNode: _focusNode,
              obscureText: widget.isPassword,
              style: const TextStyle(color: Color(0xFF2D241E), fontSize: 16, fontWeight: FontWeight.w600),
              decoration: const InputDecoration(
                border: InputBorder.none,
                isDense: true,
                contentPadding: EdgeInsets.symmetric(vertical: 8),
              ),
              onChanged: (val) => setState(() {}), // Yazı yazıldıkça state güncellensin ki etiket inmesin
            ),
          ),
        ],
      ),
    );
  }
}
