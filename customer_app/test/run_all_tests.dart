// Test runner that imports all test files.
// Run with: flutter test test/run_all_tests.dart

// Model tests
import 'models/profile_test.dart' as profile_test;
import 'models/category_test.dart' as category_test;
import 'models/product_test.dart' as product_test;
import 'models/discount_test.dart' as discount_test;
import 'models/order_test.dart' as order_test;
import 'models/notification_test.dart' as notification_test;
import 'models/estimation_rule_test.dart' as estimation_rule_test;
import 'models/cart_item_test.dart' as cart_item_test;

// Service structure tests
import 'services/auth_service_test.dart' as auth_service_test;
import 'services/push_notification_service_test.dart' as push_notification_service_test;
import 'services/notification_service_test.dart' as notification_service_test;
import 'services/catalog_service_test.dart' as catalog_service_test;
import 'services/order_service_test.dart' as order_service_test;
import 'services/estimation_service_test.dart' as estimation_service_test;
import 'services/analytics_service_test.dart' as analytics_service_test;

void main() {
  // Model tests
  profile_test.main();
  category_test.main();
  product_test.main();
  discount_test.main();
  order_test.main();
  notification_test.main();
  estimation_rule_test.main();
  cart_item_test.main();

  // Service structure tests
  auth_service_test.main();
  push_notification_service_test.main();
  notification_service_test.main();
  catalog_service_test.main();
  order_service_test.main();
  estimation_service_test.main();
  analytics_service_test.main();
}
