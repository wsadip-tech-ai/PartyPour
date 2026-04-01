import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../providers/cart_provider.dart';
import '../../providers/order_provider.dart';

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
  final _eventTypes = ['wedding', 'birthday', 'anniversary', 'corporate', 'house_party', 'other'];

  @override
  void dispose() { _addressController.dispose(); _phoneController.dispose(); _instructionsController.dispose(); super.dispose(); }

  Future<void> _placeOrder() async {
    if (_addressController.text.isEmpty || _phoneController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please fill in delivery address and phone')));
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
        showDialog(context: context, builder: (_) => AlertDialog(
          title: const Text('Order Placed!'),
          content: const Text('Your order has been submitted. We will confirm it shortly.'),
          actions: [TextButton(onPressed: () { Navigator.pop(context); context.go('/orders'); }, child: const Text('View Orders'))],
        ));
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final total = ref.watch(cartTotalProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Checkout')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Event Details', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              value: _eventType,
              decoration: const InputDecoration(labelText: 'Event Type', border: OutlineInputBorder()),
              items: _eventTypes.map((t) => DropdownMenuItem(value: t, child: Text(t.replaceAll('_', ' ').toUpperCase()))).toList(),
              onChanged: (v) => setState(() => _eventType = v!),
            ),
            const SizedBox(height: 12),
            ListTile(
              title: Text(_eventDate == null ? 'Select Event Date' : '${_eventDate!.day}/${_eventDate!.month}/${_eventDate!.year}'),
              trailing: const Icon(Icons.calendar_today),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8), side: BorderSide(color: Theme.of(context).colorScheme.outline)),
              onTap: () async {
                final date = await showDatePicker(context: context, initialDate: DateTime.now().add(const Duration(days: 7)), firstDate: DateTime.now(), lastDate: DateTime.now().add(const Duration(days: 365)));
                if (date != null) setState(() => _eventDate = date);
              },
            ),
            const SizedBox(height: 12),
            Row(children: [const Text('Guests: '), Expanded(child: Slider(value: _guestCount.toDouble(), min: 20, max: 1000, divisions: 98, label: '$_guestCount', onChanged: (v) => setState(() => _guestCount = v.round()))), Text('$_guestCount')]),
            const SizedBox(height: 24),
            Text('Delivery Details', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 12),
            TextField(controller: _addressController, maxLines: 2, decoration: const InputDecoration(labelText: 'Delivery Address', border: OutlineInputBorder())),
            const SizedBox(height: 12),
            TextField(controller: _phoneController, keyboardType: TextInputType.phone, decoration: const InputDecoration(labelText: 'Contact Phone', border: OutlineInputBorder())),
            const SizedBox(height: 12),
            TextField(controller: _instructionsController, maxLines: 2, decoration: const InputDecoration(labelText: 'Special Instructions (optional)', border: OutlineInputBorder())),
            const SizedBox(height: 24),
            Card(child: Padding(padding: const EdgeInsets.all(16), child: Row(children: [Text('Order Total', style: Theme.of(context).textTheme.titleMedium), const Spacer(), Text('NPR ${total.toStringAsFixed(0)}', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold))]))),
            const SizedBox(height: 16),
            SizedBox(width: double.infinity, child: FilledButton(onPressed: _loading ? null : _placeOrder, child: _loading ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2)) : const Text('Place Order'))),
          ],
        ),
      ),
    );
  }
}
