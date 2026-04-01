import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/cart_item.dart';
import '../models/product.dart';

class CartNotifier extends StateNotifier<List<CartItem>> {
  CartNotifier() : super([]);

  void addItem(Product product, Variant variant, String unitType, {int quantity = 1}) {
    final existingIndex = state.indexWhere((item) => item.variant.id == variant.id && item.unitType == unitType);
    if (existingIndex >= 0) {
      final updated = List<CartItem>.from(state);
      updated[existingIndex].quantity += quantity;
      state = updated;
    } else {
      state = [...state, CartItem(product: product, variant: variant, unitType: unitType, quantity: quantity)];
    }
  }

  void updateQuantity(int index, int quantity) {
    if (quantity <= 0) { removeItem(index); return; }
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
  double get totalAmount => state.fold<double>(0, (sum, item) => sum + item.totalPrice);
  int get totalItems => state.length;
}

final cartProvider = StateNotifierProvider<CartNotifier, List<CartItem>>((ref) => CartNotifier());
final cartTotalProvider = Provider<double>((ref) => ref.watch(cartProvider).fold<double>(0, (sum, item) => sum + item.totalPrice));
final cartCountProvider = Provider<int>((ref) => ref.watch(cartProvider).length);
