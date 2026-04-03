import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../providers/wizard_provider.dart';
import '../../models/product.dart';
import '../../widgets/step_progress.dart';

const _gold = Color(0xFFCA8A04);
const _goldLight = Color(0xFFEAB308);
const _darkBg = Color(0xFF1C1917);
const _surfaceDark = Color(0xFF292524);
const _textLight = Color(0xFFFAFAF9);
const _muted = Color(0xFF78716C);
const _mutedLight = Color(0xFFA8A29E);
const _border = Color(0xFF44403C);

class WizardBrandsScreen extends ConsumerStatefulWidget {
  const WizardBrandsScreen({super.key});

  @override
  ConsumerState<WizardBrandsScreen> createState() => _WizardBrandsScreenState();
}

class _WizardBrandsScreenState extends ConsumerState<WizardBrandsScreen> {
  final Map<String, String?> _originFilters = {};
  final Map<String, Future<List<Product>>> _productCache = {};

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

  Future<List<Product>> _getProducts(String slug) {
    return _productCache.putIfAbsent(slug, () => _fetchProductsBySlug(slug));
  }

  Future<List<Product>> _fetchProductsBySlug(String slug) async {
    final supabase = Supabase.instance.client;
    final subData = await supabase.from('subcategories').select('id').eq('slug', slug).maybeSingle();
    if (subData == null) return [];
    final subcategoryId = subData['id'] as String;
    final data = await supabase.from('products').select('*, variants(*)').eq('subcategory_id', subcategoryId).eq('is_active', true).order('name');
    return data.map((json) => Product.fromJson(json)).toList();
  }

  @override
  Widget build(BuildContext context) {
    final wizard = ref.watch(wizardProvider);
    final rulesAsync = ref.watch(estimationRulesProvider);
    final allHaveBrands = _allCategoriesHaveBrands(wizard);

    return Scaffold(
      backgroundColor: _darkBg,
      body: SafeArea(
        child: Column(
          children: [
            const StepProgress(currentStep: 4),
            Expanded(
              child: rulesAsync.when(
                data: (rules) {
                  final selectedRules = rules.where((r) => wizard.selectedTypeSlugs.contains(r.subcategorySlug)).toList();

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
                              TextSpan(text: 'Choose your\n'),
                              TextSpan(text: 'brands', style: TextStyle(fontStyle: FontStyle.italic, color: _gold)),
                            ],
                          )),
                        ),
                        const Padding(
                          padding: EdgeInsets.fromLTRB(20, 6, 20, 16),
                          child: Text('Pick at least one brand per category', style: TextStyle(color: _muted, fontSize: 13)),
                        ),

                        // Category sections
                        ...selectedRules.map((rule) {
                          final slug = rule.subcategorySlug;
                          final qty = wizard.estimatedQuantities[slug] ?? 0;
                          final originFilter = _originFilters[slug];
                          final icon = _iconMap[rule.iconName] ?? Icons.local_drink;

                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Category header
                              Padding(
                                padding: const EdgeInsets.fromLTRB(20, 8, 20, 8),
                                child: Row(
                                  children: [
                                    Container(
                                      width: 32, height: 32,
                                      decoration: BoxDecoration(color: _gold.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
                                      child: Icon(icon, size: 16, color: _gold),
                                    ),
                                    const SizedBox(width: 10),
                                    Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(rule.label, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: _textLight)),
                                        Text('$qty bottles needed', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: _gold)),
                                      ],
                                    ),
                                  ],
                                ),
                              ),

                              // Origin filter pills
                              Padding(
                                padding: const EdgeInsets.fromLTRB(20, 0, 20, 10),
                                child: Row(
                                  children: [null, 'local', 'imported'].map((origin) {
                                    final label = origin == null ? 'All' : origin == 'local' ? 'Local' : 'Imported';
                                    final isActive = originFilter == origin;
                                    return Padding(
                                      padding: const EdgeInsets.only(right: 6),
                                      child: GestureDetector(
                                        onTap: () => setState(() => _originFilters[slug] = origin),
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                                          decoration: BoxDecoration(
                                            color: isActive ? _gold.withValues(alpha: 0.1) : Colors.transparent,
                                            border: Border.all(color: isActive ? _gold : _border),
                                            borderRadius: BorderRadius.circular(20),
                                          ),
                                          child: Text(label, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: isActive ? _gold : _mutedLight)),
                                        ),
                                      ),
                                    );
                                  }).toList(),
                                ),
                              ),

                              // Brand list
                              _BrandList(
                                slug: slug,
                                originFilter: originFilter,
                                bottlesNeeded: qty,
                                wizard: wizard,
                                productsFuture: _getProducts(slug),
                                onBrandSelect: (product, variant) {
                                  final notifier = ref.read(wizardProvider.notifier);
                                  final currentSelections = wizard.brandSelections[slug] ?? [];
                                  final existing = currentSelections.where((s) => s.product.id == product.id).firstOrNull;
                                  if (existing != null) {
                                    notifier.removeBrandSelection(slug, currentSelections.indexOf(existing));
                                  }
                                  notifier.addBrandSelection(slug, BrandSelection(product: product, variant: variant, quantity: qty));
                                },
                              ),

                              // Divider
                              Container(height: 1, margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8), color: _border),
                            ],
                          );
                        }),
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
              decoration: BoxDecoration(color: _darkBg, boxShadow: [BoxShadow(blurRadius: 12, color: Colors.black.withValues(alpha: 0.3))]),
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
                      onTap: allHaveBrands ? () => context.push('/wizard/review') : null,
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        decoration: BoxDecoration(
                          gradient: allHaveBrands ? const LinearGradient(colors: [_gold, _goldLight]) : null,
                          color: allHaveBrands ? null : _surfaceDark,
                          borderRadius: BorderRadius.circular(14),
                          boxShadow: allHaveBrands ? [BoxShadow(color: _gold.withValues(alpha: 0.25), blurRadius: 16, offset: const Offset(0, 4))] : null,
                        ),
                        child: Center(child: Text(
                          'Next — Review Order',
                          style: TextStyle(color: allHaveBrands ? _darkBg : _muted, fontSize: 14, fontWeight: FontWeight.w700, letterSpacing: 0.3),
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

  bool _allCategoriesHaveBrands(WizardState wizard) {
    for (final slug in wizard.selectedTypeSlugs) {
      final selections = wizard.brandSelections[slug];
      if (selections == null || selections.isEmpty) return false;
    }
    return true;
  }
}

// === Brand List with cached future ===
class _BrandList extends StatelessWidget {
  final String slug;
  final String? originFilter;
  final int bottlesNeeded;
  final WizardState wizard;
  final Future<List<Product>> productsFuture;
  final void Function(Product product, Variant variant) onBrandSelect;

  const _BrandList({
    required this.slug, required this.originFilter, required this.bottlesNeeded,
    required this.wizard, required this.productsFuture, required this.onBrandSelect,
  });

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Product>>(
      future: productsFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Padding(padding: EdgeInsets.all(20), child: Center(child: CircularProgressIndicator(color: _gold, strokeWidth: 2)));
        }
        final products = snapshot.data ?? [];
        final filtered = originFilter != null ? products.where((p) => p.origin == originFilter).toList() : products;

        if (filtered.isEmpty) {
          return const Padding(padding: EdgeInsets.fromLTRB(20, 8, 20, 8), child: Text('No brands available yet', style: TextStyle(color: _muted, fontSize: 13)));
        }

        final currentSelections = wizard.brandSelections[slug] ?? [];

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            children: filtered.map((product) {
              final selectedBrand = currentSelections.where((s) => s.product.id == product.id).firstOrNull;
              final isSelected = selectedBrand != null;
              final selectedVariant = selectedBrand?.variant;

              return _BrandCard(
                product: product,
                isSelected: isSelected,
                selectedVariant: selectedVariant,
                onSelect: (variant) => onBrandSelect(product, variant),
              );
            }).toList(),
          ),
        );
      },
    );
  }
}

// === Dark themed brand card ===
class _BrandCard extends StatelessWidget {
  final Product product;
  final bool isSelected;
  final Variant? selectedVariant;
  final ValueChanged<Variant> onSelect;

  const _BrandCard({required this.product, required this.isSelected, this.selectedVariant, required this.onSelect});

  @override
  Widget build(BuildContext context) {
    final isLocal = product.origin == 'local';
    final initial = product.name.isNotEmpty ? product.name[0].toUpperCase() : '?';
    final gradientColors = _getColors(product.name);

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: isSelected ? _gold.withValues(alpha: 0.04) : _surfaceDark,
        border: Border.all(color: isSelected ? _gold : _border, width: 1.5),
        borderRadius: BorderRadius.circular(14),
      ),
      padding: const EdgeInsets.all(14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Image placeholder
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Container(
              width: 60, height: 60,
              decoration: BoxDecoration(
                gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: gradientColors),
              ),
              child: product.imageUrl != null
                  ? Image.network(product.imageUrl!, fit: BoxFit.contain, errorBuilder: (_, __, ___) => Center(child: Text(initial, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: Colors.white))))
                  : Center(child: Text(initial, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: Colors.white))),
            ),
          ),
          const SizedBox(width: 14),
          // Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(child: Text(product.name, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: _textLight))),
                    if (isSelected)
                      Container(
                        width: 20, height: 20,
                        decoration: const BoxDecoration(color: _gold, shape: BoxShape.circle),
                        child: const Icon(Icons.check, size: 13, color: _darkBg),
                      ),
                  ],
                ),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: isLocal ? const Color(0xFF4ade80).withValues(alpha: 0.12) : _goldLight.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(isLocal ? 'Local' : 'Imported', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: isLocal ? const Color(0xFF4ade80) : _goldLight)),
                ),
                const SizedBox(height: 8),
                // Size chips
                Wrap(
                  spacing: 6, runSpacing: 6,
                  children: product.variants.map((variant) {
                    final isVariantSelected = selectedVariant?.id == variant.id;
                    return GestureDetector(
                      onTap: () => onSelect(variant),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: isVariantSelected ? _gold.withValues(alpha: 0.08) : Colors.transparent,
                          border: Border.all(color: isVariantSelected ? _gold : _border),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(variant.size, style: TextStyle(fontSize: 11, color: isVariantSelected ? _gold : _mutedLight)),
                      ),
                    );
                  }).toList(),
                ),
                if (selectedVariant != null) ...[
                  const SizedBox(height: 8),
                  Text('NPR ${selectedVariant!.unitPrice.toStringAsFixed(0)} /bottle', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: _gold)),
                  if (selectedVariant!.casePrice != null)
                    Text('Case of ${selectedVariant!.caseSize}: NPR ${selectedVariant!.casePrice!.toStringAsFixed(0)}', style: const TextStyle(fontSize: 11, color: _muted)),
                ],
              ],
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
