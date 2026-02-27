import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';

// --- FİYATRADAR MARKA DNA'SI ---
const Color vanillaDark = Color(0xFFF5F3F0);
const Color vanilla = Color(0xFFFDFBF9);
const Color sienna = Color(0xFF8B4D22);
const Color siennaLight = Color(0x1A8B4D22); // %10 opacity
const Color textMain = Color(0xFF2D241E);
const Color textMuted = Color(0xFF8E8A86);
const Color borderColor = Color(0x148B4D22); // İnce karamel çizgi
const Color danger = Color(0xFFDC2626);

// ============================================================================
// ANA EKRAN: HESAP & AYARLAR
// ============================================================================
class FiyatRadarSettingsScreen extends StatelessWidget {
  const FiyatRadarSettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: vanillaDark,
      appBar: AppBar(
        backgroundColor: vanilla.withOpacity(0.95),
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: sienna),
        title: const Text('Hesap & Ayarlar', style: TextStyle(color: textMain, fontSize: 17, fontWeight: FontWeight.w600)),
        bottom: PreferredSize(preferredSize: const Size.fromHeight(1), child: Container(color: borderColor, height: 1)),
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(vertical: 24),
        children: [
          // PROFIL KARTI (Premium Gradient)
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: borderColor),
              boxShadow: [BoxShadow(color: sienna.withOpacity(0.04), blurRadius: 20, offset: const Offset(0, 4))],
            ),
            child: ListTile(
              contentPadding: const EdgeInsets.all(16),
              leading: Container(
                width: 64, height: 64,
                decoration: BoxDecoration(color: siennaLight, borderRadius: BorderRadius.circular(18)),
                alignment: Alignment.center,
                child: const Text('AB', style: TextStyle(color: sienna, fontSize: 22, fontWeight: FontWeight.bold)),
              ),
              title: const Text('Adem Bayram', style: TextStyle(color: textMain, fontSize: 18, fontWeight: FontWeight.w700)),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 4),
                  const Text('İstanbul, Kadıköy • @adem', style: TextStyle(color: textMuted, fontSize: 13)),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(color: const Color(0xFF2E7D32).withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
                    child: const Text('%86 Güven Endeksi', style: TextStyle(color: Color(0xFF2E7D32), fontSize: 11, fontWeight: FontWeight.w600)),
                  ),
                ],
              ),
              trailing: const Icon(Icons.chevron_right, color: textMuted),
              onTap: () => Navigator.push(context, CupertinoPageRoute(builder: (_) => const PersonalInfoScreen())),
            ),
          ),
          const SizedBox(height: 24),

          // HESAP YÖNETİMİ
          _buildSectionTitle('Hesap Yönetimi'),
          _buildInsetGroup([
            _buildListTile(icon: Icons.person_outline, title: 'Kişisel Bilgiler & Konum', onTap: () => Navigator.push(context, CupertinoPageRoute(builder: (_) => const PersonalInfoScreen()))),
            _buildDivider(),
            _buildListTile(icon: Icons.lock_outline, title: 'Güvenlik ve Giriş', onTap: () => Navigator.push(context, CupertinoPageRoute(builder: (_) => const SecurityScreen()))),
          ]),

          const SizedBox(height: 24),

          // UYGULAMA TERCİHLERİ
          _buildSectionTitle('Uygulama Tercihleri'),
          _buildInsetGroup([
            _buildListTile(icon: Icons.notifications_none, title: 'Bildirim Ayarları', onTap: () => Navigator.push(context, CupertinoPageRoute(builder: (_) => const NotificationsScreen()))),
            _buildDivider(),
            _buildListTile(icon: Icons.dark_mode_outlined, title: 'Karanlık Tema', trailing: CupertinoSwitch(value: false, activeColor: sienna, onChanged: (v) {})),
            _buildDivider(),
            _buildListTile(icon: Icons.cleaning_services_outlined, title: 'Önbelleği Temizle', subtitle: 'Uygulama yavaşlarsa kullan', trailing: const SizedBox.shrink()),
          ]),
          
          const SizedBox(height: 24),
          
          // DİĞER
          _buildSectionTitle('Diğer'),
          _buildInsetGroup([
            _buildListTile(icon: Icons.info_outline, title: 'Hakkında ve Destek', onTap: () => Navigator.push(context, CupertinoPageRoute(builder: (_) => const AboutScreen()))),
          ]),

          const SizedBox(height: 32),
          // TEHLİKELİ BÖLGE
          _buildSectionTitle('Tehlikeli Bölge', color: danger),
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 20),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), border: Border.all(color: danger.withOpacity(0.2))),
            child: ListTile(
              title: const Text('Hesabı Kalıcı Olarak Sil', style: TextStyle(color: danger, fontWeight: FontWeight.w600, fontSize: 15)),
              trailing: const Icon(Icons.chevron_right, color: danger),
              onTap: () {},
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title, {Color color = textMuted}) {
    return Padding(
      padding: const EdgeInsets.only(left: 36, bottom: 8),
      child: Text(title.toUpperCase(), style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w600, letterSpacing: 0.5)),
    );
  }

  Widget _buildInsetGroup(List<Widget> children) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: borderColor),
        boxShadow: [BoxShadow(color: sienna.withOpacity(0.02), blurRadius: 15, offset: const Offset(0, 4))],
      ),
      child: Column(children: children),
    );
  }

  Widget _buildListTile({required IconData icon, required String title, String? subtitle, Widget? trailing, VoidCallback? onTap}) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
      leading: Container(
        width: 36, height: 36,
        decoration: BoxDecoration(color: siennaLight, borderRadius: BorderRadius.circular(10)),
        child: Icon(icon, color: sienna, size: 20),
      ),
      title: Text(title, style: const TextStyle(color: textMain, fontSize: 15, fontWeight: FontWeight.w600)),
      subtitle: subtitle != null ? Text(subtitle, style: const TextStyle(color: textMuted, fontSize: 13)) : null,
      trailing: trailing ?? const Icon(Icons.chevron_right, color: textMuted),
      onTap: onTap,
    );
  }

  Widget _buildDivider() => const Divider(height: 1, thickness: 1, color: borderColor, indent: 64);
}

// ============================================================================
// ALT SAYFA 1: KİŞİSEL BİLGİLER
// ============================================================================
class PersonalInfoScreen extends StatelessWidget {
  const PersonalInfoScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: vanillaDark,
      appBar: AppBar(
        backgroundColor: vanilla.withOpacity(0.95), elevation: 0, iconTheme: const IconThemeData(color: sienna),
        centerTitle: true, title: const Text('Kişisel Bilgiler', style: TextStyle(color: textMain, fontSize: 17, fontWeight: FontWeight.w600)),
        bottom: PreferredSize(preferredSize: const Size.fromHeight(1), child: Container(color: borderColor, height: 1)),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          // Profil Foto Edit (Premium)
          Center(
            child: Stack(
              children: [
                Container(
                  width: 88, height: 88,
                  decoration: BoxDecoration(color: siennaLight, borderRadius: BorderRadius.circular(28)),
                  alignment: Alignment.center,
                  child: const Text('AB', style: TextStyle(color: sienna, fontSize: 32, fontWeight: FontWeight.bold)),
                ),
                Positioned(
                  bottom: -4, right: -4,
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(color: Colors.white, shape: BoxShape.circle, border: Border.all(color: borderColor), boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 4)]),
                    child: const Icon(Icons.camera_alt, size: 16, color: textMain),
                  ),
                )
              ],
            ),
          ),
          const SizedBox(height: 12),
          const Center(child: Text('Fotoğrafı Değiştir', style: TextStyle(color: sienna, fontWeight: FontWeight.w600, fontSize: 14))),
          const SizedBox(height: 32),

          const Padding(padding: EdgeInsets.only(left: 16, bottom: 8), child: Text('TEMEL BİLGİLER', style: TextStyle(color: textMuted, fontSize: 12, fontWeight: FontWeight.w600))),
          Container(
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), border: Border.all(color: borderColor)),
            child: Column(
              children: [
                _buildFloatingInput(label: 'Ad', value: 'Adem'),
                const Divider(height: 1, color: borderColor, indent: 20),
                _buildFloatingInput(label: 'Soyad', value: 'Bayram'),
                const Divider(height: 1, color: borderColor, indent: 20),
                _buildFloatingInput(label: 'Kullanıcı Adı', value: '@adem'),
              ],
            ),
          ),
          
          const SizedBox(height: 24),

          const Padding(padding: EdgeInsets.only(left: 16, bottom: 8), child: Text('KONUM (Market Önerileri İçin)', style: TextStyle(color: textMuted, fontSize: 12, fontWeight: FontWeight.w600))),
          Container(
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), border: Border.all(color: borderColor)),
            child: Column(
              children: [
                _buildDropdown(label: 'İl', value: 'İstanbul'),
                const Divider(height: 1, color: borderColor, indent: 20),
                _buildDropdown(label: 'İlçe', value: 'Kadıköy'),
                const Divider(height: 1, color: borderColor, indent: 20),
                _buildDropdown(label: 'Mahalle', value: 'Cumhuriyet Mah.'),
              ],
            ),
          ),

          const SizedBox(height: 32),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: sienna, padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)), elevation: 0,
            ),
            onPressed: () {},
            child: const Text('Değişiklikleri Kaydet', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.white)),
          )
        ],
      ),
    );
  }

  Widget _buildFloatingInput({required String label, required String value}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
      child: TextFormField(
        initialValue: value,
        style: const TextStyle(color: textMain, fontSize: 16, fontWeight: FontWeight.w500),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: const TextStyle(color: sienna, fontSize: 14, fontWeight: FontWeight.w600),
          border: InputBorder.none, isDense: true, contentPadding: const EdgeInsets.symmetric(vertical: 8),
        ),
      ),
    );
  }

  Widget _buildDropdown({required String label, required String value}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
      child: DropdownButtonFormField<String>(
        value: value,
        icon: const Icon(Icons.keyboard_arrow_down, color: sienna),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: const TextStyle(color: sienna, fontSize: 14, fontWeight: FontWeight.w600),
          border: InputBorder.none, isDense: true, contentPadding: const EdgeInsets.symmetric(vertical: 8),
        ),
        items: [DropdownMenuItem(value: value, child: Text(value, style: const TextStyle(color: textMain, fontSize: 16, fontWeight: FontWeight.w500)))],
        onChanged: (v) {},
      ),
    );
  }
}

// ============================================================================
// ALT SAYFA 2: GÜVENLİK (Yakında rezaletinin bittiği yer)
// ============================================================================
class SecurityScreen extends StatelessWidget {
  const SecurityScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: vanillaDark,
      appBar: AppBar(
        backgroundColor: vanilla.withOpacity(0.95), elevation: 0, iconTheme: const IconThemeData(color: sienna),
        centerTitle: true, title: const Text('Güvenlik ve Giriş', style: TextStyle(color: textMain, fontSize: 17, fontWeight: FontWeight.w600)),
        bottom: PreferredSize(preferredSize: const Size.fromHeight(1), child: Container(color: borderColor, height: 1)),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const Padding(padding: EdgeInsets.only(left: 16, bottom: 8), child: Text('E-POSTA YÖNETİMİ', style: TextStyle(color: textMuted, fontSize: 12, fontWeight: FontWeight.w600))),
          Container(
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), border: Border.all(color: borderColor)),
            child: Column(
              children: [
                _buildInput(label: 'Mevcut E-Posta', hint: 'adem@fiyatradar.com', enabled: false),
                const Divider(height: 1, color: borderColor, indent: 20),
                _buildInput(label: 'Yeni E-Posta Adresi', hint: 'yeni@email.com'),
              ],
            ),
          ),
          const SizedBox(height: 24),

          const Padding(padding: EdgeInsets.only(left: 16, bottom: 8), child: Text('ŞİFRE DEĞİŞTİR', style: TextStyle(color: textMuted, fontSize: 12, fontWeight: FontWeight.w600))),
          Container(
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), border: Border.all(color: borderColor)),
            child: Column(
              children: [
                _buildInput(label: 'Mevcut Şifre', hint: '••••••••', isPassword: true),
                const Divider(height: 1, color: borderColor, indent: 20),
                _buildInput(label: 'Yeni Şifre', hint: '••••••••', isPassword: true),
              ],
            ),
          ),
          const SizedBox(height: 32),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: sienna, padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)), elevation: 0,
            ),
            onPressed: () {},
            child: const Text('Güvenlik Bilgilerini Güncelle', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.white)),
          )
        ],
      ),
    );
  }

  Widget _buildInput({required String label, required String hint, bool isPassword = false, bool enabled = true}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
      child: TextFormField(
        obscureText: isPassword,
        enabled: enabled,
        style: TextStyle(color: enabled ? textMain : textMuted, fontSize: 16, fontWeight: FontWeight.w500),
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          labelStyle: const TextStyle(color: sienna, fontSize: 14, fontWeight: FontWeight.w600),
          border: InputBorder.none, isDense: true, contentPadding: const EdgeInsets.symmetric(vertical: 8),
        ),
      ),
    );
  }
}

// ============================================================================
// ALT SAYFA 3: BİLDİRİMLER (Karamel Toggle'lı)
// ============================================================================
class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: vanillaDark,
      appBar: AppBar(
        backgroundColor: vanilla.withOpacity(0.95), elevation: 0, iconTheme: const IconThemeData(color: sienna),
        centerTitle: true, title: const Text('Bildirimler', style: TextStyle(color: textMain, fontSize: 17, fontWeight: FontWeight.w600)),
        bottom: PreferredSize(preferredSize: const Size.fromHeight(1), child: Container(color: borderColor, height: 1)),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Container(
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), border: Border.all(color: borderColor)),
            child: Column(
              children: [
                _buildSwitchTile('Fiyat Alarmı Bildirimleri', 'Takip ettiğin ürün düştüğünde uyar.', true),
                const Divider(height: 1, color: borderColor, indent: 20),
                _buildSwitchTile('Kampanya Bildirimleri', 'Haftalık indirimleri bildirir.', true),
                const Divider(height: 1, color: borderColor, indent: 20),
                _buildSwitchTile('Rozet ve Puan Bildirimleri', 'Liderlik tablosu değişimlerini bildirir.', false),
              ],
            ),
          ),
          const Padding(
            padding: EdgeInsets.only(top: 16, left: 20, right: 20),
            child: Text('FiyatRadar, bildirimleri sadece sana özel fırsatlar yakalandığında gönderir. Asla spam yapmaz.', textAlign: TextAlign.center, style: TextStyle(color: textMuted, fontSize: 12)),
          )
        ],
      ),
    );
  }

  Widget _buildSwitchTile(String title, String subtitle, bool value) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      title: Text(title, style: const TextStyle(color: textMain, fontSize: 15, fontWeight: FontWeight.w600)),
      subtitle: Text(subtitle, style: const TextStyle(color: textMuted, fontSize: 13)),
      trailing: CupertinoSwitch(value: value, activeColor: sienna, onChanged: (v) {}),
    );
  }
}

// ============================================================================
// ALT SAYFA 4: HAKKINDA (Sürüm Bilgisi ve SSS)
// ============================================================================
class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: vanillaDark,
      appBar: AppBar(
        backgroundColor: vanilla.withOpacity(0.95), elevation: 0, iconTheme: const IconThemeData(color: sienna),
        centerTitle: true, title: const Text('Hakkında', style: TextStyle(color: textMain, fontSize: 17, fontWeight: FontWeight.w600)),
        bottom: PreferredSize(preferredSize: const Size.fromHeight(1), child: Container(color: borderColor, height: 1)),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const SizedBox(height: 20),
          Center(
            child: Container(
              width: 80, height: 80,
              decoration: BoxDecoration(color: sienna, borderRadius: BorderRadius.circular(20), boxShadow: [BoxShadow(color: sienna.withOpacity(0.3), blurRadius: 20, offset: const Offset(0, 8))]),
              child: const Icon(Icons.radar, color: Colors.white, size: 40),
            ),
          ),
          const SizedBox(height: 16),
          const Center(child: Text('FiyatRadar', style: TextStyle(color: textMain, fontSize: 22, fontWeight: FontWeight.bold, fontFamily: 'Poppins'))),
          const Center(child: Text('Sürüm 3.0.0', style: TextStyle(color: textMuted, fontSize: 14))),
          const SizedBox(height: 40),

          const Padding(padding: EdgeInsets.only(left: 16, bottom: 8), child: Text('DESTEK VE BİLGİ', style: TextStyle(color: textMuted, fontSize: 12, fontWeight: FontWeight.w600))),
          Container(
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), border: Border.all(color: borderColor)),
            child: Column(
              children: [
                _buildListTile('Sıkça Sorulan Sorular (SSS)'),
                const Divider(height: 1, color: borderColor, indent: 20),
                _buildListTile('Bize Ulaşın'),
                const Divider(height: 1, color: borderColor, indent: 20),
                _buildListTile('Güncelleme Geçmişi'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildListTile(String title) {
    return ListTile(
      title: Text(title, style: const TextStyle(color: textMain, fontSize: 15, fontWeight: FontWeight.w500)),
      trailing: const Icon(Icons.chevron_right, color: textMuted),
      onTap: () {},
    );
  }
}
