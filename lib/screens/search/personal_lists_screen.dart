import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class PersonalListsScreen extends StatelessWidget {
  const PersonalListsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Sana Özel Listeler')),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: FirebaseFirestore.instance
            .collection('curated_lists')
            .orderBy('order')
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return const Center(child: Text('Listeler yüklenemedi.'));
          }
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final docs = snapshot.data!.docs.where((doc) => doc.data()['isActive'] == true).toList();
          if (docs.isEmpty) {
            return const Center(child: Text('Henüz yayınlanmış liste yok.'));
          }

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: docs.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final data = docs[index].data();
              final products = (data['products'] as List<dynamic>? ?? const <dynamic>[]).map((e) => e.toString()).toList();
              return Card(
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(data['title']?.toString() ?? 'Özel Liste', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                      const SizedBox(height: 4),
                      Text(data['subtitle']?.toString() ?? 'Senin için seçildi', style: const TextStyle(color: Colors.black54)),
                      const SizedBox(height: 10),
                      if (products.isEmpty)
                        const Text('Ürün yok')
                      else
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: products
                              .map(
                                (product) => Chip(
                                  label: Text(product),
                                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                ),
                              )
                              .toList(),
                        ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
