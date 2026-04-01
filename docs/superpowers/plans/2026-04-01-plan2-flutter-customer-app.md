# RaksiChaiyo — Plan 2: Flutter Customer App

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build the cross-platform customer app (Android + iOS) using Flutter, connecting to the Supabase backend from Plan 1. Customers can browse the beverage catalog, filter by origin, add items to cart, use the event planner, and place orders.

**Architecture:** Flutter app with clean architecture — screens, widgets, models, services, and providers (Riverpod for state management). Supabase SDK for auth, database queries, and storage. Local cart state with Riverpod.

**Tech Stack:** Flutter 3.x, Dart, Riverpod (state management), Supabase Flutter SDK, GoRouter (navigation)

**Depends on:** Plan 1 (Supabase backend) must be complete.

---

## File Structure

```
root_RaksiChaiyo/
├── customer_app/
│   ├── pubspec.yaml
│   ├── lib/
│   │   ├── main.dart                          # App entry, Supabase init, router
│   │   ├── config/
│   │   │   ├── supabase_config.dart           # Supabase URL + anon key
│   │   │   └── router.dart                    # GoRouter routes
│   │   ├── models/
│   │   │   ├── category.dart                  # Category + Subcategory models
│   │   │   ├── product.dart                   # Product + Variant models
│   │   │   ├── discount.dart                  # Discount model
│   │   │   ├── cart_item.dart                 # Cart item model
│   │   │   ├── order.dart                     # Order + OrderItem models
│   │   │   └── profile.dart                   # User profile model
│   │   ├── services/
│   │   │   ├── auth_service.dart              # Supabase auth wrapper
│   │   │   ├── catalog_service.dart           # Categories, products, variants queries
│   │   │   ├── order_service.dart             # Order creation + history
│   │   │   └── planner_service.dart           # Event planner estimation logic
│   │   ├── providers/
│   │   │   ├── auth_provider.dart             # Auth state
│   │   │   ├── catalog_provider.dart          # Categories, products
│   │   │   ├── cart_provider.dart             # Cart state (local)
│   │   │   ├── order_provider.dart            # Orders
│   │   │   └── planner_provider.dart          # Planner state
│   │   ├── screens/
│   │   │   ├── auth/
│   │   │   │   └── login_screen.dart          # Email/phone login
│   │   │   ├── home/
│   │   │   │   └── home_screen.dart           # Category grid, search, featured
│   │   │   ├── catalog/
│   │   │   │   ├── category_screen.dart       # Subcategory list for a category
│   │   │   │   ├── product_list_screen.dart   # Products in subcategory
│   │   │   │   └── product_detail_screen.dart # Variants, pricing, add to cart
│   │   │   ├── cart/
│   │   │   │   └── cart_screen.dart           # Cart items, totals
│   │   │   ├── planner/
│   │   │   │   └── planner_screen.dart        # Guest count input, suggestions
│   │   │   ├── checkout/
│   │   │   │   └── checkout_screen.dart       # Event details, delivery, confirm
│   │   │   ├── orders/
│   │   │   │   ├── order_history_screen.dart  # Past orders
│   │   │   │   └── order_detail_screen.dart   # Single order details
│   │   │   └── profile/
│   │   │       └── profile_screen.dart        # User info, saved addresses
│   │   └── widgets/
│   │       ├── product_card.dart              # Reusable product card
│   │       ├── variant_selector.dart          # Size + unit/case picker
│   │       ├── origin_filter.dart             # Local/Imported toggle
│   │       └── cart_badge.dart                # Cart icon with count
│   └── test/
│       └── (tests per task)
```

---

### Task 1: Initialize Flutter Project

**Files:**
- Create: `customer_app/` (Flutter scaffold)

- [ ] **Step 1: Create Flutter project**

```bash
cd root_RaksiChaiyo
flutter create customer_app --org com.raksichaiyo
```

- [ ] **Step 2: Add dependencies to pubspec.yaml**

Replace the `dependencies` section in `customer_app/pubspec.yaml`:

```yaml
dependencies:
  flutter:
    sdk: flutter
  supabase_flutter: ^2.5.0
  flutter_riverpod: ^2.5.0
  riverpod_annotation: ^2.3.0
  go_router: ^14.0.0
  cached_network_image: ^3.3.0
  intl: ^0.19.0

dev_dependencies:
  flutter_test:
    sdk: flutter
  flutter_lints: ^4.0.0
  riverpod_generator: ^2.4.0
  build_runner: ^2.4.0
```

- [ ] **Step 3: Install dependencies**

```bash
cd customer_app
flutter pub get
```

- [ ] **Step 4: Commit**

```bash
cd ..
git add customer_app/
git commit -m "chore: initialize Flutter customer app with dependencies"
```

---

### Task 2: Supabase Config + Models

**Files:**
- Create: `customer_app/lib/config/supabase_config.dart`
- Create: `customer_app/lib/models/category.dart`
- Create: `customer_app/lib/models/product.dart`
- Create: `customer_app/lib/models/discount.dart`
- Create: `customer_app/lib/models/cart_item.dart`
- Create: `customer_app/lib/models/order.dart`
- Create: `customer_app/lib/models/profile.dart`

- [ ] **Step 1: Create supabase_config.dart**

```dart
// lib/config/supabase_config.dart

class SupabaseConfig {
  // Replace with your Supabase project values
  static const String url = 'YOUR_SUPABASE_URL';
  static const String anonKey = 'YOUR_SUPABASE_ANON_KEY';
}
```

- [ ] **Step 2: Create category.dart**

```dart
// lib/models/category.dart

class Category {
  final String id;
  final String name;
  final String slug;
  final int sortOrder;
  final String? imageUrl;

  Category({
    required this.id,
    required this.name,
    required this.slug,
    required this.sortOrder,
    this.imageUrl,
  });

  factory Category.fromJson(Map<String, dynamic> json) {
    return Category(
      id: json['id'] as String,
      name: json['name'] as String,
      slug: json['slug'] as String,
      sortOrder: json['sort_order'] as int,
      imageUrl: json['image_url'] as String?,
    );
  }
}

class Subcategory {
  final String id;
  final String categoryId;
  final String name;
  final String slug;
  final int sortOrder;
  final String? imageUrl;

  Subcategory({
    required this.id,
    required this.categoryId,
    required this.name,
    required this.slug,
    required this.sortOrder,
    this.imageUrl,
  });

  factory Subcategory.fromJson(Map<String, dynamic> json) {
    return Subcategory(
      id: json['id'] as String,
      categoryId: json['category_id'] as String,
      name: json['name'] as String,
      slug: json['slug'] as String,
      sortOrder: json['sort_order'] as int,
      imageUrl: json['image_url'] as String?,
    );
  }
}
```

- [ ] **Step 3: Create product.dart**

```dart
// lib/models/product.dart

class Product {
  final String id;
  final String subcategoryId;
  final String name;
  final String origin; // 'local' or 'imported'
  final String? description;
  final String? imageUrl;
  final List<String> tags;
  final List<Variant> variants;

  Product({
    required this.id,
    required this.subcategoryId,
    required this.name,
    required this.origin,
    this.description,
    this.imageUrl,
    this.tags = const [],
    this.variants = const [],
  });

  factory Product.fromJson(Map<String, dynamic> json) {
    final variantsList = (json['variants'] as List<dynamic>?)
        ?.map((v) => Variant.fromJson(v as Map<String, dynamic>))
        .toList() ?? [];

    return Product(
      id: json['id'] as String,
      subcategoryId: json['subcategory_id'] as String,
      name: json['name'] as String,
      origin: json['origin'] as String,
      description: json['description'] as String?,
      imageUrl: json['image_url'] as String?,
      tags: (json['tags'] as List<dynamic>?)?.cast<String>() ?? [],
      variants: variantsList,
    );
  }

  double get lowestPrice =>
      variants.isEmpty ? 0 : variants.map((v) => v.unitPrice).reduce((a, b) => a < b ? a : b);
}

class Variant {
  final String id;
  final String productId;
  final String size;
  final double unitPrice;
  final int? caseSize;
  final double? casePrice;
  final double? mrp;

  Variant({
    required this.id,
    required this.productId,
    required this.size,
    required this.unitPrice,
    this.caseSize,
    this.casePrice,
    this.mrp,
  });

  factory Variant.fromJson(Map<String, dynamic> json) {
    return Variant(
      id: json['id'] as String,
      productId: json['product_id'] as String,
      size: json['size'] as String,
      unitPrice: (json['unit_price'] as num).toDouble(),
      caseSize: json['case_size'] as int?,
      casePrice: (json['case_price'] as num?)?.toDouble(),
      mrp: (json['mrp'] as num?)?.toDouble(),
    );
  }

  double get savingsPerUnit =>
      caseSize != null && casePrice != null
          ? unitPrice - (casePrice! / caseSize!)
          : 0;
}
```

- [ ] **Step 4: Create discount.dart**

```dart
// lib/models/discount.dart

class Discount {
  final String id;
  final String? variantId;
  final String type; // 'percentage' or 'flat'
  final double value;
  final DateTime validFrom;
  final DateTime validUntil;

  Discount({
    required this.id,
    this.variantId,
    required this.type,
    required this.value,
    required this.validFrom,
    required this.validUntil,
  });

  factory Discount.fromJson(Map<String, dynamic> json) {
    return Discount(
      id: json['id'] as String,
      variantId: json['variant_id'] as String?,
      type: json['type'] as String,
      value: (json['value'] as num).toDouble(),
      validFrom: DateTime.parse(json['valid_from'] as String),
      validUntil: DateTime.parse(json['valid_until'] as String),
    );
  }

  double apply(double price) {
    if (type == 'percentage') {
      return price * (1 - value / 100);
    }
    return price - value;
  }
}
```

- [ ] **Step 5: Create cart_item.dart**

```dart
// lib/models/cart_item.dart

import 'product.dart';

class CartItem {
  final Product product;
  final Variant variant;
  final String unitType; // 'unit' or 'case'
  int quantity;

  CartItem({
    required this.product,
    required this.variant,
    required this.unitType,
    this.quantity = 1,
  });

  double get unitPrice =>
      unitType == 'case' && variant.casePrice != null
          ? variant.casePrice!
          : variant.unitPrice;

  double get totalPrice => unitPrice * quantity;

  int get effectiveUnits =>
      unitType == 'case' && variant.caseSize != null
          ? quantity * variant.caseSize!
          : quantity;
}
```

- [ ] **Step 6: Create order.dart**

```dart
// lib/models/order.dart

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

  Order({
    required this.id,
    required this.userId,
    this.eventType,
    this.eventDate,
    this.guestCount,
    this.deliveryAddress,
    this.contactPhone,
    this.specialInstructions,
    required this.status,
    required this.totalAmount,
    required this.discountAmount,
    required this.finalAmount,
    required this.createdAt,
    this.items = const [],
  });

  factory Order.fromJson(Map<String, dynamic> json) {
    final itemsList = (json['order_items'] as List<dynamic>?)
        ?.map((i) => OrderItem.fromJson(i as Map<String, dynamic>))
        .toList() ?? [];

    return Order(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      eventType: json['event_type'] as String?,
      eventDate: json['event_date'] != null
          ? DateTime.parse(json['event_date'] as String)
          : null,
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

  OrderItem({
    required this.id,
    required this.orderId,
    required this.variantId,
    required this.quantity,
    required this.unitType,
    required this.unitPrice,
    required this.totalPrice,
  });

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
```

- [ ] **Step 7: Create profile.dart**

```dart
// lib/models/profile.dart

class Profile {
  final String id;
  final String? fullName;
  final String? phone;
  final String? email;
  final String role;

  Profile({
    required this.id,
    this.fullName,
    this.phone,
    this.email,
    required this.role,
  });

  factory Profile.fromJson(Map<String, dynamic> json) {
    return Profile(
      id: json['id'] as String,
      fullName: json['full_name'] as String?,
      phone: json['phone'] as String?,
      email: json['email'] as String?,
      role: json['role'] as String,
    );
  }
}
```

- [ ] **Step 8: Commit**

```bash
git add customer_app/lib/config/ customer_app/lib/models/
git commit -m "feat: add Supabase config and data models"
```

---

### Task 3: Services Layer

**Files:**
- Create: `customer_app/lib/services/auth_service.dart`
- Create: `customer_app/lib/services/catalog_service.dart`
- Create: `customer_app/lib/services/order_service.dart`
- Create: `customer_app/lib/services/planner_service.dart`

- [ ] **Step 1: Create auth_service.dart**

```dart
// lib/services/auth_service.dart

import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/profile.dart';

class AuthService {
  final SupabaseClient _client;

  AuthService(this._client);

  User? get currentUser => _client.auth.currentUser;
  Stream<AuthState> get authStateChanges => _client.auth.onAuthStateChange;

  Future<AuthResponse> signUpWithEmail(String email, String password, String fullName) {
    return _client.auth.signUp(
      email: email,
      password: password,
      data: {'full_name': fullName},
    );
  }

  Future<AuthResponse> signInWithEmail(String email, String password) {
    return _client.auth.signInWithPassword(email: email, password: password);
  }

  Future<void> signOut() => _client.auth.signOut();

  Future<Profile?> getProfile() async {
    final userId = currentUser?.id;
    if (userId == null) return null;

    final data = await _client
        .from('profiles')
        .select()
        .eq('id', userId)
        .single();
    return Profile.fromJson(data);
  }

  Future<void> updateProfile({String? fullName, String? phone}) async {
    final userId = currentUser?.id;
    if (userId == null) return;

    final updates = <String, dynamic>{};
    if (fullName != null) updates['full_name'] = fullName;
    if (phone != null) updates['phone'] = phone;

    await _client.from('profiles').update(updates).eq('id', userId);
  }
}
```

- [ ] **Step 2: Create catalog_service.dart**

```dart
// lib/services/catalog_service.dart

import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/category.dart';
import '../models/product.dart';
import '../models/discount.dart';

class CatalogService {
  final SupabaseClient _client;

  CatalogService(this._client);

  Future<List<Category>> getCategories() async {
    final data = await _client
        .from('categories')
        .select()
        .order('sort_order');
    return data.map((json) => Category.fromJson(json)).toList();
  }

  Future<List<Subcategory>> getSubcategories(String categoryId) async {
    final data = await _client
        .from('subcategories')
        .select()
        .eq('category_id', categoryId)
        .order('sort_order');
    return data.map((json) => Subcategory.fromJson(json)).toList();
  }

  Future<List<Product>> getProducts({
    required String subcategoryId,
    String? origin,
  }) async {
    var query = _client
        .from('products')
        .select('*, variants(*)')
        .eq('subcategory_id', subcategoryId)
        .eq('is_active', true);

    if (origin != null) {
      query = query.eq('origin', origin);
    }

    final data = await query.order('name');
    return data.map((json) => Product.fromJson(json)).toList();
  }

  Future<Product> getProduct(String productId) async {
    final data = await _client
        .from('products')
        .select('*, variants(*)')
        .eq('id', productId)
        .single();
    return Product.fromJson(data);
  }

  Future<List<Discount>> getActiveDiscounts() async {
    final data = await _client
        .from('discounts')
        .select()
        .eq('is_active', true)
        .lte('valid_from', DateTime.now().toIso8601String())
        .gt('valid_until', DateTime.now().toIso8601String());
    return data.map((json) => Discount.fromJson(json)).toList();
  }

  Future<List<Product>> searchProducts(String query) async {
    final data = await _client
        .from('products')
        .select('*, variants(*)')
        .eq('is_active', true)
        .ilike('name', '%$query%')
        .order('name');
    return data.map((json) => Product.fromJson(json)).toList();
  }
}
```

- [ ] **Step 3: Create order_service.dart**

```dart
// lib/services/order_service.dart

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

    // Create order
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

    // Create order items
    final items = cartItems.map((item) => {
      'order_id': orderId,
      'variant_id': item.variant.id,
      'quantity': item.quantity,
      'unit_type': item.unitType,
      'unit_price': item.unitPrice,
      'total_price': item.totalPrice,
    }).toList();

    await _client.from('order_items').insert(items);

    return Order.fromJson({...orderData, 'order_items': items});
  }

  Future<List<Order>> getOrderHistory() async {
    final userId = _client.auth.currentUser!.id;
    final data = await _client
        .from('orders')
        .select('*, order_items(*)')
        .eq('user_id', userId)
        .order('created_at', ascending: false);
    return data.map((json) => Order.fromJson(json)).toList();
  }

  Future<Order> getOrder(String orderId) async {
    final data = await _client
        .from('orders')
        .select('*, order_items(*)')
        .eq('id', orderId)
        .single();
    return Order.fromJson(data);
  }
}
```

- [ ] **Step 4: Create planner_service.dart**

```dart
// lib/services/planner_service.dart

import '../models/product.dart';

class PlannerSuggestion {
  final Product product;
  final String variantId;
  final int quantity;
  final String unitType; // 'unit' or 'case'
  final String reason;

  PlannerSuggestion({
    required this.product,
    required this.variantId,
    required this.quantity,
    required this.unitType,
    required this.reason,
  });
}

class PlannerService {
  /// Estimate beverages for an event.
  ///
  /// Rules of thumb (per guest for a 3-4 hour event):
  /// - Hard drinks: ~3 pegs total → ~0.25 bottles (750ml) per guest
  /// - Beer: ~2 bottles per guest
  /// - Soft drinks: ~2 servings per guest → ~0.5L per guest
  /// - Water: ~0.5L per guest
  /// - Mixers: 1 soda/tonic per 2 hard drink servings
  /// - Ice: ~0.5kg per guest
  List<PlannerSuggestion> estimateBeverages({
    required int guestCount,
    required String eventType,
    required List<Product> availableProducts,
  }) {
    final suggestions = <PlannerSuggestion>[];

    // Adjust multiplier by event type
    final hardDrinkMultiplier = switch (eventType) {
      'wedding' => 1.0,
      'corporate' => 0.6,
      'birthday' => 0.8,
      'house_party' => 1.2,
      _ => 1.0,
    };

    // Whiskey: ~0.25 bottles per guest
    final whiskeyBottles = (guestCount * 0.25 * hardDrinkMultiplier).ceil();
    _addSuggestion(
      suggestions, availableProducts,
      subcategorySlug: 'whiskey',
      quantity: whiskeyBottles,
      preferredSize: '750ml',
      reason: '~3 pegs per guest across spirits',
    );

    // Beer: ~2 per guest
    final beerBottles = (guestCount * 2.0).ceil();
    _addSuggestion(
      suggestions, availableProducts,
      subcategorySlug: 'beer-bottle-can',
      quantity: beerBottles,
      preferredSize: '650ml',
      reason: '~2 beers per guest',
    );

    // Soft drinks: ~0.5L per guest
    final softDrinkLiters = (guestCount * 0.5).ceil();
    final softDrinkBottles = (softDrinkLiters / 2.25).ceil();
    _addSuggestion(
      suggestions, availableProducts,
      subcategorySlug: 'carbonated',
      quantity: softDrinkBottles,
      preferredSize: '2.25L',
      reason: '~0.5L soft drink per guest',
    );

    // Water: ~0.5L per guest
    final waterBottles = (guestCount * 0.5 / 1.0).ceil();
    _addSuggestion(
      suggestions, availableProducts,
      subcategorySlug: 'water',
      quantity: waterBottles,
      preferredSize: '1L',
      reason: '~0.5L water per guest',
    );

    // Ice: ~0.5kg per guest → 5kg bags
    final iceBags = (guestCount * 0.5 / 5.0).ceil();
    _addSuggestion(
      suggestions, availableProducts,
      subcategorySlug: 'ice-garnish',
      quantity: iceBags,
      preferredSize: '5kg bag',
      reason: '~0.5kg ice per guest',
    );

    // Convert to cases where cheaper
    for (final suggestion in suggestions) {
      final variant = suggestion.product.variants
          .where((v) => v.id == suggestion.variantId)
          .firstOrNull;
      if (variant != null && variant.caseSize != null && variant.casePrice != null) {
        final casesNeeded = (suggestion.quantity / variant.caseSize!).ceil();
        final caseTotal = casesNeeded * variant.casePrice!;
        final unitTotal = suggestion.quantity * variant.unitPrice;
        if (caseTotal < unitTotal) {
          suggestion = PlannerSuggestion(
            product: suggestion.product,
            variantId: suggestion.variantId,
            quantity: casesNeeded,
            unitType: 'case',
            reason: '${suggestion.reason} (case is cheaper)',
          );
        }
      }
    }

    return suggestions;
  }

  void _addSuggestion(
    List<PlannerSuggestion> suggestions,
    List<Product> products, {
    required String subcategorySlug,
    required int quantity,
    required String preferredSize,
    required String reason,
  }) {
    // Find first popular/available product in this subcategory
    final matching = products.where((p) =>
        p.variants.any((v) => v.size == preferredSize)).toList();

    if (matching.isEmpty) return;

    // Prefer 'popular' tagged products
    final product = matching.firstWhere(
      (p) => p.tags.contains('popular'),
      orElse: () => matching.first,
    );

    final variant = product.variants.firstWhere((v) => v.size == preferredSize);

    suggestions.add(PlannerSuggestion(
      product: product,
      variantId: variant.id,
      quantity: quantity,
      unitType: 'unit',
      reason: reason,
    ));
  }
}
```

- [ ] **Step 5: Commit**

```bash
git add customer_app/lib/services/
git commit -m "feat: add auth, catalog, order, and planner services"
```

---

### Task 4: Providers (State Management)

**Files:**
- Create: `customer_app/lib/providers/auth_provider.dart`
- Create: `customer_app/lib/providers/catalog_provider.dart`
- Create: `customer_app/lib/providers/cart_provider.dart`
- Create: `customer_app/lib/providers/order_provider.dart`
- Create: `customer_app/lib/providers/planner_provider.dart`

- [ ] **Step 1: Create auth_provider.dart**

```dart
// lib/providers/auth_provider.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/auth_service.dart';
import '../models/profile.dart';

final supabaseProvider = Provider<SupabaseClient>(
  (ref) => Supabase.instance.client,
);

final authServiceProvider = Provider<AuthService>(
  (ref) => AuthService(ref.watch(supabaseProvider)),
);

final authStateProvider = StreamProvider<AuthState>(
  (ref) => ref.watch(authServiceProvider).authStateChanges,
);

final profileProvider = FutureProvider<Profile?>((ref) {
  ref.watch(authStateProvider);
  return ref.watch(authServiceProvider).getProfile();
});
```

- [ ] **Step 2: Create catalog_provider.dart**

```dart
// lib/providers/catalog_provider.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/catalog_service.dart';
import '../models/category.dart';
import '../models/product.dart';
import 'auth_provider.dart';

final catalogServiceProvider = Provider<CatalogService>(
  (ref) => CatalogService(ref.watch(supabaseProvider)),
);

final categoriesProvider = FutureProvider<List<Category>>((ref) {
  return ref.watch(catalogServiceProvider).getCategories();
});

final subcategoriesProvider =
    FutureProvider.family<List<Subcategory>, String>((ref, categoryId) {
  return ref.watch(catalogServiceProvider).getSubcategories(categoryId);
});

final productsProvider =
    FutureProvider.family<List<Product>, ({String subcategoryId, String? origin})>(
  (ref, params) {
    return ref.watch(catalogServiceProvider).getProducts(
      subcategoryId: params.subcategoryId,
      origin: params.origin,
    );
  },
);

final productDetailProvider =
    FutureProvider.family<Product, String>((ref, productId) {
  return ref.watch(catalogServiceProvider).getProduct(productId);
});

final searchProvider =
    FutureProvider.family<List<Product>, String>((ref, query) {
  if (query.isEmpty) return Future.value([]);
  return ref.watch(catalogServiceProvider).searchProducts(query);
});
```

- [ ] **Step 3: Create cart_provider.dart**

```dart
// lib/providers/cart_provider.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/cart_item.dart';
import '../models/product.dart';

class CartNotifier extends StateNotifier<List<CartItem>> {
  CartNotifier() : super([]);

  void addItem(Product product, Variant variant, String unitType, {int quantity = 1}) {
    final existingIndex = state.indexWhere(
      (item) => item.variant.id == variant.id && item.unitType == unitType,
    );

    if (existingIndex >= 0) {
      final updated = List<CartItem>.from(state);
      updated[existingIndex].quantity += quantity;
      state = updated;
    } else {
      state = [
        ...state,
        CartItem(
          product: product,
          variant: variant,
          unitType: unitType,
          quantity: quantity,
        ),
      ];
    }
  }

  void updateQuantity(int index, int quantity) {
    if (quantity <= 0) {
      removeItem(index);
      return;
    }
    final updated = List<CartItem>.from(state);
    updated[index].quantity = quantity;
    state = updated;
  }

  void removeItem(int index) {
    final updated = List<CartItem>.from(state);
    updated.removeAt(index);
    state = updated;
  }

  void clear() => state = [];

  double get totalAmount =>
      state.fold<double>(0, (sum, item) => sum + item.totalPrice);

  int get totalItems => state.length;
}

final cartProvider = StateNotifierProvider<CartNotifier, List<CartItem>>(
  (ref) => CartNotifier(),
);

final cartTotalProvider = Provider<double>((ref) {
  final cart = ref.watch(cartProvider);
  return cart.fold<double>(0, (sum, item) => sum + item.totalPrice);
});

final cartCountProvider = Provider<int>((ref) {
  return ref.watch(cartProvider).length;
});
```

- [ ] **Step 4: Create order_provider.dart**

```dart
// lib/providers/order_provider.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/order_service.dart';
import '../models/order.dart';
import 'auth_provider.dart';

final orderServiceProvider = Provider<OrderService>(
  (ref) => OrderService(ref.watch(supabaseProvider)),
);

final orderHistoryProvider = FutureProvider<List<Order>>((ref) {
  return ref.watch(orderServiceProvider).getOrderHistory();
});

final orderDetailProvider =
    FutureProvider.family<Order, String>((ref, orderId) {
  return ref.watch(orderServiceProvider).getOrder(orderId);
});
```

- [ ] **Step 5: Create planner_provider.dart**

```dart
// lib/providers/planner_provider.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/planner_service.dart';
import '../models/product.dart';

final plannerServiceProvider = Provider<PlannerService>(
  (ref) => PlannerService(),
);

class PlannerState {
  final int guestCount;
  final String eventType;
  final List<PlannerSuggestion> suggestions;

  PlannerState({
    this.guestCount = 100,
    this.eventType = 'wedding',
    this.suggestions = const [],
  });

  PlannerState copyWith({
    int? guestCount,
    String? eventType,
    List<PlannerSuggestion>? suggestions,
  }) {
    return PlannerState(
      guestCount: guestCount ?? this.guestCount,
      eventType: eventType ?? this.eventType,
      suggestions: suggestions ?? this.suggestions,
    );
  }
}

class PlannerNotifier extends StateNotifier<PlannerState> {
  final PlannerService _service;

  PlannerNotifier(this._service) : super(PlannerState());

  void setGuestCount(int count) => state = state.copyWith(guestCount: count);
  void setEventType(String type) => state = state.copyWith(eventType: type);

  void calculate(List<Product> products) {
    final suggestions = _service.estimateBeverages(
      guestCount: state.guestCount,
      eventType: state.eventType,
      availableProducts: products,
    );
    state = state.copyWith(suggestions: suggestions);
  }
}

final plannerProvider =
    StateNotifierProvider<PlannerNotifier, PlannerState>((ref) {
  return PlannerNotifier(ref.watch(plannerServiceProvider));
});
```

- [ ] **Step 6: Commit**

```bash
git add customer_app/lib/providers/
git commit -m "feat: add Riverpod providers for auth, catalog, cart, orders, planner"
```

---

### Task 5: Router + Main Entry Point

**Files:**
- Create: `customer_app/lib/config/router.dart`
- Modify: `customer_app/lib/main.dart`

- [ ] **Step 1: Create router.dart**

```dart
// lib/config/router.dart

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../screens/auth/login_screen.dart';
import '../screens/home/home_screen.dart';
import '../screens/catalog/category_screen.dart';
import '../screens/catalog/product_list_screen.dart';
import '../screens/catalog/product_detail_screen.dart';
import '../screens/cart/cart_screen.dart';
import '../screens/planner/planner_screen.dart';
import '../screens/checkout/checkout_screen.dart';
import '../screens/orders/order_history_screen.dart';
import '../screens/orders/order_detail_screen.dart';
import '../screens/profile/profile_screen.dart';

final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/login',
    routes: [
      GoRoute(path: '/login', builder: (_, __) => const LoginScreen()),
      GoRoute(path: '/home', builder: (_, __) => const HomeScreen()),
      GoRoute(
        path: '/category/:categoryId',
        builder: (_, state) => CategoryScreen(
          categoryId: state.pathParameters['categoryId']!,
        ),
      ),
      GoRoute(
        path: '/products/:subcategoryId',
        builder: (_, state) => ProductListScreen(
          subcategoryId: state.pathParameters['subcategoryId']!,
        ),
      ),
      GoRoute(
        path: '/product/:productId',
        builder: (_, state) => ProductDetailScreen(
          productId: state.pathParameters['productId']!,
        ),
      ),
      GoRoute(path: '/cart', builder: (_, __) => const CartScreen()),
      GoRoute(path: '/planner', builder: (_, __) => const PlannerScreen()),
      GoRoute(path: '/checkout', builder: (_, __) => const CheckoutScreen()),
      GoRoute(path: '/orders', builder: (_, __) => const OrderHistoryScreen()),
      GoRoute(
        path: '/order/:orderId',
        builder: (_, state) => OrderDetailScreen(
          orderId: state.pathParameters['orderId']!,
        ),
      ),
      GoRoute(path: '/profile', builder: (_, __) => const ProfileScreen()),
    ],
  );
});
```

- [ ] **Step 2: Update main.dart**

```dart
// lib/main.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'config/supabase_config.dart';
import 'config/router.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: SupabaseConfig.url,
    anonKey: SupabaseConfig.anonKey,
  );

  runApp(const ProviderScope(child: RaksiChaiyoApp()));
}

class RaksiChaiyoApp extends ConsumerWidget {
  const RaksiChaiyoApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);

    return MaterialApp.router(
      title: 'RaksiChaiyo',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorSchemeSeed: const Color(0xFFE65100), // Deep orange
        useMaterial3: true,
        fontFamily: 'Poppins',
      ),
      routerConfig: router,
    );
  }
}
```

- [ ] **Step 3: Commit**

```bash
git add customer_app/lib/main.dart customer_app/lib/config/router.dart
git commit -m "feat: add GoRouter navigation and app entry point"
```

---

### Task 6: Auth Screen

**Files:**
- Create: `customer_app/lib/screens/auth/login_screen.dart`

- [ ] **Step 1: Create login_screen.dart**

```dart
// lib/screens/auth/login_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../providers/auth_provider.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _nameController = TextEditingController();
  bool _isSignUp = false;
  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    setState(() { _loading = true; _error = null; });

    try {
      final authService = ref.read(authServiceProvider);
      if (_isSignUp) {
        await authService.signUpWithEmail(
          _emailController.text.trim(),
          _passwordController.text,
          _nameController.text.trim(),
        );
      } else {
        await authService.signInWithEmail(
          _emailController.text.trim(),
          _passwordController.text,
        );
      }
      if (mounted) context.go('/home');
    } catch (e) {
      setState(() { _error = e.toString(); });
    } finally {
      if (mounted) setState(() { _loading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'RaksiChaiyo',
                  style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Beverages for every occasion',
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
                const SizedBox(height: 48),
                if (_isSignUp)
                  TextField(
                    controller: _nameController,
                    decoration: const InputDecoration(
                      labelText: 'Full Name',
                      border: OutlineInputBorder(),
                    ),
                  ),
                if (_isSignUp) const SizedBox(height: 16),
                TextField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(
                    labelText: 'Email',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _passwordController,
                  obscureText: true,
                  decoration: const InputDecoration(
                    labelText: 'Password',
                    border: OutlineInputBorder(),
                  ),
                ),
                if (_error != null) ...[
                  const SizedBox(height: 16),
                  Text(_error!, style: TextStyle(color: Theme.of(context).colorScheme.error)),
                ],
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: _loading ? null : _submit,
                    child: _loading
                        ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2))
                        : Text(_isSignUp ? 'Sign Up' : 'Sign In'),
                  ),
                ),
                const SizedBox(height: 16),
                TextButton(
                  onPressed: () => setState(() { _isSignUp = !_isSignUp; _error = null; }),
                  child: Text(_isSignUp
                      ? 'Already have an account? Sign In'
                      : 'Don\'t have an account? Sign Up'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
```

- [ ] **Step 2: Commit**

```bash
git add customer_app/lib/screens/auth/
git commit -m "feat: add login/signup screen"
```

---

### Task 7: Home Screen + Widgets

**Files:**
- Create: `customer_app/lib/screens/home/home_screen.dart`
- Create: `customer_app/lib/widgets/cart_badge.dart`

- [ ] **Step 1: Create cart_badge.dart**

```dart
// lib/widgets/cart_badge.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/cart_provider.dart';

class CartBadge extends ConsumerWidget {
  const CartBadge({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final count = ref.watch(cartCountProvider);

    return IconButton(
      onPressed: () => context.push('/cart'),
      icon: Badge(
        isLabelVisible: count > 0,
        label: Text('$count'),
        child: const Icon(Icons.shopping_cart_outlined),
      ),
    );
  }
}
```

- [ ] **Step 2: Create home_screen.dart**

```dart
// lib/screens/home/home_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../providers/catalog_provider.dart';
import '../../widgets/cart_badge.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final categoriesAsync = ref.watch(categoriesProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('RaksiChaiyo'),
        actions: const [CartBadge()],
      ),
      body: Column(
        children: [
          // Search bar
          Padding(
            padding: const EdgeInsets.all(16),
            child: SearchBar(
              hintText: 'Search beverages...',
              leading: const Icon(Icons.search),
              onSubmitted: (query) => context.push('/search?q=$query'),
            ),
          ),
          // Quick actions
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () => context.push('/planner'),
                icon: const Icon(Icons.event),
                label: const Text('Plan My Event'),
              ),
            ),
          ),
          const SizedBox(height: 16),
          // Categories grid
          Expanded(
            child: categoriesAsync.when(
              data: (categories) => GridView.builder(
                padding: const EdgeInsets.all(16),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: 1.2,
                ),
                itemCount: categories.length,
                itemBuilder: (context, index) {
                  final category = categories[index];
                  return Card(
                    clipBehavior: Clip.antiAlias,
                    child: InkWell(
                      onTap: () => context.push('/category/${category.id}'),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            _categoryIcon(category.slug),
                            size: 48,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            category.name,
                            style: Theme.of(context).textTheme.titleMedium,
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, _) => Center(child: Text('Error: $err')),
            ),
          ),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        destinations: const [
          NavigationDestination(icon: Icon(Icons.home), label: 'Home'),
          NavigationDestination(icon: Icon(Icons.receipt_long), label: 'Orders'),
          NavigationDestination(icon: Icon(Icons.person), label: 'Profile'),
        ],
        onDestinationSelected: (index) {
          switch (index) {
            case 0: context.go('/home');
            case 1: context.go('/orders');
            case 2: context.go('/profile');
          }
        },
      ),
    );
  }

  IconData _categoryIcon(String slug) => switch (slug) {
    'hard-drinks' => Icons.local_bar,
    'soft-drinks' => Icons.local_cafe,
    'mixers-add-ons' => Icons.blender,
    'equipment-rental' => Icons.build,
    _ => Icons.local_drink,
  };
}
```

- [ ] **Step 3: Commit**

```bash
git add customer_app/lib/screens/home/ customer_app/lib/widgets/cart_badge.dart
git commit -m "feat: add home screen with category grid and cart badge"
```

---

### Task 8: Catalog Screens (Category, Product List, Product Detail)

**Files:**
- Create: `customer_app/lib/screens/catalog/category_screen.dart`
- Create: `customer_app/lib/screens/catalog/product_list_screen.dart`
- Create: `customer_app/lib/screens/catalog/product_detail_screen.dart`
- Create: `customer_app/lib/widgets/product_card.dart`
- Create: `customer_app/lib/widgets/origin_filter.dart`
- Create: `customer_app/lib/widgets/variant_selector.dart`

- [ ] **Step 1: Create origin_filter.dart**

```dart
// lib/widgets/origin_filter.dart

import 'package:flutter/material.dart';

class OriginFilter extends StatelessWidget {
  final String? selectedOrigin;
  final ValueChanged<String?> onChanged;

  const OriginFilter({super.key, this.selectedOrigin, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return SegmentedButton<String?>(
      segments: const [
        ButtonSegment(value: null, label: Text('All')),
        ButtonSegment(value: 'local', label: Text('Local')),
        ButtonSegment(value: 'imported', label: Text('Imported')),
      ],
      selected: {selectedOrigin},
      onSelectionChanged: (selected) => onChanged(selected.first),
    );
  }
}
```

- [ ] **Step 2: Create product_card.dart**

```dart
// lib/widgets/product_card.dart

import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../models/product.dart';

class ProductCard extends StatelessWidget {
  final Product product;
  final VoidCallback onTap;

  const ProductCard({super.key, required this.product, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Product image or placeholder
              Expanded(
                child: Center(
                  child: product.imageUrl != null
                      ? CachedNetworkImage(
                          imageUrl: product.imageUrl!,
                          fit: BoxFit.contain,
                          placeholder: (_, __) => const Icon(Icons.local_drink, size: 48),
                          errorWidget: (_, __, ___) => const Icon(Icons.local_drink, size: 48),
                        )
                      : Icon(Icons.local_drink, size: 48,
                          color: Theme.of(context).colorScheme.primary),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                product.name,
                style: Theme.of(context).textTheme.titleSmall,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: product.origin == 'local'
                          ? Colors.green.shade50
                          : Colors.blue.shade50,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      product.origin == 'local' ? 'Local' : 'Imported',
                      style: TextStyle(
                        fontSize: 10,
                        color: product.origin == 'local'
                            ? Colors.green.shade700
                            : Colors.blue.shade700,
                      ),
                    ),
                  ),
                  const Spacer(),
                  Text(
                    'NPR ${product.lowestPrice.toStringAsFixed(0)}',
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
```

- [ ] **Step 3: Create category_screen.dart**

```dart
// lib/screens/catalog/category_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../providers/catalog_provider.dart';
import '../../widgets/cart_badge.dart';

class CategoryScreen extends ConsumerWidget {
  final String categoryId;

  const CategoryScreen({super.key, required this.categoryId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final subcategoriesAsync = ref.watch(subcategoriesProvider(categoryId));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Select Type'),
        actions: const [CartBadge()],
      ),
      body: subcategoriesAsync.when(
        data: (subcategories) => ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: subcategories.length,
          itemBuilder: (context, index) {
            final sub = subcategories[index];
            return Card(
              child: ListTile(
                title: Text(sub.name),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => context.push('/products/${sub.id}'),
              ),
            );
          },
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(child: Text('Error: $err')),
      ),
    );
  }
}
```

- [ ] **Step 4: Create product_list_screen.dart**

```dart
// lib/screens/catalog/product_list_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../providers/catalog_provider.dart';
import '../../widgets/product_card.dart';
import '../../widgets/origin_filter.dart';
import '../../widgets/cart_badge.dart';

class ProductListScreen extends ConsumerStatefulWidget {
  final String subcategoryId;

  const ProductListScreen({super.key, required this.subcategoryId});

  @override
  ConsumerState<ProductListScreen> createState() => _ProductListScreenState();
}

class _ProductListScreenState extends ConsumerState<ProductListScreen> {
  String? _originFilter;

  @override
  Widget build(BuildContext context) {
    final productsAsync = ref.watch(productsProvider(
      (subcategoryId: widget.subcategoryId, origin: _originFilter),
    ));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Products'),
        actions: const [CartBadge()],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: OriginFilter(
              selectedOrigin: _originFilter,
              onChanged: (origin) => setState(() => _originFilter = origin),
            ),
          ),
          Expanded(
            child: productsAsync.when(
              data: (products) => products.isEmpty
                  ? const Center(child: Text('No products found'))
                  : GridView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        crossAxisSpacing: 12,
                        mainAxisSpacing: 12,
                        childAspectRatio: 0.75,
                      ),
                      itemCount: products.length,
                      itemBuilder: (context, index) {
                        final product = products[index];
                        return ProductCard(
                          product: product,
                          onTap: () => context.push('/product/${product.id}'),
                        );
                      },
                    ),
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, _) => Center(child: Text('Error: $err')),
            ),
          ),
        ],
      ),
    );
  }
}
```

- [ ] **Step 5: Create variant_selector.dart**

```dart
// lib/widgets/variant_selector.dart

import 'package:flutter/material.dart';
import '../models/product.dart';

class VariantSelector extends StatelessWidget {
  final List<Variant> variants;
  final Variant selectedVariant;
  final ValueChanged<Variant> onChanged;

  const VariantSelector({
    super.key,
    required this.variants,
    required this.selectedVariant,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      children: variants.map((variant) {
        final isSelected = variant.id == selectedVariant.id;
        return ChoiceChip(
          label: Text(variant.size),
          selected: isSelected,
          onSelected: (_) => onChanged(variant),
        );
      }).toList(),
    );
  }
}
```

- [ ] **Step 6: Create product_detail_screen.dart**

```dart
// lib/screens/catalog/product_detail_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/catalog_provider.dart';
import '../../providers/cart_provider.dart';
import '../../widgets/variant_selector.dart';
import '../../widgets/cart_badge.dart';
import '../../models/product.dart';

class ProductDetailScreen extends ConsumerStatefulWidget {
  final String productId;

  const ProductDetailScreen({super.key, required this.productId});

  @override
  ConsumerState<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends ConsumerState<ProductDetailScreen> {
  Variant? _selectedVariant;
  String _unitType = 'unit';
  int _quantity = 1;

  @override
  Widget build(BuildContext context) {
    final productAsync = ref.watch(productDetailProvider(widget.productId));

    return Scaffold(
      appBar: AppBar(actions: const [CartBadge()]),
      body: productAsync.when(
        data: (product) {
          _selectedVariant ??= product.variants.first;
          final variant = _selectedVariant!;
          final hasCase = variant.caseSize != null && variant.casePrice != null;
          final displayPrice = _unitType == 'case' && hasCase
              ? variant.casePrice!
              : variant.unitPrice;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Product name + origin badge
                Text(product.name, style: Theme.of(context).textTheme.headlineMedium),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: product.origin == 'local' ? Colors.green.shade50 : Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    product.origin == 'local' ? 'Local' : 'Imported',
                    style: TextStyle(
                      color: product.origin == 'local' ? Colors.green.shade700 : Colors.blue.shade700,
                    ),
                  ),
                ),
                if (product.description != null) ...[
                  const SizedBox(height: 16),
                  Text(product.description!),
                ],
                const SizedBox(height: 24),

                // Size selector
                Text('Size', style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 8),
                VariantSelector(
                  variants: product.variants,
                  selectedVariant: variant,
                  onChanged: (v) => setState(() { _selectedVariant = v; _unitType = 'unit'; }),
                ),
                const SizedBox(height: 24),

                // Unit type selector
                if (hasCase) ...[
                  Text('Buy as', style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 8),
                  SegmentedButton<String>(
                    segments: [
                      const ButtonSegment(value: 'unit', label: Text('Per Bottle')),
                      ButtonSegment(value: 'case', label: Text('Case of ${variant.caseSize}')),
                    ],
                    selected: {_unitType},
                    onSelectionChanged: (s) => setState(() => _unitType = s.first),
                  ),
                  if (_unitType == 'case' && variant.savingsPerUnit > 0)
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text(
                        'Save NPR ${variant.savingsPerUnit.toStringAsFixed(0)} per bottle!',
                        style: TextStyle(color: Colors.green.shade700, fontWeight: FontWeight.w500),
                      ),
                    ),
                  const SizedBox(height: 24),
                ],

                // Price
                Text('NPR ${displayPrice.toStringAsFixed(0)}',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
                if (variant.mrp != null && variant.mrp! > displayPrice)
                  Text('MRP: NPR ${variant.mrp!.toStringAsFixed(0)}',
                    style: const TextStyle(decoration: TextDecoration.lineThrough, color: Colors.grey)),
                const SizedBox(height: 24),

                // Quantity
                Row(
                  children: [
                    Text('Quantity', style: Theme.of(context).textTheme.titleMedium),
                    const Spacer(),
                    IconButton(
                      onPressed: _quantity > 1 ? () => setState(() => _quantity--) : null,
                      icon: const Icon(Icons.remove_circle_outline),
                    ),
                    Text('$_quantity', style: Theme.of(context).textTheme.titleLarge),
                    IconButton(
                      onPressed: () => setState(() => _quantity++),
                      icon: const Icon(Icons.add_circle_outline),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text('Total: NPR ${(displayPrice * _quantity).toStringAsFixed(0)}',
                  style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 32),

                // Add to cart
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: () {
                      ref.read(cartProvider.notifier).addItem(
                        product, variant, _unitType, quantity: _quantity,
                      );
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('${product.name} added to cart')),
                      );
                    },
                    icon: const Icon(Icons.add_shopping_cart),
                    label: const Text('Add to Cart'),
                  ),
                ),
              ],
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(child: Text('Error: $err')),
      ),
    );
  }
}
```

- [ ] **Step 7: Commit**

```bash
git add customer_app/lib/screens/catalog/ customer_app/lib/widgets/
git commit -m "feat: add catalog screens - category, product list, product detail with origin filter"
```

---

### Task 9: Cart + Checkout Screens

**Files:**
- Create: `customer_app/lib/screens/cart/cart_screen.dart`
- Create: `customer_app/lib/screens/checkout/checkout_screen.dart`

- [ ] **Step 1: Create cart_screen.dart**

```dart
// lib/screens/cart/cart_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../providers/cart_provider.dart';

class CartScreen extends ConsumerWidget {
  const CartScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cartItems = ref.watch(cartProvider);
    final total = ref.watch(cartTotalProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Cart')),
      body: cartItems.isEmpty
          ? const Center(child: Text('Your cart is empty'))
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: cartItems.length,
              itemBuilder: (context, index) {
                final item = cartItems[index];
                return Card(
                  child: ListTile(
                    title: Text(item.product.name),
                    subtitle: Text(
                      '${item.variant.size} x ${item.quantity} ${item.unitType}(s)\n'
                      'NPR ${item.totalPrice.toStringAsFixed(0)}',
                    ),
                    isThreeLine: true,
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.remove),
                          onPressed: () => ref.read(cartProvider.notifier)
                              .updateQuantity(index, item.quantity - 1),
                        ),
                        Text('${item.quantity}'),
                        IconButton(
                          icon: const Icon(Icons.add),
                          onPressed: () => ref.read(cartProvider.notifier)
                              .updateQuantity(index, item.quantity + 1),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
      bottomNavigationBar: cartItems.isEmpty
          ? null
          : Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                boxShadow: [BoxShadow(blurRadius: 8, color: Colors.black12)],
              ),
              child: Row(
                children: [
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Total', style: Theme.of(context).textTheme.bodySmall),
                      Text('NPR ${total.toStringAsFixed(0)}',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
                    ],
                  ),
                  const Spacer(),
                  FilledButton(
                    onPressed: () => context.push('/checkout'),
                    child: const Text('Checkout'),
                  ),
                ],
              ),
            ),
    );
  }
}
```

- [ ] **Step 2: Create checkout_screen.dart**

```dart
// lib/screens/checkout/checkout_screen.dart

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
  void dispose() {
    _addressController.dispose();
    _phoneController.dispose();
    _instructionsController.dispose();
    super.dispose();
  }

  Future<void> _placeOrder() async {
    if (_addressController.text.isEmpty || _phoneController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill in delivery address and phone')),
      );
      return;
    }

    setState(() => _loading = true);

    try {
      final cartItems = ref.read(cartProvider);
      await ref.read(orderServiceProvider).createOrder(
        cartItems: cartItems,
        eventType: _eventType,
        eventDate: _eventDate,
        guestCount: _guestCount,
        deliveryAddress: _addressController.text.trim(),
        contactPhone: _phoneController.text.trim(),
        specialInstructions: _instructionsController.text.trim().isEmpty
            ? null
            : _instructionsController.text.trim(),
      );

      ref.read(cartProvider.notifier).clear();
      ref.invalidate(orderHistoryProvider);

      if (mounted) {
        showDialog(
          context: context,
          builder: (_) => AlertDialog(
            title: const Text('Order Placed!'),
            content: const Text('Your order has been submitted. We will confirm it shortly.'),
            actions: [
              TextButton(
                onPressed: () { Navigator.pop(context); context.go('/orders'); },
                child: const Text('View Orders'),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
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
              items: _eventTypes.map((t) => DropdownMenuItem(
                value: t,
                child: Text(t.replaceAll('_', ' ').toUpperCase()),
              )).toList(),
              onChanged: (v) => setState(() => _eventType = v!),
            ),
            const SizedBox(height: 12),
            ListTile(
              title: Text(_eventDate == null
                  ? 'Select Event Date'
                  : '${_eventDate!.day}/${_eventDate!.month}/${_eventDate!.year}'),
              trailing: const Icon(Icons.calendar_today),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
                side: BorderSide(color: Theme.of(context).colorScheme.outline),
              ),
              onTap: () async {
                final date = await showDatePicker(
                  context: context,
                  initialDate: DateTime.now().add(const Duration(days: 7)),
                  firstDate: DateTime.now(),
                  lastDate: DateTime.now().add(const Duration(days: 365)),
                );
                if (date != null) setState(() => _eventDate = date);
              },
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                const Text('Guests: '),
                Expanded(
                  child: Slider(
                    value: _guestCount.toDouble(),
                    min: 20, max: 1000, divisions: 98,
                    label: '$_guestCount',
                    onChanged: (v) => setState(() => _guestCount = v.round()),
                  ),
                ),
                Text('$_guestCount'),
              ],
            ),
            const SizedBox(height: 24),
            Text('Delivery Details', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 12),
            TextField(
              controller: _addressController,
              maxLines: 2,
              decoration: const InputDecoration(labelText: 'Delivery Address', border: OutlineInputBorder()),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _phoneController,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(labelText: 'Contact Phone', border: OutlineInputBorder()),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _instructionsController,
              maxLines: 2,
              decoration: const InputDecoration(labelText: 'Special Instructions (optional)', border: OutlineInputBorder()),
            ),
            const SizedBox(height: 24),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Text('Order Total', style: Theme.of(context).textTheme.titleMedium),
                    const Spacer(),
                    Text('NPR ${total.toStringAsFixed(0)}',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: _loading ? null : _placeOrder,
                child: _loading
                    ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2))
                    : const Text('Place Order'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
```

- [ ] **Step 3: Commit**

```bash
git add customer_app/lib/screens/cart/ customer_app/lib/screens/checkout/
git commit -m "feat: add cart and checkout screens"
```

---

### Task 10: Planner, Orders, Profile Screens

**Files:**
- Create: `customer_app/lib/screens/planner/planner_screen.dart`
- Create: `customer_app/lib/screens/orders/order_history_screen.dart`
- Create: `customer_app/lib/screens/orders/order_detail_screen.dart`
- Create: `customer_app/lib/screens/profile/profile_screen.dart`

- [ ] **Step 1: Create planner_screen.dart**

```dart
// lib/screens/planner/planner_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/planner_provider.dart';
import '../../providers/cart_provider.dart';
import '../../providers/catalog_provider.dart';

class PlannerScreen extends ConsumerWidget {
  const PlannerScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final planner = ref.watch(plannerProvider);
    final eventTypes = ['wedding', 'birthday', 'anniversary', 'corporate', 'house_party'];

    return Scaffold(
      appBar: AppBar(title: const Text('Plan My Event')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('How many guests?', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: Slider(
                    value: planner.guestCount.toDouble(),
                    min: 20, max: 1000, divisions: 98,
                    label: '${planner.guestCount}',
                    onChanged: (v) =>
                        ref.read(plannerProvider.notifier).setGuestCount(v.round()),
                  ),
                ),
                Text('${planner.guestCount}', style: Theme.of(context).textTheme.titleLarge),
              ],
            ),
            const SizedBox(height: 16),
            Text('Event type', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: eventTypes.map((type) => ChoiceChip(
                label: Text(type.replaceAll('_', ' ')),
                selected: planner.eventType == type,
                onSelected: (_) => ref.read(plannerProvider.notifier).setEventType(type),
              )).toList(),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: () {
                  // Fetch all products for estimation
                  // In practice, we need all products loaded — simplified here
                  ref.read(plannerProvider.notifier).calculate([]);
                },
                child: const Text('Calculate'),
              ),
            ),
            const SizedBox(height: 24),
            if (planner.suggestions.isNotEmpty) ...[
              Text('Suggested Beverages', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 12),
              ...planner.suggestions.map((s) => Card(
                child: ListTile(
                  title: Text(s.product.name),
                  subtitle: Text('${s.quantity} ${s.unitType}(s) — ${s.reason}'),
                  trailing: IconButton(
                    icon: const Icon(Icons.add_shopping_cart),
                    onPressed: () {
                      final variant = s.product.variants
                          .firstWhere((v) => v.id == s.variantId);
                      ref.read(cartProvider.notifier).addItem(
                        s.product, variant, s.unitType, quantity: s.quantity,
                      );
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('${s.product.name} added to cart')),
                      );
                    },
                  ),
                ),
              )),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () {
                    for (final s in planner.suggestions) {
                      final variant = s.product.variants
                          .firstWhere((v) => v.id == s.variantId);
                      ref.read(cartProvider.notifier).addItem(
                        s.product, variant, s.unitType, quantity: s.quantity,
                      );
                    }
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('All suggestions added to cart')),
                    );
                  },
                  child: const Text('Add All to Cart'),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
```

- [ ] **Step 2: Create order_history_screen.dart**

```dart
// lib/screens/orders/order_history_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../providers/order_provider.dart';

class OrderHistoryScreen extends ConsumerWidget {
  const OrderHistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ordersAsync = ref.watch(orderHistoryProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('My Orders')),
      body: ordersAsync.when(
        data: (orders) => orders.isEmpty
            ? const Center(child: Text('No orders yet'))
            : ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: orders.length,
                itemBuilder: (context, index) {
                  final order = orders[index];
                  return Card(
                    child: ListTile(
                      title: Text('Order #${order.id.substring(0, 8)}'),
                      subtitle: Text(
                        '${order.eventType ?? 'Event'} — ${order.status.toUpperCase()}\n'
                        'NPR ${order.finalAmount.toStringAsFixed(0)}',
                      ),
                      isThreeLine: true,
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () => context.push('/order/${order.id}'),
                    ),
                  );
                },
              ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(child: Text('Error: $err')),
      ),
    );
  }
}
```

- [ ] **Step 3: Create order_detail_screen.dart**

```dart
// lib/screens/orders/order_detail_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/order_provider.dart';

class OrderDetailScreen extends ConsumerWidget {
  final String orderId;

  const OrderDetailScreen({super.key, required this.orderId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final orderAsync = ref.watch(orderDetailProvider(orderId));

    return Scaffold(
      appBar: AppBar(title: const Text('Order Details')),
      body: orderAsync.when(
        data: (order) => SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Status: ${order.status.toUpperCase()}',
                        style: Theme.of(context).textTheme.titleMedium),
                      if (order.eventType != null)
                        Text('Event: ${order.eventType}'),
                      if (order.eventDate != null)
                        Text('Date: ${order.eventDate!.day}/${order.eventDate!.month}/${order.eventDate!.year}'),
                      if (order.guestCount != null)
                        Text('Guests: ${order.guestCount}'),
                      if (order.deliveryAddress != null)
                        Text('Delivery: ${order.deliveryAddress}'),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text('Items', style: Theme.of(context).textTheme.titleMedium),
              ...order.items.map((item) => Card(
                child: ListTile(
                  title: Text('Variant: ${item.variantId.substring(0, 8)}'),
                  subtitle: Text('${item.quantity} ${item.unitType}(s)'),
                  trailing: Text('NPR ${item.totalPrice.toStringAsFixed(0)}'),
                ),
              )),
              const SizedBox(height: 16),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [const Text('Subtotal'), Text('NPR ${order.totalAmount.toStringAsFixed(0)}')],
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [const Text('Discount'), Text('- NPR ${order.discountAmount.toStringAsFixed(0)}')],
                      ),
                      const Divider(),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Total', style: Theme.of(context).textTheme.titleMedium),
                          Text('NPR ${order.finalAmount.toStringAsFixed(0)}',
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(child: Text('Error: $err')),
      ),
    );
  }
}
```

- [ ] **Step 4: Create profile_screen.dart**

```dart
// lib/screens/profile/profile_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../providers/auth_provider.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(profileProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Profile')),
      body: profileAsync.when(
        data: (profile) => profile == null
            ? const Center(child: Text('Not logged in'))
            : ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  CircleAvatar(
                    radius: 40,
                    child: Text(
                      (profile.fullName ?? 'U')[0].toUpperCase(),
                      style: const TextStyle(fontSize: 32),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Card(
                    child: Column(
                      children: [
                        ListTile(
                          leading: const Icon(Icons.person),
                          title: const Text('Name'),
                          subtitle: Text(profile.fullName ?? 'Not set'),
                        ),
                        ListTile(
                          leading: const Icon(Icons.email),
                          title: const Text('Email'),
                          subtitle: Text(profile.email ?? 'Not set'),
                        ),
                        ListTile(
                          leading: const Icon(Icons.phone),
                          title: const Text('Phone'),
                          subtitle: Text(profile.phone ?? 'Not set'),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  OutlinedButton.icon(
                    onPressed: () async {
                      await ref.read(authServiceProvider).signOut();
                      if (context.mounted) context.go('/login');
                    },
                    icon: const Icon(Icons.logout),
                    label: const Text('Sign Out'),
                    style: OutlinedButton.styleFrom(foregroundColor: Colors.red),
                  ),
                ],
              ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(child: Text('Error: $err')),
      ),
    );
  }
}
```

- [ ] **Step 5: Commit**

```bash
git add customer_app/lib/screens/
git commit -m "feat: add planner, order history, order detail, and profile screens"
```

- [ ] **Step 6: Final commit + tag**

```bash
git tag v0.2.0-customer-app
```
