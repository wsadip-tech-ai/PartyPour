import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../providers/wizard_provider.dart';
import '../../providers/cart_provider.dart';
import '../../widgets/step_progress.dart';

const _gold = Color(0xFFCA8A04);
const _goldLight = Color(0xFFEAB308);
const _darkBg = Color(0xFF1C1917);
const _surfaceDark = Color(0xFF292524);
const _textLight = Color(0xFFFAFAF9);
const _muted = Color(0xFF78716C);
const _mutedLight = Color(0xFFA8A29E);
const _border = Color(0xFF44403C);

class WizardReviewScreen extends ConsumerWidget {
  const WizardReviewScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final wizard = ref.watch(wizardProvider);

    // Calculate totals
    int totalBottles = 0;
    int totalCategories = 0;
    for (final selections in wizard.brandSelections.values) {
      if (selections.isNotEmpty) {
        totalCategories++;
        for (final s in selections) {
          totalBottles += s.quantity;
        }
      }
    }

    return Scaffold(
      backgroundColor: _darkBg,
      body: SafeArea(
        child: Column(
          children: [
            const StepProgress(currentStep: 5),
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 4, 20, 0),
                      child: RichText(text: const TextSpan(
                        style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: _textLight, height: 1.15, fontFamily: 'Inter'),
                        children: [
                          TextSpan(text: 'Review your\n'),
                          TextSpan(text: 'order', style: TextStyle(fontStyle: FontStyle.italic, color: _gold)),
                        ],
                      )),
                    ),
                    const Padding(
                      padding: EdgeInsets.fromLTRB(20, 6, 20, 0),
                      child: Text('Double-check everything before placing', style: TextStyle(color: _muted, fontSize: 13)),
                    ),

                    // Event banner
                    Container(
                      margin: const EdgeInsets.fromLTRB(20, 14, 20, 16),
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      decoration: BoxDecoration(
                        color: _gold.withValues(alpha: 0.05),
                        border: Border.all(color: _gold.withValues(alpha: 0.12)),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.celebration, size: 18, color: _gold),
                          const SizedBox(width: 10),
                          RichText(text: TextSpan(
                            style: const TextStyle(fontSize: 12, color: _mutedLight, fontFamily: 'Inter'),
                            children: [
                              TextSpan(text: '${wizard.totalPax}', style: const TextStyle(color: _gold, fontWeight: FontWeight.w700)),
                              TextSpan(text: ' guests • ${wizard.eventType.replaceAll('_', ' ')}'),
                              if (wizard.eventDate != null) TextSpan(text: ' • ${wizard.eventDate!.day}/${wizard.eventDate!.month}/${wizard.eventDate!.year}'),
                            ],
                          )),
                        ],
                      ),
                    ),

                    // Category sections — receipt style
                    ...wizard.brandSelections.entries.map((entry) {
                      final slug = entry.key;
                      final selections = entry.value;
                      if (selections.isEmpty) return const SizedBox.shrink();

                      final categoryTotal = selections.fold<double>(0, (sum, s) => sum + s.totalPrice);

                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Category label
                          Padding(
                            padding: const EdgeInsets.fromLTRB(20, 4, 20, 8),
                            child: Text(
                              slug.replaceAll('-', ' ').toUpperCase(),
                              style: const TextStyle(fontSize: 11, color: _gold, fontWeight: FontWeight.w700, letterSpacing: 1.0),
                            ),
                          ),

                          // Line items
                          ...selections.asMap().entries.map((selEntry) {
                            final idx = selEntry.key;
                            final sel = selEntry.value;
                            final initial = sel.product.name.isNotEmpty ? sel.product.name[0].toUpperCase() : '?';
                            final colors = _getColors(sel.product.name);

                            return Padding(
                              padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
                              child: Row(
                                children: [
                                  // Brand thumbnail
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(10),
                                    child: Container(
                                      width: 40, height: 40,
                                      decoration: BoxDecoration(gradient: LinearGradient(colors: colors)),
                                      child: sel.product.imageUrl != null
                                          ? Image.network(sel.product.imageUrl!, fit: BoxFit.contain,
                                              errorBuilder: (_, __, ___) => Center(child: Text(initial, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: Colors.white))))
                                          : Center(child: Text(initial, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: Colors.white))),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  // Info
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(sel.product.name, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: _textLight)),
                                        Text('${sel.variant.size} • NPR ${sel.unitPrice.toStringAsFixed(0)}/bottle',
                                          style: const TextStyle(fontSize: 11, color: _muted)),
                                      ],
                                    ),
                                  ),
                                  // Qty stepper
                                  _MiniQtyStepper(
                                    value: sel.quantity,
                                    onChanged: (v) => ref.read(wizardProvider.notifier).updateBrandQuantity(slug, idx, v),
                                    onTap: () => _showEditDialog(context, sel.product.name, sel.quantity, (v) => ref.read(wizardProvider.notifier).updateBrandQuantity(slug, idx, v)),
                                  ),
                                  // Line price
                                  SizedBox(
                                    width: 72,
                                    child: Text(
                                      'NPR ${sel.totalPrice.toStringAsFixed(0)}',
                                      textAlign: TextAlign.right,
                                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: _gold),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }),

                          // Category subtotal
                          Padding(
                            padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
                            child: Align(
                              alignment: Alignment.centerRight,
                              child: Text('Subtotal: NPR ${categoryTotal.toStringAsFixed(0)}',
                                style: const TextStyle(fontSize: 12, color: _mutedLight)),
                            ),
                          ),

                          // Divider
                          Container(height: 1, margin: const EdgeInsets.symmetric(horizontal: 20), color: _border),
                          const SizedBox(height: 8),
                        ],
                      );
                    }),

                    // Total summary box
                    Container(
                      margin: const EdgeInsets.fromLTRB(20, 8, 20, 12),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: _surfaceDark,
                        border: Border.all(color: _border),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text('Items', style: TextStyle(fontSize: 13, color: _mutedLight)),
                              Text('$totalBottles bottles', style: const TextStyle(fontSize: 13, color: _mutedLight)),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text('Categories', style: TextStyle(fontSize: 13, color: _mutedLight)),
                              Text('$totalCategories types', style: const TextStyle(fontSize: 13, color: _mutedLight)),
                            ],
                          ),
                          Container(height: 1, color: _border, margin: const EdgeInsets.symmetric(vertical: 10)),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text('Grand Total', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: _textLight)),
                              Text('NPR ${wizard.grandTotal.toStringAsFixed(0)}',
                                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: _gold)),
                            ],
                          ),
                        ],
                      ),
                    ),

                    // Action buttons
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
                      child: Row(
                        children: [
                          Expanded(
                            child: GestureDetector(
                              onTap: () => context.push('/calculator'),
                              child: Container(
                                padding: const EdgeInsets.symmetric(vertical: 12),
                                decoration: BoxDecoration(border: Border.all(color: _border), borderRadius: BorderRadius.circular(12)),
                                child: const Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.calculate_outlined, size: 16, color: _gold),
                                    SizedBox(width: 6),
                                    Text('Price Calculator', style: TextStyle(fontSize: 12, color: _mutedLight)),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: GestureDetector(
                              onTap: () {}, // TODO: chat support
                              child: Container(
                                padding: const EdgeInsets.symmetric(vertical: 12),
                                decoration: BoxDecoration(border: Border.all(color: _border), borderRadius: BorderRadius.circular(12)),
                                child: const Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.chat_outlined, size: 16, color: _gold),
                                    SizedBox(width: 6),
                                    Text('Chat Support', style: TextStyle(fontSize: 12, color: _mutedLight)),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Bottom bar
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: _darkBg, boxShadow: [BoxShadow(blurRadius: 12, color: Colors.black.withValues(alpha: 0.3))]),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: GestureDetector(
                          onTap: () => context.pop(),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            decoration: BoxDecoration(border: Border.all(color: _gold, width: 1.5), borderRadius: BorderRadius.circular(14)),
                            child: const Center(child: Text('Back', style: TextStyle(color: _gold, fontSize: 14, fontWeight: FontWeight.w600))),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        flex: 2,
                        child: GestureDetector(
                          onTap: () {
                            final cart = ref.read(cartProvider.notifier);
                            cart.clear();
                            for (final selections in wizard.brandSelections.values) {
                              for (final sel in selections) {
                                cart.addItem(sel.product, sel.variant, sel.unitType, quantity: sel.quantity);
                              }
                            }
                            context.push('/checkout');
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(colors: [_gold, _goldLight]),
                              borderRadius: BorderRadius.circular(14),
                              boxShadow: [BoxShadow(color: _gold.withValues(alpha: 0.25), blurRadius: 16, offset: const Offset(0, 4))],
                            ),
                            child: const Center(child: Text('Place Order', style: TextStyle(color: _darkBg, fontWeight: FontWeight.w700, fontSize: 15, letterSpacing: 0.3))),
                          ),
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

  void _showEditDialog(BuildContext context, String label, int current, ValueChanged<int> onChanged) {
    final controller = TextEditingController(text: '$current');
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: _surfaceDark,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(label, style: const TextStyle(color: _textLight, fontSize: 16, fontWeight: FontWeight.w600)),
        content: TextField(
          controller: controller, autofocus: true,
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
          onSubmitted: (val) { onChanged((int.tryParse(val) ?? current).clamp(1, 9999)); Navigator.pop(context); },
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel', style: TextStyle(color: _muted))),
          TextButton(onPressed: () { onChanged((int.tryParse(controller.text) ?? current).clamp(1, 9999)); Navigator.pop(context); },
            child: const Text('OK', style: TextStyle(color: _gold, fontWeight: FontWeight.w700))),
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

class _MiniQtyStepper extends StatelessWidget {
  final int value;
  final ValueChanged<int> onChanged;
  final VoidCallback onTap;
  const _MiniQtyStepper({required this.value, required this.onChanged, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        GestureDetector(
          onTap: value > 1 ? () => onChanged(value - 1) : null,
          child: Container(
            width: 36, height: 36,
            decoration: BoxDecoration(borderRadius: BorderRadius.circular(10), border: Border.all(color: _border)),
            child: Icon(Icons.remove, size: 16, color: value > 1 ? _gold : _muted.withValues(alpha: 0.3)),
          ),
        ),
        GestureDetector(
          onTap: onTap,
          child: SizedBox(
            width: 32,
            child: Text('$value', textAlign: TextAlign.center, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: _textLight)),
          ),
        ),
        GestureDetector(
          onTap: () => onChanged(value + 1),
          child: Container(
            width: 36, height: 36,
            decoration: BoxDecoration(borderRadius: BorderRadius.circular(10), border: Border.all(color: _border)),
            child: const Icon(Icons.add, size: 16, color: _gold),
          ),
        ),
      ],
    );
  }
}
