import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../models/product.dart';

class BrandPickerCard extends StatelessWidget {
  final Product product;
  final Variant? selectedVariant;
  final bool isSelected;
  final ValueChanged<Variant> onSelect;

  const BrandPickerCard({
    super.key,
    required this.product,
    this.selectedVariant,
    required this.isSelected,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isLocal = product.origin == 'local';

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      decoration: BoxDecoration(
        color: isSelected
            ? theme.colorScheme.primaryContainer.withValues(alpha: 0.4)
            : theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isSelected
              ? theme.colorScheme.primary
              : theme.colorScheme.outlineVariant.withValues(alpha: 0.5),
          width: isSelected ? 2 : 1,
        ),
      ),
      padding: const EdgeInsets.all(14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Product image or placeholder
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Container(
              width: 64,
              height: 64,
              color: theme.colorScheme.surfaceContainerLow,
              child: product.imageUrl != null
                  ? CachedNetworkImage(
                      imageUrl: product.imageUrl!,
                      fit: BoxFit.contain,
                      placeholder: (_, __) => _buildMiniPlaceholder(theme),
                      errorWidget: (_, __, ___) => _buildMiniPlaceholder(theme),
                    )
                  : _buildMiniPlaceholder(theme),
            ),
          ),
          const SizedBox(width: 14),
          // Brand info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        product.name,
                        style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
                      ),
                    ),
                    if (isSelected)
                      Container(
                        padding: const EdgeInsets.all(2),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.primary,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.check, color: Colors.white, size: 14),
                      ),
                  ],
                ),
                const SizedBox(height: 4),
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
                const SizedBox(height: 10),
                // Size chips
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: product.variants.map((variant) {
                    final isVariantSelected = selectedVariant?.id == variant.id;
                    return ChoiceChip(
                      label: Text(variant.size),
                      selected: isVariantSelected,
                      onSelected: (_) => onSelect(variant),
                      labelStyle: const TextStyle(fontSize: 11),
                      visualDensity: VisualDensity.compact,
                    );
                  }).toList(),
                ),
                if (selectedVariant != null) ...[
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Text(
                        'NPR ${selectedVariant!.unitPrice.toStringAsFixed(0)}',
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: theme.colorScheme.primary,
                        ),
                      ),
                      Text('/bottle', style: theme.textTheme.bodySmall),
                      if (selectedVariant!.casePrice != null) ...[
                        const SizedBox(width: 12),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.tertiaryContainer.withValues(alpha: 0.5),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            'Case of ${selectedVariant!.caseSize}: NPR ${selectedVariant!.casePrice!.toStringAsFixed(0)}',
                            style: TextStyle(fontSize: 10, fontWeight: FontWeight.w500, color: theme.colorScheme.onTertiaryContainer),
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMiniPlaceholder(ThemeData theme) {
    final initial = product.name.isNotEmpty ? product.name[0].toUpperCase() : '?';
    final hash = product.name.hashCode.abs() % 6;
    final colors = [
      [const Color(0xFFE65100), const Color(0xFFFF8A65)],
      [const Color(0xFF1565C0), const Color(0xFF64B5F6)],
      [const Color(0xFF2E7D32), const Color(0xFF81C784)],
      [const Color(0xFF6A1B9A), const Color(0xFFCE93D8)],
      [const Color(0xFFC62828), const Color(0xFFEF9A9A)],
      [const Color(0xFF00695C), const Color(0xFF80CBC4)],
    ][hash];

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: colors,
        ),
      ),
      child: Center(
        child: Text(
          initial,
          style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white),
        ),
      ),
    );
  }
}
