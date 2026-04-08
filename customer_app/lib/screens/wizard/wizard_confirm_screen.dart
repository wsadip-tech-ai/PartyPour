import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../providers/wizard_provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/cart_provider.dart';
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

class WizardConfirmScreen extends ConsumerStatefulWidget {
  const WizardConfirmScreen({super.key});

  @override
  ConsumerState<WizardConfirmScreen> createState() => _WizardConfirmScreenState();
}

class _WizardConfirmScreenState extends ConsumerState<WizardConfirmScreen> {
  bool _loading = false;

  void _confirmAndPlace() {
    final wizard = ref.read(wizardProvider);
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: _surfaceDark,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Place Order?', style: TextStyle(color: _textLight, fontSize: 17, fontWeight: FontWeight.w700)),
        content: Text(
          'You are about to place an order of NPR ${wizard.grandTotal.toStringAsFixed(0)}. This action cannot be undone.',
          style: const TextStyle(color: _mutedLight, fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel', style: TextStyle(color: _muted)),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _placeOrder();
            },
            child: const Text('Yes, Place Order', style: TextStyle(color: _gold, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }

  Future<void> _placeOrder() async {
    setState(() => _loading = true);
    try {
      final wizard = ref.read(wizardProvider);

      // Build cart from wizard selections
      final cart = ref.read(cartProvider.notifier);
      cart.clear();
      for (final selections in wizard.brandSelections.values) {
        for (final sel in selections) {
          cart.addItem(sel.product, sel.variant, sel.unitType, quantity: sel.quantity);
        }
      }

      final cartItems = ref.read(cartProvider);
      final order = await ref.read(orderServiceProvider).createOrder(
        cartItems: cartItems,
        eventType: wizard.eventType,
        eventDate: wizard.eventDate!,
        guestCount: wizard.totalPax,
        deliveryAddress: wizard.deliveryAddress,
        contactPhone: wizard.contactPhone,
        specialInstructions: wizard.specialInstructions.isEmpty ? null : wizard.specialInstructions,
      );

      ref.read(analyticsProvider).trackWizardStepCompleted(6, 'confirm');
      ref.read(analyticsProvider).trackOrderPlaced(order.id, wizard.grandTotal, wizard.allSelections.length);
      ref.read(cartProvider.notifier).clear();
      ref.read(wizardProvider.notifier).reset();
      ref.invalidate(orderHistoryProvider);

      if (mounted) {
        context.go('/order-placed/${order.id}');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          backgroundColor: _surfaceDark,
          content: Text('Error: $e', style: const TextStyle(color: Color(0xFFEF4444))),
        ));
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.read(analyticsProvider).trackWizardStepEntered(6, 'confirm');
    final wizard = ref.watch(wizardProvider);

    int totalUnits = 0;
    int totalCategories = 0;
    for (final selections in wizard.brandSelections.values) {
      if (selections.isNotEmpty) {
        totalCategories++;
        for (final s in selections) {
          totalUnits += s.quantity;
        }
      }
    }

    return Scaffold(
      backgroundColor: _darkBg,
      appBar: AppBar(
        backgroundColor: _darkBg,
        leading: IconButton(icon: const Icon(Icons.arrow_back, color: _mutedLight), onPressed: () => context.pop()),
        title: const Text('Confirm Order', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: _textLight)),
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header
                  const Padding(
                    padding: EdgeInsets.fromLTRB(20, 8, 20, 4),
                    child: Text('Please review everything before confirming', style: TextStyle(color: _muted, fontSize: 13)),
                  ),

                  // === EVENT DETAILS ===
                  Container(
                    margin: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(color: _surfaceDark, border: Border.all(color: _border), borderRadius: BorderRadius.circular(14)),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Row(children: [
                          Icon(Icons.celebration, size: 16, color: _gold),
                          SizedBox(width: 8),
                          Text('EVENT', style: TextStyle(fontSize: 11, color: _gold, fontWeight: FontWeight.w700, letterSpacing: 1.0)),
                        ]),
                        const SizedBox(height: 10),
                        _ReadOnlyRow(label: 'Type', value: wizard.eventType.replaceAll('_', ' ')),
                        _ReadOnlyRow(label: 'Guests', value: '${wizard.totalPax}'),
                        if (wizard.ladiesCount > 0) _ReadOnlyRow(label: 'Ladies', value: '${wizard.ladiesCount}'),
                        if (wizard.childrenCount > 0) _ReadOnlyRow(label: 'Children', value: '${wizard.childrenCount}'),
                        if (wizard.eventDate != null) _ReadOnlyRow(label: 'Date', value: '${wizard.eventDate!.day}/${wizard.eventDate!.month}/${wizard.eventDate!.year}'),
                        if (wizard.eventStartTime != null) _ReadOnlyRow(label: 'Time', value: '${wizard.eventStartTime!.format(context)} — ${wizard.eventEndTime?.format(context) ?? 'TBD'}'),
                      ],
                    ),
                  ),

                  // === DELIVERY DETAILS ===
                  Container(
                    margin: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(color: _surfaceDark, border: Border.all(color: _border), borderRadius: BorderRadius.circular(14)),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Row(children: [
                          Icon(Icons.local_shipping_outlined, size: 16, color: _gold),
                          SizedBox(width: 8),
                          Text('DELIVERY', style: TextStyle(fontSize: 11, color: _gold, fontWeight: FontWeight.w700, letterSpacing: 1.0)),
                        ]),
                        const SizedBox(height: 10),
                        _ReadOnlyRow(label: 'Address', value: wizard.deliveryAddress),
                        _ReadOnlyRow(label: 'Phone', value: wizard.contactPhone),
                        if (wizard.specialInstructions.isNotEmpty) _ReadOnlyRow(label: 'Note', value: wizard.specialInstructions),
                      ],
                    ),
                  ),

                  // === ORDER ITEMS ===
                  Container(
                    margin: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(color: _surfaceDark, border: Border.all(color: _border), borderRadius: BorderRadius.circular(14)),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.receipt_long, size: 16, color: _gold),
                            const SizedBox(width: 8),
                            const Text('ORDER ITEMS', style: TextStyle(fontSize: 11, color: _gold, fontWeight: FontWeight.w700, letterSpacing: 1.0)),
                            const Spacer(),
                            Text('$totalCategories types • $totalUnits units', style: const TextStyle(fontSize: 11, color: _muted)),
                          ],
                        ),
                        const SizedBox(height: 12),

                        ...wizard.brandSelections.entries.expand((entry) {
                          final slug = entry.key;
                          final selections = entry.value;
                          if (selections.isEmpty) return <Widget>[];

                          return [
                            Text(slug.replaceAll('-', ' ').toUpperCase(), style: const TextStyle(fontSize: 10, color: _mutedLight, fontWeight: FontWeight.w600, letterSpacing: 0.8)),
                            const SizedBox(height: 6),
                            ...selections.map((sel) => Padding(
                              padding: const EdgeInsets.only(bottom: 8),
                              child: Row(
                                children: [
                                  Expanded(child: Text(sel.product.name, style: const TextStyle(fontSize: 13, color: _textLight))),
                                  Text('x${sel.quantity}', style: const TextStyle(fontSize: 12, color: _muted)),
                                  const SizedBox(width: 12),
                                  Text('NPR ${sel.totalPrice.toStringAsFixed(0)}', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: _gold)),
                                ],
                              ),
                            )),
                            Container(height: 1, color: _border, margin: const EdgeInsets.only(bottom: 8)),
                          ];
                        }),

                        // Grand total
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Grand Total', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: _textLight)),
                            Text('NPR ${wizard.grandTotal.toStringAsFixed(0)}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: _gold)),
                          ],
                        ),
                      ],
                    ),
                  ),

                  // Note
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 14, 20, 16),
                    child: Row(children: [
                      const Icon(Icons.lock_outline, size: 14, color: _green),
                      const SizedBox(width: 8),
                      const Expanded(child: Text('A confirmation link will be sent to your email after placing the order.', style: TextStyle(fontSize: 11, color: _muted))),
                    ]),
                  ),
                ],
              ),
            ),
          ),

          // Bottom bar
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: _darkBg, boxShadow: [BoxShadow(blurRadius: 12, color: Colors.black.withValues(alpha: 0.3))]),
            child: Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () => context.pop(),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      decoration: BoxDecoration(border: Border.all(color: _gold, width: 1.5), borderRadius: BorderRadius.circular(14)),
                      child: const Center(child: Text('Edit', style: TextStyle(color: _gold, fontSize: 14, fontWeight: FontWeight.w600))),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  flex: 2,
                  child: GestureDetector(
                    onTap: _loading ? null : _confirmAndPlace,
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      decoration: BoxDecoration(
                        gradient: _loading ? null : const LinearGradient(colors: [_gold, _goldLight]),
                        color: _loading ? _surfaceDark : null,
                        borderRadius: BorderRadius.circular(14),
                        boxShadow: _loading ? null : [BoxShadow(color: _gold.withValues(alpha: 0.25), blurRadius: 16, offset: const Offset(0, 4))],
                      ),
                      child: Center(
                        child: _loading
                            ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: _muted))
                            : const Text('Place Order & Pay', style: TextStyle(color: _darkBg, fontWeight: FontWeight.w700, fontSize: 15, letterSpacing: 0.3)),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ReadOnlyRow extends StatelessWidget {
  final String label;
  final String value;
  const _ReadOnlyRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(width: 70, child: Text(label, style: const TextStyle(fontSize: 12, color: _muted))),
          Expanded(child: Text(value, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: _textLight))),
        ],
      ),
    );
  }
}
