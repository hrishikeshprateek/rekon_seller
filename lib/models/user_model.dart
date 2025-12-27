// User Model for Login Response
class UserModel {
  final String firstName;
  final String lastName;
  final String city;
  final String prefLang;
  final String mobileNumber;
  final String userId;
  final bool userActive;
  final String userType;
  final String address;
  final String licenseNumber;
  final List<Store> stores; // list of stores from profile

  UserModel({
    required this.firstName,
    required this.lastName,
    required this.city,
    required this.prefLang,
    required this.mobileNumber,
    required this.userId,
    required this.userActive,
    required this.userType,
    required this.address,
    required this.licenseNumber,
    this.stores = const [],
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      firstName: json['first_name'] ?? '',
      lastName: json['last_name'] ?? '',
      city: json['city'] ?? '',
      prefLang: json['pref_lang'] ?? 'en',
      mobileNumber: json['mobile_number'] ?? '',
      userId: json['user_id']?.toString() ?? '',
      userActive: json['user_active'] ?? false,
      userType: json['user_type'] ?? '',
      address: json['address'] ?? '',
      licenseNumber: json['license_number'] ?? '',
      stores: (json['stores'] as List<dynamic>? ?? []).map((e) => Store.fromJson(e)).toList(),
    );
  }

  /// Construct user from ValidateLicense `Profile` structure
  factory UserModel.fromProfileJson(Map<String, dynamic> json, {String? licenseNumber}) {
    // Parse stores array if present
    List<Store> parsedStores = [];
    try {
      final rawStores = json['Store'];
      if (rawStores is List) {
        parsedStores = rawStores.map((e) {
          if (e is Map<String, dynamic>) return Store.fromJson(e);
          try {
            return Store.fromJson(Map<String, dynamic>.from(e));
          } catch (_) {
            return Store.empty();
          }
        }).where((s) => s.firmCode.isNotEmpty || s.name.isNotEmpty).toList();
      }
    } catch (_) {}

    return UserModel(
      firstName: json['NAME'] ?? json['first_name'] ?? '',
      lastName: '',
      city: json['CITY'] ?? json['city'] ?? '',
      prefLang: json['pref_lang'] ?? 'en',
      mobileNumber: json['MOBILENO'] ?? json['mobile_number'] ?? '',
      userId: json['CUID']?.toString() ?? json['user_id']?.toString() ?? '',
      userActive: true,
      userType: json['user_type'] ?? 'SalesMan',
      address: json['address'] ?? '',
      licenseNumber: licenseNumber ?? '',
      stores: parsedStores,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'first_name': firstName,
      'last_name': lastName,
      'city': city,
      'pref_lang': prefLang,
      'mobile_number': mobileNumber,
      'user_id': userId,
      'user_active': userActive,
      'user_type': userType,
      'address': address,
      'license_number': licenseNumber,
      'stores': stores.map((s) => s.toJson()).toList(),
    };
  }

  String get fullName => '$firstName $lastName'.trim();
}

class LoginResponse {
  final bool success;
  final String message;
  final int rs;
  final LoginData? data;

  LoginResponse({
    required this.success,
    required this.message,
    required this.rs,
    this.data,
  });

  factory LoginResponse.fromJson(Map<String, dynamic> json) {
    return LoginResponse(
      success: json['success'] ?? false,
      message: json['message'] ?? '',
      rs: json['rs'] ?? 0,
      data: json['data'] != null ? LoginData.fromJson(json['data']) : null,
    );
  }
}

class LoginData {
  final String token;
  final String jwtToken;
  final String refreshToken;
  final String language;
  final bool isRegistered;
  final bool isAuthorised;
  final bool isActive;
  final UserModel user;

  LoginData({
    required this.token,
    required this.jwtToken,
    required this.refreshToken,
    required this.language,
    required this.isRegistered,
    required this.isAuthorised,
    required this.isActive,
    required this.user,
  });

  factory LoginData.fromJson(Map<String, dynamic> json) {
    return LoginData(
      token: json['token'] ?? '',
      jwtToken: json['JwtToken'] ?? '',
      refreshToken: json['RefreshToken'] ?? '',
      language: json['language'] ?? 'en',
      isRegistered: json['isRegistered'] ?? false,
      isAuthorised: json['isAuthorised'] ?? false,
      isActive: json['isActive'] ?? false,
      user: UserModel.fromJson(json['user'] ?? {}),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'token': token,
      'JwtToken': jwtToken,
      'RefreshToken': refreshToken,
      'language': language,
      'isRegistered': isRegistered,
      'isAuthorised': isAuthorised,
      'isActive': isActive,
      'user': user.toJson(),
    };
  }
}

class Store {
  final String firmCode;
  final String add1;
  final String add2;
  final String name;
  final bool primary;

  Store({required this.firmCode, required this.add1, required this.add2, required this.name, required this.primary});

  factory Store.fromJson(Map<String, dynamic> json) {
    return Store(
      firmCode: json['FirmCode']?.toString() ?? '',
      add1: json['Add1']?.toString() ?? '',
      add2: json['Add2']?.toString() ?? '',
      name: json['Name']?.toString() ?? '',
      primary: (json['primary'] == true) || (json['primary']?.toString() == '1') || (json['primary']?.toString().toLowerCase() == 'true'),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'FirmCode': firmCode,
      'Add1': add1,
      'Add2': add2,
      'Name': name,
      'primary': primary,
    };
  }

  factory Store.empty() => Store(firmCode: '', add1: '', add2: '', name: '', primary: false);
}
