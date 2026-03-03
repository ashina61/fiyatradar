import 'package:flutter/material.dart';
import 'fiyat_radar_bottom_bar.dart'; // ADIM 2'de oluşturduğumuz dosyayı buraya çağırıyoruz

class MainScreen extends StatefulWidget {
  @override
  _MainScreenState createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0;

  // BURASI SENİN EKRANLARININ LİSTESİ
  // Şimdilik test için boş renkli ekranlar koydum, sen buralara kendi sayfalarını yazacaksın
  // Örnek: [AnaSayfa(), KesfetSayfasi(), SepetSayfasi(), ProfilSayfasi()]
  final List<Widget> _pages = [
    Center(child: Text("Ana Sayfa İçeriği", style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold))), // 0. İndex
    Center(child: Text("Keşfet İçeriği", style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold))),    // 1. İndex
    Center(child: Text("Sepet İçeriği", style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold))),     // 2. İndex
    Center(child: Text("Profil İçeriği", style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold))),    // 3. İndex
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAF6F0), // Senin uygulamanın ana bej rengi
      
      // DİKKAT: bottomNavigationBar KULLANMIYORUZ!
      // Onun yerine tüm ekranı bir Stack (üst üste bindirme) yapısına alıyoruz.
      body: Stack(
        children: [
          
          // 1. KATMAN: SENİN SAYFALARIN
          // IndexedStack, sayfalar arası geçerken durumu korur (sayfa yenilenmez)
          IndexedStack(
            index: _selectedIndex,
            children: _pages,
          ),

          // 2. KATMAN: BİZİM YÜZEN EFSANE ALT MENÜMÜZ
          // Stack'in en altına yazdığımız için sayfaların üstünde, havada süzülecek.
          FiyatRadarBottomBar(
            currentIndex: _selectedIndex,
            onTap: (index) {
              setState(() {
                _selectedIndex = index; // Menüye tıklanınca sayfayı değiştirir
              });
            },
            onFabTap: () {
              // ORTADAKİ FİYAT EKLE BUTONUNA BASILINCA OLACAKLAR
              print("Fiyat Ekle Butonuna Basıldı!");
              // Örnek: Navigator.push(context, MaterialPageRoute(builder: (context) => FiyatEkleSayfasi()));
            },
          ),
          
        ],
      ),
    );
  }
}
