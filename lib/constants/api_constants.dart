/// API Constants - Centralized configuration for all API endpoints
class ApiConstants {
  // API Base Configuration
  static const String apiHost = 'https://mobileappsandbox.reckonsales.com:8443';
  static const String apiBasePath = '/reckon-biz/api';

  // API Endpoints
  static const String baseUrl = '$apiHost$apiBasePath/reckonpwsorder';
  static const String refreshUrl = '$apiHost$apiBasePath/refresh';
  static const String getReceiptDetailUrl = '$baseUrl/GetReceiptDetail';
  static const String getSalesmanFlagsUrl = '$baseUrl/GetSalesmanFlags';

  // Tenant Configuration
  static const String tenantId = 'com.reckon.reckonbiz';

  // API Headers
  static const String packageName = 'com.reckon.reckonbiz';
  static const String contentType = 'application/json';
}

