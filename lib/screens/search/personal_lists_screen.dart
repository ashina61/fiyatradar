import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/special_list_provider.dart';
import '../cart/cart_list_detail_screen.dart';

class PersonalListsScreen extends ConsumerWidget {
  const PersonalListsScreen({super.key, this.listId});

  final String? listId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (listId != null && listId!.isNotEmpty) {
      return CartListDetailScreen(listId: listId!);
    }

    final listsAsync = ref.watch(specialListsProvider);
    return listsAsync.when(
      loading: () => const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (_, __) => const Scaffold(body: Center(child: Text('Özel listeler yüklenemedi.'))),
      data: (lists) {
        if (lists.isEmpty) {
          return const Scaffold(body: Center(child: Text('Henüz özel liste yok.')));
        }
        return CartListDetailScreen(listId: lists.first.id);
      },
    );
  }
}
