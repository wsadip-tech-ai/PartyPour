import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/category.dart';
import '../models/product.dart';
import '../models/discount.dart';

class CatalogService {
  final SupabaseClient _client;
  CatalogService(this._client);

  Future<List<Category>> getCategories() async {
    final data = await _client.from('categories').select().order('sort_order');
    return data.map((json) => Category.fromJson(json)).toList();
  }

  Future<List<Subcategory>> getSubcategories(String categoryId) async {
    final data = await _client.from('subcategories').select().eq('category_id', categoryId).order('sort_order');
    return data.map((json) => Subcategory.fromJson(json)).toList();
  }

  Future<List<Product>> getProducts({required String subcategoryId, String? origin}) async {
    var query = _client.from('products').select('*, variants(*)').eq('subcategory_id', subcategoryId).eq('is_active', true);
    if (origin != null) query = query.eq('origin', origin);
    final data = await query.order('name');
    return data.map((json) => Product.fromJson(json)).toList();
  }

  Future<Product> getProduct(String productId) async {
    final data = await _client.from('products').select('*, variants(*)').eq('id', productId).single();
    return Product.fromJson(data);
  }

  Future<List<Discount>> getActiveDiscounts() async {
    final data = await _client.from('discounts').select().eq('is_active', true).lte('valid_from', DateTime.now().toIso8601String()).gt('valid_until', DateTime.now().toIso8601String());
    return data.map((json) => Discount.fromJson(json)).toList();
  }

  Future<List<Product>> searchProducts(String query) async {
    final data = await _client.from('products').select('*, variants(*)').eq('is_active', true).ilike('name', '%$query%').order('name');
    return data.map((json) => Product.fromJson(json)).toList();
  }
}
