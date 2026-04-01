import 'package:flutter/material.dart';

import 'cart_screen_v2.dart';

/// DEPRECATED legacy entrypoint kept only for existing navigation wiring.
///
/// We now delegate to [CartScreenV2], which is backed by Firestore/Firebase
/// data flow via `BasketViewModel` instead of local mock providers.
///
/// Do not add new cart logic here. Keep this file as a thin adapter until
/// navigation is migrated directly to `CartScreenV2`.
class HomeShellScreen extends StatelessWidget {
  const HomeShellScreen({super.key});

  @override
  Widget build(BuildContext context) => const CartScreenV2();
}
