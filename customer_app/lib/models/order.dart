class Order {
  final String id;
  final String userId;
  final String? eventType;
  final DateTime? eventDate;
  final int? guestCount;
  final String? deliveryAddress;
  final String? contactPhone;
  final String? specialInstructions;
  final String status;
  final double totalAmount;
  final double discountAmount;
  final double finalAmount;
  final DateTime createdAt;
  final List<OrderItem> items;

  Order({required this.id, required this.userId, this.eventType, this.eventDate, this.guestCount, this.deliveryAddress, this.contactPhone, this.specialInstructions, required this.status, required this.totalAmount, required this.discountAmount, required this.finalAmount, required this.createdAt, this.items = const []});

  factory Order.fromJson(Map<String, dynamic> json) {
    final itemsList = (json['order_items'] as List<dynamic>?)?.map((i) => OrderItem.fromJson(i as Map<String, dynamic>)).toList() ?? [];
    return Order(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      eventType: json['event_type'] as String?,
      eventDate: json['event_date'] != null ? DateTime.parse(json['event_date'] as String) : null,
      guestCount: json['guest_count'] as int?,
      deliveryAddress: json['delivery_address'] as String?,
      contactPhone: json['contact_phone'] as String?,
      specialInstructions: json['special_instructions'] as String?,
      status: json['status'] as String,
      totalAmount: (json['total_amount'] as num).toDouble(),
      discountAmount: (json['discount_amount'] as num).toDouble(),
      finalAmount: (json['final_amount'] as num).toDouble(),
      createdAt: DateTime.parse(json['created_at'] as String),
      items: itemsList,
    );
  }
}

class OrderItem {
  final String id;
  final String orderId;
  final String variantId;
  final int quantity;
  final String unitType;
  final double unitPrice;
  final double totalPrice;

  OrderItem({required this.id, required this.orderId, required this.variantId, required this.quantity, required this.unitType, required this.unitPrice, required this.totalPrice});

  factory OrderItem.fromJson(Map<String, dynamic> json) {
    return OrderItem(
      id: json['id'] as String,
      orderId: json['order_id'] as String,
      variantId: json['variant_id'] as String,
      quantity: json['quantity'] as int,
      unitType: json['unit_type'] as String,
      unitPrice: (json['unit_price'] as num).toDouble(),
      totalPrice: (json['total_price'] as num).toDouble(),
    );
  }
}
