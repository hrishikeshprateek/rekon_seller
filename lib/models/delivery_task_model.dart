// Delivery Task Model
enum TaskType { delivery, collection }
enum TaskStatus { pending, done, returnTask }
enum PaymentType { cash, credit }

class DeliveryTask {
  final String id;
  final TaskType type;
  final TaskStatus status;
  final String partyName;
  final String partyId;
  final String station;
  final String area;
  final double? latitude;
  final double? longitude;
  final String? billNo;
  final DateTime? billDate;
  final PaymentType? paymentType;
  final double? billAmount;
  final int? itemCount;
  final double? distanceKm; // Distance from delivery man's current location
  final String? mobile; // Optional mobile number for quick actions (call)

  DeliveryTask({
    required this.id,
    required this.type,
    required this.status,
    required this.partyName,
    required this.partyId,
    required this.station,
    required this.area,
    this.latitude,
    this.longitude,
    this.billNo,
    this.billDate,
    this.paymentType,
    this.billAmount,
    this.itemCount,
    this.distanceKm,
    this.mobile,
  });

  bool get hasLocation => latitude != null && longitude != null;

  String get typeLabel => type == TaskType.delivery ? 'Delivery' : 'Collection';

  String get statusLabel {
    switch (status) {
      case TaskStatus.pending:
        return 'Pending';
      case TaskStatus.done:
        return 'Done';
      case TaskStatus.returnTask:
        return 'Return';
    }
  }

  String get paymentTypeLabel => paymentType == PaymentType.cash ? 'Cash' : 'Credit';

  Map<String, dynamic> toJson() => {
    'id': id,
    'type': type.name,
    'status': status.name,
    'partyName': partyName,
    'partyId': partyId,
    'station': station,
    'area': area,
    'latitude': latitude,
    'longitude': longitude,
    'billNo': billNo,
    'billDate': billDate?.toIso8601String(),
    'paymentType': paymentType?.name,
    'billAmount': billAmount,
    'itemCount': itemCount,
    'distanceKm': distanceKm,
    'mobile': mobile,
  };

  factory DeliveryTask.fromJson(Map<String, dynamic> json) => DeliveryTask(
    id: json['id'] as String,
    type: TaskType.values.firstWhere((e) => e.name == json['type']),
    status: TaskStatus.values.firstWhere((e) => e.name == json['status']),
    partyName: json['partyName'] as String,
    partyId: json['partyId'] as String,
    station: json['station'] as String,
    area: json['area'] as String,
    latitude: json['latitude'] as double?,
    longitude: json['longitude'] as double?,
    billNo: json['billNo'] as String?,
    billDate: json['billDate'] != null ? DateTime.parse(json['billDate'] as String) : null,
    paymentType: json['paymentType'] != null
        ? PaymentType.values.firstWhere((e) => e.name == json['paymentType'])
        : null,
    billAmount: json['billAmount'] as double?,
    itemCount: json['itemCount'] as int?,
    distanceKm: json['distanceKm'] as double?,
    mobile: json['mobile'] as String?,
  );

  // Copy with method for updating distance
  DeliveryTask copyWith({double? distanceKm, String? mobile}) => DeliveryTask(
    id: id,
    type: type,
    status: status,
    partyName: partyName,
    partyId: partyId,
    station: station,
    area: area,
    latitude: latitude,
    longitude: longitude,
    billNo: billNo,
    billDate: billDate,
    paymentType: paymentType,
    billAmount: billAmount,
    itemCount: itemCount,
    distanceKm: distanceKm ?? this.distanceKm,
    mobile: mobile ?? this.mobile,
  );
}
