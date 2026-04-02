// lib/screens/calculator/price_calculator_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../providers/wizard_provider.dart';
import '../../widgets/quantity_stepper.dart';

class PriceCalculatorScreen extends ConsumerWidget {
  const PriceCalculatorScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final wizard = ref.watch(wizardProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Price Calculator'),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => context.pop(),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          Text('Adjust quantities and see price changes in real-time.',
              style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
          const SizedBox(height: 16),

          ...wizard.brandSelections.entries.map((entry) {
            final slug = entry.key;
            final selections = entry.value;
            if (selections.isEmpty) return const SizedBox.shrink();

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(slug.replaceAll('-', ' ').toUpperCase(),
                    style: theme.textTheme.labelLarge?.copyWith(
                        color: theme.colorScheme.primary, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                ...selections.asMap().entries.map((selEntry) {
                  final idx = selEntry.key;
                  final sel = selEntry.value;
                  return Card(
                    margin: const EdgeInsets.only(bottom: 8),
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(sel.product.name, style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600)),
                                    Text(sel.variant.size, style: theme.textTheme.bodySmall),
                                  ],
                                ),
                              ),
                              // Unit/Case toggle
                              if (sel.variant.caseSize != null && sel.variant.casePrice != null)
                                SegmentedButton<String>(
                                  segments: [
                                    const ButtonSegment(value: 'unit', label: Text('Bottle')),
                                    ButtonSegment(value: 'case', label: Text('Case(${sel.variant.caseSize})')),
                                  ],
                                  selected: {sel.unitType},
                                  onSelectionChanged: (s) {
                                    sel.unitType = s.first;
                                    ref.read(wizardProvider.notifier).updateBrandQuantity(slug, idx, sel.quantity);
                                  },
                                  style: ButtonStyle(
                                    visualDensity: VisualDensity.compact,
                                    textStyle: WidgetStatePropertyAll(theme.textTheme.labelSmall),
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Text('NPR ${sel.unitPrice.toStringAsFixed(0)} each',
                                  style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
                              const Spacer(),
                              QuantityStepper(
                                value: sel.quantity,
                                min: 1,
                                onChanged: (v) => ref.read(wizardProvider.notifier).updateBrandQuantity(slug, idx, v),
                              ),
                              const SizedBox(width: 8),
                              SizedBox(
                                width: 90,
                                child: Text(
                                  'NPR ${sel.totalPrice.toStringAsFixed(0)}',
                                  textAlign: TextAlign.right,
                                  style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  );
                }),
                const SizedBox(height: 16),
              ],
            );
          }),
        ],
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          boxShadow: [BoxShadow(blurRadius: 8, color: Colors.black.withOpacity(0.08))],
        ),
        child: Row(
          children: [
            Text('Total', style: theme.textTheme.titleMedium),
            const Spacer(),
            Text(
              'NPR ${wizard.grandTotal.toStringAsFixed(0)}',
              style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold, color: theme.colorScheme.primary),
            ),
          ],
        ),
      ),
    );
  }
}
