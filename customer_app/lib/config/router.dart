// lib/config/router.dart

import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../screens/auth/login_screen.dart';
import '../screens/home/home_screen.dart';
import '../screens/catalog/category_screen.dart';
import '../screens/catalog/product_list_screen.dart';
import '../screens/catalog/product_detail_screen.dart';
import '../screens/cart/cart_screen.dart';
import '../screens/checkout/checkout_screen.dart';
import '../screens/orders/order_history_screen.dart';
import '../screens/orders/order_detail_screen.dart';
import '../screens/profile/profile_screen.dart';
import '../screens/wizard/wizard_event_screen.dart';
import '../screens/wizard/wizard_types_screen.dart';
import '../screens/wizard/wizard_quantities_screen.dart';
import '../screens/wizard/wizard_brands_screen.dart';
import '../screens/wizard/wizard_review_screen.dart';
import '../screens/calculator/price_calculator_screen.dart';

final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/login',
    routes: [
      GoRoute(path: '/login', builder: (_, __) => const LoginScreen()),
      GoRoute(path: '/home', builder: (_, __) => const HomeScreen()),
      // Wizard flow
      GoRoute(path: '/wizard/event', builder: (_, __) => const WizardEventScreen()),
      GoRoute(path: '/wizard/types', builder: (_, __) => const WizardTypesScreen()),
      GoRoute(path: '/wizard/quantities', builder: (_, __) => const WizardQuantitiesScreen()),
      GoRoute(path: '/wizard/brands', builder: (_, __) => const WizardBrandsScreen()),
      GoRoute(path: '/wizard/review', builder: (_, __) => const WizardReviewScreen()),
      GoRoute(path: '/calculator', builder: (_, __) => const PriceCalculatorScreen()),
      // Catalog (secondary)
      GoRoute(path: '/category/:categoryId', builder: (_, state) => CategoryScreen(categoryId: state.pathParameters['categoryId']!)),
      GoRoute(path: '/products/:subcategoryId', builder: (_, state) => ProductListScreen(subcategoryId: state.pathParameters['subcategoryId']!)),
      GoRoute(path: '/product/:productId', builder: (_, state) => ProductDetailScreen(productId: state.pathParameters['productId']!)),
      GoRoute(path: '/cart', builder: (_, __) => const CartScreen()),
      GoRoute(path: '/checkout', builder: (_, __) => const CheckoutScreen()),
      GoRoute(path: '/orders', builder: (_, __) => const OrderHistoryScreen()),
      GoRoute(path: '/order/:orderId', builder: (_, state) => OrderDetailScreen(orderId: state.pathParameters['orderId']!)),
      GoRoute(path: '/profile', builder: (_, __) => const ProfileScreen()),
    ],
  );
});
