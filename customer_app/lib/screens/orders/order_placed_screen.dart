import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../providers/order_provider.dart';

const _gold = Color(0xFFCA8A04);
const _goldLight = Color(0xFFEAB308);
const _darkBg = Color(0xFF1C1917);
const _surfaceDark = Color(0xFF292524);
const _textLight = Color(0xFFFAFAF9);
const _muted = Color(0xFF78716C);
const _mutedLight = Color(0xFFA8A29E);
const _border = Color(0xFF44403C);
const _green = Color(0xFF4ade80);

class OrderPlacedScreen extends ConsumerWidget {
  final String orderId;
  const OrderPlacedScreen({super.key, required this.orderId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final orderAsync = ref.watch(orderDetailProvider(orderId));

    return Scaffold(
      backgroundColor: _darkBg,
      body: SafeArea(
        child: orderAsync.when(
          data: (order) {
            return Column(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                      children: [
                        const SizedBox(height: 40),
                        // Success icon
                        Container(
                          width: 80, height: 80,
                          decoration: BoxDecoration(
                            color: _green.withValues(alpha: 0.1),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.check_circle, color: _green, size: 48),
                        ),
                        const SizedBox(height: 16),
                        const Text('Order Placed!', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: _textLight)),
                        const SizedBox(height: 6),
                        const Text('A confirmation link has been sent to your email.', style: TextStyle(fontSize: 13, color: _muted), textAlign: TextAlign.center),
                        const SizedBox(height: 24),

                        // Order summary card
                        Container(
                          margin: const EdgeInsets.symmetric(horizontal: 20),
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: _surfaceDark,
                            border: Border.all(color: _border),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  const Text('ORDER SUMMARY', style: TextStyle(fontSize: 11, color: _gold, fontWeight: FontWeight.w700, letterSpacing: 1.0)),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: _green.withValues(alpha: 0.1),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(order.status.toUpperCase(), style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: _green)),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 14),

                              // Event info
                              if (order.eventType != null)
                                _InfoRow(label: 'Event', value: order.eventType!.replaceAll('_', ' ')),
                              if (order.guestCount != null)
                                _InfoRow(label: 'Guests', value: '${order.guestCount}'),
                              if (order.eventDate != null)
                                _InfoRow(label: 'Date', value: '${order.eventDate!.day}/${order.eventDate!.month}/${order.eventDate!.year}'),
                              if (order.deliveryAddress != null)
                                _InfoRow(label: 'Delivery', value: order.deliveryAddress!),
                              if (order.contactPhone != null)
                                _InfoRow(label: 'Phone', value: order.contactPhone!),

                              Container(height: 1, color: _border, margin: const EdgeInsets.symmetric(vertical: 12)),

                              // Items
                              ...order.items.map((item) => Padding(
                                padding: const EdgeInsets.only(bottom: 8),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Expanded(
                                      child: Text('${item.quantity}x @ NPR ${item.unitPrice.toStringAsFixed(0)}',
                                        style: const TextStyle(fontSize: 13, color: _mutedLight)),
                                    ),
                                    Text('NPR ${item.totalPrice.toStringAsFixed(0)}',
                                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: _textLight)),
                                  ],
                                ),
                              )),

                              Container(height: 1, color: _border, margin: const EdgeInsets.symmetric(vertical: 8)),

                              // Total
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  const Text('Total', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: _textLight)),
                                  Text('NPR ${order.finalAmount.toStringAsFixed(0)}',
                                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: _gold)),
                                ],
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 16),

                        // Payment section placeholder
                        Container(
                          margin: const EdgeInsets.symmetric(horizontal: 20),
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: _surfaceDark,
                            border: Border.all(color: _gold.withValues(alpha: 0.2)),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Column(
                            children: [
                              const Icon(Icons.payment, size: 28, color: _gold),
                              const SizedBox(height: 8),
                              const Text('Payment', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: _textLight)),
                              const SizedBox(height: 4),
                              const Text('Payment integration coming soon.\nWe will confirm your order via call.', textAlign: TextAlign.center,
                                style: TextStyle(fontSize: 12, color: _muted)),
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),
                      ],
                    ),
                  ),
                ),

                // Bottom actions
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(color: _darkBg, border: Border(top: BorderSide(color: _border.withValues(alpha: 0.5)))),
                  child: Row(
                    children: [
                      Expanded(
                        child: GestureDetector(
                          onTap: () => context.go('/orders'),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            decoration: BoxDecoration(border: Border.all(color: _gold, width: 1.5), borderRadius: BorderRadius.circular(14)),
                            child: const Center(child: Text('View All Orders', style: TextStyle(color: _gold, fontSize: 14, fontWeight: FontWeight.w600))),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: GestureDetector(
                          onTap: () => context.go('/home'),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(colors: [_gold, _goldLight]),
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: const Center(child: Text('Back to Home', style: TextStyle(color: _darkBg, fontWeight: FontWeight.w700, fontSize: 14))),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            );
          },
          loading: () => const Center(child: CircularProgressIndicator(color: _gold)),
          error: (err, _) => Center(child: Text('Error: $err', style: const TextStyle(color: _muted))),
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  const _InfoRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(width: 80, child: Text(label, style: const TextStyle(fontSize: 12, color: _muted))),
          Expanded(child: Text(value, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: _textLight))),
        ],
      ),
    );
  }
}
