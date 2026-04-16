import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/order.dart';
import '../models/cart_item.dart';

class OrderService {
  final SupabaseClient _client;
  OrderService(this._client);

  Future<Order> createOrder({
    required List<CartItem> cartItems,
    required String? eventType,
    required DateTime? eventDate,
    required int? guestCount,
    required String deliveryAddress,
    required String contactPhone,
    String? specialInstructions,
  }) async {
    final userId = _client.auth.currentUser!.id;
    final totalAmount = cartItems.fold<double>(0, (sum, item) => sum + item.totalPrice);

    final orderData = await _client.from('orders').insert({
      'user_id': userId,
      'event_type': eventType,
      'event_date': eventDate?.toIso8601String().split('T')[0],
      'guest_count': guestCount,
      'delivery_address': deliveryAddress,
      'contact_phone': contactPhone,
      'special_instructions': specialInstructions,
      'total_amount': totalAmount,
      'discount_amount': 0,
      'final_amount': totalAmount,
    }).select().single();

    final orderId = orderData['id'] as String;

    final items = cartItems.map((item) => {
      'order_id': orderId,
      'variant_id': item.variant.id,
      'quantity': item.quantity,
      'unit_type': item.unitType,
      'unit_price': item.unitPrice,
      'total_price': item.totalPrice,
    }).toList();

    await _client.from('order_items').insert(items);

    // Trigger order confirmation notification email
    _client.functions.invoke('send-order-email', body: {'order_id': orderId}).catchError((_) {});

    // Re-fetch the complete order with server-generated IDs
    return getOrder(orderId);
  }

  static const _orderSelect = '*, order_items(*, variants(size, products(name)))';

  Future<List<Order>> getOrderHistory() async {
    final userId = _client.auth.currentUser!.id;
    final data = await _client.from('orders').select(_orderSelect).eq('user_id', userId).order('created_at', ascending: false);
    return data.map((json) => Order.fromJson(json)).toList();
  }

  Future<Order> getOrder(String orderId) async {
    final data = await _client.from('orders').select(_orderSelect).eq('id', orderId).single();
    return Order.fromJson(data);
  }
}
