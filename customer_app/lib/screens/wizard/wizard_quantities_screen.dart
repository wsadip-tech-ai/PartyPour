// lib/screens/wizard/wizard_quantities_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../providers/wizard_provider.dart';
import '../../widgets/step_progress.dart';
import '../../widgets/quantity_stepper.dart';

class WizardQuantitiesScreen extends ConsumerStatefulWidget {
  const WizardQuantitiesScreen({super.key});

  @override
  ConsumerState<WizardQuantitiesScreen> createState() => _WizardQuantitiesScreenState();
}

class _WizardQuantitiesScreenState extends ConsumerState<WizardQuantitiesScreen> {
  bool _calculated = false;

  @override
  Widget build(BuildContext context) {
    final wizard = ref.watch(wizardProvider);
    final rulesAsync = ref.watch(estimationRulesProvider);
    final theme = Theme.of(context);

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            const StepProgress(currentStep: 3),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Estimated quantities',
                      style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  Text(
                    '${wizard.totalPax} guests • ${wizard.eventType.replaceAll('_', ' ')}',
                    style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: rulesAsync.when(
                data: (rules) {
                  // Calculate on first load
                  if (!_calculated) {
                    _calculated = true;
                    WidgetsBinding.instance.addPostFrameCallback((_) async {
                      final quantities = await ref.read(estimationServiceProvider).estimateQuantities(
                        totalPax: wizard.totalPax,
                        children: wizard.childrenCount,
                        eventType: wizard.eventType,
                        selectedSlugs: wizard.selectedTypeSlugs,
                      );
                      ref.read(wizardProvider.notifier).setEstimatedQuantities(quantities);
                    });
                  }

                  final selectedRules = rules
                      .where((r) => wizard.selectedTypeSlugs.contains(r.subcategorySlug))
                      .toList();

                  return ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    itemCount: selectedRules.length,
                    itemBuilder: (context, index) {
                      final rule = selectedRules[index];
                      final qty = wizard.estimatedQuantities[rule.subcategorySlug] ?? 0;
                      final servings = qty * rule.servingsPerBottle;

                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(rule.label, style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
                                    const SizedBox(height: 4),
                                    Text(
                                      '~${servings.round()} servings for ${wizard.totalPax} guests',
                                      style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                                    ),
                                  ],
                                ),
                              ),
                              QuantityStepper(
                                value: qty,
                                min: 0,
                                onChanged: (v) => ref.read(wizardProvider.notifier).updateQuantity(rule.subcategorySlug, v),
                                large: true,
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  );
                },
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (err, _) => Center(child: Text('Error: $err')),
              ),
            ),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF1C1917),
                boxShadow: [BoxShadow(blurRadius: 12, color: Colors.black.withValues(alpha: 0.2))],
              ),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => context.pop(),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFFCA8A04),
                        side: const BorderSide(color: Color(0xFFCA8A04)),
                      ),
                      child: const Text('Back'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: FilledButton(
                      onPressed: () => context.push('/wizard/brands'),
                      child: const Text('Confirm Quantities'),
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
