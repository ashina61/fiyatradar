import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'user_model.dart';
import 'profile_service.dart';

// --- FİYATRADAR MARKA DNA'SI ---
const Color vanillaDark = Color(0xFFF5F3F0);
const Color vanilla = Color(0xFFFDFBF9);
const Color sienna = Color(0xFF8B4D22);
const Color siennaLight = Color(0x1A8B4D22); 
const Color textMain = Color(0xFF2D241E);
const Color textMuted = Color(0xFF8E8A86);
const Color borderColor = Color(0x148B4D22); 
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
          // PROFIL KARTI (Premium)
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
              title: const Text('Profilini Düzenle', style: TextStyle(color: textMain, fontSize: 18, fontWeight: FontWeight.w700)),
              subtitle: const Text('Kişisel bilgilerini ve konumunu güncelle', style: TextStyle(color: textMuted, fontSize: 13)),
              trailing: const Icon(Icons.chevron_right, color: textMuted),
              onTap: () => Navigator.push(context, CupertinoPageRoute(builder: (_) => const PersonalInfoScreen())),
            ),
          ),
          const SizedBox(height: 24),

          _buildSectionTitle('Hesap Yönetimi'),
          _buildInsetGroup([
            _buildListTile(icon: Icons.person_outline, title: 'Kişisel Bilgiler & Konum', onTap: () => Navigator.push(context, CupertinoPageRoute(builder: (_) => const PersonalInfoScreen()))),
            _buildDivider(),
            _buildListTile(icon: Icons.lock_outline, title: 'Güvenlik ve Giriş', onTap: () => Navigator.push(context, CupertinoPageRoute(builder: (_) => const SecurityScreen()))),
          ]),

          const SizedBox(height: 24),

          _buildSectionTitle('Uygulama Tercihleri'),
          _buildInsetGroup([
            _buildListTile(icon: Icons.notifications_none, title: 'Bildirim Ayarları', onTap: () => Navigator.push(context, CupertinoPageRoute(builder: (_) => const NotificationsScreen()))),
            _buildDivider(),
            _buildListTile(icon: Icons.cleaning_services_outlined, title: 'Önbelleği Temizle', subtitle: 'Uygulama yavaşlarsa kullan', trailing: const SizedBox.shrink()),
          ]),
          
          const SizedBox(height: 24),
          
          _buildSectionTitle('Diğer'),
          _buildInsetGroup([
            _buildListTile(icon: Icons.info_outline, title: 'Hakkında ve Destek', onTap: () => Navigator.push(context, CupertinoPageRoute(builder: (_) => const AboutScreen()))),
          ]),
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
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), border: Border.all(color: borderColor), boxShadow: [BoxShadow(color: sienna.withOpacity(0.02), blurRadius: 15, offset: const Offset(0, 4))]),
      child: Column(children: children),
    );
  }

  Widget _buildListTile({required IconData icon, required String title, String? subtitle, Widget? trailing, VoidCallback? onTap}) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
      leading: Container(width: 36, height: 36, decoration: BoxDecoration(color: siennaLight, borderRadius: BorderRadius.circular(10)), child: Icon(icon, color: sienna, size: 20)),
      title: Text(title, style: const TextStyle(color: textMain, fontSize: 15, fontWeight: FontWeight.w600)),
      subtitle: subtitle != null ? Text(subtitle, style: const TextStyle(color: textMuted, fontSize: 13)) : null,
      trailing: trailing ?? const Icon(Icons.chevron_right, color: textMuted),
      onTap: onTap,
    );
  }

  Widget _buildDivider() => const Divider(height: 1, thickness: 1, color: borderColor, indent: 64);
}

// ============================================================================
// ALT SAYFA 1: KİŞİSEL BİLGİLER (FIREBASE ENTEGRELİ)
// ============================================================================
class PersonalInfoScreen extends StatefulWidget {
  const PersonalInfoScreen({super.key});

  @override
  State<PersonalInfoScreen> createState() => _PersonalInfoScreenState();
}

class _PersonalInfoScreenState extends State<PersonalInfoScreen> {
  final ProfileService _profileService = ProfileService();
  UserModel? _currentUser;
  bool _isLoading = true;
  bool _isSaving = false;

  final TextEditingController _nameCtrl = TextEditingController();
  final TextEditingController _surnameCtrl = TextEditingController();
  final TextEditingController _usernameCtrl = TextEditingController();

  String _selectedCity = 'İstanbul';
  String _selectedDistrict = 'Kadıköy';
  String _selectedNeighborhood = 'Cumhuriyet Mah.';

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final user = await _profileService.getUserProfile();
    if (user != null) {
      _currentUser = user;
      _nameCtrl.text = user.name;
      _surnameCtrl.text = user.surname;
      _usernameCtrl.text = user.username;
      _selectedCity = user.city.isNotEmpty ? user.city : 'İstanbul';
      _selectedDistrict = user.district.isNotEmpty ? user.district : 'Kadıköy';
      _selectedNeighborhood = user.neighborhood.isNotEmpty ? user.neighborhood : 'Cumhuriyet Mah.';
    } else {
      // Firebase'de veri yoksa boş bir taslak oluştur
      _currentUser = UserModel(
        id: _profileService.currentUserId ?? 'temp',
        name: '', surname: '', username: '', city: 'İstanbul', district: 'Kadıköy', neighborhood: 'Cumhuriyet Mah.',
        priceAlarm: true, campaignNotification: true, badgeNotification: true,
      );
    }
    setState(() => _isLoading = false);
  }

  Future<void> _saveData() async {
    if (_currentUser == null) return;
    setState(() => _isSaving = true);

    final updatedUser = _currentUser!.copyWith(
      name: _nameCtrl.text.trim(),
      surname: _surnameCtrl.text.trim(),
      username: _usernameCtrl.text.trim(),
      city: _selectedCity,
      district: _selectedDistrict,
      neighborhood: _selectedNeighborhood,
    );

    bool success = await _profileService.updateUserProfile(updatedUser);
    
    setState(() => _isSaving = false);

    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Profil başarıyla güncellendi!'), backgroundColor: Colors.green));
      Navigator.pop(context);
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Hata oluştu, lütfen tekrar deneyin.'), backgroundColor: danger));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: vanillaDark,
      appBar: AppBar(
        backgroundColor: vanilla.withOpacity(0.95), elevation: 0, iconTheme: const IconThemeData(color: sienna),
        centerTitle: true, title: const Text('Kişisel Bilgiler', style: TextStyle(color: textMain, fontSize: 17, fontWeight: FontWeight.w600)),
        bottom: PreferredSize(preferredSize: const Size.fromHeight(1), child: Container(color: borderColor, height: 1)),
      ),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator(color: sienna))
        : ListView(
        padding: const EdgeInsets.all(20),
        children: [
          // Profil Foto Edit
          Center(
            child: Stack(
              children: [
                Container(width: 88, height: 88, decoration: BoxDecoration(color: siennaLight, borderRadius: BorderRadius.circular(28)), alignment: Alignment.center, child: const Text('AB', style: TextStyle(color: sienna, fontSize: 32, fontWeight: FontWeight.bold))),
                Positioned(bottom: -4, right: -4, child: Container(padding: const EdgeInsets.all(6), decoration: BoxDecoration(color: Colors.white, shape: BoxShape.circle, border: Border.all(color: borderColor), boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 4)]), child: const Icon(Icons.camera_alt, size: 16, color: textMain)))
              ],
            ),
          ),
          const SizedBox(height: 32),

          const Padding(padding: EdgeInsets.only(left: 16, bottom: 8), child: Text('TEMEL BİLGİLER', style: TextStyle(color: textMuted, fontSize: 12, fontWeight: FontWeight.w600))),
          Container(
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), border: Border.all(color: borderColor)),
            child: Column(
              children: [
                _buildFloatingInput(label: 'Ad', controller: _nameCtrl),
                const Divider(height: 1, color: borderColor, indent: 20),
                _buildFloatingInput(label: 'Soyad', controller: _surnameCtrl),
                const Divider(height: 1, color: borderColor, indent: 20),
                _buildFloatingInput(label: 'Kullanıcı Adı', controller: _usernameCtrl),
              ],
            ),
          ),
          
          const SizedBox(height: 24),

          const Padding(padding: EdgeInsets.only(left: 16, bottom: 8), child: Text('KONUM (Market Önerileri İçin)', style: TextStyle(color: textMuted, fontSize: 12, fontWeight: FontWeight.w600))),
          Container(
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), border: Border.all(color: borderColor)),
            child: Column(
              children: [
                _buildDropdown(label: 'İl', value: _selectedCity, items: ['İstanbul', 'Ankara', 'İzmir'], onChanged: (v) => setState(() => _selectedCity = v!)),
                const Divider(height: 1, color: borderColor, indent: 20),
                _buildDropdown(label: 'İlçe', value: _selectedDistrict, items: ['Kadıköy', 'Beşiktaş', 'Üsküdar'], onChanged: (v) => setState(() => _selectedDistrict = v!)),
                const Divider(height: 1, color: borderColor, indent: 20),
                _buildDropdown(label: 'Mahalle', value: _selectedNeighborhood, items: ['Cumhuriyet Mah.', 'Caferağa Mah.', 'Osmanağa Mah.'], onChanged: (v) => setState(() => _selectedNeighborhood = v!)),
              ],
            ),
          ),

          const SizedBox(height: 32),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: sienna, padding: const EdgeInsets.symmetric(vertical: 16), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)), elevation: 0),
            onPressed: _isSaving ? null : _saveData,
            child: _isSaving ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) : const Text('Değişiklikleri Kaydet', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.white)),
          )
        ],
      ),
    );
  }

  Widget _buildFloatingInput({required String label, required TextEditingController controller}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
      child: TextFormField(
        controller: controller,
        style: const TextStyle(color: textMain, fontSize: 16, fontWeight: FontWeight.w500),
        decoration: InputDecoration(labelText: label, labelStyle: const TextStyle(color: sienna, fontSize: 14, fontWeight: FontWeight.w600), border: InputBorder.none, isDense: true, contentPadding: const EdgeInsets.symmetric(vertical: 8)),
      ),
    );
  }

  Widget _buildDropdown({required String label, required String value, required List<String> items, required ValueChanged<String?> onChanged}) {
    // Liste güvenliği: seçili değer listede yoksa ilkini ata
    if (!items.contains(value)) value = items.first; 
    
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
      child: DropdownButtonFormField<String>(
        value: value,
        icon: const Icon(Icons.keyboard_arrow_down, color: sienna),
        decoration: InputDecoration(labelText: label, labelStyle: const TextStyle(color: sienna, fontSize: 14, fontWeight: FontWeight.w600), border: InputBorder.none, isDense: true, contentPadding: const EdgeInsets.symmetric(vertical: 8)),
        items: items.map((e) => DropdownMenuItem(value: e, child: Text(e, style: const TextStyle(color: textMain, fontSize: 16, fontWeight: FontWeight.w500)))).toList(),
        onChanged: onChanged,
      ),
    );
  }
}

// ============================================================================
// ALT SAYFA 2: BİLDİRİMLER (FIREBASE ENTEGRELİ)
// ============================================================================
class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  final ProfileService _profileService = ProfileService();
  UserModel? _currentUser;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final user = await _profileService.getUserProfile();
    setState(() {
      _currentUser = user;
      _isLoading = false;
    });
  }

  Future<void> _updateToggle(bool value, String field) async {
    if (_currentUser == null) return;
    
    // Anında UI güncelle (Hızlı hissiyat)
    setState(() {
      if (field == 'alarm') _currentUser = _currentUser!.copyWith(priceAlarm: value);
      if (field == 'campaign') _currentUser = _currentUser!.copyWith(campaignNotification: value);
      if (field == 'badge') _currentUser = _currentUser!.copyWith(badgeNotification: value);
    });

    // Arka planda Firebase'e yaz
    await _profileService.updateUserProfile(_currentUser!);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: vanillaDark,
      appBar: AppBar(
        backgroundColor: vanilla.withOpacity(0.95), elevation: 0, iconTheme: const IconThemeData(color: sienna),
        centerTitle: true, title: const Text('Bildirimler', style: TextStyle(color: textMain, fontSize: 17, fontWeight: FontWeight.w600)),
        bottom: PreferredSize(preferredSize: const Size.fromHeight(1), child: Container(color: borderColor, height: 1)),
      ),
      body: _isLoading
        ? const Center(child: CircularProgressIndicator(color: sienna))
        : ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Container(
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), border: Border.all(color: borderColor)),
            child: Column(
              children: [
                _buildSwitchTile('Fiyat Alarmı Bildirimleri', 'Takip ettiğin ürün düştüğünde uyar.', _currentUser?.priceAlarm ?? true, (v) => _updateToggle(v, 'alarm')),
                const Divider(height: 1, color: borderColor, indent: 20),
                _buildSwitchTile('Kampanya Bildirimleri', 'Haftalık indirimleri bildirir.', _currentUser?.campaignNotification ?? true, (v) => _updateToggle(v, 'campaign')),
                const Divider(height: 1, color: borderColor, indent: 20),
                _buildSwitchTile('Rozet ve Puan Bildirimleri', 'Liderlik tablosu değişimlerini bildirir.', _currentUser?.badgeNotification ?? false, (v) => _updateToggle(v, 'badge')),
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

  Widget _buildSwitchTile(String title, String subtitle, bool value, ValueChanged<bool> onChanged) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      title: Text(title, style: const TextStyle(color: textMain, fontSize: 15, fontWeight: FontWeight.w600)),
      subtitle: Text(subtitle, style: const TextStyle(color: textMuted, fontSize: 13)),
      trailing: CupertinoSwitch(value: value, activeColor: sienna, onChanged: onChanged),
    );
  }
}

// ============================================================================
// DİĞER SAYFALAR (GÜVENLİK VE HAKKINDA)
// ============================================================================
class SecurityScreen extends StatelessWidget {
  const SecurityScreen({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: vanillaDark,
      appBar: AppBar(backgroundColor: vanilla, iconTheme: const IconThemeData(color: sienna), title: const Text('Güvenlik', style: TextStyle(color: textMain))),
      body: const Center(child: Text('Firebase Auth işlemleri eklenecek.', style: TextStyle(color: textMuted))),
    );
  }
}

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: vanillaDark,
      appBar: AppBar(backgroundColor: vanilla, iconTheme: const IconThemeData(color: sienna), title: const Text('Hakkında', style: TextStyle(color: textMain))),
      body: const Center(child: Text('FiyatRadar v3.0.0', style: TextStyle(color: sienna, fontSize: 20, fontWeight: FontWeight.bold))),
    );
  }
}
