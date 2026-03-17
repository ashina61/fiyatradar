import 'package:cloud_firestore/cloud_firestore.dart';

enum BannerType { duyuru, sponsor, kampanya }

class BannerModel {
  const BannerModel({
    required this.id,
    required this.type,
    required this.title,
    required this.subtitle,
    required this.ctaLabel,
    required this.tagLabel,
    required this.isActive,
    required this.order,
    this.imageUrl,
    this.brandName,
    this.metaLabel,
    this.linkUrl,
    this.createdAt,
  });

  final String     id;
  final BannerType type;
  final String     title;
  final String     subtitle;
  final String     ctaLabel;
  final String     tagLabel;
  final bool       isActive;
  final int        order;
  final String?    imageUrl;
  final String?    brandName;
  final String?    metaLabel;
  final String?    linkUrl;
  final DateTime?  createdAt;

  factory BannerModel.fromDoc(DocumentSnapshot doc) {
    final m = doc.data() as Map<String, dynamic>;
    final typeStr = (m['type'] as String? ?? 'duyuru').toLowerCase();
    final type = switch (typeStr) {
      'sponsor'  => BannerType.sponsor,
      'kampanya' => BannerType.kampanya,
      _          => BannerType.duyuru,
    };
    return BannerModel(
      id:        doc.id,
      type:      type,
      title:     m['title']     as String? ?? '',
      subtitle:  m['subtitle']  as String? ?? '',
      ctaLabel:  m['ctaLabel']  as String? ?? 'Keşfet',
      tagLabel:  m['tagLabel']  as String? ?? 'Duyuru',
      isActive:  m['isActive']  as bool?   ?? false,
      order:     m['order']     as int?    ?? 0,
      imageUrl:  m['imageUrl']  as String?,
      brandName: m['brandName'] as String?,
      metaLabel: m['metaLabel'] as String?,
      linkUrl:   m['linkUrl']   as String?,
      createdAt: (m['createdAt'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toMap() => {
    'type':      type.name,
    'title':     title,
    'subtitle':  subtitle,
    'ctaLabel':  ctaLabel,
    'tagLabel':  tagLabel,
    'isActive':  isActive,
    'order':     order,
    if (imageUrl  != null) 'imageUrl':  imageUrl,
    if (brandName != null) 'brandName': brandName,
    if (metaLabel != null) 'metaLabel': metaLabel,
    if (linkUrl   != null) 'linkUrl':   linkUrl,
    'createdAt': FieldValue.serverTimestamp(),
  };
}
