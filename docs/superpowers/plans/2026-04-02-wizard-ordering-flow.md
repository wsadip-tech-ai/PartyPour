# Wizard Ordering Flow Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Replace the free-browse-first experience with a 5-step guided wizard for event-based beverage ordering, backed by a configurable estimation engine managed via admin portal.

**Architecture:** New Supabase table `estimation_rules` stores configurable per-category formulas. Flutter wizard uses Riverpod StateNotifier to manage multi-step state. Admin portal gets a new CRUD page. Old planner is removed; old catalog remains as secondary flow.

**Tech Stack:** Supabase (PostgreSQL), Flutter + Riverpod + GoRouter, Next.js + shadcn/ui

---

## Phase 1: Database — Estimation Rules + New Products

### Task 1: Create estimation_rules migration + new subcategories + products

**Files:**
- Create: `supabase/migrations/005_estimation_rules_and_new_products.sql`

- [ ] **Step 1: Create the migration file**

```sql
-- 005_estimation_rules_and_new_products.sql
-- Estimation engine + new subcategories (brandy, shots, cocktail mixers)

-- ============================================
-- Estimation Rules table
-- ============================================
CREATE TABLE estimation_rules (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  subcategory_slug TEXT NOT NULL,
  label TEXT NOT NULL,
  icon_name TEXT,
  drinks_per_guest DECIMAL(5,2) NOT NULL,
  servings_per_bottle DECIMAL(5,2) NOT NULL,
  event_multipliers JSONB NOT NULL DEFAULT '{"wedding":1.0,"birthday":0.8,"corporate":0.6,"house_party":1.2,"anniversary":0.9,"other":1.0}',
  children_factor DECIMAL(3,2) NOT NULL DEFAULT 0,
  is_active BOOLEAN NOT NULL DEFAULT true,
  sort_order INT NOT NULL DEFAULT 0,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TRIGGER trg_estimation_rules_updated_at
  BEFORE UPDATE ON estimation_rules
  FOR EACH ROW EXECUTE FUNCTION update_updated_at();

-- RLS
ALTER TABLE estimation_rules ENABLE ROW LEVEL SECURITY;

CREATE POLICY "estimation_rules_read" ON estimation_rules
  FOR SELECT USING (is_active = true OR is_admin());

CREATE POLICY "estimation_rules_admin_insert" ON estimation_rules
  FOR INSERT WITH CHECK (is_admin());

CREATE POLICY "estimation_rules_admin_update" ON estimation_rules
  FOR UPDATE USING (is_admin());

CREATE POLICY "estimation_rules_admin_delete" ON estimation_rules
  FOR DELETE USING (is_admin());

-- ============================================
-- Seed estimation rules
-- ============================================
INSERT INTO estimation_rules (subcategory_slug, label, icon_name, drinks_per_guest, servings_per_bottle, event_multipliers, children_factor, sort_order) VALUES
  ('whiskey', 'Whiskey', 'local_bar', 3.0, 12, '{"wedding":1.0,"birthday":0.8,"corporate":0.6,"house_party":1.2,"anniversary":0.9,"other":1.0}', 0, 1),
  ('vodka', 'Vodka', 'local_bar', 1.5, 12, '{"wedding":1.0,"birthday":0.8,"corporate":0.6,"house_party":1.2,"anniversary":0.9,"other":1.0}', 0, 2),
  ('gin', 'Gin', 'local_bar', 1.0, 12, '{"wedding":1.0,"birthday":0.8,"corporate":0.6,"house_party":1.2,"anniversary":0.9,"other":1.0}', 0, 3),
  ('rum', 'Rum', 'local_bar', 1.5, 12, '{"wedding":1.0,"birthday":0.8,"corporate":0.6,"house_party":1.2,"anniversary":0.9,"other":1.0}', 0, 4),
  ('brandy', 'Brandy', 'wine_bar', 0.5, 12, '{"wedding":1.0,"birthday":0.8,"corporate":0.6,"house_party":1.2,"anniversary":0.9,"other":1.0}', 0, 5),
  ('beer-bottle-can', 'Beer', 'sports_bar', 2.0, 1, '{"wedding":1.0,"birthday":1.2,"corporate":0.8,"house_party":1.5,"anniversary":0.8,"other":1.0}', 0, 6),
  ('wine', 'Wine', 'wine_bar', 1.0, 5, '{"wedding":1.2,"birthday":0.6,"corporate":1.0,"house_party":0.8,"anniversary":1.2,"other":1.0}', 0, 7),
  ('shots-specials', 'Shots/Specials', 'local_fire_department', 1.0, 16, '{"wedding":0.8,"birthday":1.2,"corporate":0.4,"house_party":1.5,"anniversary":0.6,"other":1.0}', 0, 8),
  ('energy-drinks', 'Energy Drinks', 'bolt', 0.5, 1, '{"wedding":0.8,"birthday":1.0,"corporate":0.6,"house_party":1.2,"anniversary":0.8,"other":1.0}', 0.5, 9),
  ('cocktail-mixers', 'Cocktails', 'blender', 1.0, 8, '{"wedding":1.0,"birthday":1.0,"corporate":0.8,"house_party":1.2,"anniversary":1.0,"other":1.0}', 0, 10),
  ('carbonated', 'Cold Drinks', 'local_cafe', 2.0, 4, '{"wedding":1.0,"birthday":1.2,"corporate":1.0,"house_party":1.2,"anniversary":1.0,"other":1.0}', 1.0, 11),
  ('juice', 'Juice', 'local_cafe', 1.0, 4, '{"wedding":1.0,"birthday":1.5,"corporate":1.0,"house_party":1.0,"anniversary":1.0,"other":1.0}', 1.5, 12),
  ('water', 'Water', 'water_drop', 2.0, 2, '{"wedding":1.0,"birthday":1.0,"corporate":1.0,"house_party":1.0,"anniversary":1.0,"other":1.0}', 1.0, 13),
  ('ice-garnish', 'Ice', 'ac_unit', 1.0, 10, '{"wedding":1.0,"birthday":1.0,"corporate":1.0,"house_party":1.0,"anniversary":1.0,"other":1.0}', 1.0, 14);

-- ============================================
-- New subcategories
-- ============================================
-- Brandy under Hard Drinks
INSERT INTO subcategories (id, category_id, name, slug, sort_order) VALUES
  ('b1000000-0000-0000-0000-000000000015', 'a1000000-0000-0000-0000-000000000001', 'Brandy', 'brandy', 8);

-- Shots/Specials under Hard Drinks
INSERT INTO subcategories (id, category_id, name, slug, sort_order) VALUES
  ('b1000000-0000-0000-0000-000000000016', 'a1000000-0000-0000-0000-000000000001', 'Shots/Specials', 'shots-specials', 9);

-- Cocktail Mixers under Mixers & Add-ons
INSERT INTO subcategories (id, category_id, name, slug, sort_order) VALUES
  ('b1000000-0000-0000-0000-000000000017', 'a1000000-0000-0000-0000-000000000003', 'Cocktail Mixers', 'cocktail-mixers', 3);

-- ============================================
-- Brandy products
-- ============================================
INSERT INTO products (id, subcategory_id, name, origin, tags) VALUES
  ('c1000000-0000-0000-0000-000000000050', 'b1000000-0000-0000-0000-000000000015', 'Sandesh Jumla Apple Brandy', 'local', '{}');
INSERT INTO variants (product_id, size, unit_price, case_size, case_price, mrp) VALUES
  ('c1000000-0000-0000-0000-000000000050', '750ml', 1000.00, 12, 11000.00, 1100.00);

INSERT INTO products (id, subcategory_id, name, origin, tags) VALUES
  ('c1000000-0000-0000-0000-000000000051', 'b1000000-0000-0000-0000-000000000015', 'E&J VSOP', 'imported', '{}');
INSERT INTO variants (product_id, size, unit_price, mrp) VALUES
  ('c1000000-0000-0000-0000-000000000051', '1L', 4285.00, 4500.00);

INSERT INTO products (id, subcategory_id, name, origin, tags) VALUES
  ('c1000000-0000-0000-0000-000000000052', 'b1000000-0000-0000-0000-000000000015', 'Bardinet Napoleon VSOP', 'imported', '{}');
INSERT INTO variants (product_id, size, unit_price, mrp) VALUES
  ('c1000000-0000-0000-0000-000000000052', '700ml', 3855.00, 4100.00),
  ('c1000000-0000-0000-0000-000000000052', '1L', 5290.00, 5500.00);

INSERT INTO products (id, subcategory_id, name, origin, tags) VALUES
  ('c1000000-0000-0000-0000-000000000053', 'b1000000-0000-0000-0000-000000000015', 'St. Remy Authentic VSOP', 'imported', '{premium}');
INSERT INTO variants (product_id, size, unit_price, mrp) VALUES
  ('c1000000-0000-0000-0000-000000000053', '1L', 5595.00, 5800.00);

INSERT INTO products (id, subcategory_id, name, origin, tags) VALUES
  ('c1000000-0000-0000-0000-000000000054', 'b1000000-0000-0000-0000-000000000015', 'Martell VS', 'imported', '{premium}');
INSERT INTO variants (product_id, size, unit_price, mrp) VALUES
  ('c1000000-0000-0000-0000-000000000054', '1L', 9415.00, 9800.00);

-- ============================================
-- Shots/Specials products
-- ============================================
INSERT INTO products (id, subcategory_id, name, origin, tags) VALUES
  ('c1000000-0000-0000-0000-000000000055', 'b1000000-0000-0000-0000-000000000016', 'Jagermeister', 'imported', '{popular}');
INSERT INTO variants (product_id, size, unit_price, case_size, case_price, mrp) VALUES
  ('c1000000-0000-0000-0000-000000000055', '750ml', 3500.00, 12, 39000.00, 3700.00);

INSERT INTO products (id, subcategory_id, name, origin, tags) VALUES
  ('c1000000-0000-0000-0000-000000000056', 'b1000000-0000-0000-0000-000000000016', 'Tequila Jose Cuervo Gold', 'imported', '{popular}');
INSERT INTO variants (product_id, size, unit_price, case_size, case_price, mrp) VALUES
  ('c1000000-0000-0000-0000-000000000056', '750ml', 4200.00, 12, 47000.00, 4500.00);

INSERT INTO products (id, subcategory_id, name, origin, tags) VALUES
  ('c1000000-0000-0000-0000-000000000057', 'b1000000-0000-0000-0000-000000000016', 'Aila (Newari Rice Spirit)', 'local', '{}');
INSERT INTO variants (product_id, size, unit_price, mrp) VALUES
  ('c1000000-0000-0000-0000-000000000057', '750ml', 400.00, 450.00);

-- ============================================
-- Cocktail Mixers products
-- ============================================
INSERT INTO products (id, subcategory_id, name, origin, tags) VALUES
  ('c1000000-0000-0000-0000-000000000058', 'b1000000-0000-0000-0000-000000000017', 'Cranberry Juice (mixer)', 'imported', '{}');
INSERT INTO variants (product_id, size, unit_price, case_size, case_price, mrp) VALUES
  ('c1000000-0000-0000-0000-000000000058', '1L', 350.00, 12, 3800.00, 400.00);

INSERT INTO products (id, subcategory_id, name, origin, tags) VALUES
  ('c1000000-0000-0000-0000-000000000059', 'b1000000-0000-0000-0000-000000000017', 'Orange Juice (mixer)', 'imported', '{}');
INSERT INTO variants (product_id, size, unit_price, case_size, case_price, mrp) VALUES
  ('c1000000-0000-0000-0000-000000000059', '1L', 300.00, 12, 3300.00, 350.00);

INSERT INTO products (id, subcategory_id, name, origin, tags) VALUES
  ('c1000000-0000-0000-0000-000000000060', 'b1000000-0000-0000-0000-000000000017', 'Grenadine Syrup', 'imported', '{}');
INSERT INTO variants (product_id, size, unit_price, mrp) VALUES
  ('c1000000-0000-0000-0000-000000000060', '750ml', 500.00, 550.00);

INSERT INTO products (id, subcategory_id, name, origin, tags) VALUES
  ('c1000000-0000-0000-0000-000000000061', 'b1000000-0000-0000-0000-000000000017', 'Triple Sec', 'imported', '{}');
INSERT INTO variants (product_id, size, unit_price, mrp) VALUES
  ('c1000000-0000-0000-0000-000000000061', '750ml', 1800.00, 2000.00);

INSERT INTO products (id, subcategory_id, name, origin, tags) VALUES
  ('c1000000-0000-0000-0000-000000000062', 'b1000000-0000-0000-0000-000000000017', 'Simple Syrup', 'local', '{}');
INSERT INTO variants (product_id, size, unit_price, mrp) VALUES
  ('c1000000-0000-0000-0000-000000000062', '500ml', 200.00, 250.00);
```

- [ ] **Step 2: Push migration to Supabase cloud**

```bash
cd root_RaksiChaiyo
supabase db push
```

Expected: Migration 005 applied successfully.

- [ ] **Step 3: Commit**

```bash
git add supabase/migrations/005_estimation_rules_and_new_products.sql
git commit -m "feat: add estimation_rules table, brandy/shots/cocktail products"
```

---

## Phase 2: Flutter — Estimation Service + Wizard Provider

### Task 2: Create estimation_service.dart

**Files:**
- Create: `customer_app/lib/services/estimation_service.dart`
- Create: `customer_app/lib/models/estimation_rule.dart`

- [ ] **Step 1: Create estimation_rule.dart model**

```dart
// lib/models/estimation_rule.dart

class EstimationRule {
  final String id;
  final String subcategorySlug;
  final String label;
  final String? iconName;
  final double drinksPerGuest;
  final double servingsPerBottle;
  final Map<String, double> eventMultipliers;
  final double childrenFactor;
  final int sortOrder;

  EstimationRule({
    required this.id,
    required this.subcategorySlug,
    required this.label,
    this.iconName,
    required this.drinksPerGuest,
    required this.servingsPerBottle,
    required this.eventMultipliers,
    required this.childrenFactor,
    required this.sortOrder,
  });

  factory EstimationRule.fromJson(Map<String, dynamic> json) {
    final multipliers = (json['event_multipliers'] as Map<String, dynamic>?)
        ?.map((k, v) => MapEntry(k, (v as num).toDouble())) ?? {};
    return EstimationRule(
      id: json['id'] as String,
      subcategorySlug: json['subcategory_slug'] as String,
      label: json['label'] as String,
      iconName: json['icon_name'] as String?,
      drinksPerGuest: (json['drinks_per_guest'] as num).toDouble(),
      servingsPerBottle: (json['servings_per_bottle'] as num).toDouble(),
      eventMultipliers: multipliers,
      childrenFactor: (json['children_factor'] as num).toDouble(),
      sortOrder: json['sort_order'] as int,
    );
  }

  int estimateBottles({
    required int totalPax,
    required int children,
    required String eventType,
  }) {
    final effectiveGuests = (totalPax - children) + (children * childrenFactor);
    final multiplier = eventMultipliers[eventType] ?? 1.0;
    final totalServings = effectiveGuests * drinksPerGuest * multiplier;
    return (totalServings / servingsPerBottle).ceil().clamp(0, 9999);
  }
}
```

- [ ] **Step 2: Create estimation_service.dart**

```dart
// lib/services/estimation_service.dart

import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/estimation_rule.dart';

class EstimationService {
  final SupabaseClient _client;
  List<EstimationRule>? _cachedRules;

  EstimationService(this._client);

  Future<List<EstimationRule>> getRules() async {
    if (_cachedRules != null) return _cachedRules!;
    final data = await _client
        .from('estimation_rules')
        .select()
        .eq('is_active', true)
        .order('sort_order');
    _cachedRules = data.map((json) => EstimationRule.fromJson(json)).toList();
    return _cachedRules!;
  }

  void clearCache() => _cachedRules = null;

  Future<Map<String, int>> estimateQuantities({
    required int totalPax,
    required int children,
    required String eventType,
    required List<String> selectedSlugs,
  }) async {
    final rules = await getRules();
    final result = <String, int>{};
    for (final rule in rules) {
      if (selectedSlugs.contains(rule.subcategorySlug)) {
        result[rule.subcategorySlug] = rule.estimateBottles(
          totalPax: totalPax,
          children: children,
          eventType: eventType,
        );
      }
    }
    return result;
  }
}
```

- [ ] **Step 3: Commit**

```bash
git add customer_app/lib/models/estimation_rule.dart customer_app/lib/services/estimation_service.dart
git commit -m "feat: add estimation rule model and estimation service"
```

---

### Task 3: Create wizard_provider.dart

**Files:**
- Create: `customer_app/lib/providers/wizard_provider.dart`

- [ ] **Step 1: Create wizard_provider.dart**

```dart
// lib/providers/wizard_provider.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/estimation_rule.dart';
import '../models/product.dart';
import '../services/estimation_service.dart';
import 'auth_provider.dart';

class BrandSelection {
  final Product product;
  final Variant variant;
  int quantity;
  String unitType;

  BrandSelection({
    required this.product,
    required this.variant,
    required this.quantity,
    this.unitType = 'unit',
  });

  double get unitPrice => unitType == 'case' && variant.casePrice != null
      ? variant.casePrice!
      : variant.unitPrice;

  double get totalPrice => unitPrice * quantity;
}

class WizardState {
  final int totalPax;
  final int childrenCount;
  final String eventType;
  final DateTime? eventDate;
  final List<String> selectedTypeSlugs;
  final Map<String, int> estimatedQuantities;
  final Map<String, List<BrandSelection>> brandSelections;

  WizardState({
    this.totalPax = 100,
    this.childrenCount = 0,
    this.eventType = 'wedding',
    this.eventDate,
    this.selectedTypeSlugs = const [],
    this.estimatedQuantities = const {},
    this.brandSelections = const {},
  });

  WizardState copyWith({
    int? totalPax,
    int? childrenCount,
    String? eventType,
    DateTime? eventDate,
    List<String>? selectedTypeSlugs,
    Map<String, int>? estimatedQuantities,
    Map<String, List<BrandSelection>>? brandSelections,
  }) {
    return WizardState(
      totalPax: totalPax ?? this.totalPax,
      childrenCount: childrenCount ?? this.childrenCount,
      eventType: eventType ?? this.eventType,
      eventDate: eventDate ?? this.eventDate,
      selectedTypeSlugs: selectedTypeSlugs ?? this.selectedTypeSlugs,
      estimatedQuantities: estimatedQuantities ?? this.estimatedQuantities,
      brandSelections: brandSelections ?? this.brandSelections,
    );
  }

  double get grandTotal {
    double total = 0;
    for (final selections in brandSelections.values) {
      for (final s in selections) {
        total += s.totalPrice;
      }
    }
    return total;
  }

  List<BrandSelection> get allSelections {
    return brandSelections.values.expand((list) => list).toList();
  }
}

class WizardNotifier extends StateNotifier<WizardState> {
  WizardNotifier() : super(WizardState());

  // Step 1
  void setTotalPax(int pax) => state = state.copyWith(totalPax: pax);
  void setChildrenCount(int count) => state = state.copyWith(childrenCount: count);
  void setEventType(String type) => state = state.copyWith(eventType: type);
  void setEventDate(DateTime date) => state = state.copyWith(eventDate: date);

  // Step 2
  void toggleType(String slug) {
    final current = List<String>.from(state.selectedTypeSlugs);
    if (current.contains(slug)) {
      current.remove(slug);
    } else {
      current.add(slug);
    }
    state = state.copyWith(selectedTypeSlugs: current);
  }

  void setSelectedTypes(List<String> slugs) {
    state = state.copyWith(selectedTypeSlugs: slugs);
  }

  // Step 3
  void setEstimatedQuantities(Map<String, int> quantities) {
    state = state.copyWith(estimatedQuantities: quantities);
  }

  void updateQuantity(String slug, int quantity) {
    final updated = Map<String, int>.from(state.estimatedQuantities);
    updated[slug] = quantity.clamp(0, 9999);
    state = state.copyWith(estimatedQuantities: updated);
  }

  // Step 4
  void setBrandSelections(String slug, List<BrandSelection> selections) {
    final updated = Map<String, List<BrandSelection>>.from(state.brandSelections);
    updated[slug] = selections;
    state = state.copyWith(brandSelections: updated);
  }

  void addBrandSelection(String slug, BrandSelection selection) {
    final updated = Map<String, List<BrandSelection>>.from(state.brandSelections);
    final list = List<BrandSelection>.from(updated[slug] ?? []);
    list.add(selection);
    updated[slug] = list;
    state = state.copyWith(brandSelections: updated);
  }

  void removeBrandSelection(String slug, int index) {
    final updated = Map<String, List<BrandSelection>>.from(state.brandSelections);
    final list = List<BrandSelection>.from(updated[slug] ?? []);
    if (index < list.length) list.removeAt(index);
    updated[slug] = list;
    state = state.copyWith(brandSelections: updated);
  }

  // Step 5 — update quantity in review
  void updateBrandQuantity(String slug, int index, int quantity) {
    final updated = Map<String, List<BrandSelection>>.from(state.brandSelections);
    final list = List<BrandSelection>.from(updated[slug] ?? []);
    if (index < list.length) {
      list[index].quantity = quantity.clamp(0, 9999);
      updated[slug] = list;
      state = state.copyWith(brandSelections: updated);
    }
  }

  void reset() => state = WizardState();
}

final wizardProvider = StateNotifierProvider<WizardNotifier, WizardState>(
  (ref) => WizardNotifier(),
);

final estimationServiceProvider = Provider<EstimationService>(
  (ref) => EstimationService(ref.watch(supabaseProvider)),
);

final estimationRulesProvider = FutureProvider<List<EstimationRule>>((ref) {
  return ref.watch(estimationServiceProvider).getRules();
});
```

- [ ] **Step 2: Commit**

```bash
git add customer_app/lib/providers/wizard_provider.dart
git commit -m "feat: add wizard state provider with BrandSelection model"
```

---

## Phase 3: Flutter — Reusable Widgets

### Task 4: Create reusable wizard widgets

**Files:**
- Create: `customer_app/lib/widgets/step_progress.dart`
- Create: `customer_app/lib/widgets/quantity_stepper.dart`
- Create: `customer_app/lib/widgets/type_selector_card.dart`
- Create: `customer_app/lib/widgets/brand_picker_card.dart`

- [ ] **Step 1: Create step_progress.dart**

```dart
// lib/widgets/step_progress.dart

import 'package:flutter/material.dart';

class StepProgress extends StatelessWidget {
  final int currentStep;
  final int totalSteps;

  const StepProgress({super.key, required this.currentStep, this.totalSteps = 5});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Column(
        children: [
          Row(
            children: List.generate(totalSteps, (index) {
              final step = index + 1;
              final isActive = step <= currentStep;
              final isCurrent = step == currentStep;
              return Expanded(
                child: Row(
                  children: [
                    Expanded(
                      child: Container(
                        height: 4,
                        decoration: BoxDecoration(
                          color: isActive
                              ? theme.colorScheme.primary
                              : theme.colorScheme.surfaceContainerHighest,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    if (index < totalSteps - 1) const SizedBox(width: 4),
                  ],
                ),
              );
            }),
          ),
          const SizedBox(height: 8),
          Text(
            'Step $currentStep of $totalSteps',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}
```

- [ ] **Step 2: Create quantity_stepper.dart**

```dart
// lib/widgets/quantity_stepper.dart

import 'package:flutter/material.dart';

class QuantityStepper extends StatelessWidget {
  final int value;
  final int min;
  final int max;
  final ValueChanged<int> onChanged;
  final bool large;

  const QuantityStepper({
    super.key,
    required this.value,
    this.min = 0,
    this.max = 9999,
    required this.onChanged,
    this.large = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final iconSize = large ? 32.0 : 24.0;
    final textStyle = large
        ? theme.textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold)
        : theme.textTheme.titleLarge;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          onPressed: value > min ? () => onChanged(value - 1) : null,
          icon: Icon(Icons.remove_circle_outline, size: iconSize),
          style: IconButton.styleFrom(
            foregroundColor: theme.colorScheme.primary,
          ),
        ),
        SizedBox(
          width: large ? 64 : 48,
          child: Text(
            '$value',
            textAlign: TextAlign.center,
            style: textStyle,
          ),
        ),
        IconButton(
          onPressed: value < max ? () => onChanged(value + 1) : null,
          icon: Icon(Icons.add_circle_outline, size: iconSize),
          style: IconButton.styleFrom(
            foregroundColor: theme.colorScheme.primary,
          ),
        ),
      ],
    );
  }
}
```

- [ ] **Step 3: Create type_selector_card.dart**

```dart
// lib/widgets/type_selector_card.dart

import 'package:flutter/material.dart';

class TypeSelectorCard extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;

  const TypeSelectorCard({
    super.key,
    required this.label,
    required this.icon,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          color: isSelected
              ? theme.colorScheme.primaryContainer
              : theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected
                ? theme.colorScheme.primary
                : theme.colorScheme.outlineVariant,
            width: isSelected ? 2 : 1,
          ),
        ),
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Stack(
              alignment: Alignment.topRight,
              children: [
                Icon(
                  icon,
                  size: 36,
                  color: isSelected
                      ? theme.colorScheme.primary
                      : theme.colorScheme.onSurfaceVariant,
                ),
                if (isSelected)
                  Icon(
                    Icons.check_circle,
                    size: 18,
                    color: theme.colorScheme.primary,
                  ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              label,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                color: isSelected
                    ? theme.colorScheme.onPrimaryContainer
                    : theme.colorScheme.onSurface,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
```

- [ ] **Step 4: Create brand_picker_card.dart**

```dart
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
```

- [ ] **Step 5: Commit**

```bash
git add customer_app/lib/widgets/step_progress.dart customer_app/lib/widgets/quantity_stepper.dart customer_app/lib/widgets/type_selector_card.dart customer_app/lib/widgets/brand_picker_card.dart
git commit -m "feat: add wizard reusable widgets - progress, stepper, type card, brand card"
```

---

## Phase 4: Flutter — Wizard Screens

### Task 5: Create wizard Step 1 — Event Info

**Files:**
- Create: `customer_app/lib/screens/wizard/wizard_event_screen.dart`

- [ ] **Step 1: Create wizard_event_screen.dart**

```dart
// lib/screens/wizard/wizard_event_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../providers/wizard_provider.dart';
import '../../widgets/step_progress.dart';
import '../../widgets/quantity_stepper.dart';

class WizardEventScreen extends ConsumerWidget {
  const WizardEventScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final wizard = ref.watch(wizardProvider);
    final theme = Theme.of(context);

    final eventTypes = [
      ('wedding', 'Wedding', Icons.favorite),
      ('birthday', 'Birthday', Icons.cake),
      ('corporate', 'Corporate', Icons.business),
      ('house_party', 'House Party', Icons.home),
      ('anniversary', 'Anniversary', Icons.celebration),
      ('other', 'Other', Icons.event),
    ];

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            const StepProgress(currentStep: 1),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Tell us about your event',
                        style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 32),

                    // Total Guests
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Row(
                          children: [
                            Icon(Icons.groups, color: theme.colorScheme.primary),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('Total Guests', style: theme.textTheme.titleMedium),
                                  Text('Including children', style: theme.textTheme.bodySmall),
                                ],
                              ),
                            ),
                            QuantityStepper(
                              value: wizard.totalPax,
                              min: 10,
                              max: 2000,
                              onChanged: (v) => ref.read(wizardProvider.notifier).setTotalPax(v),
                              large: true,
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Children
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Row(
                          children: [
                            Icon(Icons.child_care, color: theme.colorScheme.primary),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('Children', style: theme.textTheme.titleMedium),
                                  Text('Under 18 (optional)', style: theme.textTheme.bodySmall),
                                ],
                              ),
                            ),
                            QuantityStepper(
                              value: wizard.childrenCount,
                              min: 0,
                              max: wizard.totalPax,
                              onChanged: (v) => ref.read(wizardProvider.notifier).setChildrenCount(v),
                              large: true,
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Event Type
                    Text('Event Type', style: theme.textTheme.titleMedium),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: eventTypes.map((e) => ChoiceChip(
                        avatar: Icon(e.$3, size: 18),
                        label: Text(e.$2),
                        selected: wizard.eventType == e.$1,
                        onSelected: (_) => ref.read(wizardProvider.notifier).setEventType(e.$1),
                      )).toList(),
                    ),
                    const SizedBox(height: 24),

                    // Event Date
                    Card(
                      child: ListTile(
                        leading: Icon(Icons.calendar_today, color: theme.colorScheme.primary),
                        title: Text(wizard.eventDate == null
                            ? 'Select Event Date'
                            : '${wizard.eventDate!.day}/${wizard.eventDate!.month}/${wizard.eventDate!.year}'),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () async {
                          final date = await showDatePicker(
                            context: context,
                            initialDate: DateTime.now().add(const Duration(days: 7)),
                            firstDate: DateTime.now(),
                            lastDate: DateTime.now().add(const Duration(days: 365)),
                          );
                          if (date != null) {
                            ref.read(wizardProvider.notifier).setEventDate(date);
                          }
                        },
                      ),
                    ),
                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),
            // Bottom bar
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: theme.colorScheme.surface,
                boxShadow: [BoxShadow(blurRadius: 8, color: Colors.black.withOpacity(0.05))],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: () => context.push('/wizard/types'),
                      child: const Text('Next — Select Beverages'),
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextButton(
                    onPressed: () => context.push('/category/a1000000-0000-0000-0000-000000000001'),
                    child: const Text('Browse Catalog Instead'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
```

- [ ] **Step 2: Commit**

```bash
git add customer_app/lib/screens/wizard/wizard_event_screen.dart
git commit -m "feat: add wizard Step 1 — event info screen"
```

---

### Task 6: Create wizard Step 2 — Select Beverage Types

**Files:**
- Create: `customer_app/lib/screens/wizard/wizard_types_screen.dart`

- [ ] **Step 1: Create wizard_types_screen.dart**

```dart
// lib/screens/wizard/wizard_types_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../providers/wizard_provider.dart';
import '../../models/estimation_rule.dart';
import '../../widgets/step_progress.dart';
import '../../widgets/type_selector_card.dart';

class WizardTypesScreen extends ConsumerStatefulWidget {
  const WizardTypesScreen({super.key});

  @override
  ConsumerState<WizardTypesScreen> createState() => _WizardTypesScreenState();
}

class _WizardTypesScreenState extends ConsumerState<WizardTypesScreen> {
  bool _initialized = false;

  static const _defaultsByEventType = {
    'wedding': ['whiskey', 'beer-bottle-can', 'wine', 'carbonated', 'water', 'ice-garnish'],
    'birthday': ['beer-bottle-can', 'carbonated', 'juice', 'water', 'ice-garnish'],
    'corporate': ['whiskey', 'beer-bottle-can', 'wine', 'carbonated', 'water'],
    'house_party': ['whiskey', 'vodka', 'beer-bottle-can', 'carbonated', 'water', 'ice-garnish'],
    'anniversary': ['whiskey', 'wine', 'beer-bottle-can', 'carbonated', 'water', 'ice-garnish'],
  };

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
    final theme = Theme.of(context);

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            const StepProgress(currentStep: 2),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Text('What beverages do you need?',
                  style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: rulesAsync.when(
                data: (rules) {
                  // Pre-select defaults on first load
                  if (!_initialized && wizard.selectedTypeSlugs.isEmpty) {
                    _initialized = true;
                    final defaults = _defaultsByEventType[wizard.eventType] ?? [];
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      ref.read(wizardProvider.notifier).setSelectedTypes(defaults);
                    });
                  }

                  return GridView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                      childAspectRatio: 1.3,
                    ),
                    itemCount: rules.length,
                    itemBuilder: (context, index) {
                      final rule = rules[index];
                      return TypeSelectorCard(
                        label: rule.label,
                        icon: _iconMap[rule.iconName] ?? Icons.local_drink,
                        isSelected: wizard.selectedTypeSlugs.contains(rule.subcategorySlug),
                        onTap: () => ref.read(wizardProvider.notifier).toggleType(rule.subcategorySlug),
                      );
                    },
                  );
                },
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (err, _) => Center(child: Text('Error: $err')),
              ),
            ),
            // Bottom bar
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: theme.colorScheme.surface,
                boxShadow: [BoxShadow(blurRadius: 8, color: Colors.black.withOpacity(0.05))],
              ),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => context.pop(),
                      child: const Text('Back'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: FilledButton(
                      onPressed: wizard.selectedTypeSlugs.isEmpty
                          ? null
                          : () => context.push('/wizard/quantities'),
                      child: Text('Next — ${wizard.selectedTypeSlugs.length} selected'),
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
}
```

- [ ] **Step 2: Commit**

```bash
git add customer_app/lib/screens/wizard/wizard_types_screen.dart
git commit -m "feat: add wizard Step 2 — beverage type selection with smart defaults"
```

---

### Task 7: Create wizard Step 3 — Estimated Quantities

**Files:**
- Create: `customer_app/lib/screens/wizard/wizard_quantities_screen.dart`

- [ ] **Step 1: Create wizard_quantities_screen.dart**

```dart
// lib/screens/wizard/wizard_quantities_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../providers/wizard_provider.dart';
import '../../widgets/step_progress.dart';
import '../../widgets/quantity_stepper.dart';

class WizardQuantitiesScreen extends ConsumerStatefulWidget {
  const WizardQuantitiesScreen({super.key});

  @override
  ConsumerState<WizardQuantitiesScreen> createState() => _WizardQuantitiesScreenState();
}

class _WizardQuantitiesScreenState extends ConsumerState<WizardQuantitiesScreen> {
  bool _calculated = false;

  @override
  Widget build(BuildContext context) {
    final wizard = ref.watch(wizardProvider);
    final rulesAsync = ref.watch(estimationRulesProvider);
    final theme = Theme.of(context);

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            const StepProgress(currentStep: 3),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Estimated quantities',
                      style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  Text(
                    '${wizard.totalPax} guests • ${wizard.eventType.replaceAll('_', ' ')}',
                    style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: rulesAsync.when(
                data: (rules) {
                  // Calculate on first load
                  if (!_calculated) {
                    _calculated = true;
                    WidgetsBinding.instance.addPostFrameCallback((_) async {
                      final quantities = await ref.read(estimationServiceProvider).estimateQuantities(
                        totalPax: wizard.totalPax,
                        children: wizard.childrenCount,
                        eventType: wizard.eventType,
                        selectedSlugs: wizard.selectedTypeSlugs,
                      );
                      ref.read(wizardProvider.notifier).setEstimatedQuantities(quantities);
                    });
                  }

                  final selectedRules = rules
                      .where((r) => wizard.selectedTypeSlugs.contains(r.subcategorySlug))
                      .toList();

                  return ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    itemCount: selectedRules.length,
                    itemBuilder: (context, index) {
                      final rule = selectedRules[index];
                      final qty = wizard.estimatedQuantities[rule.subcategorySlug] ?? 0;
                      final servings = qty * rule.servingsPerBottle;

                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(rule.label, style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
                                    const SizedBox(height: 4),
                                    Text(
                                      '~${servings.round()} servings for ${wizard.totalPax} guests',
                                      style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                                    ),
                                  ],
                                ),
                              ),
                              QuantityStepper(
                                value: qty,
                                min: 0,
                                onChanged: (v) => ref.read(wizardProvider.notifier).updateQuantity(rule.subcategorySlug, v),
                                large: true,
                              ),
                            ],
                          ),
                        ),
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
                      onPressed: () => context.push('/wizard/brands'),
                      child: const Text('Confirm Quantities'),
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
}
```

- [ ] **Step 2: Commit**

```bash
git add customer_app/lib/screens/wizard/wizard_quantities_screen.dart
git commit -m "feat: add wizard Step 3 — estimated quantities with editable steppers"
```

---

### Task 8: Create wizard Step 4 — Choose Brands

**Files:**
- Create: `customer_app/lib/screens/wizard/wizard_brands_screen.dart`

- [ ] **Step 1: Create wizard_brands_screen.dart**

```dart
// lib/screens/wizard/wizard_brands_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
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
```

Add the missing import at top of file:

```dart
import 'package:supabase_flutter/supabase_flutter.dart';
```

- [ ] **Step 2: Commit**

```bash
git add customer_app/lib/screens/wizard/wizard_brands_screen.dart
git commit -m "feat: add wizard Step 4 — brand selection with origin filter"
```

---

### Task 9: Create wizard Step 5 — Final Review

**Files:**
- Create: `customer_app/lib/screens/wizard/wizard_review_screen.dart`

- [ ] **Step 1: Create wizard_review_screen.dart**

```dart
// lib/screens/wizard/wizard_review_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../providers/wizard_provider.dart';
import '../../providers/cart_provider.dart';
import '../../widgets/step_progress.dart';
import '../../widgets/quantity_stepper.dart';

class WizardReviewScreen extends ConsumerWidget {
  const WizardReviewScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final wizard = ref.watch(wizardProvider);
    final theme = Theme.of(context);

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            const StepProgress(currentStep: 5),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Text('Review your order',
                  style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                children: [
                  // Event summary card
                  Card(
                    color: theme.colorScheme.primaryContainer.withOpacity(0.3),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          Icon(Icons.event, color: theme.colorScheme.primary),
                          const SizedBox(width: 12),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('${wizard.totalPax} guests • ${wizard.eventType.replaceAll('_', ' ')}',
                                  style: theme.textTheme.titleSmall),
                              if (wizard.eventDate != null)
                                Text('${wizard.eventDate!.day}/${wizard.eventDate!.month}/${wizard.eventDate!.year}',
                                    style: theme.textTheme.bodySmall),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Brand selections grouped by category
                  ...wizard.brandSelections.entries.map((entry) {
                    final slug = entry.key;
                    final selections = entry.value;
                    if (selections.isEmpty) return const SizedBox.shrink();

                    double categoryTotal = selections.fold(0, (sum, s) => sum + s.totalPrice);

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(slug.replaceAll('-', ' ').toUpperCase(),
                                style: theme.textTheme.labelLarge?.copyWith(
                                    color: theme.colorScheme.primary, fontWeight: FontWeight.bold)),
                            const Spacer(),
                            Text('NPR ${categoryTotal.toStringAsFixed(0)}',
                                style: theme.textTheme.labelLarge?.copyWith(fontWeight: FontWeight.bold)),
                          ],
                        ),
                        const SizedBox(height: 8),
                        ...selections.asMap().entries.map((selEntry) {
                          final idx = selEntry.key;
                          final sel = selEntry.value;
                          return Card(
                            margin: const EdgeInsets.only(bottom: 8),
                            child: Padding(
                              padding: const EdgeInsets.all(12),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(sel.product.name, style: theme.textTheme.titleSmall),
                                        Text('${sel.variant.size} • NPR ${sel.unitPrice.toStringAsFixed(0)} each',
                                            style: theme.textTheme.bodySmall),
                                      ],
                                    ),
                                  ),
                                  QuantityStepper(
                                    value: sel.quantity,
                                    min: 1,
                                    onChanged: (v) => ref.read(wizardProvider.notifier).updateBrandQuantity(slug, idx, v),
                                  ),
                                  const SizedBox(width: 8),
                                  SizedBox(
                                    width: 80,
                                    child: Text(
                                      'NPR ${sel.totalPrice.toStringAsFixed(0)}',
                                      textAlign: TextAlign.right,
                                      style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        }),
                        const SizedBox(height: 16),
                      ],
                    );
                  }),
                ],
              ),
            ),
            // Bottom bar with total + actions
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: theme.colorScheme.surface,
                boxShadow: [BoxShadow(blurRadius: 8, color: Colors.black.withOpacity(0.08))],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Text('Grand Total', style: theme.textTheme.titleMedium),
                      const Spacer(),
                      Text(
                        'NPR ${wizard.grandTotal.toStringAsFixed(0)}',
                        style: theme.textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.bold, color: theme.colorScheme.primary),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => context.pop(),
                          child: const Text('Back'),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => context.push('/calculator'),
                          child: const Text('Price Calculator'),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: () {
                        // Push all wizard selections to cart, then go to checkout
                        final cart = ref.read(cartProvider.notifier);
                        cart.clear();
                        for (final selections in wizard.brandSelections.values) {
                          for (final sel in selections) {
                            cart.addItem(sel.product, sel.variant, sel.unitType, quantity: sel.quantity);
                          }
                        }
                        context.push('/checkout');
                      },
                      child: const Text('Place Order'),
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
}
```

- [ ] **Step 2: Commit**

```bash
git add customer_app/lib/screens/wizard/wizard_review_screen.dart
git commit -m "feat: add wizard Step 5 — final review with editable quantities and totals"
```

---

### Task 10: Create Price Calculator Screen

**Files:**
- Create: `customer_app/lib/screens/calculator/price_calculator_screen.dart`

- [ ] **Step 1: Create price_calculator_screen.dart**

```dart
// lib/screens/calculator/price_calculator_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../providers/wizard_provider.dart';
import '../../widgets/quantity_stepper.dart';

class PriceCalculatorScreen extends ConsumerWidget {
  const PriceCalculatorScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final wizard = ref.watch(wizardProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Price Calculator'),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => context.pop(),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          Text('Adjust quantities and see price changes in real-time.',
              style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
          const SizedBox(height: 16),

          ...wizard.brandSelections.entries.map((entry) {
            final slug = entry.key;
            final selections = entry.value;
            if (selections.isEmpty) return const SizedBox.shrink();

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(slug.replaceAll('-', ' ').toUpperCase(),
                    style: theme.textTheme.labelLarge?.copyWith(
                        color: theme.colorScheme.primary, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                ...selections.asMap().entries.map((selEntry) {
                  final idx = selEntry.key;
                  final sel = selEntry.value;
                  return Card(
                    margin: const EdgeInsets.only(bottom: 8),
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(sel.product.name, style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600)),
                                    Text(sel.variant.size, style: theme.textTheme.bodySmall),
                                  ],
                                ),
                              ),
                              // Unit/Case toggle
                              if (sel.variant.caseSize != null && sel.variant.casePrice != null)
                                SegmentedButton<String>(
                                  segments: [
                                    const ButtonSegment(value: 'unit', label: Text('Bottle')),
                                    ButtonSegment(value: 'case', label: Text('Case(${sel.variant.caseSize})')),
                                  ],
                                  selected: {sel.unitType},
                                  onSelectionChanged: (s) {
                                    sel.unitType = s.first;
                                    ref.read(wizardProvider.notifier).updateBrandQuantity(slug, idx, sel.quantity);
                                  },
                                  style: ButtonStyle(
                                    visualDensity: VisualDensity.compact,
                                    textStyle: WidgetStatePropertyAll(theme.textTheme.labelSmall),
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Text('NPR ${sel.unitPrice.toStringAsFixed(0)} each',
                                  style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
                              const Spacer(),
                              QuantityStepper(
                                value: sel.quantity,
                                min: 1,
                                onChanged: (v) => ref.read(wizardProvider.notifier).updateBrandQuantity(slug, idx, v),
                              ),
                              const SizedBox(width: 8),
                              SizedBox(
                                width: 90,
                                child: Text(
                                  'NPR ${sel.totalPrice.toStringAsFixed(0)}',
                                  textAlign: TextAlign.right,
                                  style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  );
                }),
                const SizedBox(height: 16),
              ],
            );
          }),
        ],
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          boxShadow: [BoxShadow(blurRadius: 8, color: Colors.black.withOpacity(0.08))],
        ),
        child: Row(
          children: [
            Text('Total', style: theme.textTheme.titleMedium),
            const Spacer(),
            Text(
              'NPR ${wizard.grandTotal.toStringAsFixed(0)}',
              style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold, color: theme.colorScheme.primary),
            ),
          ],
        ),
      ),
    );
  }
}
```

- [ ] **Step 2: Commit**

```bash
git add customer_app/lib/screens/calculator/price_calculator_screen.dart
git commit -m "feat: add price calculator with real-time unit/case toggle and totals"
```

---

## Phase 5: Flutter — Router + Home Screen Updates

### Task 11: Update router and home screen, remove old planner

**Files:**
- Modify: `customer_app/lib/config/router.dart`
- Modify: `customer_app/lib/screens/home/home_screen.dart`
- Delete: `customer_app/lib/screens/planner/planner_screen.dart`
- Delete: `customer_app/lib/services/planner_service.dart`
- Delete: `customer_app/lib/providers/planner_provider.dart`

- [ ] **Step 1: Update router.dart**

Add imports for new screens and add wizard routes. Remove planner route. The full updated file:

```dart
// lib/config/router.dart

import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../screens/auth/login_screen.dart';
import '../screens/home/home_screen.dart';
import '../screens/catalog/category_screen.dart';
import '../screens/catalog/product_list_screen.dart';
import '../screens/catalog/product_detail_screen.dart';
import '../screens/cart/cart_screen.dart';
import '../screens/checkout/checkout_screen.dart';
import '../screens/orders/order_history_screen.dart';
import '../screens/orders/order_detail_screen.dart';
import '../screens/profile/profile_screen.dart';
import '../screens/wizard/wizard_event_screen.dart';
import '../screens/wizard/wizard_types_screen.dart';
import '../screens/wizard/wizard_quantities_screen.dart';
import '../screens/wizard/wizard_brands_screen.dart';
import '../screens/wizard/wizard_review_screen.dart';
import '../screens/calculator/price_calculator_screen.dart';

final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/login',
    routes: [
      GoRoute(path: '/login', builder: (_, __) => const LoginScreen()),
      GoRoute(path: '/home', builder: (_, __) => const HomeScreen()),
      // Wizard flow
      GoRoute(path: '/wizard/event', builder: (_, __) => const WizardEventScreen()),
      GoRoute(path: '/wizard/types', builder: (_, __) => const WizardTypesScreen()),
      GoRoute(path: '/wizard/quantities', builder: (_, __) => const WizardQuantitiesScreen()),
      GoRoute(path: '/wizard/brands', builder: (_, __) => const WizardBrandsScreen()),
      GoRoute(path: '/wizard/review', builder: (_, __) => const WizardReviewScreen()),
      GoRoute(path: '/calculator', builder: (_, __) => const PriceCalculatorScreen()),
      // Catalog (secondary)
      GoRoute(path: '/category/:categoryId', builder: (_, state) => CategoryScreen(categoryId: state.pathParameters['categoryId']!)),
      GoRoute(path: '/products/:subcategoryId', builder: (_, state) => ProductListScreen(subcategoryId: state.pathParameters['subcategoryId']!)),
      GoRoute(path: '/product/:productId', builder: (_, state) => ProductDetailScreen(productId: state.pathParameters['productId']!)),
      GoRoute(path: '/cart', builder: (_, __) => const CartScreen()),
      GoRoute(path: '/checkout', builder: (_, __) => const CheckoutScreen()),
      GoRoute(path: '/orders', builder: (_, __) => const OrderHistoryScreen()),
      GoRoute(path: '/order/:orderId', builder: (_, state) => OrderDetailScreen(orderId: state.pathParameters['orderId']!)),
      GoRoute(path: '/profile', builder: (_, __) => const ProfileScreen()),
    ],
  );
});
```

- [ ] **Step 2: Update home_screen.dart**

Replace the entire home screen with the new wizard-first layout:

```dart
// lib/screens/home/home_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../providers/wizard_provider.dart';
import '../../widgets/cart_badge.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final wizard = ref.watch(wizardProvider);
    final theme = Theme.of(context);
    final hasWizardInProgress = wizard.selectedTypeSlugs.isNotEmpty;

    return Scaffold(
      appBar: AppBar(
        title: const Text('RaksiChaiyo'),
        actions: const [CartBadge()],
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Plan your event\nbeverages',
                style: theme.textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text('We help you estimate and order the right amount.',
                style: theme.textTheme.bodyLarge?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
            const SizedBox(height: 32),

            // Start order CTA
            Card(
              clipBehavior: Clip.antiAlias,
              color: theme.colorScheme.primaryContainer,
              child: InkWell(
                onTap: () {
                  ref.read(wizardProvider.notifier).reset();
                  context.push('/wizard/event');
                },
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Row(
                    children: [
                      Icon(Icons.celebration, size: 48, color: theme.colorScheme.primary),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Start Your Order', style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
                            const SizedBox(height: 4),
                            Text('Tell us about your event and we\'ll handle the rest',
                                style: theme.textTheme.bodyMedium),
                          ],
                        ),
                      ),
                      Icon(Icons.arrow_forward, color: theme.colorScheme.primary),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Resume wizard if in progress
            if (hasWizardInProgress)
              Card(
                child: ListTile(
                  leading: Icon(Icons.replay, color: theme.colorScheme.primary),
                  title: const Text('Resume your order'),
                  subtitle: Text('${wizard.selectedTypeSlugs.length} types selected • ${wizard.totalPax} guests'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => context.push('/wizard/types'),
                ),
              ),
            if (hasWizardInProgress) const SizedBox(height: 16),

            // Secondary actions
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => context.push('/calculator'),
                    icon: const Icon(Icons.calculate),
                    label: const Text('Price Calculator'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => context.push('/category/a1000000-0000-0000-0000-000000000001'),
                    icon: const Icon(Icons.local_bar),
                    label: const Text('Browse Catalog'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
      bottomNavigationBar: NavigationBar(
        destinations: const [
          NavigationDestination(icon: Icon(Icons.home), label: 'Home'),
          NavigationDestination(icon: Icon(Icons.receipt_long), label: 'Orders'),
          NavigationDestination(icon: Icon(Icons.person), label: 'Profile'),
        ],
        onDestinationSelected: (index) {
          switch (index) {
            case 0: context.go('/home');
            case 1: context.go('/orders');
            case 2: context.go('/profile');
          }
        },
      ),
    );
  }
}
```

- [ ] **Step 3: Delete old planner files**

```bash
rm customer_app/lib/screens/planner/planner_screen.dart
rm customer_app/lib/services/planner_service.dart
rm customer_app/lib/providers/planner_provider.dart
rmdir customer_app/lib/screens/planner
```

- [ ] **Step 4: Commit**

```bash
git add -A customer_app/
git commit -m "feat: update router and home screen for wizard flow, remove old planner"
```

---

## Phase 6: Admin Portal — Estimation Rules Page

### Task 12: Add estimation rules admin page

**Files:**
- Create: `admin_portal/src/app/estimation-rules/page.tsx`
- Modify: `admin_portal/src/components/sidebar.tsx`

- [ ] **Step 1: Create estimation-rules/page.tsx**

```tsx
'use client'

import { useEffect, useState } from 'react'
import { createClient } from '@/lib/supabase/client'
import { Button } from '@/components/ui/button'
import { Input } from '@/components/ui/input'
import { Label } from '@/components/ui/label'
import { Badge } from '@/components/ui/badge'
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card'
import { Dialog, DialogContent, DialogHeader, DialogTitle } from '@/components/ui/dialog'
import { Table, TableBody, TableCell, TableHead, TableHeader, TableRow } from '@/components/ui/table'
import { Textarea } from '@/components/ui/textarea'
import { toast } from 'sonner'
import { Pencil } from 'lucide-react'

interface EstimationRule {
  id: string; subcategory_slug: string; label: string; icon_name: string | null
  drinks_per_guest: number; servings_per_bottle: number; event_multipliers: Record<string, number>
  children_factor: number; is_active: boolean; sort_order: number
}

export default function EstimationRulesPage() {
  const supabase = createClient()
  const [rules, setRules] = useState<EstimationRule[]>([])
  const [editDialog, setEditDialog] = useState(false)
  const [editing, setEditing] = useState<EstimationRule | null>(null)
  const [drinksPerGuest, setDrinksPerGuest] = useState('')
  const [servingsPerBottle, setServingsPerBottle] = useState('')
  const [childrenFactor, setChildrenFactor] = useState('')
  const [multipliers, setMultipliers] = useState('')

  const fetchRules = async () => {
    const { data } = await supabase.from('estimation_rules').select('*').order('sort_order')
    setRules(data ?? [])
  }

  useEffect(() => { fetchRules() }, [])

  const openEdit = (rule: EstimationRule) => {
    setEditing(rule)
    setDrinksPerGuest(rule.drinks_per_guest.toString())
    setServingsPerBottle(rule.servings_per_bottle.toString())
    setChildrenFactor(rule.children_factor.toString())
    setMultipliers(JSON.stringify(rule.event_multipliers, null, 2))
    setEditDialog(true)
  }

  const saveRule = async () => {
    if (!editing) return
    let parsedMultipliers
    try { parsedMultipliers = JSON.parse(multipliers) }
    catch { toast.error('Invalid JSON for event multipliers'); return }

    const { error } = await supabase.from('estimation_rules').update({
      drinks_per_guest: parseFloat(drinksPerGuest),
      servings_per_bottle: parseFloat(servingsPerBottle),
      children_factor: parseFloat(childrenFactor),
      event_multipliers: parsedMultipliers,
    }).eq('id', editing.id)

    if (error) { toast.error(error.message); return }
    toast.success(`${editing.label} updated`)
    setEditDialog(false)
    fetchRules()
  }

  const toggleActive = async (id: string, current: boolean) => {
    await supabase.from('estimation_rules').update({ is_active: !current }).eq('id', id)
    toast.success(`Rule ${current ? 'deactivated' : 'activated'}`)
    fetchRules()
  }

  return (
    <div>
      <div className="flex items-center justify-between mb-8">
        <div>
          <h1 className="text-3xl font-bold">Estimation Rules</h1>
          <p className="text-muted-foreground mt-1">Configure beverage quantity formulas for the customer wizard</p>
        </div>
      </div>

      <Card className="mb-6">
        <CardHeader><CardTitle className="text-sm">Formula</CardTitle></CardHeader>
        <CardContent>
          <code className="text-xs bg-muted p-2 rounded block">
            effective_guests = (total_pax - children) + (children × children_factor)<br/>
            total_servings = effective_guests × drinks_per_guest × event_multiplier<br/>
            bottles_needed = ceil(total_servings / servings_per_bottle)
          </code>
        </CardContent>
      </Card>

      <Table>
        <TableHeader>
          <TableRow>
            <TableHead>Type</TableHead><TableHead>Drinks/Guest</TableHead><TableHead>Servings/Bottle</TableHead>
            <TableHead>Children Factor</TableHead><TableHead>Status</TableHead><TableHead></TableHead>
          </TableRow>
        </TableHeader>
        <TableBody>
          {rules.map((rule) => (
            <TableRow key={rule.id}>
              <TableCell className="font-medium">{rule.label}</TableCell>
              <TableCell>{rule.drinks_per_guest}</TableCell>
              <TableCell>{rule.servings_per_bottle}</TableCell>
              <TableCell>{rule.children_factor}</TableCell>
              <TableCell>
                <Badge variant={rule.is_active ? 'default' : 'destructive'} className="cursor-pointer"
                  onClick={() => toggleActive(rule.id, rule.is_active)}>
                  {rule.is_active ? 'Active' : 'Inactive'}
                </Badge>
              </TableCell>
              <TableCell>
                <Button variant="ghost" size="icon" onClick={() => openEdit(rule)}><Pencil className="h-4 w-4" /></Button>
              </TableCell>
            </TableRow>
          ))}
        </TableBody>
      </Table>

      <Dialog open={editDialog} onOpenChange={setEditDialog}>
        <DialogContent>
          <DialogHeader><DialogTitle>Edit: {editing?.label}</DialogTitle></DialogHeader>
          <div className="space-y-4">
            <div><Label>Drinks Per Guest</Label><Input type="number" step="0.1" value={drinksPerGuest} onChange={(e) => setDrinksPerGuest(e.target.value)} /></div>
            <div><Label>Servings Per Bottle</Label><Input type="number" step="0.1" value={servingsPerBottle} onChange={(e) => setServingsPerBottle(e.target.value)} /></div>
            <div><Label>Children Factor (0 = exclude children)</Label><Input type="number" step="0.1" value={childrenFactor} onChange={(e) => setChildrenFactor(e.target.value)} /></div>
            <div>
              <Label>Event Multipliers (JSON)</Label>
              <Textarea rows={6} value={multipliers} onChange={(e) => setMultipliers(e.target.value)} className="font-mono text-xs" />
            </div>
            <Button onClick={saveRule} className="w-full">Save</Button>
          </div>
        </DialogContent>
      </Dialog>
    </div>
  )
}
```

- [ ] **Step 2: Update sidebar.tsx — add Estimation Rules nav item**

Add to the `navItems` array in `src/components/sidebar.tsx`, after the Equipment item:

```typescript
{ href: '/estimation-rules', label: 'Estimation Rules', icon: Calculator },
```

Add `Calculator` to the lucide-react import.

- [ ] **Step 3: Commit**

```bash
git add admin_portal/src/app/estimation-rules/ admin_portal/src/components/sidebar.tsx
git commit -m "feat: add estimation rules admin page with formula editor"
```

---

## Phase 7: Verification

### Task 13: Flutter analyze + build verification

- [ ] **Step 1: Run flutter analyze**

```bash
cd customer_app
export PATH="/c/flutter/bin:$PATH"
flutter analyze
```

Expected: No issues found.

- [ ] **Step 2: Run flutter test**

```bash
flutter test
```

Expected: All existing tests pass.

- [ ] **Step 3: Run next build for admin portal**

```bash
cd ../admin_portal
npx next build
```

Expected: Build succeeds with no type errors.

- [ ] **Step 4: Push migration to Supabase**

```bash
cd ..
supabase db push
```

Expected: Migration 005 applied.

- [ ] **Step 5: Tag release**

```bash
git tag v0.4.0-wizard-flow
```
