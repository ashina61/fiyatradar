import 'package:flutter/material.dart';
import 'basket_panel.dart';

class BasketScreen extends StatelessWidget {
  const BasketScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      appBar: AppBar(
        title: Text('Sepet'),
      ),
      body: BasketPanel(),
    );
  }
}
