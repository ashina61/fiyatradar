import 'package:flutter_test/flutter_test.dart';
import 'package:fiyatradar/models/user_model.dart';

void main() {
  test('UserModel.toFirestore includes expected keys', () {
    final model = UserModel(
      uid: 'u1',
      email: 'test@example.com',
      name: 'Test User',
      city: 'İstanbul',
      createdAt: DateTime(2024, 1, 1),
      points: 10,
      isAdmin: false,
    );

    final map = model.toFirestore();
    expect(map['email'], 'test@example.com');
    expect(map['name'], 'Test User');
    expect(map['city'], 'İstanbul');
    expect(map['points'], 10);
    expect(map.containsKey('createdAt'), isTrue);
  });

  test('UserModel.copyWith updates only provided fields', () {
    final model = UserModel(
      uid: 'u1',
      email: 'a@a.com',
      name: 'A',
      createdAt: DateTime(2024, 1, 1),
      points: 5,
      isAdmin: false,
    );

    final updated = model.copyWith(name: 'B', points: 8);
    expect(updated.name, 'B');
    expect(updated.points, 8);
    expect(updated.email, 'a@a.com');
    expect(updated.uid, 'u1');
  });
}
