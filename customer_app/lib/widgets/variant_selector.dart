import 'package:flutter/material.dart';
import '../models/product.dart';

class VariantSelector extends StatelessWidget {
  final List<Variant> variants;
  final Variant selectedVariant;
  final ValueChanged<Variant> onChanged;

  const VariantSelector({super.key, required this.variants, required this.selectedVariant, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      children: variants.map((variant) {
        final isSelected = variant.id == selectedVariant.id;
        return ChoiceChip(label: Text(variant.size), selected: isSelected, onSelected: (_) => onChanged(variant));
      }).toList(),
    );
  }
}
