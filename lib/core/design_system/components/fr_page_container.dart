import 'package:flutter/widgets.dart';

import '../tokens/spacing.dart';

class FRPageContainer extends StatelessWidget {
  const FRPageContainer({required this.child, super.key, this.padding});

  final Widget child;
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: padding ?? const EdgeInsets.symmetric(horizontal: FRDsSpacing.space20),
      child: child,
    );
  }
}
