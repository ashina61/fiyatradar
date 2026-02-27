class UserModel {
  final String id;
  final String name;
  final String surname;
  final String username;
  final String city;
  final String district;
  final String neighborhood;
  final bool priceAlarm;
  final bool campaignNotification;
  final bool badgeNotification;

  UserModel({
    required this.id,
    required this.name,
    required this.surname,
    required this.username,
    required this.city,
    required this.district,
    required this.neighborhood,
    required this.priceAlarm,
    required this.campaignNotification,
    required this.badgeNotification,
  });

  // Firebase'den gelen veriyi uygulamaya çevirir
  factory UserModel.fromMap(Map<String, dynamic> data, String documentId) {
    return UserModel(
      id: documentId,
      name: data['name'] ?? '',
      surname: data['surname'] ?? '',
      username: data['username'] ?? '',
      city: data['city'] ?? 'İstanbul',
      district: data['district'] ?? 'Kadıköy',
      neighborhood: data['neighborhood'] ?? 'Cumhuriyet Mah.',
      priceAlarm: data['priceAlarm'] ?? true,
      campaignNotification: data['campaignNotification'] ?? true,
      badgeNotification: data['badgeNotification'] ?? false,
    );
  }

  // Uygulamadaki veriyi Firebase'e gönderilecek formata çevirir
  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'surname': surname,
      'username': username,
      'city': city,
      'district': district,
      'neighborhood': neighborhood,
      'priceAlarm': priceAlarm,
      'campaignNotification': campaignNotification,
      'badgeNotification': badgeNotification,
    };
  }

  // Değişiklikleri kaydederken kolaylık sağlar
  UserModel copyWith({
    String? name,
    String? surname,
    String? username,
    String? city,
    String? district,
    String? neighborhood,
    bool? priceAlarm,
    bool? campaignNotification,
    bool? badgeNotification,
  }) {
    return UserModel(
      id: id,
      name: name ?? this.name,
      surname: surname ?? this.surname,
      username: username ?? this.username,
      city: city ?? this.city,
      district: district ?? this.district,
      neighborhood: neighborhood ?? this.neighborhood,
      priceAlarm: priceAlarm ?? this.priceAlarm,
      campaignNotification: campaignNotification ?? this.campaignNotification,
      badgeNotification: badgeNotification ?? this.badgeNotification,
    );
  }
}
