import 'package:flutter/material.dart';
import 'screens/main_screen.dart';
import 'state/app_state.dart';
import 'theme.dart';

void main() {
  runApp(const FiyatRadarApp());
}

class FiyatRadarApp extends StatefulWidget {
  const FiyatRadarApp({super.key});

  @override
  State<FiyatRadarApp> createState() => _FiyatRadarAppState();
}

class _FiyatRadarAppState extends State<FiyatRadarApp> {
  final AppState _state = AppState();

  @override
  Widget build(BuildContext context) {
    return AppStateScope(
      state: _state,
      child: MaterialApp(
        title: 'FiyatRadar',
        debugShowCheckedModeBanner: false,
        theme: buildCoffeeTheme(),
        home: const MainScreen(),
      ),
    );
  }
}
