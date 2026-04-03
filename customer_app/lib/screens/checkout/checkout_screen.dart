import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
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

class CheckoutScreen extends ConsumerStatefulWidget {
  const CheckoutScreen({super.key});
  @override
  ConsumerState<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends ConsumerState<CheckoutScreen> {
  final _addressController = TextEditingController();
  final _phoneController = TextEditingController();
  final _instructionsController = TextEditingController();
  String _eventType = 'wedding';
  DateTime? _eventDate;
  int _guestCount = 100;
  bool _loading = false;

  static const _eventTypes = [
    ('wedding', 'Wedding', Icons.favorite),
    ('birthday', 'Birthday', Icons.cake),
    ('corporate', 'Corporate', Icons.business),
    ('house_party', 'Party', Icons.home),
    ('anniversary', 'Anniversary', Icons.celebration),
    ('other', 'Other', Icons.event),
  ];

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
    setState(() => _loading = true);
    try {
      final cartItems = ref.read(cartProvider);
      await ref.read(orderServiceProvider).createOrder(
        cartItems: cartItems, eventType: _eventType, eventDate: _eventDate, guestCount: _guestCount,
        deliveryAddress: _addressController.text.trim(), contactPhone: _phoneController.text.trim(),
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
            title: const Row(
              children: [
                Icon(Icons.check_circle, color: _green, size: 28),
                SizedBox(width: 10),
                Text('Order Placed!', style: TextStyle(color: _textLight, fontSize: 18, fontWeight: FontWeight.w700)),
              ],
            ),
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
                  // Total banner
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
                        Text('$count items', style: const TextStyle(fontSize: 11, color: _muted)),
                      ],
                    ),
                  ),

                  // Event Details card
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
                          Text('Event Details', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: _textLight)),
                        ]),
                        const SizedBox(height: 12),
                        // Event type chips
                        Wrap(
                          spacing: 6, runSpacing: 6,
                          children: _eventTypes.map((e) {
                            final isActive = _eventType == e.$1;
                            return GestureDetector(
                              onTap: () => setState(() => _eventType = e.$1),
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                                decoration: BoxDecoration(
                                  color: isActive ? _gold.withValues(alpha: 0.1) : Colors.transparent,
                                  border: Border.all(color: isActive ? _gold : _border, width: 1.5),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Row(mainAxisSize: MainAxisSize.min, children: [
                                  Icon(e.$3, size: 14, color: isActive ? _gold : _muted),
                                  const SizedBox(width: 6),
                                  Text(e.$2, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: isActive ? _gold : _mutedLight)),
                                ]),
                              ),
                            );
                          }).toList(),
                        ),
                        const SizedBox(height: 12),
                        // Date picker
                        GestureDetector(
                          onTap: () async {
                            final date = await showDatePicker(
                              context: context,
                              initialDate: DateTime.now().add(const Duration(days: 7)),
                              firstDate: DateTime.now(),
                              lastDate: DateTime.now().add(const Duration(days: 365)),
                              builder: (context, child) => Theme(data: Theme.of(context).copyWith(colorScheme: const ColorScheme.dark(primary: _gold, surface: _surfaceDark, onSurface: _textLight)), child: child!),
                            );
                            if (date != null) setState(() => _eventDate = date);
                          },
                          child: Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(color: _darkBg, border: Border.all(color: _border), borderRadius: BorderRadius.circular(10)),
                            child: Row(children: [
                              const Icon(Icons.calendar_today, size: 16, color: _gold),
                              const SizedBox(width: 10),
                              Text(
                                _eventDate == null ? 'Select Event Date' : '${_eventDate!.day}/${_eventDate!.month}/${_eventDate!.year}',
                                style: TextStyle(fontSize: 14, color: _eventDate == null ? _muted : _textLight),
                              ),
                              const Spacer(),
                              const Icon(Icons.chevron_right, size: 16, color: _muted),
                            ]),
                          ),
                        ),
                        const SizedBox(height: 10),
                        // Guest count
                        Row(
                          children: [
                            const Text('Guests', style: TextStyle(fontSize: 13, color: _mutedLight)),
                            const Spacer(),
                            Text('$_guestCount', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: _gold)),
                          ],
                        ),
                        const SizedBox(height: 4),
                        SliderTheme(
                          data: SliderThemeData(
                            activeTrackColor: _gold,
                            inactiveTrackColor: _border,
                            thumbColor: _gold,
                            overlayColor: _gold.withValues(alpha: 0.1),
                            trackHeight: 4,
                          ),
                          child: Slider(
                            value: _guestCount.toDouble(), min: 20, max: 1000, divisions: 98,
                            onChanged: (v) => setState(() => _guestCount = v.round()),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Delivery Details card
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

                  // Secure note
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

          // Bottom bar
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
