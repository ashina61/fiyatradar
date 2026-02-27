class UserModel {
  const UserModel({
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

  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      id: map['id'] as String? ?? '',
      name: map['name'] as String? ?? '',
      surname: map['surname'] as String? ?? '',
      username: map['username'] as String? ?? '',
      city: map['city'] as String? ?? '',
      district: map['district'] as String? ?? '',
      neighborhood: map['neighborhood'] as String? ?? '',
      priceAlarm: map['priceAlarm'] as bool? ?? true,
      campaignNotification: map['campaignNotification'] as bool? ?? true,
      badgeNotification: map['badgeNotification'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
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

  UserModel copyWith({
    String? id,
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
      id: id ?? this.id,
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
