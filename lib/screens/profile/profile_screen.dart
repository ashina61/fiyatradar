import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter/services.dart';
import '../../utils/theme.dart';
import '../../providers/theme_provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/product_provider.dart';
import '../../providers/price_provider.dart';
import '../../models/user_model.dart';
import '../../services/auth_service.dart';
import '../../utils/constants.dart';
import '../../widgets/app_card.dart';
import '../../widgets/app_section_header.dart';
import '../admin/admin_panel_screen.dart';
import '../auth/login_screen.dart';
import '../product/product_detail_screen.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userAsync = ref.watch(userModelStreamProvider);
    final themeMode = ref.watch(themeModeProvider);
    final isDark = themeMode == ThemeMode.dark;
    final theme = Theme.of(context);
    final user = userAsync.valueOrNull;
    final bool isAdmin = user?.isAdmin ?? false;

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.only(bottom: AppSpacing.xl),
          child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildProfileHeader(context, ref, user),
            Transform.translate(
              offset: const Offset(0, -20),
              child: _buildStatsRow(context, theme, user),
            ),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: AppSpacing.lg),
              child: AppSectionHeader(
                title: 'Rozetler',
                subtitle: 'Ilerlemeni takip et',
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            _buildBadgesSection(context, user),
            const SizedBox(height: AppSpacing.xl),

            const Padding(
              padding: EdgeInsets.symmetric(horizontal: AppSpacing.lg),
              child: AppSectionHeader(title: 'Kisayollar'),
            ),
            const SizedBox(height: AppSpacing.sm),
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
                onTap: () => _showPointsSystem(context, user),
              ),
              _MenuItem(
                icon: Icons.person_add_alt_1_outlined,
                title: 'Arkadas Davet Et',
                onTap: () => _showInviteFriends(context, user),
              ),
              _MenuItem(
                icon: Icons.settings_outlined,
                title: 'Ayarlar',
                onTap: () => _showSettings(context, ref),
              ),
            ]),
            const SizedBox(height: AppSpacing.lg),

            const Padding(
              padding: EdgeInsets.symmetric(horizontal: AppSpacing.lg),
              child: AppSectionHeader(title: 'Ayarlar'),
            ),
            const SizedBox(height: AppSpacing.sm),
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
            const SizedBox(height: AppSpacing.lg),

            const Padding(
              padding: EdgeInsets.symmetric(horizontal: AppSpacing.lg),
              child: AppSectionHeader(title: 'Destek'),
            ),
            const SizedBox(height: AppSpacing.sm),
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
            const SizedBox(height: AppSpacing.lg),

            if (isAdmin) _buildAdminSection(context, theme),

            // Sign Out
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
              child: AppCard(
                padding: EdgeInsets.zero,
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
                            onPressed: () async {
                              Navigator.pop(ctx);
                              await AuthService().signOut();
                              if (context.mounted) {
                                Navigator.of(context).pushAndRemoveUntil(
                                  MaterialPageRoute(
                                      builder: (_) => const LoginScreen()),
                                  (route) => false,
                                );
                              }
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
            const SizedBox(height: AppSpacing.md),

            Center(
              child: Text(
                'FiyatRadar v1.0.0',
                style: TextStyle(fontSize: 12, color: theme.hintColor),
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
          ],
        ),
      ),
      ),
    );
  }

  // ===========================================================================
  // Active Feature Handlers
  // ===========================================================================

  void _showSavedProducts(BuildContext context) {
    Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => Scaffold(
        appBar: AppBar(title: const Text('Kaydedilen Urunler')),
        body: Consumer(
          builder: (context, ref, _) {
            final productsAsync = ref.watch(allProductsProvider);
            final userAsync = ref.watch(userModelStreamProvider);
            final savedIds = userAsync.valueOrNull?.savedProducts ?? [];

            return productsAsync.when(
              data: (allProducts) {
                final saved = allProducts.where((p) => savedIds.contains(p.id)).toList();
                if (saved.isEmpty) {
                  return const Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.bookmark_outline, size: 64, color: AppColors.textTertiary),
                        SizedBox(height: AppSpacing.md),
                        Text('Kaydedilen urun yok', style: TextStyle(color: AppColors.textSecondary)),
                      ],
                    ),
                  );
                }
                return ListView.builder(
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
                        subtitle: Text('${p.lastStore ?? ''} - ${p.lastPrice?.toStringAsFixed(2) ?? '?'} TL'),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () => Navigator.of(context).push(
                          MaterialPageRoute(builder: (_) => ProductDetailScreen(productId: p.id)),
                        ),
                      ),
                    );
                  },
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (_, __) => const Center(child: Text('Yuklenemedi')),
            );
          },
        ),
      ),
    ));
  }

  void _showPriceHistory(BuildContext context) {
    Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => Scaffold(
        appBar: AppBar(title: const Text('Fiyat Gecmisim')),
        body: Consumer(
          builder: (context, ref, _) {
            final productsAsync = ref.watch(allProductsProvider);
            return productsAsync.when(
              data: (products) {
                if (products.isEmpty) {
                  return const Center(child: Text('Henuz fiyat girisi yok'));
                }
                final recentProducts = products.take(10).toList();
                return ListView.builder(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  itemCount: recentProducts.length,
                  itemBuilder: (context, i) {
                    final p = recentProducts[i];
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
                        subtitle: Text('${p.lastPrice?.toStringAsFixed(2) ?? '?'} TL'),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () => Navigator.of(context).push(
                          MaterialPageRoute(builder: (_) => ProductDetailScreen(productId: p.id)),
                        ),
                      ),
                    );
                  },
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (_, __) => const Center(child: Text('Yuklenemedi')),
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

  void _showPointsSystem(BuildContext context, UserModel? user) {
    final userPoints = user?.points ?? 0;
    String levelName;
    if (userPoints >= 5000) {
      levelName = 'Elmas Uye';
    } else if (userPoints >= 2000) {
      levelName = 'Platin Uye';
    } else if (userPoints >= 500) {
      levelName = 'Altin Uye';
    } else if (userPoints >= 100) {
      levelName = 'Gumus Uye';
    } else {
      levelName = 'Bronz Uye';
    }

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
                Text('$userPoints Puan', style: const TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Text('Seviye: $levelName', style: TextStyle(color: Colors.white.withOpacity(0.9), fontSize: 14)),
              ]),
            ),
            const SizedBox(height: AppSpacing.lg),

            const Text('Puan Kazanma Yollari', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: AppSpacing.md),

            _buildPointRow(
              Icons.add_shopping_cart,
              'Fiyat Ekleme',
              '+${AppConstants.pointsForPriceEntry} Puan',
              'Her yeni fiyat girisi icin',
              AppColors.primary,
            ),
            _buildPointRow(
              Icons.camera_alt,
              'Fotografli Fiyat',
              '+${AppConstants.pointsForPriceEntryWithPhoto} Puan',
              'Fotograf ile fiyat ekleme',
              AppColors.secondary,
            ),
            _buildPointRow(
              Icons.verified,
              'Fiyat Dogrulama',
              '+${AppConstants.pointsForValidation} Puan',
              'Baskalarinin fiyatlarini dogrulama',
              AppColors.success,
            ),
            _buildPointRow(
              Icons.comment,
              'Yorum Yazma',
              '+${AppConstants.pointsForComment} Puan',
              'Urun hakkinda yorum birakma',
              AppColors.info,
            ),
            _buildPointRow(
              Icons.report,
              'Yanlis Fiyat Bildirme',
              '+${AppConstants.pointsForReportPrice} Puan',
              'Yanlis fiyatlari raporlama',
              AppColors.error,
            ),
            _buildPointRow(
              Icons.person_add,
              'Arkadas Davet Etme',
              '+${AppConstants.pointsForInvite} Puan',
              'Davet kodu ile yeni uye',
              AppColors.accent,
            ),
            _buildPointRow(
              Icons.emoji_events,
              'Gunluk Giris',
              '+${AppConstants.pointsForDailyLogin} Puan',
              'Her gun uygulamaya giris yapma',
              const Color(0xFF8B5CF6),
            ),

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
            const Card(child: Column(children: [
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

  void _showInviteFriends(BuildContext context, UserModel? user) {
    final inviteCode = user?.inviteCode;
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.lg)),
      ),
      builder: (ctx) {
        return Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Arkadaslarini Davet Et',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                'Davet kodunu paylas, arkadasin kayit olsun ve puan kazan.',
                style: TextStyle(color: Theme.of(ctx).hintColor),
              ),
              const SizedBox(height: AppSpacing.lg),
              Container(
                padding: const EdgeInsets.all(AppSpacing.md),
                decoration: BoxDecoration(
                  color: Theme.of(ctx).cardColor,
                  borderRadius: BorderRadius.circular(AppRadius.md),
                  border: Border.all(color: AppColors.outline),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Davet Kodun',
                            style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            inviteCode ?? 'Kod olusturulamadi',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.copy),
                      onPressed: inviteCode == null
                          ? null
                          : () async {
                              await Clipboard.setData(ClipboardData(text: inviteCode));
                              if (ctx.mounted) {
                                ScaffoldMessenger.of(ctx).showSnackBar(
                                  const SnackBar(
                                    content: Text('Davet kodu kopyalandi.'),
                                    behavior: SnackBarBehavior.floating,
                                  ),
                                );
                              }
                            },
                    ),
                  ],
                ),
              ),
              if (user != null) ...[
                const SizedBox(height: AppSpacing.md),
                Text(
                  'Toplam davet: ${user.inviteCount}',
                  style: TextStyle(color: Theme.of(ctx).hintColor, fontSize: 12),
                ),
              ],
            ],
          ),
        );
      },
    );
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
              Text('Versiyon 2.0.0', style: TextStyle(color: Theme.of(context).hintColor)),
              const SizedBox(height: AppSpacing.sm),
              const Text(
                'Turkiye\'nin en akilli fiyat takip uygulamasi.\nTopluluk destekli fiyat karsilastirmasi, dogrulama sistemi ve bildirimler.',
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
  // Profile Edit Dialog
  // ===========================================================================
  void _showEditProfileDialog(BuildContext context, UserModel? user) {
    if (user == null) return;
    final emailController = TextEditingController(text: user.email);

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.lg)),
        title: Row(children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: AppColors.primary.withOpacity(0.1), borderRadius: BorderRadius.circular(AppRadius.sm)),
            child: const Icon(Icons.edit, color: AppColors.primary, size: 20),
          ),
          const SizedBox(width: AppSpacing.sm),
          const Text('Profil Duzenle'),
        ]),
        content: SingleChildScrollView(
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            // Name field - disabled
            TextField(
              controller: TextEditingController(text: user.name),
              enabled: false,
              decoration: InputDecoration(
                labelText: 'Ad Soyad',
                prefixIcon: const Icon(Icons.person_outline),
                suffixIcon: const Icon(Icons.lock_outline, size: 18),
                helperText: 'Isim degistirilemez',
                helperStyle: TextStyle(color: Theme.of(ctx).hintColor, fontSize: 11),
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            // Email field - disabled
            TextField(
              controller: emailController,
              enabled: false,
              decoration: InputDecoration(
                labelText: 'E-posta',
                prefixIcon: const Icon(Icons.email_outlined),
                suffixIcon: const Icon(Icons.lock_outline, size: 18),
                helperText: 'E-posta degistirilemez',
                helperStyle: TextStyle(color: Theme.of(ctx).hintColor, fontSize: 11),
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            Container(
              padding: const EdgeInsets.all(AppSpacing.sm),
              decoration: BoxDecoration(
                color: AppColors.info.withOpacity(0.1),
                borderRadius: BorderRadius.circular(AppRadius.sm),
              ),
              child: const Row(children: [
                Icon(Icons.info_outline, color: AppColors.info, size: 18),
                SizedBox(width: 8),
                Expanded(child: Text(
                  'Guvenlik nedeniyle ad soyad ve e-posta degistirilemez.',
                  style: TextStyle(fontSize: 12, color: AppColors.info),
                )),
              ]),
            ),
          ]),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Kapat'),
          ),
        ],
      ),
    );
  }

  // ===========================================================================
  // Profile Header
  // ===========================================================================
  Future<ImageSource?> _pickPhotoSource(BuildContext context) async {
    return showModalBottomSheet<ImageSource>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.lg)),
      ),
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.photo_library_outlined),
                title: const Text('Galeriden Sec'),
                onTap: () => Navigator.pop(context, ImageSource.gallery),
              ),
              ListTile(
                leading: const Icon(Icons.photo_camera_outlined),
                title: const Text('Kamerayi Ac'),
                onTap: () => Navigator.pop(context, ImageSource.camera),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _changeProfilePhoto(
    BuildContext context,
    WidgetRef ref,
    UserModel? user,
  ) async {
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Profil resmini guncellemek icin giris yapin.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    final source = await _pickPhotoSource(context);
    if (source == null) return;

    final picker = ImagePicker();
    final picked = await picker.pickImage(
      source: source,
      imageQuality: 85,
      maxWidth: 512,
    );

    if (picked == null) return;

    if (!context.mounted) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );

    try {
      final storageService = ref.read(storageServiceProvider);
      final authService = ref.read(authServiceProvider);
      final file = File(picked.path);
      final url = await storageService.uploadUserAvatar(
        file: file,
        userId: user.uid,
      );
      await authService.updateUserProfile(uid: user.uid, photoUrl: url);

      if (!context.mounted) return;
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Profil resmi guncellendi.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      if (!context.mounted) return;
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Profil resmi guncellenemedi: $e'),
          behavior: SnackBarBehavior.floating,
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  Widget _buildProfileHeader(BuildContext context, WidgetRef ref, UserModel? user) {
    final displayName = user?.name ?? 'Kullanici';
    final email = user?.email ?? '';
    final initial = displayName.isNotEmpty ? displayName[0].toUpperCase() : '?';
    final photoUrl = user?.photoUrl;
    final isAdmin = user?.isAdmin ?? false;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + AppSpacing.md,
        bottom: AppSpacing.xxl,
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
              onPressed: () => _showEditProfileDialog(context, user),
            ),
          ),
          Center(
            child: Column(children: [
              GestureDetector(
                onTap: () => _changeProfilePhoto(context, ref, user),
                child: Stack(
                  alignment: Alignment.bottomRight,
                  children: [
                    Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: photoUrl == null
                            ? LinearGradient(
                                colors: [
                                  AppColors.primaryLight.withOpacity(0.8),
                                  AppColors.secondaryLight.withOpacity(0.8),
                                ],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              )
                            : null,
                        image: photoUrl != null
                            ? DecorationImage(
                                image: NetworkImage(photoUrl),
                                fit: BoxFit.cover,
                                onError: (_, __) {},
                              )
                            : null,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.2),
                            blurRadius: 16,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      child: photoUrl == null
                          ? Center(
                              child: Text(
                                initial,
                                style: const TextStyle(
                                  fontSize: 30,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                            )
                          : null,
                    ),
                    Container(
                      width: 26,
                      height: 26,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.15),
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.photo_camera_outlined,
                        size: 14,
                        color: AppColors.primary,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(displayName, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: Colors.white)),
                  if (isAdmin) ...[
                    const SizedBox(width: 6),
                    const Icon(Icons.verified, color: Colors.lightBlueAccent, size: 22),
                  ],
                ],
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(email, style: const TextStyle(fontSize: 13, color: Colors.white70)),
            ]),
          ),
        ],
      ),
    );
  }

  // ===========================================================================
  // Stats Row
  // ===========================================================================
  Widget _buildStatsRow(BuildContext context, ThemeData theme, UserModel? user) {
    final cardColor = theme.cardColor;
    final priceEntries = user?.priceEntries ?? 0;
    final points = user?.points ?? 0;
    final validations = user?.validations ?? 0;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      child: Row(children: [
        Expanded(child: _buildStatCard(context, cardColor, value: '$priceEntries', label: 'Fiyat Girisi', icon: Icons.price_change, color: AppColors.primary)),
        const SizedBox(width: AppSpacing.sm),
        Expanded(child: _buildStatCard(context, cardColor, value: '$points', label: 'Puan', icon: Icons.stars, color: AppColors.accent)),
        const SizedBox(width: AppSpacing.sm),
        Expanded(child: _buildStatCard(context, cardColor, value: '$validations', label: 'Dogrulama', icon: Icons.verified, color: AppColors.secondary)),
      ]),
    );
  }

  Widget _buildStatCard(BuildContext context, Color cardColor, {
    required String value, required String label, required IconData icon, required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm + 2, horizontal: AppSpacing.sm),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 16, offset: const Offset(0, 4))],
      ),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(height: AppSpacing.xs),
        Text(value, style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: color)),
        const SizedBox(height: 2),
        Text(label, style: TextStyle(fontSize: 11, color: Theme.of(context).hintColor), textAlign: TextAlign.center),
      ]),
    );
  }

  // ===========================================================================
  // Badges
  // ===========================================================================
  Widget _buildBadgesSection(BuildContext context, UserModel? user) {
    final priceEntries = user?.priceEntries ?? 0;
    final validations = user?.validations ?? 0;

    // Define badges with unlock conditions
    final badges = [
      _BadgeItem(
        emoji: '\u{1F3C6}', name: 'Fiyat Avcisi',
        description: '50+ fiyat girisi',
        color: AppColors.accent,
        isEarned: priceEntries >= 50,
        progress: priceEntries < 50 ? '$priceEntries/50 fiyat ekle' : null,
      ),
      _BadgeItem(
        emoji: '\u{2B50}', name: 'Guvenilir Uye',
        description: '100+ dogrulama',
        color: AppColors.primary,
        isEarned: validations >= 100,
        progress: validations < 100 ? '$validations/100 dogrulama yap' : null,
      ),
      _BadgeItem(
        emoji: '\u{1F525}', name: 'Trend Belirleyici',
        description: '10+ fiyat girisi',
        color: AppColors.error,
        isEarned: priceEntries >= 10,
        progress: priceEntries < 10 ? '$priceEntries/10 fiyat ekle' : null,
      ),
      _BadgeItem(
        emoji: '\u{1F6E1}', name: 'Dogrulayici',
        description: '50+ dogrulama',
        color: AppColors.secondary,
        isEarned: validations >= 50,
        progress: validations < 50 ? '$validations/50 dogrulama yap' : null,
      ),
    ];

    final previewBadges = badges.take(4).toList();

    return Column(
      children: [
        SizedBox(
          height: 124,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
            itemCount: previewBadges.length,
        separatorBuilder: (_, __) => const SizedBox(width: AppSpacing.md),
        itemBuilder: (context, index) {
              final badge = previewBadges[index];
          final earned = badge.isEarned;
          return GestureDetector(
            onTap: !earned ? () {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(badge.progress ?? '${badge.description} gerekli'),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            } : null,
            child: SizedBox(
              width: 90,
              child: Column(children: [
                Container(
                  width: 64, height: 64,
                  decoration: BoxDecoration(
                    color: earned ? badge.color.withOpacity(0.12) : Colors.grey.withOpacity(0.08),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: earned ? badge.color.withOpacity(0.3) : Colors.grey.withOpacity(0.2),
                      width: 2,
                    ),
                  ),
                  child: Center(
                    child: Opacity(
                      opacity: earned ? 1.0 : 0.3,
                      child: Text(badge.emoji, style: const TextStyle(fontSize: 28)),
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  badge.name,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: earned
                        ? Theme.of(context).textTheme.bodyMedium?.color
                        : AppColors.textTertiary,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (!earned && badge.progress != null)
                  Text(
                    badge.progress!,
                    style: const TextStyle(fontSize: 9, color: AppColors.textTertiary),
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
              ]),
            ),
          );
        },
      ),
        ),
        TextButton(
          onPressed: () => _showAllBadges(context, badges),
          child: const Text('Tum rozetleri gor'),
        ),
      ],
    );
  }

  void _showAllBadges(BuildContext context, List<_BadgeItem> badges) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Rozetler', style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: AppSpacing.md),
              ...badges.map(
                (badge) => Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                  child: Row(
                    children: [
                      Text(badge.emoji, style: const TextStyle(fontSize: 20)),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: Text(
                          '${badge.name} • ${badge.description}',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ===========================================================================
  // Menu Card
  // ===========================================================================
  Widget _buildMenuCard(BuildContext context, ThemeData theme, {required List<_MenuItem> items}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
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
  final bool isEarned;
  final String? progress;
  const _BadgeItem({
    required this.emoji,
    required this.name,
    required this.description,
    required this.color,
    this.isEarned = false,
    this.progress,
  });
}
