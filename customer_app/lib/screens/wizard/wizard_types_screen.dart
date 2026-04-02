// lib/screens/wizard/wizard_types_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../providers/wizard_provider.dart';
import '../../models/estimation_rule.dart';
import '../../widgets/step_progress.dart';
import '../../widgets/type_selector_card.dart';

class WizardTypesScreen extends ConsumerStatefulWidget {
  const WizardTypesScreen({super.key});

  @override
  ConsumerState<WizardTypesScreen> createState() => _WizardTypesScreenState();
}

class _WizardTypesScreenState extends ConsumerState<WizardTypesScreen> {
  bool _initialized = false;

  static const _defaultsByEventType = {
    'wedding': ['whiskey', 'beer-bottle-can', 'wine', 'carbonated', 'water', 'ice-garnish'],
    'birthday': ['beer-bottle-can', 'carbonated', 'juice', 'water', 'ice-garnish'],
    'corporate': ['whiskey', 'beer-bottle-can', 'wine', 'carbonated', 'water'],
    'house_party': ['whiskey', 'vodka', 'beer-bottle-can', 'carbonated', 'water', 'ice-garnish'],
    'anniversary': ['whiskey', 'wine', 'beer-bottle-can', 'carbonated', 'water', 'ice-garnish'],
  };

  static const _iconMap = {
    'local_bar': Icons.local_bar,
    'wine_bar': Icons.wine_bar,
    'sports_bar': Icons.sports_bar,
    'local_fire_department': Icons.local_fire_department,
    'bolt': Icons.bolt,
    'blender': Icons.blender,
    'local_cafe': Icons.local_cafe,
    'water_drop': Icons.water_drop,
    'ac_unit': Icons.ac_unit,
  };

  @override
  Widget build(BuildContext context) {
    final wizard = ref.watch(wizardProvider);
    final rulesAsync = ref.watch(estimationRulesProvider);
    final theme = Theme.of(context);

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            const StepProgress(currentStep: 2),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Text('What beverages do you need?',
                  style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: rulesAsync.when(
                data: (rules) {
                  // Pre-select defaults on first load
                  if (!_initialized && wizard.selectedTypeSlugs.isEmpty) {
                    _initialized = true;
                    final defaults = _defaultsByEventType[wizard.eventType] ?? [];
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      ref.read(wizardProvider.notifier).setSelectedTypes(defaults);
                    });
                  }

                  return GridView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                      childAspectRatio: 1.3,
                    ),
                    itemCount: rules.length,
                    itemBuilder: (context, index) {
                      final rule = rules[index];
                      return TypeSelectorCard(
                        label: rule.label,
                        icon: _iconMap[rule.iconName] ?? Icons.local_drink,
                        isSelected: wizard.selectedTypeSlugs.contains(rule.subcategorySlug),
                        onTap: () => ref.read(wizardProvider.notifier).toggleType(rule.subcategorySlug),
                      );
                    },
                  );
                },
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (err, _) => Center(child: Text('Error: $err')),
              ),
            ),
            // Bottom bar
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: theme.colorScheme.surface,
                boxShadow: [BoxShadow(blurRadius: 8, color: Colors.black.withOpacity(0.05))],
              ),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => context.pop(),
                      child: const Text('Back'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: FilledButton(
                      onPressed: wizard.selectedTypeSlugs.isEmpty
                          ? null
                          : () => context.push('/wizard/quantities'),
                      child: Text('Next — ${wizard.selectedTypeSlugs.length} selected'),
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
