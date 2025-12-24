import 'package:dio/dio.dart';
import 'auth_service.dart';

class DashboardService {
  // Updated base URL to match new API host/path used by ValidateLicense
  static const String baseUrl = 'http://mobileappsandbox.reckonsales.com:8080/reckon-biz/api/reckonpwsorder';

  final Dio _dio;
  final AuthService authService;

  DashboardService(this.authService) : _dio = Dio() {
    _dio.options.baseUrl = baseUrl;
    _dio.options.connectTimeout = const Duration(seconds: 30);
    _dio.options.receiveTimeout = const Duration(seconds: 30);

    // Add interceptor to automatically add auth header
    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) {
        final authHeader = authService.getAuthHeader();
        if (authHeader != null) {
          options.headers['Authorization'] = authHeader;
        }
        // Use runtime package name provided by AuthService (reads package/bundle id at runtime)
        options.headers['package_name'] = authService.packageNameHeader;
        return handler.next(options);
      },
      onError: (error, handler) async {
        // Handle 401 errors - token expired
        if (error.response?.statusCode == 401) {
          try {
            // Try to get mobile from current user and normalize to last 10 digits
            String? mobile = authService.currentUser?.mobileNumber;
            if (mobile != null) {
              // strip non-digit chars
              mobile = mobile.replaceAll(RegExp(r'[^0-9]'), '');
              if (mobile.length > 10) mobile = mobile.substring(mobile.length - 10);
            }

            final ok = await authService.promptForMpinAndRefresh(mobile: mobile ?? '');
            if (ok) {
              // Retry the failed request with updated auth header
              final options = error.requestOptions;
              options.headers['Authorization'] = authService.getAuthHeader();
              // Perform retry
              final clonedResponse = await _dio.fetch(options);
              return handler.resolve(clonedResponse);
            } else {
              authService.logout();
            }
          } catch (e) {
            authService.logout();
          }
        }
        return handler.next(error);
      },
    ));
  }

  /// Fetch dashboard configuration from API
  Future<DashboardApiResponse> getDashboard() async {
    try {
      // endpoint moved - because baseUrl already includes `/reckonpwsorder`, call `/getNdashboard`
      final response = await _dio.get('/getNdashboard');

      return DashboardApiResponse.fromJson(response.data);
    } on DioException catch (e) {
      throw DashboardException(
        message: e.response?.data['message'] ?? e.message ?? 'Failed to fetch dashboard',
        statusCode: e.response?.statusCode,
      );
    } catch (e) {
      throw DashboardException(
        message: 'An unexpected error occurred: ${e.toString()}',
      );
    }
  }
}

class DashboardException implements Exception {
  final String message;
  final int? statusCode;

  DashboardException({required this.message, this.statusCode});

  @override
  String toString() => message;
}

// API Response Model
class DashboardApiResponse {
  final bool success;
  final String message;
  final int rs;
  final DashboardData? data;

  DashboardApiResponse({
    required this.success,
    required this.message,
    required this.rs,
    this.data,
  });

  factory DashboardApiResponse.fromJson(Map<String, dynamic> json) {
    return DashboardApiResponse(
      success: json['success'] ?? false,
      message: json['message'] ?? '',
      rs: json['rs'] ?? 0,
      data: json['data'] != null ? DashboardData.fromJson(json['data']) : null,
    );
  }
}

// Dashboard Data Model
class DashboardData {
  final String appTitle;
  final UserInfoData userInfo;
  final BrandsData brands;
  final TenantDetail tenantDetail;
  final List<String> tags;
  final String bgColor;
  final AppBarData appBar;
  final BannerListData bannerList;
  final OrderStatusData? orderStatus;
  final OrderHistoryData? orderHistory;
  final NewArrivalData newArrival;
  final List<SectionData> sections;

  DashboardData({
    required this.appTitle,
    required this.userInfo,
    required this.brands,
    required this.tenantDetail,
    required this.tags,
    required this.bgColor,
    required this.appBar,
    required this.bannerList,
    this.orderStatus,
    this.orderHistory,
    required this.newArrival,
    required this.sections,
  });

  factory DashboardData.fromJson(Map<String, dynamic> json) {
    return DashboardData(
      appTitle: json['appTitle'] ?? 'Reckon Seller',
      userInfo: UserInfoData.fromJson(json['userInfo'] ?? {}),
      brands: BrandsData.fromJson(json['brands'] ?? {}),
      tenantDetail: TenantDetail.fromJson(json['tenantDetail'] ?? {}),
      tags: List<String>.from(json['tags'] ?? []),
      bgColor: json['bg_color'] ?? '#F5F5F5',
      appBar: AppBarData.fromJson(json['app_bar'] ?? {}),
      bannerList: BannerListData.fromJson(json['banner_list'] ?? {}),
      orderStatus: json['Order_Status'] != null
          ? OrderStatusData.fromJson(json['Order_Status'])
          : null,
      orderHistory: json['Order_History'] != null
          ? OrderHistoryData.fromJson(json['Order_History'])
          : null,
      newArrival: NewArrivalData.fromJson(json['new_arrival'] ?? {}),
      sections: (json['Sections'] as List?)
          ?.map((e) => SectionData.fromJson(e))
          .toList() ?? [],
    );
  }
}

class UserInfoData {
  final String loginLabel;
  final String roleLabel;

  UserInfoData({required this.loginLabel, required this.roleLabel});

  factory UserInfoData.fromJson(Map<String, dynamic> json) {
    return UserInfoData(
      loginLabel: json['loginLabel'] ?? '',
      roleLabel: json['roleLabel'] ?? '',
    );
  }
}

class BrandsData {
  final bool visible;
  final String title;
  final String bgColor;
  final String levelColor;
  final List<dynamic> brandList;

  BrandsData({
    required this.visible,
    required this.title,
    required this.bgColor,
    required this.levelColor,
    required this.brandList,
  });

  factory BrandsData.fromJson(Map<String, dynamic> json) {
    return BrandsData(
      visible: json['visible'] ?? false,
      title: json['title'] ?? '',
      bgColor: json['bg_color'] ?? '#FFFFFF',
      levelColor: json['level_color'] ?? '#000000',
      brandList: json['brand_list'] ?? [],
    );
  }
}

class TenantDetail {
  final bool negativeStock;
  final String? tenantSmsUrl;
  final String? tenantCashReceiptFormat;
  final String? tenantBankReceiptFormat;
  final String? tenantMkey;
  final String? tenantMid;
  final bool? includeTax;
  final bool? showScheme;

  TenantDetail({
    required this.negativeStock,
    this.tenantSmsUrl,
    this.tenantCashReceiptFormat,
    this.tenantBankReceiptFormat,
    this.tenantMkey,
    this.tenantMid,
    this.includeTax,
    this.showScheme,
  });

  factory TenantDetail.fromJson(Map<String, dynamic> json) {
    return TenantDetail(
      negativeStock: json['negativestock'] ?? false,
      tenantSmsUrl: json['tenantsmsurl'],
      tenantCashReceiptFormat: json['tenantcashreceiptformat'],
      tenantBankReceiptFormat: json['tenantbankreceiptformat'],
      tenantMkey: json['tenantmkey'],
      tenantMid: json['tenantmid'],
      includeTax: json['includetax'],
      showScheme: json['showscheme'],
    );
  }
}

class AppBarData {
  final String bgColor;
  final String textColor;
  final bool showSearch;
  final bool showProfile;

  AppBarData({
    required this.bgColor,
    required this.textColor,
    required this.showSearch,
    required this.showProfile,
  });

  factory AppBarData.fromJson(Map<String, dynamic> json) {
    return AppBarData(
      bgColor: json['bg_color'] ?? '#F5F5F5',
      textColor: json['text_color'] ?? '#000000',
      showSearch: json['show_search'] ?? true,
      showProfile: json['show_profile'] ?? true,
    );
  }
}

class BannerListData {
  final bool visible;
  final List<BannerItem> banners;
  final String bgColor;

  BannerListData({
    required this.visible,
    required this.banners,
    required this.bgColor,
  });

  factory BannerListData.fromJson(Map<String, dynamic> json) {
    return BannerListData(
      visible: json['visible'] ?? false,
      banners: (json['banners'] as List?)
          ?.map((e) => BannerItem.fromJson(e))
          .toList() ?? [],
      bgColor: json['bg_color'] ?? '#FFFFFF',
    );
  }
}

class BannerItem {
  final int apId;
  final int apImageType;

  BannerItem({required this.apId, required this.apImageType});

  factory BannerItem.fromJson(Map<String, dynamic> json) {
    return BannerItem(
      apId: json['Ap_Id'] ?? 0,
      apImageType: json['Ap_ImageType'] ?? 0,
    );
  }
}

class OrderStatusData {
  final bool visible;
  final String title;
  final String date;
  final double amount;
  final String status;
  final String bgColor;
  final String levelColor;

  OrderStatusData({
    required this.visible,
    required this.title,
    required this.date,
    required this.amount,
    required this.status,
    required this.bgColor,
    required this.levelColor,
  });

  factory OrderStatusData.fromJson(Map<String, dynamic> json) {
    return OrderStatusData(
      visible: json['visible'] ?? false,
      title: json['title'] ?? '',
      date: json['date'] ?? '',
      amount: (json['amount'] ?? 0).toDouble(),
      status: json['status'] ?? '',
      bgColor: json['bg_color'] ?? '#13A2DF',
      levelColor: json['level_color'] ?? '#FFFFFF',
    );
  }
}

class OrderHistoryData {
  final bool visible;
  final String title;
  final String bgColor;
  final String levelColor;
  final int totalOrdersCount;
  final double totalOrdersAmount;
  final int invoicesCount;
  final double invoicesAmount;

  OrderHistoryData({
    required this.visible,
    required this.title,
    required this.bgColor,
    required this.levelColor,
    required this.totalOrdersCount,
    required this.totalOrdersAmount,
    required this.invoicesCount,
    required this.invoicesAmount,
  });

  factory OrderHistoryData.fromJson(Map<String, dynamic> json) {
    return OrderHistoryData(
      visible: json['visible'] ?? false,
      title: json['title'] ?? '',
      bgColor: json['bg_color'] ?? '#FFFFFF',
      levelColor: json['level_color'] ?? '#000000',
      totalOrdersCount: json['total_orders_count'] ?? 0,
      totalOrdersAmount: (json['total_orders_amount'] ?? 0).toDouble(),
      invoicesCount: json['invoices_count'] ?? 0,
      invoicesAmount: (json['invoices_amount'] ?? 0).toDouble(),
    );
  }
}

class NewArrivalData {
  final bool visible;
  final String title;
  final String bgColor;
  final String levelColor;
  final List<dynamic> arrivalList;

  NewArrivalData({
    required this.visible,
    required this.title,
    required this.bgColor,
    required this.levelColor,
    required this.arrivalList,
  });

  factory NewArrivalData.fromJson(Map<String, dynamic> json) {
    return NewArrivalData(
      visible: json['visible'] ?? false,
      title: json['title'] ?? '',
      bgColor: json['bg_color'] ?? '#FFFFFF',
      levelColor: json['level_color'] ?? '#000000',
      arrivalList: json['arrival_list'] ?? [],
    );
  }
}

class SectionData {
  final int id;
  final String title;
  final bool visible;
  final List<SectionItemData> items;
  final String? bgColor;
  final String? levelColor;

  SectionData({
    required this.id,
    required this.title,
    required this.visible,
    required this.items,
    this.bgColor,
    this.levelColor,
  });

  factory SectionData.fromJson(Map<String, dynamic> json) {
    return SectionData(
      id: json['id'] ?? 0,
      title: json['title'] ?? '',
      visible: json['visible'] ?? true,
      items: (json['items'] as List?)
          ?.map((e) => SectionItemData.fromJson(e))
          .toList() ?? [],
      bgColor: json['bg_color'],
      levelColor: json['level_color'],
    );
  }
}

class SectionItemData {
  final int id;
  final String title;
  final String? icon;
  final String? route;
  final bool visible;
  final String? image;
  final bool isActive;
  final String? bgCard;
  final String? colorTitle;

  SectionItemData({
    required this.id,
    required this.title,
    this.icon,
    this.route,
    required this.visible,
    this.image,
    required this.isActive,
    this.bgCard,
    this.colorTitle,
  });

  factory SectionItemData.fromJson(Map<String, dynamic> json) {
    return SectionItemData(
      id: json['id'] ?? 0,
      title: json['title'] ?? '',
      icon: json['icon'],
      route: json['route'],
      visible: json['visible'] ?? true,
      image: json['image'],
      isActive: json['is_active'] ?? true,
      bgCard: json['bg_card'],
      colorTitle: json['color_title'],
    );
  }
}
