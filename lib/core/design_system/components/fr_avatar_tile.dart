import 'package:flutter/material.dart';

import '../tokens/colors.dart';

class FRAvatarTile extends StatelessWidget {
  const FRAvatarTile({required this.name, super.key, this.imageUrl});

  final String name;
  final String? imageUrl;

  @override
  Widget build(BuildContext context) {
    return Row(children: [
      CircleAvatar(
        radius: 24,
        backgroundColor: FRDsColors.frGoldSoft,
        foregroundImage: imageUrl == null ? null : NetworkImage(imageUrl!),
        child: imageUrl == null ? Text((name.isNotEmpty ? name[0] : 'U').toUpperCase()) : null,
      ),
      const SizedBox(width: 12),
      Expanded(child: Text(name)),
    ]);
  }
}
