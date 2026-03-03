import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Sayfanın arka plan rengi
      backgroundColor: const Color(0xFFFAF6F0), 
      
      // SADECE ANA SAYFA İÇERİĞİ OLACAK, MENÜ YOK!
      body: Center(
        child: Text(
          '🏠 Ana Sayfa',
          style: GoogleFonts.outfit(
            fontSize: 28,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF6B4226),
          ),
        ),
      ),
    );
  }
}
