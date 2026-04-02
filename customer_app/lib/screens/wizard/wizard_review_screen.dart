// lib/screens/wizard/wizard_review_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../providers/wizard_provider.dart';
import '../../providers/cart_provider.dart';
import '../../widgets/step_progress.dart';
import '../../widgets/quantity_stepper.dart';

class WizardReviewScreen extends ConsumerWidget {
  const WizardReviewScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final wizard = ref.watch(wizardProvider);
    final theme = Theme.of(context);

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            const StepProgress(currentStep: 5),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Text('Review your order',
                  style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                children: [
                  // Event summary card
                  Card(
                    color: theme.colorScheme.primaryContainer.withOpacity(0.3),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          Icon(Icons.event, color: theme.colorScheme.primary),
                          const SizedBox(width: 12),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('${wizard.totalPax} guests • ${wizard.eventType.replaceAll('_', ' ')}',
                                  style: theme.textTheme.titleSmall),
                              if (wizard.eventDate != null)
                                Text('${wizard.eventDate!.day}/${wizard.eventDate!.month}/${wizard.eventDate!.year}',
                                    style: theme.textTheme.bodySmall),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Brand selections grouped by category
                  ...wizard.brandSelections.entries.map((entry) {
                    final slug = entry.key;
                    final selections = entry.value;
                    if (selections.isEmpty) return const SizedBox.shrink();

                    double categoryTotal = selections.fold(0, (sum, s) => sum + s.totalPrice);

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(slug.replaceAll('-', ' ').toUpperCase(),
                                style: theme.textTheme.labelLarge?.copyWith(
                                    color: theme.colorScheme.primary, fontWeight: FontWeight.bold)),
                            const Spacer(),
                            Text('NPR ${categoryTotal.toStringAsFixed(0)}',
                                style: theme.textTheme.labelLarge?.copyWith(fontWeight: FontWeight.bold)),
                          ],
                        ),
                        const SizedBox(height: 8),
                        ...selections.asMap().entries.map((selEntry) {
                          final idx = selEntry.key;
                          final sel = selEntry.value;
                          return Card(
                            margin: const EdgeInsets.only(bottom: 8),
                            child: Padding(
                              padding: const EdgeInsets.all(12),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(sel.product.name, style: theme.textTheme.titleSmall),
                                        Text('${sel.variant.size} • NPR ${sel.unitPrice.toStringAsFixed(0)} each',
                                            style: theme.textTheme.bodySmall),
                                      ],
                                    ),
                                  ),
                                  QuantityStepper(
                                    value: sel.quantity,
                                    min: 1,
                                    onChanged: (v) => ref.read(wizardProvider.notifier).updateBrandQuantity(slug, idx, v),
                                  ),
                                  const SizedBox(width: 8),
                                  SizedBox(
                                    width: 80,
                                    child: Text(
                                      'NPR ${sel.totalPrice.toStringAsFixed(0)}',
                                      textAlign: TextAlign.right,
                                      style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
                                    ),
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
            ),
            // Bottom bar with total + actions
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: theme.colorScheme.surface,
                boxShadow: [BoxShadow(blurRadius: 8, color: Colors.black.withOpacity(0.08))],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Text('Grand Total', style: theme.textTheme.titleMedium),
                      const Spacer(),
                      Text(
                        'NPR ${wizard.grandTotal.toStringAsFixed(0)}',
                        style: theme.textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.bold, color: theme.colorScheme.primary),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => context.pop(),
                          child: const Text('Back'),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => context.push('/calculator'),
                          child: const Text('Price Calculator'),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: () {
                        // Push all wizard selections to cart, then go to checkout
                        final cart = ref.read(cartProvider.notifier);
                        cart.clear();
                        for (final selections in wizard.brandSelections.values) {
                          for (final sel in selections) {
                            cart.addItem(sel.product, sel.variant, sel.unitType, quantity: sel.quantity);
                          }
                        }
                        context.push('/checkout');
                      },
                      child: const Text('Place Order'),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
