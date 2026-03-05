import 'package:flutter_riverpod/flutter_riverpod.dart';

enum HomeTab { sepet, karsilastir }

class HomeTabNotifier extends StateNotifier<HomeTab> {
  HomeTabNotifier() : super(HomeTab.sepet);

  void setTab(HomeTab tab) => state = tab;
}

final homeTabProvider = StateNotifierProvider<HomeTabNotifier, HomeTab>(
  (ref) => HomeTabNotifier(),
);
