import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../providers/cart_provider.dart';
import '../../providers/order_provider.dart';
import '../../providers/wizard_provider.dart';

const _gold = Color(0xFFCA8A04);
const _goldLight = Color(0xFFEAB308);
const _darkBg = Color(0xFF1C1917);
const _surfaceDark = Color(0xFF292524);
const _textLight = Color(0xFFFAFAF9);
const _muted = Color(0xFF78716C);
const _mutedLight = Color(0xFFA8A29E);
const _border = Color(0xFF44403C);
const _green = Color(0xFF4ade80);

const _eventIcons = {
  'wedding': Icons.favorite,
  'birthday': Icons.cake,
  'corporate': Icons.business,
  'house_party': Icons.home,
  'anniversary': Icons.celebration,
  'other': Icons.event,
};

class CheckoutScreen extends ConsumerStatefulWidget {
  const CheckoutScreen({super.key});
  @override
  ConsumerState<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends ConsumerState<CheckoutScreen> {
  final _addressController = TextEditingController();
  final _phoneController = TextEditingController();
  final _instructionsController = TextEditingController();
  bool _loading = false;
  DateTime? _eventDate;
  bool _datePickerUsed = false;

  @override
  void dispose() {
    _addressController.dispose();
    _phoneController.dispose();
    _instructionsController.dispose();
    super.dispose();
  }

  Future<void> _placeOrder() async {
    if (_addressController.text.isEmpty || _phoneController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        backgroundColor: _surfaceDark,
        content: const Text('Please fill in delivery address and phone', style: TextStyle(color: Color(0xFFEF4444))),
      ));
      return;
    }

    final wizard = ref.read(wizardProvider);
    final date = _eventDate ?? wizard.eventDate;

    if (date == null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        backgroundColor: _surfaceDark,
        content: const Text('Please select an event date', style: TextStyle(color: Color(0xFFEF4444))),
      ));
      return;
    }

    setState(() => _loading = true);
    try {
      final cartItems = ref.read(cartProvider);
      await ref.read(orderServiceProvider).createOrder(
        cartItems: cartItems,
        eventType: wizard.eventType,
        eventDate: date,
        guestCount: wizard.totalPax,
        deliveryAddress: _addressController.text.trim(),
        contactPhone: _phoneController.text.trim(),
        specialInstructions: _instructionsController.text.trim().isEmpty ? null : _instructionsController.text.trim(),
      );
      ref.read(cartProvider.notifier).clear();
      ref.invalidate(orderHistoryProvider);
      if (mounted) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (_) => AlertDialog(
            backgroundColor: _surfaceDark,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: const Row(children: [
              Icon(Icons.check_circle, color: _green, size: 28),
              SizedBox(width: 10),
              Text('Order Placed!', style: TextStyle(color: _textLight, fontSize: 18, fontWeight: FontWeight.w700)),
            ]),
            content: const Text('Your order has been submitted. We will confirm it shortly via call.', style: TextStyle(color: _mutedLight, fontSize: 14)),
            actions: [
              TextButton(
                onPressed: () { Navigator.pop(context); context.go('/orders'); },
                child: const Text('View Orders', style: TextStyle(color: _gold, fontWeight: FontWeight.w700)),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        backgroundColor: _surfaceDark,
        content: Text('Error: $e', style: const TextStyle(color: Color(0xFFEF4444))),
      ));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final total = ref.watch(cartTotalProvider);
    final count = ref.watch(cartCountProvider);
    final wizard = ref.watch(wizardProvider);
    final effectiveDate = _datePickerUsed ? _eventDate : wizard.eventDate;
    final eventIcon = _eventIcons[wizard.eventType] ?? Icons.event;

    // Calculate total bottles
    int totalBottles = 0;
    for (final item in ref.watch(cartProvider)) {
      totalBottles += item.quantity;
    }

    return Scaffold(
      backgroundColor: _darkBg,
      appBar: AppBar(
        backgroundColor: _darkBg,
        leading: IconButton(icon: const Icon(Icons.arrow_back, color: _mutedLight), onPressed: () => context.pop()),
        title: const Text('Checkout', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: _textLight)),
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  // === ORDER TOTAL BANNER ===
                  Container(
                    margin: const EdgeInsets.fromLTRB(20, 8, 20, 0),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(colors: [_gold.withValues(alpha: 0.08), _gold.withValues(alpha: 0.02)]),
                      border: Border.all(color: _gold.withValues(alpha: 0.2), width: 1.5),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Column(
                      children: [
                        const Text('ORDER TOTAL', style: TextStyle(fontSize: 11, color: _mutedLight, letterSpacing: 0.06)),
                        const SizedBox(height: 4),
                        Text('NPR ${total.toStringAsFixed(0)}', style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w800, color: _gold)),
                        Text('$count items • $totalBottles bottles', style: const TextStyle(fontSize: 11, color: _muted)),
                      ],
                    ),
                  ),

                  // === EVENT SUMMARY (display-only, from wizard) ===
                  Container(
                    margin: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(color: _surfaceDark, border: Border.all(color: _border), borderRadius: BorderRadius.circular(14)),
                    child: Column(
                      children: [
                        // Header
                        const Row(children: [
                          Icon(Icons.celebration, size: 16, color: _gold),
                          SizedBox(width: 8),
                          Text('Event Summary', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: _textLight)),
                        ]),
                        const SizedBox(height: 14),
                        // Info strips
                        Row(
                          children: [
                            // Event type
                            Expanded(child: _InfoChip(
                              icon: eventIcon,
                              label: 'Event',
                              value: wizard.eventType.replaceAll('_', ' '),
                            )),
                            const SizedBox(width: 8),
                            // Guest count
                            Expanded(child: _InfoChip(
                              icon: Icons.groups,
                              label: 'Guests',
                              value: '${wizard.totalPax}',
                            )),
                          ],
                        ),
                        const SizedBox(height: 8),
                        // Date (tappable to change if needed)
                        GestureDetector(
                          onTap: () async {
                            final date = await showDatePicker(
                              context: context,
                              initialDate: effectiveDate ?? DateTime.now().add(const Duration(days: 7)),
                              firstDate: DateTime.now(),
                              lastDate: DateTime.now().add(const Duration(days: 365)),
                              builder: (context, child) => Theme(
                                data: Theme.of(context).copyWith(colorScheme: const ColorScheme.dark(primary: _gold, surface: _surfaceDark, onSurface: _textLight)),
                                child: child!,
                              ),
                            );
                            if (date != null) setState(() { _eventDate = date; _datePickerUsed = true; });
                          },
                          child: Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                            decoration: BoxDecoration(
                              color: _darkBg,
                              border: Border.all(color: effectiveDate == null ? _gold.withValues(alpha: 0.5) : _border),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Row(children: [
                              Icon(Icons.calendar_today, size: 16, color: effectiveDate == null ? _gold : _mutedLight),
                              const SizedBox(width: 10),
                              Text(
                                effectiveDate == null
                                    ? 'Tap to select event date'
                                    : '${effectiveDate.day}/${effectiveDate.month}/${effectiveDate.year}',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: effectiveDate == null ? _gold : _textLight,
                                  fontWeight: effectiveDate == null ? FontWeight.w600 : FontWeight.w400,
                                ),
                              ),
                              const Spacer(),
                              if (effectiveDate != null)
                                const Text('Change', style: TextStyle(fontSize: 11, color: _gold, fontWeight: FontWeight.w500)),
                              if (effectiveDate == null)
                                const Icon(Icons.error_outline, size: 16, color: _gold),
                            ]),
                          ),
                        ),
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
                          Text('Delivery Details', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: _textLight)),
                        ]),
                        const SizedBox(height: 12),
                        _DarkInput(controller: _addressController, label: 'Delivery Address', maxLines: 2),
                        const SizedBox(height: 8),
                        _DarkInput(controller: _phoneController, label: 'Contact Phone', keyboardType: TextInputType.phone),
                        const SizedBox(height: 8),
                        _DarkInput(controller: _instructionsController, label: 'Special instructions (optional)', maxLines: 2),
                      ],
                    ),
                  ),

                  // === SECURE NOTE ===
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
                    child: Row(children: [
                      const Icon(Icons.lock_outline, size: 14, color: _green),
                      const SizedBox(width: 8),
                      const Expanded(child: Text('Your order details are secure. We\'ll confirm via call.', style: TextStyle(fontSize: 11, color: _muted))),
                    ]),
                  ),
                ],
              ),
            ),
          ),

          // === BOTTOM BAR ===
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: _darkBg, border: Border(top: BorderSide(color: _border.withValues(alpha: 0.5)))),
            child: GestureDetector(
              onTap: _loading ? null : _placeOrder,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 16),
                decoration: BoxDecoration(
                  gradient: _loading ? null : const LinearGradient(colors: [_gold, _goldLight]),
                  color: _loading ? _surfaceDark : null,
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: _loading ? null : [BoxShadow(color: _gold.withValues(alpha: 0.25), blurRadius: 16, offset: const Offset(0, 4))],
                ),
                child: Center(
                  child: _loading
                      ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: _muted))
                      : const Text('Confirm & Place Order', style: TextStyle(color: _darkBg, fontWeight: FontWeight.w700, fontSize: 15, letterSpacing: 0.3)),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// === Display-only info chip ===
class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  const _InfoChip({required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(color: _darkBg, border: Border.all(color: _border), borderRadius: BorderRadius.circular(10)),
      child: Row(
        children: [
          Icon(icon, size: 18, color: _gold),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: const TextStyle(fontSize: 10, color: _muted, letterSpacing: 0.04)),
                const SizedBox(height: 2),
                Text(value, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: _textLight)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// === Dark input field ===
class _DarkInput extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final int maxLines;
  final TextInputType? keyboardType;

  const _DarkInput({required this.controller, required this.label, this.maxLines = 1, this.keyboardType});

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      maxLines: maxLines,
      keyboardType: keyboardType,
      style: const TextStyle(color: _textLight, fontSize: 14),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: _muted, fontSize: 13),
        filled: true,
        fillColor: _darkBg,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: _border)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: _border)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: _gold, width: 2)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      ),
    );
  }
}
