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
          final displayPrice = _unitType == 'case' && hasCase ? variant.casePrice! : variant.unitPrice;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(product.name, style: Theme.of(context).textTheme.headlineMedium),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(color: product.origin == 'local' ? Colors.green.shade50 : Colors.blue.shade50, borderRadius: BorderRadius.circular(4)),
                  child: Text(product.origin == 'local' ? 'Local' : 'Imported', style: TextStyle(color: product.origin == 'local' ? Colors.green.shade700 : Colors.blue.shade700)),
                ),
                if (product.description != null) ...[const SizedBox(height: 16), Text(product.description!)],
                const SizedBox(height: 24),
                Text('Size', style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 8),
                VariantSelector(variants: product.variants, selectedVariant: variant, onChanged: (v) => setState(() { _selectedVariant = v; _unitType = 'unit'; })),
                const SizedBox(height: 24),
                if (hasCase) ...[
                  Text('Buy as', style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 8),
                  SegmentedButton<String>(
                    segments: [const ButtonSegment(value: 'unit', label: Text('Per Bottle')), ButtonSegment(value: 'case', label: Text('Case of ${variant.caseSize}'))],
                    selected: {_unitType},
                    onSelectionChanged: (s) => setState(() => _unitType = s.first),
                  ),
                  if (_unitType == 'case' && variant.savingsPerUnit > 0)
                    Padding(padding: const EdgeInsets.only(top: 8), child: Text('Save NPR ${variant.savingsPerUnit.toStringAsFixed(0)} per bottle!', style: TextStyle(color: Colors.green.shade700, fontWeight: FontWeight.w500))),
                  const SizedBox(height: 24),
                ],
                Text('NPR ${displayPrice.toStringAsFixed(0)}', style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
                if (variant.mrp != null && variant.mrp! > displayPrice) Text('MRP: NPR ${variant.mrp!.toStringAsFixed(0)}', style: const TextStyle(decoration: TextDecoration.lineThrough, color: Colors.grey)),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Text('Quantity', style: Theme.of(context).textTheme.titleMedium),
                    const Spacer(),
                    IconButton(onPressed: _quantity > 1 ? () => setState(() => _quantity--) : null, icon: const Icon(Icons.remove_circle_outline)),
                    Text('$_quantity', style: Theme.of(context).textTheme.titleLarge),
                    IconButton(onPressed: () => setState(() => _quantity++), icon: const Icon(Icons.add_circle_outline)),
                  ],
                ),
                const SizedBox(height: 8),
                Text('Total: NPR ${(displayPrice * _quantity).toStringAsFixed(0)}', style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 32),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: () {
                      ref.read(cartProvider.notifier).addItem(product, variant, _unitType, quantity: _quantity);
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('${product.name} added to cart')));
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
