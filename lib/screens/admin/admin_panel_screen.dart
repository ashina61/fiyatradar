import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// --- PROVIDERS ---
import '../../providers/auth_provider.dart';
import '../../providers/product_provider.dart';
import '../../providers/notification_provider.dart';

// --- SAYFALAR / MODÜLLER (Kendi proje yollarına göre uyarla) ---
import '../../pages/notification_center_page.dart';
import 'admin_statistics_tab.dart';
import 'admin_catalog_tab.dart'; // İçinde Ürünler ve Kategoriler var
import 'admin_brand_management_tab.dart'; // İçinde Markalar/Şubeler var
import 'tabs/admin_marketing_tab.dart'; // İçinde Banner ve Kampanyalar var
import 'actual_management_tab.dart';
import 'admin_user_management_tab.dart';
import 'admin_product_suggestions_tab.dart';
import 'admin_reports_management_tab.dart';
import 'admin_badge_achievements_tab.dart';

// --- PREMIUM RENK PALETİ ---
const Color pBrandBrown = Color(0xFF6A442A);
const Color pBgApp = Color(0xFFF8F6F4);
const Color pSurface = Color(0xFFFFFFFF);
const Color pDarkHeader = Color(0xFF1A110D);
const Color pGold = Color(0xFFC29B78);
const Color pTextMuted = Color(0xFF8C7B70);
const Color pBorder = Color(0x1F6A442A);

class AdminPanelScreen extends ConsumerStatefulWidget {
  const AdminPanelScreen({super.key});

  @override
  ConsumerState<AdminPanelScreen> createState() => _AdminPanelScreenState();
}

class _AdminPanelScreenState extends ConsumerState<AdminPanelScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    // Sekmeleri birleştirdiğimiz için sayı düştü (Örn: 9 Ana Sekme)
    _tabController = TabController(length: 9, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final userAsync = ref.watch(userModelStreamProvider);

    return userAsync.when(
      loading: () => const Scaffold(backgroundColor: pBgApp, body: Center(child: CircularProgressIndicator(color: pBrandBrown))),
      error: (_, __) => const Scaffold(backgroundColor: pBgApp, body: Center(child: Text('Hata oluştu.'))),
      data: (user) {
        if (user?.isAdmin != true) {
          return Scaffold(
            backgroundColor: pBgApp,
            appBar: AppBar(title: const Text('Admin Paneli'), backgroundColor: pDarkHeader, foregroundColor: pSurface),
            body: const Center(child: Text('Bu sayfaya erişim yetkiniz yok.', style: TextStyle(fontWeight: FontWeight.w800))),
          );
        }
        return _buildAdminScaffold(context);
      },
    );
  }

  Scaffold _buildAdminScaffold(BuildContext context) {
    final maintenanceAsync = ref.watch(maintenanceModeProvider);
    final unreadNotificationCount = ref.watch(unreadNotificationCountProvider);

    return Scaffold(
      backgroundColor: pBgApp,
      body: SafeArea(
        top: false, // Header en tepeye yapışsın
        bottom: false,
        child: Column(
          children: [
            // 💥 1. LÜKS KOKPİT HEADER 💥
            _AdminConsoleHeader(
              unreadCount: unreadNotificationCount,
              maintenanceAsync: maintenanceAsync,
              onBack: () => Navigator.of(context).maybePop(),
              onNotificationsTap: () {
                Navigator.push(context, MaterialPageRoute(builder: (_) => const NotificationCenterPage()));
              },
            ),

            // 💥 2. KAYDIRMALI YATAY MENÜ (TAB BAR) 💥
            Container(
              decoration: const BoxDecoration(
                color: pSurface,
                border: Border(bottom: BorderSide(color: pBorder)),
                boxShadow: [BoxShadow(color: Color(0x05000000), blurRadius: 4, offset: Offset(0, 2))],
              ),
              child: TabBar(
                controller: _tabController,
                isScrollable: true,
                indicatorColor: pBrandBrown,
                indicatorWeight: 3,
                labelColor: pBrandBrown,
                unselectedLabelColor: pTextMuted,
                labelStyle: const TextStyle(fontWeight: FontWeight.w800, fontSize: 12),
                unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12),
                tabAlignment: TabAlignment.start,
                padding: const EdgeInsets.symmetric(horizontal: 8),
                tabs: const [
                  Tab(icon: Icon(Icons.donut_large, size: 20), text: 'Özet'),
                  Tab(icon: Icon(Icons.inventory_2, size: 20), text: 'Katalog'), // Ürün + Kategori
                  Tab(icon: Icon(Icons.storefront, size: 20), text: 'Şubeler'), // Marka + Şube
                  Tab(icon: Icon(Icons.campaign, size: 20), text: 'Pazarlama'), // Banner + Kampanya
                  Tab(icon: Icon(Icons.local_offer, size: 20), text: 'Aktüel'),
                  Tab(icon: Icon(Icons.groups, size: 20), text: 'Üyeler'),
                  Tab(icon: Icon(Icons.playlist_add_check, size: 20), text: 'Öneriler'),
                  Tab(icon: Icon(Icons.flag, size: 20), text: 'Raporlar'),
                  Tab(icon: Icon(Icons.military_tech, size: 20), text: 'Rozetler'),
                ],
              ),
            ),

            // 💥 3. TAB İÇERİKLERİ (MODÜLLER) 💥
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: const [
                  AdminStatisticsTab(),
                  AdminCatalogTab(), // Parçaladığımız yeni dosya
                  AdminBrandManagementTab(), // İçine şubeleri de entegre ettiğini varsayıyorum
                  AdminMarketingTab(), // Parçaladığımız yeni dosya
                  ActualManagementTab(),
                  AdminUserManagementTab(),
                  AdminProductSuggestionsTab(),
                  AdminReportsManagementTab(),
                  AdminBadgeAchievementsTab(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// PREMIUM HEADER WIDGET
// ---------------------------------------------------------------------------
class _AdminConsoleHeader extends StatelessWidget {
  final int unreadCount;
  final AsyncValue<bool> maintenanceAsync;
  final VoidCallback onBack;
  final VoidCallback onNotificationsTap;

  const _AdminConsoleHeader({
    required this.unreadCount,
    required this.maintenanceAsync,
    required this.onBack,
    required this.onNotificationsTap,
  });

  @override
  Widget build(BuildContext context) {
    final isMaintenance = maintenanceAsync.valueOrNull ?? false;

    return Container(
      padding: EdgeInsets.fromLTRB(20, MediaQuery.of(context).padding.top + 16, 20, 20),
      decoration: const BoxDecoration(
        color: pDarkHeader,
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(24)),
        boxShadow: [BoxShadow(color: Color(0x261A110D), blurRadius: 20, offset: Offset(0, 10))],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Geri Butonu
          GestureDetector(
            onTap: onBack,
            child: Container(
              width: 44, height: 44,
              decoration: BoxDecoration(color: pGold.withOpacity(0.1), borderRadius: BorderRadius.circular(14)),
              child: const Icon(Icons.arrow_back_ios_new, color: pGold, size: 20),
            ),
          ),
          
          // Başlık ve Rozet
          Column(
            children: [
              const Text('Admin Konsolu', style: TextStyle(color: pSurface, fontSize: 18, fontWeight: FontWeight.w900, letterSpacing: 0.5)),
              const SizedBox(height: 4),
              if (isMaintenance)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(color: const Color(0xFFFF3B30).withOpacity(0.15), borderRadius: BorderRadius.circular(100), border: Border.all(color: const Color(0xFFFF3B30).withOpacity(0.5))),
                  child: const Text('BAKIM MODU AKTİF', style: TextStyle(color: Color(0xFFFF3B30), fontSize: 9, fontWeight: FontWeight.w900, letterSpacing: 0.5)),
                )
              else
                const Text('Sistem İzleniyor', style: TextStyle(color: pGold, fontSize: 10, fontWeight: FontWeight.w700, letterSpacing: 0.5)),
            ],
          ),
          
          // Bildirim Butonu
          GestureDetector(
            onTap: onNotificationsTap,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Container(
                  width: 44, height: 44,
                  decoration: BoxDecoration(color: pGold.withOpacity(0.1), borderRadius: BorderRadius.circular(14)),
                  child: const Icon(Icons.notifications, color: pGold, size: 22),
                ),
                if (unreadCount > 0)
                  Positioned(
                    right: -2, top: -2,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(color: const Color(0xFFFF3B30), shape: BoxShape.circle, border: Border.all(color: pDarkHeader, width: 2)),
                      child: Text(unreadCount > 9 ? '9+' : unreadCount.toString(), style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.w900)),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
