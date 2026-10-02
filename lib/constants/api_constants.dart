import 'package:flutter/foundation.dart' show kIsWeb;

/// API Constants - Centralized configuration for all API endpoints
class ApiConstants {
  // API Base Configuration
  static const String directHost = 'http://mobileappsandbox.reckonsales.com:8080';

  /// Optional same-origin proxy for web builds, supplied at compile time:
  ///   flutter run -d chrome --dart-define=API_PROXY=http://localhost:8010
  ///
  /// Only web honours it. The browser blocks the OTP endpoint outright because
  /// its custom headers (MobileNo, CountryCode, lApkName, GenerateOtp) are not
  /// in the server's Access-Control-Allow-Headers list, and blocks every call
  /// as mixed content when the page itself is served over HTTPS. Routing web
  /// traffic through a proxy sidesteps both. Mobile always talks direct.
  static const String webProxy = String.fromEnvironment('API_PROXY');

  static String get apiHost {
    if (!kIsWeb || webProxy.isEmpty) return directHost;
    // "/" means same origin: emit relative URLs like /reckon-biz/api/... so the
    // host that served the page proxies the call (Vercel rewrites, nginx, ...).
    // That avoids CORS entirely and sidesteps mixed-content blocking when the
    // page is HTTPS and the API is not.
    if (webProxy == '/') return '';
    return webProxy.endsWith('/')
        ? webProxy.substring(0, webProxy.length - 1)
        : webProxy;
  }

  static const String apiBasePath = '/reckon-biz/api';

  // API Endpoints
  static String get baseUrl => '$apiHost$apiBasePath/reckonpwsorder';
  static String get refreshUrl => '$apiHost$apiBasePath/refresh';
  static String get getReceiptDetailUrl => '$baseUrl/GetReceiptDetail';
  static String get getSalesmanFlagsUrl => '$baseUrl/GetSalesmanFlags';

  // Tenant Configuration.
  // Set once at startup (main.dart) to the real running package name so each
  // flavor (e.g. com.reckon.reckonbiz, com.reckon.amareorder) reports itself.
  static String tenantId = 'com.reckon.reckonbiz';

  // API Headers.
  // Set once at startup to the real running package name. NOT const.
  static String packageName = 'com.reckon.reckonbiz';
  static const String contentType = 'application/json';
}

