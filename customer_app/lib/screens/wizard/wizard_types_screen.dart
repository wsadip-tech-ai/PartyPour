import 'package:flutter/material.dart';
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
const _border = Color(0xFF44403C);

class WizardTypesScreen extends ConsumerStatefulWidget {
  const WizardTypesScreen({super.key});

  @override
  ConsumerState<WizardTypesScreen> createState() => _WizardTypesScreenState();
}

class _WizardTypesScreenState extends ConsumerState<WizardTypesScreen> {
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

  // Group slugs into categories for display
  static const _alcoholSlugs = {'whiskey', 'vodka', 'gin', 'rum', 'brandy', 'beer-bottle-can', 'wine', 'shots-specials', 'energy-drinks', 'cocktail-mixers'};

  @override
  Widget build(BuildContext context) {
    final wizard = ref.watch(wizardProvider);
    final rulesAsync = ref.watch(estimationRulesProvider);
    final selectedCount = wizard.selectedTypeSlugs.length;

    return Scaffold(
      backgroundColor: _darkBg,
      body: SafeArea(
        child: Column(
          children: [
            const StepProgress(currentStep: 2),
            Expanded(
              child: rulesAsync.when(
                data: (rules) {
                  final alcoholRules = rules.where((r) => _alcoholSlugs.contains(r.subcategorySlug)).toList();
                  final nonAlcoholRules = rules.where((r) => !_alcoholSlugs.contains(r.subcategorySlug)).toList();

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
                              TextSpan(text: 'What beverages do\nyou '),
                              TextSpan(text: 'need?', style: TextStyle(fontStyle: FontStyle.italic, color: _gold)),
                            ],
                          )),
                        ),
                        const Padding(
                          padding: EdgeInsets.fromLTRB(20, 6, 20, 0),
                          child: Text('Tap to select — pick as many as you like', style: TextStyle(color: _muted, fontSize: 13)),
                        ),

                        // Count bar
                        Container(
                          margin: const EdgeInsets.fromLTRB(20, 14, 20, 0),
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(colors: [_gold.withValues(alpha: 0.08), _gold.withValues(alpha: 0.02)]),
                            border: Border.all(color: _gold.withValues(alpha: 0.15)),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            children: [
                              RichText(text: TextSpan(
                                style: const TextStyle(fontSize: 13, color: Color(0xFFA8A29E), fontFamily: 'Inter'),
                                children: [
                                  TextSpan(text: '$selectedCount', style: const TextStyle(color: _gold, fontWeight: FontWeight.w700)),
                                  const TextSpan(text: ' types selected'),
                                ],
                              )),
                              const Spacer(),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(color: _surfaceDark, borderRadius: BorderRadius.circular(8)),
                                child: Text('${wizard.totalPax} guests • ${wizard.eventType.replaceAll('_', ' ')}',
                                  style: const TextStyle(fontSize: 11, color: _muted)),
                              ),
                            ],
                          ),
                        ),

                        // Spirits & Alcohol section
                        const Padding(
                          padding: EdgeInsets.fromLTRB(20, 16, 20, 8),
                          child: Text('SPIRITS & ALCOHOL', style: TextStyle(fontSize: 11, color: _muted, letterSpacing: 1.0, fontWeight: FontWeight.w600)),
                        ),
                        _buildTileGrid(alcoholRules, wizard),

                        // Non-Alcoholic section
                        if (nonAlcoholRules.isNotEmpty) ...[
                          const Padding(
                            padding: EdgeInsets.fromLTRB(20, 12, 20, 8),
                            child: Text('NON-ALCOHOLIC & EXTRAS', style: TextStyle(fontSize: 11, color: _muted, letterSpacing: 1.0, fontWeight: FontWeight.w600)),
                          ),
                          _buildTileGrid(nonAlcoholRules, wizard),
                        ],
                        const SizedBox(height: 16),
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
                        decoration: BoxDecoration(
                          border: Border.all(color: _gold, width: 1.5),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: const Center(child: Text('Back', style: TextStyle(color: _gold, fontSize: 14, fontWeight: FontWeight.w600))),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    flex: 2,
                    child: GestureDetector(
                      onTap: selectedCount > 0 ? () => context.push('/wizard/quantities') : null,
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        decoration: BoxDecoration(
                          gradient: selectedCount > 0
                              ? const LinearGradient(colors: [_gold, _goldLight])
                              : null,
                          color: selectedCount > 0 ? null : _surfaceDark,
                          borderRadius: BorderRadius.circular(14),
                          boxShadow: selectedCount > 0
                              ? [BoxShadow(color: _gold.withValues(alpha: 0.25), blurRadius: 16, offset: const Offset(0, 4))]
                              : null,
                        ),
                        child: Center(child: Text(
                          selectedCount > 0 ? 'Next — $selectedCount selected' : 'Select at least 1',
                          style: TextStyle(
                            color: selectedCount > 0 ? _darkBg : _muted,
                            fontSize: 14, fontWeight: FontWeight.w700, letterSpacing: 0.3,
                          ),
                        )),
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

  Widget _buildTileGrid(List rules, WizardState wizard) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          crossAxisSpacing: 10,
          mainAxisSpacing: 10,
          childAspectRatio: 0.95,
        ),
        itemCount: rules.length,
        itemBuilder: (context, index) {
          final rule = rules[index];
          final isSelected = wizard.selectedTypeSlugs.contains(rule.subcategorySlug);
          final icon = _iconMap[rule.iconName] ?? Icons.local_drink;

          return GestureDetector(
            onTap: () => ref.read(wizardProvider.notifier).toggleType(rule.subcategorySlug),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              decoration: BoxDecoration(
                color: isSelected ? _gold.withValues(alpha: 0.06) : Colors.transparent,
                border: Border.all(color: isSelected ? _gold : _border, width: 1.5),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Stack(
                children: [
                  // Subtle glow for selected
                  if (isSelected)
                    Positioned.fill(
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16),
                          gradient: RadialGradient(
                            center: Alignment.topCenter,
                            radius: 1.2,
                            colors: [_gold.withValues(alpha: 0.08), Colors.transparent],
                          ),
                        ),
                      ),
                    ),
                  // Checkmark badge
                  if (isSelected)
                    Positioned(
                      top: 8, right: 8,
                      child: Container(
                        width: 18, height: 18,
                        decoration: const BoxDecoration(color: _gold, shape: BoxShape.circle),
                        child: const Icon(Icons.check, size: 12, color: _darkBg),
                      ),
                    ),
                  // Content
                  Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(icon, size: 28, color: isSelected ? _gold : _muted),
                        const SizedBox(height: 8),
                        Text(
                          rule.label,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                            color: isSelected ? _gold : const Color(0xFFA8A29E),
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
