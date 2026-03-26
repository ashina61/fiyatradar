import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class AdminCuratedListsTab extends StatefulWidget {
  const AdminCuratedListsTab({super.key});

  @override
  State<AdminCuratedListsTab> createState() => _AdminCuratedListsTabState();
}

class _AdminCuratedListsTabState extends State<AdminCuratedListsTab> {
  final _titleController = TextEditingController();
  final _subtitleController = TextEditingController();
  final _productsController = TextEditingController();

  @override
  void dispose() {
    _titleController.dispose();
    _subtitleController.dispose();
    _productsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(12),
          child: Card(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                children: [
                  TextField(controller: _titleController, decoration: const InputDecoration(labelText: 'Liste başlığı')),
                  TextField(controller: _subtitleController, decoration: const InputDecoration(labelText: 'Alt başlık')),
                  TextField(
                    controller: _productsController,
                    decoration: const InputDecoration(labelText: 'Ürünler (virgülle ayır)'),
                  ),
                  const SizedBox(height: 8),
                  Align(
                    alignment: Alignment.centerRight,
                    child: ElevatedButton.icon(
                      onPressed: _createList,
                      icon: const Icon(Icons.add),
                      label: const Text('Liste Oluştur'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        Expanded(
          child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
            stream: FirebaseFirestore.instance.collection('curated_lists').orderBy('order').snapshots(),
            builder: (context, snapshot) {
              if (snapshot.hasError) return const Center(child: Text('Listeler yüklenemedi.'));
              if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
              final docs = snapshot.data!.docs;
              if (docs.isEmpty) return const Center(child: Text('Henüz liste yok.'));

              return ListView.builder(
                itemCount: docs.length,
                itemBuilder: (context, index) {
                  final doc = docs[index];
                  final data = doc.data();
                  final title = data['title']?.toString() ?? 'Başlıksız';
                  final subtitle = data['subtitle']?.toString() ?? '';
                  final isActive = data['isActive'] == true;

                  return ListTile(
                    title: Text(title),
                    subtitle: Text(subtitle),
                    trailing: Wrap(
                      spacing: 8,
                      children: [
                        Switch(
                          value: isActive,
                          onChanged: (v) => doc.reference.update({'isActive': v}),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete_outline),
                          onPressed: () => doc.reference.delete(),
                        ),
                      ],
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }

  Future<void> _createList() async {
    final title = _titleController.text.trim();
    if (title.isEmpty) return;

    final products = _productsController.text
        .split(',')
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList();

    final snapshot = await FirebaseFirestore.instance.collection('curated_lists').get();

    await FirebaseFirestore.instance.collection('curated_lists').add({
      'title': title,
      'subtitle': _subtitleController.text.trim(),
      'products': products,
      'isActive': true,
      'order': snapshot.docs.length,
      'updatedAt': FieldValue.serverTimestamp(),
      'createdAt': FieldValue.serverTimestamp(),
    });

    _titleController.clear();
    _subtitleController.clear();
    _productsController.clear();
  }
}
