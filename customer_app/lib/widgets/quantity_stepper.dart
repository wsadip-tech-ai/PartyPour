// lib/widgets/quantity_stepper.dart

import 'package:flutter/material.dart';

class QuantityStepper extends StatelessWidget {
  final int value;
  final int min;
  final int max;
  final ValueChanged<int> onChanged;
  final bool large;

  const QuantityStepper({
    super.key,
    required this.value,
    this.min = 0,
    this.max = 9999,
    required this.onChanged,
    this.large = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final iconSize = large ? 32.0 : 24.0;
    final textStyle = large
        ? theme.textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold)
        : theme.textTheme.titleLarge;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          onPressed: value > min ? () => onChanged(value - 1) : null,
          icon: Icon(Icons.remove_circle_outline, size: iconSize),
          style: IconButton.styleFrom(
            foregroundColor: theme.colorScheme.primary,
          ),
        ),
        SizedBox(
          width: large ? 64 : 48,
          child: Text(
            '$value',
            textAlign: TextAlign.center,
            style: textStyle,
          ),
        ),
        IconButton(
          onPressed: value < max ? () => onChanged(value + 1) : null,
          icon: Icon(Icons.add_circle_outline, size: iconSize),
          style: IconButton.styleFrom(
            foregroundColor: theme.colorScheme.primary,
          ),
        ),
      ],
    );
  }
}
