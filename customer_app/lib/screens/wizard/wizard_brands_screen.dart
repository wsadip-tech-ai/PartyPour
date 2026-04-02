// lib/screens/wizard/wizard_brands_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../providers/wizard_provider.dart';
import '../../providers/catalog_provider.dart';
import '../../models/product.dart';
import '../../widgets/step_progress.dart';
import '../../widgets/origin_filter.dart';
import '../../widgets/brand_picker_card.dart';

class WizardBrandsScreen extends ConsumerStatefulWidget {
  const WizardBrandsScreen({super.key});

  @override
  ConsumerState<WizardBrandsScreen> createState() => _WizardBrandsScreenState();
}

class _WizardBrandsScreenState extends ConsumerState<WizardBrandsScreen> {
  final Map<String, String?> _originFilters = {};

  @override
  Widget build(BuildContext context) {
    final wizard = ref.watch(wizardProvider);
    final rulesAsync = ref.watch(estimationRulesProvider);
    final theme = Theme.of(context);

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            const StepProgress(currentStep: 4),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Text('Choose your brands',
                  style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: rulesAsync.when(
                data: (rules) {
                  final selectedRules = rules
                      .where((r) => wizard.selectedTypeSlugs.contains(r.subcategorySlug))
                      .toList();

                  return ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    itemCount: selectedRules.length,
                    itemBuilder: (context, index) {
                      final rule = selectedRules[index];
                      final slug = rule.subcategorySlug;
                      final qty = wizard.estimatedQuantities[slug] ?? 0;
                      final originFilter = _originFilters[slug];

                      return _BrandSection(
                        slug: slug,
                        label: rule.label,
                        bottlesNeeded: qty,
                        originFilter: originFilter,
                        onOriginChanged: (v) => setState(() => _originFilters[slug] = v),
                        wizard: wizard,
                        ref: ref,
                        theme: theme,
                      );
                    },
                  );
                },
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (err, _) => Center(child: Text('Error: $err')),
              ),
            ),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: theme.colorScheme.surface,
                boxShadow: [BoxShadow(blurRadius: 8, color: Colors.black.withOpacity(0.05))],
              ),
              child: Row(
                children: [
                  Expanded(child: OutlinedButton(onPressed: () => context.pop(), child: const Text('Back'))),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: FilledButton(
                      onPressed: _allCategoriesHaveBrands(wizard) ? () => context.push('/wizard/review') : null,
                      child: const Text('Next — Review Order'),
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

class _BrandSection extends StatelessWidget {
  final String slug;
  final String label;
  final int bottlesNeeded;
  final String? originFilter;
  final ValueChanged<String?> onOriginChanged;
  final WizardState wizard;
  final WidgetRef ref;
  final ThemeData theme;

  const _BrandSection({
    required this.slug,
    required this.label,
    required this.bottlesNeeded,
    required this.originFilter,
    required this.onOriginChanged,
    required this.wizard,
    required this.ref,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    final productsAsync = ref.watch(productsProvider((subcategoryId: '', origin: originFilter)));
    // We need to fetch by slug, not subcategoryId. Use catalog service directly.
    // For now, we'll use a dedicated provider.

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 16),
        Row(
          children: [
            Text(label, style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
            const Spacer(),
            Text('$bottlesNeeded bottles', style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.primary)),
          ],
        ),
        const SizedBox(height: 8),
        OriginFilter(selectedOrigin: originFilter, onChanged: onOriginChanged),
        const SizedBox(height: 8),
        _BrandList(
          slug: slug,
          originFilter: originFilter,
          bottlesNeeded: bottlesNeeded,
          wizard: wizard,
          ref: ref,
        ),
        const Divider(height: 32),
      ],
    );
  }
}

class _BrandList extends ConsumerWidget {
  final String slug;
  final String? originFilter;
  final int bottlesNeeded;
  final WizardState wizard;
  final WidgetRef ref;

  const _BrandList({
    required this.slug,
    required this.originFilter,
    required this.bottlesNeeded,
    required this.wizard,
    required this.ref,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Fetch products by subcategory slug using a dedicated search
    final catalogService = ref.watch(catalogServiceProvider);

    return FutureBuilder(
      future: _fetchProductsBySlug(catalogService),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Padding(padding: EdgeInsets.all(16), child: Center(child: CircularProgressIndicator()));
        }
        final products = snapshot.data ?? [];
        final filtered = originFilter != null
            ? products.where((p) => p.origin == originFilter).toList()
            : products;

        if (filtered.isEmpty) {
          return Padding(
            padding: const EdgeInsets.all(16),
            child: Text('No brands available yet', style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant)),
          );
        }

        final currentSelections = wizard.brandSelections[slug] ?? [];

        return Column(
          children: filtered.map((product) {
            final selectedBrand = currentSelections.where((s) => s.product.id == product.id).firstOrNull;
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: BrandPickerCard(
                product: product,
                isSelected: selectedBrand != null,
                selectedVariant: selectedBrand?.variant,
                onSelect: (variant) {
                  final notifier = ref.read(wizardProvider.notifier);
                  if (selectedBrand != null) {
                    // Remove existing and re-add with new variant
                    final idx = currentSelections.indexOf(selectedBrand);
                    notifier.removeBrandSelection(slug, idx);
                  }
                  notifier.addBrandSelection(slug, BrandSelection(
                    product: product,
                    variant: variant,
                    quantity: bottlesNeeded,
                  ));
                },
              ),
            );
          }).toList(),
        );
      },
    );
  }

  Future<List<Product>> _fetchProductsBySlug(dynamic catalogService) async {
    // Fetch subcategory by slug, then products
    final supabase = Supabase.instance.client;
    final subData = await supabase.from('subcategories').select('id').eq('slug', slug).maybeSingle();
    if (subData == null) return [];
    final subcategoryId = subData['id'] as String;
    final data = await supabase.from('products').select('*, variants(*)').eq('subcategory_id', subcategoryId).eq('is_active', true).order('name');
    return data.map((json) => Product.fromJson(json)).toList();
  }
}
