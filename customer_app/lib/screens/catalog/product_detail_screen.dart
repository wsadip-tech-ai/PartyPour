import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/catalog_provider.dart';
import '../../providers/cart_provider.dart';
import '../../widgets/cart_badge.dart';
import '../../models/product.dart';

class ProductDetailScreen extends ConsumerStatefulWidget {
  final String productId;
  const ProductDetailScreen({super.key, required this.productId});

  @override
  ConsumerState<ProductDetailScreen> createState() =>
      _ProductDetailScreenState();
}

class _ProductDetailScreenState extends ConsumerState<ProductDetailScreen> {
  Variant? _selectedVariant;
  String _unitType = 'unit';
  int _quantity = 1;

  static const _bgColor = Color(0xFF1C1917);
  static const _surfaceColor = Color(0xFF292524);
  static const _goldColor = Color(0xFFCA8A04);
  static const _goldLightColor = Color(0xFFEAB308);
  static const _borderColor = Color(0xFF44403C);
  static const _textPrimary = Color(0xFFFAFAF9);
  static const _textMuted = Color(0xFFA8A29E);
  static const _textDim = Color(0xFF78716C);
  static const _localGreen = Color(0xFF4ade80);

  List<Color> _getColors(String seed) {
    final hash = seed.codeUnits.fold(0, (prev, e) => prev + e);
    final palettes = [
      [const Color(0xFF92400E), const Color(0xFF78350F)],
      [const Color(0xFF1E3A5F), const Color(0xFF0F2137)],
      [const Color(0xFF3B1F5E), const Color(0xFF1A0D2E)],
      [const Color(0xFF134E4A), const Color(0xFF0D3330)],
      [const Color(0xFF431407), const Color(0xFF2D0D04)],
    ];
    return palettes[hash % palettes.length];
  }

  @override
  Widget build(BuildContext context) {
    final productAsync = ref.watch(productDetailProvider(widget.productId));

    return Scaffold(
      backgroundColor: _bgColor,
      appBar: AppBar(
        backgroundColor: _bgColor,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: _textPrimary),
        actions: const [CartBadge()],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: _borderColor),
        ),
      ),
      body: productAsync.when(
        data: (product) {
          _selectedVariant ??= product.variants.first;
          final variant = _selectedVariant!;
          final hasCase =
              variant.caseSize != null && variant.casePrice != null;
          final displayPrice = _unitType == 'case' && hasCase
              ? variant.casePrice!
              : variant.unitPrice;
          final totalPrice = displayPrice * _quantity;
          final colors = _getColors(product.name);
          final isLocal = product.origin == 'local';
          final initial = product.name.isNotEmpty
              ? product.name[0].toUpperCase()
              : '?';

          return SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 40),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Hero Placeholder ──────────────────────────────────
                Center(
                  child: Container(
                    width: 140,
                    height: 140,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: colors,
                      ),
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: _goldColor.withOpacity(0.20),
                          blurRadius: 24,
                          spreadRadius: 0,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Center(
                      child: Text(
                        initial,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 56,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -2,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // ── Product Name + Origin ─────────────────────────────
                Center(
                  child: Column(
                    children: [
                      Text(
                        product.name,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: _textPrimary,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          height: 1.2,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: (isLocal ? _localGreen : _goldLightColor)
                              .withOpacity(0.12),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(
                            color: (isLocal ? _localGreen : _goldLightColor)
                                .withOpacity(0.35),
                            width: 1,
                          ),
                        ),
                        child: Text(
                          isLocal ? 'Local' : 'Imported',
                          style: TextStyle(
                            color: isLocal ? _localGreen : _goldLightColor,
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.3,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // ── Description ───────────────────────────────────────
                if (product.description != null &&
                    product.description!.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  Text(
                    product.description!,
                    style: const TextStyle(
                      color: _textMuted,
                      fontSize: 13,
                      height: 1.5,
                    ),
                  ),
                ],

                const SizedBox(height: 24),
                _divider(),

                // ── Select Size ───────────────────────────────────────
                const SizedBox(height: 20),
                const Text(
                  'Select Size',
                  style: TextStyle(
                    color: _textPrimary,
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: product.variants.map<Widget>((v) {
                    final isSelected = v == _selectedVariant;
                    return GestureDetector(
                      onTap: () => setState(() {
                        _selectedVariant = v;
                        _unitType = 'unit';
                      }),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 160),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 8),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? _goldColor.withOpacity(0.15)
                              : _surfaceColor,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: isSelected ? _goldColor : _borderColor,
                            width: 1.5,
                          ),
                        ),
                        child: Text(
                          v.size,
                          style: TextStyle(
                            color: isSelected ? _goldLightColor : _textMuted,
                            fontWeight: isSelected
                                ? FontWeight.w700
                                : FontWeight.w500,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),

                const SizedBox(height: 20),
                _divider(),

                // ── Pricing Card ──────────────────────────────────────
                const SizedBox(height: 20),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: _surfaceColor,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: _borderColor, width: 1),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Unit price (gold, large)
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.baseline,
                        textBaseline: TextBaseline.alphabetic,
                        children: [
                          Text(
                            'NPR ${variant.unitPrice.toStringAsFixed(0)}',
                            style: const TextStyle(
                              color: _goldLightColor,
                              fontSize: 24,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(width: 6),
                          const Text(
                            '/ bottle',
                            style: TextStyle(
                                color: _textDim,
                                fontSize: 12),
                          ),
                        ],
                      ),

                      // MRP strikethrough
                      if (variant.mrp != null &&
                          variant.mrp! > variant.unitPrice) ...[
                        const SizedBox(height: 3),
                        Text(
                          'MRP: NPR ${variant.mrp!.toStringAsFixed(0)}',
                          style: const TextStyle(
                            color: _textDim,
                            fontSize: 12,
                            decoration: TextDecoration.lineThrough,
                            decorationColor: _textDim,
                          ),
                        ),
                      ],

                      // Case price
                      if (hasCase) ...[
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            const Icon(Icons.inventory_2_outlined,
                                size: 13, color: _textDim),
                            const SizedBox(width: 5),
                            Text(
                              'Case of ${variant.caseSize}: NPR ${variant.casePrice!.toStringAsFixed(0)}',
                              style: const TextStyle(
                                  color: _textMuted, fontSize: 13),
                            ),
                          ],
                        ),
                        // Savings per bottle
                        if (variant.savingsPerUnit > 0) ...[
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              const Icon(Icons.savings_outlined,
                                  size: 13, color: _localGreen),
                              const SizedBox(width: 5),
                              Text(
                                'Save NPR ${variant.savingsPerUnit.toStringAsFixed(0)} per bottle in a case',
                                style: const TextStyle(
                                  color: _localGreen,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ],
                  ),
                ),

                // ── Buy as toggle ─────────────────────────────────────
                if (hasCase) ...[
                  const SizedBox(height: 20),
                  const Text(
                    'Buy as',
                    style: TextStyle(
                      color: _textPrimary,
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      _UnitToggleChip(
                        label: 'Per Bottle',
                        icon: Icons.wine_bar_outlined,
                        isActive: _unitType == 'unit',
                        onTap: () => setState(() => _unitType = 'unit'),
                      ),
                      const SizedBox(width: 10),
                      _UnitToggleChip(
                        label: 'Case of ${variant.caseSize}',
                        icon: Icons.inventory_2_outlined,
                        isActive: _unitType == 'case',
                        onTap: () => setState(() => _unitType = 'case'),
                      ),
                    ],
                  ),
                ],

                const SizedBox(height: 20),
                _divider(),

                // ── Quantity stepper + total ───────────────────────────
                const SizedBox(height: 20),
                Row(
                  children: [
                    const Text(
                      'Quantity',
                      style: TextStyle(
                        color: _textPrimary,
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const Spacer(),
                    // Decrement
                    _QtyButton(
                      icon: Icons.remove,
                      onPressed: _quantity > 1
                          ? () => setState(() => _quantity--)
                          : null,
                    ),
                    GestureDetector(
                      onTap: () => _showEditDialog(context),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 14),
                        child: Text(
                          '$_quantity',
                          style: const TextStyle(
                            color: _textPrimary,
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                    // Increment
                    _QtyButton(
                      icon: Icons.add,
                      onPressed: () => setState(() => _quantity++),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Total display
                Container(
                  width: double.infinity,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: _goldColor.withOpacity(0.06),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                        color: _goldColor.withOpacity(0.20), width: 1),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Total',
                        style: TextStyle(color: _textMuted, fontSize: 14),
                      ),
                      Text(
                        'NPR ${totalPrice.toStringAsFixed(0)}',
                        style: const TextStyle(
                          color: _goldLightColor,
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 28),

                // ── Add to Cart button ────────────────────────────────
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFFCA8A04), Color(0xFFEAB308)],
                        begin: Alignment.centerLeft,
                        end: Alignment.centerRight,
                      ),
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: _goldColor.withOpacity(0.35),
                          blurRadius: 16,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        shadowColor: Colors.transparent,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: () {
                        ref.read(cartProvider.notifier).addItem(
                              product,
                              variant,
                              _unitType,
                              quantity: _quantity,
                            );
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              '${product.name} added to cart',
                              style: const TextStyle(
                                  color: _textPrimary, fontSize: 13),
                            ),
                            backgroundColor: _surfaceColor,
                            behavior: SnackBarBehavior.floating,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                              side: const BorderSide(
                                  color: _borderColor, width: 1),
                            ),
                            margin: const EdgeInsets.all(16),
                          ),
                        );
                      },
                      icon: const Icon(Icons.add_shopping_cart_rounded,
                          color: Color(0xFF1C1917), size: 20),
                      label: const Text(
                        'Add to Cart',
                        style: TextStyle(
                          color: Color(0xFF1C1917),
                          fontWeight: FontWeight.w800,
                          fontSize: 15,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
        loading: () => const Center(
          child: CircularProgressIndicator(
            color: _goldColor,
            strokeWidth: 2.5,
          ),
        ),
        error: (err, _) => Center(
          child: Text(
            'Error: $err',
            style: const TextStyle(color: _textMuted),
          ),
        ),
      ),
    );
  }

  void _showEditDialog(BuildContext context) {
    final controller = TextEditingController(text: '$_quantity');
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: _surfaceColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Quantity', style: TextStyle(color: _textPrimary, fontSize: 16, fontWeight: FontWeight.w600)),
        content: TextField(
          controller: controller,
          autofocus: true,
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          style: const TextStyle(color: _goldColor, fontSize: 28, fontWeight: FontWeight.w800),
          textAlign: TextAlign.center,
          decoration: InputDecoration(
            filled: true, fillColor: _bgColor,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: _borderColor)),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: _borderColor)),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: _goldColor, width: 2)),
          ),
          onSubmitted: (val) {
            setState(() => _quantity = (int.tryParse(val) ?? _quantity).clamp(1, 9999));
            Navigator.pop(context);
          },
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel', style: TextStyle(color: _textDim))),
          TextButton(
            onPressed: () {
              setState(() => _quantity = (int.tryParse(controller.text) ?? _quantity).clamp(1, 9999));
              Navigator.pop(context);
            },
            child: const Text('OK', style: TextStyle(color: _goldColor, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }

  Widget _divider() => Container(height: 1, color: _borderColor);
}

class _UnitToggleChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool isActive;
  final VoidCallback onTap;

  const _UnitToggleChip({
    required this.label,
    required this.icon,
    required this.isActive,
    required this.onTap,
  });

  static const _gold = Color(0xFFCA8A04);
  static const _goldLight = Color(0xFFEAB308);
  static const _surface = Color(0xFF292524);
  static const _border = Color(0xFF44403C);
  static const _muted = Color(0xFFA8A29E);

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isActive ? _gold.withOpacity(0.14) : _surface,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: isActive ? _gold : _border,
              width: 1.5,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon,
                  size: 15,
                  color: isActive ? _goldLight : _muted),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  color: isActive ? _goldLight : _muted,
                  fontWeight:
                      isActive ? FontWeight.w700 : FontWeight.w500,
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _QtyButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onPressed;

  const _QtyButton({required this.icon, this.onPressed});

  @override
  Widget build(BuildContext context) {
    final enabled = onPressed != null;
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: enabled
              ? const Color(0xFFCA8A04).withOpacity(0.12)
              : const Color(0xFF292524),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: enabled
                ? const Color(0xFFCA8A04).withOpacity(0.40)
                : const Color(0xFF44403C),
            width: 1.5,
          ),
        ),
        child: Icon(
          icon,
          size: 17,
          color: enabled
              ? const Color(0xFFEAB308)
              : const Color(0xFF78716C),
        ),
      ),
    );
  }
}
