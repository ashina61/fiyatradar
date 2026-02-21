class Store {
  const Store({
    required this.id,
    required this.name,
    required this.type,
    required this.distanceMeters,
    required this.logoUrl,
    this.subtitle,
  });

  final String id;
  final String name;
  final String type;
  final int? distanceMeters;
  final String logoUrl;
  final String? subtitle;

  factory Store.fromJson(Map<String, dynamic> json) {
    return Store(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      type: json['type'] as String? ?? 'nearby',
      distanceMeters: (json['distance_meters'] as num?)?.toInt(),
      logoUrl: json['logoUrl'] as String? ?? '',
      subtitle: json['subtitle'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'type': type,
      'distance_meters': distanceMeters,
      'logoUrl': logoUrl,
      'subtitle': subtitle,
    };
  }
}
