// lib/widgets/brand_picker_card.dart

import 'package:flutter/material.dart';
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
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      decoration: BoxDecoration(
        color: isSelected
            ? theme.colorScheme.primaryContainer.withOpacity(0.5)
            : theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isSelected
              ? theme.colorScheme.primary
              : theme.colorScheme.outlineVariant,
          width: isSelected ? 2 : 1,
        ),
      ),
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  product.name,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              if (isSelected)
                Icon(Icons.check_circle, color: theme.colorScheme.primary, size: 20),
              const SizedBox(width: 4),
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
                    fontWeight: FontWeight.w500,
                    color: product.origin == 'local'
                        ? Colors.green.shade700
                        : Colors.blue.shade700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 6,
            children: product.variants.map((variant) {
              final isVariantSelected = selectedVariant?.id == variant.id;
              return ChoiceChip(
                label: Text(variant.size),
                selected: isVariantSelected,
                onSelected: (_) => onSelect(variant),
                labelStyle: TextStyle(fontSize: 12),
              );
            }).toList(),
          ),
          if (selectedVariant != null) ...[
            const SizedBox(height: 8),
            Text(
              'NPR ${selectedVariant!.unitPrice.toStringAsFixed(0)}/bottle'
              '${selectedVariant!.casePrice != null ? '  •  NPR ${selectedVariant!.casePrice!.toStringAsFixed(0)}/case of ${selectedVariant!.caseSize}' : ''}',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
