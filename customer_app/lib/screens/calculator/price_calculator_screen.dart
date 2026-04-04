import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../providers/wizard_provider.dart';

const _gold = Color(0xFFCA8A04);
const _goldLight = Color(0xFFEAB308);
const _darkBg = Color(0xFF1C1917);
const _surfaceDark = Color(0xFF292524);
const _textLight = Color(0xFFFAFAF9);
const _muted = Color(0xFF78716C);
const _mutedLight = Color(0xFFA8A29E);
const _border = Color(0xFF44403C);
const _green = Color(0xFF4ade80);

class PriceCalculatorScreen extends ConsumerWidget {
  const PriceCalculatorScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final wizard = ref.watch(wizardProvider);

    // Calculate totals and savings
    int totalBottles = 0;
    int totalCategories = 0;
    double caseSavings = 0;
    for (final entry in wizard.brandSelections.entries) {
      final selections = entry.value;
      if (selections.isNotEmpty) {
        totalCategories++;
        for (final s in selections) {
          totalBottles += s.quantity;
          if (s.unitType == 'case' && s.variant.casePrice != null && s.variant.caseSize != null) {
            final bottleEquivPrice = s.variant.unitPrice * s.variant.caseSize!;
            final caseSaving = (bottleEquivPrice - s.variant.casePrice!) * s.quantity;
            caseSavings += caseSaving;
          }
        }
      }
    }

    return Scaffold(
      backgroundColor: _darkBg,
      appBar: AppBar(
        backgroundColor: _darkBg,
        leading: GestureDetector(
          onTap: () => context.pop(),
          child: Center(
            child: Container(
              width: 32, height: 32,
              decoration: BoxDecoration(borderRadius: BorderRadius.circular(8), border: Border.all(color: _border)),
              child: const Icon(Icons.close, size: 16, color: _mutedLight),
            ),
          ),
        ),
        title: const Text('Price Calculator', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: _textLight)),
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Live indicator
                  Container(
                    margin: const EdgeInsets.fromLTRB(20, 8, 20, 12),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(colors: [_gold.withValues(alpha: 0.06), _gold.withValues(alpha: 0.02)]),
                      border: Border.all(color: _gold.withValues(alpha: 0.12)),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      children: [
                        Container(width: 6, height: 6, decoration: const BoxDecoration(color: _green, shape: BoxShape.circle)),
                        const SizedBox(width: 8),
                        const Text('Prices update as you change quantities', style: TextStyle(fontSize: 11, color: _mutedLight)),
                      ],
                    ),
                  ),

                  // Item rows grouped by category
                  ...wizard.brandSelections.entries.map((entry) {
                    final slug = entry.key;
                    final selections = entry.value;
                    if (selections.isEmpty) return const SizedBox.shrink();

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Category label
                        Padding(
                          padding: const EdgeInsets.fromLTRB(20, 8, 20, 6),
                          child: Text(slug.replaceAll('-', ' ').toUpperCase(),
                            style: const TextStyle(fontSize: 11, color: _gold, fontWeight: FontWeight.w700, letterSpacing: 1.0)),
                        ),

                        // Compact rows
                        ...selections.asMap().entries.map((selEntry) {
                          final idx = selEntry.key;
                          final sel = selEntry.value;
                          final initial = sel.product.name.isNotEmpty ? sel.product.name[0].toUpperCase() : '?';
                          final colors = _getColors(sel.product.name);
                          final hasCase = sel.variant.caseSize != null && sel.variant.casePrice != null;

                          return Container(
                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                            decoration: BoxDecoration(
                              color: idx.isEven ? Colors.transparent : Colors.white.withValues(alpha: 0.01),
                            ),
                            child: Row(
                              children: [
                                // Brand thumbnail
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: Container(
                                    width: 34, height: 34,
                                    decoration: BoxDecoration(gradient: LinearGradient(colors: colors)),
                                    child: Center(child: Text(initial, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: Colors.white))),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                // Name + size
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(sel.product.name, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: _textLight), overflow: TextOverflow.ellipsis, maxLines: 1),
                                      Text(sel.variant.size, style: const TextStyle(fontSize: 10, color: _muted)),
                                    ],
                                  ),
                                ),
                                // Btl / Case toggle
                                if (hasCase)
                                  Container(
                                    decoration: BoxDecoration(color: _surfaceDark, borderRadius: BorderRadius.circular(6)),
                                    padding: const EdgeInsets.all(2),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: ['unit', 'case'].map((type) {
                                        final isActive = sel.unitType == type;
                                        return GestureDetector(
                                          onTap: () {
                                            sel.unitType = type;
                                            ref.read(wizardProvider.notifier).updateBrandQuantity(slug, idx, sel.quantity);
                                          },
                                          child: Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                            decoration: BoxDecoration(
                                              color: isActive ? _gold : Colors.transparent,
                                              borderRadius: BorderRadius.circular(4),
                                            ),
                                            child: Text(
                                              type == 'unit' ? 'Btl' : 'Case',
                                              style: TextStyle(fontSize: 9, fontWeight: FontWeight.w600, color: isActive ? _darkBg : _muted),
                                            ),
                                          ),
                                        );
                                      }).toList(),
                                    ),
                                  ),
                                if (!hasCase) const SizedBox(width: 50),
                                const SizedBox(width: 8),
                                // Qty stepper
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    GestureDetector(
                                      onTap: sel.quantity > 1 ? () => ref.read(wizardProvider.notifier).updateBrandQuantity(slug, idx, sel.quantity - 1) : null,
                                      child: Container(
                                        width: 36, height: 36,
                                        decoration: BoxDecoration(borderRadius: BorderRadius.circular(10), border: Border.all(color: _border)),
                                        child: Icon(Icons.remove, size: 16, color: sel.quantity > 1 ? _gold : _muted.withValues(alpha: 0.3)),
                                      ),
                                    ),
                                    GestureDetector(
                                      onTap: () => _showEditDialog(context, sel.product.name, sel.quantity, (v) => ref.read(wizardProvider.notifier).updateBrandQuantity(slug, idx, v)),
                                      child: SizedBox(
                                        width: 30,
                                        child: Text('${sel.quantity}', textAlign: TextAlign.center, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: _textLight)),
                                      ),
                                    ),
                                    GestureDetector(
                                      onTap: () => ref.read(wizardProvider.notifier).updateBrandQuantity(slug, idx, sel.quantity + 1),
                                      child: Container(
                                        width: 36, height: 36,
                                        decoration: BoxDecoration(borderRadius: BorderRadius.circular(10), border: Border.all(color: _border)),
                                        child: const Icon(Icons.add, size: 16, color: _gold),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(width: 6),
                                // Price
                                SizedBox(
                                  width: 58,
                                  child: Text(
                                    _formatPrice(sel.totalPrice),
                                    textAlign: TextAlign.right,
                                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: _gold),
                                  ),
                                ),
                              ],
                            ),
                          );
                        }),

                        // Divider
                        Container(height: 1, margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 4), color: _border),
                      ],
                    );
                  }),

                  // Summary section
                  Container(
                    margin: const EdgeInsets.fromLTRB(20, 12, 20, 16),
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: _surfaceDark,
                      border: Border.all(color: _border),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      children: [
                        _SummaryRow(label: 'Bottles', value: '$totalBottles'),
                        const SizedBox(height: 4),
                        _SummaryRow(label: 'Categories', value: '$totalCategories types'),
                        if (caseSavings > 0) ...[
                          const SizedBox(height: 4),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text('Savings (case)', style: TextStyle(fontSize: 12, color: _mutedLight)),
                              Text('- NPR ${caseSavings.toStringAsFixed(0)}', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: _green)),
                            ],
                          ),
                        ],
                        Container(height: 1, color: _border, margin: const EdgeInsets.symmetric(vertical: 8)),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Total', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: _textLight)),
                            Text('NPR ${wizard.grandTotal.toStringAsFixed(0)}', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: _gold)),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Sticky total bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            decoration: BoxDecoration(color: _darkBg, border: Border(top: BorderSide(color: _border.withValues(alpha: 0.5)))),
            child: Row(
              children: [
                const Text('Total', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: _textLight)),
                const Spacer(),
                Text('NPR ${wizard.grandTotal.toStringAsFixed(0)}', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: _gold)),
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
          onSubmitted: (val) {
            onChanged((int.tryParse(val) ?? current).clamp(1, 9999));
            Navigator.pop(context);
          },
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel', style: TextStyle(color: _muted))),
          TextButton(
            onPressed: () {
              onChanged((int.tryParse(controller.text) ?? current).clamp(1, 9999));
              Navigator.pop(context);
            },
            child: const Text('OK', style: TextStyle(color: _gold, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }

  String _formatPrice(double price) {
    if (price >= 100000) return '${(price / 1000).toStringAsFixed(0)}K';
    return price.toStringAsFixed(0);
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

class _SummaryRow extends StatelessWidget {
  final String label;
  final String value;
  const _SummaryRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(fontSize: 12, color: _mutedLight)),
        Text(value, style: const TextStyle(fontSize: 12, color: _mutedLight)),
      ],
    );
  }
}
