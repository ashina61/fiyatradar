import 'package:flutter/material.dart';

// --- DUMMY MODELLER (Test edebilmen için eklendi) ---
class ProductModel {
  final String image;
  final String brand;
  final String name;
  final double lastPrice; // Senin düzeltmene istinaden 'price' yerine 'lastPrice' kullanıldı
  final double? oldPrice;
  final String store;
  final String discount;

  ProductModel({
    required this.image,
    required this.brand,
    required this.name,
    required this.lastPrice,
    this.oldPrice,
    required this.store,
    required this.discount,
  });
}

class MarketFlowModel {
  final String productName;
  final String storeAndUser;
  final double price;
  final String timeIcon; // Şimdilik ikon kullanıyoruz

  MarketFlowModel({
    required this.productName,
    required this.storeAndUser,
    required this.price,
    this.timeIcon = '',
  });
}

// --- ANA SAYFA ---
class HomePage extends StatelessWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF3F0EC), // Arka plan krem rengi
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.only(bottom: 100), // Bottom nav için boşluk
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(),
                const SizedBox(height: 16),
                _buildCategories(),
                const SizedBox(height: 24),
                _buildBanner(),
                const SizedBox(height: 24),
                _buildTrendProducts(),
                const SizedBox(height: 24),
                _buildMarketFlow(),
              ],
            ),
          ),
          // Custom Bottom Navigation Bar
          Positioned(
            bottom: 20,
            left: 20,
            right: 20,
            child: _buildBottomNavBar(),
          ),
        ],
      ),
    );
  }

  // 1. HEADER & ARAMA ÇUBUĞU (İstatistikler kaldırıldı)
  Widget _buildHeader() {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          padding: const EdgeInsets.only(top: 60, left: 20, right: 20, bottom: 40),
          decoration: const BoxDecoration(
            color: Color(0xFF3E2723), // Koyu kahverengi
            borderRadius: BorderRadius.only(
              bottomLeft: Radius.circular(30),
              bottomRight: Radius.circular(30),
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const CircleAvatar(
                    radius: 24,
                    backgroundImage: NetworkImage('https://i.pravatar.cc/150?img=11'), // Avatar placeholder
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      Text("Hoş geldin,", style: TextStyle(color: Colors.white70, fontSize: 12)),
                      Text("Adem Bayram", style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ],
              ),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      children: const [
                        Icon(Icons.monetization_on, color: Color(0xFFD7CCC8), size: 16),
                        SizedBox(width: 4),
                        Text("20.506", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.notifications_none, color: Colors.white, size: 20),
                  ),
                ],
              )
            ],
          ),
        ),
        Positioned(
          bottom: -25,
          left: 20,
          right: 20,
          child: Container(
            height: 50,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(25),
              boxShadow: [
                BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 5)),
              ],
            ),
            child: TextField(
              decoration: InputDecoration(
                hintText: "Ürün, marka veya market ara...",
                hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 14),
                prefixIcon: Icon(Icons.search, color: Colors.grey.shade400),
                suffixIcon: Icon(Icons.qr_code_scanner, color: Colors.grey.shade400),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(vertical: 15),
              ),
            ),
          ),
        ),
      ],
    );
  }

  // 2. KATEGORİLER (Karemsi beyaz arka plan)
  Widget _buildCategories() {
    final categories = [
      {"icon": Icons.grid_view_rounded, "name": "Tümü", "isActive": true},
      {"icon": Icons.shopping_cart_outlined, "name": "Market", "isActive": false},
      {"icon": Icons.computer_outlined, "name": "Teknoloji", "isActive": false},
      {"icon": Icons.face_retouching_natural, "name": "Kozmetik", "isActive": false},
      {"icon": Icons.sports_esports_outlined, "name": "Hobi", "isActive": false},
    ];

    return Padding(
      padding: const EdgeInsets.only(top: 30.0),
      child: SizedBox(
        height: 90,
        child: ListView.builder(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 20),
          itemCount: categories.length,
          itemBuilder: (context, index) {
            final cat = categories[index];
            final isActive = cat["isActive"] as bool;
            return Padding(
              padding: const EdgeInsets.only(right: 20),
              child: Column(
                children: [
                  Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      color: isActive ? const Color(0xFF3E2723) : Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        if (!isActive)
                          BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 4)),
                      ],
                    ),
                    child: Icon(
                      cat["icon"] as IconData,
                      color: isActive ? Colors.white : Colors.grey.shade600,
                      size: 28,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    cat["name"] as String,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: isActive ? FontWeight.bold : FontWeight.w500,
                      color: isActive ? Colors.black87 : Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  // 3. BANNER
  Widget _buildBanner() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        width: double.infinity,
        height: 140,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          color: const Color(0xFF2C2C2C), // Koyu gri/siyah arka plan
          // Gerekirse buraya DecorationImage ile arka plan resmi ekleyebilirsin
        ),
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(6)),
              child: const Text("HAFTANIN YILDIZI", style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
            ),
            const SizedBox(height: 10),
            const Text("Elektronikte\nDip Fiyatlar", style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold, height: 1.2)),
            const Spacer(),
            Row(
              children: const [
                Text("Göz At", style: TextStyle(color: Colors.white70, fontSize: 12)),
                SizedBox(width: 4),
                Icon(Icons.arrow_forward, color: Colors.white70, size: 14),
              ],
            )
          ],
        ),
      ),
    );
  }

  // 4. TREND ÜRÜNLER (Senin _OriginalProductCard widget'ın ile)
  Widget _buildTrendProducts() {
    // Dummy veriler
    final List<ProductModel> products = [
      ProductModel(
        image: 'https://via.placeholder.com/150', // Nutella resmi
        brand: 'FERRERO',
        name: 'Nutella Kakaolu Fındık\nKreması 400g',
        lastPrice: 36.00, // .price yerine .lastPrice kullanıldı
        oldPrice: 40.00,
        store: 'Trendyol M.',
        discount: '%18',
      ),
      ProductModel(
        image: 'https://via.placeholder.com/150', // Pizza resmi
        brand: 'DR. OETKER',
        name: 'Ristorante Karışık\nPizza 340g',
        lastPrice: 89.00,
        oldPrice: 110.00,
        store: 'A-101',
        discount: '%20',
      ),
    ];

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text("Trend Ürünler", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87)),
              Text("Tümünü Gör", style: TextStyle(fontSize: 12, color: Colors.orange.shade700, fontWeight: FontWeight.w600)),
            ],
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 260,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 10),
            itemCount: products.length,
            itemBuilder: (context, index) {
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10),
                child: _OriginalProductCard(product: products[index]),
              );
            },
          ),
        ),
      ],
    );
  }

  // 5. PİYASA AKIŞI (Yeni Eklenen Kısım)
  Widget _buildMarketFlow() {
    final flows = [
      MarketFlowModel(productName: "Ayçiçek Yağı 5L", storeAndUser: "BİM • Ahmet_34", price: 185.00),
      MarketFlowModel(productName: "Osmancık Pirinç 2.5Kg", storeAndUser: "A-101 • Sistem", price: 95.00),
      MarketFlowModel(productName: "Doğuş Çay 1Kg", storeAndUser: "Migros • Ceren_K", price: 145.00),
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("Piyasa Akışı", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87)),
          const SizedBox(height: 12),
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: flows.length,
            itemBuilder: (context, index) {
              final flow = flows[index];
              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 8, offset: const Offset(0, 2)),
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(color: const Color(0xFFF3F0EC), shape: BoxShape.circle),
                      child: Icon(Icons.history, color: Colors.brown.shade300, size: 20),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(flow.productName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                          const SizedBox(height: 4),
                          Text(flow.storeAndUser, style: TextStyle(color: Colors.grey.shade500, fontSize: 11)),
                        ],
                      ),
                    ),
                    Text(
                      "${flow.price.toStringAsFixed(2)}₺",
                      style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16, color: Colors.black87),
                    ),
                  ],
                ),
              );
            },
          )
        ],
      ),
    );
  }

  // 6. BOTTOM NAVIGATION BAR
  Widget _buildBottomNavBar() {
    return Container(
      height: 70,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(35),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 20, offset: const Offset(0, 5)),
        ],
      ),
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.center,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildNavItem(Icons.home_filled, "Ana Sayfa", true),
              _buildNavItem(Icons.explore_outlined, "Keşfet", false),
              const SizedBox(width: 40), // Orta buton için boşluk
              _buildNavItem(Icons.shopping_bag_outlined, "Sepetim", false),
              _buildNavItem(Icons.person_outline, "Profil", false),
            ],
          ),
          Positioned(
            top: -20,
            child: Container(
              height: 60,
              width: 60,
              decoration: BoxDecoration(
                color: const Color(0xFF5D4037),
                shape: BoxShape.circle,
                border: Border.all(color: const Color(0xFFF3F0EC), width: 4),
                boxShadow: [
                  BoxShadow(color: const Color(0xFF5D4037).withOpacity(0.4), blurRadius: 10, offset: const Offset(0, 4)),
                ],
              ),
              child: const Icon(Icons.add, color: Colors.white, size: 30),
            ),
          )
        ],
      ),
    );
  }

  Widget _buildNavItem(IconData icon, String label, bool isActive) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(icon, color: isActive ? const Color(0xFF3E2723) : Colors.grey.shade400, size: 24),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 10,
            fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
            color: isActive ? const Color(0xFF3E2723) : Colors.grey.shade500,
          ),
        )
      ],
    );
  }
}

// --- PRODUCT CARD WIDGET'I (Senin belirttiğin kurala göre uyarlandı) ---
class _OriginalProductCard extends StatelessWidget {
  final ProductModel product;

  const _OriginalProductCard({Key? key, required this.product}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // BURASI ÖNEMLİ: product.price yerine product.lastPrice kullandık
    String priceStr = "${product.lastPrice.toStringAsFixed(2)}₺";
    String oldPriceStr = product.oldPrice != null ? "${product.oldPrice!.toStringAsFixed(2)}₺" : "";

    return Container(
      width: 160,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Üst Kısım: Resim ve Etiketler
          Stack(
            children: [
              Container(
                height: 120,
                width: double.infinity,
                decoration: const BoxDecoration(
                  color: Color(0xFFF9F9F9),
                  borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
                ),
                child: Center(
                  child: Icon(Icons.image, size: 50, color: Colors.grey.shade300), // Resim placeholder
                ),
              ),
              Positioned(
                top: 8,
                left: 8,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                  decoration: BoxDecoration(color: Colors.green.shade50, borderRadius: BorderRadius.circular(4)),
                  child: Text("↘ ${product.discount}", style: TextStyle(color: Colors.green.shade700, fontSize: 10, fontWeight: FontWeight.bold)),
                ),
              ),
              Positioned(
                top: 8,
                right: 8,
                child: Icon(Icons.favorite, color: Colors.red.shade400, size: 20),
              )
            ],
          ),
          
          // Alt Kısım: Metinler ve Fiyat
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  product.brand,
                  style: TextStyle(color: Colors.grey.shade500, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 0.5),
                ),
                const SizedBox(height: 4),
                Text(
                  product.name,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, height: 1.2),
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (product.oldPrice != null)
                          Text(
                            oldPriceStr,
                            style: TextStyle(decoration: TextDecoration.lineThrough, color: Colors.grey.shade400, fontSize: 11, fontWeight: FontWeight.w600),
                          ),
                        Text(
                          priceStr, // Getter hatasını çözen değişken
                          style: const TextStyle(color: Color(0xFF8B4513), fontSize: 18, fontWeight: FontWeight.w900),
                        ),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                      decoration: BoxDecoration(color: const Color(0xFFF3F0EC), borderRadius: BorderRadius.circular(6)),
                      child: Text(
                        product.store,
                        style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Colors.grey.shade700),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          )
        ],
      ),
    );
  }
}
