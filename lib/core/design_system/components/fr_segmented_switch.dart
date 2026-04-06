import 'package:flutter/material.dart';

class FRSegmentedSwitch<T> extends StatelessWidget {
  const FRSegmentedSwitch({required this.segments, required this.selected, required this.onSelectionChanged, super.key});

  final Map<T, Widget> segments;
  final Set<T> selected;
  final ValueChanged<Set<T>> onSelectionChanged;

  @override
  Widget build(BuildContext context) {
    return SegmentedButton<T>(
      segments: segments.entries.map((e) => ButtonSegment<T>(value: e.key, label: e.value)).toList(),
      selected: selected,
      onSelectionChanged: onSelectionChanged,
      showSelectedIcon: false,
      multiSelectionEnabled: false,
    );
  }
}
