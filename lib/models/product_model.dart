// Product/Medicine Model
class Product {
  final String id;
  final String name;
  final String category;
  final double price;
  final double mrp;
  final String unit; // 'Strip', 'Box', 'Bottle', etc.
  final int stockQuantity;
  final String? manufacturer;
  final String? batchNumber;
  final DateTime? expiryDate;
  final String? description;
  final String? imageUrl;
  final String? salt;
  final String? code; // Icode
  final int? iidcol; // i_id_col

  Product({
    required this.id,
    required this.name,
    required this.category,
    required this.price,
    required this.mrp,
    required this.unit,
    required this.stockQuantity,
    this.manufacturer,
    this.batchNumber,
    this.expiryDate,
    this.description,
    this.imageUrl,
    this.salt,
    this.code,
    this.iidcol,
  });

  // Discount percentage
  double get discountPercent => ((mrp - price) / mrp * 100);

  // Check if product is in stock
  bool get isInStock => stockQuantity > 0;

  // Check if expiring soon (within 3 months)
  bool get isExpiringSoon {
    if (expiryDate == null) return false;
    final threeMonthsFromNow = DateTime.now().add(const Duration(days: 90));
    return expiryDate!.isBefore(threeMonthsFromNow);
  }

  // Convert to JSON
  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'category': category,
    'price': price,
    'mrp': mrp,
    'unit': unit,
    'stockQuantity': stockQuantity,
    'manufacturer': manufacturer,
    'batchNumber': batchNumber,
    'expiryDate': expiryDate?.toIso8601String(),
    'description': description,
    'imageUrl': imageUrl,
    'salt': salt,
    'code': code,
    'iidcol': iidcol,
  };

  // Create from JSON
  factory Product.fromJson(Map<String, dynamic> json) => Product(
    id: json['id'] as String,
    name: json['name'] as String,
    category: json['category'] as String,
    price: (json['price'] as num).toDouble(),
    mrp: (json['mrp'] as num).toDouble(),
    unit: json['unit'] as String,
    stockQuantity: json['stockQuantity'] as int,
    manufacturer: json['manufacturer'] as String?,
    batchNumber: json['batchNumber'] as String?,
    expiryDate: json['expiryDate'] != null
        ? DateTime.parse(json['expiryDate'] as String)
        : null,
    description: json['description'] as String?,
    imageUrl: json['imageUrl'] as String?,
    salt: json['salt'] as String?,
    code: json['code'] as String?,
    iidcol: json['iidcol'] as int?,
  );

  @override
  String toString() => name;
}
