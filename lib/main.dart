import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

import 'screens/main_screen.dart';
import 'state/app_state.dart';
import 'theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(const FiyatRadarApp());
}

class FiyatRadarApp extends StatefulWidget {
  const FiyatRadarApp({super.key});

  @override
  State<FiyatRadarApp> createState() => _FiyatRadarAppState();
}

class _FiyatRadarAppState extends State<FiyatRadarApp> {
  final AppState _state = AppState();
  late final Future<void> _initFuture = _state.init();

  @override
  void dispose() {
    _state.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AppStateScope(
      state: _state,
      child: MaterialApp(
        title: 'FiyatRadar',
        debugShowCheckedModeBanner: false,
        theme: buildCoffeeTheme(),
        home: FutureBuilder<void>(
          future: _initFuture,
          builder: (context, snap) {
            if (snap.connectionState != ConnectionState.done) {
              return const _SplashScreen();
            }
            if (snap.hasError) {
              return _ErrorScreen(error: '${snap.error}');
            }
            return const MainScreen();
          },
        ),
      ),
    );
  }
}

class _SplashScreen extends StatelessWidget {
  const _SplashScreen();
  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.coffee, size: 56),
            SizedBox(height: 12),
            Text('FiyatRadar',
                style: TextStyle(fontWeight: FontWeight.w800, fontSize: 22)),
            SizedBox(height: 16),
            CircularProgressIndicator(),
          ],
        ),
      ),
    );
  }
}

class _ErrorScreen extends StatelessWidget {
  const _ErrorScreen({required this.error});
  final String error;
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text('Bağlantı hatası: $error',
              textAlign: TextAlign.center),
        ),
      ),
    );
  }
}
