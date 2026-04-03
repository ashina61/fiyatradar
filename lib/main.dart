import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/theme/app_theme.dart';
import 'screens/main_layout.dart';

void main() {
  runApp(const ProviderScope(child: FiyatRadarApp()));
}

class FiyatRadarApp extends StatelessWidget {
  const FiyatRadarApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'FiyatRadar V10',
      theme: AppTheme.darkTheme,
      home: const MainLayout(),
    );
  }
}
