class Category {
  final String id;
  final String name;
  final String slug;
  final int sortOrder;
  final String? imageUrl;

  Category({required this.id, required this.name, required this.slug, required this.sortOrder, this.imageUrl});

  factory Category.fromJson(Map<String, dynamic> json) {
    return Category(
      id: json['id'] as String,
      name: json['name'] as String,
      slug: json['slug'] as String,
      sortOrder: json['sort_order'] as int,
      imageUrl: json['image_url'] as String?,
    );
  }
}

class Subcategory {
  final String id;
  final String categoryId;
  final String name;
  final String slug;
  final int sortOrder;
  final String? imageUrl;

  Subcategory({required this.id, required this.categoryId, required this.name, required this.slug, required this.sortOrder, this.imageUrl});

  factory Subcategory.fromJson(Map<String, dynamic> json) {
    return Subcategory(
      id: json['id'] as String,
      categoryId: json['category_id'] as String,
      name: json['name'] as String,
      slug: json['slug'] as String,
      sortOrder: json['sort_order'] as int,
      imageUrl: json['image_url'] as String?,
    );
  }
}
