import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../providers/order_provider.dart';
import '../../providers/notification_provider.dart';
import '../../models/order.dart';

const _gold = Color(0xFFCA8A04);
const _darkBg = Color(0xFF1C1917);
const _surfaceDark = Color(0xFF292524);
const _textLight = Color(0xFFFAFAF9);
const _muted = Color(0xFF78716C);
const _mutedLight = Color(0xFFA8A29E);
const _border = Color(0xFF44403C);

const _statusColors = {
  'pending': Color(0xFFFB923C),
  'confirmed': Color(0xFF4ade80),
  'dispatched': Color(0xFF60a5fa),
  'delivered': Color(0xFFc084fc),
  'cancelled': Color(0xFFEF4444),
};

const _statusLabels = {
  'pending': 'Awaiting Confirmation',
  'confirmed': 'Confirmed',
  'dispatched': 'On the Way',
  'delivered': 'Delivered',
  'cancelled': 'Cancelled',
};

const _statusIcons = {
  'pending': Icons.hourglass_empty_rounded,
  'confirmed': Icons.check_circle_outline_rounded,
  'dispatched': Icons.local_shipping_outlined,
  'delivered': Icons.done_all_rounded,
  'cancelled': Icons.cancel_outlined,
};

// Progress step index per status (0-3)
const _statusStep = {'pending': 0, 'confirmed': 1, 'dispatched': 2, 'delivered': 3};

class OrderHistoryScreen extends ConsumerWidget {
  const OrderHistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ordersAsync = ref.watch(orderHistoryProvider);

    return Scaffold(
      backgroundColor: _darkBg,
      appBar: AppBar(
        backgroundColor: _darkBg,
        title: const Text('My Orders', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: _textLight)),
        actions: [
          Consumer(builder: (context, ref, _) {
            final unread = ref.watch(unreadCountProvider);
            return IconButton(
              onPressed: () => context.push('/notifications'),
              icon: Badge(
                isLabelVisible: unread > 0,
                label: Text('$unread'),
                backgroundColor: _gold,
                child: const Icon(Icons.notifications_outlined, color: _muted),
              ),
            );
          }),
        ],
      ),
      body: ordersAsync.when(
        data: (orders) {
          if (orders.isEmpty) return _buildEmpty(context);

          final active = orders.where((o) => o.status != 'delivered' && o.status != 'cancelled').toList();
          final past = orders.where((o) => o.status == 'delivered' || o.status == 'cancelled').toList();

          return SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Active orders
                if (active.isNotEmpty) ...[
                  const Text('ACTIVE ORDERS', style: TextStyle(fontSize: 11, color: _gold, fontWeight: FontWeight.w700, letterSpacing: 1.0)),
                  const SizedBox(height: 10),
                  ...active.map((order) => _ActiveOrderCard(order: order)),
                ],

                // Past orders
                if (past.isNotEmpty) ...[
                  Padding(
                    padding: EdgeInsets.only(top: active.isNotEmpty ? 16 : 0),
                    child: const Text('PAST ORDERS', style: TextStyle(fontSize: 11, color: _muted, fontWeight: FontWeight.w700, letterSpacing: 1.0)),
                  ),
                  const SizedBox(height: 10),
                  ...past.map((order) => _PastOrderCard(order: order)),
                ],
              ],
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator(color: _gold)),
        error: (err, _) => Center(child: Text('Error: $err', style: const TextStyle(color: _muted))),
      ),
      bottomNavigationBar: Consumer(builder: (context, ref, _) {
        final unread = ref.watch(unreadCountProvider);
        return NavigationBar(
          destinations: [
            const NavigationDestination(icon: Icon(Icons.home), label: 'Home'),
            NavigationDestination(
              icon: Badge(isLabelVisible: unread > 0, label: Text('$unread'), backgroundColor: _gold, child: const Icon(Icons.receipt_long)),
              label: 'Orders',
            ),
            const NavigationDestination(icon: Icon(Icons.person), label: 'Profile'),
          ],
          selectedIndex: 1,
          onDestinationSelected: (i) {
            switch (i) {
              case 0: context.go('/home');
              case 1: context.go('/orders');
              case 2: context.go('/profile');
            }
          },
        );
      }),
    );
  }

  Widget _buildEmpty(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.receipt_long_outlined, size: 64, color: _border),
          const SizedBox(height: 16),
          const Text('No orders yet', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: _mutedLight)),
          const SizedBox(height: 8),
          const Text('Place your first order to see it here', style: TextStyle(fontSize: 13, color: _muted)),
          const SizedBox(height: 24),
          GestureDetector(
            onTap: () => context.go('/home'),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
              decoration: BoxDecoration(gradient: const LinearGradient(colors: [_gold, Color(0xFFEAB308)]), borderRadius: BorderRadius.circular(14)),
              child: const Text('Start Your Order', style: TextStyle(color: _darkBg, fontWeight: FontWeight.w700, fontSize: 14)),
            ),
          ),
        ],
      ),
    );
  }
}

// === Active Order Card with progress bar ===
class _ActiveOrderCard extends StatelessWidget {
  final Order order;
  const _ActiveOrderCard({required this.order});

  @override
  Widget build(BuildContext context) {
    final color = _statusColors[order.status] ?? _gold;
    final label = _statusLabels[order.status] ?? order.status;
    final icon = _statusIcons[order.status] ?? Icons.info_outline;
    final step = _statusStep[order.status] ?? 0;

    return GestureDetector(
      onTap: () => context.push('/order/${order.id}'),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        decoration: BoxDecoration(
          color: _surfaceDark,
          border: Border(left: BorderSide(color: color, width: 3)),
          borderRadius: const BorderRadius.only(topRight: Radius.circular(14), bottomRight: Radius.circular(14)),
        ),
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top: ID + status
            Row(
              children: [
                Expanded(child: Text('Order #${order.id.substring(0, 8)}', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: _textLight))),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.12),
                    border: Border.all(color: color.withValues(alpha: 0.3)),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    Icon(icon, size: 12, color: color),
                    const SizedBox(width: 4),
                    Text(label, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: color)),
                  ]),
                ),
              ],
            ),
            const SizedBox(height: 6),
            // Mid: event + date
            Row(
              children: [
                Text('${order.eventType ?? 'Event'} • ${order.guestCount ?? ''} guests', style: const TextStyle(fontSize: 12, color: _mutedLight)),
                const Spacer(),
                if (order.eventDate != null)
                  Text('${order.eventDate!.day}/${order.eventDate!.month}/${order.eventDate!.year}', style: const TextStyle(fontSize: 11, color: _muted)),
              ],
            ),
            const SizedBox(height: 8),
            // Amount
            Text('NPR ${order.finalAmount.toStringAsFixed(0)}', style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: _gold)),
            const SizedBox(height: 10),
            // Progress bar
            Row(
              children: List.generate(4, (i) {
                Color segColor;
                if (i < step) {
                  segColor = const Color(0xFF4ade80); // done
                } else if (i == step) {
                  segColor = color; // current
                } else {
                  segColor = _border; // future
                }
                return Expanded(
                  child: Container(
                    height: 3,
                    margin: EdgeInsets.only(right: i < 3 ? 4 : 0),
                    decoration: BoxDecoration(color: segColor, borderRadius: BorderRadius.circular(2)),
                  ),
                );
              }),
            ),
          ],
        ),
      ),
    );
  }
}

// === Past Order Card (compact) ===
class _PastOrderCard extends StatelessWidget {
  final Order order;
  const _PastOrderCard({required this.order});

  @override
  Widget build(BuildContext context) {
    final color = _statusColors[order.status] ?? _muted;
    final isDelivered = order.status == 'delivered';

    return GestureDetector(
      onTap: () => context.push('/order/${order.id}'),
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(color: _surfaceDark, border: Border.all(color: _border), borderRadius: BorderRadius.circular(12)),
        child: Row(
          children: [
            Container(
              width: 36, height: 36,
              decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)),
              child: Icon(isDelivered ? Icons.done_all_rounded : Icons.cancel_outlined, size: 16, color: color),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Order #${order.id.substring(0, 8)}', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: _textLight)),
                  Text(
                    '${order.eventType ?? 'Event'} • ${order.createdAt.day}/${order.createdAt.month} • ${isDelivered ? 'Delivered' : 'Cancelled'}',
                    style: const TextStyle(fontSize: 11, color: _muted),
                  ),
                ],
              ),
            ),
            Text('NPR ${order.finalAmount.toStringAsFixed(0)}', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: _gold)),
            const SizedBox(width: 4),
            const Icon(Icons.chevron_right, size: 16, color: _muted),
          ],
        ),
      ),
    );
  }
}
