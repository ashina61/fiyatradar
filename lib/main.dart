import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});
  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  String token = "Yükleniyor...";

  @override
  void initState() {
    super.initState();
    getToken();
  }

  Future<void> getToken() async {
    await FirebaseMessaging.instance.requestPermission();
    final t = await FirebaseMessaging.instance.getToken();
    setState(() {
      token = t ?? "TOKEN NULL";
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(title: const Text("FCM Token")),
        body: Padding(
          padding: const EdgeInsets.all(16),
          child: SelectableText(token),
        ),
      ),
    );
  }
}