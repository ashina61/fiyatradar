import 'package:flutter/material.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';

import '../../models/turkey_locations.dart';
import '../../ui/components.dart';
import '../../ui/tokens.dart';

/// Result of [showRegionPickerSheet].
class RegionSelection {
  final String city;
  final String district;
  const RegionSelection({required this.city, required this.district});
}

/// Opens a bottom sheet that lets the user pick a Turkish province and
/// district from the canonical [TurkeyLocations] whitelist. Free-text entry
/// is intentionally not supported so different spellings of the same city
/// can never reach Firestore.
Future<RegionSelection?> showRegionPickerSheet(
  BuildContext context, {
  String? initialCity,
  String? initialDistrict,
}) {
  return showModalBottomSheet<RegionSelection>(
    context: context,
    backgroundColor: FR.surface,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (_) => RegionPickerSheet(
      initialCity: initialCity,
      initialDistrict: initialDistrict,
    ),
  );
}

class RegionPickerSheet extends StatefulWidget {
  const RegionPickerSheet({
    super.key,
    this.initialCity,
    this.initialDistrict,
  });
  final String? initialCity;
  final String? initialDistrict;

  @override
  State<RegionPickerSheet> createState() => _RegionPickerSheetState();
}

class _RegionPickerSheetState extends State<RegionPickerSheet> {
  String? _city;
  String? _district;
  bool _locating = false;

  @override
  void initState() {
    super.initState();
    _city = TurkeyLocations.canonicalCity(widget.initialCity);
    if (_city != null) {
      _district =
          TurkeyLocations.canonicalDistrict(_city, widget.initialDistrict);
    }
  }

  Future<void> _useLocation() async {
    setState(() => _locating = true);
    try {
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.deniedForever ||
          permission == LocationPermission.denied) {
        _snack('Konum izni verilmedi. Listeden seçmeye devam edebilirsin.');
        return;
      }
      final pos = await Geolocator.getCurrentPosition();
      final marks =
          await placemarkFromCoordinates(pos.latitude, pos.longitude);
      final mark = marks.isNotEmpty ? marks.first : null;
      final cityRaw =
          (mark?.administrativeArea ?? mark?.locality ?? '').trim();
      final districtRaw =
          (mark?.subAdministrativeArea ?? mark?.subLocality ?? '').trim();
      final city = TurkeyLocations.canonicalCity(cityRaw);
      if (city == null) {
        _snack('Konum tanınamadı. Lütfen listeden seç.');
        return;
      }
      final district =
          TurkeyLocations.canonicalDistrict(city, districtRaw);
      if (!mounted) return;
      setState(() {
        _city = city;
        _district = district;
      });
      if (district == null) {
        _snack('Şehir bulundu: $city. Lütfen ilçeyi listeden seç.');
      }
    } catch (_) {
      _snack('Konum alınamadı.');
    } finally {
      if (mounted) setState(() => _locating = false);
    }
  }

  void _snack(String text) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(text)));
  }

  Future<void> _pickCity() async {
    final selected = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: FR.surface,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => _LocationListSheet(
        title: 'İl seç',
        items: TurkeyLocations.cities,
        selected: _city,
      ),
    );
    if (selected == null) return;
    setState(() {
      _city = selected;
      // District whitelist depends on city; clear if it's no longer valid.
      if (_district != null) {
        _district = TurkeyLocations.canonicalDistrict(selected, _district);
      }
    });
  }

  Future<void> _pickDistrict() async {
    final city = _city;
    if (city == null) return;
    final districts = TurkeyLocations.districtsOf(city);
    if (districts.isEmpty) {
      _snack('Bu il için ilçe listesi henüz tanımlı değil.');
      return;
    }
    final selected = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: FR.surface,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => _LocationListSheet(
        title: '$city · İlçe seç',
        items: districts,
        selected: _district,
      ),
    );
    if (selected == null) return;
    setState(() => _district = selected);
  }

  @override
  Widget build(BuildContext context) {
    final canSave = _city != null && _district != null;
    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 18,
        bottom: 20 + MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 38,
              height: 4,
              decoration: BoxDecoration(
                color: FR.hairline,
                borderRadius: FRRad.all(999),
              ),
            ),
          ),
          const SizedBox(height: 14),
          Text('BÖLGE', style: frOverline()),
          const SizedBox(height: 4),
          Text('Bölgeni seç', style: frDisplay(22, FontWeight.w700)),
          const SizedBox(height: 6),
          Text(
            'Yalnızca listedeki il ve ilçeleri seçebilirsin. '
            'Aynı yere birden fazla isim eklenmesin diye sabit liste kullanıyoruz.',
            style: frText(11.5, FontWeight.w600, color: FR.ink3, height: 1.4),
          ),
          const SizedBox(height: 14),
          FRCta(
            label: _locating ? 'Konum alınıyor…' : 'Konumumu kullan',
            icon: Icons.my_location_rounded,
            onTap: _locating ? null : _useLocation,
          ),
          const SizedBox(height: 16),
          Row(children: [
            Expanded(child: Divider(color: FR.hairline, height: 1)),
            const SizedBox(width: 8),
            Text('VEYA',
                style: frOverline(color: FR.ink3, size: 9.5)),
            const SizedBox(width: 8),
            Expanded(child: Divider(color: FR.hairline, height: 1)),
          ]),
          const SizedBox(height: 14),
          _PickerTile(
            label: 'İl',
            value: _city ?? 'Şehir seç',
            placeholder: _city == null,
            icon: Icons.location_city_outlined,
            onTap: _pickCity,
          ),
          const SizedBox(height: 10),
          _PickerTile(
            label: 'İlçe',
            value: _district ??
                (_city == null ? 'Önce il seç' : 'İlçe seç'),
            placeholder: _district == null,
            icon: Icons.map_outlined,
            onTap: _city == null ? null : _pickDistrict,
          ),
          const SizedBox(height: 14),
          FRCta(
            label: 'Kaydet',
            icon: Icons.check_rounded,
            filled: false,
            onTap: canSave
                ? () => Navigator.pop(
                      context,
                      RegionSelection(city: _city!, district: _district!),
                    )
                : null,
          ),
          const SizedBox(height: 4),
        ],
      ),
    );
  }
}

class _PickerTile extends StatelessWidget {
  const _PickerTile({
    required this.label,
    required this.value,
    required this.icon,
    required this.placeholder,
    this.onTap,
  });
  final String label;
  final String value;
  final IconData icon;
  final bool placeholder;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final disabled = onTap == null;
    return InkWell(
      onTap: onTap,
      borderRadius: FRRad.all(FRRad.l),
      child: Container(
        padding: const EdgeInsets.fromLTRB(14, 12, 12, 12),
        decoration: BoxDecoration(
          color: FR.bgElev,
          borderRadius: FRRad.all(FRRad.l),
          border: Border.all(color: FR.hairline),
        ),
        child: Row(
          children: [
            Icon(icon, size: 18, color: disabled ? FR.ink3 : FR.gold),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label, style: frOverline(color: FR.ink3, size: 9.5)),
                  const SizedBox(height: 2),
                  Text(
                    value,
                    style: frText(
                      14,
                      FontWeight.w800,
                      color: placeholder ? FR.ink3 : FR.ink,
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.keyboard_arrow_right_rounded,
                color: disabled ? FR.ink3 : FR.ink2),
          ],
        ),
      ),
    );
  }
}

class _LocationListSheet extends StatefulWidget {
  const _LocationListSheet({
    required this.title,
    required this.items,
    this.selected,
  });
  final String title;
  final List<String> items;
  final String? selected;

  @override
  State<_LocationListSheet> createState() => _LocationListSheetState();
}

class _LocationListSheetState extends State<_LocationListSheet> {
  final TextEditingController _searchCtrl = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  String _normalize(String value) {
    final lower = value.trim().toLowerCase();
    const map = <String, String>{
      'ı': 'i', 'İ': 'i', 'I': 'i',
      'ş': 's', 'ç': 'c', 'ğ': 'g', 'ö': 'o', 'ü': 'u', 'â': 'a',
    };
    final buf = StringBuffer();
    for (final ch in lower.split('')) {
      buf.write(map[ch] ?? ch);
    }
    return buf.toString();
  }

  @override
  Widget build(BuildContext context) {
    final normalizedQuery = _normalize(_query);
    final filtered = normalizedQuery.isEmpty
        ? widget.items
        : widget.items
            .where((item) => _normalize(item).contains(normalizedQuery))
            .toList();
    final viewInsets = MediaQuery.of(context).viewInsets.bottom;
    final maxHeight = MediaQuery.of(context).size.height * 0.78;
    return Padding(
      padding: EdgeInsets.only(bottom: viewInsets),
      child: ConstrainedBox(
        constraints: BoxConstraints(maxHeight: maxHeight),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 14),
            Center(
              child: Container(
                width: 38,
                height: 4,
                decoration: BoxDecoration(
                  color: FR.hairline,
                  borderRadius: FRRad.all(999),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 14, 20, 0),
              child: Text(widget.title,
                  style: frDisplay(20, FontWeight.w700)),
            ),
            const SizedBox(height: 10),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: TextField(
                controller: _searchCtrl,
                onChanged: (v) => setState(() => _query = v),
                style: frText(13.5, FontWeight.w700),
                cursorColor: FR.gold,
                decoration: InputDecoration(
                  prefixIcon: Icon(Icons.search_rounded,
                      color: FR.ink3, size: 18),
                  hintText: 'Ara…',
                  filled: true,
                  fillColor: FR.bgElev,
                  border: OutlineInputBorder(
                    borderRadius: FRRad.all(FRRad.m),
                    borderSide: BorderSide(color: FR.hairline),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: FRRad.all(FRRad.m),
                    borderSide: BorderSide(color: FR.hairline),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Flexible(
              child: filtered.isEmpty
                  ? Padding(
                      padding: const EdgeInsets.all(24),
                      child: Center(
                        child: Text('Sonuç yok.',
                            style: frText(12.5, FontWeight.w700,
                                color: FR.ink3)),
                      ),
                    )
                  : ListView.separated(
                      padding:
                          const EdgeInsets.fromLTRB(12, 4, 12, 16),
                      itemCount: filtered.length,
                      separatorBuilder: (_, __) =>
                          const SizedBox(height: 4),
                      itemBuilder: (_, i) {
                        final item = filtered[i];
                        final selected = item == widget.selected;
                        return InkWell(
                          borderRadius: FRRad.all(FRRad.m),
                          onTap: () => Navigator.pop(context, item),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 12),
                            decoration: BoxDecoration(
                              color: selected
                                  ? FR.gold.withOpacity(.12)
                                  : Colors.transparent,
                              borderRadius: FRRad.all(FRRad.m),
                              border: Border.all(
                                color: selected
                                    ? FR.gold.withOpacity(.4)
                                    : Colors.transparent,
                              ),
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Text(item,
                                      style: frText(13.5, FontWeight.w800,
                                          color: selected
                                              ? FR.gold
                                              : FR.ink)),
                                ),
                                if (selected)
                                  Icon(Icons.check_rounded,
                                      size: 18, color: FR.gold),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
