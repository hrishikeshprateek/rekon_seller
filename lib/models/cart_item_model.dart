import 'product_model.dart';

// Cart Item Model
class CartItem {
  final Product product;
  int quantity;
  final double priceAtAddition; // Store price when added (in case it changes)

  CartItem({
    required this.product,
    this.quantity = 1,
    double? priceAtAddition,
  }) : priceAtAddition = priceAtAddition ?? product.price;

  // Total for this line item
  double get total => priceAtAddition * quantity;

  // Total MRP (before discount)
  double get totalMrp => product.mrp * quantity;

  // Discount amount
  double get discountAmount => totalMrp - total;

  // Copy with new quantity
  CartItem copyWith({int? quantity}) => CartItem(
    product: product,
    quantity: quantity ?? this.quantity,
    priceAtAddition: priceAtAddition,
  );

  // Convert to JSON
  Map<String, dynamic> toJson() => {
    'product': product.toJson(),
    'quantity': quantity,
    'priceAtAddition': priceAtAddition,
  };

  // Create from JSON
  factory CartItem.fromJson(Map<String, dynamic> json) => CartItem(
    product: Product.fromJson(json['product'] as Map<String, dynamic>),
    quantity: json['quantity'] as int,
    priceAtAddition: (json['priceAtAddition'] as num).toDouble(),
  );
}

