// filepath: /Users/hrishikeshprateek/AndroidStudioProjects/reckon_seller_2_0/lib/auth_service.dart
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:dio/dio.dart';
import 'dart:async';
import 'dart:convert';
import 'models/user_model.dart';
import 'app_navigator.dart';
import 'pages/mpin_entry_page.dart';

class AuthService with ChangeNotifier {
  // API configuration
  // Updated base URL (new API host + path)
  static const String baseUrl = 'http://mobileappsandbox.reckonsales.com:8080/reckon-biz/api/reckonpwsorder';
  static const String tenantId = 'com.reckon.reckonbiz';
  // Updated API header package name
  static const String packageName = 'com.reckon.reckonbiz';

  final FlutterSecureStorage _storage = const FlutterSecureStorage();
  final Dio _dio = Dio();

  // package name used in API header
  String get packageNameHeader => packageName;


  Completer<void>? _autoLoginCompleter;

  String? _accessToken;
  String? _jwtToken;
  String? _refreshToken;
  UserModel? _currentUser;

  String? get accessToken => _accessToken;
  String? get jwtToken => _jwtToken;
  // Expose refresh token safely for diagnostic use
  String? get refreshToken => _refreshToken;

  // Public getter to expose the current logged-in user (used across UI pages)
  // Added to fix references like `auth.currentUser` from UI code.
  UserModel? get currentUser => _currentUser;

  // Whether user is considered authenticated (used by UI to decide home/login)
  bool get isAuthenticated {
    if (_accessToken != null && _accessToken!.isNotEmpty) return true;
    if (_jwtToken != null && _jwtToken!.isNotEmpty) return true;
    if (_currentUser != null) return true;
    return false;
  }

  AuthService() {
    _dio.options.baseUrl = baseUrl;
    _dio.options.connectTimeout = const Duration(seconds: 30);
    _dio.options.receiveTimeout = const Duration(seconds: 30);

    // Add interceptor to handle 401 errors globally
    _dio.interceptors.add(
      InterceptorsWrapper(
        onError: (DioException error, ErrorInterceptorHandler handler) async {
          if (error.response?.statusCode == 401) {
            debugPrint('[AuthService] 401 detected, attempting MPIN validation and token refresh');

            // Try to refresh token via MPIN
            final success = await _handleUnauthorized();

            if (success && error.requestOptions.extra['retry'] != true) {
              // Mark this request as retried to avoid infinite loops
              error.requestOptions.extra['retry'] = true;

              // Retry the original request with new token
              try {
                final response = await _dio.fetch(error.requestOptions);
                return handler.resolve(response);
              } catch (e) {
                return handler.next(error);
              }
            }
          }
          return handler.next(error);
        },
      ),
    );
  }

  /// Handle 401 unauthorized by showing MPIN entry and refreshing token
  Future<bool> _handleUnauthorized() async {
    final navigator = appNavigatorKey.currentState;
    if (navigator == null || _currentUser == null) return false;

    try {
      // Show MPIN entry page
      final result = await navigator.push<dynamic>(
        MaterialPageRoute(
          builder: (_) => MpinEntryPage(
            mobile: _currentUser!.mobileNumber,
            allowCancel: false,
          ),
        ),
      );

      // Check if MPIN was validated
      if (result is Map && result['success'] == true) {
        // Now refresh the token
        final refreshResult = await refreshAccessToken();

        if (refreshResult['success'] == true) {
          debugPrint('[AuthService] Token refreshed successfully after MPIN validation');
          return true;
        } else {
          debugPrint('[AuthService] Token refresh failed: ${refreshResult['message']}');
        }
      }
    } catch (e) {
      debugPrint('[AuthService] Error handling 401: $e');
    }

    return false;
  }

  // Helper to ensure response data is a Map<String, dynamic>
  Map<String, dynamic> _normalizeResponse(dynamic raw) {
    if (raw is Map<String, dynamic>) return raw;
    if (raw is String) {
      try {
        final decoded = jsonDecode(raw);
        if (decoded is Map<String, dynamic>) return decoded;
        return {'Message': raw};
      } catch (_) {
        return {'Message': raw};
      }
    }
    if (raw == null) return {'Message': 'Empty response'};
    try {
      final decoded = jsonDecode(jsonEncode(raw));
      if (decoded is Map<String, dynamic>) return decoded;
      return {'Message': decoded.toString()};
    } catch (_) {
      return {'Message': 'Unknown response format'};
    }
  }

  // Get device info (you can enhance this with device_info_plus package)
  String get deviceId => '14319366a2e9f11';
  String get deviceName => 'unknown Android Android SDK built for arm64';

  /// Validate license / login using the new ValidateLicense API
  Future<Map<String, dynamic>> validateLicense({
    required String licenseNumber,
    required String mobile,
    required String password,
    String countryCode = '91',
    String apkName = 'com.reckon.reckonbiz',
    String appRole = 'SalesMan',
    int vCode = 31,
    String versionName = '1.7.23',
    String lRole = 'SalesMan',
  }) async {
    try {
      final payload = {
        'lApkName': apkName,
        'LicNo': licenseNumber,
        'MobileNo': mobile,
        'Password': password,
        'CountryCode': countryCode,
        'app_role': appRole,
        'LoginDeviceId': deviceId,
        'device_name': deviceName,
        'v_code': vCode,
        'version_name': versionName,
        'lRole': lRole,
      };

      final response = await _dio.post(
        '/ValidateLicense',
        data: payload,
        options: Options(
          headers: {
            'Content-Type': 'application/json',
            'package_name': packageNameHeader,
          },
        ),
      );

      // Robust parsing: response.data may be Map, String, or other.
      dynamic raw = response.data;
      debugPrint('[AuthService] Raw response from API: $raw');
      debugPrint('[AuthService] Raw response type: ${raw.runtimeType}');

      Map<String, dynamic> data;
      if (raw is Map<String, dynamic>) {
        data = raw;
        debugPrint('[AuthService] Response is already a Map');
      } else if (raw is String) {
        try {
          final decoded = jsonDecode(raw);
          if (decoded is Map<String, dynamic>) {
            data = decoded;
            debugPrint('[AuthService] Response was String, decoded to Map');
          } else {
            data = {'Message': raw};
            debugPrint('[AuthService] Response was String, but not valid JSON');
          }
        } catch (_) {
          // not JSON, store raw string in Message
          data = {'Message': raw};
          debugPrint('[AuthService] Response was String, but JSON decode failed');
        }
      } else if (raw == null) {
        data = {'Message': 'Empty response'};
        debugPrint('[AuthService] Response was null');
      } else {
        // try to convert to Map via jsonEncode -> decode
        try {
          final decoded = jsonDecode(jsonEncode(raw));
          if (decoded is Map<String, dynamic>) {
            data = decoded;
            debugPrint('[AuthService] Response was other type, converted to Map');
          } else {
            data = {'Message': decoded.toString()};
            debugPrint('[AuthService] Response was other type, converted but not Map');
          }
        } catch (_) {
          data = {'Message': 'Unknown response format'};
          debugPrint('[AuthService] Response was other type, conversion failed');
        }
      }

      debugPrint('[AuthService] Final parsed data: $data');

      // Check if user needs to create password or MPIN FIRST - before checking Status
      debugPrint('[AuthService] ===== FLAG DETECTION START =====');
      debugPrint('[AuthService] Raw data: $data');
      debugPrint('[AuthService] data["CreatePasswd"] = ${data['CreatePasswd']}');
      debugPrint('[AuthService] data["CreatePasswd"] type = ${data['CreatePasswd']?.runtimeType}');
      debugPrint('[AuthService] data["CreateMPin"] = ${data['CreateMPin']}');
      debugPrint('[AuthService] data["CreateMPin"] type = ${data['CreateMPin']?.runtimeType}');
      debugPrint('[AuthService] data["Status"] = ${data['Status']}');
      debugPrint('[AuthService] data["Status"] type = ${data['Status']?.runtimeType}');

      // BULLETPROOF flag detection - handle all possible cases
      bool needsCreatePass = false;
      bool needsCreateMPin = false;

      // Check CreatePasswd
      final cpValue = data['CreatePasswd'];
      if (cpValue == true) {
        needsCreatePass = true;
        debugPrint('[AuthService] CreatePasswd detected: == true');
      } else if (cpValue is bool && cpValue) {
        needsCreatePass = true;
        debugPrint('[AuthService] CreatePasswd detected: bool && cpValue');
      } else if (cpValue?.toString().toLowerCase() == 'true') {
        needsCreatePass = true;
        debugPrint('[AuthService] CreatePasswd detected: string "true"');
      } else if (cpValue?.toString() == '1') {
        needsCreatePass = true;
        debugPrint('[AuthService] CreatePasswd detected: string "1"');
      }

      // Check CreateMPin
      final cmValue = data['CreateMPin'];
      if (cmValue == true) {
        needsCreateMPin = true;
        debugPrint('[AuthService] CreateMPin detected: == true');
      } else if (cmValue is bool && cmValue) {
        needsCreateMPin = true;
        debugPrint('[AuthService] CreateMPin detected: bool && cmValue');
      } else if (cmValue?.toString().toLowerCase() == 'true') {
        needsCreateMPin = true;
        debugPrint('[AuthService] CreateMPin detected: string "true"');
      } else if (cmValue?.toString() == '1') {
        needsCreateMPin = true;
        debugPrint('[AuthService] CreateMPin detected: string "1"');
      }

      debugPrint('[AuthService] FINAL: needsCreatePass = $needsCreatePass');
      debugPrint('[AuthService] FINAL: needsCreateMPin = $needsCreateMPin');
      debugPrint('[AuthService] ===== FLAG DETECTION END =====');

      // If user needs to create password or MPIN, return success even if Status is false
      // This allows UI to navigate to password/mpin creation screens
      debugPrint('[AuthService] CHECKPOINT 1: About to check if needsCreatePass || needsCreateMPin');
      debugPrint('[AuthService] CHECKPOINT 1: needsCreatePass=$needsCreatePass, needsCreateMPin=$needsCreateMPin');

      if (needsCreatePass || needsCreateMPin) {
        debugPrint('[AuthService] CHECKPOINT 2: ENTERED THE IF BLOCK - Will return success');
        debugPrint('[AuthService] User needs to create password/mpin. CreatePasswd=$needsCreatePass, CreateMPin=$needsCreateMPin');
        final returnValue = {
          'success': true,
          'message': data['Message'] ?? 'Please create password/MPIN',
          'data': data,
          'raw': raw,
        };
        debugPrint('[AuthService] CHECKPOINT 3: RETURNING SUCCESS with data containing CreatePasswd');
        debugPrint('[AuthService] Return value success: ${returnValue['success']}');
        return returnValue;
      }

      debugPrint('[AuthService] CHECKPOINT 4: DID NOT ENTER CreatePasswd block, continuing to Status check');

      // If backend explicitly returned Status: false (and no password/mpin needed), treat as failure
      if (data.containsKey('Status') && (data['Status'] == false || data['Status']?.toString().toLowerCase() == 'false')) {
        return {
          'success': false,
          'message': data['Message'] ?? data['message'] ?? 'Login failed (Status false)',
          'data': data,
          'raw': raw,
        };
      }

      // If API returns AccessToken, consider it successful login
      final hasAccessToken = (data['AccessToken'] != null && data['AccessToken'].toString().isNotEmpty);
      final statusTrue = data['Status'] == true || (data['Status']?.toString().toLowerCase() == 'true');

      if (hasAccessToken || statusTrue) {
        // Only persist tokens if user doesn't need to create password/mpin
        if (!needsCreatePass && !needsCreateMPin) {
          _accessToken = data['AccessToken']?.toString();
          // Some APIs return only AccessToken - use it as jwt token for Authorization header
          _jwtToken = _accessToken;

          // Map profile to our UserModel (Profile may be null)
          final profileRaw = data['Profile'];
          Map<String, dynamic>? profile;
          if (profileRaw is Map<String, dynamic>) {
            profile = profileRaw;
          } else if (profileRaw is String) {
            try {
              final p = jsonDecode(profileRaw);
              if (p is Map<String, dynamic>) profile = p;
            } catch (_) {}
          }
          if (profile != null) {
            _currentUser = UserModel.fromProfileJson(profile, licenseNumber: licenseNumber);
          }

          // Persist
          if (_accessToken != null) await _storage.write(key: 'access_token', value: _accessToken);
          if (_jwtToken != null) await _storage.write(key: 'jwt_token', value: _jwtToken);
          if (_currentUser != null) await _storage.write(key: 'user_data', value: jsonEncode(_currentUser!.toJson()));

          notifyListeners();
        }

        return {
          'success': true,
          'message': data['Message'] ?? 'Login successful',
          'data': data,
        };
      }

      return {
        'success': false,
        'message': data['Message'] ?? 'Login failed',
        'data': data,
      };
    } on DioException catch (e) {
      return {
        'success': false,
        // try to get a useful message from error response
        'message': e.response?.data is Map ? (e.response?.data['Message'] ?? e.response?.data['message']) : (e.response?.data?.toString() ?? e.message ?? 'Network error'),
        'data': null,
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'An unexpected error occurred: ${e.toString()}',
        'data': null,
      };
    }
  }

  /// Send OTP to mobile number
  Future<Map<String, dynamic>> sendOTP({
    required String mobile,
    required String licenseNumber,
    String countryCode = '91',
  }) async {
    try {
      final response = await _dio.post(
        '/login/otp',
        data: {
          'mobile': mobile,
          'license_number': licenseNumber,
          'country_code': countryCode,
        },
        options: Options(
          headers: {
            'X-Tenant-Id': tenantId,
            'Content-Type': 'application/json',
            'package_name': packageNameHeader,
            'device_id': deviceId,
            'device_name': deviceName,
          },
        ),
      );

      final data = _normalizeResponse(response.data);
      // If backend explicitly returned Status: false, treat as failure
      if (data.containsKey('Status') && (data['Status'] == false || data['Status']?.toString().toLowerCase() == 'false')) {
        return {
          'success': false,
          'message': data['Message'] ?? data['message'] ?? 'Operation failed (Status false)',
          'data': data,
          'raw': response.data,
        };
      }
      return {
        'success': data['success'] == true || data['success']?.toString() == '1',
        'message': data['message'] ?? data['Message'] ?? 'Unknown error',
        'data': data,
        'raw': response.data,
      };
    } on DioException catch (e) {
      return {
        'success': false,
        'message': e.response?.data is Map ? (e.response?.data['message'] ?? e.response?.data['Message']) : (e.response?.data?.toString() ?? e.message ?? 'Network error'),
        'data': null,
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'An unexpected error occurred: ${e.toString()}',
        'data': null,
      };
    }
  }

  /// Verify OTP and login
  Future<Map<String, dynamic>> verifyOTP({
    required String mobile,
    required String licenseNumber,
    required String otp,
    String countryCode = '91',
  }) async {
    try {
      final response = await _dio.post(
        '/login/verify',
        data: {
          'mobile': mobile,
          'license_number': licenseNumber,
          'country_code': countryCode,
          'otp': otp,
        },
        options: Options(
          headers: {
            'Content-Type': 'application/json',
            'package_name': packageNameHeader,
            'device_id': deviceId,
            'device_name': deviceName,
          },
        ),
      );

      final data = _normalizeResponse(response.data);
      // If backend explicitly returned Status: false, treat as failure
      if (data.containsKey('Status') && (data['Status'] == false || data['Status']?.toString().toLowerCase() == 'false')) {
        return {
          'success': false,
          'message': data['Message'] ?? data['message'] ?? 'Operation failed (Status false)',
          'data': data,
          'raw': response.data,
        };
      }
      if (data['success'] == true || data['success']?.toString() == '1') {
        // Attempt to read nested 'data' field which may hold tokens
        final nested = data['data'];
        if (nested is Map<String, dynamic>) {
          try {
            final loginResponse = LoginResponse.fromJson({'success': true, 'message': data['message'] ?? '', 'rs': data['rs'] ?? 0, 'data': nested});
            if (loginResponse.data != null) {
              _accessToken = loginResponse.data!.token;
              _jwtToken = loginResponse.data!.jwtToken;
              _refreshToken = loginResponse.data!.refreshToken;
              _currentUser = loginResponse.data!.user;

              await _storage.write(key: 'access_token', value: _accessToken);
              await _storage.write(key: 'jwt_token', value: _jwtToken);
              await _storage.write(key: 'refresh_token', value: _refreshToken);
              await _storage.write(key: 'user_data', value: jsonEncode(_currentUser!.toJson()));

              notifyListeners();
            }
            return {'success': true, 'message': data['message'] ?? 'Login successful', 'data': nested, 'raw': response.data};
          } catch (_) {
            return {'success': true, 'message': data['message'] ?? 'Success', 'data': data, 'raw': response.data};
          }
        }
        return {'success': true, 'message': data['message'] ?? 'Success', 'data': data, 'raw': response.data};
      }

      return {'success': false, 'message': data['message'] ?? data['Message'] ?? 'Verification failed', 'data': data, 'raw': response.data};
    } on DioException catch (e) {
      return {
        'success': false,
        'message': e.response?.data['message'] ?? e.message ?? 'Network error',
        'data': null,
        'raw': e.response?.data,
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'An unexpected error occurred: ${e.toString()}',
        'data': null,
        'raw': null,
      };
    }
  }

  /// Validate mobile OTP endpoint (new API)
  Future<Map<String, dynamic>> validateMobileOTP({
    required String mobile,
    required String otp,
    String countryCode = '91',
  }) async {
    try {
      final response = await _dio.post(
        '/ValidateMobileOTP',
        data: {
          'MobileNo': mobile,
          'OTP': otp,
          'CountryCode': countryCode,
        },
        options: Options(
          headers: {
            'Content-Type': 'application/json',
            'package_name': packageNameHeader,
            if (getAuthHeader() != null) 'Authorization': getAuthHeader(),
          },
        ),
      );

      final data = _normalizeResponse(response.data);
      // If backend explicitly returned Status: false, treat as failure
      if (data.containsKey('Status') && (data['Status'] == false || data['Status']?.toString().toLowerCase() == 'false')) {
        return {
          'success': false,
          'message': data['Message'] ?? data['message'] ?? 'Operation failed (Status false)',
          'data': data,
          'raw': response.data,
        };
      }
      // If API returns AccessToken, treat as successful and persist
      final hasAccessToken = (data['AccessToken'] != null && data['AccessToken'].toString().isNotEmpty);
      final statusTrue = data['Status'] == true || (data['Status']?.toString().toLowerCase() == 'true');
      if (hasAccessToken || statusTrue) {
        _accessToken = data['AccessToken']?.toString();
        _jwtToken = _accessToken;
        final profile = data['Profile'] is Map<String, dynamic> ? data['Profile'] as Map<String, dynamic> : null;
        if (profile != null) _currentUser = UserModel.fromProfileJson(profile);
        if (_accessToken != null) await _storage.write(key: 'access_token', value: _accessToken);
        if (_jwtToken != null) await _storage.write(key: 'jwt_token', value: _jwtToken);
        if (_currentUser != null) await _storage.write(key: 'user_data', value: jsonEncode(_currentUser!.toJson()));
        notifyListeners();
        return {'success': true, 'message': data['Message'] ?? 'OTP Verified', 'data': data, 'raw': response.data};
      }

      return {'success': false, 'message': data['Message'] ?? data['message'] ?? 'OTP verification failed', 'data': data, 'raw': response.data};
    } on DioException catch (e) {
      return {'success': false, 'message': e.response?.data?.toString() ?? e.message ?? 'Network error', 'data': null};
    } catch (e) {
      return {'success': false, 'message': 'An unexpected error occurred: ${e.toString()}', 'data': null};
    }
  }

  /// Create or set user password
  /// Uses endpoint POST /forgotpassword with payload: { licNo, countryCode, password }
  Future<Map<String, dynamic>> createPassword({
    required String mobile,
    required String password,
    String countryCode = '91',
    String? licenseNumber,
  }) async {
    try {
      // The backend expects the user's mobile number in licNo (per API examples).
      // Prefer `mobile` here; fallback to licenseNumber only if mobile is empty.
      String lic = (mobile.isNotEmpty) ? mobile : (licenseNumber ?? '');
      // Normalize: keep digits only and use last 10 digits if longer
      lic = lic.replaceAll(RegExp(r'[^0-9]'), '');
      if (lic.length > 10) lic = lic.substring(lic.length - 10);

      final payload = {
        'licNo': lic,
        'countryCode': countryCode,
        'password': password,
      };

      debugPrint('[AuthService.createPassword] payload: $payload');

      final response = await _dio.post(
        '/forgotpassword',
        data: payload,
        options: Options(
          headers: {
            'Content-Type': 'application/json',
            'package_name': packageNameHeader,
            // Note: curl example does not include Authorization; omit it here for parity.
          },
          contentType: Headers.jsonContentType,
        ),
      );

      debugPrint('[AuthService.createPassword] raw response: ${response.data}');

      final data = _normalizeResponse(response.data);
      final success = data['success'] == true || data['Status'] == true || (data['status']?.toString().toLowerCase() == 'true');
      return {
        'success': success,
        'message': data['message'] ?? data['Message'] ?? (success ? 'Password created' : 'Failed to create password'),
        'data': data,
        'raw': response.data,
      };
    } on DioException catch (e) {
      return {
        'success': false,
        'message': e.response?.data?.toString() ?? e.message ?? 'Network error',
        'data': null,
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'An unexpected error occurred: ${e.toString()}',
        'data': null,
      };
    }
  }

  /// Create / set MPIN (6-digit) - uses new endpoint '/saveMpin'
  Future<Map<String, dynamic>> createMPin({
    required String mobile,
    required String mpin,
    String countryCode = '91',
    String? licenseNumber,
  }) async {
    try {
      final payload = {
        'mobileNo': mobile,
        'countryCode': countryCode,
        'mPin': mpin,
      };
      // licenseNumber not used by new endpoint but keep for compatibility

      final response = await _dio.post(
        '/saveMpin',
        data: payload,
        options: Options(headers: {
          'Content-Type': 'application/json',
          'package_name': packageNameHeader,
        }),
      );

      final data = _normalizeResponse(response.data);
      final success = data['success'] == true || data['Status'] == true || (data['status']?.toString().toLowerCase() == 'true');
      return {
        'success': success,
        'message': data['message'] ?? data['Message'] ?? (success ? 'MPIN created' : 'Failed to create MPIN'),
        'data': data,
        'raw': response.data,
      };
    } on DioException catch (e) {
      return {'success': false, 'message': e.response?.data?.toString() ?? e.message ?? 'Network error', 'data': null, 'raw': e.response?.data};
    } catch (e) {
      return {'success': false, 'message': 'An unexpected error occurred: ${e.toString()}', 'data': null, 'raw': null};
    }
  }

  /// Change MPIN API wrapper. Uses user's mobile number.
  Future<Map<String, dynamic>> changeMpin({String? mobile, required String oldMpin, required String newMpin, String countryCode = '91'}) async {
    try {
      String mob = mobile ?? _currentUser?.mobileNumber ?? '';
      if (mob.isEmpty) {
        return {'success': false, 'message': 'Mobile number not available', 'data': null};
      }

      // Normalize mobile number: strip non-digit chars and take last 10 digits
      mob = mob.replaceAll(RegExp(r'[^0-9]'), '');
      if (mob.length > 10) mob = mob.substring(mob.length - 10);

      final payload = {
        'mobileNo': mob,
        'countryCode': countryCode,
        'mPin': newMpin,
        'oldMpin': oldMpin,
      };

      final response = await _dio.post(
        '/forgetMpin',
        data: payload,
        options: Options(headers: {'Content-Type': 'application/json', 'package_name': packageNameHeader}),
      );

      final data = _normalizeResponse(response.data);
      final status = data['Status'];
      final success = (status == true) || (status?.toString().toLowerCase() == 'true');

      return {
        'success': success,
        'message': data['Message'] ?? data['message'] ?? (success ? 'MPIN changed' : 'Failed to change MPIN'),
        'data': data,
        'raw': response.data,
      };
    } on DioException catch (e) {
      return {
        'success': false,
        'message': e.response?.data is Map
            ? (e.response?.data['Message'] ?? e.response?.data['message'])
            : (e.response?.data?.toString() ?? e.message ?? 'Network error'),
        'data': null,
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'An unexpected error occurred: ${e.toString()}',
        'data': null,
      };
    }
  }

  /// Validate MPIN endpoint
  Future<Map<String, dynamic>> validateMpin({
    required String mobile,
    required String mpin,
    String countryCode = '91',
  }) async {
    try {
      final payload = {
        'mobileNo': mobile,
        'countryCode': countryCode,
        'mpin': mpin,
      };
      // Corrected endpoint name: /validateMpin
      final response = await _dio.post('/validateMpin', data: payload, options: Options(headers: {
        'Content-Type': 'application/json',
        'package_name': packageNameHeader,
        if (getAuthHeader() != null) 'Authorization': getAuthHeader(),
      }));
      final data = _normalizeResponse(response.data);
      return {
        'success': data['Status'] == true || data['status']?.toString() == 'true' || data['success'] == true,
        'message': data['Message'] ?? data['message'] ?? '',
        'data': data,
        'raw': response.data,
      };
    } on DioException catch (e) {
      return {'success': false, 'message': e.response?.data?.toString() ?? e.message ?? 'Network error', 'data': null, 'raw': e.response?.data, 'statusCode': e.response?.statusCode};
    } catch (e) {
      return {'success': false, 'message': 'Unexpected: ${e.toString()}', 'data': null, 'raw': null};
    }
  }

  /// Refresh Access Token using stored refresh token. Calls the absolute /refresh endpoint.
  Future<Map<String, dynamic>> refreshAccessToken() async {
    if (_refreshToken == null || _refreshToken!.isEmpty) {
      return {'success': false, 'message': 'No refresh token available'};
    }
    try {
      final refreshUrl = 'http://mobileappsandbox.reckonsales.com:8080/reckon-biz/api/refresh';
      final payload = {'refresh_token': _refreshToken};
      // Use a new Dio instance so baseUrl doesn't interfere
      final d = Dio();
      d.options.connectTimeout = const Duration(seconds: 30);
      d.options.receiveTimeout = const Duration(seconds: 30);

      // Attach current JWT if available
      final headers = {
        'Content-Type': 'application/json',
        'package_name': packageNameHeader,
        if (getAuthHeader() != null) 'Authorization': getAuthHeader(),
      };

      final response = await d.post(refreshUrl, data: payload, options: Options(headers: headers));
      final raw = response.data;
      final data = _normalizeResponse(raw);

      // API returns access_token and refresh_token keys (snake_case)
      final newAccess = data['access_token'] ?? data['AccessToken'] ?? data['accessToken'];
      final newRefresh = data['refresh_token'] ?? data['RefreshToken'] ?? data['refreshToken'];

      if (newAccess != null && newAccess.toString().isNotEmpty) {
        _accessToken = newAccess.toString();
        _jwtToken = _accessToken;
        if (newRefresh != null) _refreshToken = newRefresh.toString();

        await _storage.write(key: 'access_token', value: _accessToken);
        await _storage.write(key: 'jwt_token', value: _jwtToken);
        if (_refreshToken != null) await _storage.write(key: 'refresh_token', value: _refreshToken);

        notifyListeners();
        return {'success': true, 'data': data, 'message': data['message'] ?? 'Refreshed'};
      }

      return {'success': false, 'message': data['message'] ?? 'Failed to refresh token', 'data': data};
    } on DioException catch (e) {
      return {'success': false, 'message': e.response?.data?.toString() ?? e.message ?? 'Network error', 'data': null};
    } catch (e) {
      return {'success': false, 'message': 'Unexpected: ${e.toString()}', 'data': null};
    }
  }

  /// Show MPIN prompt (now pushes a full screen MPIN entry) and attempt to optionally refresh tokens. Returns true if validation (and optional refresh) succeeded.
  Future<bool> promptForMpinAndRefresh({required String mobile, String countryCode = '91', bool refreshOnSuccess = false}) async {
    final navigator = appNavigatorKey.currentState;
    if (navigator == null) return false;

    // Ensure mobile is normalized (digits only, last 10)
    var mob = mobile.replaceAll(RegExp(r'[^0-9]'), '');
    if (mob.length > 10) mob = mob.substring(mob.length - 10);

    final result = await navigator.push<dynamic>(MaterialPageRoute(builder: (_) => MpinEntryPage(mobile: mob, allowCancel: false)));

    // Handle both old boolean return and new map return
    bool mpinValid = false;
    String? validatedMpin;

    if (result is Map && result['success'] == true) {
      mpinValid = true;
      validatedMpin = result['mpin'] as String?;
    } else if (result == true) {
      mpinValid = true;
    }

    if (!mpinValid) return false;

    if (refreshOnSuccess) {
      // When token is expired and we need fresh tokens, use MPIN to login
      if (validatedMpin != null && validatedMpin.isNotEmpty) {
        final licNo = _currentUser?.licenseNumber;
        if (licNo != null) {
          // Do a fresh MPIN login to get new tokens
          final loginResult = await loginWithMpinOnly(
            mobile: mob,
            licenseNumber: licNo,
            mpin: validatedMpin,
            countryCode: countryCode,
          );
          return loginResult['success'] == true;
        }
      }

      // Fallback: try refresh token if available
      if (_refreshToken != null && _refreshToken!.isNotEmpty) {
        final r = await refreshAccessToken();
        return r['success'] == true;
      }

      return false;
    }

    return true;
  }

  /// Login with MPIN only (used when token expires and user validates MPIN)
  Future<Map<String, dynamic>> loginWithMpinOnly({
    required String mobile,
    required String licenseNumber,
    required String mpin,
    String countryCode = '91',
  }) async {
    try {
      final payload = {
        'mobileNo': mobile,
        'countryCode': countryCode,
        'licNo': licenseNumber,
        'mpin': mpin,
      };

      final response = await _dio.post('/loginWithMpin', data: payload, options: Options(headers: {
        'Content-Type': 'application/json',
        'package_name': packageNameHeader,
      }));

      final data = _normalizeResponse(response.data);

      if (data['Status'] == true || data['status']?.toString() == 'true' || data['success'] == true) {
        // Extract tokens
        _accessToken = data['access_token'] ?? data['accessToken'];
        _jwtToken = data['jwt_token'] ?? data['jwtToken'] ?? data['access_token'];
        _refreshToken = data['refresh_token'] ?? data['refreshToken'];

        // Save tokens
        if (_accessToken != null) await _storage.write(key: 'access_token', value: _accessToken);
        if (_jwtToken != null) await _storage.write(key: 'jwt_token', value: _jwtToken);
        if (_refreshToken != null) await _storage.write(key: 'refresh_token', value: _refreshToken);

        // Update user data if available
        if (_currentUser != null) {
          await _storage.write(key: 'user_data', value: jsonEncode(_currentUser!.toJson()));
        }

        notifyListeners();
        return {'success': true, 'message': 'Login successful', 'data': data};
      }

      return {
        'success': false,
        'message': data['Message'] ?? data['message'] ?? 'Login failed',
        'data': null,
      };
    } catch (e) {
      debugPrint('loginWithMpinOnly error: $e');
      return {'success': false, 'message': 'Login failed: ${e.toString()}'};
    }
  }

  /// Try auto login from stored tokens
  Future<void> tryAutoLogin() async {
    if (_autoLoginCompleter != null) {
      return _autoLoginCompleter!.future;
    }

    _autoLoginCompleter = Completer();

    try {
      if (await _storage.containsKey(key: 'access_token')) {
        _accessToken = await _storage.read(key: 'access_token');
        _jwtToken = await _storage.read(key: 'jwt_token');
        _refreshToken = await _storage.read(key: 'refresh_token');

        final userDataJson = await _storage.read(key: 'user_data');
        if (userDataJson != null) {
          _currentUser = UserModel.fromJson(jsonDecode(userDataJson));
        }

        notifyListeners();
      }
      _autoLoginCompleter!.complete();
    } catch (e) {
      _autoLoginCompleter!.completeError(e);
    }

    return _autoLoginCompleter!.future;
  }

  /// Logout user
  Future<void> logout() async {
    _accessToken = null;
    _jwtToken = null;
    _refreshToken = null;
    _currentUser = null;
    // Delete only authentication/session related keys, keep saved license/mobile for autofill
    final keysToRemove = ['access_token', 'jwt_token', 'refresh_token', 'user_data'];
    for (final k in keysToRemove) {
      try {
        await _storage.delete(key: k);
      } catch (_) {}
    }
    _autoLoginCompleter = null;
    notifyListeners();
  }

  /// Get JWT token for API calls
  String? getAuthHeader() {
    return _jwtToken != null ? 'Bearer $_jwtToken' : null;
  }

  /// Update password API wrapper. Uses user's mobile number as licNo by default.
  Future<Map<String, dynamic>> updatePassword({String? licNo, required String oldPassword, required String newPassword, String countryCode = '91'}) async {
    try {
      String lic = licNo ?? _currentUser?.mobileNumber ?? '';
      if (lic.isEmpty) {
        return {'success': false, 'message': 'Mobile number not available', 'data': null};
      }

      // Normalize mobile number: strip non-digit chars and take last 10 digits
      lic = lic.replaceAll(RegExp(r'[^0-9]'), '');
      if (lic.length > 10) lic = lic.substring(lic.length - 10);

      final payload = {
        'licNo': lic,
        'countryCode': countryCode,
        'password': newPassword,
        'oldPassword': oldPassword,
      };

      final response = await _dio.post(
        '/updatePassword',
        data: payload,
        options: Options(headers: {'Content-Type': 'application/json', 'package_name': packageNameHeader}),
      );

      final data = _normalizeResponse(response.data);
      final status = data['Status'];
      final success = (status == true) || (status?.toString().toLowerCase() == 'true');

      return {
        'success': success,
        'message': data['Message'] ?? data['message'] ?? (success ? 'Password updated' : 'Failed to update password'),
        'data': data,
        'raw': response.data,
      };
    } on DioException catch (e) {
      return {
        'success': false,
        'message': e.response?.data is Map
            ? (e.response?.data['Message'] ?? e.response?.data['message'])
            : (e.response?.data?.toString() ?? e.message ?? 'Network error'),
        'data': null,
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'An unexpected error occurred: ${e.toString()}',
        'data': null,
      };
    }
  }

  /// Get a Dio client configured with the 401 interceptor
  /// Use this in all API calls to automatically handle token expiration
  Dio getDioClient({String? customBaseUrl}) {
    final dio = Dio(BaseOptions(
      baseUrl: customBaseUrl ?? baseUrl,
      connectTimeout: const Duration(seconds: 30),
      receiveTimeout: const Duration(seconds: 30),
      responseType: ResponseType.plain,
    ));

    // Add the same 401 interceptor
    dio.interceptors.add(
      InterceptorsWrapper(
        onError: (DioException error, ErrorInterceptorHandler handler) async {
          if (error.response?.statusCode == 401) {
            debugPrint('[DioClient] 401 detected, attempting MPIN validation and token refresh');

            // Try to refresh token via MPIN
            final success = await _handleUnauthorized();

            if (success && error.requestOptions.extra['retry'] != true) {
              // Mark this request as retried to avoid infinite loops
              error.requestOptions.extra['retry'] = true;

              // Update the authorization header with new token
              if (getAuthHeader() != null) {
                error.requestOptions.headers['Authorization'] = getAuthHeader();
              }

              // Retry the original request with new token
              try {
                final response = await dio.fetch(error.requestOptions);
                return handler.resolve(response);
              } catch (e) {
                return handler.next(error);
              }
            }
          }
          return handler.next(error);
        },
      ),
    );

    return dio;
  }
}
