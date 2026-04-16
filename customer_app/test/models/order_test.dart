import 'package:flutter_test/flutter_test.dart';
import 'package:customer_app/models/order.dart';

void main() {
  group('OrderItem', () {
    test('fromJson creates OrderItem with all fields', () {
      final json = {
        'id': 'oi-1',
        'order_id': 'ord-1',
        'variant_id': 'var-1',
        'quantity': 3,
        'unit_type': 'bottle',
        'unit_price': 1500.0,
        'total_price': 4500.0,
      };

      final item = OrderItem.fromJson(json);

      expect(item.id, 'oi-1');
      expect(item.orderId, 'ord-1');
      expect(item.variantId, 'var-1');
      expect(item.quantity, 3);
      expect(item.unitType, 'bottle');
      expect(item.unitPrice, 1500.0);
      expect(item.totalPrice, 4500.0);
    });

    test('fromJson extracts product name and variant size from joined data', () {
      final json = {
        'id': 'oi-3',
        'order_id': 'ord-1',
        'variant_id': 'var-1',
        'quantity': 2,
        'unit_type': 'bottle',
        'unit_price': 1500.0,
        'total_price': 3000.0,
        'variants': {
          'size': '750ml',
          'products': {'name': 'Khukuri Rum'},
        },
      };

      final item = OrderItem.fromJson(json);

      expect(item.productName, 'Khukuri Rum');
      expect(item.variantSize, '750ml');
    });

    test('fromJson handles missing variants gracefully', () {
      final json = {
        'id': 'oi-4',
        'order_id': 'ord-1',
        'variant_id': 'var-1',
        'quantity': 1,
        'unit_type': 'bottle',
        'unit_price': 1500.0,
        'total_price': 1500.0,
      };

      final item = OrderItem.fromJson(json);

      expect(item.productName, isNull);
      expect(item.variantSize, isNull);
    });

    test('fromJson handles int prices via num.toDouble()', () {
      final json = {
        'id': 'oi-2',
        'order_id': 'ord-1',
        'variant_id': 'var-2',
        'quantity': 1,
        'unit_type': 'case',
        'unit_price': 5000,
        'total_price': 5000,
      };

      final item = OrderItem.fromJson(json);

      expect(item.unitPrice, 5000.0);
      expect(item.unitPrice, isA<double>());
      expect(item.totalPrice, 5000.0);
      expect(item.totalPrice, isA<double>());
    });
  });

  group('Order', () {
    test('fromJson creates Order with all fields and items', () {
      final json = {
        'id': 'ord-1',
        'user_id': 'user-1',
        'event_type': 'wedding',
        'event_date': '2026-06-15',
        'guest_count': 150,
        'delivery_address': '123 Main St, Kathmandu',
        'contact_phone': '+977-9800000000',
        'special_instructions': 'Deliver before noon',
        'status': 'pending',
        'total_amount': 50000.0,
        'discount_amount': 5000.0,
        'final_amount': 45000.0,
        'created_at': '2026-04-08T10:00:00Z',
        'order_items': [
          {
            'id': 'oi-1',
            'order_id': 'ord-1',
            'variant_id': 'var-1',
            'quantity': 10,
            'unit_type': 'bottle',
            'unit_price': 2500.0,
            'total_price': 25000.0,
          },
          {
            'id': 'oi-2',
            'order_id': 'ord-1',
            'variant_id': 'var-2',
            'quantity': 5,
            'unit_type': 'case',
            'unit_price': 5000.0,
            'total_price': 25000.0,
          },
        ],
      };

      final order = Order.fromJson(json);

      expect(order.id, 'ord-1');
      expect(order.userId, 'user-1');
      expect(order.eventType, 'wedding');
      expect(order.eventDate, isNotNull);
      expect(order.eventDate!.year, 2026);
      expect(order.eventDate!.month, 6);
      expect(order.eventDate!.day, 15);
      expect(order.guestCount, 150);
      expect(order.deliveryAddress, '123 Main St, Kathmandu');
      expect(order.contactPhone, '+977-9800000000');
      expect(order.specialInstructions, 'Deliver before noon');
      expect(order.status, 'pending');
      expect(order.totalAmount, 50000.0);
      expect(order.discountAmount, 5000.0);
      expect(order.finalAmount, 45000.0);
      expect(order.createdAt.year, 2026);
      expect(order.items, hasLength(2));
      expect(order.items[0].quantity, 10);
      expect(order.items[1].unitType, 'case');
    });

    test('fromJson handles null optional fields', () {
      final json = {
        'id': 'ord-2',
        'user_id': 'user-1',
        'event_type': null,
        'event_date': null,
        'guest_count': null,
        'delivery_address': null,
        'contact_phone': null,
        'special_instructions': null,
        'status': 'draft',
        'total_amount': 0,
        'discount_amount': 0,
        'final_amount': 0,
        'created_at': '2026-04-08T10:00:00Z',
      };

      final order = Order.fromJson(json);

      expect(order.eventType, isNull);
      expect(order.eventDate, isNull);
      expect(order.guestCount, isNull);
      expect(order.deliveryAddress, isNull);
      expect(order.contactPhone, isNull);
      expect(order.specialInstructions, isNull);
      expect(order.items, isEmpty);
    });

    test('fromJson handles missing order_items key', () {
      final json = {
        'id': 'ord-3',
        'user_id': 'user-1',
        'status': 'pending',
        'total_amount': 1000,
        'discount_amount': 0,
        'final_amount': 1000,
        'created_at': '2026-04-08T10:00:00Z',
      };

      final order = Order.fromJson(json);

      expect(order.items, isEmpty);
    });
  });
}
