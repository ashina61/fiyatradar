import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../ui/tokens.dart';
import '../models/illustration_asset.dart';

class IllustrationGridItem extends StatelessWidget {
  const IllustrationGridItem({
    super.key,
    required this.asset,
    required this.selected,
    required this.isCurrent,
    required this.onTap,
  });

  final IllustrationAsset asset;
  final bool selected;

  /// True when this entry is the one currently saved on the product.
  final bool isCurrent;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final borderColor = selected ? FR.gold : FR.hairline;
    final borderWidth = selected ? 2.0 : 1.0;
    return InkWell(
      onTap: onTap,
      borderRadius: FRRad.all(18),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 140),
        decoration: BoxDecoration(
          color: FR.surfaceHi,
          borderRadius: FRRad.all(18),
          border: Border.all(color: borderColor, width: borderWidth),
        ),
        padding: const EdgeInsets.fromLTRB(8, 10, 8, 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: Stack(
                children: [
                  Positioned.fill(
                    child: SvgPicture.asset(
                      asset.assetPath,
                      fit: BoxFit.contain,
                      semanticsLabel: asset.label,
                      placeholderBuilder: (_) => Center(
                        child: SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation(FR.gold),
                          ),
                        ),
                      ),
                    ),
                  ),
                  if (selected)
                    Positioned(
                      top: 0,
                      right: 0,
                      child: Container(
                        width: 22,
                        height: 22,
                        decoration: BoxDecoration(
                          color: FR.gold,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: FR.shadowTone.withOpacity(.25),
                              blurRadius: 6,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Icon(Icons.check_rounded,
                            color: FR.onGold, size: 14),
                      ),
                    )
                  else if (isCurrent)
                    Positioned(
                      top: 0,
                      right: 0,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: FR.bg,
                          borderRadius: FRRad.all(999),
                          border: Border.all(color: FR.hairline),
                        ),
                        child: Text(
                          'Mevcut',
                          style: frText(8.5, FontWeight.w800, color: FR.ink3),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 6),
            Text(
              asset.label,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: frText(11, FontWeight.w700, color: FR.ink, height: 1.15),
            ),
          ],
        ),
      ),
    );
  }
}
