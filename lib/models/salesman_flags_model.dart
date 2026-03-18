import 'dart:convert';

class SalesmanFlags {
  final int tenantId;
  final String tenantName;
  final bool negativeStock;
  final String includeTax;
  final double minOrderValueSalesMan;
  final bool enableScreenshot;
  final bool showStockSalesMan;
  final bool showlocationSalesman;
  final bool showRateSalesMan;
  final bool showMrpSalesMan;
  final bool enablePriceSalesMan;
  final bool showdisc1perSalesman;
  final bool showDiscPerSalesMan;
  final bool showDiscPcsSalesMan;
  final bool showSchemeSalesMan;
  final bool showFreeQtySalesMan;
  final bool showManualSchemeSalesMan;
  final bool showIncreaseDecreaseButtonSalesMan;
  final bool showadddetailsbottomsheetSalesMan;
  final bool showProductDescSalesMan;
  final bool showItemRemarkSalesMan;
  final bool showItemRefNumberSalesMan;
  final bool showItemCompositionSalesMan;
  final bool showItemMfgCompSalesMan;
  final bool showitemCategorySalesMan;
  final String searchfieldlistSalesman;

  SalesmanFlags({
    required this.tenantId,
    required this.tenantName,
    required this.negativeStock,
    required this.includeTax,
    required this.minOrderValueSalesMan,
    required this.enableScreenshot,
    required this.showStockSalesMan,
    required this.showlocationSalesman,
    required this.showRateSalesMan,
    required this.showMrpSalesMan,
    required this.enablePriceSalesMan,
    required this.showdisc1perSalesman,
    required this.showDiscPerSalesMan,
    required this.showDiscPcsSalesMan,
    required this.showSchemeSalesMan,
    required this.showFreeQtySalesMan,
    required this.showManualSchemeSalesMan,
    required this.showIncreaseDecreaseButtonSalesMan,
    required this.showadddetailsbottomsheetSalesMan,
    required this.showProductDescSalesMan,
    required this.showItemRemarkSalesMan,
    required this.showItemRefNumberSalesMan,
    required this.showItemCompositionSalesMan,
    required this.showItemMfgCompSalesMan,
    required this.showitemCategorySalesMan,
    required this.searchfieldlistSalesman,
  });

  factory SalesmanFlags.fromJson(Map<String, dynamic> json) {
    return SalesmanFlags(
      tenantId: json['TenantId'] ?? 0,
      tenantName: json['TenantName'] ?? '',
      negativeStock: json['NegativeStock'] ?? false,
      includeTax: json['IncludeTax']?.toString() ?? '0',
      minOrderValueSalesMan: _safeDouble(json['MinOrderValue_SalesMan']),
      enableScreenshot: json['enable_screenshot'] ?? false,
      showStockSalesMan: json['ShowStock_SalesMan'] ?? false,
      showlocationSalesman: json['showlocation_Salesman'] ?? false,
      showRateSalesMan: json['ShowRate_SalesMan'] ?? false,
      showMrpSalesMan: json['ShowMrp_SalesMan'] ?? false,
      enablePriceSalesMan: json['EnablePrice_SalesMan'] ?? false,
      showdisc1perSalesman: json['showdisc1per_Salesman'] ?? false,
      showDiscPerSalesMan: json['ShowDiscPer_SalesMan'] ?? false,
      showDiscPcsSalesMan: json['ShowDiscPcs_SalesMan'] ?? false,
      showSchemeSalesMan: json['ShowScheme_SalesMan'] ?? false,
      showFreeQtySalesMan: json['ShowFreeQty_SalesMan'] ?? false,
      showManualSchemeSalesMan: json['ShowManualScheme_SalesMan'] ?? false,
      showIncreaseDecreaseButtonSalesMan: json['ShowIncreaseDecreaseButton_SalesMan'] ?? false,
      showadddetailsbottomsheetSalesMan: json['Showadddetailsbottomsheet_SalesMan'] ?? false,
      showProductDescSalesMan: json['ShowProductDesc_SalesMan'] ?? false,
      showItemRemarkSalesMan: json['ShowItemRemark_SalesMan'] ?? false,
      showItemRefNumberSalesMan: json['ShowItemRefNumber_SalesMan'] ?? false,
      showItemCompositionSalesMan: json['showItemComposition_SalesMan'] ?? false,
      showItemMfgCompSalesMan: json['showItemMfgComp_SalesMan'] ?? false,
      showitemCategorySalesMan: json['showitemCategory_SalesMan'] ?? false,
      searchfieldlistSalesman: json['searchfieldlist_Salesman']?.toString() ?? '0',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'TenantId': tenantId,
      'TenantName': tenantName,
      'NegativeStock': negativeStock,
      'IncludeTax': includeTax,
      'MinOrderValue_SalesMan': minOrderValueSalesMan,
      'enable_screenshot': enableScreenshot,
      'ShowStock_SalesMan': showStockSalesMan,
      'showlocation_Salesman': showlocationSalesman,
      'ShowRate_SalesMan': showRateSalesMan,
      'ShowMrp_SalesMan': showMrpSalesMan,
      'EnablePrice_SalesMan': enablePriceSalesMan,
      'showdisc1per_Salesman': showdisc1perSalesman,
      'ShowDiscPer_SalesMan': showDiscPerSalesMan,
      'ShowDiscPcs_SalesMan': showDiscPcsSalesMan,
      'ShowScheme_SalesMan': showSchemeSalesMan,
      'ShowFreeQty_SalesMan': showFreeQtySalesMan,
      'ShowManualScheme_SalesMan': showManualSchemeSalesMan,
      'ShowIncreaseDecreaseButton_SalesMan': showIncreaseDecreaseButtonSalesMan,
      'Showadddetailsbottomsheet_SalesMan': showadddetailsbottomsheetSalesMan,
      'ShowProductDesc_SalesMan': showProductDescSalesMan,
      'ShowItemRemark_SalesMan': showItemRemarkSalesMan,
      'ShowItemRefNumber_SalesMan': showItemRefNumberSalesMan,
      'showItemComposition_SalesMan': showItemCompositionSalesMan,
      'showItemMfgComp_SalesMan': showItemMfgCompSalesMan,
      'showitemCategory_SalesMan': showitemCategorySalesMan,
      'searchfieldlist_Salesman': searchfieldlistSalesman,
    };
  }

  String toJsonString() => jsonEncode(toJson());

  factory SalesmanFlags.fromJsonString(String jsonString) {
    return SalesmanFlags.fromJson(jsonDecode(jsonString));
  }

  static double _safeDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0.0;
    return 0.0;
  }
}

