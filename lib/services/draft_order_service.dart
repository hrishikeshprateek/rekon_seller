import 'dart:async';
import 'dart:convert';

import 'package:dio/dio.dart';

import '../auth_service.dart';

class DraftOrderContext {
  final String userId;
  final String licNo;
  final String firmCode;
  final String acCode;
  final int cuId;
  final String packageName;
  final String? authHeader;

  const DraftOrderContext({
    required this.userId,
    required this.licNo,
    required this.firmCode,
    required this.acCode,
    required this.cuId,
    required this.packageName,
    this.authHeader,
  });

  factory DraftOrderContext.fromAuth({
    required AuthService auth,
    required String acCode,
  }) {
    final user = auth.currentUser;
    String firmCode = '';
    try {
      final stores = user?.stores;
      if (stores != null && stores.isNotEmpty) {
        final primary = stores.firstWhere((s) => s.primary == true, orElse: () => stores.first);
        firmCode = primary.firmCode;
      }
    } catch (_) {}

    return DraftOrderContext(
      userId: user?.mobileNumber ?? user?.userId ?? '',
      licNo: user?.licenseNumber ?? '',
      firmCode: firmCode,
      acCode: acCode,
      cuId: int.tryParse(user?.userId ?? '') ?? 0,
      packageName: auth.packageNameHeader,
      authHeader: auth.getAuthHeader(),
    );
  }
}

class DraftOrderRequest {
  final String itemCode;
  final int idCol;
  final String itemQty;
  final String itemRate;
  final String itemFQty;
  final String itemSchQty;
  final String itemDSchQty;
  final String itemAmt;
  final String discountPercentage;
  final String discountPercentage1;
  final String discountPcs;
  final String remark;
  final int insertRecord;
  final bool defaultHit;

  const DraftOrderRequest({
    required this.itemCode,
    required this.idCol,
    required this.itemQty,
    required this.itemRate,
    required this.itemFQty,
    required this.itemSchQty,
    required this.itemDSchQty,
    required this.itemAmt,
    required this.discountPercentage,
    required this.discountPercentage1,
    required this.discountPcs,
    required this.remark,
    required this.insertRecord,
    this.defaultHit = true,
  });

  DraftOrderRequest copyWith({
    String? itemQty,
    String? itemRate,
    String? itemFQty,
    String? itemSchQty,
    String? itemDSchQty,
    String? itemAmt,
    String? discountPercentage,
    String? discountPercentage1,
    String? discountPcs,
    String? remark,
    int? insertRecord,
    bool? defaultHit,
  }) {
    return DraftOrderRequest(
      itemCode: itemCode,
      idCol: idCol,
      itemQty: itemQty ?? this.itemQty,
      itemRate: itemRate ?? this.itemRate,
      itemFQty: itemFQty ?? this.itemFQty,
      itemSchQty: itemSchQty ?? this.itemSchQty,
      itemDSchQty: itemDSchQty ?? this.itemDSchQty,
      itemAmt: itemAmt ?? this.itemAmt,
      discountPercentage: discountPercentage ?? this.discountPercentage,
      discountPercentage1: discountPercentage1 ?? this.discountPercentage1,
      discountPcs: discountPcs ?? this.discountPcs,
      remark: remark ?? this.remark,
      insertRecord: insertRecord ?? this.insertRecord,
      defaultHit: defaultHit ?? this.defaultHit,
    );
  }

  Map<String, dynamic> toPayload(DraftOrderContext context) {
    return {
      'UserId': context.userId,
      'LicNo': context.licNo,
      'lFirmCode': context.firmCode,
      'AcCode': context.acCode,
      'ItemCode': itemCode,
      // NOTE: do NOT add `Icode` here. When present, the backend resolves
      // the item's stored per-account discount rule and discards the
      // `discount_percentage` we send. Postman calls without `Icode`
      // honour the user-typed discount; sending it locks the % to the
      // server default. Confirmed via paired Postman/Flutter test (May
      // 2026): same payload, only differing by `Icode`, returned 7.0
      // vs the sent 8.0.
      'IdCol': idCol,
      'cu_id': context.cuId,
      'ItemQty': itemQty,
      'ItemRate': itemRate,
      'ItemFQty': itemFQty,
      'ItemSchQty': itemSchQty,
      'ItemDSchQty': itemDSchQty,
      'ItemAmt': itemAmt,
      'discount_percentage': discountPercentage,
      'discount_percentage1': discountPercentage1,
      'discount_pcs': discountPcs,
      'remark': remark,
      'insert_record': insertRecord,
      'default_hit': defaultHit,
    };
  }
}

class DraftOrderPreviewResult {
  final bool success;
  final String message;
  final String qty;
  final double freeQty;
  final double rate;
  final double amt;
  final String itemSchType;
  final double schemeQty;
  final double dSchemeQty;
  final double aSchemeQty;
  final double schemeAmt;
  final double taxAmt;
  final double discAmt;
  final double disc1Amt;
  final double disc2Amt;
  final double discPer;
  final double disc1Per;
  final double disc2Per;
  final double netAmt;
  final double totalDisc;
  final double mrp;
  final String remark;
  final Map<String, dynamic> raw;

  const DraftOrderPreviewResult({
    required this.success,
    required this.message,
    required this.qty,
    required this.freeQty,
    required this.rate,
    required this.amt,
    required this.itemSchType,
    required this.schemeQty,
    required this.dSchemeQty,
    required this.aSchemeQty,
    required this.schemeAmt,
    required this.taxAmt,
    required this.discAmt,
    required this.disc1Amt,
    required this.disc2Amt,
    required this.discPer,
    required this.disc1Per,
    required this.disc2Per,
    required this.netAmt,
    required this.totalDisc,
    required this.mrp,
    required this.remark,
    required this.raw,
  });

  factory DraftOrderPreviewResult.fromResponse(Map<String, dynamic> response) {
    final data = response['data'] is Map<String, dynamic>
        ? response['data'] as Map<String, dynamic>
        : <String, dynamic>{};

    double asDouble(dynamic value) {
      if (value == null) return 0.0;
      if (value is num) return value.toDouble();
      return double.tryParse(value.toString()) ?? 0.0;
    }

    return DraftOrderPreviewResult(
      success: response['success'] == true || data['Status'] == true || response['rs'] == 1,
      message: data['Message']?.toString() ?? response['message']?.toString() ?? '',
      qty: data['Qty']?.toString() ?? '',
      freeQty: asDouble(data['DQty']),
      rate: asDouble(data['Rate']),
      amt: asDouble(data['Amt']),
      itemSchType: data['ItemSchType']?.toString() ?? '',
      schemeQty: asDouble(data['ItemSchQty']),
      dSchemeQty: asDouble(data['ItemDSchQty']),
      aSchemeQty: asDouble(data['ItemASchQty']),
      schemeAmt: asDouble(data['ItemSchAmt']),
      taxAmt: asDouble(data['ItemTaxAmt']),
      discAmt: asDouble(data['ItemDiscAmt']),
      disc1Amt: asDouble(data['ItemDisc1Amt']),
      disc2Amt: asDouble(data['ItemDisc2Amt']),
      discPer: asDouble(data['ItemDiscPer']),
      disc1Per: asDouble(data['ItemDisc1Per']),
      disc2Per: asDouble(data['ItemDisc2Per']),
      netAmt: asDouble(data['ItemNetAmt']),
      totalDisc: asDouble(data['totalDisc']),
      mrp: asDouble(data['Mrp']),
      remark: data['Remark']?.toString() ?? '',
      raw: response,
    );
  }
}

class DraftOrderService {
  final Dio dio;
  final DraftOrderContext context;

  const DraftOrderService({
    required this.dio,
    required this.context,
  });

  Future<DraftOrderPreviewResult> calculate(DraftOrderRequest request) {
    return _post(request.copyWith(insertRecord: 0));
  }

  Future<DraftOrderPreviewResult> insert(DraftOrderRequest request) {
    return _post(request.copyWith(insertRecord: 1));
  }

  Future<DraftOrderPreviewResult> _post(DraftOrderRequest request) async {
    final payload = request.toPayload(context);
    final headers = {
      'Content-Type': 'application/json',
      'package_name': context.packageName,
      if (context.authHeader != null) 'Authorization': context.authHeader,
    };

    final mode = payload['insert_record'] == 0 ? 'PREVIEW' : 'INSERT';
    print('[DraftOrderService $mode] >>> BODY ${jsonEncode(payload)}');

    final response = await dio.post(
      '/AddDraftOrder',
      data: payload,
      options: Options(headers: headers),
    );

    final rawStr = response.data is String ? response.data as String : jsonEncode(response.data);
    print('[DraftOrderService $mode] <<< RESPONSE $rawStr');

    return DraftOrderPreviewResult.fromResponse(_normalizeResponse(response.data));
  }

  static Map<String, dynamic> normalizeResponse(dynamic raw) => _normalizeResponse(raw);

  static Map<String, dynamic> _normalizeResponse(dynamic raw) {
    if (raw is Map<String, dynamic>) return raw;
    if (raw is String) {
      final clean = raw.replaceAll(RegExp(r'[\x00-\x1F\x7F]'), '').trim();
      return jsonDecode(clean) as Map<String, dynamic>;
    }
    return jsonDecode(jsonEncode(raw)) as Map<String, dynamic>;
  }
}

