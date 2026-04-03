import 'package:flutter_riverpod/flutter_riverpod.dart';

final userNameProvider = StateProvider<String>((ref) => 'Mehmet');
final userLevelProvider = StateProvider<int>((ref) => 12);
final isNotificationEnabledProvider = StateProvider<bool>((ref) => true);
