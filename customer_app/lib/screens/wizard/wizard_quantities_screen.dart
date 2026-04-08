import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../providers/wizard_provider.dart';
import '../../widgets/step_progress.dart';

const _gold = Color(0xFFCA8A04);
const _goldLight = Color(0xFFEAB308);
const _darkBg = Color(0xFF1C1917);
const _surfaceDark = Color(0xFF292524);
const _textLight = Color(0xFFFAFAF9);
const _muted = Color(0xFF78716C);
const _mutedLight = Color(0xFFA8A29E);
const _border = Color(0xFF44403C);

class WizardQuantitiesScreen extends ConsumerStatefulWidget {
  const WizardQuantitiesScreen({super.key});

  @override
  ConsumerState<WizardQuantitiesScreen> createState() => _WizardQuantitiesScreenState();
}

class _WizardQuantitiesScreenState extends ConsumerState<WizardQuantitiesScreen> {
  bool _calculated = false;

  static const _iconMap = {
    'local_bar': Icons.local_bar,
    'wine_bar': Icons.wine_bar,
    'sports_bar': Icons.sports_bar,
    'local_fire_department': Icons.local_fire_department,
    'bolt': Icons.bolt,
    'blender': Icons.blender,
    'local_cafe': Icons.local_cafe,
    'water_drop': Icons.water_drop,
    'ac_unit': Icons.ac_unit,
  };

  @override
  Widget build(BuildContext context) {
    final wizard = ref.watch(wizardProvider);
    final rulesAsync = ref.watch(estimationRulesProvider);

    return Scaffold(
      backgroundColor: _darkBg,
      body: SafeArea(
        child: Column(
          children: [
            const StepProgress(currentStep: 3),
            Expanded(
              child: rulesAsync.when(
                data: (rules) {
                  if (!_calculated) {
                    _calculated = true;
                    WidgetsBinding.instance.addPostFrameCallback((_) async {
                      final quantities = await ref.read(estimationServiceProvider).estimateQuantities(
                        totalPax: wizard.totalPax,
                        children: wizard.childrenCount,
                        ladies: wizard.ladiesCount,
                        eventType: wizard.eventType,
                        selectedSlugs: wizard.selectedTypeSlugs,
                      );
                      ref.read(wizardProvider.notifier).setEstimatedQuantities(quantities);
                    });
                  }

                  final selectedRules = rules
                      .where((r) => wizard.selectedTypeSlugs.contains(r.subcategorySlug))
                      .toList();

                  return SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Header
                        Padding(
                          padding: const EdgeInsets.fromLTRB(20, 4, 20, 0),
                          child: RichText(text: const TextSpan(
                            style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: _textLight, height: 1.15, fontFamily: 'Inter'),
                            children: [
                              TextSpan(text: "Here's what\nwe "),
                              TextSpan(text: 'recommend', style: TextStyle(fontStyle: FontStyle.italic, color: _gold)),
                            ],
                          )),
                        ),
                        const Padding(
                          padding: EdgeInsets.fromLTRB(20, 6, 20, 0),
                          child: Text('Based on your event — adjust as needed', style: TextStyle(color: _muted, fontSize: 13)),
                        ),

                        // Summary bar
                        Container(
                          margin: const EdgeInsets.fromLTRB(20, 14, 20, 0),
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          decoration: BoxDecoration(
                            color: _surfaceDark,
                            border: Border.all(color: _border),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            children: [
                              Container(width: 8, height: 8, decoration: const BoxDecoration(color: _gold, shape: BoxShape.circle)),
                              const SizedBox(width: 10),
                              RichText(text: TextSpan(
                                style: const TextStyle(fontSize: 12, color: _mutedLight, fontFamily: 'Inter'),
                                children: [
                                  TextSpan(text: '${wizard.totalPax}', style: const TextStyle(color: _gold, fontWeight: FontWeight.w700)),
                                  TextSpan(text: ' guests • ${wizard.eventType.replaceAll('_', ' ')}'),
                                ],
                              )),
                              const Spacer(),
                              Text('${selectedRules.length} types', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: _gold)),
                            ],
                          ),
                        ),

                        // Quantity cards
                        Padding(
                          padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                          child: Column(
                            children: selectedRules.map((rule) {
                              final slug = rule.subcategorySlug;
                              final qty = wizard.estimatedQuantities[slug] ?? 0;
                              final servings = (qty * rule.servingsPerBottle).round();
                              final icon = _iconMap[rule.iconName] ?? Icons.local_drink;
                              final unit = rule.unit;

                              return Container(
                                margin: const EdgeInsets.only(bottom: 12),
                                padding: const EdgeInsets.all(18),
                                decoration: BoxDecoration(
                                  color: _surfaceDark,
                                  border: Border.all(color: _border),
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: Column(
                                  children: [
                                    // Top row: icon + name + servings
                                    Row(
                                      children: [
                                        // Gold left accent
                                        Container(
                                          width: 3, height: 36,
                                          decoration: BoxDecoration(color: _gold, borderRadius: BorderRadius.circular(2)),
                                        ),
                                        const SizedBox(width: 12),
                                        Container(
                                          width: 36, height: 36,
                                          decoration: BoxDecoration(color: _gold.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)),
                                          child: Icon(icon, size: 18, color: _gold),
                                        ),
                                        const SizedBox(width: 12),
                                        Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(rule.label, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: _textLight)),
                                            const SizedBox(height: 2),
                                            Text('~$servings servings for ${wizard.totalPax} guests',
                                              style: const TextStyle(fontSize: 11, color: _muted)),
                                          ],
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 14),
                                    // Centered stepper
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        _StepperButton(
                                          icon: Icons.remove,
                                          onTap: qty > 0 ? () => ref.read(wizardProvider.notifier).updateQuantity(slug, qty - 1) : null,
                                        ),
                                        const SizedBox(width: 16),
                                        GestureDetector(
                                          onTap: () => _showEditDialog(context, rule.label, qty, (v) => ref.read(wizardProvider.notifier).updateQuantity(slug, v)),
                                          child: Column(
                                            children: [
                                              Text('$qty', style: const TextStyle(fontSize: 36, fontWeight: FontWeight.w800, color: _gold, height: 1)),
                                              const SizedBox(height: 2),
                                              Text(unit, style: const TextStyle(fontSize: 10, color: _muted)),
                                            ],
                                          ),
                                        ),
                                        const SizedBox(width: 16),
                                        _StepperButton(
                                          icon: Icons.add,
                                          onTap: () => ref.read(wizardProvider.notifier).updateQuantity(slug, qty + 1),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 4),
                                    const Text('tap number to edit', style: TextStyle(fontSize: 10, color: _muted)),
                                  ],
                                ),
                              );
                            }).toList(),
                          ),
                        ),

                        // Tip
                        Container(
                          margin: const EdgeInsets.fromLTRB(20, 0, 20, 16),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: _gold.withValues(alpha: 0.05),
                            border: Border.all(color: _gold.withValues(alpha: 0.1)),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Row(
                            children: [
                              Icon(Icons.lightbulb_outline, size: 16, color: _gold),
                              SizedBox(width: 8),
                              Expanded(child: Text('These estimates are based on typical consumption. Feel free to adjust!',
                                style: TextStyle(fontSize: 11, color: _mutedLight))),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                },
                loading: () => const Center(child: CircularProgressIndicator(color: _gold)),
                error: (err, _) => Center(child: Text('Error: $err', style: const TextStyle(color: _muted))),
              ),
            ),

            // Bottom bar
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: _darkBg,
                boxShadow: [BoxShadow(blurRadius: 12, color: Colors.black.withValues(alpha: 0.3))],
              ),
              child: Row(
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
                      onTap: () => context.push('/wizard/brands'),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(colors: [_gold, _goldLight]),
                          borderRadius: BorderRadius.circular(14),
                          boxShadow: [BoxShadow(color: _gold.withValues(alpha: 0.25), blurRadius: 16, offset: const Offset(0, 4))],
                        ),
                        child: const Center(child: Text('Confirm Quantities', style: TextStyle(color: _darkBg, fontWeight: FontWeight.w700, fontSize: 14, letterSpacing: 0.3))),
                      ),
                    ),
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
            final n = int.tryParse(val) ?? current;
            onChanged(n.clamp(0, 9999));
            Navigator.pop(context);
          },
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel', style: TextStyle(color: _muted))),
          TextButton(onPressed: () {
            final n = int.tryParse(controller.text) ?? current;
            onChanged(n.clamp(0, 9999));
            Navigator.pop(context);
          }, child: const Text('OK', style: TextStyle(color: _gold, fontWeight: FontWeight.w700))),
        ],
      ),
    );
  }
}

class _StepperButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onTap;
  const _StepperButton({required this.icon, this.onTap});

  @override
  Widget build(BuildContext context) {
    final enabled = onTap != null;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 44, height: 44,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: enabled ? _border : _border.withValues(alpha: 0.3), width: 1.5),
        ),
        child: Icon(icon, size: 20, color: enabled ? _gold : _muted.withValues(alpha: 0.3)),
      ),
    );
  }
}
