// Dev-only entry point that boots directly into the executive ThemePreviewScreen.
// Does NOT touch main.dart or Firebase. Use: flutter run -t lib/main_preview.dart
//
// Safe to keep checked in; production builds use lib/main.dart as usual.

import 'package:flutter/material.dart';

import 'screens/dev/theme_preview_screen.dart';
import 'theme/executive_theme.dart';

void main() {
  runApp(const _PreviewApp());
}

class _PreviewApp extends StatelessWidget {
  const _PreviewApp();

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'FiyatRadar · Theme Preview',
      debugShowCheckedModeBanner: false,
      theme: buildExecutiveTheme(),
      home: const ThemePreviewScreen(),
    );
  }
}
