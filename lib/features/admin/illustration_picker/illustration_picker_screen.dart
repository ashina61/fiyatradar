import 'package:flutter/material.dart';

import '../../../ui/components.dart';
import '../../../ui/tokens.dart';
import '../models/illustration_asset.dart';
import 'illustration_category_chip.dart';
import 'illustration_grid_item.dart';
import 'illustration_manifest_service.dart';
import 'illustration_search_bar.dart';

/// Admin picker for the brand-agnostic category illustration library.
///
/// Pops with the selected [IllustrationAsset] when the admin confirms,
/// or `null` if they cancel. The picker is read-only — it never mutates
/// the underlying product, the caller persists the choice.
class IllustrationPickerScreen extends StatefulWidget {
  const IllustrationPickerScreen({
    super.key,
    this.initialCategory,
    this.currentIllustrationId,
  });

  /// Category id (matches `manifest.categories[].id`) to preselect when
  /// the picker opens — e.g. the product's existing category.
  final String? initialCategory;

  /// The illustration currently assigned to the product. Used for the
  /// "Mevcut" badge + disabled CTA when the admin re-selects the same one.
  final String? currentIllustrationId;

  @override
  State<IllustrationPickerScreen> createState() =>
      _IllustrationPickerScreenState();
}

class _IllustrationPickerScreenState extends State<IllustrationPickerScreen> {
  static const String _allCategoryId = '__all__';

  final TextEditingController _searchCtrl = TextEditingController();
  late Future<IllustrationManifest> _manifestFuture;

  String _activeCategoryId = _allCategoryId;
  String _searchQuery = '';
  String? _selectedId;

  @override
  void initState() {
    super.initState();
    _manifestFuture = IllustrationManifestService.load();
    _selectedId = widget.currentIllustrationId;
    if (widget.initialCategory != null && widget.initialCategory!.isNotEmpty) {
      _activeCategoryId = widget.initialCategory!;
    }
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  /// Normalises Turkish characters + casing so "kola" matches "Kola" and
  /// "süt" matches "sut" — Dart's `toLowerCase` is unicode-default, which
  /// turns İ into "i̇" (i + combining dot above); we strip that
  /// sequence here instead of relying on a locale-aware fold.
  String _normalize(String input) {
    var s = input.toLowerCase().replaceAll('̇', '');
    const replacements = {
      'ç': 'c',
      'ğ': 'g',
      'ı': 'i',
      'ö': 'o',
      'ş': 's',
      'ü': 'u',
    };
    replacements.forEach((from, to) {
      s = s.replaceAll(from, to);
    });
    return s.trim();
  }

  List<IllustrationAsset> _filter(List<IllustrationAsset> all) {
    final q = _normalize(_searchQuery);
    Iterable<IllustrationAsset> result = all;
    if (_activeCategoryId != _allCategoryId) {
      result = result.where((a) => a.category == _activeCategoryId);
    }
    if (q.isNotEmpty) {
      result = result.where((a) {
        if (_normalize(a.label).contains(q)) return true;
        if (_normalize(a.category).contains(q)) return true;
        if (_normalize(a.categoryLabel).contains(q)) return true;
        if (a.id.contains(q)) return true;
        for (final tag in a.tags) {
          if (_normalize(tag).contains(q)) return true;
        }
        return false;
      });
    }
    return result.toList(growable: false);
  }

  void _onSearchChanged(String value) {
    if (value.trim().isEmpty && _searchQuery.isEmpty) return;
    setState(() {
      _searchQuery = value;
      // Per spec: typing into search collapses the chip filter to "All"
      // so results aren't double-filtered out from under the user.
      if (value.trim().isNotEmpty && _activeCategoryId != _allCategoryId) {
        _activeCategoryId = _allCategoryId;
      }
    });
  }

  void _onCategoryTap(String id) {
    if (_activeCategoryId == id && _searchQuery.isEmpty) return;
    setState(() {
      _activeCategoryId = id;
      // Per spec: choosing a category clears search.
      if (_searchQuery.isNotEmpty) {
        _searchQuery = '';
        _searchCtrl.clear();
      }
    });
  }

  void _confirmSelection(IllustrationAsset asset) {
    Navigator.of(context).pop<IllustrationAsset?>(asset);
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final crossAxisCount = width >= 720 ? 4 : 3;
    return Scaffold(
      backgroundColor: FR.bg,
      body: SafeArea(
        bottom: false,
        child: FutureBuilder<IllustrationManifest>(
          future: _manifestFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState != ConnectionState.done) {
              return _loadingState();
            }
            if (snapshot.hasError || snapshot.data == null) {
              return _errorState(snapshot.error?.toString() ?? 'Bilinmeyen hata');
            }
            return _buildLoaded(snapshot.data!, crossAxisCount);
          },
        ),
      ),
    );
  }

  Widget _loadingState() {
    return Center(
      child: SizedBox(
        width: 28,
        height: 28,
        child: CircularProgressIndicator(
          strokeWidth: 2.4,
          valueColor: AlwaysStoppedAnimation(FR.gold),
        ),
      ),
    );
  }

  Widget _errorState(String message) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.warning_amber_rounded, color: FR.bad, size: 36),
          const SizedBox(height: 10),
          Text(
            'Görsel kütüphanesi yüklenemedi.',
            style: frText(14, FontWeight.w800),
          ),
          const SizedBox(height: 6),
          Text(
            message,
            textAlign: TextAlign.center,
            style: frText(11.5, FontWeight.w600, color: FR.ink3),
          ),
        ],
      ),
    );
  }

  Widget _buildLoaded(IllustrationManifest manifest, int crossAxisCount) {
    final filtered = _filter(manifest.illustrations);
    final selectedAsset = _resolveSelection(manifest, filtered);
    final canConfirm = selectedAsset != null &&
        selectedAsset.id != widget.currentIllustrationId;

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
          child: Row(
            children: [
              FRIconChip(
                icon: Icons.arrow_back_rounded,
                onTap: () => Navigator.of(context).pop<IllustrationAsset?>(null),
              ),
              const Spacer(),
              FRIconChip(
                icon: Icons.close_rounded,
                onTap: () => Navigator.of(context).pop<IllustrationAsset?>(null),
              ),
            ],
          ),
        ),
        const Padding(
          padding: EdgeInsets.fromLTRB(20, 14, 20, 0), // LEGACY_EXCEPTION: reason=token_migration owner=codex remove_by=2026-06-30
          child: FRPageHeader(
            overline: 'KÜTÜPHANE',
            title: 'Görsel',
            italicTail: ' seç',
          ),
        ),
        const SizedBox(height: 14),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: IllustrationSearchBar(
            controller: _searchCtrl,
            onChanged: _onSearchChanged,
          ),
        ),
        const SizedBox(height: 10),
        _categoryChipsRow(manifest, filtered.length),
        const SizedBox(height: 4),
        Expanded(
          child: filtered.isEmpty
              ? _emptyState()
              : GridView.builder(
                  padding: EdgeInsets.fromLTRB(
                    16,
                    8,
                    16,
                    96 + MediaQuery.of(context).viewPadding.bottom,
                  ),
                  itemCount: filtered.length,
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: crossAxisCount,
                    childAspectRatio: 0.78,
                    crossAxisSpacing: 10,
                    mainAxisSpacing: 10,
                  ),
                  itemBuilder: (context, index) {
                    final asset = filtered[index];
                    final isSelected = asset.id == _selectedId;
                    final isCurrent = asset.id == widget.currentIllustrationId;
                    return IllustrationGridItem(
                      asset: asset,
                      selected: isSelected,
                      isCurrent: isCurrent && !isSelected,
                      onTap: () => setState(() => _selectedId = asset.id),
                    );
                  },
                ),
        ),
        _bottomBar(selectedAsset, canConfirm),
      ],
    );
  }

  IllustrationAsset? _resolveSelection(
    IllustrationManifest manifest,
    List<IllustrationAsset> filtered,
  ) {
    if (_selectedId == null) return null;
    for (final a in manifest.illustrations) {
      if (a.id == _selectedId) return a;
    }
    return filtered.isNotEmpty ? filtered.first : null;
  }

  Widget _categoryChipsRow(
    IllustrationManifest manifest,
    int filteredCount,
  ) {
    // Sabit yükseklik 46px chip içeriği (~36px) + dikey padding (2*8) ile
    // taşınca metnin alt yarısı kırpılıyordu — "İçecekler" gibi uzun
    // etiketlerde belirgindi. Yüksekliği 58'e çıkardık, dikey padding'i de
    // hafifletip metni tam ortaladık.
    return SizedBox(
      height: 58,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
        children: [
          IllustrationCategoryChip(
            label: 'Tümü · ${manifest.illustrations.length}',
            selected: _activeCategoryId == _allCategoryId,
            onTap: () => _onCategoryTap(_allCategoryId),
          ),
          for (final c in manifest.categories) ...[
            const SizedBox(width: 8),
            IllustrationCategoryChip(
              label: c.label,
              selected: _activeCategoryId == c.id,
              onTap: () => _onCategoryTap(c.id),
            ),
          ],
          const SizedBox(width: 12),
          if (_searchQuery.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(left: 4, top: 6),
              child: Text(
                '$filteredCount sonuç',
                style: frText(11, FontWeight.w700, color: FR.ink3),
              ),
            ),
        ],
      ),
    );
  }

  Widget _emptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.search_off_rounded, color: FR.ink3, size: 36),
            const SizedBox(height: 10),
            Text(
              'Bu kategoride sonuç bulunamadı',
              style: frText(13.5, FontWeight.w800),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 6),
            Text(
              'Farklı bir kategori dene veya arama metnini değiştir.',
              style: frText(11.5, FontWeight.w600, color: FR.ink3),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _bottomBar(IllustrationAsset? selectedAsset, bool canConfirm) {
    final label = selectedAsset == null
        ? 'Bir görsel seç'
        : (canConfirm
            ? 'Bu görseli ata · ${selectedAsset.label}'
            : 'Geçerli görsel');
    return Container(
      padding: EdgeInsets.fromLTRB(
        20,
        12,
        20,
        12 + MediaQuery.of(context).viewPadding.bottom,
      ),
      decoration: BoxDecoration(
        color: FR.bgElev,
        border: Border(top: BorderSide(color: FR.hairline)),
      ),
      child: FRCta(
        label: label,
        icon: canConfirm ? Icons.check_rounded : Icons.image_outlined,
        onTap: canConfirm && selectedAsset != null
            ? () => _confirmSelection(selectedAsset)
            : null,
      ),
    );
  }
}
