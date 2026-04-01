import '../models/product.dart';

class PlannerSuggestion {
  final Product product;
  final String variantId;
  final int quantity;
  final String unitType;
  final String reason;

  PlannerSuggestion({required this.product, required this.variantId, required this.quantity, required this.unitType, required this.reason});
}

class PlannerService {
  List<PlannerSuggestion> estimateBeverages({
    required int guestCount,
    required String eventType,
    required List<Product> availableProducts,
  }) {
    final suggestions = <PlannerSuggestion>[];

    final hardDrinkMultiplier = switch (eventType) {
      'wedding' => 1.0,
      'corporate' => 0.6,
      'birthday' => 0.8,
      'house_party' => 1.2,
      _ => 1.0,
    };

    // Whiskey: ~0.25 bottles per guest
    final whiskeyBottles = (guestCount * 0.25 * hardDrinkMultiplier).ceil();
    _addSuggestion(suggestions, availableProducts, preferredSize: '750ml', quantity: whiskeyBottles, reason: '~3 pegs per guest across spirits', tagPreference: 'popular');

    // Beer: ~2 per guest
    final beerBottles = (guestCount * 2.0).ceil();
    _addSuggestion(suggestions, availableProducts, preferredSize: '650ml', quantity: beerBottles, reason: '~2 beers per guest', tagPreference: 'popular');

    // Soft drinks: ~0.5L per guest
    final softDrinkBottles = (guestCount * 0.5 / 2.25).ceil();
    _addSuggestion(suggestions, availableProducts, preferredSize: '2.25L', quantity: softDrinkBottles, reason: '~0.5L soft drink per guest', tagPreference: 'popular');

    // Water: ~0.5L per guest
    final waterBottles = (guestCount * 0.5).ceil();
    _addSuggestion(suggestions, availableProducts, preferredSize: '1L', quantity: waterBottles, reason: '~0.5L water per guest');

    // Ice: ~0.5kg per guest
    final iceBags = (guestCount * 0.5 / 5.0).ceil();
    _addSuggestion(suggestions, availableProducts, preferredSize: '5kg bag', quantity: iceBags, reason: '~0.5kg ice per guest');

    return suggestions;
  }

  void _addSuggestion(List<PlannerSuggestion> suggestions, List<Product> products, {required String preferredSize, required int quantity, required String reason, String? tagPreference}) {
    final matching = products.where((p) => p.variants.any((v) => v.size == preferredSize)).toList();
    if (matching.isEmpty) return;

    final product = tagPreference != null
        ? matching.firstWhere((p) => p.tags.contains(tagPreference), orElse: () => matching.first)
        : matching.first;

    final variant = product.variants.firstWhere((v) => v.size == preferredSize);

    suggestions.add(PlannerSuggestion(product: product, variantId: variant.id, quantity: quantity, unitType: 'unit', reason: reason));
  }
}
