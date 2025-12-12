// Delivery Man Model
class DeliveryMan {
  final String id;
  final String name;
  final String phone;
  final double? currentLatitude;
  final double? currentLongitude;
  final String? currentLocation;

  DeliveryMan({
    required this.id,
    required this.name,
    required this.phone,
    this.currentLatitude,
    this.currentLongitude,
    this.currentLocation,
  });

  bool get hasCurrentLocation => currentLatitude != null && currentLongitude != null;

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'phone': phone,
    'currentLatitude': currentLatitude,
    'currentLongitude': currentLongitude,
    'currentLocation': currentLocation,
  };

  factory DeliveryMan.fromJson(Map<String, dynamic> json) => DeliveryMan(
    id: json['id'] as String,
    name: json['name'] as String,
    phone: json['phone'] as String,
    currentLatitude: json['currentLatitude'] as double?,
    currentLongitude: json['currentLongitude'] as double?,
    currentLocation: json['currentLocation'] as String?,
  );
}

