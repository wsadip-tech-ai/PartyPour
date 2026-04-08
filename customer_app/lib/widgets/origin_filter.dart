import 'package:flutter/material.dart';

class OriginFilter extends StatelessWidget {
  final String? selectedOrigin;
  final ValueChanged<String?> onChanged;

  const OriginFilter({super.key, this.selectedOrigin, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return SegmentedButton<String?>(
      segments: const [
        ButtonSegment(value: null, label: Text('All')),
        ButtonSegment(value: 'local', label: Text('Domestic')),
        ButtonSegment(value: 'imported', label: Text('Imported')),
      ],
      selected: {selectedOrigin},
      onSelectionChanged: (selected) => onChanged(selected.first),
    );
  }
}
