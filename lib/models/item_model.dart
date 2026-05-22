// Item model for GetItemList API
class ItemModel {
  final int iidcol; // i_id_col
  final String code;
  final String name;
  final String packing;
  final String mfgComp;
  final double rateA;
  final double mrp;
  final double stock;
  final double tax;
  final String stockType;
  final String firmName;
  final String salt;
  final String? refNumber; // RefNumber from API
  final String scheme; // scheme narration from GetItemList
  // Visibility flags from GetItemList — control whether to show each field.
  final bool showMrp;
  final bool showRate;
  final bool showStock;
  final bool showScheme;
  final double rating; // item rating from GetItemList

  ItemModel({
    required this.iidcol,
    required this.code,
    required this.name,
    required this.packing,
    required this.mfgComp,
    required this.rateA,
    required this.mrp,
    required this.stock,
    required this.tax,
    required this.stockType,
    required this.firmName,
    required this.salt,
    this.refNumber,
    this.scheme = '',
    this.showMrp = true,
    this.showRate = true,
    this.showStock = true,
    this.showScheme = true,
    this.rating = 0,
  });

  factory ItemModel.fromJson(Map<String, dynamic> json) {
    int parseInt(dynamic v) {
      if (v == null) return 0;
      if (v is int) return v;
      return int.tryParse(v.toString()) ?? 0;
    }

    double parseDouble(dynamic v) {
      if (v == null) return 0.0;
      if (v is double) return v;
      if (v is int) return v.toDouble();
      return double.tryParse(v.toString()) ?? 0.0;
    }

    return ItemModel(
      iidcol: parseInt(json['i_id_col'] ?? json['i_idcol'] ?? json['iIdCol']),
      code: (json['Code'] ?? '').toString(),
      name: (json['Name'] ?? '').toString(),
      packing: (json['packing'] ?? '').toString(),
      mfgComp: (json['MfgComp'] ?? '').toString(),
      rateA: parseDouble(json['RateA'] ?? json['Rate'] ?? json['PRate']),
      mrp: parseDouble(json['Mrp']),
      stock: parseDouble(json['Stock']),
      tax: parseDouble(json['Tax']),
      stockType: (json['StockType'] ?? '').toString(),
      firmName: (json['FirmName'] ?? '').toString(),
      salt: (json['Salt'] ?? json['Salt '] ?? '').toString(),
      refNumber: (json['RefNumber'] ?? '').toString().isEmpty ? null : (json['RefNumber'] ?? '').toString(),
      // Scheme narration from GetItemList — confirmed key is 'SCHNARR'.
      scheme: (json['SCHNARR'] ?? '').toString().trim(),
      showMrp: json['ShowMrp'] == true,
      showRate: json['ShowRate'] == true,
      showStock: json['ShowStock'] == true,
      showScheme: json['ShowScheme'] == true,
      rating: parseDouble(json['Rating']),
    );
  }
}
