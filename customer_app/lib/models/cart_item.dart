import 'product.dart';

class CartItem {
  final Product product;
  final Variant variant;
  final String unitType;
  int quantity;

  CartItem({required this.product, required this.variant, required this.unitType, this.quantity = 1});

  double get unitPrice => unitType == 'case' && variant.casePrice != null ? variant.casePrice! : variant.unitPrice;
  double get totalPrice => unitPrice * quantity;
  int get effectiveUnits => unitType == 'case' && variant.caseSize != null ? quantity * variant.caseSize! : quantity;
}
