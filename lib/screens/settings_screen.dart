import 'package:flutter/material.dart';
import '../theme.dart';
import '../widgets/design.dart';

// ─── Entry point ──────────────────────────────────────────────────────────────

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: CoffeeColors.cream,
      appBar: AppBar(
        title: const Text('Ayarlar'),
        leading: const BackButton(),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 40),
        children: [
          _SettingsGroup(
            title: 'Hesap',
            items: [
              _SettingsItem(
                icon: Icons.person_outline,
                title: 'Kişisel Bilgiler',
                subtitle: 'Ad, e-posta, profil',
                onTap: () => Navigator.push(context,
                    MaterialPageRoute(
                        builder: (_) => const _PersonalInfoPage())),
              ),
              _SettingsItem(
                icon: Icons.lock_outline,
                title: 'Güvenlik ve Giriş',
                subtitle: 'Şifre, oturum yönetimi',
                onTap: () => Navigator.push(context,
                    MaterialPageRoute(
                        builder: (_) => const _SecurityPage())),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _SettingsGroup(
            title: 'Tercihler',
            items: [
              _SettingsItem(
                icon: Icons.notifications_none,
                title: 'Bildirim Tercihleri',
                subtitle: 'Fiyat alarmları, haberler',
                onTap: () => Navigator.push(context,
                    MaterialPageRoute(
                        builder: (_) => const _NotificationsPage())),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _SettingsGroup(
            title: 'Destek',
            items: [
              _SettingsItem(
                icon: Icons.help_outline,
                title: 'Sıkça Sorulan Sorular',
                subtitle: 'Nasıl çalışır, nasıl kullanılır',
                onTap: () => Navigator.push(context,
                    MaterialPageRoute(builder: (_) => const _FAQPage())),
              ),
              _SettingsItem(
                icon: Icons.mail_outline,
                title: 'Bize Ulaşın',
                subtitle: 'Öneri, şikayet, geri bildirim',
                onTap: () => Navigator.push(context,
                    MaterialPageRoute(
                        builder: (_) => const _ContactPage())),
              ),
              _SettingsItem(
                icon: Icons.star_outline,
                title: 'Uygulamayı Puanla',
                subtitle: 'App Store / Play Store değerlendirmesi',
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content:
                          Text('Mağazaya yönlendiriliyorsunuz…'),
                      backgroundColor: CoffeeColors.darkRoast,
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                },
              ),
            ],
          ),
          const SizedBox(height: 16),
          _SettingsGroup(
            title: 'Uygulama',
            items: [
              _SettingsItem(
                icon: Icons.history,
                title: 'Güncelleme Geçmişi',
                subtitle: 'Versiyon notları',
                onTap: () => Navigator.push(context,
                    MaterialPageRoute(
                        builder: (_) => const _ChangelogPage())),
              ),
              _SettingsItem(
                icon: Icons.description_outlined,
                title: 'Kullanım Koşulları',
                onTap: () => Navigator.push(context,
                    MaterialPageRoute(
                        builder: (_) => const _TermsPage())),
              ),
              _SettingsItem(
                icon: Icons.privacy_tip_outlined,
                title: 'Gizlilik Politikası',
                onTap: () => Navigator.push(context,
                    MaterialPageRoute(
                        builder: (_) => const _PrivacyPage())),
              ),
            ],
          ),
          const SizedBox(height: 32),
          const Center(
            child: Text(
              'FiyatRadar v1.0.0',
              style: TextStyle(color: CoffeeColors.cocoa, fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Reusable group + item ────────────────────────────────────────────────────

class _SettingsGroup extends StatelessWidget {
  const _SettingsGroup({required this.title, required this.items});
  final String title;
  final List<_SettingsItem> items;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 8),
          child: Text(
            title.toUpperCase(),
            style: const TextStyle(
              color: CoffeeColors.cocoa,
              fontSize: 11,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.2,
            ),
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
              final i = entry.key;
              final item = entry.value;
              return Column(
                children: [
                  item,
                  if (i < items.length - 1)
                    const Divider(
                        height: 1,
                        indent: 54,
                        color: CoffeeColors.crema),
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
  });
  final IconData icon;
  final String title;
  final String? subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: onTap,
      contentPadding:
          const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
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
              style:
                  const TextStyle(color: CoffeeColors.cocoa, fontSize: 12),
            )
          : null,
      trailing: const Icon(Icons.chevron_right,
          color: CoffeeColors.cocoa, size: 20),
    );
  }
}

// ─── Sub-screens ──────────────────────────────────────────────────────────────

class _PersonalInfoPage extends StatelessWidget {
  const _PersonalInfoPage();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: CoffeeColors.cream,
      appBar: AppBar(title: const Text('Kişisel Bilgiler')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 40),
        children: [
          // Avatar area
          Center(
            child: Column(
              children: [
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: CoffeeColors.espresso,
                    shape: BoxShape.circle,
                    border: Border.all(
                        color: CoffeeColors.caramel, width: 2.5),
                  ),
                  alignment: Alignment.center,
                  child: const Text('☕',
                      style: TextStyle(fontSize: 36)),
                ),
                const SizedBox(height: 12),
                TextButton(
                  onPressed: () {},
                  child: const Text('Fotoğraf Değiştir',
                      style: TextStyle(color: CoffeeColors.caramel)),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          _InfoField(label: 'Ad Soyad', value: 'Kahve Avcısı'),
          const SizedBox(height: 12),
          _InfoField(label: 'Kullanıcı Adı', value: '@fiyatradar_user'),
          const SizedBox(height: 12),
          _InfoField(label: 'E-posta', value: 'kullanici@ornek.com'),
          const SizedBox(height: 12),
          _InfoField(label: 'Telefon', value: '+90 5xx xxx xx xx'),
          const SizedBox(height: 28),
          ElevatedButton(
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Bilgiler kaydedildi'),
                  backgroundColor: CoffeeColors.darkRoast,
                  behavior: SnackBarBehavior.floating,
                ),
              );
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(
                minimumSize: const Size.fromHeight(52)),
            child: const Text('Kaydet'),
          ),
        ],
      ),
    );
  }
}

class _InfoField extends StatelessWidget {
  const _InfoField({required this.label, required this.value});
  final String label;
  final String value;

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
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: CoffeeColors.crema),
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  value,
                  style: const TextStyle(
                    color: CoffeeColors.espresso,
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
              ),
              const Icon(Icons.edit_outlined,
                  color: CoffeeColors.cocoa, size: 16),
            ],
          ),
        ),
      ],
    );
  }
}

class _SecurityPage extends StatefulWidget {
  const _SecurityPage();
  @override
  State<_SecurityPage> createState() => _SecurityPageState();
}

class _SecurityPageState extends State<_SecurityPage> {
  bool _twoFA = false;
  bool _biometric = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: CoffeeColors.cream,
      appBar: AppBar(title: const Text('Güvenlik ve Giriş')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 40),
        children: [
          _ToggleTile(
            icon: Icons.fingerprint,
            title: 'Biyometrik Giriş',
            subtitle: 'Parmak izi veya yüz tanıma ile giriş',
            value: _biometric,
            onChanged: (v) => setState(() => _biometric = v),
          ),
          const SizedBox(height: 12),
          _ToggleTile(
            icon: Icons.security,
            title: 'İki Faktörlü Doğrulama',
            subtitle: 'Giriş yaparken SMS kodu iste',
            value: _twoFA,
            onChanged: (v) => setState(() => _twoFA = v),
          ),
          const SizedBox(height: 20),
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: CoffeeColors.crema),
            ),
            child: Column(
              children: [
                _ActionTile(
                  icon: Icons.lock_outline,
                  title: 'Şifre Değiştir',
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Şifre sıfırlama maili gönderildi'),
                        backgroundColor: CoffeeColors.darkRoast,
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  },
                ),
                const Divider(height: 1, indent: 54, color: CoffeeColors.crema),
                _ActionTile(
                  icon: Icons.devices_outlined,
                  title: 'Aktif Oturumlar',
                  onTap: () {},
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _NotificationsPage extends StatefulWidget {
  const _NotificationsPage();
  @override
  State<_NotificationsPage> createState() => _NotificationsPageState();
}

class _NotificationsPageState extends State<_NotificationsPage> {
  bool _priceAlerts = true;
  bool _weeklyReport = true;
  bool _newContributions = false;
  bool _communityNews = false;

  @override
  Widget build(BuildContext context) {
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
            ),
            child: Column(
              children: [
                _ToggleTileCompact(
                  title: 'Fiyat Alarmları',
                  subtitle: 'Takip ettiğin ürünlerde fiyat düşünce',
                  value: _priceAlerts,
                  onChanged: (v) => setState(() => _priceAlerts = v),
                ),
                const Divider(height: 1, indent: 16, color: CoffeeColors.crema),
                _ToggleTileCompact(
                  title: 'Haftalık Özet',
                  subtitle: 'Haftanın en hareketli ürünleri',
                  value: _weeklyReport,
                  onChanged: (v) => setState(() => _weeklyReport = v),
                ),
                const Divider(height: 1, indent: 16, color: CoffeeColors.crema),
                _ToggleTileCompact(
                  title: 'Yeni Katkılar',
                  subtitle: 'Takip ettiğin ürünlere fiyat eklenince',
                  value: _newContributions,
                  onChanged: (v) =>
                      setState(() => _newContributions = v),
                ),
                const Divider(height: 1, indent: 16, color: CoffeeColors.crema),
                _ToggleTileCompact(
                  title: 'Topluluk Haberleri',
                  subtitle: 'Kampanya ve duyurular',
                  value: _communityNews,
                  onChanged: (v) => setState(() => _communityNews = v),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _FAQPage extends StatelessWidget {
  const _FAQPage();

  static const _faqs = [
    _FAQ(
      q: 'FiyatRadar nasıl çalışır?',
      a: 'Kullanıcılar markette gördükleri fiyatları uygulama üzerinden paylaşır. Bu veriler anlık olarak işlenerek diğer kullanıcılara sunulur. Piyasa fiyatı topluluk katkısıyla oluşur.',
    ),
    _FAQ(
      q: 'Fiyat verileri güvenilir mi?',
      a: 'Her fiyat girişi zaman damgası ve katkıcı bilgisiyle saklanır. Birden fazla kullanıcı aynı fiyatı doğruladığında güven skoru artar.',
    ),
    _FAQ(
      q: 'Nasıl puan kazanırım?',
      a: 'Fiyat ekleme (+10 puan), yeni ürün ekleme (+25 puan), favorilere ekleme (+2 puan), günlük giriş (+5 puan) ile puan kazanırsın. 100 puan = ₺5 değerindedir.',
    ),
    _FAQ(
      q: 'Fiyat alarmı nasıl kurulur?',
      a: 'Ürün detay ekranında zil simgesine dokunarak fiyat alarmı kurabilirsin. Fiyat belirlediğin seviyenin altına düşünce bildirim alırsın.',
    ),
    _FAQ(
      q: 'Hangi marketler destekleniyor?',
      a: 'Şu an A101, BİM, ŞOK, Migros, CarrefourSA ve Tarım Kredi destekleniyor. Yeni marketler yakında eklenecek.',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: CoffeeColors.cream,
      appBar: AppBar(title: const Text('Sıkça Sorulan Sorular')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 40),
        children: _faqs
            .map((f) => _FAQTile(faq: f))
            .toList(),
      ),
    );
  }
}

class _FAQ {
  final String q;
  final String a;
  const _FAQ({required this.q, required this.a});
}

class _FAQTile extends StatefulWidget {
  const _FAQTile({required this.faq});
  final _FAQ faq;
  @override
  State<_FAQTile> createState() => _FAQTileState();
}

class _FAQTileState extends State<_FAQTile> {
  bool _open = false;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: _open
              ? CoffeeColors.caramel.withOpacity(0.5)
              : CoffeeColors.crema,
        ),
      ),
      child: Column(
        children: [
          ListTile(
            onTap: () => setState(() => _open = !_open),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            title: Text(
              widget.faq.q,
              style: TextStyle(
                fontWeight: FontWeight.w700,
                color: _open
                    ? CoffeeColors.espresso
                    : CoffeeColors.darkRoast,
                fontSize: 14,
              ),
            ),
            trailing: AnimatedRotation(
              duration: const Duration(milliseconds: 200),
              turns: _open ? 0.5 : 0,
              child: const Icon(Icons.keyboard_arrow_down,
                  color: CoffeeColors.cocoa),
            ),
          ),
          if (_open)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
              child: Text(
                widget.faq.a,
                style: const TextStyle(
                  color: CoffeeColors.cocoa,
                  fontSize: 13,
                  height: 1.5,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _ContactPage extends StatelessWidget {
  const _ContactPage();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: CoffeeColors.cream,
      appBar: AppBar(title: const Text('Bize Ulaşın')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 40),
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [CoffeeColors.espresso, CoffeeColors.darkRoast],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('💬',
                    style: TextStyle(fontSize: 32)),
                SizedBox(height: 12),
                Text(
                  'Seni duyuyoruz',
                  style: TextStyle(
                    color: CoffeeColors.cream,
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                SizedBox(height: 6),
                Text(
                  'Öneri, şikayet veya geri bildirimini paylaş. Her mesaja 24 saat içinde yanıt veriyoruz.',
                  style: TextStyle(
                      color: CoffeeColors.latte, fontSize: 13, height: 1.4),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          _ContactRow(
            icon: Icons.mail_outline,
            label: 'E-posta',
            value: 'destek@fiyatradar.app',
          ),
          const SizedBox(height: 10),
          _ContactRow(
            icon: Icons.chat_bubble_outline,
            label: 'Canlı Destek',
            value: 'Hafta içi 09:00 – 18:00',
          ),
          const SizedBox(height: 24),
          TextField(
            maxLines: 5,
            decoration: InputDecoration(
              hintText: 'Mesajını buraya yaz…',
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide:
                    const BorderSide(color: CoffeeColors.crema),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide:
                    const BorderSide(color: CoffeeColors.crema),
              ),
            ),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Mesajın iletildi, teşekkürler'),
                  backgroundColor: CoffeeColors.darkRoast,
                  behavior: SnackBarBehavior.floating,
                ),
              );
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(
                minimumSize: const Size.fromHeight(52)),
            child: const Text('Gönder'),
          ),
        ],
      ),
    );
  }
}

class _ContactRow extends StatelessWidget {
  const _ContactRow(
      {required this.icon, required this.label, required this.value});
  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding:
          const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: CoffeeColors.crema),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: CoffeeColors.foam,
              borderRadius: BorderRadius.circular(10),
            ),
            child:
                Icon(icon, color: CoffeeColors.darkRoast, size: 18),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                    color: CoffeeColors.cocoa, fontSize: 11),
              ),
              Text(
                value,
                style: const TextStyle(
                  color: CoffeeColors.espresso,
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ChangelogPage extends StatelessWidget {
  const _ChangelogPage();

  static const _versions = [
    _Version(
      version: '1.0.0',
      date: 'Nisan 2026',
      notes: [
        'İlk kararlı sürüm yayınlandı',
        'Topluluk fiyat katkısı sistemi',
        'Market karşılaştırması',
        'Puan ve seviye sistemi',
        'Fiyat alarmı altyapısı',
      ],
    ),
    _Version(
      version: '0.9.0',
      date: 'Mart 2026',
      notes: [
        'Beta testi başladı',
        'Onboarding akışı eklendi',
        'Arama ve filtreleme iyileştirmeleri',
        'Performans optimizasyonları',
      ],
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: CoffeeColors.cream,
      appBar: AppBar(title: const Text('Güncelleme Geçmişi')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 40),
        children: _versions
            .map((v) => _VersionCard(version: v))
            .toList(),
      ),
    );
  }
}

class _Version {
  final String version;
  final String date;
  final List<String> notes;
  const _Version(
      {required this.version, required this.date, required this.notes});
}

class _VersionCard extends StatelessWidget {
  const _VersionCard({required this.version});
  final _Version version;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: CoffeeColors.crema),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: CoffeeColors.espresso,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'v${version.version}',
                  style: const TextStyle(
                    color: CoffeeColors.cream,
                    fontWeight: FontWeight.w800,
                    fontSize: 12,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Text(
                version.date,
                style: const TextStyle(
                    color: CoffeeColors.cocoa, fontSize: 12),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...version.notes.map((note) => Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Padding(
                      padding: EdgeInsets.only(top: 6),
                      child: CircleAvatar(
                        radius: 3,
                        backgroundColor: CoffeeColors.caramel,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        note,
                        style: const TextStyle(
                          color: CoffeeColors.darkRoast,
                          fontSize: 13,
                          height: 1.4,
                        ),
                      ),
                    ),
                  ],
                ),
              )),
        ],
      ),
    );
  }
}

class _TermsPage extends StatelessWidget {
  const _TermsPage();

  @override
  Widget build(BuildContext context) {
    return _TextContentPage(
      title: 'Kullanım Koşulları',
      sections: const [
        _TextSection(
          heading: '1. Hizmetin Kapsamı',
          body:
              'FiyatRadar, kullanıcıların market fiyatlarını paylaşmasına ve karşılaştırmasına olanak tanıyan topluluk destekli bir platformdur. Uygulama yalnızca bilgi amaçlıdır.',
        ),
        _TextSection(
          heading: '2. Kullanıcı Yükümlülükleri',
          body:
              'Kullanıcılar yalnızca gerçek ve doğru fiyat bilgisi paylaşmalıdır. Yanıltıcı veya sahte bilgi girişi hesap askıya alınmasına yol açabilir.',
        ),
        _TextSection(
          heading: '3. Veri Kullanımı',
          body:
              'Paylaşılan fiyat verileri anonim olarak analiz edilir ve toplulukla paylaşılır. Kişisel veriler üçüncü taraflarla satılmaz.',
        ),
        _TextSection(
          heading: '4. Sorumluluk Sınırlaması',
          body:
              'FiyatRadar, paylaşılan fiyat verilerinin doğruluğunu garanti etmez. Satın alma kararları kullanıcının sorumluluğundadır.',
        ),
        _TextSection(
          heading: '5. Değişiklikler',
          body:
              'Bu koşullar önceden bildirim yapılarak değiştirilebilir. Uygulamayı kullanmaya devam etmek güncel koşulları kabul etmek anlamına gelir.',
        ),
      ],
    );
  }
}

class _PrivacyPage extends StatelessWidget {
  const _PrivacyPage();

  @override
  Widget build(BuildContext context) {
    return _TextContentPage(
      title: 'Gizlilik Politikası',
      sections: const [
        _TextSection(
          heading: 'Topladığımız Veriler',
          body:
              'E-posta adresi, kullanıcı adı ve fiyat katkıları toplanır. Konum verisi opsiyoneldir ve yalnızca yakın market önerileri için kullanılır.',
        ),
        _TextSection(
          heading: 'Verilerin Kullanımı',
          body:
              'Verileriniz hizmetin iyileştirilmesi, topluluk içeriklerinin moderasyonu ve kişiselleştirilmiş öneriler için kullanılır.',
        ),
        _TextSection(
          heading: 'Veri Güvenliği',
          body:
              'Tüm veriler şifreli bağlantı (TLS) üzerinden iletilir. Firebase altyapısı kullanılmaktadır ve endüstri standardı güvenlik önlemleri uygulanmaktadır.',
        ),
        _TextSection(
          heading: 'Üçüncü Taraflar',
          body:
              'Kişisel verileriniz hiçbir üçüncü tarafa satılmaz veya kiralanmaz. Analitik amaçlı anonimleştirilmiş veriler kullanılabilir.',
        ),
        _TextSection(
          heading: 'Haklarınız',
          body:
              'Hesabınızı ve verilerinizi istediğiniz zaman silebilirsiniz. Veri erişim veya silme talepleriniz için destek@fiyatradar.app adresine yazabilirsiniz.',
        ),
      ],
    );
  }
}

class _TextSection {
  final String heading;
  final String body;
  const _TextSection({required this.heading, required this.body});
}

class _TextContentPage extends StatelessWidget {
  const _TextContentPage(
      {required this.title, required this.sections});
  final String title;
  final List<_TextSection> sections;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: CoffeeColors.cream,
      appBar: AppBar(title: Text(title)),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 40),
        children: [
          ...sections.map((s) => Padding(
                padding: const EdgeInsets.only(bottom: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      s.heading,
                      style: const TextStyle(
                        color: CoffeeColors.espresso,
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      s.body,
                      style: const TextStyle(
                        color: CoffeeColors.darkRoast,
                        fontSize: 13,
                        height: 1.55,
                      ),
                    ),
                  ],
                ),
              )),
        ],
      ),
    );
  }
}

// ─── Reusable toggle components ───────────────────────────────────────────────

class _ToggleTile extends StatelessWidget {
  const _ToggleTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });
  final IconData icon;
  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: CoffeeColors.crema),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: value
                  ? CoffeeColors.espresso.withOpacity(0.1)
                  : CoffeeColors.foam,
              borderRadius: BorderRadius.circular(11),
            ),
            child: Icon(icon,
                color: value
                    ? CoffeeColors.espresso
                    : CoffeeColors.darkRoast,
                size: 20),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        color: CoffeeColors.espresso,
                        fontSize: 14)),
                Text(subtitle,
                    style: const TextStyle(
                        color: CoffeeColors.cocoa, fontSize: 12)),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeColor: CoffeeColors.espresso,
            activeTrackColor: CoffeeColors.caramel,
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
  });
  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: const EdgeInsets.fromLTRB(16, 4, 12, 4),
      title: Text(title,
          style: const TextStyle(
              fontWeight: FontWeight.w700,
              color: CoffeeColors.espresso,
              fontSize: 14)),
      subtitle: Text(subtitle,
          style: const TextStyle(color: CoffeeColors.cocoa, fontSize: 12)),
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
  const _ActionTile(
      {required this.icon, required this.title, required this.onTap});
  final IconData icon;
  final String title;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: onTap,
      contentPadding:
          const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      leading: Container(
        width: 38,
        height: 38,
        decoration: BoxDecoration(
          color: CoffeeColors.foam,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: CoffeeColors.darkRoast, size: 19),
      ),
      title: Text(title,
          style: const TextStyle(
              fontWeight: FontWeight.w700,
              color: CoffeeColors.espresso,
              fontSize: 14)),
      trailing: const Icon(Icons.chevron_right,
          color: CoffeeColors.cocoa, size: 20),
    );
  }
}
