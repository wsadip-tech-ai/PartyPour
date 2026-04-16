// lib/providers/wizard_provider.dart

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../main.dart' show prefs;
import '../models/estimation_rule.dart';
import '../models/product.dart';
import '../services/estimation_service.dart';
import 'auth_provider.dart';

const _wizardKey = 'wizard_state';

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

  Map<String, dynamic> toJson() => {
    'product': product.toJson(),
    'variant': variant.toJson(),
    'quantity': quantity,
    'unitType': unitType,
  };

  factory BrandSelection.fromJson(Map<String, dynamic> json) => BrandSelection(
    product: Product.fromJson(json['product'] as Map<String, dynamic>),
    variant: Variant.fromJson(json['variant'] as Map<String, dynamic>),
    quantity: json['quantity'] as int,
    unitType: json['unitType'] as String? ?? 'unit',
  );
}

class WizardState {
  final int totalPax;
  final int childrenCount;
  final int ladiesCount;
  final String eventType;
  final DateTime? eventDate;
  final TimeOfDay? eventStartTime;
  final TimeOfDay? eventEndTime;
  final List<String> selectedTypeSlugs;
  final Map<String, int> estimatedQuantities;
  final Map<String, List<BrandSelection>> brandSelections;
  final String deliveryAddress;
  final String contactPhone;
  final String specialInstructions;

  WizardState({
    this.totalPax = 0,
    this.childrenCount = 0,
    this.ladiesCount = 0,
    this.eventType = 'wedding',
    this.eventDate,
    this.eventStartTime,
    this.eventEndTime,
    this.selectedTypeSlugs = const [],
    this.estimatedQuantities = const {},
    this.brandSelections = const {},
    this.deliveryAddress = '',
    this.contactPhone = '',
    this.specialInstructions = '',
  });

  WizardState copyWith({
    int? totalPax,
    int? childrenCount,
    int? ladiesCount,
    String? eventType,
    DateTime? eventDate,
    TimeOfDay? eventStartTime,
    TimeOfDay? eventEndTime,
    List<String>? selectedTypeSlugs,
    Map<String, int>? estimatedQuantities,
    Map<String, List<BrandSelection>>? brandSelections,
    String? deliveryAddress,
    String? contactPhone,
    String? specialInstructions,
  }) {
    return WizardState(
      totalPax: totalPax ?? this.totalPax,
      childrenCount: childrenCount ?? this.childrenCount,
      ladiesCount: ladiesCount ?? this.ladiesCount,
      eventType: eventType ?? this.eventType,
      eventDate: eventDate ?? this.eventDate,
      eventStartTime: eventStartTime ?? this.eventStartTime,
      eventEndTime: eventEndTime ?? this.eventEndTime,
      selectedTypeSlugs: selectedTypeSlugs ?? this.selectedTypeSlugs,
      estimatedQuantities: estimatedQuantities ?? this.estimatedQuantities,
      brandSelections: brandSelections ?? this.brandSelections,
      deliveryAddress: deliveryAddress ?? this.deliveryAddress,
      contactPhone: contactPhone ?? this.contactPhone,
      specialInstructions: specialInstructions ?? this.specialInstructions,
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

  Map<String, dynamic> toJson() => {
    'totalPax': totalPax,
    'childrenCount': childrenCount,
    'ladiesCount': ladiesCount,
    'eventType': eventType,
    'eventDate': eventDate?.toIso8601String(),
    'eventStartTime': eventStartTime != null ? '${eventStartTime!.hour}:${eventStartTime!.minute}' : null,
    'eventEndTime': eventEndTime != null ? '${eventEndTime!.hour}:${eventEndTime!.minute}' : null,
    'selectedTypeSlugs': selectedTypeSlugs,
    'estimatedQuantities': estimatedQuantities,
    'brandSelections': brandSelections.map((k, v) => MapEntry(k, v.map((s) => s.toJson()).toList())),
    'deliveryAddress': deliveryAddress,
    'contactPhone': contactPhone,
    'specialInstructions': specialInstructions,
  };

  factory WizardState.fromJson(Map<String, dynamic> json) {
    TimeOfDay? parseTime(String? s) {
      if (s == null) return null;
      final parts = s.split(':');
      return TimeOfDay(hour: int.parse(parts[0]), minute: int.parse(parts[1]));
    }

    final brandMap = <String, List<BrandSelection>>{};
    final rawBrands = json['brandSelections'] as Map<String, dynamic>? ?? {};
    for (final entry in rawBrands.entries) {
      final list = (entry.value as List<dynamic>)
          .map((item) => BrandSelection.fromJson(item as Map<String, dynamic>))
          .toList();
      brandMap[entry.key] = list;
    }

    final rawQty = json['estimatedQuantities'] as Map<String, dynamic>? ?? {};
    final quantities = rawQty.map((k, v) => MapEntry(k, (v as num).toInt()));

    return WizardState(
      totalPax: json['totalPax'] as int? ?? 0,
      childrenCount: json['childrenCount'] as int? ?? 0,
      ladiesCount: json['ladiesCount'] as int? ?? 0,
      eventType: json['eventType'] as String? ?? 'wedding',
      eventDate: json['eventDate'] != null ? DateTime.tryParse(json['eventDate'] as String) : null,
      eventStartTime: parseTime(json['eventStartTime'] as String?),
      eventEndTime: parseTime(json['eventEndTime'] as String?),
      selectedTypeSlugs: (json['selectedTypeSlugs'] as List<dynamic>?)?.cast<String>() ?? [],
      estimatedQuantities: quantities,
      brandSelections: brandMap,
      deliveryAddress: json['deliveryAddress'] as String? ?? '',
      contactPhone: json['contactPhone'] as String? ?? '',
      specialInstructions: json['specialInstructions'] as String? ?? '',
    );
  }
}

class WizardNotifier extends StateNotifier<WizardState> {
  WizardNotifier() : super(_restore());

  /// Restore saved wizard state from SharedPreferences
  static WizardState _restore() {
    try {
      final raw = prefs.getString(_wizardKey);
      if (raw != null) {
        return WizardState.fromJson(jsonDecode(raw) as Map<String, dynamic>);
      }
    } catch (_) {
      // Corrupted data — start fresh
    }
    return WizardState();
  }

  /// Persist current state after every mutation
  void _persist() {
    prefs.setString(_wizardKey, jsonEncode(state.toJson()));
  }

  void _update(WizardState newState) {
    state = newState;
    _persist();
  }

  // Step 1
  void setTotalPax(int pax) => _update(state.copyWith(totalPax: pax));
  void setChildrenCount(int count) => _update(state.copyWith(childrenCount: count));
  void setLadiesCount(int count) => _update(state.copyWith(ladiesCount: count));
  void setEventType(String type) => _update(state.copyWith(eventType: type));
  void setEventDate(DateTime date) => _update(state.copyWith(eventDate: date));
  void setEventStartTime(TimeOfDay time) => _update(state.copyWith(eventStartTime: time));
  void setEventEndTime(TimeOfDay time) => _update(state.copyWith(eventEndTime: time));
  void setDeliveryAddress(String address) => _update(state.copyWith(deliveryAddress: address));
  void setContactPhone(String phone) => _update(state.copyWith(contactPhone: phone));
  void setSpecialInstructions(String instructions) => _update(state.copyWith(specialInstructions: instructions));

  // Step 2
  void toggleType(String slug) {
    final current = List<String>.from(state.selectedTypeSlugs);
    if (current.contains(slug)) {
      current.remove(slug);
    } else {
      current.add(slug);
    }
    _update(state.copyWith(selectedTypeSlugs: current));
  }

  void setSelectedTypes(List<String> slugs) {
    _update(state.copyWith(selectedTypeSlugs: slugs));
  }

  // Step 3
  void setEstimatedQuantities(Map<String, int> quantities) {
    _update(state.copyWith(estimatedQuantities: quantities));
  }

  void updateQuantity(String slug, int quantity) {
    final updated = Map<String, int>.from(state.estimatedQuantities);
    updated[slug] = quantity.clamp(0, 99999);
    _update(state.copyWith(estimatedQuantities: updated));
  }

  // Step 4
  void setBrandSelections(String slug, List<BrandSelection> selections) {
    final updated = Map<String, List<BrandSelection>>.from(state.brandSelections);
    updated[slug] = selections;
    _update(state.copyWith(brandSelections: updated));
  }

  void addBrandSelection(String slug, BrandSelection selection) {
    final updated = Map<String, List<BrandSelection>>.from(state.brandSelections);
    final list = List<BrandSelection>.from(updated[slug] ?? []);
    list.add(selection);
    updated[slug] = list;
    _update(state.copyWith(brandSelections: updated));
  }

  void removeBrandSelection(String slug, int index) {
    final updated = Map<String, List<BrandSelection>>.from(state.brandSelections);
    final list = List<BrandSelection>.from(updated[slug] ?? []);
    if (index < list.length) list.removeAt(index);
    updated[slug] = list;
    _update(state.copyWith(brandSelections: updated));
  }

  // Step 5 — update quantity in review
  void updateBrandQuantity(String slug, int index, int quantity) {
    final updated = Map<String, List<BrandSelection>>.from(state.brandSelections);
    final list = List<BrandSelection>.from(updated[slug] ?? []);
    if (index < list.length) {
      list[index].quantity = quantity.clamp(0, 99999);
      updated[slug] = list;
      _update(state.copyWith(brandSelections: updated));
    }
  }

  void reset() {
    state = WizardState();
    prefs.remove(_wizardKey);
  }
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
