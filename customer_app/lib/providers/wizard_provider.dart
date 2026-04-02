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
