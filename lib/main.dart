import 'package:flutter/material.dart';
import 'fiyat_radar_bottom_bar.dart'; // Menüyü buradan çağırıyoruz

void main() {
  runApp(const FiyatRadarApp());
}

class FiyatRadarApp extends StatelessWidget {
  const FiyatRadarApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Fiyat Radar',
      theme: ThemeData(
        primaryColor: const Color(0xFF6B4226),
        fontFamily: 'Outfit', // Fontun yüklüyse devreye girer
      ),
      home: const MainScreen(),
    );
  }
}

class MainScreen extends StatefulWidget {
  const MainScreen({Key? key}) : super(key: key);

  @override
  _MainScreenState createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0;

  // BURASI SENİN EKRANLARININ LİSTESİ
  final List<Widget> _pages = [
    const Center(child: Text("Ana Sayfa İçeriği", style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFF4A2E1B)))), 
    const Center(child: Text("Keşfet İçeriği", style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFF4A2E1B)))),    
    const Center(child: Text("Sepet İçeriği", style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFF4A2E1B)))),     
    const Center(child: Text("Profil İçeriği", style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFF4A2E1B)))),    
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAF6F0), // Ana uygulamanın bej rengi
      
      body: Stack(
        children: [
          // 1. KATMAN: SENİN SAYFALARIN (Arkada çalışır)
          IndexedStack(
            index: _selectedIndex,
            children: _pages,
          ),

          // 2. KATMAN: EFSANE YÜZEN ALT MENÜMÜZ (Sayfaların üzerine biner)
          FiyatRadarBottomBar(
            currentIndex: _selectedIndex,
            onTap: (index) {
              setState(() {
                _selectedIndex = index; 
              });
            },
            onFabTap: () {
              print("Fiyat Ekle Butonuna Basıldı!");
              // İleride buraya: Navigator.push(...) gelecek
            },
          ),
        ],
      ),
    );
  }
}
