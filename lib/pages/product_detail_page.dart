import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:provider/provider.dart';
import '../auth_service.dart';
import 'dart:convert';
import '../models/account_model.dart' as models;
import '../models/product_model.dart';
import 'cart_page.dart';
import 'dart:async';
import '../services/draft_order_service.dart';

class ProductDetailPage extends StatefulWidget {
  final dynamic product;
  final models.Account selectedAccount;

  const ProductDetailPage({
    required this.product,
    required this.selectedAccount,
  });

  @override
  State<ProductDetailPage> createState() => _ProductDetailPageState();
}

class _ProductDetailPageState extends State<ProductDetailPage> {
  late dynamic product;
  int qty = 1;
  late TextEditingController qtyController;
  bool loadingSimilar = false;
  List<dynamic> similarProducts = [];
  int receivedId = 0;
  int cartQty = 0;

  @override
  void initState() {
    super.initState();
    product = widget.product;
    debugPrint('[ProductDetailPage] Product data: $product');
    _extractProductId();
    qty = _getInt(product, ['qty', 'Qty'], fallback: 1);
    qtyController = TextEditingController(text: qty.toString());
    fetchCartAndSetQty();
    fetchSimilarProducts();
  }

  void _extractProductId() {
    if (product is Product) {
      receivedId = product.iidcol ?? 0;
    } else if (product is Map) {
      var rawId = product['i_id_col'] ?? product['IdCol'] ?? product['iidcol'] ?? 0;
      if (rawId is int) {
        receivedId = rawId;
      } else if (rawId is String) {
        receivedId = int.tryParse(rawId) ?? 0;
      }
    } else {
      try {
        receivedId = product.iidcol ?? 0;
      } catch (_) {}
    }
  }

  @override
  void dispose() {
    qtyController.dispose();
    super.dispose();
  }

  Future<void> fetchCartAndSetQty() async {
    try {
      final auth = Provider.of<AuthService>(context, listen: false);
      final dio = auth.getDioClient();
      final user = auth.currentUser;
      final mobile = user?.mobileNumber ?? '';
      final licNo = user?.licenseNumber ?? '';
      String firmCode = '';

      try {
        if (user != null && user.stores.isNotEmpty) {
          final primary = user.stores.firstWhere(
            (s) => s.primary,
            orElse: () => user.stores.first,
          );
          firmCode = primary.firmCode;
        }
      } catch (_) {}

      // Use same acCode logic as order_entry_page
      final acCode = widget.selectedAccount.code ??
          (widget.selectedAccount.acIdCol != null
              ? widget.selectedAccount.acIdCol.toString()
              : widget.selectedAccount.id);

      final payload = {
        'lUserId': mobile,
        'lLicNo': licNo,
        'lFirmCode': firmCode,
        'AcCode': acCode,
      };

      final response = await dio.post(
        '/ListDraftOrder',
        data: payload,
        options: Options(
          headers: {
            'Content-Type': 'application/json',
            'package_name': auth.packageNameHeader,
            if (auth.getAuthHeader() != null)
              'Authorization': auth.getAuthHeader(),
          },
        ),
      );

      final parsed = _parseJson(response.data);
      int foundQty = 0;

      if (parsed['success'] == true && parsed['data'] != null) {
        final list = (parsed['data']['DraftOrder'] as List<dynamic>?) ?? [];

        // Extract product identifiers - handle both Product objects and Maps
        String productCode = '';
        int productIdCol = 0;

        if (product is Product) {
          productCode = product.code ?? '';
          productIdCol = product.iidcol ?? 0;
        } else if (product is Map) {
          productCode = product['Code']?.toString() ??
              product['code']?.toString() ??
              product['Icode']?.toString() ??
              product['ItemCode']?.toString() ??
              '';
          productIdCol = int.tryParse(product['i_id_col']?.toString() ??
                  product['iidcol']?.toString() ??
                  product['IdCol']?.toString() ??
                  '') ??
              0;
        } else {
          try {
            productCode = product.code ?? '';
            productIdCol = product.iidcol ?? 0;
          } catch (_) {}
        }

        for (final e in list) {
          final idCol = int.tryParse(
                  e['IdCol']?.toString() ?? e['Idcol']?.toString() ?? '') ??
              0;
          final code = e['Icode']?.toString() ??
              e['Code']?.toString() ??
              e['ItemCode']?.toString() ??
              '';

          bool matches = false;
          if (productIdCol > 0 && idCol > 0) {
            matches = productIdCol == idCol;
          }
          if (!matches && productCode.isNotEmpty && code.isNotEmpty) {
            matches = productCode == code;
          }

          if (matches) {
            foundQty = int.tryParse(e['Qty']?.toString() ?? '0') ?? 0;
            break;
          }
        }
      }

      if (mounted) {
        setState(() {
          cartQty = foundQty;
        });
      }
    } catch (e) {
      debugPrint('Error fetching cart: $e');
    }
  }

  Future<Map<String, dynamic>> fetchCartItemDetails() async {
    try {
      final auth = Provider.of<AuthService>(context, listen: false);
      final dio = auth.getDioClient();
      final user = auth.currentUser;
      final mobile = user?.mobileNumber ?? '';
      final licNo = user?.licenseNumber ?? '';
      String firmCode = '';

      try {
        if (user != null && user.stores.isNotEmpty) {
          final primary = user.stores.firstWhere(
            (s) => s.primary,
            orElse: () => user.stores.first,
          );
          firmCode = primary.firmCode;
        }
      } catch (_) {}

      // Use same acCode logic as order_entry_page
      final acCode = widget.selectedAccount.code ??
          (widget.selectedAccount.acIdCol != null
              ? widget.selectedAccount.acIdCol.toString()
              : widget.selectedAccount.id);

      final payload = {
        'lUserId': mobile,
        'lLicNo': licNo,
        'lFirmCode': firmCode,
        'AcCode': acCode,
      };

      final response = await dio.post(
        '/ListDraftOrder',
        data: payload,
        options: Options(
          headers: {
            'Content-Type': 'application/json',
            'package_name': auth.packageNameHeader,
            if (auth.getAuthHeader() != null)
              'Authorization': auth.getAuthHeader(),
          },
        ),
      );

      final parsed = _parseJson(response.data);

      if (parsed['success'] == true && parsed['data'] != null) {
        final list = (parsed['data']['DraftOrder'] as List<dynamic>?) ?? [];

        // Extract product identifiers - handle both Product objects and Maps
        String productCode = '';
        int productIdCol = 0;

        if (product is Product) {
          productCode = product.code ?? '';
          productIdCol = product.iidcol ?? 0;
        } else if (product is Map) {
          productCode = product['Code']?.toString() ??
              product['code']?.toString() ??
              product['Icode']?.toString() ??
              product['ItemCode']?.toString() ??
              '';
          productIdCol = int.tryParse(product['i_id_col']?.toString() ??
                  product['iidcol']?.toString() ??
                  product['IdCol']?.toString() ??
                  '') ??
              0;
        } else {
          try {
            productCode = product.code ?? '';
            productIdCol = product.iidcol ?? 0;
          } catch (_) {}
        }

        debugPrint('[fetchCartItemDetails] Looking for - Code: $productCode, IdCol: $productIdCol');

        for (final e in list) {
          final code = e['Icode']?.toString() ??
              e['Code']?.toString() ??
              e['ItemCode']?.toString() ??
              '';
          final idCol = int.tryParse(
                  e['IdCol']?.toString() ?? e['Idcol']?.toString() ?? '') ??
              0;

          debugPrint('[fetchCartItemDetails] Checking - Code: $code, IdCol: $idCol');

          bool matches = false;

          if (productIdCol > 0 && idCol > 0) {
            matches = productIdCol == idCol;
            if (matches) debugPrint('[fetchCartItemDetails] Matched by IdCol');
          }

          if (!matches && productCode.isNotEmpty && code.isNotEmpty) {
            matches = productCode == code;
            if (matches) debugPrint('[fetchCartItemDetails] Matched by Code');
          }

          if (matches) {
            int parseQty(dynamic v) => v is int ? v : (v is double ? v.toInt() : (v is num ? v.toInt() : int.tryParse(v?.toString().split('.').first ?? '0') ?? 0));
            return {
              'Qty':     parseQty(e['Qty']),
              'FQty':    parseQty(e['FQty']),
              'SchQty':  (e['SchQty'] is num) ? (e['SchQty'] as num).toDouble() : double.tryParse(e['SchQty']?.toString() ?? '') ?? 0.0,
              'DSchQty': (e['SchDQty'] is num) ? (e['SchDQty'] as num).toDouble() : double.tryParse(e['SchDQty']?.toString() ?? '') ?? 0.0,
              'Rate':    (e['Rate']   is num) ? (e['Rate']   as num).toDouble() : double.tryParse(e['Rate']?.toString()   ?? '') ?? 0.0,
              'Mrp':     (e['Mrp']    is num) ? (e['Mrp']    as num).toDouble() : double.tryParse(e['Mrp']?.toString()    ?? '') ?? 0.0,
              // discount_pcs        → DO_Disc2Per
              'DiscPcs':    (e['DO_Disc2Per'] is num) ? (e['DO_Disc2Per'] as num).toDouble() : double.tryParse(e['DO_Disc2Per']?.toString() ?? '') ?? 0.0,
              // discount_percentage → DO_DiscPer
              'DiscPer':    (e['DO_DiscPer']  is num) ? (e['DO_DiscPer']  as num).toDouble() : double.tryParse(e['DO_DiscPer']?.toString()  ?? '') ?? 0.0,
              // discount_percentage1→ DO_Disc1Per
              'AddDiscPer': (e['DO_Disc1Per'] is num) ? (e['DO_Disc1Per'] as num).toDouble() : double.tryParse(e['DO_Disc1Per']?.toString() ?? '') ?? 0.0,
              'Remark':  e['DO_Remark']?.toString() ?? '',
              'SchNarr': e['SchNarr']?.toString() ?? '',
            };
          }
        }
      }
    } catch (e) {
      debugPrint('Error fetching cart details: $e');
    }

    return {
      'Qty': 0,
      'FQty': 0,
      'SchQty': 0,
      'DSchQty': 0,
      'Rate': 0.0,
      'Mrp': 0.0,
      'DiscPcs': 0.0,
      'DiscPer': 0.0,
      'AddDiscPer': 0.0,
      'Remark': '',
      'SchNarr': '',
    };
  }

  Map<String, dynamic> _parseJson(dynamic raw) {
    if (raw is Map<String, dynamic>) return raw;
    if (raw is String) {
      try {
        final clean = raw.replaceAll(RegExp(r'[\x00-\x1F\x7F]'), '').trim();
        return jsonDecode(clean) as Map<String, dynamic>;
      } catch (_) {
        return {};
      }
    }
    try {
      return jsonDecode(jsonEncode(raw)) as Map<String, dynamic>;
    } catch (_) {
      return {};
    }
  }

  int _getInt(dynamic obj, List<String> keys, {int fallback = 0}) {
    // Handle Product model
    if (obj is Product) {
      for (var k in keys) {
        switch (k) {
          case 'stockQuantity':
          case 'Stock':
          case 'stock':
          case 'quantity':
            return obj.stockQuantity;
          case 'iidcol':
          case 'i_id_col':
          case 'IdCol':
            return obj.iidcol ?? fallback;
          case 'qty':
          case 'Qty':
            return fallback;
        }
      }
    }

    // Handle Map objects
    for (var k in keys) {
      if (obj is Map && obj[k] != null) {
        if (obj[k] is int) return obj[k];
        if (obj[k] is String) return int.tryParse(obj[k]) ?? fallback;
        if (obj[k] is double) return (obj[k] as double).toInt();
      }
    }
    return fallback;
  }

  double _getDouble(dynamic obj, List<String> keys, {double fallback = 0.0}) {
    // Handle Product model
    if (obj is Product) {
      for (var k in keys) {
        switch (k) {
          case 'price':
          case 'Rate':
          case 'Amt':
          case 'amt':
            return obj.price;
          case 'Mrp':
          case 'mrp':
            return obj.mrp;
        }
      }
    }

    // Handle Map objects
    for (var k in keys) {
      if (obj is Map && obj[k] != null) {
        if (obj[k] is double) return obj[k];
        if (obj[k] is int) return (obj[k] as int).toDouble();
        if (obj[k] is String) return double.tryParse(obj[k]) ?? fallback;
      }
    }
    return fallback;
  }

  String _getString(dynamic obj, List<String> keys,
      {String fallback = ''}) {
    // Handle Product model
    if (obj is Product) {
      for (var k in keys) {
        switch (k) {
          case 'name':
          case 'Name':
          case 'ItemName':
          case 'item_name':
          case 'I_NAME':
            return obj.name;
          case 'code':
          case 'Code':
          case 'ItemCode':
          case 'Icode':
          case 'icode':
            return obj.code ?? '';
          case 'manufacturer':
          case 'MfgComp':
          case 'mfgcomp':
          case 'company':
            return obj.manufacturer ?? '';
          case 'unit':
          case 'packing':
          case 'Packing':
          case 'UOM':
          case 'uom':
            return obj.unit;
          case 'salt':
          case 'Salt':
          case 'composition':
          case 'Composition':
            return obj.salt ?? '';
          case 'description':
          case 'Description':
            return obj.description ?? '';
        }
      }
    }

    // Handle Map objects
    for (var k in keys) {
      if (obj is Map && obj[k] != null) {
        return obj[k].toString();
      }
    }
    return fallback;
  }

  Future<void> fetchSimilarProducts() async {
    setState(() => loadingSimilar = true);
    try {
      final auth = Provider.of<AuthService>(context, listen: false);
      final dio = auth.getDioClient();
      String firmCode = '';

      try {
        final stores = auth.currentUser?.stores;
        if (stores != null && stores.isNotEmpty) {
          final primary =
              stores.firstWhere((s) => s.primary == true, orElse: () => stores.first);
          firmCode = primary.firmCode;
        }
      } catch (_) {}

      final payload = {
        'lLicNo': auth.currentUser?.licenseNumber ?? '',
        'lUserId': auth.currentUser?.mobileNumber ??
            auth.currentUser?.userId ??
            '',
        'lFirmCode': firmCode,
        'lPageNo': 1,
        'lSize': -1,
        'lSearchFieldValue': '',
        'lExecuteTotalRows': true,
        'lRateType': 'A',
        'CMIDCOL': -1,
        'IDCOL': 0,
        'Wsch': 0,
        'MCIDCOL': 0,
        'AcCode': _getString(product, ['AcCode', 'Ac_Code'], fallback: ''),
        'NewArrival': false,
        'lSearchFieldName': 'I_NAME',
        'lExcludeId': receivedId,
        'filters': [],
      };

      final headers = {
        'Content-Type': 'application/json',
        'package_name': auth.packageNameHeader,
        if (auth.getAuthHeader() != null)
          'Authorization': auth.getAuthHeader(),
      };

      final response =
          await dio.post('/GetItemList', data: payload, options: Options(headers: headers));

      List<dynamic> items = [];
      dynamic raw = response.data;

      if (raw is String) {
        try {
          final decoded = jsonDecode(raw);
          if (decoded is List) {
            items = decoded;
          } else if (decoded is Map && decoded['data'] is List) {
            items = decoded['data'];
          } else if (decoded is Map && decoded['Item'] is List) {
            items = decoded['Item'];
          } else if (decoded is Map && decoded['items'] is List) {
            items = decoded['items'];
          }
        } catch (_) {}
      } else if (raw is List) {
        items = raw;
      } else if (raw is Map && raw['data'] is List) {
        items = raw['data'];
      } else if (raw is Map && raw['Item'] is List) {
        items = raw['Item'];
      } else if (raw is Map && raw['items'] is List) {
        items = raw['items'];
      }

      setState(() => similarProducts = items);
    } catch (e) {
      debugPrint('Error fetching similar products: $e');
    } finally {
      setState(() => loadingSimilar = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final price = _getDouble(product, ['price', 'Rate', 'Amt', 'amt'], fallback: 0.0);
    final stock = _getInt(product, ['stockQuantity', 'Stock', 'stock', 'quantity'], fallback: 0);
    final manufacturer = _getString(product, ['manufacturer', 'MfgComp', 'mfgcomp', 'company']);
    final packing = _getString(product, ['unit', 'packing', 'Packing', 'UOM', 'uom']);
    final name = _getString(product, ['name', 'Name', 'ItemName', 'item_name', 'I_NAME']);
    final salt = _getString(product, ['salt', 'Salt', 'composition', 'Composition']);

    return Scaffold(
      backgroundColor: colorScheme.surfaceContainerLowest,
      appBar: AppBar(
        title: Text('Product Details',
            style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
        centerTitle: true,
        elevation: 0,
        scrolledUnderElevation: 0,
        backgroundColor: colorScheme.surfaceContainerLowest,
        surfaceTintColor: Colors.transparent,
        actions: [
          Stack(
            alignment: Alignment.center,
            children: [
              IconButton(
                icon: Icon(Icons.shopping_cart_outlined, color: colorScheme.onSurface),
                tooltip: 'Open Cart',
                onPressed: () {
                  final acCode = widget.selectedAccount.code ??
                      (widget.selectedAccount.acIdCol != null
                          ? widget.selectedAccount.acIdCol.toString()
                          : widget.selectedAccount.id);
                  Navigator.of(context).push(MaterialPageRoute(
                    builder: (_) => CartPage(
                      acCode: acCode,
                      selectedAccount: widget.selectedAccount,
                    ),
                  ));
                },
              ),
              if (cartQty > 0)
                Positioned(
                  top: 8,
                  right: 8,
                  child: Container(
                    width: 16,
                    height: 16,
                    decoration: BoxDecoration(
                      color: colorScheme.error,
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        cartQty > 9 ? '9+' : '$cartQty',
                        style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildProductHeroSection(colorScheme, textTheme, price, stock, manufacturer, packing, name),
            if (salt.isNotEmpty) ...[
              const SizedBox(height: 4),
              _buildInfoSection(colorScheme, textTheme, "Composition", salt, Icons.biotech_outlined),
            ],
            const SizedBox(height: 24),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  Container(width: 4, height: 20, decoration: BoxDecoration(color: colorScheme.primary, borderRadius: BorderRadius.circular(2))),
                  const SizedBox(width: 10),
                  Text('Similar Products',
                      style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
                ],
              ),
            ),
            const SizedBox(height: 12),
            _buildSimilarProductsList(colorScheme, textTheme),
            const SizedBox(height: 110),
          ],
        ),
      ),
      bottomNavigationBar: _buildBottomAction(colorScheme, price),
    );
  }

  Widget _buildProductHeroSection(ColorScheme cs, TextTheme tt, double price,
      int stock, String manufacturer, String packing, String name) {
    final mrp = _getDouble(product, ['Mrp', 'mrp'], fallback: 0.0);
    final code = _getString(product, ['code', 'Code', 'Icode', 'icode']);
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.4)),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 12, offset: const Offset(0, 4)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top accent bar
          Container(
            height: 4,
            decoration: BoxDecoration(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
              gradient: LinearGradient(colors: [cs.primary, cs.tertiary]),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Code + stock row
                Row(
                  children: [
                    if (code.isNotEmpty)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: cs.secondaryContainer,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(code,
                            style: tt.labelSmall?.copyWith(
                                color: cs.onSecondaryContainer, fontWeight: FontWeight.w700, letterSpacing: 0.5)),
                      ),
                    if (code.isNotEmpty) const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: stock > 0 ? Colors.green.shade50 : Colors.red.shade50,
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: stock > 0 ? Colors.green.shade200 : Colors.red.shade200),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            stock > 0 ? Icons.check_circle_outline : Icons.cancel_outlined,
                            size: 11,
                            color: stock > 0 ? Colors.green.shade700 : Colors.red.shade700,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            stock > 0 ? 'In Stock: $stock' : 'Out of Stock',
                            style: tt.labelSmall?.copyWith(
                                color: stock > 0 ? Colors.green.shade700 : Colors.red.shade700,
                                fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
                    ),
                    if (packing.isNotEmpty) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: cs.primaryContainer.withValues(alpha: 0.5),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(packing,
                            style: tt.labelSmall?.copyWith(
                                color: cs.onPrimaryContainer, fontWeight: FontWeight.w600)),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 12),
                Text(name.isNotEmpty ? name : 'Product',
                    style: tt.titleLarge?.copyWith(fontWeight: FontWeight.w800, letterSpacing: -0.3, height: 1.25)),
                if (manufacturer.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(manufacturer,
                      style: tt.bodyMedium?.copyWith(color: cs.primary, fontWeight: FontWeight.w600)),
                ],
                const SizedBox(height: 16),
                // Price row
                Row(
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Price', style: tt.labelSmall?.copyWith(color: cs.onSurfaceVariant, letterSpacing: 0.5)),
                        const SizedBox(height: 2),
                        Text('₹${price.toStringAsFixed(2)}',
                            style: tt.headlineSmall?.copyWith(
                                fontWeight: FontWeight.w800, color: cs.onSurface, letterSpacing: -0.5)),
                      ],
                    ),
                    if (mrp > 0) ...[
                      const SizedBox(width: 24),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('MRP', style: tt.labelSmall?.copyWith(color: cs.onSurfaceVariant, letterSpacing: 0.5)),
                          const SizedBox(height: 2),
                          Text('₹${mrp.toStringAsFixed(2)}',
                              style: tt.titleMedium?.copyWith(
                                  fontWeight: FontWeight.w600,
                                  color: cs.onSurfaceVariant,
                                  decoration: TextDecoration.lineThrough)),
                        ],
                      ),
                    ],
                    const Spacer(),
                    if (cartQty > 0)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: cs.primaryContainer,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.shopping_cart_outlined, size: 14, color: cs.onPrimaryContainer),
                            const SizedBox(width: 4),
                            Text('Qty: $cartQty',
                                style: tt.labelMedium?.copyWith(
                                    fontWeight: FontWeight.w700, color: cs.onPrimaryContainer)),
                          ],
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoSection(ColorScheme cs, TextTheme tt, String title, String content, IconData icon) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.4)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: cs.primaryContainer.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: cs.primary, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: tt.labelMedium?.copyWith(
                        fontWeight: FontWeight.w700, color: cs.onSurfaceVariant, letterSpacing: 0.4)),
                const SizedBox(height: 4),
                Text(content, style: tt.bodyMedium?.copyWith(height: 1.4)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSimilarProductsList(ColorScheme cs, TextTheme tt) {
    if (loadingSimilar) {
      return Padding(
        padding: const EdgeInsets.all(24),
        child: Center(child: CircularProgressIndicator(color: cs.primary, strokeWidth: 2)),
      );
    }
    if (similarProducts.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Text('No similar products found.',
            style: tt.bodyMedium?.copyWith(color: cs.onSurfaceVariant)),
      );
    }

    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: similarProducts.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (ctx, idx) {
        final sp = similarProducts[idx];
        final spName = _getString(sp, ['Name', 'name', 'ItemName', 'item_name', 'I_NAME']);
        final spMfg = _getString(sp, ['MfgComp', 'manufacturer', 'mfgcomp', 'company']);
        final spPrice = _getDouble(sp, ['Rate', 'price', 'Amt', 'amt']);
        return GestureDetector(
          onTap: () => Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (_) => ProductDetailPage(product: sp, selectedAccount: widget.selectedAccount),
            ),
          ),
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: cs.surface,
              border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.4)),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 8, offset: const Offset(0, 2)),
              ],
            ),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: cs.secondaryContainer.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(Icons.medication_outlined, size: 20, color: cs.secondary),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(spName, maxLines: 2, overflow: TextOverflow.ellipsis,
                          style: tt.labelLarge?.copyWith(fontWeight: FontWeight.w700)),
                      if (spMfg.isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Text(spMfg, maxLines: 1, overflow: TextOverflow.ellipsis,
                            style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant)),
                      ],
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text('₹${spPrice.toStringAsFixed(2)}',
                        style: tt.titleSmall?.copyWith(color: cs.primary, fontWeight: FontWeight.w700)),
                    const SizedBox(height: 4),
                    Icon(Icons.chevron_right_rounded, size: 16, color: cs.onSurfaceVariant),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildBottomAction(ColorScheme cs, double price) {
    return Container(
      padding: EdgeInsets.fromLTRB(16, 12, 16, MediaQuery.of(context).padding.bottom + 12),
      decoration: BoxDecoration(
        color: cs.surface,
        border: Border(top: BorderSide(color: cs.outlineVariant.withValues(alpha: 0.3))),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 16, offset: const Offset(0, -4)),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Price', style: TextStyle(fontSize: 11, color: cs.onSurfaceVariant, fontWeight: FontWeight.w500)),
                Text('₹${price.toStringAsFixed(2)}',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: cs.onSurface, letterSpacing: -0.5)),
                if (cartQty > 0)
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Text('In cart: $cartQty pcs',
                        style: TextStyle(fontSize: 11, color: cs.primary, fontWeight: FontWeight.w600)),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          SizedBox(
            height: 48,
            child: FilledButton.icon(
              onPressed: _showAddToCartBottomSheet,
              style: FilledButton.styleFrom(
                backgroundColor: cartQty > 0 ? cs.secondary : cs.primary,
                foregroundColor: cartQty > 0 ? cs.onSecondary : cs.onPrimary,
                padding: const EdgeInsets.symmetric(horizontal: 24),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
              icon: Icon(cartQty > 0 ? Icons.edit_outlined : Icons.add_shopping_cart_outlined, size: 18),
              label: Text(
                cartQty > 0 ? 'UPDATE' : 'ADD TO CART',
                style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13, letterSpacing: 0.5),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showAddToCartBottomSheet() async {
    await fetchCartAndSetQty();
    final cartDetails = await fetchCartItemDetails();
    if (!mounted) return;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _KeyboardAwareSheet(
        child: _AddToCartSheet(
          product: product,
          selectedAccount: widget.selectedAccount,
          cartDetails: cartDetails,
          cartQty: cartQty,
          onCartUpdated: () async {
            Navigator.pop(ctx);
            await fetchCartAndSetQty();
            if (mounted) setState(() {});
          },
        ),
      ),
    );
  }

  Widget _buildBottomSheetContent(Map<String, dynamic> cartDetails) => const SizedBox.shrink();

  Widget _infoChip(ColorScheme cs, String label, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: color),
          const SizedBox(width: 4),
          Text(label, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: color)),
        ],
      ),
    );
  }

  Widget _sheetSectionLabel(ColorScheme cs, TextTheme tt, String title) {
    return Row(
      children: [
        Container(width: 3, height: 16, decoration: BoxDecoration(color: cs.primary, borderRadius: BorderRadius.circular(2))),
        const SizedBox(width: 8),
        Text(title,
            style: tt.labelMedium?.copyWith(
                fontWeight: FontWeight.w800, color: cs.primary, letterSpacing: 1.2)),
      ],
    );
  }

  Widget _buildInputField(String label, TextEditingController controller, TextInputType keyboardType,
      VoidCallback onChanged, ColorScheme cs, TextTheme tt) {
    return Row(
      children: [
        Expanded(
          child: Text(label, style: tt.bodyMedium?.copyWith(fontWeight: FontWeight.w600, color: cs.onSurface)),
        ),
        SizedBox(
          width: 130,
          child: TextField(
            controller: controller,
            keyboardType: keyboardType,
            textAlign: TextAlign.right,
            onChanged: (_) => onChanged(),
            style: tt.titleSmall?.copyWith(fontWeight: FontWeight.w700),
            decoration: InputDecoration(
              hintText: '0',
              hintStyle: TextStyle(color: cs.onSurfaceVariant.withValues(alpha: 0.4), fontWeight: FontWeight.normal),
              isDense: true,
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              filled: true,
              fillColor: cs.surfaceContainerHighest.withValues(alpha: 0.5),
              border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(color: cs.outlineVariant.withValues(alpha: 0.3))),
              enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(color: cs.outlineVariant.withValues(alpha: 0.3))),
              focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(color: cs.primary, width: 2)),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSchemeInput(TextEditingController schQtyCtrl, TextEditingController dSchQtyCtrl,
      VoidCallback onChanged, ColorScheme cs, TextTheme tt) {
    InputDecoration schemeDeco(String hint) => InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(color: cs.onSurfaceVariant.withValues(alpha: 0.4), fontWeight: FontWeight.normal),
      isDense: true,
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      filled: true,
      fillColor: cs.surfaceContainerHighest.withValues(alpha: 0.5),
      border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: cs.outlineVariant.withValues(alpha: 0.3))),
      enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: cs.outlineVariant.withValues(alpha: 0.3))),
      focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: cs.primary, width: 2)),
    );

    return Row(
      children: [
        Expanded(
          child: Text('Scheme', style: tt.bodyMedium?.copyWith(fontWeight: FontWeight.w600, color: cs.onSurface)),
        ),
        SizedBox(
          width: 56,
          child: TextField(
            controller: schQtyCtrl,
            keyboardType: TextInputType.number,
            textAlign: TextAlign.center,
            onChanged: (_) => onChanged(),
            style: tt.titleSmall?.copyWith(fontWeight: FontWeight.w700),
            decoration: schemeDeco('0'),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 6),
          child: Text('+', style: tt.titleMedium?.copyWith(fontWeight: FontWeight.w700, color: cs.primary)),
        ),
        SizedBox(
          width: 56,
          child: TextField(
            controller: dSchQtyCtrl,
            keyboardType: TextInputType.number,
            textAlign: TextAlign.center,
            onChanged: (_) => onChanged(),
            style: tt.titleSmall?.copyWith(fontWeight: FontWeight.w700),
            decoration: schemeDeco('0'),
          ),
        ),
      ],
    );
  }

  Widget _buildInputFieldWithAmount(String label, TextEditingController controller, double amount,
      VoidCallback onChanged, ColorScheme cs, TextTheme tt) {
    final bool hasAmount = amount > 0;
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: tt.bodyMedium?.copyWith(fontWeight: FontWeight.w600, color: cs.onSurface)),
              const SizedBox(height: 4),
              // API-returned amount shown as a small colored badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                decoration: BoxDecoration(
                  color: hasAmount
                      ? Colors.red.shade50
                      : cs.surfaceContainerHighest.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(
                    color: hasAmount
                        ? Colors.red.shade200
                        : cs.outlineVariant.withValues(alpha: 0.4),
                    width: 0.8,
                  ),
                ),
                child: Text(
                  '- ₹${amount.toStringAsFixed(2)}',
                  style: tt.labelSmall?.copyWith(
                    color: hasAmount ? Colors.red.shade700 : cs.outline,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.2,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        SizedBox(
          width: 130,
          child: TextField(
            controller: controller,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            textAlign: TextAlign.right,
            onChanged: (_) => onChanged(),
            style: tt.titleSmall?.copyWith(fontWeight: FontWeight.w700),
            decoration: InputDecoration(
              hintText: '0',
              hintStyle: TextStyle(color: cs.onSurfaceVariant.withValues(alpha: 0.4), fontWeight: FontWeight.normal),
              isDense: true,
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              filled: true,
              fillColor: cs.surfaceContainerHighest.withValues(alpha: 0.5),
              border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(color: cs.outlineVariant.withValues(alpha: 0.3))),
              enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(color: cs.outlineVariant.withValues(alpha: 0.3))),
              focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(color: cs.primary, width: 2)),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildRemarkField(TextEditingController controller, String label, ColorScheme cs, TextTheme tt) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: tt.bodyMedium?.copyWith(fontWeight: FontWeight.w600, color: cs.onSurface)),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          maxLength: 200,
          maxLines: 2,
          style: tt.bodyMedium,
          decoration: InputDecoration(
            hintText: 'Type here...',
            hintStyle: TextStyle(color: cs.onSurfaceVariant.withValues(alpha: 0.4)),
            contentPadding: const EdgeInsets.all(12),
            isDense: true,
            filled: true,
            fillColor: cs.surfaceContainerHighest.withValues(alpha: 0.5),
            border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(color: cs.outlineVariant.withValues(alpha: 0.3))),
            enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(color: cs.outlineVariant.withValues(alpha: 0.3))),
            focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(color: cs.primary, width: 2)),
            counterText: '',
          ),
        ),
      ],
    );
  }

  Widget _buildSummaryCard(double goodsValue, double schemeValue, double discountValue,
      double gst, double netValue, ColorScheme cs, TextTheme tt) {
    return Container(
      decoration: BoxDecoration(
        color: cs.surfaceContainerLow,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
            child: Column(
              children: [
                _summaryRow(cs, tt, 'Goods Value', '₹${goodsValue.toStringAsFixed(2)}', isHighlight: false),
                const SizedBox(height: 8),
                _summaryRow(cs, tt, 'Scheme Value', '₹${schemeValue.toStringAsFixed(2)}', isHighlight: false),
                const SizedBox(height: 8),
                _summaryRow(cs, tt, 'Discount Value', '-₹${discountValue.toStringAsFixed(2)}', isHighlight: false, isNegative: true),
                const SizedBox(height: 8),
                _summaryRow(cs, tt, 'GST % (EXCLUSIVE)', '₹${gst.toStringAsFixed(2)}', isHighlight: false),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: cs.primary.withValues(alpha: 0.08),
              borderRadius: const BorderRadius.vertical(bottom: Radius.circular(16)),
              border: Border(top: BorderSide(color: cs.primary.withValues(alpha: 0.15))),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Net Value',
                    style: tt.titleSmall?.copyWith(fontWeight: FontWeight.w800, color: cs.primary)),
                Text('₹${netValue.toStringAsFixed(2)}',
                    style: tt.titleLarge?.copyWith(fontWeight: FontWeight.w900, color: cs.primary, letterSpacing: -0.5)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _summaryRow(ColorScheme cs, TextTheme tt, String label, String value,
      {bool isHighlight = false, bool isNegative = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label,
            style: tt.bodySmall?.copyWith(
                color: cs.onSurfaceVariant, fontWeight: FontWeight.w500)),
        Text(value,
            style: tt.bodyMedium?.copyWith(
                fontWeight: FontWeight.w700,
                color: isNegative ? Colors.red.shade600 : cs.onSurface)),
      ],
    );
  }

  Widget _buildActionButtons(ColorScheme cs, TextTheme tt,
      TextEditingController qtyCtrl, TextEditingController fQtyCtrl,
      TextEditingController schQtyCtrl, TextEditingController dSchQtyCtrl,
      TextEditingController priceCtrl, TextEditingController discPcsCtrl,
      TextEditingController discPerCtrl, TextEditingController addDiscPerCtrl,
      TextEditingController schNarrCtrl, TextEditingController remarkCtrl) {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton(
            onPressed: () => Navigator.pop(context),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 14),
              side: BorderSide(color: cs.outlineVariant),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: Text('CLOSE',
                style: tt.labelLarge?.copyWith(fontWeight: FontWeight.w700, letterSpacing: 0.8)),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          flex: 2,
          child: FilledButton(
            onPressed: () => _addToCart(qtyCtrl, fQtyCtrl, schQtyCtrl, dSchQtyCtrl,
                priceCtrl, discPcsCtrl, discPerCtrl, addDiscPerCtrl, schNarrCtrl, remarkCtrl),
            style: FilledButton.styleFrom(
              backgroundColor: cartQty > 0 ? cs.secondary : cs.primary,
              foregroundColor: cartQty > 0 ? cs.onSecondary : cs.onPrimary,
              padding: const EdgeInsets.symmetric(vertical: 14),
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: Text(
              cartQty > 0 ? 'UPDATE CART' : 'ADD TO CART',
              style: tt.labelLarge?.copyWith(fontWeight: FontWeight.w800, letterSpacing: 0.8,
                  color: cartQty > 0 ? cs.onSecondary : cs.onPrimary),
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _addToCart(
    TextEditingController qtyCtrl,
    TextEditingController fQtyCtrl,
    TextEditingController schQtyCtrl,
    TextEditingController dSchQtyCtrl,
    TextEditingController priceCtrl,
    TextEditingController discPcsCtrl,
    TextEditingController discPerCtrl,
    TextEditingController addDiscPerCtrl,
    TextEditingController schNarrCtrl,
    TextEditingController remarkCtrl,
  ) async {
    try {
      final auth = Provider.of<AuthService>(context, listen: false);
      final dio = auth.getDioClient();
      final user = auth.currentUser;

      // Get firmCode from user stores (same as order_entry_page)
      String firmCode = '';
      try {
        final stores = user?.stores;
        if (stores != null && stores.isNotEmpty) {
          final primary = stores.firstWhere((s) => s.primary == true, orElse: () => stores.first);
          firmCode = primary.firmCode;
        }
      } catch (_) {}

      final acCode = widget.selectedAccount.code ??
          (widget.selectedAccount.acIdCol != null
              ? widget.selectedAccount.acIdCol.toString()
              : widget.selectedAccount.id);

      String itemCode = '';
      int idCol = 0;
      if (product is Product) {
        itemCode = product.code ?? product.id;
        idCol = product.iidcol ?? int.tryParse(product.id) ?? 0;
      } else if (product is Map) {
        itemCode = product['Icode']?.toString() ??
            product['icode']?.toString() ??
            product['Code']?.toString() ??
            product['code']?.toString() ??
            '';
        idCol = int.tryParse(
                product['i_id_col']?.toString() ??
                    product['iidcol']?.toString() ??
                    product['IdCol']?.toString() ??
                    '') ??
            0;
      } else {
        try {
          itemCode = product.code ?? '';
          idCol = product.iidcol ?? 0;
        } catch (_) {}
      }

      final qty = int.tryParse(qtyCtrl.text) ?? 1;
      final usedPrice = double.tryParse(priceCtrl.text) ?? 0.0;

      final request = _buildDraftOrderRequest(
        itemCode: itemCode,
        idCol: idCol,
        qty: qtyCtrl.text.trim(),
        rate: usedPrice.toStringAsFixed(2),
        freeQty: fQtyCtrl.text.trim(),
        schemeQty: schQtyCtrl.text.trim(),
        dSchemeQty: dSchQtyCtrl.text.trim(),
        itemAmt: (usedPrice * qty).toStringAsFixed(2),
        discountPer: discPerCtrl.text.trim(),
        addDiscountPer: addDiscPerCtrl.text.trim(),
        discountPcs: discPcsCtrl.text.trim(),
        remark: remarkCtrl.text.trim(),
        insertRecord: 1,
      );

      final result = await _draftOrderServiceFor(acCode).insert(request);
      if (!result.success) {
        throw Exception(result.message.isNotEmpty ? result.message : 'Failed to add item');
      }

      if (mounted) {
        Navigator.pop(context);
        await fetchCartAndSetQty();
        if (mounted) {
          setState(() {});
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Item added to cart')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to add: $e')),
        );
      }
      debugPrint('Error adding to cart: $e');
    }
  }

  DraftOrderService _draftOrderServiceFor(String acCode) {
    final auth = Provider.of<AuthService>(context, listen: false);
    return DraftOrderService(
      dio: auth.getDioClient(),
      context: DraftOrderContext.fromAuth(auth: auth, acCode: acCode),
    );
  }

  DraftOrderRequest _buildDraftOrderRequest({
    required String itemCode,
    required int idCol,
    required String qty,
    required String rate,
    required String freeQty,
    required String schemeQty,
    required String dSchemeQty,
    required String itemAmt,
    required String discountPer,
    required String addDiscountPer,
    required String discountPcs,
    required String remark,
    required int insertRecord,
  }) {
    return DraftOrderRequest(
      itemCode: itemCode,
      idCol: idCol,
      itemQty: qty,
      itemRate: rate,
      itemFQty: freeQty.isEmpty ? '0' : freeQty,
      itemSchQty: schemeQty.isEmpty ? '0' : schemeQty,
      itemDSchQty: dSchemeQty.isEmpty ? '0' : dSchemeQty,
      itemAmt: itemAmt,
      discountPercentage: discountPer,
      discountPercentage1: addDiscountPer,
      discountPcs: discountPcs,
      remark: remark,
      insertRecord: insertRecord,
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Keyboard-aware wrapper — isolates viewInsets so sheet never resets on KB dismiss
// ─────────────────────────────────────────────────────────────────────────────
class _KeyboardAwareSheet extends StatelessWidget {
  final Widget child;
  const _KeyboardAwareSheet({required this.child});
  @override
  Widget build(BuildContext context) => AnimatedPadding(
    duration: const Duration(milliseconds: 150),
    curve: Curves.easeOut,
    padding: MediaQuery.of(context).viewInsets,
    child: child,
  );
}

// ─────────────────────────────────────────────────────────────────────────────
// Add/Update cart bottom sheet — StatefulWidget so controllers live in initState
// ─────────────────────────────────────────────────────────────────────────────
class _AddToCartSheet extends StatefulWidget {
  final dynamic product;
  final dynamic selectedAccount;
  final Map<String, dynamic> cartDetails;
  final int cartQty;
  final VoidCallback onCartUpdated;

  const _AddToCartSheet({
    required this.product,
    required this.selectedAccount,
    required this.cartDetails,
    required this.cartQty,
    required this.onCartUpdated,
  });

  @override
  State<_AddToCartSheet> createState() => _AddToCartSheetState();
}

class _AddToCartSheetState extends State<_AddToCartSheet> {
  late final TextEditingController qtyCtrl;
  late final TextEditingController fQtyCtrl;
  late final TextEditingController schQtyCtrl;
  late final TextEditingController dSchQtyCtrl;
  late final TextEditingController priceCtrl;
  late final TextEditingController discPcsCtrl;
  late final TextEditingController discPerCtrl;
  late final TextEditingController addDiscPerCtrl;
  late final TextEditingController schNarrCtrl;
  late final TextEditingController remarkCtrl;

  double goodsValue = 0, schemeValue = 0, discountValue = 0, gst = 0, netValue = 0;
  DraftOrderPreviewResult? preview;
  Timer? _debounce;
  int _token = 0;
  bool _loading = false;
  bool _firstBuild = true;

  @override
  void initState() {
    super.initState();
    final d = widget.cartDetails;
    double sd(dynamic v) => v is double ? v : (v is int ? v.toDouble() : double.tryParse(v?.toString() ?? '') ?? 0.0);
    int si(dynamic v) => v is int ? v : (v is double ? v.toInt() : int.tryParse(v?.toString() ?? '') ?? 0);

    final p = widget.product;
    final price = p is Product ? p.price : sd(p is Map ? (p['Rate'] ?? p['price']) : 0.0);

    qtyCtrl        = TextEditingController(text: si(d['Qty']).toString());
    fQtyCtrl       = TextEditingController(text: si(d['FQty']).toString());
    schQtyCtrl     = TextEditingController(text: sd(d['SchQty']).toStringAsFixed(0));
    dSchQtyCtrl    = TextEditingController(text: sd(d['DSchQty']).toStringAsFixed(0));
    priceCtrl      = TextEditingController(text: sd(d['Rate']) > 0 ? sd(d['Rate']).toStringAsFixed(2) : price.toStringAsFixed(2));
    discPcsCtrl    = TextEditingController(text: sd(d['DiscPcs']).toString());
    discPerCtrl    = TextEditingController(text: sd(d['DiscPer']).toString());
    addDiscPerCtrl = TextEditingController(text: sd(d['AddDiscPer']).toString());
    schNarrCtrl    = TextEditingController(text: d['SchNarr']?.toString() ?? '');
    remarkCtrl     = TextEditingController(text: d['Remark']?.toString() ?? '');
  }

  @override
  void dispose() {
    qtyCtrl.dispose(); fQtyCtrl.dispose(); schQtyCtrl.dispose();
    dSchQtyCtrl.dispose(); priceCtrl.dispose(); discPcsCtrl.dispose();
    discPerCtrl.dispose(); addDiscPerCtrl.dispose();
    schNarrCtrl.dispose(); remarkCtrl.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  String get _acCode {
    final acc = widget.selectedAccount;
    try {
      return acc.code ?? (acc.acIdCol != null ? acc.acIdCol.toString() : acc.id ?? '');
    } catch (_) { return ''; }
  }

  void _resolveProductIds(void Function(String code, int idCol) cb) {
    final p = widget.product;
    String code = ''; int idCol = 0;
    if (p is Product) {
      code = p.code ?? p.id;
      idCol = p.iidcol ?? int.tryParse(p.id) ?? 0;
    } else if (p is Map) {
      code = p['Icode']?.toString() ?? p['Code']?.toString() ?? p['code']?.toString() ?? '';
      idCol = int.tryParse(p['i_id_col']?.toString() ?? p['iidcol']?.toString() ?? p['IdCol']?.toString() ?? '') ?? 0;
    } else {
      try { code = p.code ?? ''; idCol = p.iidcol ?? 0; } catch (_) {}
    }
    cb(code, idCol);
  }

  DraftOrderService _service() {
    final auth = Provider.of<AuthService>(context, listen: false);
    return DraftOrderService(
      dio: auth.getDioClient(),
      context: DraftOrderContext.fromAuth(auth: auth, acCode: _acCode),
    );
  }

  DraftOrderRequest _buildRequest(int insertRecord) {
    String code = ''; int idCol = 0;
    _resolveProductIds((c, i) { code = c; idCol = i; });
    final qty  = int.tryParse(qtyCtrl.text.trim()) ?? 0;
    final rate = double.tryParse(priceCtrl.text.trim()) ?? 0.0;
    return DraftOrderRequest(
      itemCode: code, idCol: idCol,
      itemQty: qtyCtrl.text.trim(),
      itemRate: rate.toStringAsFixed(2),
      itemFQty:    fQtyCtrl.text.trim().isEmpty    ? '0' : fQtyCtrl.text.trim(),
      itemSchQty:  schQtyCtrl.text.trim().isEmpty  ? '0' : schQtyCtrl.text.trim(),
      itemDSchQty: dSchQtyCtrl.text.trim().isEmpty ? '0' : dSchQtyCtrl.text.trim(),
      itemAmt: (rate * qty).toStringAsFixed(2),
      discountPercentage:  discPerCtrl.text.trim(),
      discountPercentage1: addDiscPerCtrl.text.trim(),
      discountPcs:         discPcsCtrl.text.trim(),
      remark:              remarkCtrl.text.trim(),
      insertRecord:        insertRecord,
    );
  }

  void _onChanged() {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 350), () async {
      final qty = int.tryParse(qtyCtrl.text.trim()) ?? 0;
      if (qty <= 0) {
        if (mounted) setState(() { goodsValue = 0; schemeValue = 0; discountValue = 0; gst = 0; netValue = 0; preview = null; _loading = false; });
        return;
      }
      final t = ++_token;
      if (mounted) setState(() => _loading = true);
      try {
        final result = await _service().calculate(_buildRequest(0));
        if (!mounted || t != _token) return;
        setState(() {
          preview = result;
          goodsValue = result.amt; schemeValue = result.schemeAmt;
          discountValue = result.totalDisc; gst = result.taxAmt; netValue = result.netAmt;
          _loading = false;
        });
      } catch (_) {
        if (mounted) setState(() => _loading = false);
      }
    });
  }

  Future<void> _submit() async {
    try {
      final result = await _service().insert(_buildRequest(1));
      if (!result.success) throw Exception(result.message.isNotEmpty ? result.message : 'Failed');
      widget.onCartUpdated();
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    if (_firstBuild) {
      _firstBuild = false;
      if ((int.tryParse(qtyCtrl.text) ?? 0) > 0) {
        WidgetsBinding.instance.addPostFrameCallback((_) => _onChanged());
      }
    }

    final p = widget.product;
    final name  = p is Product ? p.name : (p is Map ? (p['Name'] ?? p['name'] ?? '') : '');
    final mfg   = p is Product ? (p.manufacturer ?? '') : (p is Map ? (p['MfgComp'] ?? '') : '');
    final price = p is Product ? p.price : (p is Map ? (double.tryParse(p['Rate']?.toString() ?? '') ?? 0.0) : 0.0);
    final mrp   = p is Product ? p.mrp   : (p is Map ? (double.tryParse(p['Mrp']?.toString()  ?? '') ?? 0.0) : 0.0);
    final stock = p is Product ? p.stockQuantity : (p is Map ? (int.tryParse(p['Stock']?.toString() ?? '') ?? 0) : 0);

    InputDecoration fieldDeco({String hint = '0'}) => InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(color: cs.onSurfaceVariant.withValues(alpha: 0.4)),
      isDense: true,
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      filled: true,
      fillColor: cs.surfaceContainerHighest.withValues(alpha: 0.5),
      border:        OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: cs.outlineVariant.withValues(alpha: 0.3))),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: cs.outlineVariant.withValues(alpha: 0.3))),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: cs.primary, width: 2)),
    );

    Widget rowField(String label, TextEditingController ctrl, TextInputType kb) => Row(
      children: [
        Expanded(child: Text(label, style: tt.bodyMedium?.copyWith(fontWeight: FontWeight.w600))),
        SizedBox(width: 130, child: TextField(controller: ctrl, keyboardType: kb, textAlign: TextAlign.right, onChanged: (_) => _onChanged(), style: tt.titleSmall?.copyWith(fontWeight: FontWeight.w700), decoration: fieldDeco())),
      ],
    );

    Widget rowFieldAmt(String label, TextEditingController ctrl, double amt) {
      final has = amt > 0;
      return Row(children: [
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(label, style: tt.bodyMedium?.copyWith(fontWeight: FontWeight.w600)),
          const SizedBox(height: 4),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
            decoration: BoxDecoration(color: has ? Colors.red.shade50 : cs.surfaceContainerHighest.withValues(alpha: 0.5), borderRadius: BorderRadius.circular(6), border: Border.all(color: has ? Colors.red.shade200 : cs.outlineVariant.withValues(alpha: 0.4), width: 0.8)),
            child: Text('- ₹${amt.toStringAsFixed(2)}', style: tt.labelSmall?.copyWith(color: has ? Colors.red.shade700 : cs.outline, fontWeight: FontWeight.w700)),
          ),
        ])),
        const SizedBox(width: 12),
        SizedBox(width: 130, child: TextField(controller: ctrl, keyboardType: const TextInputType.numberWithOptions(decimal: true), textAlign: TextAlign.right, onChanged: (_) => _onChanged(), style: tt.titleSmall?.copyWith(fontWeight: FontWeight.w700), decoration: fieldDeco())),
      ]);
    }

    Widget sLabel(String t) => Row(children: [
      Container(width: 3, height: 16, decoration: BoxDecoration(color: cs.primary, borderRadius: BorderRadius.circular(2))),
      const SizedBox(width: 8),
      Text(t, style: tt.labelMedium?.copyWith(fontWeight: FontWeight.w800, color: cs.primary, letterSpacing: 1.2)),
    ]);

    Widget infoChip(String label, IconData icon, Color color) => Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(20), border: Border.all(color: color.withValues(alpha: 0.25))),
      child: Row(mainAxisSize: MainAxisSize.min, children: [Icon(icon, size: 13, color: color), const SizedBox(width: 4), Text(label, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: color))]),
    );

    return Container(
      decoration: BoxDecoration(color: cs.surface, borderRadius: const BorderRadius.vertical(top: Radius.circular(24))),
      child: DraggableScrollableSheet(
        expand: false, initialChildSize: 0.92, minChildSize: 0.5, maxChildSize: 0.95,
        builder: (ctx, scroll) => Column(children: [
          Container(margin: const EdgeInsets.only(top: 12, bottom: 4), width: 40, height: 4, decoration: BoxDecoration(color: cs.outlineVariant, borderRadius: BorderRadius.circular(2))),
          Padding(padding: const EdgeInsets.fromLTRB(20, 8, 12, 12), child: Row(children: [
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(name.toString(), style: tt.titleMedium?.copyWith(fontWeight: FontWeight.w800), maxLines: 2, overflow: TextOverflow.ellipsis),
              const SizedBox(height: 2),
              Text(mfg.toString(), style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant)),
            ])),
            IconButton.filledTonal(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.close_rounded, size: 18), style: IconButton.styleFrom(minimumSize: const Size(36, 36), padding: EdgeInsets.zero)),
          ])),
          Padding(padding: const EdgeInsets.fromLTRB(20, 0, 20, 12), child: Wrap(spacing: 8, runSpacing: 6, children: [
            infoChip('₹${price.toStringAsFixed(2)}', Icons.sell_outlined, cs.primary),
            if (mrp > 0) infoChip('MRP ₹${mrp.toStringAsFixed(2)}', Icons.price_change_outlined, cs.secondary),
            infoChip(stock > 0 ? 'Stock: $stock' : 'Out of Stock', stock > 0 ? Icons.inventory_2_outlined : Icons.remove_shopping_cart_outlined, stock > 0 ? Colors.green.shade600 : cs.error),
          ])),
          Divider(height: 1, thickness: 0.5, color: cs.outlineVariant),
          Expanded(child: SingleChildScrollView(
            controller: scroll,
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              sLabel('ORDER DETAILS'), const SizedBox(height: 14),
              rowField('Quantity', qtyCtrl, TextInputType.number), const SizedBox(height: 12),
              rowField('Free Quantity', fQtyCtrl, TextInputType.number), const SizedBox(height: 12),
              Row(children: [
                Expanded(child: Text('Scheme', style: tt.bodyMedium?.copyWith(fontWeight: FontWeight.w600))),
                SizedBox(width: 56, child: TextField(controller: schQtyCtrl, keyboardType: TextInputType.number, textAlign: TextAlign.center, onChanged: (_) => _onChanged(), style: tt.titleSmall?.copyWith(fontWeight: FontWeight.w700), decoration: fieldDeco(hint: '0'))),
                Padding(padding: const EdgeInsets.symmetric(horizontal: 6), child: Text('+', style: tt.titleMedium?.copyWith(fontWeight: FontWeight.w700, color: cs.primary))),
                SizedBox(width: 56, child: TextField(controller: dSchQtyCtrl, keyboardType: TextInputType.number, textAlign: TextAlign.center, onChanged: (_) => _onChanged(), style: tt.titleSmall?.copyWith(fontWeight: FontWeight.w700), decoration: fieldDeco(hint: '0'))),
              ]),
              const SizedBox(height: 12),
              rowField('Price', priceCtrl, const TextInputType.numberWithOptions(decimal: true)),
              const SizedBox(height: 20),
              sLabel('DISCOUNTS'), const SizedBox(height: 14),
              rowFieldAmt('Discount (Pcs)', discPcsCtrl, preview?.discAmt ?? 0.0), const SizedBox(height: 12),
              rowFieldAmt('Discount (%)', discPerCtrl, preview?.disc1Amt ?? 0.0), const SizedBox(height: 12),
              rowFieldAmt('Add. Discount (%)', addDiscPerCtrl, preview?.disc2Amt ?? 0.0),
              const SizedBox(height: 20),
              Text('Add Remark (Optional)', style: tt.bodyMedium?.copyWith(fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              TextField(controller: remarkCtrl, maxLength: 200, maxLines: 2, style: tt.bodyMedium,
                decoration: fieldDeco(hint: 'Type here...').copyWith(counterText: '', contentPadding: const EdgeInsets.all(12))),
              const SizedBox(height: 24),
              // Summary
              Container(
                decoration: BoxDecoration(color: cs.surfaceContainerLow, borderRadius: BorderRadius.circular(16), border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.3))),
                child: Column(children: [
                  Padding(padding: const EdgeInsets.fromLTRB(16, 14, 16, 10), child: Column(children: [
                    _sr(cs, tt, 'Goods Value',    '₹${goodsValue.toStringAsFixed(2)}'),   const SizedBox(height: 8),
                    _sr(cs, tt, 'Scheme Value',   '₹${schemeValue.toStringAsFixed(2)}'),  const SizedBox(height: 8),
                    _sr(cs, tt, 'Discount Value', '-₹${discountValue.toStringAsFixed(2)}', neg: true), const SizedBox(height: 8),
                    _sr(cs, tt, 'GST (Excl.)',    '₹${gst.toStringAsFixed(2)}'),
                  ])),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    decoration: BoxDecoration(color: cs.primary.withValues(alpha: 0.08), borderRadius: const BorderRadius.vertical(bottom: Radius.circular(16)), border: Border(top: BorderSide(color: cs.primary.withValues(alpha: 0.15)))),
                    child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                      Text('Net Value', style: tt.titleSmall?.copyWith(fontWeight: FontWeight.w800, color: cs.primary)),
                      Text('₹${netValue.toStringAsFixed(2)}', style: tt.titleLarge?.copyWith(fontWeight: FontWeight.w900, color: cs.primary, letterSpacing: -0.5)),
                    ]),
                  ),
                ]),
              ),
              if (_loading) ...[const SizedBox(height: 12), const LinearProgressIndicator(minHeight: 3)],
              const SizedBox(height: 24),
              Row(children: [
                Expanded(child: OutlinedButton(
                  onPressed: () => Navigator.pop(context),
                  style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 14), side: BorderSide(color: cs.outlineVariant), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                  child: Text('CLOSE', style: tt.labelLarge?.copyWith(fontWeight: FontWeight.w700, letterSpacing: 0.8)),
                )),
                const SizedBox(width: 12),
                Expanded(flex: 2, child: FilledButton(
                  onPressed: _submit,
                  style: FilledButton.styleFrom(
                    backgroundColor: widget.cartQty > 0 ? cs.secondary : cs.primary,
                    foregroundColor: widget.cartQty > 0 ? cs.onSecondary : cs.onPrimary,
                    padding: const EdgeInsets.symmetric(vertical: 14), elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: Text(widget.cartQty > 0 ? 'UPDATE CART' : 'ADD TO CART', style: tt.labelLarge?.copyWith(fontWeight: FontWeight.w800, letterSpacing: 0.8)),
                )),
              ]),
            ]),
          )),
        ]),
      ),
    );
  }

  Widget _sr(ColorScheme cs, TextTheme tt, String label, String value, {bool neg = false}) => Row(
    mainAxisAlignment: MainAxisAlignment.spaceBetween,
    children: [
      Text(label, style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant, fontWeight: FontWeight.w500)),
      Text(value, style: tt.bodyMedium?.copyWith(fontWeight: FontWeight.w700, color: neg ? Colors.red.shade600 : cs.onSurface)),
    ],
  );
}

