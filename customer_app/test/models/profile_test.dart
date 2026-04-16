import 'package:flutter_test/flutter_test.dart';
import 'package:customer_app/models/profile.dart';

void main() {
  group('Profile', () {
    test('fromJson creates Profile with all fields', () {
      final json = {
        'id': 'user-123',
        'full_name': 'Sadip Wagle',
        'phone': '+977-9800000000',
        'email': 'test@example.com',
        'role': 'customer',
      };

      final profile = Profile.fromJson(json);

      expect(profile.id, 'user-123');
      expect(profile.fullName, 'Sadip Wagle');
      expect(profile.phone, '+977-9800000000');
      expect(profile.email, 'test@example.com');
      expect(profile.role, 'customer');
    });

    test('fromJson handles null optional fields', () {
      final json = {
        'id': 'user-456',
        'full_name': null,
        'phone': null,
        'email': null,
        'role': 'customer',
      };

      final profile = Profile.fromJson(json);

      expect(profile.id, 'user-456');
      expect(profile.fullName, isNull);
      expect(profile.phone, isNull);
      expect(profile.email, isNull);
      expect(profile.role, 'customer');
    });

    test('fromJson handles missing optional fields', () {
      final json = {
        'id': 'user-789',
        'role': 'admin',
      };

      final profile = Profile.fromJson(json);

      expect(profile.id, 'user-789');
      expect(profile.fullName, isNull);
      expect(profile.role, 'admin');
    });
  });
}
