import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../providers/auth_provider.dart';
import '../../providers/firebase_init_provider.dart';
import '../../utils/cities_tr.dart';


class DistrictTR {
  const DistrictTR({required this.name, required this.neighborhoods});

  final String name;
  final List<String> neighborhoods;
}

const Map<String, List<DistrictTR>> kDistrictsByCityCode = {
  '34': [
    DistrictTR(name: 'Kadıköy', neighborhoods: ['Caferağa', 'Fenerbahçe', 'Kozyatağı']),
    DistrictTR(name: 'Beşiktaş', neighborhoods: ['Levent', 'Etiler', 'Ortaköy']),
    DistrictTR(name: 'Üsküdar', neighborhoods: ['Acıbadem', 'Altunizade', 'Çengelköy']),
  ],
  '06': [
    DistrictTR(name: 'Çankaya', neighborhoods: ['Bahçelievler', 'Kızılay', 'Ayrancı']),
    DistrictTR(name: 'Keçiören', neighborhoods: ['Etlik', 'Aktepe', 'Kalaba']),
    DistrictTR(name: 'Yenimahalle', neighborhoods: ['Batıkent', 'Demetevler', 'Şentepe']),
  ],
  '35': [
    DistrictTR(name: 'Konak', neighborhoods: ['Alsancak', 'Güzelyalı', 'Mimar Sinan']),
    DistrictTR(name: 'Karşıyaka', neighborhoods: ['Bostanlı', 'Mavişehir', 'Alaybey']),
    DistrictTR(name: 'Bornova', neighborhoods: ['Kazımdirik', 'Evka-3', 'Atatürk']),
  ],
};

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _inviteController = TextEditingController();

  bool _isLoading = false;
  bool _isGoogleLoading = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  String? _errorMessage;

  CityTR? _selectedCity;
  String? _selectedDistrict;
  String? _selectedNeighborhood;

  List<DistrictTR> get _availableDistricts {
    final cityCode = _selectedCity?.code;
    if (cityCode == null) return const [];
    return kDistrictsByCityCode[cityCode] ?? const [];
  }

  List<String> get _availableNeighborhoods {
    final districtName = _selectedDistrict;
    if (districtName == null) return const [];
    for (final district in _availableDistricts) {
      if (district.name == districtName) return district.neighborhoods;
    }
    return const [];
  }


  static const _bg = Color(0xFFFAF6F0);
  static const _title = Color(0xFF4A2E1B);
  static const _subtitle = Color(0xFF8C6A53);
  static const _placeholder = Color(0xFFB59A86);
  static const _iconSoft = Color(0xFFA38671);
  static const _iconStrong = Color(0xFF6B4226);
  static const _border = Color(0x1AA66632);

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _inviteController.dispose();
    super.dispose();
  }

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    if (!ref.read(firebaseInitializedProvider)) {
      setState(() {
        _isLoading = false;
        _errorMessage =
            'Firebase bağlantısı kurulamadı. Lütfen internet bağlantınızı kontrol edin.';
      });
      return;
    }

    if (_selectedCity == null) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Lütfen şehir seçin.';
      });
      return;
    }

    try {
      await ref.read(authServiceProvider).registerWithEmailAndPassword(
            email: _emailController.text.trim(),
            password: _passwordController.text,
            name: _nameController.text.trim(),
            inviteCode: _inviteController.text.trim(),
            cityCode: _selectedCity?.code,
            cityName: _selectedCity?.name,
          );

      if (!mounted) return;
      context.go('/main');
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _errorMessage = ref.read(authServiceProvider).getErrorMessage(e);
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _errorMessage = 'Kayıt oluşturulamadı: $e';
      });
    }
  }

  Future<void> _signInWithGoogle() async {
    if (!ref.read(firebaseInitializedProvider)) {
      setState(() {
        _errorMessage =
            'Firebase bağlantısı kurulamadı. Lütfen internet bağlantınızı kontrol edin.';
      });
      return;
    }

    setState(() {
      _isGoogleLoading = true;
      _errorMessage = null;
    });

    try {
      final user = await ref.read(authServiceProvider).signInWithGoogle();

      if (user != null && mounted) {
        context.go('/main');
      } else if (mounted) {
        setState(() => _isGoogleLoading = false);
      }
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;
      setState(() {
        _isGoogleLoading = false;
        _errorMessage = ref.read(authServiceProvider).getErrorMessage(e);
      });
    } catch (e) {
      if (!mounted) return;
      String errorMessage = 'Google ile kayıt oluşturulamadı.';
      if (e.toString().contains('ApiException: 10')) {
        errorMessage =
            'Google giriş yapılandırması eksik. Firebase Console\'dan SHA-1 parmak izi ekleyin.';
      }
      setState(() {
        _isGoogleLoading = false;
        _errorMessage = errorMessage;
      });
    }
  }

  InputDecoration _inputDecoration({
    required IconData icon,
    required String hint,
    Widget? suffix,
  }) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(
        fontFamily: 'Outfit',
        color: _placeholder,
        fontWeight: FontWeight.w400,
      ),
      prefixIcon: Icon(icon, color: _iconSoft, size: 22),
      suffixIcon: suffix,
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: _border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: _iconStrong),
      ),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: _border),
      ),
    );
  }

  Widget _buildFieldShadow({required Widget child}) {
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(
            color: Color(0x146B4226),
            blurRadius: 12,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: child,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      resizeToAvoidBottomInset: true,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 10),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  InkWell(
                    onTap: () {
                      if (context.canPop()) {
                        context.pop();
                      } else {
                        context.go('/login');
                      }
                    },
                    borderRadius: BorderRadius.circular(20),
                    child: const SizedBox(
                      width: 24,
                      height: 24,
                      child: Icon(Icons.arrow_back_ios_new, color: _iconStrong, size: 20),
                    ),
                  ),
                  const Text(
                    'Hesap Oluştur',
                    style: TextStyle(
                      fontFamily: 'Outfit',
                      fontWeight: FontWeight.w700,
                      fontSize: 18,
                      color: _title,
                    ),
                  ),
                  const SizedBox(width: 24, height: 24),
                ],
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(24, 10, 24, 30),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const Text(
                        "FiyatRadar'a Katıl",
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontFamily: 'Outfit',
                          fontWeight: FontWeight.w700,
                          fontSize: 24,
                          letterSpacing: -0.5,
                          color: _title,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Fiyat takibi yap, toplulukla paylaş ve premium puanları topla!',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontFamily: 'Outfit',
                          color: _subtitle,
                          fontSize: 14,
                          height: 1.5,
                        ),
                      ),
                      const SizedBox(height: 24),
                      _buildGoogleButton(),
                      const SizedBox(height: 24),
                      Row(
                        children: const [
                          Expanded(
                            child: Divider(
                              color: Color(0x26A66632),
                              thickness: 1,
                            ),
                          ),
                          Padding(
                            padding: EdgeInsets.symmetric(horizontal: 16),
                            child: Text(
                              'veya e-posta ile',
                              style: TextStyle(
                                fontFamily: 'Outfit',
                                color: _placeholder,
                                fontSize: 13,
                              ),
                            ),
                          ),
                          Expanded(
                            child: Divider(
                              color: Color(0x26A66632),
                              thickness: 1,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      if (_errorMessage != null) ...[
                        Container(
                          padding: const EdgeInsets.all(12),
                          margin: const EdgeInsets.only(bottom: 12),
                          decoration: BoxDecoration(
                            color: Colors.red.withOpacity(0.08),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.red.withOpacity(0.35)),
                          ),
                          child: Text(
                            _errorMessage!,
                            style: const TextStyle(
                              fontFamily: 'Outfit',
                              fontSize: 13,
                              color: _title,
                            ),
                          ),
                        ),
                      ],
                      _buildFieldShadow(
                        child: TextFormField(
                          controller: _nameController,
                          textInputAction: TextInputAction.next,
                          decoration: _inputDecoration(
                            icon: Icons.person,
                            hint: 'Ad Soyad',
                          ),
                          style: const TextStyle(
                            fontFamily: 'Outfit',
                            color: _title,
                            fontSize: 15,
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) return 'Ad soyad gerekli';
                            if (value.length < 2) return 'Geçerli bir isim girin';
                            return null;
                          },
                        ),
                      ),
                      const SizedBox(height: 16),
                      _buildFieldShadow(
                        child: TextFormField(
                          controller: _inviteController,
                          textInputAction: TextInputAction.next,
                          decoration: _inputDecoration(
                            icon: Icons.group_add,
                            hint: 'Davet Kodu (Opsiyonel)',
                          ),
                          style: const TextStyle(
                            fontFamily: 'Outfit',
                            color: _title,
                            fontSize: 15,
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      _buildFieldShadow(
                        child: DropdownButtonFormField<CityTR>(
                          value: _selectedCity,
                          isExpanded: true,
                          icon: const Icon(Icons.keyboard_arrow_down, color: _iconSoft),
                          borderRadius: BorderRadius.circular(16),
                          decoration: _inputDecoration(
                            icon: Icons.location_city,
                            hint: 'Şehir Seçiniz',
                          ),
                          style: const TextStyle(
                            fontFamily: 'Outfit',
                            color: _title,
                            fontSize: 15,
                          ),
                          hint: const Text(
                            'Şehir Seçiniz',
                            style: TextStyle(
                              fontFamily: 'Outfit',
                              color: _placeholder,
                            ),
                          ),
                          items: kCitiesTR
                              .map(
                                (city) => DropdownMenuItem<CityTR>(
                                  value: city,
                                  child: Text(
                                    city.name,
                                    style: const TextStyle(fontFamily: 'Outfit'),
                                  ),
                                ),
                              )
                              .toList(),
                          onChanged: (value) => setState(() {
                            _selectedCity = value;
                            _selectedDistrict = null;
                            _selectedNeighborhood = null;
                          }),
                          validator: (value) => value == null ? 'Lütfen şehir seçin.' : null,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: _buildFieldShadow(
                              child: DropdownButtonFormField<String>(
                                value: _selectedDistrict,
                                isExpanded: true,
                                icon: const Icon(Icons.keyboard_arrow_down, color: _iconSoft, size: 20),
                                borderRadius: BorderRadius.circular(16),
                                decoration: _inputDecoration(
                                  icon: Icons.map,
                                  hint: 'İlçe',
                                ),
                                hint: const Text(
                                  'İlçe',
                                  style: TextStyle(
                                    fontFamily: 'Outfit',
                                    color: _placeholder,
                                    fontSize: 14,
                                  ),
                                ),
                                style: const TextStyle(
                                  fontFamily: 'Outfit',
                                  color: _title,
                                  fontSize: 14,
                                ),
                                items: _availableDistricts
                                    .map((district) => DropdownMenuItem(value: district.name, child: Text(district.name)))
                                    .toList(),
                                onChanged: (value) => setState(() {
                                  _selectedDistrict = value;
                                  _selectedNeighborhood = null;
                                }),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _buildFieldShadow(
                              child: DropdownButtonFormField<String>(
                                value: _selectedNeighborhood,
                                isExpanded: true,
                                icon: const Icon(Icons.keyboard_arrow_down, color: _iconSoft, size: 20),
                                borderRadius: BorderRadius.circular(16),
                                decoration: _inputDecoration(
                                  icon: Icons.holiday_village,
                                  hint: 'Mahalle',
                                ),
                                hint: const Text(
                                  'Mahalle',
                                  style: TextStyle(
                                    fontFamily: 'Outfit',
                                    color: _placeholder,
                                    fontSize: 14,
                                  ),
                                ),
                                style: const TextStyle(
                                  fontFamily: 'Outfit',
                                  color: _title,
                                  fontSize: 14,
                                ),
                                items: _availableNeighborhoods
                                    .map((neighborhood) => DropdownMenuItem(value: neighborhood, child: Text(neighborhood)))
                                    .toList(),
                                onChanged: (value) => setState(() => _selectedNeighborhood = value),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      _buildFieldShadow(
                        child: TextFormField(
                          controller: _emailController,
                          keyboardType: TextInputType.emailAddress,
                          textInputAction: TextInputAction.next,
                          decoration: _inputDecoration(
                            icon: Icons.mail,
                            hint: 'E-posta adresin',
                          ),
                          style: const TextStyle(
                            fontFamily: 'Outfit',
                            color: _title,
                            fontSize: 15,
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) return 'E-posta adresi gerekli';
                            if (!value.contains('@') || !value.contains('.')) {
                              return 'Geçerli bir e-posta adresi girin';
                            }
                            return null;
                          },
                        ),
                      ),
                      const SizedBox(height: 16),
                      _buildFieldShadow(
                        child: TextFormField(
                          controller: _passwordController,
                          obscureText: _obscurePassword,
                          textInputAction: TextInputAction.next,
                          decoration: _inputDecoration(
                            icon: Icons.lock,
                            hint: 'Şifre',
                            suffix: IconButton(
                              onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                              icon: Icon(
                                _obscurePassword ? Icons.visibility_off : Icons.visibility,
                                color: _iconSoft,
                              ),
                            ),
                          ),
                          style: const TextStyle(
                            fontFamily: 'Outfit',
                            color: _title,
                            fontSize: 15,
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) return 'Şifre gerekli';
                            if (value.length < 6) return 'Şifre en az 6 karakter olmalı';
                            return null;
                          },
                        ),
                      ),
                      const SizedBox(height: 16),
                      _buildFieldShadow(
                        child: TextFormField(
                          controller: _confirmPasswordController,
                          obscureText: _obscureConfirmPassword,
                          textInputAction: TextInputAction.done,
                          onFieldSubmitted: (_) => _register(),
                          decoration: _inputDecoration(
                            icon: Icons.lock_reset,
                            hint: 'Şifre Tekrar',
                            suffix: IconButton(
                              onPressed: () =>
                                  setState(() => _obscureConfirmPassword = !_obscureConfirmPassword),
                              icon: Icon(
                                _obscureConfirmPassword ? Icons.visibility_off : Icons.visibility,
                                color: _iconSoft,
                              ),
                            ),
                          ),
                          style: const TextStyle(
                            fontFamily: 'Outfit',
                            color: _title,
                            fontSize: 15,
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) return 'Şifre tekrarı gerekli';
                            if (value != _passwordController.text) return 'Şifreler eşleşmiyor';
                            return null;
                          },
                        ),
                      ),
                      const SizedBox(height: 24),
                      SizedBox(
                        height: 56,
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(16),
                            gradient: const LinearGradient(
                              colors: [Color(0xFF8C5938), Color(0xFF4A2E1B)],
                            ),
                            boxShadow: const [
                              BoxShadow(
                                color: Color(0x336B4226),
                                blurRadius: 25,
                                offset: Offset(0, 10),
                              ),
                            ],
                          ),
                          child: ElevatedButton(
                            onPressed: _isLoading ? null : _register,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.transparent,
                              shadowColor: Colors.transparent,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                            ),
                            child: _isLoading
                                ? const SizedBox(
                                    width: 22,
                                    height: 22,
                                    child: CircularProgressIndicator(
                                      color: Colors.white,
                                      strokeWidth: 2.4,
                                    ),
                                  )
                                : const Text(
                                    'Kayıt Ol',
                                    style: TextStyle(
                                      fontFamily: 'Outfit',
                                      color: Colors.white,
                                      fontWeight: FontWeight.w700,
                                      fontSize: 16,
                                    ),
                                  ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      Text.rich(
                        TextSpan(
                          text: 'Zaten hesabın var mı? ',
                          style: const TextStyle(
                            fontFamily: 'Outfit',
                            color: _subtitle,
                            fontSize: 14.5,
                          ),
                          children: [
                            WidgetSpan(
                              child: GestureDetector(
                                onTap: () => context.go('/login'),
                                child: const Text(
                                  'Giriş Yap',
                                  style: TextStyle(
                                    fontFamily: 'Outfit',
                                    color: _iconStrong,
                                    fontWeight: FontWeight.w700,
                                    fontSize: 14.5,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        "Kayıt olarak Kullanım Koşulları ve Gizlilik Politikası'nı kabul etmiş olursunuz.",
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontFamily: 'Outfit',
                          color: _placeholder,
                          fontSize: 12,
                          height: 1.6,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGoogleButton() {
    return SizedBox(
      height: 56,
      child: OutlinedButton(
        onPressed: _isGoogleLoading ? null : _signInWithGoogle,
        style: OutlinedButton.styleFrom(
          backgroundColor: Colors.white,
          side: const BorderSide(color: Color(0x26A66632)),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        child: _isGoogleLoading
            ? const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  color: _iconStrong,
                ),
              )
            : const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.g_mobiledata, size: 24, color: Color(0xFFDB4437)),
                  SizedBox(width: 12),
                  Text(
                    'Google ile Kayıt Ol',
                    style: TextStyle(
                      fontFamily: 'Outfit',
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: _title,
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}
