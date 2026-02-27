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
                    _buildQtyPicker(it, cs),
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
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _metric('Rate', '₹${it.rate?.toStringAsFixed(2)}', cs),
                        _metric('MRP', '₹${it.mrp?.toStringAsFixed(2)}', cs),
                        _metric('Value', '₹${it.amt?.toStringAsFixed(2)}', cs),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _metric('GV', '₹${(it.rate ?? 0) * (it.qty)}', cs),
                        _metric('SV', '₹${it.discAmt?.toStringAsFixed(2)}', cs),
                        _metric('DV', '₹${it.taxAmt?.toStringAsFixed(2)}', cs),
                        _metric('GST', '₹${it.netAmt?.toStringAsFixed(2)}', cs),
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

  Widget _buildQtyPicker(DraftOrderItem it, ColorScheme cs) {
    return Container(
      decoration: BoxDecoration(
        color: cs.primaryContainer.withAlpha((0.15 * 255).toInt()),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: cs.primary.withAlpha((0.1 * 255).toInt())),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            onPressed: () => _updateQuantity(it, (it.qty - 1).clamp(0, 9999)),
            icon: const Icon(Icons.remove, size: 16),
            constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
            color: cs.primary,
          ),
          Text(
            it.qty.toString(),
            style: TextStyle(fontWeight: FontWeight.bold, color: cs.onSurface),
          ),
          IconButton(
            onPressed: () => _updateQuantity(it, it.qty + 1),
            icon: const Icon(Icons.add, size: 16),
            constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
            color: cs.primary,
          ),
        ],
      ),
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
      rate: parseDouble(json['Rate']),
      mrp: parseDouble(json['Mrp']),
      amt: parseDouble(json['Amt'] ?? json['NetAmt']),
      taxAmt: parseDouble(json['TaxAmt']),
      netAmt: parseDouble(json['NetAmt']),
      discAmt: parseDouble(json['DO_DiscAmt']),
      disc1Amt: parseDouble(json['DO_Disc1Amt'] ?? json['DO_Disc1Amt']),
      disc2Amt: parseDouble(json['DO_Disc2Amt'] ?? json['DO_Disc2Amt']),
      stock: parseDouble(json['Stock']),
      idCol: parseInt(json['i_id_col'] ?? json['IdCol'] ?? json['Idcol']),
      remark: (json['DO_Remark'] ?? '').toString(),
    );
  }
}
