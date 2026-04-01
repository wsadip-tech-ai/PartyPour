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
    final productsAsync = ref.watch(productsProvider((subcategoryId: widget.subcategoryId, origin: _originFilter)));
    return Scaffold(
      appBar: AppBar(title: const Text('Products'), actions: const [CartBadge()]),
      body: Column(
        children: [
          Padding(padding: const EdgeInsets.all(16), child: OriginFilter(selectedOrigin: _originFilter, onChanged: (origin) => setState(() => _originFilter = origin))),
          Expanded(
            child: productsAsync.when(
              data: (products) => products.isEmpty
                  ? const Center(child: Text('No products found'))
                  : GridView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2, crossAxisSpacing: 12, mainAxisSpacing: 12, childAspectRatio: 0.75),
                      itemCount: products.length,
                      itemBuilder: (context, index) {
                        final product = products[index];
                        return ProductCard(product: product, onTap: () => context.push('/product/${product.id}'));
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
