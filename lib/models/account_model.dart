// Account/Party Model
class Account {
  final String id;
  final String name;
  final String type; // 'Party', 'Bank', 'Cash', etc.
  final String? phone;
  final String? email;
  final double? balance;
  final String? address;
  final double? latitude;
  final double? longitude;

  Account({
    required this.id,
    required this.name,
    required this.type,
    this.phone,
    this.email,
    this.balance,
    this.address,
    this.latitude,
    this.longitude,
  });

  // Convert to JSON
  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'type': type,
    'phone': phone,
    'email': email,
    'balance': balance,
    'address': address,
    'latitude': latitude,
    'longitude': longitude,
  };

  // Create from JSON
  factory Account.fromJson(Map<String, dynamic> json) => Account(
    id: json['id'] as String,
    name: json['name'] as String,
    type: json['type'] as String,
    phone: json['phone'] as String?,
    email: json['email'] as String?,
    balance: json['balance'] as double?,
    address: json['address'] as String?,
    latitude: json['latitude'] as double?,
    longitude: json['longitude'] as double?,
  );

  // Check if account has location
  bool get hasLocation => latitude != null && longitude != null;

  @override
  String toString() => name;
}

