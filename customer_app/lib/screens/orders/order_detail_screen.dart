import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../providers/order_provider.dart';

const _gold = Color(0xFFCA8A04);
const _darkBg = Color(0xFF1C1917);
const _surfaceDark = Color(0xFF292524);
const _textLight = Color(0xFFFAFAF9);
const _muted = Color(0xFF78716C);
const _mutedLight = Color(0xFFA8A29E);
const _border = Color(0xFF44403C);
const _green = Color(0xFF4ade80);

const _steps = ['pending', 'confirmed', 'dispatched', 'delivered'];
const _stepLabels = {'pending': 'Placed', 'confirmed': 'Confirmed', 'dispatched': 'On the Way', 'delivered': 'Delivered'};
const _statusColors = {'pending': Color(0xFFFB923C), 'confirmed': Color(0xFF4ade80), 'dispatched': Color(0xFF60a5fa), 'delivered': Color(0xFFc084fc), 'cancelled': Color(0xFFEF4444)};
const _statusLabels = {'pending': 'Awaiting Confirmation', 'confirmed': 'Order Confirmed', 'dispatched': 'On the Way', 'delivered': 'Delivered', 'cancelled': 'Cancelled'};
const _statusDescs = {'pending': 'Your order is being reviewed', 'confirmed': "We're preparing your beverages", 'dispatched': 'Your order is on its way!', 'delivered': 'Your order has been delivered', 'cancelled': 'This order was cancelled'};
const _statusIcons = {'pending': Icons.hourglass_empty_rounded, 'confirmed': Icons.check_circle_outline_rounded, 'dispatched': Icons.local_shipping_outlined, 'delivered': Icons.done_all_rounded, 'cancelled': Icons.cancel_outlined};

class OrderDetailScreen extends ConsumerWidget {
  final String orderId;
  const OrderDetailScreen({super.key, required this.orderId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final orderAsync = ref.watch(orderDetailProvider(orderId));

    return Scaffold(
      backgroundColor: _darkBg,
      appBar: AppBar(
        backgroundColor: _darkBg,
        leading: IconButton(icon: const Icon(Icons.arrow_back, color: _mutedLight), onPressed: () => context.canPop() ? context.pop() : context.go('/home')),
        title: const Text('Order Details', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: _textLight)),
      ),
      body: orderAsync.when(
        data: (order) {
          final status = order.status;
          final color = _statusColors[status] ?? _gold;
          final isCancelled = status == 'cancelled';
          final currentStep = _steps.indexOf(status).clamp(0, 3);

          return SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // === STATUS BANNER ===
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.08),
                    border: Border.all(color: color.withValues(alpha: 0.2)),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 36, height: 36,
                        decoration: BoxDecoration(color: color.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(10)),
                        child: Icon(_statusIcons[status] ?? Icons.info_outline, size: 18, color: color),
                      ),
                      const SizedBox(width: 10),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(_statusLabels[status] ?? status, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: color)),
                          Text(_statusDescs[status] ?? '', style: const TextStyle(fontSize: 11, color: _mutedLight)),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // === VISUAL DOT TIMELINE ===
                if (!isCancelled)
                  SizedBox(
                    height: 64,
                    child: Row(
                      children: List.generate(7, (i) {
                        // Dots at 0, 2, 4, 6 — lines at 1, 3, 5
                        if (i.isOdd) {
                          final lineIdx = i ~/ 2;
                          final isDone = lineIdx < currentStep;
                          return Expanded(child: Container(height: 2, color: isDone ? _green : _border));
                        }
                        final stepIdx = i ~/ 2;
                        final isDone = stepIdx < currentStep;
                        final isCurrent = stepIdx == currentStep;
                        final stepLabel = _stepLabels[_steps[stepIdx]] ?? '';

                        return Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 28, height: 28,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: isDone ? _green : isCurrent ? color : _surfaceDark,
                                border: isCurrent ? null : Border.all(color: isDone ? _green : _border, width: 1.5),
                                boxShadow: isCurrent ? [BoxShadow(color: color.withValues(alpha: 0.4), blurRadius: 10)] : null,
                              ),
                              child: Center(child: isDone || isCurrent
                                  ? const Icon(Icons.check, size: 14, color: _darkBg)
                                  : Text('${stepIdx + 1}', style: const TextStyle(fontSize: 10, color: _muted))),
                            ),
                            const SizedBox(height: 6),
                            Text(stepLabel, style: TextStyle(
                              fontSize: 9,
                              fontWeight: isCurrent ? FontWeight.w600 : FontWeight.w400,
                              color: isDone ? _green : isCurrent ? color : _muted,
                            )),
                          ],
                        );
                      }),
                    ),
                  ),

                if (isCancelled)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEF4444).withValues(alpha: 0.08),
                      border: Border.all(color: const Color(0xFFEF4444).withValues(alpha: 0.2)),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Text('This order was cancelled and will not be processed.', style: TextStyle(color: Color(0xFFEF4444), fontSize: 12)),
                  ),

                const SizedBox(height: 16),

                // === EVENT DETAILS CARD ===
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(color: _surfaceDark, border: Border.all(color: _border), borderRadius: BorderRadius.circular(14)),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(children: [
                        Icon(Icons.celebration, size: 14, color: _gold),
                        SizedBox(width: 6),
                        Text('Event Details', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: _textLight)),
                      ]),
                      const SizedBox(height: 10),
                      if (order.eventType != null) _DetailRow('Type', order.eventType!.replaceAll('_', ' ')),
                      if (order.eventDate != null) _DetailRow('Date', '${order.eventDate!.day}/${order.eventDate!.month}/${order.eventDate!.year}'),
                      if (order.guestCount != null) _DetailRow('Guests', '${order.guestCount}'),
                      if (order.deliveryAddress != null) _DetailRow('Delivery', order.deliveryAddress!),
                      if (order.contactPhone != null) _DetailRow('Phone', order.contactPhone!),
                      if (order.specialInstructions != null) _DetailRow('Notes', order.specialInstructions!),
                    ],
                  ),
                ),
                const SizedBox(height: 12),

                // === ITEMS ===
                const Text('ITEMS ORDERED', style: TextStyle(fontSize: 11, color: _gold, fontWeight: FontWeight.w700, letterSpacing: 1.0)),
                const SizedBox(height: 8),
                ...order.items.map((item) {
                  return Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(color: _surfaceDark, border: Border.all(color: _border), borderRadius: BorderRadius.circular(12)),
                    child: Row(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: Container(
                            width: 38, height: 38,
                            decoration: BoxDecoration(gradient: LinearGradient(colors: _getColors(item.productName ?? item.variantId))),
                            child: Center(child: Text((item.productName ?? '?')[0].toUpperCase(), style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: Colors.white))),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(item.productName ?? 'Item #${item.variantId.substring(0, 8)}', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: _textLight)),
                              Text('${item.variantSize ?? ''} • ${item.quantity} ${item.unitType}(s) @ NPR ${item.unitPrice.toStringAsFixed(0)}', style: const TextStyle(fontSize: 10, color: _muted)),
                            ],
                          ),
                        ),
                        Text('NPR ${item.totalPrice.toStringAsFixed(0)}', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: _gold)),
                      ],
                    ),
                  );
                }),
                const SizedBox(height: 8),

                // === GRAND TOTAL CARD ===
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(colors: [_gold.withValues(alpha: 0.06), _gold.withValues(alpha: 0.02)]),
                    border: Border.all(color: _gold.withValues(alpha: 0.2), width: 1.5),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Column(
                    children: [
                      _TotalRow('Subtotal', 'NPR ${order.totalAmount.toStringAsFixed(0)}'),
                      const SizedBox(height: 4),
                      _TotalRow('Discount', '- NPR ${order.discountAmount.toStringAsFixed(0)}'),
                      const SizedBox(height: 4),
                      const _TotalRow('Delivery', 'FREE', valueColor: _green),
                      Container(height: 1, color: _gold.withValues(alpha: 0.15), margin: const EdgeInsets.symmetric(vertical: 10)),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Grand Total', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: _textLight)),
                          Text('NPR ${order.finalAmount.toStringAsFixed(0)}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: _gold)),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),

                // === ACTION BUTTONS ===
                Row(
                  children: [
                    Expanded(child: _ActionButton(icon: Icons.chat_outlined, label: 'Chat Support', onTap: () => context.push('/chat'))),
                    const SizedBox(width: 8),
                    Expanded(child: _ActionButton(icon: Icons.phone_outlined, label: 'Call Us', onTap: () => launchUrl(Uri.parse('tel:+9779800000000')))),
                  ],
                ),
              ],
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator(color: _gold)),
        error: (err, _) => Center(child: Text('Error: $err', style: const TextStyle(color: _muted))),
      ),
    );
  }

  static List<Color> _getColors(String id) {
    final hash = id.hashCode.abs() % 5;
    return [
      [_gold, const Color(0xFFEAB308)],
      [const Color(0xFF44403C), _surfaceDark],
      [const Color(0xFF1565C0), const Color(0xFF64B5F6)],
      [const Color(0xFF2E7D32), const Color(0xFF81C784)],
      [const Color(0xFFC62828), const Color(0xFFEF9A9A)],
    ][hash];
  }
}

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;
  const _DetailRow(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(width: 70, child: Text(label, style: const TextStyle(fontSize: 13, color: _muted))),
          Expanded(child: Text(value, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: _textLight))),
        ],
      ),
    );
  }
}

class _TotalRow extends StatelessWidget {
  final String label;
  final String value;
  final Color? valueColor;
  const _TotalRow(this.label, this.value, {this.valueColor});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(fontSize: 12, color: _mutedLight)),
        Text(value, style: TextStyle(fontSize: 12, color: valueColor ?? _mutedLight)),
      ],
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  const _ActionButton({required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(border: Border.all(color: _border), borderRadius: BorderRadius.circular(12)),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 16, color: _gold),
            const SizedBox(width: 6),
            Text(label, style: const TextStyle(fontSize: 12, color: _mutedLight)),
          ],
        ),
      ),
    );
  }
}
