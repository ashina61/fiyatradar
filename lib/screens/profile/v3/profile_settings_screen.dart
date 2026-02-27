import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import 'profile_service.dart';
import 'user_model.dart';

class ProfileSettingsScreen extends StatefulWidget {
  const ProfileSettingsScreen({super.key});

  @override
  State<ProfileSettingsScreen> createState() => _ProfileSettingsScreenState();
}

class _ProfileSettingsScreenState extends State<ProfileSettingsScreen> {
  static const Color _background = Color(0xFFF5F3F0);
  static const Color _card = Color(0xFFFFFFFF);
  static const Color _sienna = Color(0xFF8B4D22);

  final ProfileService _service = ProfileService();

  bool _loading = true;
  String? _error;
  UserModel? _user;

  @override
  void initState() {
    super.initState();
    _fetchUser();
  }

  Future<void> _fetchUser() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final user = await _service.getUserProfile();
      if (!mounted) {
        return;
      }
      setState(() => _user = user);
    } catch (e) {
      if (!mounted) {
        return;
      }
      setState(() => _error = e.toString());
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  Future<void> _openProfileForm() async {
    final user = _user;
    if (user == null) {
      return;
    }

    final updated = await Navigator.of(context).push<UserModel>(
      CupertinoPageRoute(
        builder: (_) => ProfileFormScreen(
          initialUser: user,
          service: _service,
        ),
      ),
    );

    if (updated != null && mounted) {
      setState(() => _user = updated);
    }
  }

  Future<void> _openNotificationForm() async {
    final user = _user;
    if (user == null) {
      return;
    }

    final updated = await Navigator.of(context).push<UserModel>(
      CupertinoPageRoute(
        builder: (_) => NotificationSettingsFormScreen(
          initialUser: user,
          service: _service,
        ),
      ),
    );

    if (updated != null && mounted) {
      setState(() => _user = updated);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _background,
      appBar: AppBar(
        centerTitle: true,
        backgroundColor: _background,
        title: const Text('Hesap & Ayarlar'),
      ),
      body: _loading
          ? const Center(
              child: CircularProgressIndicator(
                color: _sienna,
              ),
            )
          : _error != null
              ? Center(child: Text('Bir hata oluştu: $_error'))
              : ListView(
                  padding: const EdgeInsets.all(20),
                  children: [
                    _cardButton(
                      title: 'Kişisel Bilgiler & Konum',
                      subtitle: 'Ad, soyad, kullanıcı adı ve konum bilgilerini düzenle.',
                      onTap: _openProfileForm,
                    ),
                    const SizedBox(height: 12),
                    _cardButton(
                      title: 'Bildirim Ayarları',
                      subtitle: 'Alarm, kampanya ve rozet bildirimlerini yönet.',
                      onTap: _openNotificationForm,
                    ),
                  ],
                ),
    );
  }

  Widget _cardButton({
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: _card,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 15,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      color: Color(0xFF8E8A86),
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: _sienna),
          ],
        ),
      ),
    );
  }
}

class ProfileFormScreen extends StatefulWidget {
  const ProfileFormScreen({
    super.key,
    required this.initialUser,
    required this.service,
  });

  final UserModel initialUser;
  final ProfileService service;

  @override
  State<ProfileFormScreen> createState() => _ProfileFormScreenState();
}

class _ProfileFormScreenState extends State<ProfileFormScreen> {
  static const Color _background = Color(0xFFF5F3F0);
  static const Color _card = Color(0xFFFFFFFF);
  static const Color _sienna = Color(0xFF8B4D22);

  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _nameController;
  late final TextEditingController _surnameController;
  late final TextEditingController _usernameController;

  late String _city;
  late String _district;
  late String _neighborhood;

  bool _saving = false;

  final Map<String, Map<String, List<String>>> _locations = {
    'İstanbul': {
      'Kadıköy': ['Cumhuriyet Mah.', 'Caferağa Mah.', 'Osmanağa Mah.'],
      'Beşiktaş': ['Levent Mah.', 'Etiler Mah.'],
      'Üsküdar': ['Altunizade Mah.', 'Kuzguncuk Mah.'],
    },
    'Ankara': {
      'Çankaya': ['Kızılay Mah.', 'Bahçelievler Mah.'],
      'Yenimahalle': ['Demetevler Mah.', 'Batıkent Mah.'],
    },
    'İzmir': {
      'Konak': ['Alsancak Mah.', 'Güzelyalı Mah.'],
      'Karşıyaka': ['Bostanlı Mah.', 'Mavişehir Mah.'],
    },
  };

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.initialUser.name);
    _surnameController = TextEditingController(text: widget.initialUser.surname);
    _usernameController = TextEditingController(text: widget.initialUser.username);

    _city = _locations.containsKey(widget.initialUser.city) ? widget.initialUser.city : _locations.keys.first;
    final districts = _locations[_city]!.keys.toList();
    _district = districts.contains(widget.initialUser.district) ? widget.initialUser.district : districts.first;

    final neighborhoods = _locations[_city]![_district]!;
    _neighborhood = neighborhoods.contains(widget.initialUser.neighborhood)
        ? widget.initialUser.neighborhood
        : neighborhoods.first;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _surnameController.dispose();
    _usernameController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final newUser = widget.initialUser.copyWith(
      name: _nameController.text.trim(),
      surname: _surnameController.text.trim(),
      username: _usernameController.text.trim(),
      city: _city,
      district: _district,
      neighborhood: _neighborhood,
    );

    setState(() => _saving = true);

    try {
      await widget.service.updateUserProfile(newUser);
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Profil bilgileri güncellendi.'),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.of(context).pop(newUser);
    } catch (e) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Güncelleme sırasında hata oluştu: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _saving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final districts = _locations[_city]!.keys.toList();
    final neighborhoods = _locations[_city]![_district]!;

    return AbsorbPointer(
      absorbing: _saving,
      child: Scaffold(
        backgroundColor: _background,
        appBar: AppBar(
          centerTitle: true,
          title: const Text('Kişisel Bilgiler'),
          backgroundColor: _background,
        ),
        body: Stack(
          children: [
            Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.all(20),
                children: [
                  Container(
                    decoration: BoxDecoration(
                      color: _card,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Column(
                      children: [
                        _buildInput(
                          controller: _nameController,
                          label: 'Ad',
                        ),
                        const Divider(height: 1, color: Color(0x148B4D22), indent: 20),
                        _buildInput(
                          controller: _surnameController,
                          label: 'Soyad',
                        ),
                        const Divider(height: 1, color: Color(0x148B4D22), indent: 20),
                        _buildInput(
                          controller: _usernameController,
                          label: 'Kullanıcı Adı',
                        ),
                        const Divider(height: 1, color: Color(0x148B4D22), indent: 20),
                        _buildDropdown(
                          label: 'İl',
                          value: _city,
                          items: _locations.keys.toList(),
                          onChanged: (value) {
                            setState(() {
                              _city = value;
                              _district = _locations[_city]!.keys.first;
                              _neighborhood = _locations[_city]![_district]!.first;
                            });
                          },
                        ),
                        const Divider(height: 1, color: Color(0x148B4D22), indent: 20),
                        _buildDropdown(
                          label: 'İlçe',
                          value: _district,
                          items: districts,
                          onChanged: (value) {
                            setState(() {
                              _district = value;
                              _neighborhood = _locations[_city]![_district]!.first;
                            });
                          },
                        ),
                        const Divider(height: 1, color: Color(0x148B4D22), indent: 20),
                        _buildDropdown(
                          label: 'Mahalle',
                          value: _neighborhood,
                          items: neighborhoods,
                          onChanged: (value) => setState(() => _neighborhood = value),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    height: 52,
                    child: ElevatedButton(
                      onPressed: _saving ? null : _save,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _sienna,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: _saving
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Text('Değişiklikleri Kaydet'),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInput({
    required TextEditingController controller,
    required String label,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: TextFormField(
        controller: controller,
        decoration: InputDecoration(
          border: InputBorder.none,
          labelText: label,
          labelStyle: const TextStyle(color: _sienna),
        ),
        validator: (value) => (value == null || value.trim().isEmpty) ? '$label boş bırakılamaz' : null,
      ),
    );
  }

  Widget _buildDropdown({
    required String label,
    required String value,
    required List<String> items,
    required ValueChanged<String> onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: DropdownButtonFormField<String>(
        value: value,
        decoration: InputDecoration(
          border: InputBorder.none,
          labelText: label,
          labelStyle: const TextStyle(color: _sienna),
        ),
        items: items
            .map((item) => DropdownMenuItem<String>(
                  value: item,
                  child: Text(item),
                ))
            .toList(),
        onChanged: (selected) {
          if (selected != null) {
            onChanged(selected);
          }
        },
      ),
    );
  }
}

class NotificationSettingsFormScreen extends StatefulWidget {
  const NotificationSettingsFormScreen({
    super.key,
    required this.initialUser,
    required this.service,
  });

  final UserModel initialUser;
  final ProfileService service;

  @override
  State<NotificationSettingsFormScreen> createState() => _NotificationSettingsFormScreenState();
}

class _NotificationSettingsFormScreenState extends State<NotificationSettingsFormScreen> {
  static const Color _background = Color(0xFFF5F3F0);
  static const Color _card = Color(0xFFFFFFFF);
  static const Color _sienna = Color(0xFF8B4D22);

  late bool _priceAlarm;
  late bool _campaignNotification;
  late bool _badgeNotification;

  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _priceAlarm = widget.initialUser.priceAlarm;
    _campaignNotification = widget.initialUser.campaignNotification;
    _badgeNotification = widget.initialUser.badgeNotification;
  }

  Future<void> _save() async {
    final updated = widget.initialUser.copyWith(
      priceAlarm: _priceAlarm,
      campaignNotification: _campaignNotification,
      badgeNotification: _badgeNotification,
    );

    setState(() => _saving = true);

    try {
      await widget.service.updateUserProfile(updated);
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Bildirim tercihleri güncellendi.'),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.of(context).pop(updated);
    } catch (e) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Güncelleme sırasında hata oluştu: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _saving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AbsorbPointer(
      absorbing: _saving,
      child: Scaffold(
        backgroundColor: _background,
        appBar: AppBar(
          centerTitle: true,
          title: const Text('Bildirimler'),
          backgroundColor: _background,
        ),
        body: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Container(
              decoration: BoxDecoration(
                color: _card,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                children: [
                  _switchRow(
                    title: 'Fiyat Alarmı Bildirimleri',
                    subtitle: 'Takip ettiğin ürün düştüğünde uyar.',
                    value: _priceAlarm,
                    onChanged: (value) => setState(() => _priceAlarm = value),
                  ),
                  const Divider(height: 1, color: Color(0x148B4D22), indent: 20),
                  _switchRow(
                    title: 'Kampanya Bildirimleri',
                    subtitle: 'A101, BİM vb. haftalık indirimleri.',
                    value: _campaignNotification,
                    onChanged: (value) => setState(() => _campaignNotification = value),
                  ),
                  const Divider(height: 1, color: Color(0x148B4D22), indent: 20),
                  _switchRow(
                    title: 'Rozet ve Puan Bildirimleri',
                    subtitle: 'Liderlik tablosunda yükseldiğinde uyar.',
                    value: _badgeNotification,
                    onChanged: (value) => setState(() => _badgeNotification = value),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 52,
              child: ElevatedButton(
                onPressed: _saving ? null : _save,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _sienna,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: _saving
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Text('Değişiklikleri Kaydet'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _switchRow({
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return ListTile(
      onTap: () => onChanged(!value),
      title: Text(
        title,
        style: const TextStyle(fontWeight: FontWeight.w600),
      ),
      subtitle: Text(
        subtitle,
        style: const TextStyle(fontSize: 13),
      ),
      trailing: CupertinoSwitch(
        value: value,
        activeColor: _sienna,
        onChanged: onChanged,
      ),
    );
  }
}

class FiyatRadarSettingsScreen extends ProfileSettingsScreen {
  const FiyatRadarSettingsScreen({super.key});
}
