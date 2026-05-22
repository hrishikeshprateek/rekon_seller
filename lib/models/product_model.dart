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
  final String? refNumber; // RefNumber from API
  final double gst; // GST / tax percentage
  final String? scheme; // scheme narration, e.g. "10.00 + 1.00 Full"
  // Visibility flags from GetItemList.
  final bool showMrp;
  final bool showRate;
  final bool showStock;
  final bool showScheme;
  final String? firmName; // owning firm name
  final double rating; // item rating

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
    this.refNumber,
    this.gst = 0,
    this.scheme,
    this.showMrp = true,
    this.showRate = true,
    this.showStock = true,
    this.showScheme = true,
    this.firmName,
    this.rating = 0,
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
    'RefNumber': refNumber,
    'gst': gst,
    'scheme': scheme,
    'showMrp': showMrp,
    'showRate': showRate,
    'showStock': showStock,
    'showScheme': showScheme,
    'firmName': firmName,
    'rating': rating,
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
    refNumber: json['refNumber'] as String? ?? json['RefNumber'] as String?,
    gst: (json['gst'] as num?)?.toDouble() ?? 0,
    scheme: json['scheme'] as String?,
    showMrp: json['showMrp'] as bool? ?? true,
    showRate: json['showRate'] as bool? ?? true,
    showStock: json['showStock'] as bool? ?? true,
    showScheme: json['showScheme'] as bool? ?? true,
    firmName: json['firmName'] as String?,
    rating: (json['rating'] as num?)?.toDouble() ?? 0,
  );

  @override
  String toString() => name;
}
