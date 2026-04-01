import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/catalog_service.dart';
import '../models/category.dart';
import '../models/product.dart';
import 'auth_provider.dart';

final catalogServiceProvider = Provider<CatalogService>((ref) => CatalogService(ref.watch(supabaseProvider)));
final categoriesProvider = FutureProvider<List<Category>>((ref) => ref.watch(catalogServiceProvider).getCategories());
final subcategoriesProvider = FutureProvider.family<List<Subcategory>, String>((ref, categoryId) => ref.watch(catalogServiceProvider).getSubcategories(categoryId));
final productsProvider = FutureProvider.family<List<Product>, ({String subcategoryId, String? origin})>((ref, params) => ref.watch(catalogServiceProvider).getProducts(subcategoryId: params.subcategoryId, origin: params.origin));
final productDetailProvider = FutureProvider.family<Product, String>((ref, productId) => ref.watch(catalogServiceProvider).getProduct(productId));
final searchProvider = FutureProvider.family<List<Product>, String>((ref, query) {
  if (query.isEmpty) return Future.value([]);
  return ref.watch(catalogServiceProvider).searchProducts(query);
});
