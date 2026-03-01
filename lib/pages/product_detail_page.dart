import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:provider/provider.dart';
import '../auth_service.dart';
import 'dart:convert';
import '../models/product_model.dart';
import '../models/account_model.dart' as models;
import 'cart_page.dart';

class ProductDetailPage extends StatefulWidget {
  final dynamic product;
  final models.Account selectedAccount;
  const ProductDetailPage({Key? key, required this.product, required this.selectedAccount}) : super(key: key);

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

  int cartQty = 1; // Default to 1 if not in cart

  @override
  void initState() {
    super.initState();
    product = widget.product;
    // Use robust id extraction logic as in the reference
    if (product is Map) {
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
    qty = _getInt(product, ['qty', 'Qty'], fallback: 1);
    qtyController = TextEditingController(text: qty.toString());
    fetchCartAndSetQty();
    fetchSimilarProducts();
  }

  Future<void> fetchCartAndSetQty() async {
    setState(() {});
    try {
      final auth = Provider.of<AuthService>(context, listen: false);
      final dio = auth.getDioClient();
      final user = auth.currentUser;
      final mobile = user?.mobileNumber ?? '';
      final licNo = user?.licenseNumber ?? '';
      String firmCode = '';
      try {
        if (user != null && user.stores.isNotEmpty) {
          final primary = user.stores.firstWhere((s) => s.primary, orElse: () => user.stores.first);
          firmCode = primary.firmCode;
        }
      } catch (_) {}
      // ✅ FIXED: Use selectedAccount.code instead of firmCode
      final acCode = widget.selectedAccount.code ?? '';
      final payload = jsonEncode({
        'lUserId': mobile,
        'lLicNo': licNo,
        'lFirmCode': firmCode,
        'AcCode': acCode,
      });
      final response = await dio.post(
        '/ListDraftOrder',
        data: payload,
        options: Options(
          headers: {
            'Content-Type': 'application/json',
            'package_name': auth.packageNameHeader,
            if (auth.getAuthHeader() != null) 'Authorization': auth.getAuthHeader(),
          },
        ),
      );
      dynamic raw = response.data;
      Map<String, dynamic> parsed = _parseJson(raw);
      int foundQty = 1;
      if (parsed['success'] == true && parsed['data'] != null) {
        final list = (parsed['data']['DraftOrder'] as List<dynamic>?) ?? [];
        debugPrint('[fetchCartAndSetQty] Found ${list.length} items in cart');

        // Get product identifiers
        final productCode = product['Code']?.toString() ?? product['code']?.toString() ?? product['ItemCode']?.toString() ?? '';
        final productIdCol = product['i_id_col']?.toString() ?? product['iidcol']?.toString() ?? product['IdCol']?.toString() ?? '';
        final productId = product['id']?.toString() ?? '';

        debugPrint('[fetchCartAndSetQty] Looking for - Code: $productCode, IdCol: $productIdCol, Id: $productId');

        for (final e in list) {
          final code = e['Code']?.toString() ?? e['ItemCode']?.toString() ?? '';
          final idCol = e['i_id_col']?.toString() ?? e['IdCol']?.toString() ?? '';
          final itemId = e['id']?.toString() ?? '';

          debugPrint('[fetchCartAndSetQty] Checking - Code: $code, IdCol: $idCol, Id: $itemId');

          bool matches = false;

          // Match by IdCol first (most reliable)
          if (productIdCol.isNotEmpty && idCol.isNotEmpty) {
            matches = productIdCol == idCol;
            if (matches) debugPrint('[fetchCartAndSetQty] Matched by IdCol');
          }

          // Then by code
          if (!matches && productCode.isNotEmpty && code.isNotEmpty) {
            matches = productCode == code;
            if (matches) debugPrint('[fetchCartAndSetQty] Matched by Code');
          }

          // Then by id
          if (!matches && productId.isNotEmpty && itemId.isNotEmpty) {
            matches = productId == itemId;
            if (matches) debugPrint('[fetchCartAndSetQty] Matched by Id');
          }

          if (matches) {
            foundQty = int.tryParse(e['Qty']?.toString() ?? e['qty']?.toString() ?? '1') ?? 1;
            debugPrint('[fetchCartAndSetQty] Found matching item with qty: $foundQty');
            break;
          }
        }
      }
      
      debugPrint('[fetchCartAndSetQty] Final foundQty: $foundQty');
      setState(() {
        cartQty = foundQty;
        qty = cartQty;
        qtyController.text = cartQty.toString();
      });
    } catch (e) {
      // fallback: do nothing
    } finally {
      setState(() {});
    }
  }

  // ✅ NEW: Fetch full cart item details (discounts, schemes, remarks, etc.)
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
          final primary = user.stores.firstWhere((s) => s.primary, orElse: () => user.stores.first);
          firmCode = primary.firmCode;
        }
      } catch (_) {}
      final acCode = widget.selectedAccount.code ?? '';
      
      final payload = jsonEncode({
        'lUserId': mobile,
        'lLicNo': licNo,
        'lFirmCode': firmCode,
        'AcCode': acCode,
      });
      
      final response = await dio.post(
        '/ListDraftOrder',
        data: payload,
        options: Options(
          headers: {
            'Content-Type': 'application/json',
            'package_name': auth.packageNameHeader,
            if (auth.getAuthHeader() != null) 'Authorization': auth.getAuthHeader(),
          },
        ),
      );

      dynamic raw = response.data;
      Map<String, dynamic> parsed = _parseJson(raw);

      if (parsed['success'] == true && parsed['data'] != null) {
        final list = (parsed['data']['DraftOrder'] as List<dynamic>?) ?? [];

        // Get product identifiers
        final productCode = product['Code']?.toString() ?? product['code']?.toString() ?? '';
        final productIdCol = product['i_id_col']?.toString() ?? product['iidcol']?.toString() ?? '';

        for (final e in list) {
          final code = e['Code']?.toString() ?? e['ItemCode']?.toString() ?? '';
          final idCol = e['i_id_col']?.toString() ?? e['IdCol']?.toString() ?? '';

          bool matches = false;
          if (productIdCol.isNotEmpty && idCol.isNotEmpty) {
            matches = productIdCol == idCol;
          }
          if (!matches && productCode.isNotEmpty && code.isNotEmpty) {
            matches = productCode == code;
          }

          if (matches) {
            debugPrint('[fetchCartItemDetails] Found item with full details');
            return {
              'Qty': int.tryParse(e['Qty']?.toString() ?? '1') ?? 1,
              'FreeQty': int.tryParse(e['ItemFQty']?.toString() ?? e['FreeQty']?.toString() ?? '0') ?? 0,
              'Scheme': int.tryParse(e['ItemSchQty']?.toString() ?? e['SchemeQty']?.toString() ?? '0') ?? 0,
              'DiscPcs': double.tryParse(e['discount_pcs']?.toString() ?? e['DiscPcs']?.toString() ?? '0.0') ?? 0.0,
              'DiscPer': double.tryParse(e['discount_percentage']?.toString() ?? e['DiscPer']?.toString() ?? '0.0') ?? 0.0,
              'AddDiscPer': double.tryParse(e['discount_percentage1']?.toString() ?? e['AddDiscPer']?.toString() ?? '0.0') ?? 0.0,
              'Remark': e['remark']?.toString() ?? e['Remark']?.toString() ?? '',
            };
          }
        }
      }
    } catch (e) {
      debugPrint('[fetchCartItemDetails] Error: $e');
    }

    // Return empty map if not found
    return {
      'Qty': 1,
      'FreeQty': 0,
      'Scheme': 0,
      'DiscPcs': 0.0,
      'DiscPer': 0.0,
      'AddDiscPer': 0.0,
      'Remark': '',
    };
  }

  Map<String, dynamic> _parseJson(dynamic raw) {
    if (raw is Map<String, dynamic>) return raw;
    if (raw is String) {
      final clean = raw.replaceAll(RegExp(r'[\x00-\x1F\x7F]'), '').trim();
      return jsonDecode(clean) as Map<String, dynamic>;
    }
    return jsonDecode(jsonEncode(raw)) as Map<String, dynamic>;
  }

  // ... (Keep existing _getInt, _getDouble, _getString helper methods exactly as they are) ...

  int _getInt(dynamic obj, List<String> keys, {int fallback = 0}) {
    for (var k in keys) {
      if (obj is Map && obj[k] != null) {
        if (obj[k] is int) return obj[k];
        if (obj[k] is String) return int.tryParse(obj[k]) ?? fallback;
        if (obj[k] is double) return (obj[k] as double).toInt();
      } else if (obj != null && obj is! Map) {
        try {
          var json = obj.toJson();
          if (json.containsKey(k)) {
            var v = json[k];
            if (v is int) return v;
            if (v is String) return int.tryParse(v) ?? fallback;
            if (v is double) return v.toInt();
          }
        } catch (_) {}
      }
    }
    return fallback;
  }

  double _getDouble(dynamic obj, List<String> keys, {double fallback = 0.0}) {
    for (var k in keys) {
      if (obj is Map && obj[k] != null) {
        if (obj[k] is double) return obj[k];
        if (obj[k] is int) return (obj[k] as int).toDouble();
        if (obj[k] is String) return double.tryParse(obj[k]) ?? fallback;
      } else if (obj != null && obj is! Map) {
        try {
          var json = obj.toJson();
          if (json.containsKey(k)) {
            var v = json[k];
            if (v is double) return v;
            if (v is int) return v.toDouble();
            if (v is String) return double.tryParse(v) ?? fallback;
          }
        } catch (_) {}
      }
    }
    return fallback;
  }

  String _getString(dynamic obj, List<String> keys, {String fallback = ''}) {
    for (var k in keys) {
      if (obj is Map && obj[k] != null) return obj[k].toString();
      else if (obj != null && obj is! Map) {
        try {
          var json = obj.toJson();
          if (json.containsKey(k)) return json[k].toString();
        } catch (_) {}
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
          final primary = stores.firstWhere((s) => s.primary == true, orElse: () => stores.first);
          firmCode = primary.firmCode;
        }
      } catch (_) {
        firmCode = '';
      }
      // Use robust payload logic as in the reference
      final payload = {
        'lLicNo': auth.currentUser?.licenseNumber ?? '',
        'lUserId': auth.currentUser?.mobileNumber ?? auth.currentUser?.userId ?? '',
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
        if (auth.getAuthHeader() != null) 'Authorization': auth.getAuthHeader(),
      };
      debugPrint('[SimilarItems] Request payload: ' + payload.toString());
      final response = await dio.post('/GetItemList', data: payload, options: Options(headers: headers));
      dynamic raw = response.data;
      debugPrint('[SimilarItems] Full raw response: ' + raw.toString());
      List<dynamic> items = [];
      // Fix: If raw is a String, decode it first
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
        } catch (e) {
          debugPrint('[SimilarItems] JSON decode error: ' + e.toString());
        }
      } else if (raw is List) {
        items = raw;
      } else if (raw is Map && raw['data'] is List) {
        items = raw['data'];
      } else if (raw is Map && raw['Item'] is List) {
        items = raw['Item'];
      } else if (raw is Map && raw['items'] is List) {
        items = raw['items'];
      }
      debugPrint('[SimilarItems] Parsed items: ' + items.toString());
      setState(() => similarProducts = items);
    } catch (e) {
      debugPrint('Error: $e');
    } finally {
      setState(() => loadingSimilar = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final price = _getDouble(product, ['price', 'Rate'], fallback: 0.0);
    final stock = _getInt(product, ['stockQuantity', 'Stock'], fallback: 0);
    final manufacturer = _getString(product, ['manufacturer', 'MfgComp']);
    final packing = _getString(product, ['unit', 'packing']);
    final name = _getString(product, ['name', 'Name']);
    final salt = _getString(product, ['salt', 'Salt']);

    // Extract account code and selected account for cart navigation
    final auth = Provider.of<AuthService>(context, listen: false);
    final user = auth.currentUser;
    String acCode = '';
    models.Account? selectedAccount;
    // Use Provider or navigation arguments to get the current selectedAccount
    // If you have a selectedAccount in navigation arguments, use that
    final routeArgs = ModalRoute.of(context)?.settings.arguments;
    if (routeArgs is Map && routeArgs['selectedAccount'] != null) {
      selectedAccount = routeArgs['selectedAccount'] as models.Account?;
      acCode = selectedAccount?.code ?? '';
    } else if (user != null && user.stores.isNotEmpty) {
      // Fallback: try to get Account from Provider or other app state
      // If you have a global selectedAccount, use that here
      // Otherwise, leave selectedAccount as null
      acCode = user.stores.first.firmCode;
    }

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        title: const Text('Product Details'),
        elevation: 0,
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        actions: [
          IconButton(
            icon: const Icon(Icons.shopping_cart),
            tooltip: 'Open Cart',
            onPressed: () {
              final acCode = widget.selectedAccount.code ?? '';
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => CartPage(acCode: acCode, selectedAccount: widget.selectedAccount),
                ),
              );
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // --- Product Hero Section ---
            Container(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: colorScheme.primaryContainer,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(packing, style: textTheme.labelLarge?.copyWith(color: colorScheme.onPrimaryContainer, fontWeight: FontWeight.bold)),
                      ),
                      const SizedBox(width: 10),
                      Text('Stock: $stock Pcs', style: textTheme.bodyMedium?.copyWith(color: stock > 0 ? Colors.green : Colors.red, fontWeight: FontWeight.bold)),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(name, style: textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold, letterSpacing: -0.5)),
                  const SizedBox(height: 4),
                  Text(manufacturer, style: textTheme.titleMedium?.copyWith(color: colorScheme.primary)),
                  const Divider(height: 32),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Unit Price', style: textTheme.bodySmall),
                          Text('₹${price.toStringAsFixed(2)}', style: textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold, color: colorScheme.onSurface)),
                        ],
                      ),
                      _buildQtyCounter(colorScheme),
                    ],
                  ),
                ],
              ),
            ),

            // --- Salt/Description Section ---
            if (salt.isNotEmpty)
              _buildInfoSection(colorScheme, textTheme, "Composition", salt, Icons.biotech_outlined),

            const SizedBox(height: 20),

            // --- Similar Products Header ---
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Text('Similar Products', style: textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
            ),
            const SizedBox(height: 12),
            _buildSimilarProductsList(colorScheme, textTheme),

            const SizedBox(height: 100), // Bottom padding for FAB
          ],
        ),
      ),
      bottomNavigationBar: _buildBottomAction(colorScheme, price),
    );
  }

  Widget _buildQtyCounter(ColorScheme colorScheme) {
    // Remove + and - buttons, just show quantity
    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withAlpha(77),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Center(
        child: Text('$qty', textAlign: TextAlign.center, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
      ),
    );
  }

  Widget _buildInfoSection(ColorScheme cs, TextTheme tt, String title, String content, IconData icon) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest.withAlpha(51),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: cs.primary),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: tt.labelLarge?.copyWith(fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Text(content, style: tt.bodyMedium),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSimilarProductsList(ColorScheme cs, TextTheme tt) {
    if (loadingSimilar) return const Center(child: Padding(padding: EdgeInsets.all(20), child: CircularProgressIndicator()));
    if (similarProducts.isEmpty) return const Padding(padding: EdgeInsets.all(20), child: Text("No similar products found."));

    return ListView.separated(
      shrinkWrap: true,
      physics: NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 20),
      itemCount: similarProducts.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (ctx, idx) {
        final sp = similarProducts[idx];
        return GestureDetector(
          onTap: () => Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => ProductDetailPage(product: sp, selectedAccount: widget.selectedAccount))),
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              border: Border.all(color: cs.outlineVariant),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(_getString(sp, ['Name', 'name']), maxLines: 2, overflow: TextOverflow.ellipsis, style: tt.labelLarge?.copyWith(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Text(_getString(sp, ['MfgComp', 'manufacturer']), maxLines: 1, overflow: TextOverflow.ellipsis, style: tt.bodySmall),
                const SizedBox(height: 8),
                Text('₹${_getDouble(sp, ['Rate', 'price']).toStringAsFixed(2)}', style: tt.titleMedium?.copyWith(color: cs.primary, fontWeight: FontWeight.bold)),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildBottomAction(ColorScheme cs, double price) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
      decoration: BoxDecoration(
        color: cs.surface,
        boxShadow: [BoxShadow(color: Colors.black.withAlpha(13), blurRadius: 10, offset: const Offset(0, -5))],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Total Value', style: TextStyle(color: cs.outline)),
                          Text('₹${(price * qty).toStringAsFixed(2)}', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ),
                    if (cartQty > 0)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: cs.primaryContainer,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          'In Cart: $cartQty',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: cs.onPrimaryContainer,
                            fontSize: 12,
                          ),
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          ElevatedButton(
            onPressed: () {
              // Convert product to Product model if needed
              final p = product is Map ? _tryMapToProduct(product) : product;
              if (p != null) _showBulkAddBottomSheetFromDetail(p);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: cs.primary,
              foregroundColor: cs.onPrimary,
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            ),
            child: Text(
              cartQty > 0 ? 'UPDATE' : 'ADD',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  Product? _tryMapToProduct(dynamic map) {
    try {
      return Product(
        id: map['id']?.toString() ?? map['Code']?.toString() ?? '',
        name: map['Name']?.toString() ?? map['name']?.toString() ?? '',
        category: map['category']?.toString() ?? '',
        price: (map['Rate'] ?? map['price'] ?? 0).toDouble(),
        mrp: (map['Mrp'] ?? map['mrp'] ?? 0).toDouble(),
        unit: map['packing']?.toString() ?? map['unit']?.toString() ?? '',
        stockQuantity: (map['Stock'] ?? map['stockQuantity'] ?? 0).toInt(),
        manufacturer: map['MfgComp']?.toString() ?? map['manufacturer']?.toString(),
        batchNumber: map['batchNumber']?.toString(),
        expiryDate: map['expiryDate'] != null ? DateTime.tryParse(map['expiryDate']) : null,
        description: map['description']?.toString(),
        imageUrl: map['imageUrl']?.toString(),
        salt: map['Salt']?.toString() ?? map['salt']?.toString(),
        code: map['Code']?.toString() ?? map['code']?.toString(),
        iidcol: (map['i_id_col'] ?? map['iidcol'] ?? map['IdCol']) != null ? int.tryParse(map['i_id_col']?.toString() ?? map['iidcol']?.toString() ?? map['IdCol']?.toString() ?? '') : null,
      );
    } catch (_) {
      return null;
    }
  }


  void _showBulkAddBottomSheetFromDetail(Product product) async {
    await fetchCartAndSetQty(); // Always refresh cart qty before showing
    
    // ✅ NEW: Fetch existing cart item details if item is in cart
    final cartItemDetails = await fetchCartItemDetails();
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        final colorScheme = Theme.of(context).colorScheme;
        final textTheme = Theme.of(context).textTheme;
        
        // ✅ NEW: Pre-fill with existing data
        final TextEditingController qtyController = TextEditingController(text: cartItemDetails['Qty'].toString());
        final TextEditingController freeQtyController = TextEditingController(text: cartItemDetails['FreeQty'].toString());
        final TextEditingController schemeController = TextEditingController(text: cartItemDetails['Scheme'].toString());
        final TextEditingController discPcsController = TextEditingController(text: cartItemDetails['DiscPcs'].toString());
        final TextEditingController discPerController = TextEditingController(text: cartItemDetails['DiscPer'].toString());
        final TextEditingController addDiscPerController = TextEditingController(text: cartItemDetails['AddDiscPer'].toString());
        final TextEditingController remarkController = TextEditingController(text: cartItemDetails['Remark'].toString());

        double price = product.price;
        int available = product.stockQuantity;
        double goodsValue = 0.0, discountValue = 0.0, gst = 0.0, netValue = 0.0;

        void recalc() {
          int qty = int.tryParse(qtyController.text) ?? 1;
          int scheme = int.tryParse(schemeController.text) ?? 0;
          double discPcs = double.tryParse(discPcsController.text) ?? 0.0;
          double discPer = double.tryParse(discPerController.text) ?? 0.0;
          double addDiscPer = double.tryParse(addDiscPerController.text) ?? 0.0;
          goodsValue = price * qty;
          discountValue = discPcs + (goodsValue * (discPer + addDiscPer) / 100);
          gst = (goodsValue - discountValue) * 0.18;
          netValue = goodsValue - discountValue + gst;
        }
        recalc();

        return StatefulBuilder(
          builder: (context, setModalState) {
            void updateFields() => setModalState(() => recalc());
            InputDecoration _inputDeco(String label, {IconData? icon, String? suffix}) => InputDecoration(
              labelText: label,
              suffixText: suffix,
              isDense: true,
              filled: true,
              fillColor: colorScheme.surfaceContainerHighest.withAlpha(77),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
              prefixIcon: icon != null ? Icon(icon, size: 18) : null,
            );
            return Container(
              decoration: BoxDecoration(
                color: colorScheme.surface,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
              ),
              padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        width: 40, height: 4,
                        margin: const EdgeInsets.only(bottom: 20),
                        decoration: BoxDecoration(color: colorScheme.outlineVariant, borderRadius: BorderRadius.circular(2)),
                      ),
                    ),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(product.name, style: textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: cartQty > 0
                                        ? colorScheme.primaryContainer
                                        : colorScheme.secondaryContainer,
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Text(
                                      cartQty > 0 ? 'UPDATE' : 'ADD',
                                      style: TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                        color: cartQty > 0
                                          ? colorScheme.onPrimaryContainer
                                          : colorScheme.onSecondaryContainer,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              Text("${product.manufacturer ?? ''} • ${product.unit}", style: textTheme.bodySmall),
                            ],
                          ),
                        ),
                        IconButton.filledTonal(
                          onPressed: () => Navigator.pop(context),
                          icon: const Icon(Icons.close),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(color: colorScheme.primaryContainer.withAlpha(102), borderRadius: BorderRadius.circular(16)),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _buildHeaderStat("Price", "₹${price.toStringAsFixed(2)}", colorScheme),
                          _buildHeaderStat("Stock", "$available", colorScheme),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    Row(
                      children: [
                        Expanded(child: TextField(controller: qtyController, keyboardType: TextInputType.number, onChanged: (_) => updateFields(), decoration: _inputDeco('Quantity', icon: Icons.shopping_basket))),
                        const SizedBox(width: 12),
                        Expanded(child: TextField(controller: schemeController, keyboardType: TextInputType.number, onChanged: (_) => updateFields(), decoration: _inputDeco('Scheme', icon: Icons.card_giftcard))),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(child: TextField(controller: discPerController, keyboardType: TextInputType.number, onChanged: (_) => updateFields(), decoration: _inputDeco('Disc %', icon: Icons.percent))),
                        const SizedBox(width: 12),
                        Expanded(child: TextField(controller: addDiscPerController, keyboardType: TextInputType.number, onChanged: (_) => updateFields(), decoration: _inputDeco('Add %', icon: Icons.add_circle_outline))),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(child: TextField(controller: discPcsController, keyboardType: TextInputType.number, onChanged: (_) => updateFields(), decoration: _inputDeco('Disc Cash', icon: Icons.money))),
                        const SizedBox(width: 12),
                        Expanded(child: TextField(controller: freeQtyController, keyboardType: TextInputType.number, onChanged: (_) => updateFields(), decoration: _inputDeco('Free Qty', icon: Icons.inventory_2))),
                      ],
                    ),
                    const SizedBox(height: 12),
                    TextField(controller: remarkController, decoration: _inputDeco('Add Remark', icon: Icons.notes)),
                    const SizedBox(height: 24),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: colorScheme.surfaceContainerHighest.withAlpha(128),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: colorScheme.outlineVariant),
                      ),
                      child: Column(
                        children: [
                          _buildSummaryRow("Goods Value", "₹${goodsValue.toStringAsFixed(2)}", textTheme),
                          _buildSummaryRow("Total Discount", "-₹${discountValue.toStringAsFixed(2)}", textTheme, isNegative: true),
                          _buildSummaryRow("GST (18%)", "+₹${gst.toStringAsFixed(2)}", textTheme),
                          const Divider(height: 20),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text('Net Payable', style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                              Text('₹${netValue.toStringAsFixed(2)}', style: textTheme.titleLarge?.copyWith(color: colorScheme.primary, fontWeight: FontWeight.bold)),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    Row(
                      children: [
                        Expanded(
                          flex: 1,
                          child: OutlinedButton(
                            style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                            onPressed: () => Navigator.pop(context),
                            child: const Text('CANCEL'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          flex: 2,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: colorScheme.primary,
                              foregroundColor: colorScheme.onPrimary,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              elevation: 0,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            onPressed: () async {
                              int qty = int.tryParse(qtyController.text) ?? 1;
                              if (qty > available) {
                                debugPrint('[ProductDetailPage] Attempted to add qty > available: $qty > $available');
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text('Cannot add more than available stock ($available)')),
                                );
                                return;
                              }
                              final auth = Provider.of<AuthService>(context, listen: false);
                              final dio = auth.getDioClient();
                              final user = auth.currentUser;
                              final acCode = widget.selectedAccount.code ?? '';
                              final cuId = int.tryParse(user?.userId ?? '') ?? 0;
                              final itemCode = product.code ?? product.id;
                              final idCol = product.iidcol ?? int.tryParse(product.id) ?? 0;

                              // Get firmCode from user's stores (same as order_entry_page)
                              String firmCode = '';
                              if (user?.stores.isNotEmpty == true) {
                                firmCode = user!.stores.first.firmCode;
                              }

                              debugPrint('[ProductDetailPage] Add to cart pressed');
                              debugPrint('[ProductDetailPage] Product id: ${product.id}, code: $itemCode, iidcol: $idCol');
                              final payload = {
                                'UserId': user?.mobileNumber ?? user?.userId ?? '',
                                'LicNo': user?.licenseNumber ?? '',
                                'lFirmCode': firmCode,
                                'AcCode': acCode,
                                'ItemCode': itemCode,
                                'Icode': itemCode,
                                'IdCol': idCol,
                                'ItemQty': qtyController.text,
                                'ItemRate': price.toStringAsFixed(2),
                                'cu_id': cuId,
                                'ItemFQty': freeQtyController.text,
                                'ItemSchQty': schemeController.text,
                                'ItemDSchQty': '0.0',
                                'ItemAmt': goodsValue.toStringAsFixed(2),
                                'discount_percentage': discPerController.text,
                                'discount_percentage1': addDiscPerController.text,
                                'discount_pcs': discPcsController.text,
                                'remark': remarkController.text,
                                'insert_record': 1,
                                'default_hit': true,
                              };
                              final headers = {
                                'Content-Type': 'application/json',
                                'package_name': auth.packageNameHeader,
                                if (auth.getAuthHeader() != null) 'Authorization': auth.getAuthHeader(),
                              };
                              debugPrint('[ProductDetailPage] Cart API payload: ' + payload.toString());
                              debugPrint('[ProductDetailPage] Cart API headers: ' + headers.toString());
                              try {
                                final response = await dio.post('/AddDraftOrder', data: payload, options: Options(headers: headers));
                                debugPrint('[ProductDetailPage] Cart API response: ' + response.data.toString());
                                if (mounted) {
                                  final wasUpdating = cartQty > 0;
                                  await fetchCartAndSetQty(); // Refresh cart quantity
                                  Navigator.pop(context, true);
                                  final message = wasUpdating
                                    ? 'Item quantity updated in cart'
                                    : 'Item added to cart';
                                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
                                }
                              } catch (e) {
                                debugPrint('[ProductDetailPage] Cart API error: ' + e.toString());
                                if (mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to add: $e')));
                                }
                              }
                            },
                            child: Text(
                              cartQty > 0 ? 'UPDATE CART' : 'ADD TO CART',
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildHeaderStat(String label, String value, ColorScheme cs) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(label, style: TextStyle(color: cs.onSurfaceVariant, fontSize: 12)),
        const SizedBox(height: 4),
        Text(value, style: TextStyle(color: cs.onSurface, fontWeight: FontWeight.bold, fontSize: 16)),
      ],
    );
  }

  Widget _buildSummaryRow(String label, String value, TextTheme tt, {bool isNegative = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: tt.bodyMedium?.copyWith(color: isNegative ? Colors.red : null)),
        Text(value, style: tt.titleMedium?.copyWith(fontWeight: FontWeight.bold, color: isNegative ? Colors.red : null)),
      ],
    );
  }
}
