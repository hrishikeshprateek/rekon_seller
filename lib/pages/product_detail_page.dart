import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:provider/provider.dart';
import '../auth_service.dart';
import 'dart:convert';

class ProductDetailPage extends StatefulWidget {
  final dynamic product;
  const ProductDetailPage({Key? key, required this.product}) : super(key: key);

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
    fetchSimilarProducts();
  }

  void _extractId() {
    if (product is Map) {
      var rawId = product['i_id_col'] ?? product['IdCol'] ?? product['iidcol'] ?? 0;
      receivedId = rawId is int ? rawId : int.tryParse(rawId.toString()) ?? 0;
    } else {
      try { receivedId = product.iidcol ?? 0; } catch (_) {}
    }
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

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        title: const Text('Product Details'),
        elevation: 0,
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
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
    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surfaceVariant.withOpacity(0.3),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          IconButton(onPressed: () => setState(() => qty = (qty > 1) ? qty - 1 : 1), icon: const Icon(Icons.remove)),
          SizedBox(
            width: 40,
            child: Text('$qty', textAlign: TextAlign.center, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          ),
          IconButton(onPressed: () => setState(() => qty++), icon: const Icon(Icons.add)),
        ],
      ),
    );
  }

  Widget _buildInfoSection(ColorScheme cs, TextTheme tt, String title, String content, IconData icon) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cs.surfaceVariant.withOpacity(0.2),
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

    return SizedBox(
      height: 180,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        scrollDirection: Axis.horizontal,
        itemCount: similarProducts.length,
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (ctx, idx) {
          final sp = similarProducts[idx];
          return GestureDetector(
            onTap: () => Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => ProductDetailPage(product: sp))),
            child: Container(
              width: 160,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                border: Border.all(color: cs.outlineVariant),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(_getString(sp, ['Name', 'name']), maxLines: 2, overflow: TextOverflow.ellipsis, style: tt.labelLarge?.copyWith(fontWeight: FontWeight.bold)),
                  const Spacer(),
                  Text(_getString(sp, ['MfgComp', 'manufacturer']), maxLines: 1, overflow: TextOverflow.ellipsis, style: tt.bodySmall),
                  const SizedBox(height: 8),
                  Text('₹${_getDouble(sp, ['Rate', 'price']).toStringAsFixed(2)}', style: tt.titleMedium?.copyWith(color: cs.primary, fontWeight: FontWeight.bold)),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildBottomAction(ColorScheme cs, double price) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
      decoration: BoxDecoration(
        color: cs.surface,
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, -5))],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Total Value', style: TextStyle(color: cs.outline)),
                Text('₹${(price * qty).toStringAsFixed(2)}', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              ],
            ),
          ),
          ElevatedButton(
            onPressed: _showBulkUpdateBottomSheet, // Use the user's custom bottom sheet
            style: ElevatedButton.styleFrom(
              backgroundColor: cs.primary,
              foregroundColor: cs.onPrimary,
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            ),
            child: const Text('EDIT & ADD', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  void _showBulkUpdateBottomSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        final colorScheme = Theme.of(context).colorScheme;
        final textTheme = Theme.of(context).textTheme;
        final TextEditingController localQtyController = TextEditingController(text: qty.toString());
        double price = _getDouble(product, ['price', 'Rate'], fallback: 0.0);
        int available = _getInt(product, ['stockQuantity', 'Stock'], fallback: 0);
        return Padding(
          padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
          child: Container(
            decoration: BoxDecoration(
              color: colorScheme.surface,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
            ),
            padding: const EdgeInsets.all(20),
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
                Text('Edit Quantity', style: textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: localQtyController,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          labelText: 'Quantity',
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text('Available: $available', style: textTheme.bodyMedium),
                  ],
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('CANCEL'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          int newQty = int.tryParse(localQtyController.text) ?? qty;
                          if (newQty > 0 && newQty <= available) {
                            setState(() => qty = newQty);
                            Navigator.pop(context);
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Invalid quantity.')),
                            );
                          }
                        },
                        child: const Text('UPDATE'),
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
  }

  Widget _buildHeaderStat(ColorScheme cs, double price, int qty) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cs.surfaceVariant.withOpacity(0.2),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _buildSummaryRow(cs, 'Unit Price', '₹${price.toStringAsFixed(2)}', Icons.price_check),
          _buildSummaryRow(cs, 'Quantity', '$qty', Icons.format_list_numbered),
          _buildSummaryRow(cs, 'Total', '₹${(price * qty).toStringAsFixed(2)}', Icons.monetization_on),
        ],
      ),
    );
  }

  Widget _buildSummaryRow(ColorScheme cs, String label, String value, IconData icon) {
    return Row(
      children: [
        Icon(icon, color: cs.primary, size: 20),
        const SizedBox(width: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: TextStyle(color: cs.onSurfaceVariant)),
            Text(value, style: TextStyle(fontWeight: FontWeight.bold, color: cs.onSurface)),
          ],
        ),
      ],
    );
  }
}