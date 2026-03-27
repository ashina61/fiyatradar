import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/special_list_provider.dart';
import '../cart/cart_list_detail_screen.dart';

class PersonalListsScreen extends ConsumerWidget {
  const PersonalListsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final listsAsync = ref.watch(activeSpecialListsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Özel Listeler')),
      body: listsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, __) => const Center(child: Text('Listeler yüklenemedi.')),
        data: (lists) {
          if (lists.isEmpty) {
            return const Center(child: Text('Aktif özel liste bulunamadı.'));
          }
          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemBuilder: (context, index) {
              final list = lists[index];
              return ListTile(
                tileColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                title: Text(list.title),
                subtitle: Text(list.subtitle),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute<void>(builder: (_) => CartListDetailScreen(listId: list.id)),
                  );
                },
              );
            },
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemCount: lists.length,
          );
        },
      ),
    );
  }
}
