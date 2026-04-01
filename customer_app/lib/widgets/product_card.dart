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
              Expanded(
                child: Center(
                  child: product.imageUrl != null
                      ? CachedNetworkImage(imageUrl: product.imageUrl!, fit: BoxFit.contain, placeholder: (_, __) => const Icon(Icons.local_drink, size: 48), errorWidget: (_, __, ___) => const Icon(Icons.local_drink, size: 48))
                      : Icon(Icons.local_drink, size: 48, color: Theme.of(context).colorScheme.primary),
                ),
              ),
              const SizedBox(height: 8),
              Text(product.name, style: Theme.of(context).textTheme.titleSmall, maxLines: 1, overflow: TextOverflow.ellipsis),
              const SizedBox(height: 4),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(color: product.origin == 'local' ? Colors.green.shade50 : Colors.blue.shade50, borderRadius: BorderRadius.circular(4)),
                    child: Text(product.origin == 'local' ? 'Local' : 'Imported', style: TextStyle(fontSize: 10, color: product.origin == 'local' ? Colors.green.shade700 : Colors.blue.shade700)),
                  ),
                  const Spacer(),
                  Text('NPR ${product.lowestPrice.toStringAsFixed(0)}', style: Theme.of(context).textTheme.labelLarge?.copyWith(fontWeight: FontWeight.bold)),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
