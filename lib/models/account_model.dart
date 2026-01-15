class Account {
  final String id;
  final String name;
  final String type; // 'Party', 'Bank', 'Cash'
  final String? phone;
  final String? email;
  final double? balance;
  final String? address;
  final double? latitude;
  final double? longitude;

  // Additional fields from API
  final String? code;
  final String? gstNumber;
  final String? address2;
  final String? address3;
  final int? rcount;
  final int? acIdCol;
  final double? opBal;
  final double? closBal;
  final int? accountCreditDays;
  final int? accountCreditLimit;
  final int? accountCreditBills;

  const Account({
    required this.id,
    required this.name,
    required this.type,
    this.phone,
    this.email,
    this.balance,
    this.address,
    this.latitude,
    this.longitude,
    this.code,
    this.gstNumber,
    this.address2,
    this.address3,
    this.rcount,
    this.acIdCol,
    this.opBal,
    this.closBal,
    this.accountCreditDays,
    this.accountCreditLimit,
    this.accountCreditBills,
  });

  /// Check if valid location data exists
  bool get hasLocation =>
      latitude != null && longitude != null && latitude != 0 && longitude != 0;

  /// Convert model to a JSON-serializable map
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
    'code': code,
    'gstNumber': gstNumber,
    'address2': address2,
    'address3': address3,
    'rcount': rcount,
    'acIdCol': acIdCol,
    'opBal': opBal,
    'closBal': closBal,
    'accountCreditDays': accountCreditDays,
    'accountCreditLimit': accountCreditLimit,
    'accountCreditBills': accountCreditBills,
  };

  /// Create an Account from API JSON (robust to nulls, types, and empty strings)
  factory Account.fromApiJson(Map<String, dynamic> json) {
    // Helper: Safely parse double from String, Int, or Double
    double? _toDouble(dynamic v) {
      if (v == null) return null;
      if (v is double) return v;
      if (v is int) return v.toDouble();
      if (v is String) {
        if (v.trim().isEmpty) return null;
        return double.tryParse(v);
      }
      return null;
    }

    // Helper: Safely parse int
    int? _toInt(dynamic v) {
      if (v == null) return null;
      if (v is int) return v;
      if (v is double) return v.toInt();
      if (v is String) {
        if (v.trim().isEmpty) return null;
        return int.tryParse(v);
      }
      return null;
    }

    // Helper: Safely stringify
    String _str(dynamic v) {
      if (v == null) return '';
      return v.toString().trim();
    }

    // Build address from API fields (Address1, Address2, Address3)
    final parts = <String>[];
    if (json['Address1'] != null && json['Address1'].toString().trim().isNotEmpty) {
      parts.add(json['Address1'].toString().trim());
    }
    if (json['Address2'] != null && json['Address2'].toString().trim().isNotEmpty) {
      parts.add(json['Address2'].toString().trim());
    }
    if (json['Address3'] != null && json['Address3'].toString().trim().isNotEmpty) {
      parts.add(json['Address3'].toString().trim());
    }
    final fullAddress = parts.isEmpty ? null : parts.join(', ');

    return Account(
      id: _str(json['Code']).isEmpty ? _str(json['id']) : _str(json['Code']),
      name: _str(json['Name']).isEmpty ? _str(json['name']) : _str(json['Name']),
      type: _str(json['Type']).isEmpty ? 'Party' : _str(json['Type']),
      phone: json['Mobile'] != null ? _str(json['Mobile']) : null,
      email: json['Email'] != null ? _str(json['Email']) : null,

      // Critical Mapping for Balance
      balance: _toDouble(json['ClosBal'] ?? json['Balance'] ?? json['closingBalance']),
      closBal: _toDouble(json['ClosBal'] ?? json['closBal']),

      address: fullAddress,

      // Handle lat/long which might be empty strings "" in API
      latitude: _toDouble(json['latitude'] ?? json['Latitude']),
      longitude: _toDouble(json['longitude'] ?? json['Longitude']),

      code: json['Code'] != null ? _str(json['Code']) : null,
      gstNumber: json['GstNumber'] != null ? _str(json['GstNumber']) : null,
      address2: json['Address2'] != null ? _str(json['Address2']) : null,
      address3: json['Address3'] != null ? _str(json['Address3']) : null,
      rcount: _toInt(json['RCount'] ?? json['rcount']),
      acIdCol: _toInt(json['ac_id_col'] ?? json['acIdCol'] ?? json['AcIdCol']),
      opBal: _toDouble(json['OpBal'] ?? json['opbal']),
      accountCreditDays: _toInt(json['account_creditdays'] ?? json['accountCreditDays']),
      accountCreditLimit: _toInt(json['account_creditlimit'] ?? json['accountCreditLimit']),
      accountCreditBills: _toInt(json['account_creditbills'] ?? json['accountCreditBills']),
    );
  }

  @override
  String toString() => name;
}