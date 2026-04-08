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

  /// Returns the display unit for this beverage type
  String get unit => subcategorySlug == 'beer-bottle-can' ? 'cases' : 'litres';

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
