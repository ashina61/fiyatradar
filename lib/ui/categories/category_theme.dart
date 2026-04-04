import '../../utils/theme.dart';

const String _categoryAssetBasePath = 'assets/icons/categories/';

enum CategoryId {
  temizlik,
  kisiselBakim,
  gida,
  icecek,
  atistirmalik,
  bebek,
  evYasam,
  elektronik,
  kitap,
  spor,
  evcilHayvan,
  diger,
}

class CategoryMeta {
  final CategoryId id;
  final String firestoreId;
  final String title;
  final String iconAsset;
  final int sort;

  const CategoryMeta({
    required this.id,
    required this.firestoreId,
    required this.title,
    required this.iconAsset,
    required this.sort,
  });
}

class CategoryTokens {
  static const chipBg = AppColors.surfaceVariant;
  static const chipBgActive = AppColors.secondaryLight;
  static const chipBorder = AppColors.outline;
  static const chipBorderActive = AppColors.secondary;
  static const iconTint = AppColors.secondaryDark;
  static const iconTintActive = AppColors.primaryDark;
  static const shadowSoft = AppColors.cardShadow;
  static const pressedOverlay = AppColors.primary;
  static const textPrimary = AppColors.textPrimary;
  static const textSecondary = AppColors.textSecondary;
}

const CategoryMeta _fallbackCategory = CategoryMeta(
  id: CategoryId.diger,
  firestoreId: 'diger',
  title: 'Diğer',
  iconAsset: '${_categoryAssetBasePath}temizlik.png',
  sort: 999,
);

const Map<String, CategoryMeta> _categoryMetaMap = {
  'temizlik': CategoryMeta(
    id: CategoryId.temizlik,
    firestoreId: 'temizlik',
    title: 'Temizlik',
    iconAsset: '${_categoryAssetBasePath}temizlik.png',
    sort: 1,
  ),
  'kisisel_bakim': CategoryMeta(
    id: CategoryId.kisiselBakim,
    firestoreId: 'kisisel_bakim',
    title: 'Kişisel Bakım',
    iconAsset: '${_categoryAssetBasePath}temizlik.png',
    sort: 2,
  ),
  'gida': CategoryMeta(
    id: CategoryId.gida,
    firestoreId: 'gida',
    title: 'Gıda',
    iconAsset: '${_categoryAssetBasePath}gida.png',
    sort: 3,
  ),
  'icecek': CategoryMeta(
    id: CategoryId.icecek,
    firestoreId: 'icecek',
    title: 'İçecek',
    iconAsset: '${_categoryAssetBasePath}icecek.png',
    sort: 4,
  ),
  'atistirmalik': CategoryMeta(
    id: CategoryId.atistirmalik,
    firestoreId: 'atistirmalik',
    title: 'Atıştırmalık',
    iconAsset: '${_categoryAssetBasePath}atistirmalik.png',
    sort: 5,
  ),
  'bebek': CategoryMeta(
    id: CategoryId.bebek,
    firestoreId: 'bebek',
    title: 'Bebek',
    iconAsset: '${_categoryAssetBasePath}bebek.png',
    sort: 6,
  ),
  'ev_yasam': CategoryMeta(
    id: CategoryId.evYasam,
    firestoreId: 'ev_yasam',
    title: 'Ev & Yaşam',
    iconAsset: '${_categoryAssetBasePath}ev_yasam.png',
    sort: 7,
  ),
  'elektronik': CategoryMeta(
    id: CategoryId.elektronik,
    firestoreId: 'elektronik',
    title: 'Elektronik',
    iconAsset: '${_categoryAssetBasePath}elektronik.png',
    sort: 8,
  ),
  'kitap': CategoryMeta(
    id: CategoryId.kitap,
    firestoreId: 'kitap',
    title: 'Kitap',
    iconAsset: '${_categoryAssetBasePath}kitap.png',
    sort: 9,
  ),
  'spor': CategoryMeta(
    id: CategoryId.spor,
    firestoreId: 'spor',
    title: 'Spor',
    iconAsset: '${_categoryAssetBasePath}spor.png',
    sort: 10,
  ),
  'evcil_hayvan': CategoryMeta(
    id: CategoryId.evcilHayvan,
    firestoreId: 'evcil_hayvan',
    title: 'Evcil Hayvan',
    iconAsset: '${_categoryAssetBasePath}evcil_hayvan.png',
    sort: 11,
  ),
  'diger': CategoryMeta(
    id: CategoryId.diger,
    firestoreId: 'diger',
    title: 'Diğer',
    iconAsset: '${_categoryAssetBasePath}temizlik.png',
    sort: 12,
  ),
};

CategoryMeta metaFromFirestoreId(String id) {
  final normalized = id.trim().toLowerCase();
  return _categoryMetaMap[normalized] ?? _fallbackCategory;
}

String? categoryIconAssetOrNull(String id) {
  final normalized = id.trim().toLowerCase();
  return _categoryMetaMap[normalized]?.iconAsset;
}
