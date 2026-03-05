import 'package:flutter/material.dart';

import 'cart_screen_v2.dart';

/// Legacy entrypoint kept for existing navigation wiring.
///
/// We now delegate to [CartScreenV2], which is backed by Firestore/Firebase
/// data flow via `BasketViewModel` instead of local mock providers.
class HomeShellScreen extends StatelessWidget {
  const HomeShellScreen({super.key});

  @override
  Widget build(BuildContext context) => const CartScreenV2();
}
