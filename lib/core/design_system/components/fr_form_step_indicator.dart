import 'package:flutter/material.dart';

import '../tokens/colors.dart';

class FRFormStepIndicator extends StatelessWidget {
  const FRFormStepIndicator({required this.steps, required this.currentStep, super.key});

  final int steps;
  final int currentStep;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: List.generate(steps, (index) {
        final active = index <= currentStep;
        return Expanded(
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 4),
            height: 6,
            decoration: BoxDecoration(
              color: active ? FRDsColors.frGold : FRDsColors.frBorderSoft,
              borderRadius: BorderRadius.circular(999),
            ),
          ),
        );
      }),
    );
  }
}
