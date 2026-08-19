import 'package:flutter/material.dart';
import '../constants/branding.dart';
import 'package:dio/dio.dart';
import 'package:provider/provider.dart';
import '../auth_service.dart';
import 'dart:convert';
import '../models/account_model.dart' as models;
import '../models/product_model.dart';
import 'cart_page.dart';
import 'dart:async';
import '../services/draft_order_service.dart';
import '../services/salesman_flags_service.dart';
import '../widgets/quick_quantity_adjuster.dart';

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
      debugPrint('[fetchCartAndSetQty] Raw response: $parsed');
      int foundQty = 0;

      if (parsed['success'] == true && parsed['data'] != null) {
        final list = (parsed['data']['DraftOrder'] as List<dynamic>?) ?? [];
        debugPrint('[fetchCartAndSetQty] Cart has ${list.length} items');

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

        debugPrint('[fetchCartAndSetQty] Looking for - Code: $productCode, IdCol: $productIdCol');

        for (final e in list) {
          final idCol = int.tryParse(
                  e['IdCol']?.toString() ?? e['Idcol']?.toString() ?? '') ??
              0;
          final code = e['Icode']?.toString() ??
              e['Code']?.toString() ??
              e['ItemCode']?.toString() ??
              '';

          debugPrint('[fetchCartAndSetQty] Cart item - Code: $code, IdCol: $idCol, Qty: ${e['Qty']}');

          bool matches = false;
          if (productIdCol > 0 && idCol > 0) {
            matches = productIdCol == idCol;
            if (matches) debugPrint('[fetchCartAndSetQty] ✓ Matched by IdCol');
          }
          if (!matches && productCode.isNotEmpty && code.isNotEmpty) {
            matches = productCode == code;
            if (matches) debugPrint('[fetchCartAndSetQty] ✓ Matched by Code');
          }

          if (matches) {
            // Parse as double first, then convert to int (handles both "1" and "1.0")
            final qtyValue = double.tryParse(e['Qty']?.toString() ?? '0') ?? 0.0;
            foundQty = qtyValue.toInt();
            debugPrint('[fetchCartAndSetQty] Found quantity: $foundQty (raw: ${e['Qty']})');
            break;
          }
        }

        if (foundQty == 0) {
          debugPrint('[fetchCartAndSetQty] ✗ Product NOT found in cart');
        }
      }

      if (mounted) {
        setState(() {
          cartQty = foundQty;
          debugPrint('[fetchCartAndSetQty] Updated cartQty to: $cartQty');
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
              'DiscPcs':    (e['DO_Disc2Per'] is num) ? (e['DO_Disc2Per'] as num).toDouble() : double.tryParse(e['DO_Disc2Per']?.toString() ?? '') ?? 0.0,
              'DiscPer':    (e['DO_DiscPer']  is num) ? (e['DO_DiscPer']  as num).toDouble() : double.tryParse(e['DO_DiscPer']?.toString()  ?? '') ?? 0.0,
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

      debugPrint('[SimilarProducts] /GetItemList raw response: $raw');

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

      if (items.isNotEmpty && items.first is Map) {
        debugPrint('[SimilarProducts] count: ${items.length} | first item keys: '
            '${(items.first as Map).keys.toList()}');
        debugPrint('[SimilarProducts] first item: ${items.first}');
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
        title: Text('PRODUCT DETAILS',
            style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700, color: Colors.white)),
        centerTitle: true,
        elevation: 0,
        scrolledUnderElevation: 0,
        backgroundColor: Branding.primary,
        surfaceTintColor: Colors.transparent,
        actions: [
          Stack(
            alignment: Alignment.center,
            children: [
              IconButton(
                icon: const Icon(Icons.shopping_cart_outlined, color: Colors.white),
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
        final spMrp = _getDouble(sp, ['Mrp', 'mrp', 'MRP']);
        final spPacking = _getString(sp, ['packing', 'Packing', 'unit', 'UOM']);
        // fallback -1 => the API did not return a stock value for this item.
        final spStock = _getInt(sp, ['Stock', 'stock', 'stockQuantity', 'quantity'], fallback: -1);
        // Respect the per-item visibility flags GetItemList returns.
        final showSpStock = spStock >= 0 && sp is Map && sp['ShowStock'] == true;
        final showSpMrp = spMrp > 0 && sp is Map && sp['ShowMrp'] == true;
        final showSpRate = sp is Map && sp['ShowRate'] == true;
        final spInStock = spStock > 0;
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
                      if (showSpStock || spPacking.isNotEmpty) ...[
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            if (showSpStock)
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: (spInStock ? Colors.green : cs.error).withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  spInStock ? 'Stock: $spStock' : 'Out of stock',
                                  style: tt.labelSmall?.copyWith(
                                    fontWeight: FontWeight.w700,
                                    color: spInStock ? Colors.green.shade700 : cs.error,
                                  ),
                                ),
                              ),
                            if (showSpStock && spPacking.isNotEmpty) const SizedBox(width: 6),
                            if (spPacking.isNotEmpty)
                              Flexible(
                                child: Text(spPacking, maxLines: 1, overflow: TextOverflow.ellipsis,
                                    style: tt.labelSmall?.copyWith(color: cs.onSurfaceVariant)),
                              ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (showSpRate)
                      Text('₹${spPrice.toStringAsFixed(2)}',
                          style: tt.titleSmall?.copyWith(color: cs.primary, fontWeight: FontWeight.w700)),
                    if (showSpMrp) ...[
                      if (showSpRate) const SizedBox(height: 2),
                      Text('MRP ₹${spMrp.toStringAsFixed(2)}',
                          style: tt.labelSmall?.copyWith(color: cs.onSurfaceVariant)),
                    ],
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
    debugPrint('[_buildBottomAction] Building with cartQty = $cartQty');
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
          // If Showadddetailsbottomsheet_SalesMan is FALSE: Show only -/+ button, hide Add/Update
          if (!(context.watch<SalesmanFlagsService>().flags?.showadddetailsbottomsheetSalesMan ?? false))
            SizedBox(
              height: 48,
              child: QuickQuantityAdjuster(
                product: product,
                currentQuantity: cartQty,
                selectedAccount: widget.selectedAccount,
                onQuantityChanged: () async {
                  debugPrint('[_buildBottomAction] QuickQuantityAdjuster onQuantityChanged called');
                  await fetchCartAndSetQty();
                  if (mounted) setState(() {
                    debugPrint('[_buildBottomAction] setState called after QuickQuantityAdjuster');
                  });
                },
              ),
            )
          else
            // If Showadddetailsbottomsheet_SalesMan is TRUE: Show Add/Update button, hide -/+
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
      // _AddToCartSheet handles the keyboard inset itself (its container pads
      // for viewInsets) — no extra keyboard-aware wrapper, else padding doubles.
      builder: (ctx) => _AddToCartSheet(
        product: product,
        selectedAccount: widget.selectedAccount,
        cartDetails: cartDetails,
        cartQty: cartQty,
        onCartUpdated: () async {
          debugPrint('[ProductDetailPage] onCartUpdated called');
          Navigator.pop(ctx);
          await fetchCartAndSetQty();
          debugPrint('[ProductDetailPage] After fetchCartAndSetQty, cartQty = $cartQty');
          if (mounted) {
            setState(() {
              // Explicitly update state to reflect cartQty change
              debugPrint('[ProductDetailPage] setState called, cartQty = $cartQty');
            });
          }
        },
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


}

// ─────────────────────────────────────────────────────────────────────────────
// Keyboard-aware wrapper — isolates viewInsets so sheet never resets on KB dismiss
// ─────────────────────────────────────────────────────────────────────────────
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
  late final TextEditingController boxController;
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
  // Guards the one-time prefill of scheme/discount fields from the first preview.
  bool _prefilled = false;

  @override
  void initState() {
    super.initState();
    final d = widget.cartDetails;
    double sd(dynamic v) => v is double ? v : (v is int ? v.toDouble() : double.tryParse(v?.toString() ?? '') ?? 0.0);
    int si(dynamic v) => v is int ? v : (v is double ? v.toInt() : int.tryParse(v?.toString() ?? '') ?? 0);

    final p = widget.product;
    final price = p is Product ? p.price : sd(p is Map ? (p['Rate'] ?? p['price']) : 0.0);

    // For a brand-new add (no existing cart entry), leave numeric fields
    // blank — the hint shows "0" so the user can just tap and type. For an
    // edit of an existing cart item, prefill with the saved values.
    final bool isNew = d.isEmpty || si(d['Qty']) == 0;
    qtyCtrl        = TextEditingController(text: isNew ? '' : si(d['Qty']).toString());
    boxController  = TextEditingController(text: '');
    fQtyCtrl       = TextEditingController(text: isNew ? '' : si(d['FQty']).toString());
    schQtyCtrl     = TextEditingController(text: isNew ? '' : sd(d['SchQty']).toStringAsFixed(0));
    dSchQtyCtrl    = TextEditingController(text: isNew ? '' : sd(d['DSchQty']).toStringAsFixed(0));
    priceCtrl      = TextEditingController(text: sd(d['Rate']) > 0 ? sd(d['Rate']).toStringAsFixed(2) : price.toStringAsFixed(2));
    discPcsCtrl    = TextEditingController(text: isNew ? '' : sd(d['DiscPcs']).toString());
    discPerCtrl    = TextEditingController(text: isNew ? '' : sd(d['DiscPer']).toString());
    addDiscPerCtrl = TextEditingController(text: isNew ? '' : sd(d['AddDiscPer']).toString());
    // Scheme narration: keep the saved cart value, else fall back to the
    // item's own scheme so a fresh add still shows the available scheme.
    final dSchNarr = d['SchNarr']?.toString() ?? '';
    final itemScheme = p is Product
        ? (p.scheme ?? '')
        : (p is Map ? (p['SCHNARR'] ?? p['SchNarr'] ?? '').toString() : '');
    schNarrCtrl    = TextEditingController(text: dSchNarr.isNotEmpty ? dSchNarr : itemScheme);
    remarkCtrl     = TextEditingController(text: d['Remark']?.toString() ?? '');
  }

  // Explicit FocusNodes so the keyboard "Next" key reliably hops to every
  // visible field — including the flag-gated Free Qty and Pcs Discount rows.
  final FocusNode _boxFocus        = FocusNode();
  final FocusNode _qtyFocus        = FocusNode();
  final FocusNode _freeQtyFocus    = FocusNode();
  final FocusNode _schemeFocus     = FocusNode();
  final FocusNode _dSchemeFocus    = FocusNode();
  final FocusNode _priceFocus      = FocusNode();
  final FocusNode _discPcsFocus    = FocusNode();
  final FocusNode _discPerFocus    = FocusNode();
  final FocusNode _addDiscPerFocus = FocusNode();
  final FocusNode _remarkFocus     = FocusNode();

  List<FocusNode> get _orderedFocus => [
        _boxFocus, _qtyFocus, _freeQtyFocus, _schemeFocus, _dSchemeFocus, _priceFocus,
        _discPcsFocus, _discPerFocus, _addDiscPerFocus, _remarkFocus,
      ];

  // Find the next currently-mounted focus node after `current`.
  // A node whose widget isn't in the tree (because the flag hides it) has a
  // null context — skip those so the "Next" key never lands on nothing.
  FocusNode? _nextVisibleFocus(FocusNode current) {
    final ordered = _orderedFocus;
    final idx = ordered.indexOf(current);
    if (idx < 0) return null;
    for (int i = idx + 1; i < ordered.length; i++) {
      if (ordered[i].context != null) return ordered[i];
    }
    return null;
  }

  @override
  void dispose() {
    qtyCtrl.dispose(); boxController.dispose(); fQtyCtrl.dispose(); schQtyCtrl.dispose();
    dSchQtyCtrl.dispose(); priceCtrl.dispose(); discPcsCtrl.dispose();
    discPerCtrl.dispose(); addDiscPerCtrl.dispose();
    schNarrCtrl.dispose(); remarkCtrl.dispose();
    _qtyFocus.dispose();
    _boxFocus.dispose();
    _freeQtyFocus.dispose();
    _schemeFocus.dispose();
    _dSchemeFocus.dispose();
    _priceFocus.dispose();
    _discPcsFocus.dispose();
    _discPerFocus.dispose();
    _addDiscPerFocus.dispose();
    _remarkFocus.dispose();
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
    final box  = int.tryParse(boxController.text.trim()) ?? 0;
    final rate = double.tryParse(priceCtrl.text.trim()) ?? 0.0;
    String orZero(String s) => s.trim().isEmpty ? '0' : s.trim();
    return DraftOrderRequest(
      itemCode: code, idCol: idCol,
      // When boxes are entered, send base 0 so the server returns
      // box × conversion (no compounding); the total is shown in the Qty field.
      itemQty: box > 0 ? '0' : orZero(qtyCtrl.text),
      itemUnit1Qty: orZero(boxController.text),
      itemRate: rate.toStringAsFixed(2),
      itemFQty:    orZero(fQtyCtrl.text),
      itemSchQty:  orZero(schQtyCtrl.text),
      itemDSchQty: orZero(dSchQtyCtrl.text),
      itemAmt: (rate * (box > 0 ? 0 : qty)).toStringAsFixed(2),
      discountPercentage:  orZero(discPerCtrl.text),
      discountPercentage1: orZero(addDiscPerCtrl.text),
      discountPcs:         orZero(discPcsCtrl.text),
      remark:              remarkCtrl.text.trim(),
      insertRecord:        insertRecord,
    );
  }

  // When the Box is cleared/zero, reset the Qty (it was holding the box-driven
  // total), then re-run the preview.
  void _onBoxChanged() {
    final b = int.tryParse(boxController.text.trim()) ?? 0;
    if (b <= 0) qtyCtrl.text = '';
    _onChanged();
  }

  void _onChanged() {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 350), () async {
      final qty = int.tryParse(qtyCtrl.text.trim()) ?? 0;
      final box = int.tryParse(boxController.text.trim()) ?? 0;
      if (qty <= 0 && box <= 0) {
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
          // Box-driven: show the server's total quantity in the Qty field.
          if (box > 0 && result.qty.isNotEmpty) {
            // Quantity as a whole number (server sends e.g. "40.00").
            final n = double.tryParse(result.qty);
            qtyCtrl.text = n != null ? n.toInt().toString() : result.qty;
          }
          // First preview after the sheet opens: prefill the scheme & discount
          // fields with the default the server applied — but only where the
          // user (or a saved cart entry) hasn't already filled something in.
          if (!_prefilled) {
            _prefilled = true;
            void seed(TextEditingController c, double v, {int dp = 2}) {
              if (c.text.trim().isEmpty && v > 0) c.text = v.toStringAsFixed(dp);
            }
            seed(discPerCtrl, result.discPer);
            seed(addDiscPerCtrl, result.disc1Per);
            seed(discPcsCtrl, result.disc2Per);
            seed(schQtyCtrl, result.schemeQty, dp: 0);
            seed(dSchQtyCtrl, result.dSchemeQty, dp: 0);
          }
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

  // Shared input decoration.
  InputDecoration _fieldDeco(ColorScheme cs) => InputDecoration(
        hintText: '0',
        hintStyle: TextStyle(color: cs.onSurfaceVariant.withValues(alpha: 0.4), fontWeight: FontWeight.normal),
        isDense: true,
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: cs.outlineVariant)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: cs.outlineVariant)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: cs.primary, width: 2)),
      );

  Widget _rowField(ColorScheme cs, TextTheme tt, String label, TextEditingController ctrl, TextInputType kbType, {bool enabled = true, FocusNode? focusNode, bool autofocus = false, VoidCallback? onFieldChanged}) => Row(
        children: [
          Expanded(child: Text(label, style: tt.titleMedium?.copyWith(fontWeight: FontWeight.w600))),
          SizedBox(
            width: 130,
            child: TextField(
              controller: ctrl,
              focusNode: focusNode,
              autofocus: autofocus,
              keyboardType: kbType,
              textInputAction: TextInputAction.next,
              onSubmitted: (_) {
                final next = focusNode != null ? _nextVisibleFocus(focusNode) : null;
                if (next != null) {
                  next.requestFocus();
                } else {
                  FocusScope.of(context).unfocus();
                }
              },
              textAlign: TextAlign.right,
              enabled: enabled,
              onChanged: (_) => (onFieldChanged ?? _onChanged)(),
              style: tt.titleSmall?.copyWith(fontWeight: FontWeight.w700),
              decoration: _fieldDeco(cs),
            ),
          ),
        ],
      );

  Widget _rowFieldWithAmt(ColorScheme cs, TextTheme tt, String label, TextEditingController ctrl, double amt, {FocusNode? focusNode}) {
    final bool hasAmt = amt > 0;
    return Row(
      children: [
        Expanded(
          child: Text(label, style: tt.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
        ),
        const SizedBox(width: 8),
        // Amount chip — sits to the LEFT of the value entry box.
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: hasAmt ? Colors.red.shade50 : cs.surfaceContainerHighest.withValues(alpha: 0.5),
            borderRadius: BorderRadius.circular(6),
            border: Border.all(
              color: hasAmt ? Colors.red.shade200 : cs.outlineVariant.withValues(alpha: 0.4),
              width: 0.8,
            ),
          ),
          child: Text(
            '- ₹${amt.toStringAsFixed(2)}',
            style: tt.labelLarge?.copyWith(
              color: hasAmt ? Colors.red.shade700 : cs.outline,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.2,
            ),
          ),
        ),
        const SizedBox(width: 8),
        SizedBox(
          width: 110,
          child: TextField(
            controller: ctrl,
            focusNode: focusNode,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            textInputAction: TextInputAction.next,
            onSubmitted: (_) {
              final next = focusNode != null ? _nextVisibleFocus(focusNode) : null;
              if (next != null) {
                next.requestFocus();
              } else {
                FocusScope.of(context).unfocus();
              }
            },
            textAlign: TextAlign.right,
            onChanged: (_) => _onChanged(),
            style: tt.titleSmall?.copyWith(fontWeight: FontWeight.w700),
            decoration: _fieldDeco(cs),
          ),
        ),
      ],
    );
  }

  Widget _infoChip(String label, IconData icon, Color color) => Container(
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

  Widget _summaryRow(ColorScheme cs, TextTheme tt, String label, String value, {bool isNegative = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant, fontWeight: FontWeight.w500)),
        Text(value, style: tt.bodyMedium?.copyWith(fontWeight: FontWeight.w700, color: isNegative ? Colors.red.shade600 : cs.onSurface)),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    if (_firstBuild) {
      _firstBuild = false;
      if ((int.tryParse(qtyCtrl.text) ?? 0) > 0) {
        WidgetsBinding.instance.addPostFrameCallback((_) => _onChanged());
      }
    }

    final p = widget.product;
    final name  = p is Product ? p.name : (p is Map ? (p['Name'] ?? p['name'] ?? '') : '');
    final mfg   = p is Product ? (p.manufacturer ?? '') : (p is Map ? (p['MfgComp'] ?? '') : '');
    final unit  = p is Product ? p.unit : (p is Map ? (p['Packing'] ?? p['packing'] ?? p['UOM'] ?? '').toString() : '');
    final price = p is Product ? p.price : (p is Map ? (double.tryParse(p['Rate']?.toString() ?? '') ?? 0.0) : 0.0);
    final mrp   = p is Product ? p.mrp   : (p is Map ? (double.tryParse(p['Mrp']?.toString()  ?? '') ?? 0.0) : 0.0);
    // Stock from the API comes as a decimal string (e.g. "52.0"); int.tryParse
    // would fail on that, so parse as double first then truncate to int.
    final stock = p is Product
        ? p.stockQuantity
        : (p is Map
            ? (double.tryParse((p['Stock'] ?? p['stock'] ?? p['stockQuantity'] ?? '').toString()) ?? 0).toInt()
            : 0);

    final subtitle = [mfg.toString(), unit.toString()]
        .where((s) => s.trim().isNotEmpty)
        .join(' • ');

    return Container(
      height: MediaQuery.of(context).size.height * 0.92,
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Column(
        children: [
          // Handle
          Container(
            margin: const EdgeInsets.only(top: 12, bottom: 4),
            width: 40,
            height: 4,
            decoration: BoxDecoration(color: colorScheme.outlineVariant, borderRadius: BorderRadius.circular(2)),
          ),
          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 12, 12),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(name.toString(),
                          style: textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
                          maxLines: 2, overflow: TextOverflow.ellipsis),
                      const SizedBox(height: 2),
                      Text(subtitle,
                          style: textTheme.bodySmall?.copyWith(color: colorScheme.onSurfaceVariant)),
                    ],
                  ),
                ),
                IconButton.filledTonal(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close_rounded, size: 18),
                  style: IconButton.styleFrom(minimumSize: const Size(36, 36), padding: EdgeInsets.zero),
                ),
              ],
            ),
          ),
          // Info chips
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
            child: Wrap(
              spacing: 8,
              runSpacing: 6,
              children: [
                _infoChip('₹${price.toStringAsFixed(2)}', Icons.sell_outlined, colorScheme.primary),
                if (mrp > 0) _infoChip('MRP ₹${mrp.toStringAsFixed(2)}', Icons.price_change_outlined, colorScheme.secondary),
                _infoChip(
                  stock > 0 ? 'Stock: $stock' : 'Out of Stock',
                  stock > 0 ? Icons.inventory_2_outlined : Icons.remove_shopping_cart_outlined,
                  stock > 0 ? Colors.green.shade600 : colorScheme.error,
                ),
              ],
            ),
          ),
          Divider(height: 1, thickness: 0.5, color: colorScheme.outlineVariant),
          // Scrollable form body
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
              // Force focus to advance in widget-tree order so the keyboard's
              // "Next" key hits every visible field (Quantity → Free Qty →
              // Scheme → +Scheme → Price → Discount fields → Remark) without
              // skipping.
              child: FocusTraversalGroup(
                policy: WidgetOrderTraversalPolicy(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (context.watch<SalesmanFlagsService>().flags?.showBoxQty ?? true) ...[
                      _rowField(colorScheme, textTheme, 'Box', boxController, TextInputType.number, focusNode: _boxFocus, autofocus: true, onFieldChanged: _onBoxChanged),
                      const SizedBox(height: 8),
                    ],
                    _rowField(colorScheme, textTheme, 'Quantity', qtyCtrl, TextInputType.number, focusNode: _qtyFocus, autofocus: !(context.watch<SalesmanFlagsService>().flags?.showBoxQty ?? true)),
                    const SizedBox(height: 8),
                    if (context.watch<SalesmanFlagsService>().flags?.showFreeQtySalesMan ?? false)
                      ...[
                        _rowField(colorScheme, textTheme, 'Free Quantity', fQtyCtrl, TextInputType.number, focusNode: _freeQtyFocus),
                        const SizedBox(height: 8),
                      ],
                    // Scheme (two boxes with +)
                    if (context.watch<SalesmanFlagsService>().flags?.showSchemeSalesMan ?? false)
                      ...[
                        Row(
                          children: [
                            Expanded(child: Text('Scheme', style: textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600))),
                            SizedBox(
                              width: 56,
                              child: TextField(
                                controller: schQtyCtrl,
                                focusNode: _schemeFocus,
                                keyboardType: TextInputType.number,
                                textInputAction: TextInputAction.next,
                                onSubmitted: (_) {
                                  final next = _nextVisibleFocus(_schemeFocus);
                                  if (next != null) {
                                    next.requestFocus();
                                  } else {
                                    FocusScope.of(context).unfocus();
                                  }
                                },
                                textAlign: TextAlign.center,
                                onChanged: (_) => _onChanged(),
                                style: textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
                                decoration: _fieldDeco(colorScheme),
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 6),
                              child: Text('+', style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700, color: colorScheme.primary)),
                            ),
                            SizedBox(
                              width: 56,
                              child: TextField(
                                controller: dSchQtyCtrl,
                                focusNode: _dSchemeFocus,
                                keyboardType: TextInputType.number,
                                textInputAction: TextInputAction.next,
                                onSubmitted: (_) {
                                  final next = _nextVisibleFocus(_dSchemeFocus);
                                  if (next != null) {
                                    next.requestFocus();
                                  } else {
                                    FocusScope.of(context).unfocus();
                                  }
                                },
                                textAlign: TextAlign.center,
                                onChanged: (_) => _onChanged(),
                                style: textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
                                decoration: _fieldDeco(colorScheme),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                      ],
                    // Price field - always visible, editable/disabled based on flag
                    _rowField(
                      colorScheme,
                      textTheme,
                      'Price',
                      priceCtrl,
                      const TextInputType.numberWithOptions(decimal: true),
                      enabled: context.watch<SalesmanFlagsService>().flags?.enablePriceSalesMan ?? false,
                      focusNode: _priceFocus,
                    ),
                    const SizedBox(height: 8),
                    if (context.watch<SalesmanFlagsService>().flags?.showDiscPcsSalesMan ?? false)
                      ...[
                        _rowFieldWithAmt(colorScheme, textTheme, 'Discount (Pcs)', discPcsCtrl, preview?.disc2Amt ?? 0.0, focusNode: _discPcsFocus),
                        const SizedBox(height: 8),
                      ],
                    if (context.watch<SalesmanFlagsService>().flags?.showDiscPerSalesMan ?? false)
                      ...[
                        _rowFieldWithAmt(colorScheme, textTheme, 'Discount (%)', discPerCtrl, preview?.discAmt ?? 0.0, focusNode: _discPerFocus),
                        const SizedBox(height: 8),
                      ],
                    if (context.watch<SalesmanFlagsService>().flags?.showdisc1perSalesman ?? false)
                      ...[
                        _rowFieldWithAmt(colorScheme, textTheme, 'Add. Discount (%)', addDiscPerCtrl, preview?.disc1Amt ?? 0.0, focusNode: _addDiscPerFocus),
                        const SizedBox(height: 8),
                      ],
                    const SizedBox(height: 12),
                    // Remark
                    if (context.watch<SalesmanFlagsService>().flags?.showItemRemarkSalesMan ?? false)
                      ...[
                        Text('Add Remark (Optional)', style: textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600)),
                        const SizedBox(height: 8),
                        TextField(
                          controller: remarkCtrl,
                          focusNode: _remarkFocus,
                          maxLength: 200,
                          maxLines: 2,
                          textInputAction: TextInputAction.done,
                          onSubmitted: (_) => FocusScope.of(context).unfocus(),
                          style: textTheme.bodyMedium,
                          decoration: _fieldDeco(colorScheme).copyWith(
                            hintText: 'Type here...',
                            contentPadding: const EdgeInsets.all(12),
                            counterText: '',
                          ),
                        ),
                        const SizedBox(height: 24),
                      ]
                    else
                      const SizedBox(height: 20),
                    // Summary card - show/hide based on Showadddetailsbottomsheet_SalesMan flag
                    if (context.watch<SalesmanFlagsService>().flags?.showadddetailsbottomsheetSalesMan ?? true)
                      ...[
                        Container(
                          decoration: BoxDecoration(
                            color: colorScheme.surfaceContainerLow,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: colorScheme.outlineVariant.withValues(alpha: 0.3)),
                          ),
                          child: Column(
                            children: [
                              Padding(
                                padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
                                child: Column(
                                  children: [
                                    _summaryRow(colorScheme, textTheme, 'Goods Value', '₹${goodsValue.toStringAsFixed(2)}'),
                                    const SizedBox(height: 8),
                                    _summaryRow(colorScheme, textTheme, 'Scheme Value', '₹${schemeValue.toStringAsFixed(2)}'),
                                    const SizedBox(height: 8),
                                    _summaryRow(colorScheme, textTheme, 'Discount Value', '-₹${discountValue.toStringAsFixed(2)}', isNegative: true),
                                    const SizedBox(height: 8),
                                    _summaryRow(colorScheme, textTheme, 'GST % (Excl)', '₹${gst.toStringAsFixed(2)}'),
                                  ],
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                                decoration: BoxDecoration(
                                  color: colorScheme.primary.withValues(alpha: 0.08),
                                  borderRadius: const BorderRadius.vertical(bottom: Radius.circular(16)),
                                  border: Border(top: BorderSide(color: colorScheme.primary.withValues(alpha: 0.15))),
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text('Net Value', style: textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800, color: colorScheme.primary)),
                                    Text('₹${netValue.toStringAsFixed(2)}', style: textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900, color: colorScheme.primary, letterSpacing: -0.5)),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),
                      ],
                    const SizedBox(height: 12),
                    if (_loading) ...[
                      const SizedBox(height: 12),
                      const LinearProgressIndicator(minHeight: 3),
                      const SizedBox(height: 12),
                    ],
                    // Action buttons — matches cart_page._CartUpdateBottomSheet
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => Navigator.pop(context),
                            style: OutlinedButton.styleFrom(
                              minimumSize: const Size(double.infinity, 54),
                              side: BorderSide(color: colorScheme.outlineVariant),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                            ),
                            child: const Text('Close', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          flex: 2,
                          child: FilledButton(
                            onPressed: () async {
                              if ((int.tryParse(qtyCtrl.text) ?? 0) <= 0) {
                                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Quantity must be greater than 0')));
                                return;
                              }
                              await _submit();
                            },
                            style: FilledButton.styleFrom(
                              minimumSize: const Size(double.infinity, 54),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                              elevation: 0,
                            ),
                            child: Text(
                              widget.cartQty > 0 ? 'Update Cart' : 'Add to Cart',
                              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
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
      final user = auth.currentUser;

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
      if (widget.product is Product) {
        itemCode = widget.product.code ?? widget.product.id;
        idCol = widget.product.iidcol ?? int.tryParse(widget.product.id) ?? 0;
      } else if (widget.product is Map) {
        itemCode = widget.product['Icode']?.toString() ??
            widget.product['icode']?.toString() ??
            widget.product['Code']?.toString() ??
            widget.product['code']?.toString() ??
            '';
        idCol = int.tryParse(
                widget.product['i_id_col']?.toString() ??
                    widget.product['iidcol']?.toString() ??
                    widget.product['IdCol']?.toString() ??
                    '') ??
            0;
      } else {
        try {
          itemCode = widget.product.code ?? '';
          idCol = widget.product.iidcol ?? 0;
        } catch (_) {}
      }

      final qty = int.tryParse(qtyCtrl.text) ?? 1;
      final usedPrice = double.tryParse(priceCtrl.text) ?? 0.0;

      final request = _buildDraftOrderRequest(
        itemCode: itemCode,
        idCol: idCol,
        qty: qtyCtrl.text.trim(),
        box: boxController.text.trim(),
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

      debugPrint('[_AddToCartSheet._addToCart] Success! Calling onCartUpdated');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Item added to cart'), duration: Duration(milliseconds: 800)),
        );
        widget.onCartUpdated();
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
    required String box,
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
    String orZero(String s) => s.trim().isEmpty ? '0' : s.trim();
    return DraftOrderRequest(
      itemCode: itemCode,
      idCol: idCol,
      itemQty: orZero(qty),
      itemUnit1Qty: orZero(box),
      itemRate: rate,
      itemFQty: orZero(freeQty),
      itemSchQty: orZero(schemeQty),
      itemDSchQty: orZero(dSchemeQty),
      itemAmt: itemAmt,
      discountPercentage: orZero(discountPer),
      discountPercentage1: orZero(addDiscountPer),
      discountPcs: orZero(discountPcs),
      remark: remark,
      insertRecord: insertRecord,
    );
  }
}

