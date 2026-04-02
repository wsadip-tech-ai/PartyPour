import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../models/product.dart';

class ProductCard extends StatelessWidget {
  final Product product;
  final VoidCallback onTap;

  const ProductCard({super.key, required this.product, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isLocal = product.origin == 'local';

    return Card(
      clipBehavior: Clip.antiAlias,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5)),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image section
            Expanded(
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainerLow,
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                ),
                child: product.imageUrl != null
                    ? CachedNetworkImage(
                        imageUrl: product.imageUrl!,
                        fit: BoxFit.contain,
                        placeholder: (_, __) => _buildPlaceholder(theme),
                        errorWidget: (_, __, ___) => _buildPlaceholder(theme),
                      )
                    : _buildPlaceholder(theme),
              ),
            ),
            // Info section
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product.name,
                    style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: isLocal ? const Color(0xFFE8F5E9) : const Color(0xFFE3F2FD),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          isLocal ? 'Local' : 'Imported',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: isLocal ? const Color(0xFF2E7D32) : const Color(0xFF1565C0),
                          ),
                        ),
                      ),
                      const Spacer(),
                      Text(
                        'NPR ${product.lowestPrice.toStringAsFixed(0)}',
                        style: theme.textTheme.labelLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: theme.colorScheme.primary,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlaceholder(ThemeData theme) {
    // Stylish gradient placeholder with brand initial
    final initial = product.name.isNotEmpty ? product.name[0].toUpperCase() : '?';
    final colors = _getGradientColors(product.name);

    return Center(
      child: Container(
        width: 72,
        height: 72,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: colors,
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: colors[0].withValues(alpha: 0.3),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Center(
          child: Text(
            initial,
            style: const TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ),
      ),
    );
  }

  List<Color> _getGradientColors(String name) {
    final hash = name.hashCode.abs() % 8;
    switch (hash) {
      case 0: return [const Color(0xFFE65100), const Color(0xFFFF8A65)]; // Deep orange
      case 1: return [const Color(0xFF1565C0), const Color(0xFF64B5F6)]; // Blue
      case 2: return [const Color(0xFF2E7D32), const Color(0xFF81C784)]; // Green
      case 3: return [const Color(0xFF6A1B9A), const Color(0xFFCE93D8)]; // Purple
      case 4: return [const Color(0xFFC62828), const Color(0xFFEF9A9A)]; // Red
      case 5: return [const Color(0xFF00695C), const Color(0xFF80CBC4)]; // Teal
      case 6: return [const Color(0xFF4527A0), const Color(0xFF9FA8DA)]; // Indigo
      default: return [const Color(0xFF37474F), const Color(0xFF90A4AE)]; // Blue grey
    }
  }
}
