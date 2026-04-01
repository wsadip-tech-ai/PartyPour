class Discount {
  final String id;
  final String? variantId;
  final String type;
  final double value;
  final DateTime validFrom;
  final DateTime validUntil;

  Discount({required this.id, this.variantId, required this.type, required this.value, required this.validFrom, required this.validUntil});

  factory Discount.fromJson(Map<String, dynamic> json) {
    return Discount(
      id: json['id'] as String,
      variantId: json['variant_id'] as String?,
      type: json['type'] as String,
      value: (json['value'] as num).toDouble(),
      validFrom: DateTime.parse(json['valid_from'] as String),
      validUntil: DateTime.parse(json['valid_until'] as String),
    );
  }

  double apply(double price) {
    if (type == 'percentage') return price * (1 - value / 100);
    return price - value;
  }
}
