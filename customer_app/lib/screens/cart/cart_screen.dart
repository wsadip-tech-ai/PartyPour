import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../providers/cart_provider.dart';

const _gold = Color(0xFFCA8A04);
const _goldLight = Color(0xFFEAB308);
const _darkBg = Color(0xFF1C1917);
const _surfaceDark = Color(0xFF292524);
const _textLight = Color(0xFFFAFAF9);
const _muted = Color(0xFF78716C);
const _mutedLight = Color(0xFFA8A29E);
const _border = Color(0xFF44403C);
const _green = Color(0xFF4ade80);

class CartScreen extends ConsumerWidget {
  const CartScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cartItems = ref.watch(cartProvider);
    final total = ref.watch(cartTotalProvider);
    final count = ref.watch(cartCountProvider);

    int totalBottles = 0;
    for (final item in cartItems) {
      totalBottles += item.effectiveUnits;
    }

    return Scaffold(
      backgroundColor: _darkBg,
      appBar: AppBar(
        backgroundColor: _darkBg,
        leading: IconButton(icon: const Icon(Icons.arrow_back, color: _mutedLight), onPressed: () => context.pop()),
        title: const Text('Cart', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: _textLight)),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Center(child: Text('$count items', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: _gold))),
          ),
        ],
      ),
      body: cartItems.isEmpty
          ? _buildEmptyCart(context)
          : Column(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Summary chips
                        Padding(
                          padding: const EdgeInsets.fromLTRB(20, 8, 20, 8),
                          child: Row(
                            children: [
                              _SummaryChip(label: '$count', suffix: 'items'),
                              const SizedBox(width: 8),
                              _SummaryChip(label: '$totalBottles', suffix: 'bottles'),
                            ],
                          ),
                        ),

                        // Table header
                        Padding(
                          padding: const EdgeInsets.fromLTRB(20, 8, 20, 6),
                          child: Row(
                            children: [
                              const Expanded(child: Text('ITEM', style: TextStyle(fontSize: 10, color: _muted, letterSpacing: 0.08, fontWeight: FontWeight.w600))),
                              const SizedBox(width: 80, child: Center(child: Text('QTY', style: TextStyle(fontSize: 10, color: _muted, letterSpacing: 0.08, fontWeight: FontWeight.w600)))),
                              const SizedBox(width: 68, child: Text('TOTAL', textAlign: TextAlign.right, style: TextStyle(fontSize: 10, color: _muted, letterSpacing: 0.08, fontWeight: FontWeight.w600))),
                            ],
                          ),
                        ),

                        // Cart rows
                        ...cartItems.asMap().entries.map((entry) {
                          final idx = entry.key;
                          final item = entry.value;
                          final initial = item.product.name.isNotEmpty ? item.product.name[0].toUpperCase() : '?';
                          final colors = _getColors(item.product.name);

                          return Dismissible(
                            key: ValueKey('${item.variant.id}_${item.unitType}'),
                            direction: DismissDirection.endToStart,
                            onDismissed: (_) => ref.read(cartProvider.notifier).removeItem(idx),
                            background: Container(
                              alignment: Alignment.centerRight,
                              padding: const EdgeInsets.only(right: 20),
                              color: const Color(0xFFEF4444).withValues(alpha: 0.15),
                              child: const Icon(Icons.delete_outline, color: Color(0xFFEF4444)),
                            ),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                              color: idx.isEven ? Colors.transparent : Colors.white.withValues(alpha: 0.01),
                              child: Row(
                                children: [
                                  // Thumbnail
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(10),
                                    child: Container(
                                      width: 38, height: 38,
                                      decoration: BoxDecoration(gradient: LinearGradient(colors: colors)),
                                      child: item.product.imageUrl != null
                                          ? Image.network(item.product.imageUrl!, fit: BoxFit.contain,
                                              errorBuilder: (_, __, ___) => Center(child: Text(initial, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: Colors.white))))
                                          : Center(child: Text(initial, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: Colors.white))),
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  // Info
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(item.product.name, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: _textLight), maxLines: 1, overflow: TextOverflow.ellipsis),
                                        Text('${item.variant.size} • NPR ${item.unitPrice.toStringAsFixed(0)}', style: const TextStyle(fontSize: 10, color: _muted)),
                                      ],
                                    ),
                                  ),
                                  // Qty
                                  SizedBox(
                                    width: 80,
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        GestureDetector(
                                          onTap: () => ref.read(cartProvider.notifier).updateQuantity(idx, item.quantity - 1),
                                          child: Container(
                                            width: 22, height: 22,
                                            decoration: BoxDecoration(borderRadius: BorderRadius.circular(6), border: Border.all(color: _border)),
                                            child: const Icon(Icons.remove, size: 10, color: _gold),
                                          ),
                                        ),
                                        SizedBox(width: 26, child: Text('${item.quantity}', textAlign: TextAlign.center, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: _textLight))),
                                        GestureDetector(
                                          onTap: () => ref.read(cartProvider.notifier).updateQuantity(idx, item.quantity + 1),
                                          child: Container(
                                            width: 22, height: 22,
                                            decoration: BoxDecoration(borderRadius: BorderRadius.circular(6), border: Border.all(color: _border)),
                                            child: const Icon(Icons.add, size: 10, color: _gold),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  // Price
                                  SizedBox(
                                    width: 68,
                                    child: Text(
                                      'NPR ${item.totalPrice.toStringAsFixed(0)}',
                                      textAlign: TextAlign.right,
                                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: _gold),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        }),

                        Container(height: 1, margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8), color: _border),

                        // Breakdown
                        Container(
                          margin: const EdgeInsets.fromLTRB(20, 4, 20, 8),
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(color: _surfaceDark, border: Border.all(color: _border), borderRadius: BorderRadius.circular(12)),
                          child: Column(
                            children: [
                              _BreakdownRow(label: 'Subtotal', value: 'NPR ${total.toStringAsFixed(0)}'),
                              const SizedBox(height: 4),
                              const _BreakdownRow(label: 'Discount', value: 'NPR 0'),
                              const SizedBox(height: 4),
                              const _BreakdownRow(label: 'Delivery', value: 'FREE', valueColor: _green),
                              Container(height: 1, color: _border, margin: const EdgeInsets.symmetric(vertical: 8)),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  const Text('Grand Total', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: _textLight)),
                                  Text('NPR ${total.toStringAsFixed(0)}', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: _gold)),
                                ],
                              ),
                            ],
                          ),
                        ),

                        // Add more
                        GestureDetector(
                          onTap: () => context.push('/category/a1000000-0000-0000-0000-000000000001'),
                          child: Container(
                            margin: const EdgeInsets.fromLTRB(20, 4, 20, 16),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            decoration: BoxDecoration(
                              border: Border.all(color: _border, style: BorderStyle.solid),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.add, size: 16, color: _gold),
                                SizedBox(width: 6),
                                Text('Add more from catalog', style: TextStyle(fontSize: 12, color: _muted)),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // Bottom checkout bar
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(color: _darkBg, border: Border(top: BorderSide(color: _border.withValues(alpha: 0.5)))),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        children: [
                          Text('Total ($count items)', style: const TextStyle(fontSize: 13, color: _mutedLight)),
                          const Spacer(),
                          Text('NPR ${total.toStringAsFixed(0)}', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: _gold)),
                        ],
                      ),
                      const SizedBox(height: 12),
                      GestureDetector(
                        onTap: () => context.push('/checkout'),
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(colors: [_gold, _goldLight]),
                            borderRadius: BorderRadius.circular(14),
                            boxShadow: [BoxShadow(color: _gold.withValues(alpha: 0.25), blurRadius: 16, offset: const Offset(0, 4))],
                          ),
                          child: const Center(child: Text('Proceed to Checkout', style: TextStyle(color: _darkBg, fontWeight: FontWeight.w700, fontSize: 15, letterSpacing: 0.3))),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildEmptyCart(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.shopping_cart_outlined, size: 64, color: _border),
          const SizedBox(height: 16),
          const Text('Your cart is empty', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: _mutedLight)),
          const SizedBox(height: 8),
          const Text('Start by planning your event', style: TextStyle(fontSize: 13, color: _muted)),
          const SizedBox(height: 24),
          GestureDetector(
            onTap: () => context.go('/home'),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
              decoration: BoxDecoration(
                gradient: const LinearGradient(colors: [_gold, _goldLight]),
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Text('Start Your Order', style: TextStyle(color: _darkBg, fontWeight: FontWeight.w700, fontSize: 14)),
            ),
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

class _SummaryChip extends StatelessWidget {
  final String label;
  final String suffix;
  const _SummaryChip({required this.label, required this.suffix});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(color: _surfaceDark, border: Border.all(color: _border), borderRadius: BorderRadius.circular(10)),
      child: RichText(text: TextSpan(
        style: const TextStyle(fontSize: 11, color: _mutedLight, fontFamily: 'Inter'),
        children: [
          TextSpan(text: label, style: const TextStyle(color: _gold, fontWeight: FontWeight.w700)),
          TextSpan(text: ' $suffix'),
        ],
      )),
    );
  }
}

class _BreakdownRow extends StatelessWidget {
  final String label;
  final String value;
  final Color? valueColor;
  const _BreakdownRow({required this.label, required this.value, this.valueColor});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(fontSize: 12, color: _mutedLight)),
        Text(value, style: TextStyle(fontSize: 12, color: valueColor ?? _mutedLight)),
      ],
    );
  }
}
