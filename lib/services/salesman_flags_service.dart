import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:dio/dio.dart';
import 'dart:async';
import '../models/salesman_flags_model.dart';
import '../auth_service.dart';

class SalesmanFlagsService with ChangeNotifier {
  static const String baseUrl = 'http://mobileappsandbox.reckonsales.com:8080/reckon-biz/api/reckonpwsorder';
  static const String _storageKey = 'salesman_flags';
  static const String tenantId = '456';

  final FlutterSecureStorage _storage = const FlutterSecureStorage();
  final Dio _dio = Dio();

  SalesmanFlags? _flags;
  bool _isLoading = false;
  String? _error;

  SalesmanFlags? get flags => _flags;
  bool get isLoading => _isLoading;
  String? get error => _error;

  SalesmanFlagsService() {
    // Use Vercel proxy for web, direct URL for mobile
    final apiUrl = kIsWeb ? '/reckon-biz/api/reckonpwsorder' : baseUrl;
    _dio.options.baseUrl = apiUrl;
    _dio.options.connectTimeout = const Duration(seconds: 30);
    _dio.options.receiveTimeout = const Duration(seconds: 30);
  }

  /// Fetch salesman flags from API and cache them
  Future<bool> fetchAndCacheSalesmanFlags({
    required AuthService authService,
    required String packageName,
  }) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      final authHeader = authService.getAuthHeader();
      if (authHeader == null || authHeader.isEmpty) {
        _error = 'Authentication required. Please login again.';
        _isLoading = false;
        notifyListeners();
        return false;
      }

      debugPrint('[SalesmanFlagsService] Fetching salesman flags...');

      final response = await _dio.get(
        '/GetSalesmanFlags',
        queryParameters: {
          'tenantId': tenantId,
        },
        options: Options(
          headers: {
            'Accept': 'application/json',
            'package_name': packageName,
            'Authorization': authHeader,
          },
        ),
      );

      debugPrint('[SalesmanFlagsService] Response status: ${response.statusCode}');
      debugPrint('[SalesmanFlagsService] Response: ${response.data}');

      if (response.statusCode == 200) {
        final jsonData = response.data;
        debugPrint('[SalesmanFlagsService] === API RESPONSE ===');
        debugPrint('[SalesmanFlagsService] Response JSON: $jsonData');

        if (jsonData is Map<String, dynamic> && jsonData['success'] == true) {
          final data = jsonData['data'];
          if (data is Map<String, dynamic>) {
            _flags = SalesmanFlags.fromJson(data);

            // Cache to secure storage
            await _cacheFlags(_flags!);

            // Log saved variables in storage
            _logStoredData();

            _isLoading = false;
            notifyListeners();

            debugPrint('[SalesmanFlagsService] ✅ Salesman flags fetched and cached successfully');
            debugPrint('[SalesmanFlagsService] === FLAGS OBJECT ===');
            debugPrint('[SalesmanFlagsService] $_flags');
            return true;
          }
        }
      }

      _error = 'Failed to fetch salesman flags';
      _isLoading = false;
      notifyListeners();
      return false;
    } on DioException catch (e) {
      _error = 'Network error: ${e.message}';
      debugPrint('[SalesmanFlagsService] ❌ DioException: ${e.message}');
      _isLoading = false;
      notifyListeners();
      return false;
    } catch (e) {
      _error = 'Error: $e';
      debugPrint('[SalesmanFlagsService] ❌ Exception: $e');
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Cache flags to secure storage
  Future<void> _cacheFlags(SalesmanFlags flags) async {
    try {
      await _storage.write(
        key: _storageKey,
        value: flags.toJsonString(),
      );
      debugPrint('[SalesmanFlagsService] Flags cached successfully');
    } catch (e) {
      debugPrint('[SalesmanFlagsService] Failed to cache flags: $e');
    }
  }

  /// Log stored data from secure storage
  Future<void> _logStoredData() async {
    try {
      final cachedJson = await _storage.read(key: _storageKey);
      debugPrint('[SalesmanFlagsService] === STORED DATA IN SECURE STORAGE ===');
      if (cachedJson != null && cachedJson.isNotEmpty) {
        debugPrint('[SalesmanFlagsService] Storage Key: $_storageKey');
        debugPrint('[SalesmanFlagsService] Stored JSON String:');
        debugPrint('[SalesmanFlagsService] $cachedJson');

        // Parse and log individual fields
        try {
          final parsed = SalesmanFlags.fromJsonString(cachedJson);
          debugPrint('[SalesmanFlagsService] === PARSED STORED FLAGS ===');
          debugPrint('[SalesmanFlagsService] tenantId: ${parsed.tenantId}');
          debugPrint('[SalesmanFlagsService] tenantName: ${parsed.tenantName}');
          debugPrint('[SalesmanFlagsService] negativeStock: ${parsed.negativeStock}');
          debugPrint('[SalesmanFlagsService] includeTax: ${parsed.includeTax}');
          debugPrint('[SalesmanFlagsService] minOrderValueSalesMan: ${parsed.minOrderValueSalesMan}');
          debugPrint('[SalesmanFlagsService] enableScreenshot: ${parsed.enableScreenshot}');
          debugPrint('[SalesmanFlagsService] showStockSalesMan: ${parsed.showStockSalesMan}');
          debugPrint('[SalesmanFlagsService] showlocationSalesman: ${parsed.showlocationSalesman}');
          debugPrint('[SalesmanFlagsService] showRateSalesMan: ${parsed.showRateSalesMan}');
          debugPrint('[SalesmanFlagsService] showMrpSalesMan: ${parsed.showMrpSalesMan}');
          debugPrint('[SalesmanFlagsService] enablePriceSalesMan: ${parsed.enablePriceSalesMan}');
          debugPrint('[SalesmanFlagsService] showdisc1perSalesman: ${parsed.showdisc1perSalesman}');
          debugPrint('[SalesmanFlagsService] showDiscPerSalesMan: ${parsed.showDiscPerSalesMan}');
          debugPrint('[SalesmanFlagsService] showDiscPcsSalesMan: ${parsed.showDiscPcsSalesMan}');
          debugPrint('[SalesmanFlagsService] showSchemeSalesMan: ${parsed.showSchemeSalesMan}');
          debugPrint('[SalesmanFlagsService] showFreeQtySalesMan: ${parsed.showFreeQtySalesMan}');
          debugPrint('[SalesmanFlagsService] showManualSchemeSalesMan: ${parsed.showManualSchemeSalesMan}');
          debugPrint('[SalesmanFlagsService] showIncreaseDecreaseButtonSalesMan: ${parsed.showIncreaseDecreaseButtonSalesMan}');
          debugPrint('[SalesmanFlagsService] showadddetailsbottomsheetSalesMan: ${parsed.showadddetailsbottomsheetSalesMan}');
          debugPrint('[SalesmanFlagsService] showProductDescSalesMan: ${parsed.showProductDescSalesMan}');
          debugPrint('[SalesmanFlagsService] showItemRemarkSalesMan: ${parsed.showItemRemarkSalesMan}');
          debugPrint('[SalesmanFlagsService] showItemRefNumberSalesMan: ${parsed.showItemRefNumberSalesMan}');
          debugPrint('[SalesmanFlagsService] showItemCompositionSalesMan: ${parsed.showItemCompositionSalesMan}');
          debugPrint('[SalesmanFlagsService] showItemMfgCompSalesMan: ${parsed.showItemMfgCompSalesMan}');
          debugPrint('[SalesmanFlagsService] showitemCategorySalesMan: ${parsed.showitemCategorySalesMan}');
          debugPrint('[SalesmanFlagsService] searchfieldlistSalesman: ${parsed.searchfieldlistSalesman}');
          debugPrint('[SalesmanFlagsService] === END STORED FLAGS ===');
        } catch (parseError) {
          debugPrint('[SalesmanFlagsService] Error parsing stored flags: $parseError');
        }
      } else {
        debugPrint('[SalesmanFlagsService] No stored data found for key: $_storageKey');
      }
    } catch (e) {
      debugPrint('[SalesmanFlagsService] Error reading from storage: $e');
    }
  }

  /// Load flags from cache
  Future<void> loadCachedFlags() async {
    try {
      debugPrint('[SalesmanFlagsService] === LOADING CACHED FLAGS ===');
      final cachedJson = await _storage.read(key: _storageKey);

      if (cachedJson != null && cachedJson.isNotEmpty) {
        debugPrint('[SalesmanFlagsService] Cached data found for key: $_storageKey');
        debugPrint('[SalesmanFlagsService] Cached JSON:');
        debugPrint('[SalesmanFlagsService] $cachedJson');

        _flags = SalesmanFlags.fromJsonString(cachedJson);
        debugPrint('[SalesmanFlagsService] ✅ Flags loaded from cache successfully');
        debugPrint('[SalesmanFlagsService] === LOADED FLAGS DETAILS ===');
        debugPrint('[SalesmanFlagsService] tenantId: ${_flags?.tenantId}');
        debugPrint('[SalesmanFlagsService] tenantName: ${_flags?.tenantName}');
        debugPrint('[SalesmanFlagsService] negativeStock: ${_flags?.negativeStock}');
        debugPrint('[SalesmanFlagsService] includeTax: ${_flags?.includeTax}');
        debugPrint('[SalesmanFlagsService] minOrderValueSalesMan: ${_flags?.minOrderValueSalesMan}');
        debugPrint('[SalesmanFlagsService] enableScreenshot: ${_flags?.enableScreenshot}');
        debugPrint('[SalesmanFlagsService] showStockSalesMan: ${_flags?.showStockSalesMan}');
        debugPrint('[SalesmanFlagsService] showlocationSalesman: ${_flags?.showlocationSalesman}');
        debugPrint('[SalesmanFlagsService] showRateSalesMan: ${_flags?.showRateSalesMan}');
        debugPrint('[SalesmanFlagsService] showMrpSalesMan: ${_flags?.showMrpSalesMan}');
        debugPrint('[SalesmanFlagsService] enablePriceSalesMan: ${_flags?.enablePriceSalesMan}');
        debugPrint('[SalesmanFlagsService] showdisc1perSalesman: ${_flags?.showdisc1perSalesman}');
        debugPrint('[SalesmanFlagsService] showDiscPerSalesMan: ${_flags?.showDiscPerSalesMan}');
        debugPrint('[SalesmanFlagsService] showDiscPcsSalesMan: ${_flags?.showDiscPcsSalesMan}');
        debugPrint('[SalesmanFlagsService] showSchemeSalesMan: ${_flags?.showSchemeSalesMan}');
        debugPrint('[SalesmanFlagsService] showFreeQtySalesMan: ${_flags?.showFreeQtySalesMan}');
        debugPrint('[SalesmanFlagsService] showManualSchemeSalesMan: ${_flags?.showManualSchemeSalesMan}');
        debugPrint('[SalesmanFlagsService] showIncreaseDecreaseButtonSalesMan: ${_flags?.showIncreaseDecreaseButtonSalesMan}');
        debugPrint('[SalesmanFlagsService] showadddetailsbottomsheetSalesMan: ${_flags?.showadddetailsbottomsheetSalesMan}');
        debugPrint('[SalesmanFlagsService] showProductDescSalesMan: ${_flags?.showProductDescSalesMan}');
        debugPrint('[SalesmanFlagsService] showItemRemarkSalesMan: ${_flags?.showItemRemarkSalesMan}');
        debugPrint('[SalesmanFlagsService] showItemRefNumberSalesMan: ${_flags?.showItemRefNumberSalesMan}');
        debugPrint('[SalesmanFlagsService] showItemCompositionSalesMan: ${_flags?.showItemCompositionSalesMan}');
        debugPrint('[SalesmanFlagsService] showItemMfgCompSalesMan: ${_flags?.showItemMfgCompSalesMan}');
        debugPrint('[SalesmanFlagsService] showitemCategorySalesMan: ${_flags?.showitemCategorySalesMan}');
        debugPrint('[SalesmanFlagsService] searchfieldlistSalesman: ${_flags?.searchfieldlistSalesman}');
        debugPrint('[SalesmanFlagsService] === END LOADED FLAGS ===');

        notifyListeners();
        return;
      } else {
        debugPrint('[SalesmanFlagsService] ⚠️ No cached data found for key: $_storageKey');
      }
    } catch (e) {
      debugPrint('[SalesmanFlagsService] ❌ Error loading cached flags: $e');
    }
    _flags = null;
  }

  /// Clear cached flags
  Future<void> clearCachedFlags() async {
    try {
      await _storage.delete(key: _storageKey);
      _flags = null;
      debugPrint('[SalesmanFlagsService] Cached flags cleared');
      notifyListeners();
    } catch (e) {
      debugPrint('[SalesmanFlagsService] Failed to clear cached flags: $e');
    }
  }

  /// Check if a specific flag is enabled
  bool isFlagEnabled(bool Function(SalesmanFlags) flagGetter) {
    if (_flags == null) return false;
    return flagGetter(_flags!);
  }
}

