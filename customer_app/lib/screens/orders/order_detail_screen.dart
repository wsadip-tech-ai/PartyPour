import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/order_provider.dart';

class OrderDetailScreen extends ConsumerWidget {
  final String orderId;
  const OrderDetailScreen({super.key, required this.orderId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final orderAsync = ref.watch(orderDetailProvider(orderId));
    return Scaffold(
      appBar: AppBar(title: const Text('Order Details')),
      body: orderAsync.when(
        data: (order) => SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Card(child: Padding(padding: const EdgeInsets.all(16), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('Status: ${order.status.toUpperCase()}', style: Theme.of(context).textTheme.titleMedium),
                if (order.eventType != null) Text('Event: ${order.eventType}'),
                if (order.eventDate != null) Text('Date: ${order.eventDate!.day}/${order.eventDate!.month}/${order.eventDate!.year}'),
                if (order.guestCount != null) Text('Guests: ${order.guestCount}'),
                if (order.deliveryAddress != null) Text('Delivery: ${order.deliveryAddress}'),
              ]))),
              const SizedBox(height: 16),
              Text('Items', style: Theme.of(context).textTheme.titleMedium),
              ...order.items.map((item) => Card(child: ListTile(
                title: Text('Variant: ${item.variantId.substring(0, 8)}'),
                subtitle: Text('${item.quantity} ${item.unitType}(s)'),
                trailing: Text('NPR ${item.totalPrice.toStringAsFixed(0)}'),
              ))),
              const SizedBox(height: 16),
              Card(child: Padding(padding: const EdgeInsets.all(16), child: Column(children: [
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [const Text('Subtotal'), Text('NPR ${order.totalAmount.toStringAsFixed(0)}')]),
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [const Text('Discount'), Text('- NPR ${order.discountAmount.toStringAsFixed(0)}')]),
                const Divider(),
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                  Text('Total', style: Theme.of(context).textTheme.titleMedium),
                  Text('NPR ${order.finalAmount.toStringAsFixed(0)}', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                ]),
              ]))),
            ],
          ),
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(child: Text('Error: $err')),
      ),
    );
  }
}
