// lib/screens/home/home_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../providers/wizard_provider.dart';
import '../../widgets/cart_badge.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final wizard = ref.watch(wizardProvider);
    final theme = Theme.of(context);
    final hasWizardInProgress = wizard.selectedTypeSlugs.isNotEmpty;

    return Scaffold(
      appBar: AppBar(
        title: const Text('RaksiChaiyo'),
        actions: const [CartBadge()],
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Plan your event\nbeverages',
                style: theme.textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text('We help you estimate and order the right amount.',
                style: theme.textTheme.bodyLarge?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
            const SizedBox(height: 32),

            // Start order CTA
            Card(
              clipBehavior: Clip.antiAlias,
              color: theme.colorScheme.primaryContainer,
              child: InkWell(
                onTap: () {
                  ref.read(wizardProvider.notifier).reset();
                  context.push('/wizard/event');
                },
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Row(
                    children: [
                      Icon(Icons.celebration, size: 48, color: theme.colorScheme.primary),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Start Your Order', style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
                            const SizedBox(height: 4),
                            Text('Tell us about your event and we\'ll handle the rest',
                                style: theme.textTheme.bodyMedium),
                          ],
                        ),
                      ),
                      Icon(Icons.arrow_forward, color: theme.colorScheme.primary),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Resume wizard if in progress
            if (hasWizardInProgress)
              Card(
                child: ListTile(
                  leading: Icon(Icons.replay, color: theme.colorScheme.primary),
                  title: const Text('Resume your order'),
                  subtitle: Text('${wizard.selectedTypeSlugs.length} types selected • ${wizard.totalPax} guests'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => context.push('/wizard/types'),
                ),
              ),
            if (hasWizardInProgress) const SizedBox(height: 16),

            // Secondary actions
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => context.push('/calculator'),
                    icon: const Icon(Icons.calculate),
                    label: const Text('Price Calculator'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => context.push('/category/a1000000-0000-0000-0000-000000000001'),
                    icon: const Icon(Icons.local_bar),
                    label: const Text('Browse Catalog'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
      bottomNavigationBar: NavigationBar(
        destinations: const [
          NavigationDestination(icon: Icon(Icons.home), label: 'Home'),
          NavigationDestination(icon: Icon(Icons.receipt_long), label: 'Orders'),
          NavigationDestination(icon: Icon(Icons.person), label: 'Profile'),
        ],
        onDestinationSelected: (index) {
          switch (index) {
            case 0: context.go('/home');
            case 1: context.go('/orders');
            case 2: context.go('/profile');
          }
        },
      ),
    );
  }
}
