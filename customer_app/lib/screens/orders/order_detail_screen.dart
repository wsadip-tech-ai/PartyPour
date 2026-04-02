import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/order_provider.dart';

// Timeline steps in order — cancelled is a side-branch handled separately
const _timelineSteps = ['pending', 'confirmed', 'dispatched', 'delivered'];

const Map<String, Color> _statusColor = {
  'pending':    Color(0xFFF97316),
  'confirmed':  Color(0xFF22C55E),
  'dispatched': Color(0xFF3B82F6),
  'delivered':  Color(0xFF8B5CF6),
  'cancelled':  Color(0xFFEF4444),
};

const Map<String, String> _statusLabel = {
  'pending':    'Awaiting Confirmation',
  'confirmed':  'Order Confirmed',
  'dispatched': 'On the Way',
  'delivered':  'Delivered',
  'cancelled':  'Cancelled',
};

const Map<String, IconData> _statusIcon = {
  'pending':    Icons.hourglass_empty_rounded,
  'confirmed':  Icons.check_circle_outline_rounded,
  'dispatched': Icons.local_shipping_outlined,
  'delivered':  Icons.done_all_rounded,
  'cancelled':  Icons.cancel_outlined,
};

const Map<String, String> _timelineLabel = {
  'pending':    'Order Placed',
  'confirmed':  'Confirmed',
  'dispatched': 'On the Way',
  'delivered':  'Delivered',
};

class OrderDetailScreen extends ConsumerWidget {
  final String orderId;
  const OrderDetailScreen({super.key, required this.orderId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final orderAsync = ref.watch(orderDetailProvider(orderId));
    return Scaffold(
      appBar: AppBar(title: const Text('Order Details')),
      body: orderAsync.when(
        data: (order) {
          final status = order.status;
          final isCancelled = status == 'cancelled';
          final bannerColor = _statusColor[status] ?? Colors.grey;
          final bannerLabel = _statusLabel[status] ?? status.toUpperCase();
          final bannerIcon  = _statusIcon[status]  ?? Icons.info_outline;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Status banner ──────────────────────────────────────────
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
                  decoration: BoxDecoration(
                    color: bannerColor.withOpacity(0.1),
                    border: Border.all(color: bannerColor.withOpacity(0.4), width: 1.5),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: bannerColor.withOpacity(0.18),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(bannerIcon, color: bannerColor, size: 24),
                      ),
                      const SizedBox(width: 14),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Status',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: bannerColor.withOpacity(0.7),
                              letterSpacing: 1.2,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            bannerLabel,
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: bannerColor,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                // ── Status timeline ────────────────────────────────────────
                if (!isCancelled) _StatusTimeline(currentStatus: status),
                if (isCancelled)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEF4444).withOpacity(0.07),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Text(
                      'This order was cancelled and will not be processed.',
                      style: TextStyle(color: Color(0xFFEF4444), fontSize: 13),
                    ),
                  ),

                const SizedBox(height: 20),

                // ── Order info card ────────────────────────────────────────
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (order.eventType != null) _InfoRow('Event', order.eventType!),
                        if (order.eventDate != null)
                          _InfoRow('Date', '${order.eventDate!.day}/${order.eventDate!.month}/${order.eventDate!.year}'),
                        if (order.guestCount != null) _InfoRow('Guests', '${order.guestCount}'),
                        if (order.deliveryAddress != null) _InfoRow('Delivery', order.deliveryAddress!),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                Text('Items', style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 8),

                ...order.items.map((item) => Card(
                  child: ListTile(
                    title: Text('Variant: ${item.variantId.substring(0, 8)}'),
                    subtitle: Text('${item.quantity} ${item.unitType}(s)'),
                    trailing: Text('NPR ${item.totalPrice.toStringAsFixed(0)}'),
                  ),
                )),

                const SizedBox(height: 16),

                // ── Totals card ────────────────────────────────────────────
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Subtotal'),
                            Text('NPR ${order.totalAmount.toStringAsFixed(0)}'),
                          ],
                        ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Discount'),
                            Text('- NPR ${order.discountAmount.toStringAsFixed(0)}'),
                          ],
                        ),
                        const Divider(),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('Total', style: Theme.of(context).textTheme.titleMedium),
                            Text(
                              'NPR ${order.finalAmount.toStringAsFixed(0)}',
                              style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(child: Text('Error: $err')),
      ),
    );
  }
}

// ── Helpers ──────────────────────────────────────────────────────────────────

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  const _InfoRow(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text('$label:', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
          ),
          Expanded(child: Text(value, style: const TextStyle(fontSize: 13))),
        ],
      ),
    );
  }
}

class _StatusTimeline extends StatelessWidget {
  final String currentStatus;
  const _StatusTimeline({required this.currentStatus});

  @override
  Widget build(BuildContext context) {
    final currentIndex = _timelineSteps.indexOf(currentStatus);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 16),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: List.generate(_timelineSteps.length * 2 - 1, (i) {
          // Even indices are step nodes, odd indices are connectors
          if (i.isOdd) {
            final stepIndex = i ~/ 2;
            final isPast = stepIndex < currentIndex;
            return Expanded(
              child: Container(
                height: 2,
                color: isPast ? const Color(0xFF22C55E) : Colors.grey.shade300,
              ),
            );
          }

          final stepIndex = i ~/ 2;
          final stepStatus = _timelineSteps[stepIndex];
          final isPast    = stepIndex < currentIndex;
          final isCurrent = stepIndex == currentIndex;
          final isFuture  = stepIndex > currentIndex;

          final nodeColor = isCurrent
              ? (_statusColor[stepStatus] ?? Colors.grey)
              : isPast
                  ? const Color(0xFF22C55E)
                  : Colors.grey.shade300;

          return Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isFuture ? Colors.transparent : nodeColor.withOpacity(isCurrent ? 0.15 : 1.0),
                  border: Border.all(
                    color: isFuture ? Colors.grey.shade300 : nodeColor,
                    width: isCurrent ? 2.5 : 1.5,
                  ),
                ),
                child: Icon(
                  isPast
                      ? Icons.check_rounded
                      : (_statusIcon[stepStatus] ?? Icons.circle),
                  size: 16,
                  color: isFuture
                      ? Colors.grey.shade400
                      : isCurrent
                          ? nodeColor
                          : Colors.white,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                _timelineLabel[stepStatus] ?? stepStatus,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: isCurrent ? FontWeight.bold : FontWeight.normal,
                  color: isFuture ? Colors.grey.shade400 : nodeColor,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          );
        }),
      ),
    );
  }
}
