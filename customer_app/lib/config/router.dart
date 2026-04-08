// lib/config/router.dart

import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../main.dart' show prefs;
import '../screens/auth/login_screen.dart';
import '../screens/home/home_screen.dart';
import '../screens/catalog/category_screen.dart';
import '../screens/catalog/product_list_screen.dart';
import '../screens/catalog/product_detail_screen.dart';
import '../screens/cart/cart_screen.dart';
import '../screens/checkout/checkout_screen.dart';
import '../screens/orders/order_history_screen.dart';
import '../screens/orders/order_detail_screen.dart';
import '../screens/orders/order_placed_screen.dart';
import '../screens/profile/profile_screen.dart';
import '../screens/wizard/wizard_event_screen.dart';
import '../screens/wizard/wizard_types_screen.dart';
import '../screens/wizard/wizard_quantities_screen.dart';
import '../screens/wizard/wizard_brands_screen.dart';
import '../screens/wizard/wizard_review_screen.dart';
import '../screens/wizard/wizard_confirm_screen.dart';
import '../screens/calculator/price_calculator_screen.dart';
import '../screens/notifications/notifications_screen.dart';
import '../screens/chat/chat_screen.dart';

const _lastRouteKey = 'last_route';

// Routes safe to restore (wizard state is now persisted too)
bool _isRestorableRoute(String route) {
  const safe = {
    '/home', '/orders', '/profile', '/cart', '/calculator', '/notifications', '/chat',
    '/wizard/event', '/wizard/types', '/wizard/quantities', '/wizard/brands',
    '/wizard/review', '/wizard/confirm',
  };
  if (safe.contains(route)) return true;
  if (route.startsWith('/order/') ||
      route.startsWith('/category/') ||
      route.startsWith('/products/') ||
      route.startsWith('/product/')) return true;
  return false;
}

final routerProvider = Provider<GoRouter>((ref) {
  final isLoggedIn = Supabase.instance.client.auth.currentSession != null;

  // Determine start screen
  String initialLocation = '/login';
  if (isLoggedIn) {
    final lastRoute = prefs.getString(_lastRouteKey);
    initialLocation = (lastRoute != null && _isRestorableRoute(lastRoute)) ? lastRoute : '/home';
  }

  return GoRouter(
    initialLocation: initialLocation,
    redirect: (context, state) {
      final loggedIn = Supabase.instance.client.auth.currentSession != null;
      final isOnLogin = state.matchedLocation == '/login';

      if (!loggedIn && !isOnLogin) return '/login';
      if (loggedIn && isOnLogin) return '/home';

      // Persist current route for next app launch
      if (loggedIn) {
        final currentRoute = state.uri.toString();
        if (currentRoute != '/login') {
          prefs.setString(_lastRouteKey, currentRoute);
        }
      }

      return null;
    },
    routes: [
      GoRoute(path: '/login', builder: (_, __) => const LoginScreen()),
      GoRoute(path: '/home', builder: (_, __) => const HomeScreen()),
      // Wizard flow
      GoRoute(path: '/wizard/event', builder: (_, __) => const WizardEventScreen()),
      GoRoute(path: '/wizard/types', builder: (_, __) => const WizardTypesScreen()),
      GoRoute(path: '/wizard/quantities', builder: (_, __) => const WizardQuantitiesScreen()),
      GoRoute(path: '/wizard/brands', builder: (_, __) => const WizardBrandsScreen()),
      GoRoute(path: '/wizard/review', builder: (_, __) => const WizardReviewScreen()),
      GoRoute(path: '/wizard/confirm', builder: (_, __) => const WizardConfirmScreen()),
      GoRoute(path: '/calculator', builder: (_, __) => const PriceCalculatorScreen()),
      // Catalog
      GoRoute(path: '/category/:categoryId', builder: (_, state) => CategoryScreen(categoryId: state.pathParameters['categoryId']!)),
      GoRoute(path: '/products/:subcategoryId', builder: (_, state) => ProductListScreen(subcategoryId: state.pathParameters['subcategoryId']!)),
      GoRoute(path: '/product/:productId', builder: (_, state) => ProductDetailScreen(productId: state.pathParameters['productId']!)),
      GoRoute(path: '/cart', builder: (_, __) => const CartScreen()),
      GoRoute(path: '/checkout', builder: (_, __) => const CheckoutScreen()),
      GoRoute(path: '/order-placed/:orderId', builder: (_, state) => OrderPlacedScreen(orderId: state.pathParameters['orderId']!)),
      GoRoute(path: '/orders', builder: (_, __) => const OrderHistoryScreen()),
      GoRoute(path: '/order/:orderId', builder: (_, state) => OrderDetailScreen(orderId: state.pathParameters['orderId']!)),
      GoRoute(path: '/profile', builder: (_, __) => const ProfileScreen()),
      GoRoute(path: '/notifications', builder: (_, __) => const NotificationsScreen()),
      GoRoute(path: '/chat', builder: (_, __) => const ChatScreen()),
    ],
  );
});
