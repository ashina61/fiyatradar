import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../state/app_state.dart';
import '../theme.dart';
import '../widgets/design.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  static final Uri _termsUri =
      Uri.parse('https://fiyatradar.app/terms');
  static final Uri _privacyUri =
      Uri.parse('https://fiyatradar.app/privacy');
  static final Uri _faqUri =
      Uri.parse('https://fiyatradar.app/faq');
  static final Uri _changelogUri =
      Uri.parse('https://fiyatradar.app/changelog');
  static final Uri _storeUri = Uri.parse(
    'https://play.google.com/store/apps/details?id=app.fiyatradar',
  );

  @override
  Widget build(BuildContext context) {
    final state = AppStateScope.of(context);
    final user = state.user;

    return Scaffold(
      backgroundColor: CoffeeColors.cream,
      appBar: AppBar(
        title: const Text('Ayarlar'),
        leading: const BackButton(),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: CoffeeColors.crema),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 48),
        children: [
          _AccountBlock(
            displayName: state.displayName,
            email: user?.email,
            onEdit: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const _PersonalInfoPage()),
            ),
          ),
          const SizedBox(height: 24),
          _SettingsGroup(
            title: 'Hesap',
            icon: Icons.person_outline,
            items: [
              _SettingsItem(
                icon: Icons.person_outline,
                title: 'Kişisel Bilgiler',
                subtitle: 'Ad, kullanıcı adı, telefon',
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const _PersonalInfoPage()),
                ),
              ),
              _SettingsItem(
                icon: Icons.lock_outline,
                title: 'Güvenlik ve Giriş',
                subtitle: '2FA, biyometrik, oturum bilgisi',
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const _SecurityPage()),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _SettingsGroup(
            title: 'Tercihler',
            icon: Icons.tune_outlined,
            items: [
              _SettingsItem(
                icon: Icons.notifications_none,
                title: 'Bildirim Tercihleri',
                subtitle: 'Push, fiyat alarmı, haftalık özet',
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const _NotificationPreferencesPage(),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _SettingsGroup(
            title: 'Destek',
            icon: Icons.support_outlined,
            items: [
              _SettingsItem(
                icon: Icons.help_outline,
                title: 'Sıkça Sorulan Sorular',
                subtitle: 'Yardım merkezi',
                onTap: () => _launchExternal(context, _faqUri),
              ),
              _SettingsItem(
                icon: Icons.mail_outline,
                title: 'Bize Ulaşın',
                subtitle: 'destek@fiyatradar.app',
                onTap: () => _launchExternal(
                  context,
                  Uri(
                    scheme: 'mailto',
                    path: 'destek@fiyatradar.app',
                    query: 'subject=FiyatRadar%20Destek',
                  ),
                ),
              ),
              _SettingsItem(
                icon: Icons.star_outline,
                title: 'Uygulamayı Puanla',
                subtitle: 'Play Store',
                onTap: () => _launchExternal(context, _storeUri),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _SettingsGroup(
            title: 'Uygulama',
            icon: Icons.info_outline,
            items: [
              _SettingsItem(
                icon: Icons.history,
                title: 'Güncelleme Geçmişi',
                subtitle: 'Sürüm notları',
                onTap: () => _launchExternal(context, _changelogUri),
              ),
              _SettingsItem(
                icon: Icons.description_outlined,
                title: 'Kullanım Koşulları',
                onTap: () => _launchExternal(context, _termsUri),
              ),
              _SettingsItem(
                icon: Icons.privacy_tip_outlined,
                title: 'Gizlilik Politikası',
                onTap: () => _launchExternal(context, _privacyUri),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _SettingsGroup(
            title: 'Oturum',
            icon: Icons.logout,
            items: [
              _SettingsItem(
                icon: Icons.logout,
                title: 'Çıkış Yap',
                subtitle: 'Geçerli oturumu sonlandır',
                isDestructive: true,
                onTap: () => _confirmLogout(context),
              ),
            ],
          ),
          const SizedBox(height: 32),
          Center(
            child: Column(
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                  decoration: BoxDecoration(
                    color: CoffeeColors.foam,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: CoffeeColors.crema),
                  ),
                  child: const Text(
                    'FiyatRadar v1.0.0',
                    style: TextStyle(
                      color: CoffeeColors.cocoa,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Topluluk gücüyle fiyat avantajı',
                  style: TextStyle(color: CoffeeColors.cocoa, fontSize: 11),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  static Future<void> _launchExternal(BuildContext context, Uri uri) async {
    final launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!context.mounted || launched) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Bağlantı açılamadı: $uri'),
        backgroundColor: CoffeeColors.darkRoast,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  static Future<void> _confirmLogout(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Çıkış Yap'),
        content: const Text('Hesabından çıkmak istediğine emin misin?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('İptal'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: CoffeeColors.danger,
              foregroundColor: Colors.white,
            ),
            child: const Text('Çıkış Yap'),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;
    final state = AppStateScope.of(context);
    await state.logout();
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Oturum kapatıldı.'),
        backgroundColor: CoffeeColors.darkRoast,
      ),
    );
    Navigator.of(context).popUntil((route) => route.isFirst);
  }
}

class _AccountBlock extends StatelessWidget {
  const _AccountBlock({
    required this.displayName,
    required this.email,
    required this.onEdit,
  });

  final String displayName;
  final String? email;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [CoffeeColors.espresso, CoffeeColors.darkRoast],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: CoffeeColors.espresso.withOpacity(0.22),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: CoffeeColors.caramel.withOpacity(0.22),
              shape: BoxShape.circle,
              border: Border.all(
                color: CoffeeColors.caramel.withOpacity(0.45),
                width: 2,
              ),
            ),
            alignment: Alignment.center,
            child: const Text('☕', style: TextStyle(fontSize: 22)),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  displayName,
                  style: const TextStyle(
                    color: CoffeeColors.cream,
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.3,
                  ),
                ),
                Text(
                  email ?? 'Anonim hesap',
                  style: const TextStyle(color: CoffeeColors.latte, fontSize: 13),
                ),
              ],
            ),
          ),
          GestureDetector(
            onTap: onEdit,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.10),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.white.withOpacity(0.15)),
              ),
              child: const Text(
                'Düzenle',
                style: TextStyle(
                  color: CoffeeColors.latte,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SettingsGroup extends StatelessWidget {
  const _SettingsGroup({
    required this.title,
    required this.items,
    this.icon,
  });

  final String title;
  final List<_SettingsItem> items;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 9),
          child: Row(
            children: [
              if (icon != null) ...[
                Icon(icon!, size: 13, color: CoffeeColors.caramel),
                const SizedBox(width: 6),
              ],
              Text(
                title.toUpperCase(),
                style: const TextStyle(
                  color: CoffeeColors.cocoa,
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.2,
                ),
              ),
            ],
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: CoffeeColors.crema),
            boxShadow: FR.softShadow,
          ),
          child: Column(
            children: items.asMap().entries.map((entry) {
              final index = entry.key;
              final item = entry.value;
              return Column(
                children: [
                  item,
                  if (index < items.length - 1)
                    const Divider(
                      height: 1,
                      indent: 54,
                      color: CoffeeColors.crema,
                    ),
                ],
              );
            }).toList(),
          ),
        ),
      ],
    );
  }
}

class _SettingsItem extends StatelessWidget {
  const _SettingsItem({
    required this.icon,
    required this.title,
    this.subtitle,
    required this.onTap,
    this.isDestructive = false,
  });

  final IconData icon;
  final String title;
  final String? subtitle;
  final VoidCallback onTap;
  final bool isDestructive;

  @override
  Widget build(BuildContext context) {
    final titleColor = isDestructive ? CoffeeColors.danger : CoffeeColors.espresso;
    final iconColor = isDestructive ? CoffeeColors.danger : CoffeeColors.darkRoast;

    return ListTile(
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      leading: Container(
        width: 38,
        height: 38,
        decoration: BoxDecoration(
          color: CoffeeColors.foam,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: CoffeeColors.crema),
        ),
        child: Icon(icon, color: iconColor, size: 19),
      ),
      title: Text(
        title,
        style: TextStyle(fontWeight: FontWeight.w700, color: titleColor, fontSize: 14),
      ),
      subtitle: subtitle != null
          ? Text(
              subtitle!,
              style: const TextStyle(color: CoffeeColors.cocoa, fontSize: 12),
            )
          : null,
      trailing: const Icon(Icons.chevron_right, color: CoffeeColors.cocoa, size: 20),
    );
  }
}

class _PersonalInfoPage extends StatefulWidget {
  const _PersonalInfoPage();

  @override
  State<_PersonalInfoPage> createState() => _PersonalInfoPageState();
}

class _PersonalInfoPageState extends State<_PersonalInfoPage> {
  late final TextEditingController _displayNameController =
      TextEditingController();
  late final TextEditingController _usernameController = TextEditingController();
  late final TextEditingController _phoneController = TextEditingController();
  bool _initializedControllers = false;
  bool _saving = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_initializedControllers) return;
    final state = AppStateScope.of(context);
    _displayNameController.text = state.displayName;
    _usernameController.text = state.username;
    _phoneController.text = state.phoneNumber ?? '';
    _initializedControllers = true;
  }

  @override
  void dispose() {
    _displayNameController.dispose();
    _usernameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: CoffeeColors.cream,
      appBar: AppBar(title: const Text('Kişisel Bilgiler')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 40),
        children: [
          _EditableField(label: 'Ad Soyad', controller: _displayNameController),
          const SizedBox(height: 12),
          _EditableField(label: 'Kullanıcı Adı', controller: _usernameController),
          const SizedBox(height: 12),
          _EditableField(
            label: 'Telefon',
            controller: _phoneController,
            keyboardType: TextInputType.phone,
          ),
          const SizedBox(height: 28),
          ElevatedButton(
            onPressed: _saving ? null : _save,
            style: ElevatedButton.styleFrom(minimumSize: const Size.fromHeight(52)),
            child: _saving
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                  )
                : const Text('Kaydet'),
          ),
        ],
      ),
    );
  }

  Future<void> _save() async {
    final state = AppStateScope.of(context);
    final displayName = _displayNameController.text.trim();
    final username = _usernameController.text.trim();
    if (displayName.isEmpty || username.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ad ve kullanıcı adı zorunludur.')),
      );
      return;
    }
    setState(() => _saving = true);
    await state.updateProfileSettings(
      displayName: displayName,
      username: username,
      phoneNumber: _phoneController.text,
    );
    if (!mounted) return;
    setState(() => _saving = false);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Bilgiler güncellendi.'),
        backgroundColor: CoffeeColors.darkRoast,
      ),
    );
    Navigator.pop(context);
  }
}

class _EditableField extends StatelessWidget {
  const _EditableField({
    required this.label,
    required this.controller,
    this.keyboardType,
  });

  final String label;
  final TextEditingController controller;
  final TextInputType? keyboardType;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: CoffeeColors.cocoa,
            fontSize: 12,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          keyboardType: keyboardType,
          decoration: InputDecoration(
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: CoffeeColors.crema),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: CoffeeColors.crema),
            ),
          ),
        ),
      ],
    );
  }
}

class _NotificationPreferencesPage extends StatelessWidget {
  const _NotificationPreferencesPage();

  @override
  Widget build(BuildContext context) {
    final state = AppStateScope.of(context);

    return Scaffold(
      backgroundColor: CoffeeColors.cream,
      appBar: AppBar(title: const Text('Bildirim Tercihleri')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 40),
        children: [
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: CoffeeColors.crema),
              boxShadow: FR.softShadow,
            ),
            child: Column(
              children: [
                _ToggleTileCompact(
                  title: 'Push Bildirimleri',
                  subtitle: 'Uygulama bildirim izni',
                  icon: Icons.notifications_active_outlined,
                  value: state.pushNotificationsEnabled,
                  onChanged: (value) => state.updateNotificationSettings(pushEnabled: value),
                ),
                const Divider(height: 1, indent: 16, color: CoffeeColors.crema),
                _ToggleTileCompact(
                  title: 'Fiyat Alarmı Bildirimleri',
                  subtitle: 'Alarm ürünlerinde düşüş olduğunda bildir',
                  icon: Icons.price_change_outlined,
                  value: state.priceAlertsEnabled,
                  onChanged: state.pushNotificationsEnabled
                      ? (value) => state.updateNotificationSettings(priceAlertsEnabled: value)
                      : null,
                ),
                const Divider(height: 1, indent: 16, color: CoffeeColors.crema),
                _ToggleTileCompact(
                  title: 'Haftalık Özet',
                  subtitle: 'Haftalık fiyat özeti ve trendler',
                  icon: Icons.summarize_outlined,
                  value: state.weeklySummaryEnabled,
                  onChanged: state.pushNotificationsEnabled
                      ? (value) => state.updateNotificationSettings(weeklySummaryEnabled: value)
                      : null,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SecurityPage extends StatelessWidget {
  const _SecurityPage();

  @override
  Widget build(BuildContext context) {
    final state = AppStateScope.of(context);
    final user = state.user;

    return Scaffold(
      backgroundColor: CoffeeColors.cream,
      appBar: AppBar(title: const Text('Güvenlik ve Giriş')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 40),
        children: [
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: CoffeeColors.crema),
              boxShadow: FR.softShadow,
            ),
            child: Column(
              children: [
                _ToggleTileCompact(
                  title: 'Biyometrik Giriş',
                  subtitle: 'Parmak izi veya yüz tanıma',
                  icon: Icons.fingerprint,
                  value: state.biometricEnabled,
                  onChanged: (value) => state.updateSecuritySettings(biometricEnabled: value),
                ),
                const Divider(height: 1, indent: 16, color: CoffeeColors.crema),
                _ToggleTileCompact(
                  title: 'İki Faktörlü Doğrulama',
                  subtitle: 'Giriş yaparken ek doğrulama iste',
                  icon: Icons.security,
                  value: state.twoFactorEnabled,
                  onChanged: (value) => state.updateSecuritySettings(twoFactorEnabled: value),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: CoffeeColors.crema),
              boxShadow: FR.softShadow,
            ),
            child: Column(
              children: [
                _ActionTile(
                  icon: Icons.lock_outline,
                  title: 'Şifre Değiştir',
                  subtitle: 'Giriş sağlayıcına göre güncelle',
                  onTap: () => ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Anonim oturumda şifre güncelleme desteklenmiyor.'),
                    ),
                  ),
                ),
                const Divider(height: 1, indent: 54, color: CoffeeColors.crema),
                _ActionTile(
                  icon: Icons.devices_outlined,
                  title: 'Aktif Oturum',
                  subtitle: user == null
                      ? 'Oturum bilgisi bulunamadı'
                      : 'UID: ${user.uid.substring(0, 8)}…',
                  onTap: () => showDialog<void>(
                    context: context,
                    builder: (ctx) => AlertDialog(
                      title: const Text('Aktif Oturum'),
                      content: Text(
                        user == null
                            ? 'Aktif kullanıcı bulunamadı.'
                            : 'UID: ${user.uid}\nSon giriş: ${user.metadata.lastSignInTime ?? '-'}',
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(ctx),
                          child: const Text('Tamam'),
                        ),
                      ],
                    ),
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

class _ToggleTileCompact extends StatelessWidget {
  const _ToggleTileCompact({
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
    this.icon,
  });

  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool>? onChanged;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: const EdgeInsets.fromLTRB(16, 4, 12, 4),
      leading: icon != null
          ? Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: CoffeeColors.foam,
                borderRadius: BorderRadius.circular(9),
              ),
              child: Icon(icon!, color: CoffeeColors.darkRoast, size: 18),
            )
          : null,
      title: Text(
        title,
        style: const TextStyle(
          fontWeight: FontWeight.w700,
          color: CoffeeColors.espresso,
          fontSize: 14,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: const TextStyle(color: CoffeeColors.cocoa, fontSize: 12),
      ),
      trailing: Switch(
        value: value,
        onChanged: onChanged,
        activeColor: CoffeeColors.espresso,
        activeTrackColor: CoffeeColors.caramel,
      ),
    );
  }
}

class _ActionTile extends StatelessWidget {
  const _ActionTile({
    required this.icon,
    required this.title,
    required this.onTap,
    this.subtitle,
  });

  final IconData icon;
  final String title;
  final String? subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      leading: Container(
        width: 38,
        height: 38,
        decoration: BoxDecoration(
          color: CoffeeColors.foam,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: CoffeeColors.darkRoast, size: 19),
      ),
      title: Text(
        title,
        style: const TextStyle(
          fontWeight: FontWeight.w700,
          color: CoffeeColors.espresso,
          fontSize: 14,
        ),
      ),
      subtitle: subtitle != null
          ? Text(
              subtitle!,
              style: const TextStyle(color: CoffeeColors.cocoa, fontSize: 12),
            )
          : null,
      trailing: const Icon(Icons.chevron_right, color: CoffeeColors.cocoa, size: 20),
    );
  }
}
