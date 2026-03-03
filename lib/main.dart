import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// --- SENİN GERÇEK SAYFALARININ İMPORTLARI ---
import 'add_price/add_price_screen.dart';
import 'cart/cart_screen_v2.dart';
import 'home/home_screen.dart';
import 'profile/profile_screen.dart';
import 'search/search_screen.dart';

import 'fiyat_radar_bottom_bar.dart'; // Yaptığımız kusursuz menü

void main() {
  // Senin sistem Riverpod kullandığı için ProviderScope eklemek zorundayız
  runApp(const ProviderScope(child: FiyatRadarApp()));
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
        fontFamily: 'Outfit', 
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
  bool _isNavigating = false;

  // İŞTE BURASI DÜZELDİ: Artık boş yazılar değil, senin gerçek sayfaların var!
  // Menüde 4 sekme olduğu için burada da tam 4 sayfa var.
  final List<Widget> _pages = const [
    HomeScreen(key: PageStorageKey('home-tab')),
    SearchScreen(key: PageStorageKey('search-tab')),
    CartScreenV2(key: PageStorageKey('basket-tab')),
    ProfileScreen(key: PageStorageKey('profile-tab')),
  ];

  // Ortadaki Fiyat Ekle butonuna basıldığında çalışacak gerçek yönlendirme
  Future<void> _onFABPressed() async {
    if (_isNavigating) return;
    _isNavigating = true;
    try {
      await Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => const AddPriceScreen()),
      );
    } finally {
      _isNavigating = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAF6F0), 
      // Sayfa içeriğinin alt menünün altına kadar inmesi için kritik ayar:
      extendBody: true, 
      
      body: Stack(
        children: [
          // 1. KATMAN: GERÇEK SAYFALARIN (Geçişlerde sayfa yenilenmez, durum korunur)
          IndexedStack(
            index: _selectedIndex,
            children: _pages,
          ),

          // 2. KATMAN: EFSANE YÜZEN ALT MENÜMÜZ
          FiyatRadarBottomBar(
            currentIndex: _selectedIndex,
            onTap: (index) {
              setState(() {
                _selectedIndex = index; 
              });
            },
            onFabTap: _onFABPressed, // Gerçek yönlendirme fonksiyonunu bağladık
          ),
        ],
      ),
    );
  }
}
