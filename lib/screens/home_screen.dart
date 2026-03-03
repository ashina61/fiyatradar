// FILE: lib/screens/home_screen.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../widgets/dynamic_bottom_dock.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;

  late final List<Widget> _pages = [
    _buildPage('🏠 Ana Sayfa'),
    _buildPage('🔍 Keşfet'),
    _buildPage('🛒 Sepet'),
    _buildPage('👤 Profil'),
  ];

  Widget _buildPage(String text) {
    return Center(
      child: Text(
        text,
        style: GoogleFonts.outfit(
          fontSize: 28,
          fontWeight: FontWeight.w600,
          color: const Color(0xFF6B4226),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFEAD8C8),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 380, maxHeight: 750),
          child: Container(
            decoration: BoxDecoration(
              color: const Color(0xFFFAF6F0),
              borderRadius: BorderRadius.circular(40),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF6B4226).withOpacity(0.25),
                  blurRadius: 50,
                  offset: const Offset(0, 25),
                  spreadRadius: -12,
                ),
              ],
            ),
            clipBehavior: Clip.antiAlias,
            child: Stack(
              children: [
                Padding(
                  padding: const EdgeInsets.only(bottom: 110),
                  child: _pages[_selectedIndex],
                ),
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 0,
                  child: DynamicBottomDock(
                    initialIndex: _selectedIndex,
                    onTabChanged: (index) {
                      setState(() => _selectedIndex = index);
                    },
                    onCenterAction: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            'Yeni işlem başlatılıyor',
                            style: GoogleFonts.outfit(fontWeight: FontWeight.w500),
                          ),
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
