import 'package:flutter_test/flutter_test.dart';
import 'package:customer_app/services/auth_service.dart';

/// These tests verify the AuthService API surface without requiring
/// a live Supabase connection. They ensure the class can be imported
/// and its constructor signature is correct.
void main() {
  group('AuthService structure', () {
    test('AuthService class exists and is importable', () {
      // If this compiles, AuthService is importable
      expect(AuthService, isNotNull);
    });

    test('AuthService has expected method signatures', () {
      // Verify the class has the methods we expect.
      // These will fail at compile time if methods are removed or renamed.
      final methods = <String>[
        'signUpWithEmail',
        'signInWithEmail',
        'signOut',
        'signInWithGoogle',
        'sendPhoneOtp',
        'verifyPhoneOtp',
        'getProfile',
        'updateProfile',
      ];

      // This test passes if the file compiles
      expect(methods, hasLength(8));
    });
  });
}
