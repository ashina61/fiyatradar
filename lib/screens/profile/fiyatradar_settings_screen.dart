import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../../models/user_model.dart';
import '../../services/user_settings_repository.dart';

class FiyatRadarSettingsScreen extends StatefulWidget {
  const FiyatRadarSettingsScreen({super.key});

  @override
  State<FiyatRadarSettingsScreen> createState() => _FiyatRadarSettingsScreenState();
}

class _FiyatRadarSettingsScreenState extends State<FiyatRadarSettingsScreen> {
  static const vanilla = Color(0xFFF5F3F0);
  static const sienna = Color(0xFF8B4D22);
  static const card = Color(0xFFFFFFFF);

  final UserSettingsRepository _repository = UserSettingsRepository();

  bool _loading = true;
  String? _error;
  UserModel? _user;
  bool _darkMode = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final user = await _repository.fetchCurrentUser();
      if (!mounted) {
        return;
      }
      setState(() {
        _user = user;
      });
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _error = error.toString();
      });
    } finally {
      if (mounted) {
        setState(() {
          _loading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: ThemeData(
        scaffoldBackgroundColor: vanilla,
        colorScheme: ColorScheme.fromSeed(seedColor: sienna),
      ),
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: vanilla,
          centerTitle: true,
          title: const Text(
            'Hesap & Ayarlar',
            style: TextStyle(fontWeight: FontWeight.w600),
          ),
        ),
        body: _loading
            ? const Center(child: CircularProgressIndicator())
            : _error != null
                ? Center(child: Text('Yüklenemedi: $_error'))
                : ListView(
                    padding: const EdgeInsets.fromLTRB(20, 20, 20, 30),
                    children: [
                      _profileHeader(context),
                      const SizedBox(height: 20),
                      _sectionTitle('Hesap Yönetimi'),
                      _group(
                        children: [
                          _navTile(
                            icon: Icons.person_outline,
                            title: 'Kişisel Bilgiler & Konum',
                            onTap: () => Navigator.of(context).push(
                              CupertinoPageRoute(
                                builder: (_) => PersonalInfoScreen(
                                  user: _user,
                                  repository: _repository,
                                ),
                              ),
                            ),
                          ),
                          _navTile(
                            icon: Icons.lock_outline,
                            title: 'Güvenlik ve Giriş',
                            onTap: () => Navigator.of(context).push(
                              CupertinoPageRoute(builder: (_) => const SecurityScreen()),
                            ),
                          ),
                        ],
                      ),
                      _sectionTitle('Uygulama Tercihleri'),
                      _group(
                        children: [
                          _navTile(
                            icon: Icons.notifications_none,
                            title: 'Bildirim Ayarları',
                            onTap: () => Navigator.of(context).push(
                              CupertinoPageRoute(
                                builder: (_) => NotificationSettingsScreen(
                                  user: _user,
                                  repository: _repository,
                                ),
                              ),
                            ),
                          ),
                          SwitchListTile.adaptive(
                            value: _darkMode,
                            onChanged: (value) => setState(() => _darkMode = value),
                            title: const Text('Karanlık Tema'),
                            activeColor: sienna,
                          ),
                        ],
                      ),
                      _sectionTitle('Diğer'),
                      _group(
                        children: [
                          _navTile(
                            icon: Icons.info_outline,
                            title: 'Hakkında ve Destek',
                            onTap: () => Navigator.of(context).push(
                              CupertinoPageRoute(builder: (_) => const AboutSettingsScreen()),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
      ),
    );
  }

  Widget _sectionTitle(String text) {
    return Padding(
      padding: const EdgeInsets.only(left: 12, bottom: 8, top: 8),
      child: Text(
        text,
        style: const TextStyle(
          color: Color(0xFF8E8A86),
          fontSize: 13,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _group({required List<Widget> children}) {
    return Container(
      decoration: BoxDecoration(
        color: card,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(children: children),
    );
  }

  Widget _navTile({required IconData icon, required String title, required VoidCallback onTap}) {
    return ListTile(
      leading: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: sienna.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(icon, color: sienna, size: 20),
      ),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
      trailing: const Icon(Icons.chevron_right),
      onTap: onTap,
    );
  }

  Widget _profileHeader(BuildContext context) {
    final firstName = _user?.firstName?.trim().isNotEmpty == true ? _user!.firstName! : 'Ad';
    final lastName = _user?.lastName?.trim().isNotEmpty == true ? _user!.lastName! : 'Soyad';
    final initials = '${firstName.isNotEmpty ? firstName[0] : 'A'}${lastName.isNotEmpty ? lastName[0] : 'B'}'.toUpperCase();
    final location = [
      if ((_user?.city ?? '').isNotEmpty) _user!.city!,
      if ((_user?.district ?? '').isNotEmpty) _user!.district!,
    ].join(', ');

    return InkWell(
      borderRadius: BorderRadius.circular(20),
      onTap: () => Navigator.of(context).push(
        CupertinoPageRoute(
          builder: (_) => PersonalInfoScreen(
            user: _user,
            repository: _repository,
          ),
        ),
      ),
      child: Container(
        decoration: BoxDecoration(
          color: card,
          borderRadius: BorderRadius.circular(20),
        ),
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              width: 68,
              height: 68,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(22),
                color: sienna.withOpacity(0.1),
              ),
              alignment: Alignment.center,
              child: Text(
                initials,
                style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w700, color: sienna),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '$firstName $lastName',
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 4),
                  Text(location.isEmpty ? 'Konum bilgisi eksik' : location),
                ],
              ),
            ),
            const Icon(Icons.chevron_right),
          ],
        ),
      ),
    );
  }
}

class PersonalInfoScreen extends StatefulWidget {
  const PersonalInfoScreen({
    super.key,
    required this.user,
    required this.repository,
  });

  final UserModel? user;
  final UserSettingsRepository repository;

  @override
  State<PersonalInfoScreen> createState() => _PersonalInfoScreenState();
}

class _PersonalInfoScreenState extends State<PersonalInfoScreen> {
  static const sienna = Color(0xFF8B4D22);
  static const card = Color(0xFFFFFFFF);

  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _surnameController;
  bool _saving = false;

  final Map<String, Map<String, List<String>>> _locations = {
    'İstanbul': {
      'Kadıköy': ['Caferağa Mah.', 'Osmanağa Mah.', 'Cumhuriyet Mah.'],
      'Beşiktaş': ['Levent Mah.', 'Etiler Mah.'],
    },
    'Ankara': {
      'Çankaya': ['Kızılay Mah.', 'Bahçelievler Mah.'],
    },
  };

  late String _selectedCity;
  late String _selectedDistrict;
  late String _selectedNeighborhood;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.user?.firstName ?? 'Adem');
    _surnameController = TextEditingController(text: widget.user?.lastName ?? 'Bayram');

    _selectedCity = widget.user?.city ?? _locations.keys.first;
    final districts = _locations[_selectedCity] ?? <String, List<String>>{};
    _selectedDistrict = widget.user?.district ?? districts.keys.first;
    final neighborhoods = districts[_selectedDistrict] ?? <String>[];
    _selectedNeighborhood = widget.user?.neighborhood ?? neighborhoods.first;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _surnameController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _saving = true);
    try {
      await widget.repository.savePersonalInfo(
        firstName: _nameController.text.trim(),
        lastName: _surnameController.text.trim(),
        city: _selectedCity,
        district: _selectedDistrict,
        neighborhood: _selectedNeighborhood,
      );
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Bilgiler kaydedildi.')));
      Navigator.of(context).pop();
    } catch (error) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Kaydetme hatası: $error')));
    } finally {
      if (mounted) {
        setState(() => _saving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F3F0),
      appBar: AppBar(
        title: const Text('Kişisel Bilgiler'),
        centerTitle: true,
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(color: card, borderRadius: BorderRadius.circular(20)),
              child: Column(
                children: [
                  TextFormField(
                    controller: _nameController,
                    decoration: const InputDecoration(labelText: 'Ad'),
                    validator: (value) => (value == null || value.trim().isEmpty) ? 'Ad gerekli' : null,
                  ),
                  TextFormField(
                    controller: _surnameController,
                    decoration: const InputDecoration(labelText: 'Soyad'),
                    validator: (value) => (value == null || value.trim().isEmpty) ? 'Soyad gerekli' : null,
                  ),
                  DropdownButtonFormField<String>(
                    initialValue: _selectedCity,
                    decoration: const InputDecoration(labelText: 'İl'),
                    items: _locations.keys.map((city) => DropdownMenuItem(value: city, child: Text(city))).toList(),
                    onChanged: (value) {
                      if (value == null) {
                        return;
                      }
                      setState(() {
                        _selectedCity = value;
                        _selectedDistrict = _locations[value]!.keys.first;
                        _selectedNeighborhood = _locations[value]![_selectedDistrict]!.first;
                      });
                    },
                  ),
                  DropdownButtonFormField<String>(
                    initialValue: _selectedDistrict,
                    decoration: const InputDecoration(labelText: 'İlçe'),
                    items: _locations[_selectedCity]!.keys.map((district) => DropdownMenuItem(value: district, child: Text(district))).toList(),
                    onChanged: (value) {
                      if (value == null) {
                        return;
                      }
                      setState(() {
                        _selectedDistrict = value;
                        _selectedNeighborhood = _locations[_selectedCity]![_selectedDistrict]!.first;
                      });
                    },
                  ),
                  DropdownButtonFormField<String>(
                    initialValue: _selectedNeighborhood,
                    decoration: const InputDecoration(labelText: 'Mahalle'),
                    items: _locations[_selectedCity]![_selectedDistrict]!
                        .map((neighborhood) => DropdownMenuItem(value: neighborhood, child: Text(neighborhood)))
                        .toList(),
                    onChanged: (value) {
                      if (value == null) {
                        return;
                      }
                      setState(() => _selectedNeighborhood = value);
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _saving ? null : _save,
              style: ElevatedButton.styleFrom(
                backgroundColor: sienna,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: _saving
                  ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                  : const Text('Kaydet'),
            ),
          ],
        ),
      ),
    );
  }
}

class NotificationSettingsScreen extends StatefulWidget {
  const NotificationSettingsScreen({
    super.key,
    required this.user,
    required this.repository,
  });

  final UserModel? user;
  final UserSettingsRepository repository;

  @override
  State<NotificationSettingsScreen> createState() => _NotificationSettingsScreenState();
}

class _NotificationSettingsScreenState extends State<NotificationSettingsScreen> {
  bool _alarm = true;
  bool _campaign = true;
  bool _badge = false;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _alarm = widget.user?.alarmNotifications ?? true;
    _campaign = widget.user?.campaignNotifications ?? true;
    _badge = widget.user?.badgeNotifications ?? false;
  }

  Future<void> _persist({bool? alarm, bool? campaign, bool? badge}) async {
    setState(() => _saving = true);
    try {
      await widget.repository.updateNotificationPreference(
        alarm: alarm,
        campaign: campaign,
        badge: badge,
      );
    } catch (error) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Bildirim kaydı hatası: $error')));
    } finally {
      if (mounted) {
        setState(() => _saving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F3F0),
      appBar: AppBar(title: const Text('Bildirimler'), centerTitle: true),
      body: Stack(
        children: [
          ListView(
            padding: const EdgeInsets.all(20),
            children: [
              Container(
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20)),
                child: Column(
                  children: [
                    CupertinoSwitchListTile(
                      title: const Text('Fiyat Alarmı Bildirimleri'),
                      subtitle: const Text('Takip ettiğin ürün düştüğünde uyar.'),
                      value: _alarm,
                      onChanged: (value) {
                        setState(() => _alarm = value);
                        _persist(alarm: value);
                      },
                    ),
                    CupertinoSwitchListTile(
                      title: const Text('Kampanya Bildirimleri'),
                      subtitle: const Text('Haftalık indirimleri bildirir.'),
                      value: _campaign,
                      onChanged: (value) {
                        setState(() => _campaign = value);
                        _persist(campaign: value);
                      },
                    ),
                    CupertinoSwitchListTile(
                      title: const Text('Rozet ve Puan Bildirimleri'),
                      subtitle: const Text('Liderlik tablosu değişimlerini bildirir.'),
                      value: _badge,
                      onChanged: (value) {
                        setState(() => _badge = value);
                        _persist(badge: value);
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (_saving)
            const Positioned(
              top: 12,
              right: 12,
              child: SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2)),
            ),
        ],
      ),
    );
  }
}

class SecurityScreen extends StatelessWidget {
  const SecurityScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F3F0),
      appBar: AppBar(title: const Text('Güvenlik ve Giriş'), centerTitle: true),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Container(
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20)),
            child: const Column(
              children: [
                ListTile(title: Text('Mevcut E-Posta'), subtitle: Text('auth üzerinden yönetilir')),
                ListTile(title: Text('Yeni E-Posta Adresi'), subtitle: Text('Yakında')),
                ListTile(title: Text('Şifre Değiştir'), subtitle: Text('Yakında')),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class AboutSettingsScreen extends StatelessWidget {
  const AboutSettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F3F0),
      appBar: AppBar(title: const Text('Hakkında'), centerTitle: true),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20)),
            child: const Column(
              children: [
                Icon(Icons.radar, size: 48),
                SizedBox(height: 10),
                Text('FiyatRadar', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700)),
                SizedBox(height: 4),
                Text('Sürüm 3.0.0'),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class CupertinoSwitchListTile extends StatelessWidget {
  const CupertinoSwitchListTile({
    super.key,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  final Widget title;
  final Widget subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: title,
      subtitle: subtitle,
      trailing: CupertinoSwitch(value: value, onChanged: onChanged),
      onTap: () => onChanged(!value),
    );
  }
}
