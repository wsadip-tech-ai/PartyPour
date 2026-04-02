import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../providers/order_provider.dart';

class OrderHistoryScreen extends ConsumerWidget {
  const OrderHistoryScreen({super.key});

  static const Map<String, Color> _statusColor = {
    'pending':    Color(0xFFF97316), // orange
    'confirmed':  Color(0xFF22C55E), // green
    'dispatched': Color(0xFF3B82F6), // blue
    'delivered':  Color(0xFF8B5CF6), // purple
    'cancelled':  Color(0xFFEF4444), // red
  };

  static const Map<String, String> _statusLabel = {
    'pending':    'Awaiting Confirmation',
    'confirmed':  'Order Confirmed',
    'dispatched': 'On the Way',
    'delivered':  'Delivered',
    'cancelled':  'Cancelled',
  };

  static const Map<String, IconData> _statusIcon = {
    'pending':    Icons.hourglass_empty_rounded,
    'confirmed':  Icons.check_circle_outline_rounded,
    'dispatched': Icons.local_shipping_outlined,
    'delivered':  Icons.done_all_rounded,
    'cancelled':  Icons.cancel_outlined,
  };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ordersAsync = ref.watch(orderHistoryProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('My Orders')),
      body: ordersAsync.when(
        data: (orders) => orders.isEmpty
            ? const Center(child: Text('No orders yet'))
            : ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: orders.length,
                itemBuilder: (context, index) {
                  final order = orders[index];
                  final status = order.status;
                  final color = _statusColor[status] ?? Colors.grey;
                  final label = _statusLabel[status] ?? status.toUpperCase();
                  final icon  = _statusIcon[status]  ?? Icons.info_outline;

                  return Card(
                    margin: const EdgeInsets.only(bottom: 12),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(12),
                      onTap: () => context.push('/order/${order.id}'),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Order #${order.id.substring(0, 8)}',
                                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                // Colored status badge
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: color.withOpacity(0.12),
                                    border: Border.all(color: color.withOpacity(0.5)),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(icon, size: 13, color: color),
                                      const SizedBox(width: 5),
                                      Text(
                                        label,
                                        style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600,
                                          color: color,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              '${order.eventType ?? 'Event'}  •  NPR ${order.finalAmount.toStringAsFixed(0)}',
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(child: Text('Error: $err')),
      ),
    );
  }
}
