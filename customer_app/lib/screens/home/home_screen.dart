// lib/screens/home/home_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../providers/wizard_provider.dart';
import '../../providers/notification_provider.dart';
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
        title: const Text(
          'RaksiChaiyo',
          style: TextStyle(
            color: Color(0xFFCA8A04),
            fontWeight: FontWeight.w800,
            fontSize: 22,
            letterSpacing: 0.5,
          ),
        ),
        actions: const [CartBadge()],
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Plan your event\nbeverages',
                style: theme.textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: const Color(0xFF0C0A09),
                  height: 1.15,
                )),
            const SizedBox(height: 8),
            Text('We help you estimate and order the right amount.',
                style: theme.textTheme.bodyLarge?.copyWith(color: const Color(0xFFA8A29E))),
            const SizedBox(height: 32),

            // Start order CTA — dark card with gold accent
            Container(
              decoration: BoxDecoration(
                color: const Color(0xFF292524),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF1C1917).withValues(alpha: 0.18),
                    blurRadius: 16,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Material(
                color: Colors.transparent,
                borderRadius: BorderRadius.circular(16),
                child: InkWell(
                  borderRadius: BorderRadius.circular(16),
                  onTap: () {
                    ref.read(wizardProvider.notifier).reset();
                    context.push('/wizard/event');
                  },
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Row(
                      children: [
                        const Icon(Icons.celebration, size: 48, color: Color(0xFFCA8A04)),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Start Your Order',
                                  style: theme.textTheme.titleLarge?.copyWith(
                                    fontWeight: FontWeight.w800,
                                    color: const Color(0xFFFAFAF9),
                                  )),
                              const SizedBox(height: 4),
                              Text('Tell us about your event and we\'ll handle the rest',
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    color: const Color(0xFFA8A29E),
                                  )),
                            ],
                          ),
                        ),
                        const Icon(Icons.arrow_forward, color: Color(0xFFCA8A04)),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Resume wizard if in progress — gold left border accent
            if (hasWizardInProgress)
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: const Border(
                    left: BorderSide(color: Color(0xFFCA8A04), width: 4),
                    top: BorderSide(color: Color(0xFFE7E5E4)),
                    right: BorderSide(color: Color(0xFFE7E5E4)),
                    bottom: BorderSide(color: Color(0xFFE7E5E4)),
                  ),
                ),
                child: ListTile(
                  leading: const Icon(Icons.replay, color: Color(0xFFCA8A04)),
                  title: const Text('Resume your order',
                      style: TextStyle(fontWeight: FontWeight.w600, color: Color(0xFF0C0A09))),
                  subtitle: Text(
                    '${wizard.selectedTypeSlugs.length} types selected • ${wizard.totalPax} guests',
                    style: const TextStyle(color: Color(0xFFA8A29E)),
                  ),
                  trailing: const Icon(Icons.chevron_right, color: Color(0xFFCA8A04)),
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
      bottomNavigationBar: Consumer(
        builder: (context, ref, _) {
          final unreadCount = ref.watch(unreadCountProvider);
          return NavigationBar(
            destinations: [
              const NavigationDestination(icon: Icon(Icons.home), label: 'Home'),
              NavigationDestination(
                icon: Badge(
                  isLabelVisible: unreadCount > 0,
                  label: Text('$unreadCount'),
                  child: const Icon(Icons.receipt_long),
                ),
                label: 'Orders',
              ),
              const NavigationDestination(icon: Icon(Icons.person), label: 'Profile'),
            ],
            onDestinationSelected: (index) {
              switch (index) {
                case 0: context.go('/home');
                case 1: context.go('/orders');
                case 2: context.go('/profile');
              }
            },
          );
        },
      ),
    );
  }
}
