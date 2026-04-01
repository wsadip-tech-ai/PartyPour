import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/planner_provider.dart';
import '../../providers/cart_provider.dart';

class PlannerScreen extends ConsumerWidget {
  const PlannerScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final planner = ref.watch(plannerProvider);
    final eventTypes = ['wedding', 'birthday', 'anniversary', 'corporate', 'house_party'];
    return Scaffold(
      appBar: AppBar(title: const Text('Plan My Event')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('How many guests?', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            Row(children: [Expanded(child: Slider(value: planner.guestCount.toDouble(), min: 20, max: 1000, divisions: 98, label: '${planner.guestCount}', onChanged: (v) => ref.read(plannerProvider.notifier).setGuestCount(v.round()))), Text('${planner.guestCount}', style: Theme.of(context).textTheme.titleLarge)]),
            const SizedBox(height: 16),
            Text('Event type', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            Wrap(spacing: 8, children: eventTypes.map((type) => ChoiceChip(label: Text(type.replaceAll('_', ' ')), selected: planner.eventType == type, onSelected: (_) => ref.read(plannerProvider.notifier).setEventType(type))).toList()),
            const SizedBox(height: 24),
            SizedBox(width: double.infinity, child: FilledButton(onPressed: () { ref.read(plannerProvider.notifier).calculate([]); }, child: const Text('Calculate'))),
            const SizedBox(height: 24),
            if (planner.suggestions.isNotEmpty) ...[
              Text('Suggested Beverages', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 12),
              ...planner.suggestions.map((s) => Card(
                child: ListTile(
                  title: Text(s.product.name),
                  subtitle: Text('${s.quantity} ${s.unitType}(s) - ${s.reason}'),
                  trailing: IconButton(
                    icon: const Icon(Icons.add_shopping_cart),
                    onPressed: () {
                      final variant = s.product.variants.firstWhere((v) => v.id == s.variantId);
                      ref.read(cartProvider.notifier).addItem(s.product, variant, s.unitType, quantity: s.quantity);
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('${s.product.name} added to cart')));
                    },
                  ),
                ),
              )),
              const SizedBox(height: 16),
              SizedBox(width: double.infinity, child: OutlinedButton(
                onPressed: () {
                  for (final s in planner.suggestions) {
                    final variant = s.product.variants.firstWhere((v) => v.id == s.variantId);
                    ref.read(cartProvider.notifier).addItem(s.product, variant, s.unitType, quantity: s.quantity);
                  }
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('All suggestions added to cart')));
                },
                child: const Text('Add All to Cart'),
              )),
            ],
          ],
        ),
      ),
    );
  }
}
