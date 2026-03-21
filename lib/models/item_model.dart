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
    );
  }
}
