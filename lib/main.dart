import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';

void main() {
  runApp(const ProviderScope(child: FiyatRadarApp()));
}

class FiyatRadarApp extends ConsumerWidget {
  const FiyatRadarApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp.router(
      debugShowCheckedModeBanner: false,
      title: 'FiyatRadar V10',
      theme: AppTheme.darkTheme,
      routerConfig: appRouter,
    );
  }
}
