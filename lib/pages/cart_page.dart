import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:dio/dio.dart';
import '../auth_service.dart';
import '../models/account_model.dart' as models;
import '../services/account_selection_service.dart';
import 'select_account_page.dart';
import 'place_order_page.dart';

class CartPage extends StatefulWidget {
  final String acCode;
  final models.Account? selectedAccount;

  const CartPage({Key? key, required this.acCode, this.selectedAccount})
    : super(key: key);

  @override
  State<CartPage> createState() => _CartPageState();
}

class _CartPageState extends State<CartPage> {
  bool _isLoading = true;
  String? _error;
  List<DraftOrderItem> _items = [];

  late String _currentAcCode;
  String? _selectedAccountName;

  @override
  void initState() {
    _currentAcCode = widget.acCode;
    _selectedAccountName = widget.selectedAccount?.name;
    super.initState();
    _loadCart();
  }

  Future<void> _openSelectAccount() async {
    try {
      final models.Account? account = await SelectAccountPage.show(
        context,
        title: 'Select Party',
        accountType: 'Party',
        showBalance: true,
        selectedAccount: (widget.selectedAccount is models.Account)
            ? widget.selectedAccount as models.Account
            : null,
      );

      if (account == null) return;

      final acno = account.id.toString();
      final name = account.name.toString();

      if (acno.isNotEmpty && acno != _currentAcCode) {
        if (!mounted) return;
        setState(() {
          _currentAcCode = acno;
          _selectedAccountName = name;
          _isLoading = true;
          _error = null;
        });
        await _loadCart();
      } else if (name != null) {
        if (!mounted) return;
        setState(() => _selectedAccountName = name);
      }
    } catch (e) {
      debugPrint('Failed to select account: $e');
    }
  }

  Future<void> _loadCart() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
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

      final payload = jsonEncode({
        'lUserId': mobile,
        'lLicNo': licNo,
        'lFirmCode': firmCode,
        'AcCode': _currentAcCode,
      });

      print('===== ListDraftOrder Request Body (cart_page _loadCart) =====');
      print(payload);
      print('==============================================================');

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

      dynamic raw = response.data;
      Map<String, dynamic> parsed = _parseJson(raw);

      if (parsed['success'] == true && parsed['data'] != null) {
        final list = (parsed['data']['DraftOrder'] as List<dynamic>?) ?? [];
        _items = list
            .map((e) => DraftOrderItem.fromJson(e as Map<String, dynamic>))
            .toList();
      } else {
        _error = parsed['message']?.toString() ?? 'Failed to load cart';
      }
    } catch (e) {
      _error = e.toString();
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Map<String, dynamic> _parseJson(dynamic raw) {
    if (raw is Map<String, dynamic>) return raw;
    if (raw is String) {
      final clean = raw.replaceAll(RegExp(r'[\x00-\x1F\x7F]'), '').trim();
      return jsonDecode(clean) as Map<String, dynamic>;
    }
    return jsonDecode(jsonEncode(raw)) as Map<String, dynamic>;
  }

  Future<void> _updateQuantity(DraftOrderItem item, int newQty) async {
    final oldQty = item.qty;
    setState(() => item.qty = newQty);
    try {
      final auth = Provider.of<AuthService>(context, listen: false);
      final user = auth.currentUser;
      final cuId = int.tryParse(user?.userId ?? '') ?? 0;
      String firmCode = '';
      try {
        if (user != null && user.stores.isNotEmpty) {
          firmCode = user.stores
              .firstWhere((s) => s.primary, orElse: () => user.stores.first)
              .firmCode;
        }
      } catch (_) {}

      final payload = jsonEncode({
        'UserId': user?.mobileNumber ?? '',
        'LicNo': user?.licenseNumber ?? '',
        'lFirmCode': firmCode,
        'AcCode': _currentAcCode,
        'ItemCode': item.code, // Icode from ItemList
        'ItemQty': newQty.toString(),
        'ItemRate': item.rate?.toString() ?? '',
        'IdCol': item.idCol, // IdCol from ItemList
        'cu_id': cuId,
        'ItemAmt': item.amt?.toString() ?? '0.0',
        'insert_record': 1,
        'default_hit': true,
      });

      final response = await auth.getDioClient().post(
        '/AddDraftOrder',
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

      if (_parseJson(response.data)['success'] == true) {
        await _loadCart();
      } else {
        setState(() => item.qty = oldQty);
      }
    } catch (e) {
      setState(() => item.qty = oldQty);
    }
  }

  Future<void> _removeItem(DraftOrderItem item) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Remove item?'),
        content: Text('"${item.name}" will be removed from your order.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton.tonal(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Remove'),
          ),
        ],
      ),
    );
    if (confirm != true) return;
    _apiRemove(item.idCol);
  }

  Future<void> _clearCart() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Empty Cart?'),
        content: const Text('This will remove all items for this account.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Clear All'),
          ),
        ],
      ),
    );
    if (confirm != true) return;
    _apiRemove(0);
  }

  Future<void> _apiRemove(int idCol) async {
    setState(() => _isLoading = true);
    try {
      final auth = Provider.of<AuthService>(context, listen: false);
      final user = auth.currentUser;
      String firmCode = '';
      try {
        if (user != null && user.stores.isNotEmpty) {
          firmCode = user.stores
              .firstWhere((s) => s.primary, orElse: () => user.stores.first)
              .firmCode;
        }
      } catch (_) {}

      final payload = jsonEncode({
        'lUserId': user?.mobileNumber ?? '',
        'lLicNo': user?.licenseNumber ?? '',
        'lFirmCode': firmCode,
        'AcCode': _currentAcCode,
        'lIdCol': idCol,
      });

      final resp = await auth.getDioClient().post(
        '/RemoveDraftOrder',
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

      if (_parseJson(resp.data)['success'] == true) {
        await _loadCart();
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showUpdateBottomSheet(DraftOrderItem item, ColorScheme cs) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        final textTheme = Theme.of(context).textTheme;

        final TextEditingController priceController = TextEditingController(text: (item.rate ?? 0).toStringAsFixed(2));
        final TextEditingController qtyController = TextEditingController(text: item.qty.toString());
        final TextEditingController freeQtyController = TextEditingController(text: (item.freeQty ?? 0).toString());
        final TextEditingController schemeController = TextEditingController(text: '0');
        final TextEditingController discPcsController = TextEditingController(text: (item.disc1Amt ?? 0).toStringAsFixed(2));
        final TextEditingController discPerController = TextEditingController(text: (item.disc2Amt ?? 0).toStringAsFixed(2));
        final TextEditingController addDiscPerController = TextEditingController(text: '0.0');
        final TextEditingController remarkController = TextEditingController(text: item.remark ?? '');

        double price = item.rate ?? 0;
        int available = (item.stock ?? 0).toInt();
        double goodsValue = 0.0, discountValue = 0.0, gst = 0.0, netValue = 0.0;

        void recalc() {
          int qty = int.tryParse(qtyController.text) ?? 1;
          double discPcs = double.tryParse(discPcsController.text) ?? 0.0;
          double discPer = double.tryParse(discPerController.text) ?? 0.0;
          double addDiscPer = double.tryParse(addDiscPerController.text) ?? 0.0;
          price = double.tryParse(priceController.text) ?? (item.rate ?? 0);
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
              fillColor: cs.surfaceContainerHighest.withAlpha(77),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
              prefixIcon: icon != null ? Icon(icon, size: 18) : null,
            );

            return Container(
              decoration: BoxDecoration(
                color: cs.surface,
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
                        decoration: BoxDecoration(color: cs.outlineVariant, borderRadius: BorderRadius.circular(2)),
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
                                    child: Text(item.name, style: textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: cs.primaryContainer,
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Text(
                                      'UPDATE',
                                      style: TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                        color: cs.onPrimaryContainer,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              Text("${item.mfg ?? ''}", style: textTheme.bodySmall),
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
                      decoration: BoxDecoration(color: cs.primaryContainer.withAlpha(102), borderRadius: BorderRadius.circular(16)),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _buildHeaderStatForSheet("Price", "₹${price.toStringAsFixed(2)}", cs),
                          _buildHeaderStatForSheet("Stock", "${available}", cs),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    Row(
                      children: [
                        Expanded(child: TextField(controller: priceController, keyboardType: TextInputType.numberWithOptions(decimal: true), onChanged: (_) => updateFields(), decoration: _inputDeco('Price', icon: Icons.price_check))),
                        const SizedBox(width: 12),
                        Expanded(child: TextField(controller: qtyController, keyboardType: TextInputType.number, onChanged: (_) => updateFields(), decoration: _inputDeco('Quantity', icon: Icons.shopping_basket))),
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
                    Row(
                      children: [
                        Expanded(child: TextField(controller: schemeController, keyboardType: TextInputType.number, onChanged: (_) => updateFields(), decoration: _inputDeco('Scheme', icon: Icons.card_giftcard))),
                        const SizedBox(width: 12),
                        Expanded(child: TextField(controller: remarkController, decoration: _inputDeco('Add Remark', icon: Icons.notes))),
                      ],
                    ),
                    const SizedBox(height: 24),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: cs.surfaceContainerHighest.withAlpha(128),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: cs.outlineVariant),
                      ),
                      child: Column(
                        children: [
                          _buildSummaryRowForSheet("Goods Value", "₹${goodsValue.toStringAsFixed(2)}", textTheme),
                          _buildSummaryRowForSheet("Total Discount", "-₹${discountValue.toStringAsFixed(2)}", textTheme, isNegative: true),
                          _buildSummaryRowForSheet("GST (18%)", "+₹${gst.toStringAsFixed(2)}", textTheme),
                          const Divider(height: 20),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text('Net Payable', style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                              Text('₹${netValue.toStringAsFixed(2)}', style: textTheme.titleLarge?.copyWith(color: cs.primary, fontWeight: FontWeight.bold)),
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
                              backgroundColor: cs.primary,
                              foregroundColor: cs.onPrimary,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              elevation: 0,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            onPressed: () async {
                              int qty = int.tryParse(qtyController.text) ?? 1;
                              if (qty <= 0) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Quantity must be greater than 0')),
                                );
                                return;
                              }
                              await _updateQuantity(item, qty);
                              Navigator.of(context).pop();
                            },
                            child: const Text('UPDATE CART', style: TextStyle(fontWeight: FontWeight.bold)),
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

  Widget _buildHeaderStatForSheet(String label, String value, ColorScheme colorScheme) {
    return Column(
      children: [
        Text(label, style: TextStyle(fontSize: 12, color: colorScheme.primary)),
        Text(value, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
      ],
    );
  }

  Widget _buildSummaryRowForSheet(String label, String value, TextTheme textTheme, {bool isNegative = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: textTheme.bodyMedium?.copyWith(color: isNegative ? Colors.red : null)),
          Text(value, style: textTheme.bodyMedium?.copyWith(
            color: isNegative ? Colors.red : null,
            fontWeight: FontWeight.w500,
          )),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        scrolledUnderElevation: 0,
        backgroundColor: Colors.white,
        elevation: 0,
        title: GestureDetector(
          onTap: _openSelectAccount,
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Review Order',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            color: cs.onSurface,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Icon(Icons.arrow_drop_down, color: cs.primary),
                        const SizedBox(width: 8),
                        // Show account name as a chip if available
                        if (_selectedAccountName != null && _selectedAccountName!.isNotEmpty)
                          Flexible(
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: cs.primary.withAlpha((0.08 * 255).toInt()),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: cs.primary.withAlpha((0.12 * 255).toInt())),
                              ),
                              child: Text(
                                _selectedAccountName!,
                                style: TextStyle(
                                  fontSize: 13,
                                  color: cs.primary,
                                  fontWeight: FontWeight.w600,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      // show account name when available, otherwise show account code
                      _selectedAccountName != null && _selectedAccountName!.isNotEmpty
                          ? _selectedAccountName!
                          : 'A/C: $_currentAcCode',
                      style: TextStyle(
                        fontSize: 12,
                        color: cs.primary,
                        fontWeight: FontWeight.w500,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        actions: [
          IconButton(
            onPressed: _loadCart,
            icon: const Icon(Icons.refresh_rounded),
          ),
          IconButton(
            onPressed: _clearCart,
            icon: const Icon(
              Icons.delete_sweep_outlined,
              color: Colors.redAccent,
            ),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _items.isEmpty
          ? _buildEmptyState(cs)
          : _buildItemList(cs),
      bottomNavigationBar: _items.isEmpty ? null : _buildCheckoutFooter(cs),
    );
  }

  Widget _buildEmptyState(ColorScheme cs) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.shopping_basket_outlined,
            size: 80,
            color: cs.outlineVariant,
          ),
          const SizedBox(height: 16),
          Text(
            'Your cart is empty',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: cs.onSurface,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Change account or add items to start.',
            style: TextStyle(color: cs.onSurfaceVariant),
          ),
          const SizedBox(height: 24),
          FilledButton.tonal(
            onPressed: _openSelectAccount,
            child: const Text('Switch Account'),
          ),
        ],
      ),
    );
  }

  Widget _buildItemList(ColorScheme cs) {
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 100),
      itemCount: _items.length,
      itemBuilder: (context, index) {
        final it = _items[index];
        return Container(
          margin: const EdgeInsets.only(bottom: 12.0),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: cs.outlineVariant.withAlpha((0.5 * 255).toInt())),
          ),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            it.name,
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              letterSpacing: -0.2,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            it.mfg ?? 'No Mfr Info',
                            style: TextStyle(
                              fontSize: 12,
                              color: cs.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                    // delete icon for single item removal
                    IconButton(
                      icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
                      tooltip: 'Remove item',
                      onPressed: () => _removeItem(it),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border(
                    top: BorderSide(color: cs.outlineVariant.withAlpha((0.3 * 255).toInt())),
                  ),
                  borderRadius: const BorderRadius.vertical(
                    bottom: Radius.circular(16),
                  ),
                ),
                child: Column(
                  children: [
                    // Row 1: Price, MRP, Value
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _metric('Price', '₹${it.rate?.toStringAsFixed(2) ?? '0.00'}', cs),
                        _metric('MRP', '₹${it.mrp?.toStringAsFixed(2) ?? '0.00'}', cs),
                        _metric('Value', '₹${it.amt?.toStringAsFixed(2) ?? '0.00'}', cs),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // Row 2: Dis (Pcs), Dis (%), Add Dis (%)
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _metric('Dis (Pcs)', '₹${it.disc1Amt?.toStringAsFixed(2) ?? '0.00'}', cs),
                        _metric('Dis (%)', '₹${it.disc2Amt?.toStringAsFixed(2) ?? '0.00'}', cs),
                        _metric('Add Dis (%)', '₹${((it.discAmt ?? 0) - (it.disc1Amt ?? 0) - (it.disc2Amt ?? 0)).toStringAsFixed(2)}', cs),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // Row 3: Qty, FQty, UPDATE button
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _metric('Qty', '${it.qty}', cs),
                        _metric('FQty', '${it.freeQty ?? 0}', cs),
                        ElevatedButton(
                          onPressed: () => _showUpdateBottomSheet(it, cs),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: cs.primary,
                            foregroundColor: cs.onPrimary,
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          ),
                          child: const Text('UPDATE', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // Row 4: GV, SV, DV, GST
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _metric('GV', '₹${((it.rate ?? 0) * it.qty).toStringAsFixed(2)}', cs),
                        _metric('SV', '₹${(it.discAmt ?? 0).toStringAsFixed(2)}', cs),
                        _metric('DV', '₹${(it.taxAmt ?? 0).toStringAsFixed(2)}', cs),
                        _metric('GST', '₹${((((it.rate ?? 0) * it.qty) - (it.discAmt ?? 0)) * 0.18).toStringAsFixed(2)}', cs),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // Row 5: Net Value
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Net Value', style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant, fontWeight: FontWeight.w600)),
                        Text('₹${(it.netAmt ?? 0).toStringAsFixed(2)}', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: cs.primary)),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _metric(String label, String val, ColorScheme cs) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 10,
            color: cs.onSurfaceVariant,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          val,
          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
        ),
      ],
    );
  }

  Widget _buildCheckoutFooter(ColorScheme cs) {
    final total = _items.fold(0.0, (s, e) => s + (e.amt ?? 0));
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          top: BorderSide(color: cs.outlineVariant.withAlpha((0.3 * 255).toInt())),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha((0.04 * 255).toInt()),
            blurRadius: 10,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Payable Amount',
                    style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant),
                  ),
                  Text(
                    '₹${total.toStringAsFixed(2)}',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                      color: cs.primary,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: FilledButton(
                onPressed: () async {
                  models.Account? account = widget.selectedAccount;
                  if (account == null) {
                    // Try to get the account from AccountSelectionService via Provider
                    final accountService = Provider.of<AccountSelectionService>(context, listen: false);
                    account = accountService.selectedAccount;
                  }
                  if (account == null) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('No account selected.')),
                    );
                    return;
                  }
                  await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => PlaceOrderPage(
                        account: account!, // non-null
                        cartItems: _items,
                        totalAmount: total,
                      ),
                    ),
                  );
                },
                style: FilledButton.styleFrom(
                  minimumSize: const Size(double.infinity, 54),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 0,
                ),
                child: const Text(
                  'Place Order',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class DraftOrderItem {
  final String code;
  final String name;
  final String? mfg;
  int qty;
  final int? freeQty;
  final double? rate;
  final double? mrp;
  final double? amt;
  final double? taxAmt;
  final double? netAmt;
  final double? discAmt;
  final double? disc1Amt;
  final double? disc2Amt;
  final double? stock;
  final int idCol;
  final String? remark;

  DraftOrderItem({
    required this.code,
    required this.name,
    this.mfg,
    required this.qty,
    this.freeQty,
    this.rate,
    this.mrp,
    this.amt,
    this.taxAmt,
    this.netAmt,
    this.discAmt,
    this.disc1Amt,
    this.disc2Amt,
    this.stock,
    required this.idCol,
    this.remark,
  });

  factory DraftOrderItem.fromJson(Map<String, dynamic> json) {
    double? parseDouble(dynamic v) {
      return (v is num) ? v.toDouble() : double.tryParse(v?.toString() ?? '');
    }

    int parseInt(dynamic v) {
      return (v is int) ? v : int.tryParse(v?.toString() ?? '') ?? 0;
    }

    return DraftOrderItem(
      code: (json['Icode'] ?? json['I_CODE'] ?? json['ItemCode'] ?? '')
          .toString(),
      name: (json['Name'] ?? json['IName'] ?? '').toString(),
      mfg: (json['MfgComp'] ?? '').toString(),
      qty: (json['Qty'] is num)
          ? (json['Qty'] as num).toInt()
          : parseInt(json['Qty']),
      freeQty: (json['FQty'] is num)
          ? (json['FQty'] as num).toInt()
          : parseInt(json['FQty'] ?? json['FreeQty'] ?? '0'),
      rate: parseDouble(json['Rate']),
      mrp: parseDouble(json['Mrp']),
      amt: parseDouble(json['Amt']),
      taxAmt: parseDouble(json['TaxAmt']),
      netAmt: parseDouble(json['NetAmt']),
      discAmt: parseDouble(json['DO_DiscAmt']),
      disc1Amt: parseDouble(json['DO_Disc1Amt']),
      disc2Amt: parseDouble(json['DO_Disc2Amt']),
      stock: parseDouble(json['Stock']),
      idCol: parseInt(json['i_id_col'] ?? json['IdCol'] ?? json['Idcol']),
      remark: (json['DO_Remark'] ?? '').toString(),
    );
  }
}
