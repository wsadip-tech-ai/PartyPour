class Product {
  final String id;
  final String subcategoryId;
  final String name;
  final String origin;
  final String? description;
  final String? imageUrl;
  final List<String> tags;
  final List<Variant> variants;

  Product({required this.id, required this.subcategoryId, required this.name, required this.origin, this.description, this.imageUrl, this.tags = const [], this.variants = const []});

  factory Product.fromJson(Map<String, dynamic> json) {
    final variantsList = (json['variants'] as List<dynamic>?)?.map((v) => Variant.fromJson(v as Map<String, dynamic>)).toList() ?? [];
    return Product(
      id: json['id'] as String,
      subcategoryId: json['subcategory_id'] as String,
      name: json['name'] as String,
      origin: json['origin'] as String,
      description: json['description'] as String?,
      imageUrl: json['image_url'] as String?,
      tags: (json['tags'] as List<dynamic>?)?.cast<String>() ?? [],
      variants: variantsList,
    );
  }

  double get lowestPrice => variants.isEmpty ? 0 : variants.map((v) => v.unitPrice).reduce((a, b) => a < b ? a : b);

  Map<String, dynamic> toJson() => {
    'id': id,
    'subcategory_id': subcategoryId,
    'name': name,
    'origin': origin,
    'description': description,
    'image_url': imageUrl,
    'tags': tags,
    'variants': variants.map((v) => v.toJson()).toList(),
  };
}

class Variant {
  final String id;
  final String productId;
  final String size;
  final double unitPrice;
  final int? caseSize;
  final double? casePrice;
  final double? mrp;

  Variant({required this.id, required this.productId, required this.size, required this.unitPrice, this.caseSize, this.casePrice, this.mrp});

  factory Variant.fromJson(Map<String, dynamic> json) {
    return Variant(
      id: json['id'] as String,
      productId: json['product_id'] as String,
      size: json['size'] as String,
      unitPrice: (json['unit_price'] as num).toDouble(),
      caseSize: json['case_size'] as int?,
      casePrice: (json['case_price'] as num?)?.toDouble(),
      mrp: (json['mrp'] as num?)?.toDouble(),
    );
  }

  /// Whether this variant is sold only as a case (e.g. beer).
  bool get isCaseOnly => size.toLowerCase().startsWith('case');

  double get savingsPerUnit => caseSize != null && casePrice != null && !isCaseOnly ? unitPrice - (casePrice! / caseSize!) : 0;

  Map<String, dynamic> toJson() => {
    'id': id,
    'product_id': productId,
    'size': size,
    'unit_price': unitPrice,
    'case_size': caseSize,
    'case_price': casePrice,
    'mrp': mrp,
  };
}
