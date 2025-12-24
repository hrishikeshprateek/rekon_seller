import 'dart:convert';

class DashboardConfig {
  final String appTitle;
  final String bgColor;
  final AppBarConfig? appBar;
  final UserInfo userInfo;
  final BannerList bannerList;
  final OrderStatus orderStatus;
  final OrderHistory orderHistory;
  final NewArrival newArrival;
  final Brands brands;
  final Testimonials testimonials;
  final TenantDetail tenantDetail;
  final List<String> tags;
  final List<DashboardSection> sections;
  final List<DashboardItem> extras;
  final List<BottomNavItem> bottomNavigation;

  DashboardConfig({
    required this.appTitle,
    required this.bgColor,
    this.appBar,
    required this.userInfo,
    required this.bannerList,
    required this.orderStatus,
    required this.orderHistory,
    required this.newArrival,
    required this.brands,
    required this.testimonials,
    required this.tenantDetail,
    required this.tags,
    required this.sections,
    required this.extras,
    required this.bottomNavigation,
  });

  factory DashboardConfig.fromJson(Map<String, dynamic> json) {
    return DashboardConfig(
      appTitle: json['appTitle'] ?? '',
      bgColor: json['bg_color'] ?? '#F5F5F5',
      appBar: json['app_bar'] != null ? AppBarConfig.fromJson(json['app_bar']) : null,
      userInfo: UserInfo.fromJson(json['userInfo'] ?? {}),
      bannerList: BannerList.fromJson(json['banner_list'] ?? {}),
      orderStatus: OrderStatus.fromJson(json['order_status'] ?? {}),
      orderHistory: OrderHistory.fromJson(json['order_history'] ?? {}),
      newArrival: NewArrival.fromJson(json['new_arrival'] ?? {}),
      brands: Brands.fromJson(json['brands'] ?? {}),
      testimonials: Testimonials.fromJson(json['testimonials'] ?? {}),
      tenantDetail: TenantDetail.fromJson(json['tenantDetail'] ?? {}),
      tags: (json['tags'] as List?)?.map((t) => t.toString()).toList() ?? [],
      sections: (json['sections'] as List?)
          ?.map((s) => DashboardSection.fromJson(s))
          .toList() ?? [],
      extras: (json['extras'] as List?)
          ?.map((e) => DashboardItem.fromJson(e))
          .toList() ?? [],
      bottomNavigation: (json['bottomNavigation'] as List?)
          ?.map((n) => BottomNavItem.fromJson(n))
          .toList() ?? [],
    );
  }

  static DashboardConfig fromJsonString(String jsonString) {
    final Map<String, dynamic> jsonMap = json.decode(jsonString);
    return DashboardConfig.fromJson(jsonMap);
  }
}

class AppBarConfig {
  final String bgColor;
  final String textColor;
  final bool showSearch;
  final bool showProfile;

  AppBarConfig({
    required this.bgColor,
    required this.textColor,
    required this.showSearch,
    required this.showProfile,
  });

  factory AppBarConfig.fromJson(Map<String, dynamic> json) {
    return AppBarConfig(
      bgColor: json['bg_color'] ?? '#F5F5F5',
      textColor: json['text_color'] ?? '#000000',
      showSearch: json['show_search'] ?? true,
      showProfile: json['show_profile'] ?? true,
    );
  }
}

class UserInfo {
  final String loginLabel;
  final String roleLabel;

  UserInfo({
    required this.loginLabel,
    required this.roleLabel,
  });

  factory UserInfo.fromJson(Map<String, dynamic> json) {
    return UserInfo(
      loginLabel: json['loginLabel'] ?? '',
      roleLabel: json['roleLabel'] ?? '',
    );
  }
}

class BannerList {
  final bool visible;
  final String bgColor;
  final List<BannerItem> banners;

  BannerList({
    required this.visible,
    required this.bgColor,
    required this.banners,
  });

  factory BannerList.fromJson(Map<String, dynamic> json) {
    return BannerList(
      visible: json['visible'] ?? true,
      bgColor: json['bg_color'] ?? '#FFFFFF',
      banners: (json['banners'] as List?)
          ?.map((b) => BannerItem.fromJson(b))
          .toList() ?? [],
    );
  }
}

class BannerItem {
  final int id;
  final String image;
  final String title;
  final bool visible;
  final String link;

  BannerItem({
    required this.id,
    required this.image,
    required this.title,
    required this.visible,
    required this.link,
  });

  factory BannerItem.fromJson(Map<String, dynamic> json) {
    return BannerItem(
      id: json['id'] ?? 0,
      image: json['image'] ?? '',
      title: json['title'] ?? '',
      visible: json['visible'] ?? true,
      link: json['link'] ?? '',
    );
  }
}

class OrderStatus {
  final bool visible;
  final String bgColor;
  final String levelColor;
  final String title;
  final String date;
  final double amount;
  final String currency;
  final int id;
  final String status;

  OrderStatus({
    required this.visible,
    required this.bgColor,
    required this.levelColor,
    required this.title,
    required this.date,
    required this.amount,
    required this.currency,
    required this.id,
    required this.status,
  });

  factory OrderStatus.fromJson(Map<String, dynamic> json) {
    return OrderStatus(
      visible: json['visible'] ?? true,
      bgColor: json['bg_color'] ?? '#13A2DF',
      levelColor: json['level_color'] ?? '#FFFFFF',
      title: json['title'] ?? 'Order Status',
      date: json['date'] ?? '',
      amount: (json['amount'] ?? 0).toDouble(),
      currency: json['currency'] ?? '₹',
      id: json['id'] ?? 0,
      status: json['status'] ?? 'No Active Order',
    );
  }
}

class OrderHistory {
  final bool visible;
  final String bgColor;
  final String levelColor;
  final String title;
  final int totalOrdersCount;
  final double totalOrdersAmount;
  final int invoicesCount;
  final double invoicesAmount;

  OrderHistory({
    required this.visible,
    required this.bgColor,
    required this.levelColor,
    required this.title,
    required this.totalOrdersCount,
    required this.totalOrdersAmount,
    required this.invoicesCount,
    required this.invoicesAmount,
  });

  factory OrderHistory.fromJson(Map<String, dynamic> json) {
    return OrderHistory(
      visible: json['visible'] ?? true,
      bgColor: json['bg_color'] ?? '#FFFFFF',
      levelColor: json['level_color'] ?? '#000000',
      title: json['title'] ?? 'Order History',
      totalOrdersCount: json['total_orders_count'] ?? 0,
      totalOrdersAmount: (json['total_orders_amount'] ?? 0).toDouble(),
      invoicesCount: json['invoices_count'] ?? 0,
      invoicesAmount: (json['invoices_amount'] ?? 0).toDouble(),
    );
  }
}

class NewArrival {
  final bool visible;
  final String bgColor;
  final String levelColor;
  final String title;
  final List<dynamic> arrivalList;

  NewArrival({
    required this.visible,
    required this.bgColor,
    required this.levelColor,
    required this.title,
    required this.arrivalList,
  });

  factory NewArrival.fromJson(Map<String, dynamic> json) {
    return NewArrival(
      visible: json['visible'] ?? true,
      bgColor: json['bg_color'] ?? '#FFFFFF',
      levelColor: json['level_color'] ?? '#000000',
      title: json['title'] ?? 'New Arrival',
      arrivalList: json['arrival_list'] ?? [],
    );
  }
}

class Brands {
  final bool visible;
  final String bgColor;
  final String levelColor;
  final String title;
  final List<dynamic> brandList;

  Brands({
    required this.visible,
    required this.bgColor,
    required this.levelColor,
    required this.title,
    required this.brandList,
  });

  factory Brands.fromJson(Map<String, dynamic> json) {
    return Brands(
      visible: json['visible'] ?? true,
      bgColor: json['bg_color'] ?? '#FFFFFF',
      levelColor: json['level_color'] ?? '#000000',
      title: json['title'] ?? 'Brands',
      brandList: json['brand_list'] ?? [],
    );
  }
}

class Testimonials {
  final bool visible;
  final String bgColor;
  final String levelColor;
  final String title;
  final List<dynamic> testimonialsList;

  Testimonials({
    required this.visible,
    required this.bgColor,
    required this.levelColor,
    required this.title,
    required this.testimonialsList,
  });

  factory Testimonials.fromJson(Map<String, dynamic> json) {
    return Testimonials(
      visible: json['visible'] ?? false,
      bgColor: json['bg_color'] ?? '#FFFFFF',
      levelColor: json['level_color'] ?? '#000000',
      title: json['title'] ?? 'Testimonials',
      testimonialsList: json['testimonials_list'] ?? [],
    );
  }
}

class TenantDetail {
  final bool showIncreaseDecreaseButton;
  final bool showDiscPcs;
  final bool showAddDetailsBottomSheet;
  final bool showItemComposition;
  final bool showAdditionalDiscount;
  final bool enableScreenshot;
  final bool showFreeQty;
  final int minOrderValue;
  final bool showStock;
  final bool showRate;
  final bool showDiscPer;
  final bool showItemRefNumber;
  final bool showItemCategory;
  final bool showItemMfgComp;
  final String includeTax;
  final bool showMrp;
  final bool showScheme;
  final bool enablePrice;
  final bool negativeStock;
  final bool showItemRemark;
  final bool showProductDesc;
  final bool showLocation;
  final bool showManualScheme;

  TenantDetail({
    required this.showIncreaseDecreaseButton,
    required this.showDiscPcs,
    required this.showAddDetailsBottomSheet,
    required this.showItemComposition,
    required this.showAdditionalDiscount,
    required this.enableScreenshot,
    required this.showFreeQty,
    required this.minOrderValue,
    required this.showStock,
    required this.showRate,
    required this.showDiscPer,
    required this.showItemRefNumber,
    required this.showItemCategory,
    required this.showItemMfgComp,
    required this.includeTax,
    required this.showMrp,
    required this.showScheme,
    required this.enablePrice,
    required this.negativeStock,
    required this.showItemRemark,
    required this.showProductDesc,
    required this.showLocation,
    required this.showManualScheme,
  });

  factory TenantDetail.fromJson(Map<String, dynamic> json) {
    return TenantDetail(
      showIncreaseDecreaseButton: json['show_increase_decrease_button'] ?? false,
      showDiscPcs: json['show_disc_pcs'] ?? true,
      showAddDetailsBottomSheet: json['show_add_details_bottom_sheet'] ?? true,
      showItemComposition: json['show_item_composition'] ?? true,
      showAdditionalDiscount: json['show_additional_discount'] ?? true,
      enableScreenshot: json['enable_screenshot'] ?? true,
      showFreeQty: json['show_free_qty'] ?? true,
      minOrderValue: json['minordervalue'] ?? 1000,
      showStock: json['show_stock'] ?? true,
      showRate: json['show_rate'] ?? true,
      showDiscPer: json['show_disc_per'] ?? true,
      showItemRefNumber: json['show_item_refnumber'] ?? true,
      showItemCategory: json['show_item_category'] ?? true,
      showItemMfgComp: json['show_item_mfgcomp'] ?? true,
      includeTax: json['includetax'] ?? '0',
      showMrp: json['show_mrp'] ?? true,
      showScheme: json['show_scheme'] ?? true,
      enablePrice: json['enable_price'] ?? true,
      negativeStock: json['negativestock'] ?? true,
      showItemRemark: json['show_item_remark'] ?? false,
      showProductDesc: json['show_product_desc'] ?? false,
      showLocation: json['show_location'] ?? true,
      showManualScheme: json['show_manual_scheme'] ?? true,
    );
  }
}

class DashboardSection {
  final String id;
  final String title;
  final String bgColor;
  final String levelColor;
  final bool visible;
  final List<DashboardItem> items;

  DashboardSection({
    required this.id,
    required this.title,
    required this.bgColor,
    required this.levelColor,
    required this.visible,
    required this.items,
  });

  factory DashboardSection.fromJson(Map<String, dynamic> json) {
    return DashboardSection(
      id: json['id'] ?? '',
      title: json['title'] ?? '',
      bgColor: json['bg_color'] ?? '#13A2DF',
      levelColor: json['level_color'] ?? '#FFFFFF',
      visible: json['visible'] ?? true,
      items: (json['items'] as List?)
          ?.map((i) => DashboardItem.fromJson(i))
          .toList() ?? [],
    );
  }
}

class DashboardItem {
  final String id;
  final String label;
  final String icon;
  final String route;
  final bool visible;
  final bool isActive;
  final String bgCard;
  final String colorTitle;
  final String type;
  final String image;

  DashboardItem({
    required this.id,
    required this.label,
    required this.icon,
    required this.route,
    required this.visible,
    required this.isActive,
    required this.bgCard,
    required this.colorTitle,
    required this.type,
    required this.image,
  });

  factory DashboardItem.fromJson(Map<String, dynamic> json) {
    return DashboardItem(
      id: json['id'] ?? '',
      label: json['label'] ?? '',
      icon: json['icon'] ?? '',
      route: json['route'] ?? '',
      visible: json['visible'] ?? true,
      isActive: json['is_active'] ?? true,
      bgCard: json['bg_card'] ?? '#FFFFFF',
      colorTitle: json['color_title'] ?? '#1E5FA6',
      type: json['type']?.toString() ?? '',
      image: json['image'] ?? '',
    );
  }
}

class BottomNavItem {
  final String id;
  final String label;
  final String icon;
  final String selectedIcon;

  BottomNavItem({
    required this.id,
    required this.label,
    required this.icon,
    required this.selectedIcon,
  });

  factory BottomNavItem.fromJson(Map<String, dynamic> json) {
    return BottomNavItem(
      id: json['id'] ?? '',
      label: json['label'] ?? '',
      icon: json['icon'] ?? '',
      selectedIcon: json['selectedIcon'] ?? '',
    );
  }
}

