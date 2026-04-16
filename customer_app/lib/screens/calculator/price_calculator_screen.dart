import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../models/product.dart';

const _gold = Color(0xFFCA8A04);
const _goldLight = Color(0xFFEAB308);
const _darkBg = Color(0xFF1C1917);
const _surfaceDark = Color(0xFF292524);
const _textLight = Color(0xFFFAFAF9);
const _muted = Color(0xFF78716C);
const _mutedLight = Color(0xFFA8A29E);
const _border = Color(0xFF44403C);
const _green = Color(0xFF4ade80);

/// Icon mapping for known subcategory slugs.
IconData _iconForSlug(String slug) => switch (slug) {
  'whiskey' => Icons.local_bar,
  'vodka' => Icons.local_bar,
  'rum' => Icons.local_bar,
  'wine' => Icons.wine_bar,
  'beer-bottle-can' => Icons.sports_bar,
  'beer-draught' => Icons.sports_bar,
  'gin' => Icons.local_bar,
  'brandy' => Icons.wine_bar,
  'shots-specials' => Icons.local_fire_department,
  'carbonated' => Icons.local_cafe,
  'juice' => Icons.local_drink,
  'water' => Icons.water_drop,
  'energy-drinks' => Icons.bolt,
  'soda' => Icons.bubble_chart,
  'ice-cream' => Icons.icecream,
  'mixers' => Icons.blender,
  'ice-garnish' => Icons.ac_unit,
  'cocktail-mixers' => Icons.local_bar_outlined,
  'draught-beer-setup' => Icons.settings,
  _ => Icons.liquor,
};

/// A calculator item — product + variant + quantity (independent of wizard)
class _CalcItem {
  final Product product;
  final Variant variant;
  int quantity;
  _CalcItem({required this.product, required this.variant, int quantity = 1}) : quantity = quantity;
  double get total => variant.isCaseOnly && variant.casePrice != null
      ? variant.casePrice! * quantity
      : variant.unitPrice * quantity;
}

class PriceCalculatorScreen extends ConsumerStatefulWidget {
  const PriceCalculatorScreen({super.key});

  @override
  ConsumerState<PriceCalculatorScreen> createState() => _PriceCalculatorScreenState();
}

class _PriceCalculatorScreenState extends ConsumerState<PriceCalculatorScreen> {
  final List<_CalcItem> _items = [];

  // Category data — grouped by parent
  List<Map<String, dynamic>> _categories = [];
  List<Map<String, dynamic>> _subcategories = [];
  String? _selectedSubcategoryId;
  String? _selectedSubcategoryName;

  // Products
  List<Product> _products = [];
  List<Product> _searchResults = [];
  bool _loadingSubs = true;
  bool _loadingProducts = false;
  bool _isSearching = false;

  // Search
  String _search = '';
  final _searchController = TextEditingController();
  Timer? _debounce;

  bool _showCart = false;

  @override
  void initState() {
    super.initState();
    _loadCategoriesAndSubs();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  Future<void> _loadCategoriesAndSubs() async {
    final supabase = Supabase.instance.client;
    final catData = await supabase.from('categories').select().order('sort_order');
    final subData = await supabase.from('subcategories').select('id, name, slug, category_id').order('sort_order');
    if (mounted) {
      setState(() {
        _categories = List<Map<String, dynamic>>.from(catData);
        _subcategories = List<Map<String, dynamic>>.from(subData);
        _loadingSubs = false;
        // Auto-select first
        if (_subcategories.isNotEmpty) {
          _selectSubcategory(_subcategories.first);
        }
      });
    }
  }

  void _selectSubcategory(Map<String, dynamic> sub) {
    setState(() {
      _selectedSubcategoryId = sub['id'] as String;
      _selectedSubcategoryName = sub['name'] as String;
      _search = '';
      _searchController.clear();
      _searchResults = [];
      _isSearching = false;
    });
    _loadProducts(sub['id'] as String);
  }

  void _selectAll() {
    setState(() {
      _selectedSubcategoryId = null;
      _selectedSubcategoryName = 'All Products';
      _search = '';
      _searchController.clear();
      _searchResults = [];
      _isSearching = false;
    });
    _loadAllProducts();
  }

  Future<void> _loadProducts(String subcategoryId) async {
    setState(() => _loadingProducts = true);
    final supabase = Supabase.instance.client;
    final data = await supabase
        .from('products')
        .select('*, variants(*)')
        .eq('subcategory_id', subcategoryId)
        .eq('is_active', true)
        .order('name');
    if (mounted) {
      setState(() {
        _products = data.map((json) => Product.fromJson(json)).toList();
        _loadingProducts = false;
      });
    }
  }

  Future<void> _loadAllProducts() async {
    setState(() => _loadingProducts = true);
    final supabase = Supabase.instance.client;
    final data = await supabase
        .from('products')
        .select('*, variants(*)')
        .eq('is_active', true)
        .order('name');
    if (mounted) {
      setState(() {
        _products = data.map((json) => Product.fromJson(json)).toList();
        _loadingProducts = false;
      });
    }
  }

  void _onSearchChanged(String value) {
    final query = value.toLowerCase();
    setState(() => _search = query);

    _debounce?.cancel();
    if (query.isEmpty) {
      setState(() {
        _isSearching = false;
        _searchResults = [];
      });
      return;
    }

    _debounce = Timer(const Duration(milliseconds: 300), () => _performGlobalSearch(query));
  }

  Future<void> _performGlobalSearch(String query) async {
    setState(() => _isSearching = true);
    final supabase = Supabase.instance.client;
    final data = await supabase
        .from('products')
        .select('*, variants(*)')
        .eq('is_active', true)
        .ilike('name', '%$query%')
        .order('name')
        .limit(50);
    if (mounted && _search == query) {
      final results = data.map((json) => Product.fromJson(json)).toList();
      // Priority sort: starts-with first
      final starts = results.where((p) => p.name.toLowerCase().startsWith(query)).toList();
      final contains = results.where((p) => !p.name.toLowerCase().startsWith(query)).toList();
      setState(() {
        _searchResults = [...starts, ...contains];
        _isSearching = false;
      });
    }
  }

  void _addToCalc(Product product) {
    if (product.variants.isEmpty) return;
    final existing = _items.where((i) => i.product.id == product.id).firstOrNull;
    if (existing != null) {
      setState(() => existing.quantity++);
    } else {
      setState(() => _items.add(_CalcItem(product: product, variant: product.variants.first)));
    }
  }

  void _removeFromCalc(int index) {
    setState(() => _items.removeAt(index));
  }

  double get _grandTotal => _items.fold(0, (sum, i) => sum + i.total);
  int get _totalItems => _items.fold(0, (sum, i) => sum + i.quantity);

  /// Find subcategory name for a product (for global search results)
  String? _subcategoryNameFor(String subcategoryId) {
    final match = _subcategories.where((s) => s['id'] == subcategoryId).firstOrNull;
    return match?['name'] as String?;
  }

  void _showCategorySheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => _CategoryBottomSheet(
        categories: _categories,
        subcategories: _subcategories,
        selectedSubcategoryId: _selectedSubcategoryId,
        onSelect: (sub) {
          Navigator.pop(context);
          _selectSubcategory(sub);
        },
        onSelectAll: () {
          Navigator.pop(context);
          _selectAll();
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // When searching, show global results; otherwise show category products
    final displayProducts = _search.isNotEmpty ? _searchResults : _products;

    return Scaffold(
      backgroundColor: _darkBg,
      appBar: AppBar(
        backgroundColor: _darkBg,
        leading: IconButton(
          icon: const Icon(Icons.close, color: _mutedLight, size: 20),
          onPressed: () => context.pop(),
        ),
        title: const Text('Price Calculator', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: _textLight)),
        actions: [
          if (_items.isNotEmpty)
            GestureDetector(
              onTap: () => setState(() => _items.clear()),
              child: const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16),
                child: Center(child: Text('Clear All', style: TextStyle(fontSize: 12, color: _gold))),
              ),
            ),
        ],
      ),
      body: Column(
        children: [
          // === SEARCH + FILTER ROW ===
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            child: Row(
              children: [
                // Search field
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    style: const TextStyle(color: _textLight, fontSize: 14),
                    decoration: InputDecoration(
                      hintText: 'Search all products...',
                      hintStyle: const TextStyle(color: _muted, fontSize: 14),
                      prefixIcon: const Icon(Icons.search, color: _muted, size: 20),
                      suffixIcon: _search.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear, color: _muted, size: 18),
                              onPressed: () {
                                _searchController.clear();
                                _onSearchChanged('');
                              },
                            )
                          : null,
                      filled: true,
                      fillColor: _surfaceDark,
                      contentPadding: const EdgeInsets.symmetric(vertical: 10),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: _border)),
                      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: _border)),
                      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: _gold, width: 2)),
                    ),
                    onChanged: _onSearchChanged,
                  ),
                ),
                const SizedBox(width: 8),
                // Category filter button
                GestureDetector(
                  onTap: _loadingSubs ? null : _showCategorySheet,
                  child: Container(
                    height: 46,
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      color: _selectedSubcategoryId != null ? _gold.withValues(alpha: 0.12) : _surfaceDark,
                      border: Border.all(color: _selectedSubcategoryId != null ? _gold : _border),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.filter_list_rounded, size: 16,
                          color: _selectedSubcategoryId != null ? _gold : _mutedLight),
                        const SizedBox(width: 6),
                        ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 80),
                          child: Text(
                            _selectedSubcategoryName ?? 'All',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: _selectedSubcategoryId != null ? _gold : _mutedLight,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 2),
                        Icon(Icons.keyboard_arrow_down_rounded, size: 16,
                          color: _selectedSubcategoryId != null ? _gold : _mutedLight),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          // === Searching indicator ===
          if (_isSearching)
            const Padding(
              padding: EdgeInsets.only(top: 8),
              child: SizedBox(height: 2, child: LinearProgressIndicator(color: _gold, backgroundColor: _surfaceDark)),
            ),

          // === PRODUCT LIST ===
          Expanded(
            child: _showCart
                ? _buildCartView()
                : (_search.isNotEmpty
                    ? _buildProductList(displayProducts, showCategory: true)
                    : _buildProductList(displayProducts)),
          ),

          // === BOTTOM BAR — sticky total ===
          if (_items.isNotEmpty)
            GestureDetector(
              onTap: () => setState(() => _showCart = !_showCart),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                decoration: BoxDecoration(
                  color: _surfaceDark,
                  border: Border(top: BorderSide(color: _gold.withValues(alpha: 0.2))),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(color: _gold, borderRadius: BorderRadius.circular(10)),
                      child: Text('$_totalItems', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: _darkBg)),
                    ),
                    const SizedBox(width: 10),
                    Text(_showCart ? 'Browse Products' : 'View Calculation', style: const TextStyle(fontSize: 13, color: _mutedLight)),
                    const SizedBox(width: 4),
                    Icon(_showCart ? Icons.storefront : Icons.receipt_long, size: 14, color: _mutedLight),
                    const Spacer(),
                    Text('NPR ${_grandTotal.toStringAsFixed(0)}', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: _gold)),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildProductList(List<Product> products, {bool showCategory = false}) {
    if (_loadingProducts && _search.isEmpty) {
      return const Center(child: CircularProgressIndicator(color: _gold, strokeWidth: 2));
    }
    if (products.isEmpty && !_isSearching) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.search_off, size: 40, color: _muted),
            const SizedBox(height: 8),
            Text(_search.isNotEmpty ? 'No products match "$_search"' : 'No products in this category',
              style: const TextStyle(color: _muted, fontSize: 14)),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      itemCount: products.length,
      itemBuilder: (_, i) {
        final product = products[i];
        final isInCalc = _items.any((item) => item.product.id == product.id);
        final calcItem = isInCalc ? _items.firstWhere((item) => item.product.id == product.id) : null;
        final initial = product.name.isNotEmpty ? product.name[0].toUpperCase() : '?';
        final colors = _getColors(product.name);
        final isLocal = product.origin == 'local';
        final subcatName = showCategory ? _subcategoryNameFor(product.subcategoryId) : null;

        return Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: isInCalc ? _gold.withValues(alpha: 0.04) : _surfaceDark,
            border: Border.all(color: isInCalc ? _gold.withValues(alpha: 0.3) : _border),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              // Thumbnail
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: Container(
                  width: 44, height: 44,
                  decoration: BoxDecoration(gradient: LinearGradient(colors: colors)),
                  child: Center(child: Text(initial, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: Colors.white))),
                ),
              ),
              const SizedBox(width: 12),
              // Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(product.name, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: _textLight), maxLines: 1, overflow: TextOverflow.ellipsis),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                          decoration: BoxDecoration(
                            color: isLocal ? _green.withValues(alpha: 0.12) : _goldLight.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(isLocal ? 'Domestic' : 'Imported', style: TextStyle(fontSize: 9, fontWeight: FontWeight.w600, color: isLocal ? _green : _goldLight)),
                        ),
                        if (subcatName != null) ...[
                          const SizedBox(width: 4),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                            decoration: BoxDecoration(
                              color: _mutedLight.withValues(alpha: 0.10),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(subcatName, style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w500, color: _mutedLight)),
                          ),
                        ],
                        if (product.variants.isNotEmpty) ...[
                          const SizedBox(width: 6),
                          Text('NPR ${product.lowestPrice.toStringAsFixed(0)}', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: _gold)),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
              // Add / qty control
              if (!isInCalc)
                GestureDetector(
                  onTap: () => _addToCalc(product),
                  child: Container(
                    width: 36, height: 36,
                    decoration: BoxDecoration(color: _gold.withValues(alpha: 0.1), border: Border.all(color: _gold), borderRadius: BorderRadius.circular(10)),
                    child: const Icon(Icons.add, size: 18, color: _gold),
                  ),
                )
              else
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    GestureDetector(
                      onTap: () {
                        if (calcItem!.quantity > 1) {
                          setState(() => calcItem.quantity--);
                        } else {
                          setState(() => _items.remove(calcItem));
                        }
                      },
                      child: Container(
                        width: 30, height: 30,
                        decoration: BoxDecoration(borderRadius: BorderRadius.circular(8), border: Border.all(color: _border)),
                        child: Icon(calcItem!.quantity > 1 ? Icons.remove : Icons.delete_outline, size: 14, color: calcItem.quantity > 1 ? _gold : const Color(0xFFEF4444)),
                      ),
                    ),
                    SizedBox(
                      width: 28,
                      child: Text('${calcItem.quantity}', textAlign: TextAlign.center, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: _textLight)),
                    ),
                    GestureDetector(
                      onTap: () => setState(() => calcItem.quantity++),
                      child: Container(
                        width: 30, height: 30,
                        decoration: BoxDecoration(borderRadius: BorderRadius.circular(8), border: Border.all(color: _border)),
                        child: const Icon(Icons.add, size: 14, color: _gold),
                      ),
                    ),
                    const SizedBox(width: 8),
                    SizedBox(
                      width: 52,
                      child: Text('NPR ${calcItem.total.toStringAsFixed(0)}', textAlign: TextAlign.right, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: _gold)),
                    ),
                  ],
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildCartView() {
    if (_items.isEmpty) {
      return const Center(child: Text('No items added yet', style: TextStyle(color: _muted, fontSize: 14)));
    }

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(20, 12, 20, 8),
            child: Text('YOUR CALCULATION', style: TextStyle(fontSize: 11, color: _gold, fontWeight: FontWeight.w700, letterSpacing: 1.0)),
          ),

          ...List.generate(_items.length, (i) {
            final item = _items[i];
            final initial = item.product.name.isNotEmpty ? item.product.name[0].toUpperCase() : '?';
            final colors = _getColors(item.product.name);
            final unitLabel = item.variant.isCaseOnly ? 'case' : 'unit';
            final unitPrice = item.variant.isCaseOnly && item.variant.casePrice != null
                ? item.variant.casePrice!
                : item.variant.unitPrice;

            return Container(
              margin: const EdgeInsets.fromLTRB(16, 0, 16, 8),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: _surfaceDark, border: Border.all(color: _border), borderRadius: BorderRadius.circular(12)),
              child: Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      width: 36, height: 36,
                      decoration: BoxDecoration(gradient: LinearGradient(colors: colors)),
                      child: Center(child: Text(initial, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: Colors.white))),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(item.product.name, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: _textLight), maxLines: 1, overflow: TextOverflow.ellipsis),
                        Text('${item.variant.size} \u2022 NPR ${unitPrice.toStringAsFixed(0)}/$unitLabel', style: const TextStyle(fontSize: 10, color: _muted)),
                      ],
                    ),
                  ),
                  // Qty stepper
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      GestureDetector(
                        onTap: () {
                          if (item.quantity > 1) {
                            setState(() => item.quantity--);
                          } else {
                            _removeFromCalc(i);
                          }
                        },
                        child: Container(
                          width: 30, height: 30,
                          decoration: BoxDecoration(borderRadius: BorderRadius.circular(8), border: Border.all(color: _border)),
                          child: Icon(item.quantity > 1 ? Icons.remove : Icons.delete_outline, size: 14, color: item.quantity > 1 ? _gold : const Color(0xFFEF4444)),
                        ),
                      ),
                      GestureDetector(
                        onTap: () => _showEditDialog(context, item.product.name, item.quantity, (v) => setState(() => item.quantity = v)),
                        child: SizedBox(
                          width: 28,
                          child: Text('${item.quantity}', textAlign: TextAlign.center, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: _textLight)),
                        ),
                      ),
                      GestureDetector(
                        onTap: () => setState(() => item.quantity++),
                        child: Container(
                          width: 30, height: 30,
                          decoration: BoxDecoration(borderRadius: BorderRadius.circular(8), border: Border.all(color: _border)),
                          child: const Icon(Icons.add, size: 14, color: _gold),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(width: 8),
                  SizedBox(
                    width: 58,
                    child: Text('NPR ${item.total.toStringAsFixed(0)}', textAlign: TextAlign.right, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: _gold)),
                  ),
                ],
              ),
            );
          }),

          // Summary
          Container(
            margin: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(color: _surfaceDark, border: Border.all(color: _border), borderRadius: BorderRadius.circular(12)),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Items', style: TextStyle(fontSize: 12, color: _mutedLight)),
                    Text('$_totalItems units', style: const TextStyle(fontSize: 12, color: _mutedLight)),
                  ],
                ),
                Container(height: 1, color: _border, margin: const EdgeInsets.symmetric(vertical: 8)),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Estimated Total', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: _textLight)),
                    Text('NPR ${_grandTotal.toStringAsFixed(0)}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: _gold)),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showEditDialog(BuildContext context, String label, int current, ValueChanged<int> onChanged) {
    final controller = TextEditingController(text: '$current');
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: _surfaceDark,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(label, style: const TextStyle(color: _textLight, fontSize: 16, fontWeight: FontWeight.w600)),
        content: TextField(
          controller: controller,
          autofocus: true,
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          style: const TextStyle(color: _gold, fontSize: 28, fontWeight: FontWeight.w800),
          textAlign: TextAlign.center,
          decoration: InputDecoration(
            filled: true, fillColor: _darkBg,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: _border)),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: _border)),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: _gold, width: 2)),
          ),
          onSubmitted: (val) { onChanged((int.tryParse(val) ?? current).clamp(1, 99999)); Navigator.pop(context); },
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel', style: TextStyle(color: _muted))),
          TextButton(
            onPressed: () { onChanged((int.tryParse(controller.text) ?? current).clamp(1, 99999)); Navigator.pop(context); },
            child: const Text('OK', style: TextStyle(color: _gold, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }

  List<Color> _getColors(String name) {
    final hash = name.hashCode.abs() % 6;
    return [
      [_gold, _goldLight],
      [const Color(0xFF44403C), _surfaceDark],
      [const Color(0xFF1565C0), const Color(0xFF64B5F6)],
      [const Color(0xFF2E7D32), const Color(0xFF81C784)],
      [const Color(0xFFC62828), const Color(0xFFEF9A9A)],
      [const Color(0xFF6A1B9A), const Color(0xFFCE93D8)],
    ][hash];
  }
}

// ─── Category Bottom Sheet ───────────────────────────────────────────────────

class _CategoryBottomSheet extends StatelessWidget {
  final List<Map<String, dynamic>> categories;
  final List<Map<String, dynamic>> subcategories;
  final String? selectedSubcategoryId;
  final ValueChanged<Map<String, dynamic>> onSelect;
  final VoidCallback onSelectAll;

  const _CategoryBottomSheet({
    required this.categories,
    required this.subcategories,
    required this.selectedSubcategoryId,
    required this.onSelect,
    required this.onSelectAll,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.65),
      decoration: const BoxDecoration(
        color: _darkBg,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        border: Border(top: BorderSide(color: _gold, width: 1.5)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle bar
          Container(
            margin: const EdgeInsets.only(top: 10, bottom: 4),
            width: 36,
            height: 4,
            decoration: BoxDecoration(color: _muted, borderRadius: BorderRadius.circular(2)),
          ),
          // Title row
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
            child: Row(
              children: [
                const Icon(Icons.filter_list_rounded, size: 18, color: _gold),
                const SizedBox(width: 8),
                const Text('Filter by Category', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: _textLight)),
                const Spacer(),
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: const Icon(Icons.close, size: 20, color: _mutedLight),
                ),
              ],
            ),
          ),
          Container(height: 1, color: _border),

          // Scrollable content
          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // "All Products" chip
                  GestureDetector(
                    onTap: onSelectAll,
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      margin: const EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(
                        color: selectedSubcategoryId == null
                            ? _gold.withValues(alpha: 0.15)
                            : _surfaceDark,
                        border: Border.all(
                          color: selectedSubcategoryId == null ? _gold : _border,
                          width: selectedSubcategoryId == null ? 1.5 : 1,
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.grid_view_rounded, size: 16,
                            color: selectedSubcategoryId == null ? _gold : _mutedLight),
                          const SizedBox(width: 8),
                          Text(
                            'All Products',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: selectedSubcategoryId == null ? _gold : _mutedLight,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Grouped categories
                  ...categories.map((cat) {
                    final catId = cat['id'] as String;
                    final catName = cat['name'] as String;
                    final subs = subcategories.where((s) => s['category_id'] == catId).toList();
                    if (subs.isEmpty) return const SizedBox.shrink();

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Parent category header
                        Padding(
                          padding: const EdgeInsets.only(bottom: 8, left: 4),
                          child: Text(
                            catName.toUpperCase(),
                            style: const TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: _mutedLight,
                              letterSpacing: 1.2,
                            ),
                          ),
                        ),
                        // Subcategory chips in a grid
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: subs.map((sub) {
                            final isActive = sub['id'] == selectedSubcategoryId;
                            final slug = (sub['slug'] as String?) ?? '';
                            return GestureDetector(
                              onTap: () => onSelect(sub),
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                decoration: BoxDecoration(
                                  color: isActive ? _gold.withValues(alpha: 0.15) : _surfaceDark,
                                  border: Border.all(
                                    color: isActive ? _gold : _border,
                                    width: isActive ? 1.5 : 1,
                                  ),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(_iconForSlug(slug), size: 14,
                                      color: isActive ? _gold : _muted),
                                    const SizedBox(width: 6),
                                    Text(
                                      sub['name'] as String,
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
                                        color: isActive ? _gold : _mutedLight,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                        const SizedBox(height: 16),
                      ],
                    );
                  }),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
