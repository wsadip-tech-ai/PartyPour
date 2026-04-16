import 'package:flutter_test/flutter_test.dart';
import 'package:customer_app/models/notification.dart';

void main() {
  group('AppNotification', () {
    test('fromJson creates AppNotification with all fields', () {
      final json = {
        'id': 'notif-1',
        'user_id': 'user-1',
        'order_id': 'ord-1',
        'title': 'Order Confirmed',
        'message': 'Your order #ord-1 has been confirmed.',
        'is_read': false,
        'created_at': '2026-04-08T10:30:00Z',
      };

      final notification = AppNotification.fromJson(json);

      expect(notification.id, 'notif-1');
      expect(notification.userId, 'user-1');
      expect(notification.orderId, 'ord-1');
      expect(notification.title, 'Order Confirmed');
      expect(notification.message, 'Your order #ord-1 has been confirmed.');
      expect(notification.isRead, isFalse);
      expect(notification.createdAt.year, 2026);
    });

    test('fromJson handles null orderId', () {
      final json = {
        'id': 'notif-2',
        'user_id': 'user-1',
        'order_id': null,
        'title': 'Welcome!',
        'message': 'Welcome to PartyPour.',
        'is_read': true,
        'created_at': '2026-04-01T00:00:00Z',
      };

      final notification = AppNotification.fromJson(json);

      expect(notification.orderId, isNull);
      expect(notification.isRead, isTrue);
    });

    test('fromJson parses created_at correctly', () {
      final json = {
        'id': 'notif-3',
        'user_id': 'user-1',
        'title': 'Test',
        'message': 'Test message',
        'is_read': false,
        'created_at': '2026-12-25T18:30:00Z',
      };

      final notification = AppNotification.fromJson(json);

      expect(notification.createdAt.month, 12);
      expect(notification.createdAt.day, 25);
      expect(notification.createdAt.hour, 18);
      expect(notification.createdAt.minute, 30);
    });
  });
}
