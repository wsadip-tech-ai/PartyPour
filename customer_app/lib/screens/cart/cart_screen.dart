import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../providers/cart_provider.dart';

class CartScreen extends ConsumerWidget {
  const CartScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cartItems = ref.watch(cartProvider);
    final total = ref.watch(cartTotalProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Cart')),
      body: cartItems.isEmpty
          ? const Center(child: Text('Your cart is empty'))
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: cartItems.length,
              itemBuilder: (context, index) {
                final item = cartItems[index];
                return Card(
                  child: ListTile(
                    title: Text(item.product.name),
                    subtitle: Text('${item.variant.size} x ${item.quantity} ${item.unitType}(s)\nNPR ${item.totalPrice.toStringAsFixed(0)}'),
                    isThreeLine: true,
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(icon: const Icon(Icons.remove), onPressed: () => ref.read(cartProvider.notifier).updateQuantity(index, item.quantity - 1)),
                        Text('${item.quantity}'),
                        IconButton(icon: const Icon(Icons.add), onPressed: () => ref.read(cartProvider.notifier).updateQuantity(index, item.quantity + 1)),
                      ],
                    ),
                  ),
                );
              },
            ),
      bottomNavigationBar: cartItems.isEmpty ? null : Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(color: Theme.of(context).colorScheme.surface, boxShadow: [BoxShadow(blurRadius: 8, color: Colors.black12)]),
        child: Row(
          children: [
            Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Total', style: Theme.of(context).textTheme.bodySmall),
              Text('NPR ${total.toStringAsFixed(0)}', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
            ]),
            const Spacer(),
            FilledButton(onPressed: () => context.push('/checkout'), child: const Text('Checkout')),
          ],
        ),
      ),
    );
  }
}
