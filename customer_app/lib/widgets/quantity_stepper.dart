// lib/widgets/quantity_stepper.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

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

  void _showEditDialog(BuildContext context) {
    final controller = TextEditingController(text: '$value');
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Enter quantity'),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          autofocus: true,
          decoration: InputDecoration(
            hintText: '$min – $max',
          ),
          onSubmitted: (text) {
            final parsed = int.tryParse(text);
            if (parsed != null) {
              onChanged(parsed.clamp(min, max));
            }
            Navigator.of(ctx).pop();
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              final parsed = int.tryParse(controller.text);
              if (parsed != null) {
                onChanged(parsed.clamp(min, max));
              }
              Navigator.of(ctx).pop();
            },
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

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
        GestureDetector(
          onTap: () => _showEditDialog(context),
          child: SizedBox(
            width: large ? 64 : 48,
            child: Text(
              '$value',
              textAlign: TextAlign.center,
              style: textStyle?.copyWith(
                decoration: TextDecoration.underline,
                decorationStyle: TextDecorationStyle.dotted,
              ),
            ),
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
