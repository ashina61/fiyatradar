import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../utils/theme.dart';
import '../../services/mock_data_service.dart';
import '../../providers/theme_provider.dart';
import '../admin/admin_panel_screen.dart';
import '../auth/login_screen.dart';
import '../product/product_detail_screen.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mockUser = MockDataService().currentUser;
    final themeMode = ref.watch(themeModeProvider);
    final isDark = themeMode == ThemeMode.dark;
    final theme = Theme.of(context);
    const bool isAdmin = true;

    return Scaffold(
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildProfileHeader(context, mockUser),
            Transform.translate(
              offset: const Offset(0, -36),
              child: _buildStatsRow(context, theme),
            ),

            // Badges
            Padding(
              padding: const EdgeInsets.fromLTRB(
                  AppSpacing.md, 0, AppSpacing.md, AppSpacing.sm),
              child: Text(
                'Rozetler',
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            _buildBadgesSection(context),
            const SizedBox(height: AppSpacing.lg),

            // Menu Group 1
            _buildMenuCard(context, theme, items: [
              _MenuItem(
                icon: Icons.bookmark_outline,
                title: 'Kaydedilen Urunler',
                onTap: () => _showSavedProducts(context),
              ),
              _MenuItem(
                icon: Icons.history,
                title: 'Fiyat Gecmisim',
                onTap: () => _showPriceHistory(context),
              ),
              _MenuItem(
                icon: Icons.stars_outlined,
                title: 'Puan Sistemi',
                onTap: () => _showPointsSystem(context),
              ),
              _MenuItem(
                icon: Icons.settings_outlined,
                title: 'Ayarlar',
                onTap: () => _showSettings(context, ref),
              ),
            ]),
            const SizedBox(height: AppSpacing.md),

            // Menu Group 2
            _buildMenuCard(context, theme, items: [
              _MenuItem(
                icon: Icons.dark_mode_outlined,
                title: 'Karanlik Mod',
                trailing: Switch(
                  value: isDark,
                  onChanged: (val) {
                    ref.read(themeModeProvider.notifier).toggleDarkMode();
                  },
                  activeColor: AppColors.primary,
                ),
              ),
              _MenuItem(
                icon: Icons.notifications_outlined,
                title: 'Bildirim Ayarlari',
                onTap: () => _showNotificationSettings(context),
              ),
            ]),
            const SizedBox(height: AppSpacing.md),

            // Menu Group 3
            _buildMenuCard(context, theme, items: [
              _MenuItem(
                icon: Icons.help_outline,
                title: 'Yardim & Destek',
                onTap: () => _showHelpSupport(context),
              ),
              _MenuItem(
                icon: Icons.feedback_outlined,
                title: 'Geri Bildirim',
                onTap: () => _showFeedbackDialog(context),
              ),
              _MenuItem(
                icon: Icons.info_outline,
                title: 'Hakkinda',
                onTap: () => _showAboutDialog(context),
              ),
            ]),
            const SizedBox(height: AppSpacing.md),

            if (isAdmin) _buildAdminSection(context, theme),

            // Sign Out
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
              child: Card(
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppRadius.lg),
                  side: BorderSide(color: AppColors.error.withOpacity(0.2)),
                ),
                child: ListTile(
                  leading: const Icon(Icons.logout, color: AppColors.error),
                  title: const Text(
                    'Cikis Yap',
                    style: TextStyle(
                      color: AppColors.error,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppRadius.lg),
                  ),
                  onTap: () {
                    showDialog(
                      context: context,
                      builder: (ctx) => AlertDialog(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(AppRadius.lg),
                        ),
                        title: const Text('Cikis Yap'),
                        content: const Text('Cikis yapmak istediginize emin misiniz?'),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(ctx),
                            child: const Text('Iptal'),
                          ),
                          ElevatedButton(
                            onPressed: () {
                              Navigator.pop(ctx);
                              Navigator.of(context).pushAndRemoveUntil(
                                MaterialPageRoute(
                                    builder: (_) => const LoginScreen()),
                                (route) => false,
                              );
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.error,
                            ),
                            child: const Text('Cikis Yap',
                                style: TextStyle(color: Colors.white)),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.lg),

            Center(
              child: Text(
                'FiyatRadar v1.0.0',
                style: TextStyle(fontSize: 12, color: theme.hintColor),
              ),
            ),
            const SizedBox(height: AppSpacing.xl),
          ],
        ),
      ),
    );
  }

  // ===========================================================================
  // Active Feature Handlers
  // ===========================================================================

  void _showSavedProducts(BuildContext context) {
    final saved = MockDataService().savedProducts;
    Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => Scaffold(
        appBar: AppBar(title: const Text('Kaydedilen Urunler')),
        body: saved.isEmpty
            ? const Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.bookmark_outline, size: 64, color: AppColors.textTertiary),
                    SizedBox(height: AppSpacing.md),
                    Text('Kaydedilen urun yok', style: TextStyle(color: AppColors.textSecondary)),
                  ],
                ),
              )
            : ListView.builder(
                padding: const EdgeInsets.all(AppSpacing.md),
                itemCount: saved.length,
                itemBuilder: (context, i) {
                  final p = saved[i];
                  return Card(
                    margin: const EdgeInsets.only(bottom: AppSpacing.sm),
                    child: ListTile(
                      leading: Container(
                        width: 44, height: 44,
                        decoration: BoxDecoration(
                          color: AppColors.primary.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(AppRadius.sm),
                        ),
                        child: const Icon(Icons.shopping_bag_outlined, color: AppColors.primary),
                      ),
                      title: Text(p.name, maxLines: 1, overflow: TextOverflow.ellipsis),
                      subtitle: Text('${p.store} - ${p.currentPrice.toStringAsFixed(2)} TL'),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => ProductDetailScreen(productId: p.id)),
                      ),
                    ),
                  );
                },
              ),
      ),
    ));
  }

  void _showPriceHistory(BuildContext context) {
    final products = MockDataService().products.take(5).toList();
    Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => Scaffold(
        appBar: AppBar(title: const Text('Fiyat Gecmisim')),
        body: ListView.builder(
          padding: const EdgeInsets.all(AppSpacing.md),
          itemCount: products.length,
          itemBuilder: (context, i) {
            final p = products[i];
            final daysAgo = DateTime.now().difference(p.addedAt).inHours;
            return Card(
              margin: const EdgeInsets.only(bottom: AppSpacing.sm),
              child: ListTile(
                leading: Container(
                  width: 44, height: 44,
                  decoration: BoxDecoration(
                    color: AppColors.secondary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(AppRadius.sm),
                  ),
                  child: const Icon(Icons.history, color: AppColors.secondary),
                ),
                title: Text(p.name, maxLines: 1, overflow: TextOverflow.ellipsis),
                subtitle: Text('${p.currentPrice.toStringAsFixed(2)} TL - ${daysAgo}s once'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => ProductDetailScreen(productId: p.id)),
                ),
              ),
            );
          },
        ),
      ),
    ));
  }

  void _showSettings(BuildContext context, WidgetRef ref) {
    final themeMode = ref.read(themeModeProvider);
    Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => Scaffold(
        appBar: AppBar(title: const Text('Ayarlar')),
        body: ListView(
          padding: const EdgeInsets.all(AppSpacing.md),
          children: [
            Card(
              child: Column(children: [
                ListTile(
                  leading: const Icon(Icons.language, color: AppColors.primary),
                  title: const Text('Dil'),
                  subtitle: const Text('Turkce'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {},
                ),
                const Divider(height: 1, indent: 56),
                ListTile(
                  leading: const Icon(Icons.palette, color: AppColors.primary),
                  title: const Text('Tema'),
                  subtitle: Text(themeMode == ThemeMode.dark ? 'Karanlik' : 'Aydinlik'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {},
                ),
                const Divider(height: 1, indent: 56),
                ListTile(
                  leading: const Icon(Icons.storage, color: AppColors.primary),
                  title: const Text('Onbellek Temizle'),
                  subtitle: const Text('12.5 MB'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Onbellek temizlendi'), behavior: SnackBarBehavior.floating),
                    );
                  },
                ),
              ]),
            ),
          ],
        ),
      ),
    ));
  }

  void _showNotificationSettings(BuildContext context) {
    Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => _NotificationSettingsPage(),
    ));
  }

  void _showHelpSupport(BuildContext context) {
    Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => Scaffold(
        appBar: AppBar(title: const Text('Yardim & Destek')),
        body: ListView(
          padding: const EdgeInsets.all(AppSpacing.md),
          children: [
            _buildFaqItem('FiyatRadar nedir?',
                'FiyatRadar, farkli magazalardaki urun fiyatlarini karsilastirmaniza ve takip etmenize yardimci olan bir uygulamadir.'),
            _buildFaqItem('Fiyat nasil eklenir?',
                'Alt barda bulunan + butonuna basarak yeni fiyat ekleyebilirsiniz. Urun secin, magaza secin ve fiyati girin.'),
            _buildFaqItem('Puan sistemi nasil calisir?',
                'Fiyat eklediginizde, dogrulama yaptiginizda ve topluluga katki sagladiginizda puan kazanirsiniz.'),
            _buildFaqItem('Bildirimleri nasil kapatirim?',
                'Profil > Bildirim Ayarlari bolumunden bildirim tercihlerinizi yonetebilirsiniz.'),
            const SizedBox(height: AppSpacing.lg),
            Card(
              child: ListTile(
                leading: const Icon(Icons.email_outlined, color: AppColors.primary),
                title: const Text('Bize Ulasin'),
                subtitle: const Text('destek@fiyatradar.com'),
                onTap: () {},
              ),
            ),
          ],
        ),
      ),
    ));
  }

  Widget _buildFaqItem(String question, String answer) {
    return Card(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: ExpansionTile(
        title: Text(question, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
        childrenPadding: const EdgeInsets.fromLTRB(AppSpacing.md, 0, AppSpacing.md, AppSpacing.md),
        children: [Text(answer, style: const TextStyle(fontSize: 13, color: AppColors.textSecondary))],
      ),
    );
  }

  void _showFeedbackDialog(BuildContext context) {
    final controller = TextEditingController();
    int rating = 0;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.lg)),
          title: Row(children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.accent.withOpacity(0.1),
                borderRadius: BorderRadius.circular(AppRadius.sm),
              ),
              child: const Icon(Icons.feedback_outlined, color: AppColors.accent, size: 20),
            ),
            const SizedBox(width: AppSpacing.sm),
            const Text('Geri Bildirim'),
          ]),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Uygulamayi nasil buldunuz?'),
              const SizedBox(height: AppSpacing.md),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(5, (i) => IconButton(
                  icon: Icon(
                    i < rating ? Icons.star : Icons.star_border,
                    color: AppColors.accent,
                    size: 32,
                  ),
                  onPressed: () => setDialogState(() => rating = i + 1),
                )),
              ),
              const SizedBox(height: AppSpacing.md),
              TextField(
                controller: controller,
                maxLines: 3,
                decoration: const InputDecoration(
                  hintText: 'Goruslerinizi yazin...',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Iptal')),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Geri bildiriminiz icin tesekkurler!'),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              },
              child: const Text('Gonder'),
            ),
          ],
        ),
      ),
    );
  }

  void _showPointsSystem(BuildContext context) {
    Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => Scaffold(
        appBar: AppBar(title: const Text('Puan Sistemi')),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            // Header
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(AppSpacing.lg),
              decoration: BoxDecoration(
                gradient: const LinearGradient(colors: [AppColors.accent, Color(0xFFFF8C00)]),
                borderRadius: BorderRadius.circular(AppRadius.lg),
              ),
              child: Column(children: [
                const Icon(Icons.stars, color: Colors.white, size: 48),
                const SizedBox(height: AppSpacing.sm),
                const Text('1250 Puan', style: TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Text('Seviye: Altin Uye', style: TextStyle(color: Colors.white.withOpacity(0.9), fontSize: 14)),
              ]),
            ),
            const SizedBox(height: AppSpacing.lg),

            const Text('Puan Kazanma Yollari', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: AppSpacing.md),

            _buildPointRow(Icons.add_shopping_cart, 'Fiyat Ekleme', '+10 Puan', 'Her yeni fiyat girisi icin', AppColors.primary),
            _buildPointRow(Icons.camera_alt, 'Fotografli Fiyat', '+20 Puan', 'Fotograf ile fiyat ekleme', AppColors.secondary),
            _buildPointRow(Icons.verified, 'Fiyat Dogrulama', '+5 Puan', 'Baskalarinin fiyatlarini dogrulama', AppColors.success),
            _buildPointRow(Icons.comment, 'Yorum Yazma', '+3 Puan', 'Urun hakkinda yorum birakma', AppColors.info),
            _buildPointRow(Icons.report, 'Yanlis Fiyat Bildirme', '+8 Puan', 'Yanlis fiyatlari raporlama', AppColors.error),
            _buildPointRow(Icons.person_add, 'Arkadas Davet Etme', '+50 Puan', 'Davet linki ile yeni uye', AppColors.accent),
            _buildPointRow(Icons.emoji_events, 'Gunluk Giris', '+2 Puan', 'Her gun uygulamaya giris yapma', const Color(0xFF8B5CF6)),

            const SizedBox(height: AppSpacing.lg),
            const Text('Seviye Sistemi', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: AppSpacing.md),

            _buildLevelRow('Bronz', '0 - 100 Puan', const Color(0xFFCD7F32)),
            _buildLevelRow('Gumus', '100 - 500 Puan', const Color(0xFFC0C0C0)),
            _buildLevelRow('Altin', '500 - 2000 Puan', AppColors.accent),
            _buildLevelRow('Platin', '2000 - 5000 Puan', AppColors.primary),
            _buildLevelRow('Elmas', '5000+ Puan', const Color(0xFF00BCD4)),

            const SizedBox(height: AppSpacing.lg),
            const Text('Avantajlar', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: AppSpacing.md),
            Card(child: Column(children: const [
              ListTile(leading: Icon(Icons.notifications_active, color: AppColors.primary), title: Text('Oncelikli bildirimler'), subtitle: Text('Fiyat dususlerinden ilk siz haberdar olun')),
              Divider(height: 1, indent: 56),
              ListTile(leading: Icon(Icons.workspace_premium, color: AppColors.accent), title: Text('Ozel rozetler'), subtitle: Text('Profilinizde ozel rozetler sergileyin')),
              Divider(height: 1, indent: 56),
              ListTile(leading: Icon(Icons.leaderboard, color: AppColors.secondary), title: Text('Liderlik tablosu'), subtitle: Text('En aktif uyelerin siralama listesi')),
            ])),

            const SizedBox(height: AppSpacing.xl),
          ]),
        ),
      ),
    ));
  }

  Widget _buildPointRow(IconData icon, String title, String points, String desc, Color color) {
    return Card(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: ListTile(
        leading: Container(
          width: 44, height: 44,
          decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(AppRadius.sm)),
          child: Icon(icon, color: color, size: 22),
        ),
        title: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Flexible(child: Text(title, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14))),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(AppRadius.sm)),
            child: Text(points, style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 12)),
          ),
        ]),
        subtitle: Text(desc, style: const TextStyle(fontSize: 12)),
      ),
    );
  }

  Widget _buildLevelRow(String level, String range, Color color) {
    return Card(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: ListTile(
        leading: Container(
          width: 40, height: 40,
          decoration: BoxDecoration(color: color.withOpacity(0.15), shape: BoxShape.circle, border: Border.all(color: color, width: 2)),
          child: Icon(Icons.shield, color: color, size: 20),
        ),
        title: Text(level, style: TextStyle(fontWeight: FontWeight.bold, color: color)),
        trailing: Text(range, style: const TextStyle(fontSize: 12)),
      ),
    );
  }

  void _showAboutDialog(BuildContext context) {
    Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => Scaffold(
        appBar: AppBar(title: const Text('Hakkinda')),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            // App logo
            Center(child: Column(children: [
              Container(
                width: 80, height: 80,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(colors: [AppColors.primary, AppColors.secondary]),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Icon(Icons.radar, size: 48, color: Colors.white),
              ),
              const SizedBox(height: AppSpacing.md),
              const Text('FiyatRadar', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
              const SizedBox(height: AppSpacing.xs),
              Text('Versiyon 1.0.0', style: TextStyle(color: Theme.of(context).hintColor)),
              const SizedBox(height: AppSpacing.sm),
              const Text(
                'Turkiye\'nin en akilli fiyat takip uygulamasi.\nTopluluk destekli fiyat karsilastirmasi ve bildirimler.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 13),
              ),
            ])),
            const SizedBox(height: AppSpacing.xl),

            // Update History
            const Text('Guncelleme Gecmisi', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: AppSpacing.md),

            _buildUpdateItem(context, 'v1.0.0', 'Subat 2025', 'Ilk Surum', [
              'Uygulama temelden insa edildi',
              'Firebase entegrasyonu ve kimlik dogrulama',
              'Flutter 3.16+ ve Material Design 3 tasarim',
              'Riverpod durum yonetimi altyapisi',
              'GitHub Actions CI/CD pipeline',
              'Urun, magaza ve kategori yonetimi',
            ]),
            _buildUpdateItem(context, 'v1.1.0', 'Subat 2025', 'Mock Data ve Premium Tasarim', [
              'Firebase devre disi birakildi, mock data servisi eklendi',
              '10 demo urun, 10 magaza, 10 kategori',
              'Premium UI tasarimi - gradientler, animasyonlar',
              'Onboarding tutorial (3 sayfa)',
              'Login ekrani - demo mod destegi',
              'Anasayfa: profil resmi, karsilama, bildirim cani',
              'Banner carousel ve kategori tarama',
              'Trending urunler ve en iyi firsatlar',
              'Arama ekrani: filtreler, siralama, grid/liste gorunumu',
              'Profil: istatistikler, rozetler, ayarlar menusu',
              'Bildirimler: filtre sekmeleri, kaydir-sil',
              'Urun detay: fiyat grafigi, topluluk dogrulamasi',
              'Admin paneli: urun/magaza/kategori CRUD',
              'Yeni uygulama simgesi',
            ]),
            _buildUpdateItem(context, 'v1.2.0', 'Subat 2025', 'Banner Yonetimi ve Dark Mode', [
              'Admin paneline banner yonetimi eklendi',
              'Banner resim destegi (URL ile)',
              'Banner aktif/pasif durumu',
              'Karanlik mod toggle - SharedPreferences ile kalici',
              'Dark mode tum ekranlarda sorunsuz calisir',
              'Profil sayfasi tamamen aktif: kaydedilen urunler, fiyat gecmisi, ayarlar, bildirim ayarlari, yardim & destek, geri bildirim, hakkinda, cikis',
              'Admin istatistikler pixel overflow duzeltildi',
              'Puan sistemi aciklama sayfasi',
              'Fiyat ekleme ekrani: TL simgesi, konum secimi',
              'Firebase yapilandirmasi gomuldu (gercek API anahtarlari)',
              'Hakkinda sayfasi guncelleme gecmisi',
            ]),

            const SizedBox(height: AppSpacing.lg),
            const Divider(),
            const SizedBox(height: AppSpacing.md),

            Center(child: Column(children: [
              Text('2024-2025 FiyatRadar', style: TextStyle(fontSize: 12, color: Theme.of(context).hintColor)),
              const SizedBox(height: 4),
              Text('Tum haklari saklidir.', style: TextStyle(fontSize: 11, color: Theme.of(context).hintColor)),
            ])),
            const SizedBox(height: AppSpacing.xl),
          ]),
        ),
      ),
    ));
  }

  Widget _buildUpdateItem(BuildContext context, String version, String date, String title, List<String> changes) {
    return Card(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(color: AppColors.primary.withOpacity(0.1), borderRadius: BorderRadius.circular(AppRadius.sm)),
              child: Text(version, style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold, fontSize: 13)),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(child: Text(title, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14))),
          ]),
          const SizedBox(height: 4),
          Text(date, style: TextStyle(fontSize: 11, color: Theme.of(context).hintColor)),
          const SizedBox(height: AppSpacing.sm),
          ...changes.map((c) => Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text('\u2022 ', style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold)),
              Expanded(child: Text(c, style: const TextStyle(fontSize: 12))),
            ]),
          )),
        ]),
      ),
    );
  }

  // ===========================================================================
  // Profile Header
  // ===========================================================================
  Widget _buildProfileHeader(BuildContext context, MockUser user) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + AppSpacing.lg,
        bottom: AppSpacing.xxl + 12,
        left: AppSpacing.lg,
        right: AppSpacing.lg,
      ),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.primary, AppColors.secondary],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Stack(
        children: [
          Positioned(
            top: 0, right: 0,
            child: IconButton(
              icon: const Icon(Icons.edit, color: Colors.white70, size: 22),
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Profil duzenleme demo modda kulanilamaz'), behavior: SnackBarBehavior.floating),
                );
              },
            ),
          ),
          Center(
            child: Column(children: [
              Container(
                width: 100, height: 100,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(colors: [
                    AppColors.primaryLight.withOpacity(0.8),
                    AppColors.secondaryLight.withOpacity(0.8),
                  ], begin: Alignment.topLeft, end: Alignment.bottomRight),
                  boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 16, offset: const Offset(0, 6))],
                ),
                child: Center(
                  child: Text(user.initial, style: const TextStyle(fontSize: 40, fontWeight: FontWeight.bold, color: Colors.white)),
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              Text(user.displayName, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white)),
              const SizedBox(height: AppSpacing.xs),
              Text(user.email, style: const TextStyle(fontSize: 14, color: Colors.white70)),
            ]),
          ),
        ],
      ),
    );
  }

  // ===========================================================================
  // Stats Row
  // ===========================================================================
  Widget _buildStatsRow(BuildContext context, ThemeData theme) {
    final cardColor = theme.cardColor;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
      child: Row(children: [
        Expanded(child: _buildStatCard(context, cardColor, value: '45', label: 'Fiyat Girisi', icon: Icons.price_change, color: AppColors.primary)),
        const SizedBox(width: AppSpacing.sm),
        Expanded(child: _buildStatCard(context, cardColor, value: '1250', label: 'Puan', icon: Icons.stars, color: AppColors.accent)),
        const SizedBox(width: AppSpacing.sm),
        Expanded(child: _buildStatCard(context, cardColor, value: '120', label: 'Dogrulama', icon: Icons.verified, color: AppColors.secondary)),
      ]),
    );
  }

  Widget _buildStatCard(BuildContext context, Color cardColor, {
    required String value, required String label, required IconData icon, required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.md, horizontal: AppSpacing.sm),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 16, offset: const Offset(0, 4))],
      ),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, color: color, size: 24),
        const SizedBox(height: AppSpacing.xs),
        Text(value, style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: color)),
        const SizedBox(height: 2),
        Text(label, style: TextStyle(fontSize: 11, color: Theme.of(context).hintColor), textAlign: TextAlign.center),
      ]),
    );
  }

  // ===========================================================================
  // Badges
  // ===========================================================================
  Widget _buildBadgesSection(BuildContext context) {
    final badges = [
      _BadgeItem(emoji: '\u{1F3C6}', name: 'Fiyat Avcisi', description: '50+ fiyat girisi', color: AppColors.accent),
      _BadgeItem(emoji: '\u{2B50}', name: 'Guvenilir Uye', description: '100+ dogrulama', color: AppColors.primary),
      _BadgeItem(emoji: '\u{1F525}', name: 'Trend Belirleyici', description: '10+ trend urun', color: AppColors.error),
      _BadgeItem(emoji: '\u{1F6E1}', name: 'Dogrulayici', description: '50+ dogrulama', color: AppColors.secondary),
    ];

    return SizedBox(
      height: 120,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
        itemCount: badges.length,
        separatorBuilder: (_, __) => const SizedBox(width: AppSpacing.md),
        itemBuilder: (context, index) {
          final badge = badges[index];
          return SizedBox(
            width: 90,
            child: Column(children: [
              Container(
                width: 64, height: 64,
                decoration: BoxDecoration(
                  color: badge.color.withOpacity(0.12),
                  shape: BoxShape.circle,
                  border: Border.all(color: badge.color.withOpacity(0.3), width: 2),
                ),
                child: Center(child: Text(badge.emoji, style: const TextStyle(fontSize: 28))),
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(badge.name, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Theme.of(context).textTheme.bodyMedium?.color), textAlign: TextAlign.center, maxLines: 2, overflow: TextOverflow.ellipsis),
            ]),
          );
        },
      ),
    );
  }

  // ===========================================================================
  // Menu Card
  // ===========================================================================
  Widget _buildMenuCard(BuildContext context, ThemeData theme, {required List<_MenuItem> items}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
      child: Container(
        decoration: BoxDecoration(
          color: theme.cardColor,
          borderRadius: BorderRadius.circular(AppRadius.lg),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 12, offset: const Offset(0, 2))],
        ),
        child: Column(
          children: List.generate(items.length, (index) {
            final item = items[index];
            final isLast = index == items.length - 1;
            return Column(children: [
              ListTile(
                leading: Icon(item.icon, color: AppColors.primary, size: 22),
                title: Text(item.title, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w500, color: theme.textTheme.bodyLarge?.color)),
                trailing: item.trailing ?? Icon(Icons.chevron_right, color: theme.hintColor),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.vertical(
                    top: index == 0 ? const Radius.circular(AppRadius.lg) : Radius.zero,
                    bottom: isLast ? const Radius.circular(AppRadius.lg) : Radius.zero,
                  ),
                ),
                onTap: item.onTap,
              ),
              if (!isLast) Divider(height: 1, indent: 56, color: theme.dividerColor.withOpacity(0.5)),
            ]);
          }),
        ),
      ),
    );
  }

  // ===========================================================================
  // Admin Section
  // ===========================================================================
  Widget _buildAdminSection(BuildContext context, ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
          child: Row(children: [
            Text('Admin', style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(width: AppSpacing.sm),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: 2),
              decoration: BoxDecoration(color: AppColors.error, borderRadius: BorderRadius.circular(AppRadius.sm)),
              child: const Text('ADMIN', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.white)),
            ),
          ]),
        ),
        _buildMenuCard(context, theme, items: [
          _MenuItem(
            icon: Icons.build_outlined,
            title: 'Admin Paneli',
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const AdminPanelScreen()),
            ),
          ),
        ]),
        const SizedBox(height: AppSpacing.md),
      ],
    );
  }
}

// =============================================================================
// Notification Settings Page
// =============================================================================
class _NotificationSettingsPage extends StatefulWidget {
  @override
  State<_NotificationSettingsPage> createState() => _NotificationSettingsPageState();
}

class _NotificationSettingsPageState extends State<_NotificationSettingsPage> {
  bool _priceDrops = true;
  bool _newPrices = true;
  bool _badges = true;
  bool _system = false;
  bool _comments = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Bildirim Ayarlari')),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.md),
        children: [
          Card(
            child: Column(children: [
              SwitchListTile(
                title: const Text('Fiyat Dususleri'),
                subtitle: const Text('Takip ettiginiz urunler ucuzladiginda bildirim alin'),
                value: _priceDrops,
                onChanged: (v) => setState(() => _priceDrops = v),
                activeColor: AppColors.primary,
                secondary: const Icon(Icons.trending_down, color: AppColors.success),
              ),
              const Divider(height: 1, indent: 56),
              SwitchListTile(
                title: const Text('Yeni Fiyat Girisleri'),
                subtitle: const Text('Takip ettiginiz urunlere fiyat eklendiginde'),
                value: _newPrices,
                onChanged: (v) => setState(() => _newPrices = v),
                activeColor: AppColors.primary,
                secondary: const Icon(Icons.price_change_outlined, color: AppColors.primary),
              ),
              const Divider(height: 1, indent: 56),
              SwitchListTile(
                title: const Text('Rozetler'),
                subtitle: const Text('Yeni rozet kazandiginizda'),
                value: _badges,
                onChanged: (v) => setState(() => _badges = v),
                activeColor: AppColors.primary,
                secondary: const Icon(Icons.emoji_events, color: AppColors.accent),
              ),
              const Divider(height: 1, indent: 56),
              SwitchListTile(
                title: const Text('Yorumlar'),
                subtitle: const Text('Yorumlariniza yanit geldiginde'),
                value: _comments,
                onChanged: (v) => setState(() => _comments = v),
                activeColor: AppColors.primary,
                secondary: const Icon(Icons.comment_outlined, color: AppColors.info),
              ),
              const Divider(height: 1, indent: 56),
              SwitchListTile(
                title: const Text('Sistem Bildirimleri'),
                subtitle: const Text('Uygulama guncelleme ve duyurular'),
                value: _system,
                onChanged: (v) => setState(() => _system = v),
                activeColor: AppColors.primary,
                secondary: const Icon(Icons.campaign_outlined, color: AppColors.textSecondary),
              ),
            ]),
          ),
        ],
      ),
    );
  }
}

// =============================================================================
// Helper classes
// =============================================================================
class _MenuItem {
  final IconData icon;
  final String title;
  final VoidCallback? onTap;
  final Widget? trailing;
  const _MenuItem({required this.icon, required this.title, this.onTap, this.trailing});
}

class _BadgeItem {
  final String emoji;
  final String name;
  final String description;
  final Color color;
  const _BadgeItem({required this.emoji, required this.name, required this.description, required this.color});
}
