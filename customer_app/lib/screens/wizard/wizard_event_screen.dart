// lib/screens/wizard/wizard_event_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../providers/wizard_provider.dart';
import '../../widgets/step_progress.dart';
import '../../widgets/quantity_stepper.dart';

class WizardEventScreen extends ConsumerWidget {
  const WizardEventScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final wizard = ref.watch(wizardProvider);
    final theme = Theme.of(context);

    final eventTypes = [
      ('wedding', 'Wedding', Icons.favorite),
      ('birthday', 'Birthday', Icons.cake),
      ('corporate', 'Corporate', Icons.business),
      ('house_party', 'House Party', Icons.home),
      ('anniversary', 'Anniversary', Icons.celebration),
      ('other', 'Other', Icons.event),
    ];

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            const StepProgress(currentStep: 1),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Tell us about your event',
                        style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 32),

                    // Total Guests
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Row(
                          children: [
                            Icon(Icons.groups, color: theme.colorScheme.primary),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('Total Guests', style: theme.textTheme.titleMedium),
                                  Text('Including children', style: theme.textTheme.bodySmall),
                                ],
                              ),
                            ),
                            QuantityStepper(
                              value: wizard.totalPax,
                              min: 10,
                              max: 2000,
                              onChanged: (v) => ref.read(wizardProvider.notifier).setTotalPax(v),
                              large: true,
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Children
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Row(
                          children: [
                            Icon(Icons.child_care, color: theme.colorScheme.primary),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('Children', style: theme.textTheme.titleMedium),
                                  Text('Included in total guests (optional)', style: theme.textTheme.bodySmall),
                                ],
                              ),
                            ),
                            QuantityStepper(
                              value: wizard.childrenCount,
                              min: 0,
                              max: wizard.totalPax,
                              onChanged: (v) => ref.read(wizardProvider.notifier).setChildrenCount(v),
                              large: true,
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Event Type
                    Text('Event Type', style: theme.textTheme.titleMedium),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: eventTypes.map((e) => ChoiceChip(
                        avatar: Icon(e.$3, size: 18),
                        label: Text(e.$2),
                        selected: wizard.eventType == e.$1,
                        onSelected: (_) => ref.read(wizardProvider.notifier).setEventType(e.$1),
                      )).toList(),
                    ),
                    const SizedBox(height: 24),

                    // Event Date
                    Card(
                      child: ListTile(
                        leading: Icon(Icons.calendar_today, color: theme.colorScheme.primary),
                        title: Text(wizard.eventDate == null
                            ? 'Select Event Date'
                            : '${wizard.eventDate!.day}/${wizard.eventDate!.month}/${wizard.eventDate!.year}'),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () async {
                          final date = await showDatePicker(
                            context: context,
                            initialDate: DateTime.now().add(const Duration(days: 7)),
                            firstDate: DateTime.now(),
                            lastDate: DateTime.now().add(const Duration(days: 365)),
                          );
                          if (date != null) {
                            ref.read(wizardProvider.notifier).setEventDate(date);
                          }
                        },
                      ),
                    ),
                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),
            // Bottom bar
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: theme.colorScheme.surface,
                boxShadow: [BoxShadow(blurRadius: 8, color: Colors.black.withOpacity(0.05))],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: () => context.push('/wizard/types'),
                      child: const Text('Next — Select Beverages'),
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextButton(
                    onPressed: () => context.push('/category/a1000000-0000-0000-0000-000000000001'),
                    child: const Text('Browse Catalog Instead'),
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
