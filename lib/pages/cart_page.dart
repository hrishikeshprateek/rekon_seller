import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:dio/dio.dart';
import '../auth_service.dart';
import '../models/account_model.dart' as models;
import '../services/account_selection_service.dart';
import '../services/salesman_flags_service.dart';
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
      print('===== ListDraftOrder RESPONSE (cart_page _loadCart) =====');
      print(raw);
      print('==========================================================');
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
      useSafeArea: true,
      builder: (ctx) => _CartUpdateBottomSheet(
        item: item,
        acCode: _currentAcCode,
        onUpdated: () async {
          Navigator.pop(ctx);
          await _loadCart();
        },
      ),
    );
  }

  Future<void> _updateItemWithDetails({
    required DraftOrderItem item,
    required int qty,
    required double price,
    required int freeQty,
    required int schemeQty,
    required double discPcs,
    required double discPer,
    required double addDiscPer,
    required String remark,
    required double goodsValue,
  }) async {
    try {
      final auth = Provider.of<AuthService>(context, listen: false);
      final user = auth.currentUser;
      final cuId = int.tryParse(user?.userId ?? '') ?? 0;
      String firmCode = '';
      try {
        if (user != null && user.stores.isNotEmpty) {
          firmCode = user.stores.firstWhere((s) => s.primary, orElse: () => user.stores.first).firmCode;
        }
      } catch (_) {}

      final payload = {
        'UserId': user?.mobileNumber ?? user?.userId ?? '',
        'LicNo': user?.licenseNumber ?? '',
        'lFirmCode': firmCode,
        'AcCode': _currentAcCode,
        'ItemCode': item.code,
        'IdCol': item.idCol,
        'ItemQty': qty.toString(),
        'ItemRate': price.toStringAsFixed(2),
        'cu_id': cuId,
        'ItemFQty': freeQty.toString(),
        'ItemSchQty': schemeQty.toString(),
        'ItemDSchQty': '0',
        'ItemAmt': goodsValue.toStringAsFixed(2),
        'discount_percentage': discPer.toString(),
        'discount_percentage1': addDiscPer.toString(),
        'discount_pcs': discPcs.toString(),
        'remark': remark,
        'insert_record': 1,
        'default_hit': true,
      };

      final response = await auth.getDioClient().post(
        '/AddDraftOrder',
        data: payload,
        options: Options(headers: {
          'Content-Type': 'application/json',
          'package_name': auth.packageNameHeader,
          if (auth.getAuthHeader() != null) 'Authorization': auth.getAuthHeader(),
        }),
      );

      if (_parseJson(response.data)['success'] == true) {
        await _loadCart();
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to update: ${_parseJson(response.data)['message'] ?? 'Unknown error'}')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
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

        final double gv  = it.amt ?? 0;
        final double sv  = it.schAmt ?? 0;
        final double dv  = (it.discAmt ?? 0) + (it.disc1Amt ?? 0) + (it.disc2Amt ?? 0);
        final double gst = it.taxAmt ?? 0;
        final double net = it.netAmt ?? 0;

        return Stack(
          clipBehavior: Clip.none,
          children: [
            Container(
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: cs.outlineVariant.withAlpha((0.5 * 255).toInt())),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Header: name + mfg + delete ──────────────────────────────
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 14, 8, 10),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            it.name,
                            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, letterSpacing: -0.2),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            it.mfg ?? '',
                            style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete_outline, color: Colors.redAccent, size: 20),
                      tooltip: 'Remove item',
                      onPressed: () => _removeItem(it),
                      constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                    ),
                  ],
                ),
              ),

              Divider(height: 1, color: cs.outlineVariant.withAlpha((0.3 * 255).toInt())),

              // ── Details grid ──────────────────────────────────────────────
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 14),
                child: Column(
                  children: [
                    // Row 1: Price | MRP | Value
                    Row(
                      children: [
                        _metricCell(cs, 'Price',  '₹${(it.rate ?? 0).toStringAsFixed(2)}'),
                        _metricCell(cs, 'MRP',    '₹${(it.mrp  ?? 0).toStringAsFixed(2)}'),
                        _metricCell(cs, 'Value',  '₹${gv.toStringAsFixed(2)}'),
                      ],
                    ),
                    const SizedBox(height: 10),

                    // Row 2: Dis(Pcs) | Dis(%) | Add Dis(%)
                    Row(
                      children: [
                        _metricCell(cs, 'Dis (Pcs)', '${(it.disc2Per ?? 0).toStringAsFixed(1)} (₹${(it.disc2Amt ?? 0).toStringAsFixed(2)})'),
                        _metricCell(cs, 'Dis (%)',   '${(it.discPer ?? 0).toStringAsFixed(0)} (₹${(it.discAmt ?? 0).toStringAsFixed(2)})'),
                        _metricCell(cs, 'Add Dis (%)', '${(it.disc1Per ?? 0).toStringAsFixed(0)} (₹${(it.disc1Amt ?? 0).toStringAsFixed(2)})'),
                      ],
                    ),
                    const SizedBox(height: 10),

                    // Row 3: Qty | FQty | UPDATE
                    Row(
                      children: [
                        _metricCell(cs, 'Qty',  '${it.qty}'),
                        _metricCell(cs, 'FQty', '${it.freeQty ?? 0}'),
                        Expanded(
                          child: Align(
                            alignment: Alignment.centerRight,
                            child: SizedBox(
                              height: 34,
                              child: FilledButton(
                                onPressed: () => _showUpdateBottomSheet(it, cs),
                                style: FilledButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(horizontal: 18),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                ),
                                child: const Text('UPDATE', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    Divider(height: 1, color: cs.outlineVariant.withAlpha((0.25 * 255).toInt())),
                    const SizedBox(height: 10),

                    // Row 4: GV | SV | DV | GST
                    Row(
                      children: [
                        _metricCell(cs, 'GV',  '₹${gv.toStringAsFixed(2)}'),
                        _metricCell(cs, 'SV',  '₹${sv.toStringAsFixed(2)}'),
                        _metricCell(cs, 'DV',  '₹${dv.toStringAsFixed(2)}'),
                        _metricCell(cs, 'GST', '₹${gst.toStringAsFixed(2)}'),
                      ],
                    ),
                    const SizedBox(height: 10),

                    // Row 5: Net Value (full width)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: cs.primary.withAlpha((0.07 * 255).toInt()),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Net Value',
                            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: cs.primary),
                          ),
                          Text(
                            '₹${net.toStringAsFixed(2)}',
                            style: TextStyle(fontSize: 15, fontWeight: FontWeight.w900, color: cs.primary),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
            // ── SchNarr top-right badge ──
            if (it.schNarr != null && it.schNarr!.isNotEmpty)
              Positioned(
                top: -1,
                right: 12,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: Colors.green.shade600,
                    borderRadius: const BorderRadius.vertical(
                      bottom: Radius.circular(8),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const SizedBox(width: 4),
                      Text(
                        it.schNarr!,
                        style: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                          letterSpacing: 0.2,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        );
      },
    );
  }

  Widget _metricCell(ColorScheme cs, String label, String val) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: TextStyle(fontSize: 10, color: cs.onSurfaceVariant, fontWeight: FontWeight.w600)),
          const SizedBox(height: 2),
          Text(val, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }

  Widget _buildCheckoutFooter(ColorScheme cs) {
    final total = _items.fold(0.0, (s, e) => s + (e.netAmt ?? 0));
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
  final double? discPer;
  final double? disc1Per;
  final double? disc2Per;
  final double? stock;
  final int idCol;
  final String? remark;
  final double? schQty;
  final double? dSchQty;
  final String? schNarr;
  final double? schAmt;

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
    this.discPer,
    this.disc1Per,
    this.disc2Per,
    this.stock,
    required this.idCol,
    this.remark,
    this.schQty,
    this.dSchQty,
    this.schNarr,
    this.schAmt,
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
      discPer: parseDouble(json['DO_DiscPer']),
      disc1Per: parseDouble(json['DO_Disc1Per']),
      disc2Per: parseDouble(json['DO_Disc2Per']),
      stock: parseDouble(json['Stock']),
      idCol: parseInt(json['i_id_col'] ?? json['IdCol'] ?? json['Idcol']),
      remark: (json['DO_Remark'] ?? '').toString(),
      schQty: parseDouble(json['SchQty']),
      dSchQty: parseDouble(json['SchDQty']),
      schNarr: (json['SchNarr'] ?? '').toString().trim(),
      schAmt: parseDouble(json['SchAmt']),
    );
  }
}

class _CartUpdateBottomSheet extends StatefulWidget {
  final DraftOrderItem item;
  final String acCode;
  final VoidCallback onUpdated;

  const _CartUpdateBottomSheet({
    Key? key,
    required this.item,
    required this.acCode,
    required this.onUpdated,
  }) : super(key: key);

  @override
  State<_CartUpdateBottomSheet> createState() => _CartUpdateBottomSheetState();
}

class _CartUpdateBottomSheetState extends State<_CartUpdateBottomSheet> {
  late final TextEditingController qtyController;
  late final TextEditingController priceController;
  late final TextEditingController freeQtyController;
  late final TextEditingController schemeController;
  late final TextEditingController dSchemeController;
  late final TextEditingController discPcsController;
  late final TextEditingController discPerController;
  late final TextEditingController addDiscPerController;
  late final TextEditingController remarkController;

  double _goodsValue    = 0.0;
  double _schemeValue   = 0.0;
  double _discountValue = 0.0;
  double _gst           = 0.0;
  double _netValue      = 0.0;

  Timer?  _debounce;
  int     _token   = 0;
  bool    _loading = false;
  bool    _firstBuild = true;

  @override
  void initState() {
    super.initState();
    final it = widget.item;
    qtyController        = TextEditingController(text: it.qty.toString());
    priceController      = TextEditingController(text: (it.rate ?? 0).toStringAsFixed(2));
    freeQtyController    = TextEditingController(text: (it.freeQty ?? 0).toString());
    // scheme: map SchQty / SchDQty
    schemeController     = TextEditingController(text: (it.schQty ?? 0).toStringAsFixed(0));
    dSchemeController    = TextEditingController(text: (it.dSchQty ?? 0).toStringAsFixed(0));
    // discounts: map the *Per fields (inputs), not Amt fields
    discPcsController    = TextEditingController(text: (it.disc2Per ?? 0).toStringAsFixed(2));
    discPerController    = TextEditingController(text: (it.discPer  ?? 0).toStringAsFixed(2));
    addDiscPerController = TextEditingController(text: (it.disc1Per ?? 0).toStringAsFixed(2));
    remarkController     = TextEditingController(text: it.remark ?? '');
  }

  @override
  void dispose() {
    qtyController.dispose();
    priceController.dispose();
    freeQtyController.dispose();
    schemeController.dispose();
    dSchemeController.dispose();
    discPcsController.dispose();
    discPerController.dispose();
    addDiscPerController.dispose();
    remarkController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  Map<String, dynamic> _buildPayload(int insertRecord) {
    final auth = Provider.of<AuthService>(context, listen: false);
    final user = auth.currentUser;
    final cuId = int.tryParse(user?.userId ?? '') ?? 0;
    String firmCode = '';
    try {
      if (user != null && user.stores.isNotEmpty) {
        firmCode = user.stores.firstWhere((s) => s.primary, orElse: () => user.stores.first).firmCode;
      }
    } catch (_) {}
    return {
      'UserId':               user?.mobileNumber ?? user?.userId ?? '',
      'LicNo':                user?.licenseNumber ?? '',
      'lFirmCode':            firmCode,
      'AcCode':               widget.acCode,
      'ItemCode':             widget.item.code,
      'IdCol':                widget.item.idCol,
      'ItemQty':              qtyController.text.trim(),
      'ItemRate':             priceController.text.trim(),
      'cu_id':                cuId,
      'ItemFQty':             freeQtyController.text.trim().isEmpty    ? '0' : freeQtyController.text.trim(),
      'ItemSchQty':           schemeController.text.trim().isEmpty     ? '0' : schemeController.text.trim(),
      'ItemDSchQty':          dSchemeController.text.trim().isEmpty    ? '0' : dSchemeController.text.trim(),
      'ItemAmt':              ((double.tryParse(priceController.text) ?? 0) * (int.tryParse(qtyController.text) ?? 0)).toStringAsFixed(2),
      'discount_percentage':  discPerController.text.trim(),
      'discount_percentage1': addDiscPerController.text.trim(),
      'discount_pcs':         discPcsController.text.trim(),
      'remark':               remarkController.text.trim(),
      'insert_record':        insertRecord,
      'default_hit':          true,
    };
  }

  void _onChanged() {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 350), () async {
      final qty = int.tryParse(qtyController.text.trim()) ?? 0;
      if (qty <= 0) {
        if (mounted) setState(() { _goodsValue = 0; _schemeValue = 0; _discountValue = 0; _gst = 0; _netValue = 0; _loading = false; });
        return;
      }
      final t = ++_token;
      if (mounted) setState(() => _loading = true);
      try {
        final auth = Provider.of<AuthService>(context, listen: false);
        final resp = await auth.getDioClient().post(
          '/AddDraftOrder',
          data: _buildPayload(0),
          options: Options(headers: {
            'Content-Type': 'application/json',
            'package_name': auth.packageNameHeader,
            if (auth.getAuthHeader() != null) 'Authorization': auth.getAuthHeader(),
          }),
        );
        if (!mounted || t != _token) return;
        final parsed = _parseResp(resp.data);
        if (parsed['success'] == true && parsed['data'] != null) {
          final d = parsed['data'];
          double pd(dynamic v) => v is num ? v.toDouble() : double.tryParse(v?.toString() ?? '') ?? 0.0;
          setState(() {
            _goodsValue    = pd(d['Amt']);
            _schemeValue   = pd(d['ItemSchAmt']);
            _discountValue = pd(d['totalDisc']);
            _gst           = pd(d['ItemTaxAmt']);
            _netValue      = pd(d['ItemNetAmt']);
            _loading       = false;
          });
        } else {
          if (mounted) setState(() => _loading = false);
        }
      } catch (_) {
        if (mounted) setState(() => _loading = false);
      }
    });
  }

  Future<void> _submit() async {
    try {
      final auth = Provider.of<AuthService>(context, listen: false);
      final payload = _buildPayload(1);
      print('===== AddDraftOrder REQUEST (cart_page _submit) =====');
      print(jsonEncode(payload));
      print('======================================================');
      final response = await auth.getDioClient().post(
        '/AddDraftOrder',
        data: payload,
        options: Options(headers: {
          'Content-Type': 'application/json',
          'package_name': auth.packageNameHeader,
          if (auth.getAuthHeader() != null) 'Authorization': auth.getAuthHeader(),
        }),
      );
      final parsed = _parseResp(response.data);
      print('===== AddDraftOrder RESPONSE (cart_page _submit) =====');
      print(response.data);
      print('=======================================================');
      if (parsed['success'] == true) {
        widget.onUpdated();
      } else {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed: ${parsed['message'] ?? 'Unknown error'}')));
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  Map<String, dynamic> _parseResp(dynamic raw) {
    if (raw is Map<String, dynamic>) return raw;
    if (raw is String) {
      final clean = raw.replaceAll(RegExp(r'[\x00-\x1F\x7F]'), '').trim();
      return jsonDecode(clean) as Map<String, dynamic>;
    }
    return jsonDecode(jsonEncode(raw)) as Map<String, dynamic>;
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final int available = (widget.item.stock ?? 0).toInt();

    // Get salesman flags from service
    final flagsService = Provider.of<SalesmanFlagsService>(context, listen: false);
    final flags = flagsService.flags;

    // Get visibility flags with defaults (show if flags not loaded)
    final showFreeQty = flags?.showFreeQtySalesMan ?? true;
    final showScheme = flags?.showSchemeSalesMan ?? true;
    final showPrice = flags?.enablePriceSalesMan ?? true;
    final showDiscPcs = flags?.showDiscPcsSalesMan ?? true;
    final showDiscPer = flags?.showDiscPerSalesMan ?? true;
    final showAddDiscPer = flags?.showdisc1perSalesman ?? true;
    final showRemark = flags?.showItemRemarkSalesMan ?? true;
    final showAddDetailsBottomSheet = flags?.showadddetailsbottomsheetSalesMan ?? true;

    // Log flag visibility for debugging
    debugPrint('[CartUpdateBottomSheet] === FIELD VISIBILITY FLAGS ===');
    debugPrint('[CartUpdateBottomSheet] showFreeQty: $showFreeQty (ShowFreeQty_SalesMan)');
    debugPrint('[CartUpdateBottomSheet] showScheme: $showScheme (ShowScheme_SalesMan)');
    debugPrint('[CartUpdateBottomSheet] showPrice: $showPrice (EnablePrice_SalesMan)');
    debugPrint('[CartUpdateBottomSheet] showDiscPcs: $showDiscPcs (ShowDiscPcs_SalesMan)');
    debugPrint('[CartUpdateBottomSheet] showDiscPer: $showDiscPer (ShowDiscPer_SalesMan)');
    debugPrint('[CartUpdateBottomSheet] showAddDiscPer: $showAddDiscPer (showdisc1per_Salesman)');
    debugPrint('[CartUpdateBottomSheet] showRemark: $showRemark (ShowItemRemark_SalesMan)');
    debugPrint('[CartUpdateBottomSheet] showAddDetailsBottomSheet: $showAddDetailsBottomSheet (Showadddetailsbottomsheet_SalesMan)');
    debugPrint('[CartUpdateBottomSheet] ===========================');

    // Trigger preview on first open with existing values
    if (_firstBuild) {
      _firstBuild = false;
      WidgetsBinding.instance.addPostFrameCallback((_) => _onChanged());
    }

    // Shared input decoration
    InputDecoration fieldDeco(ColorScheme csc) => InputDecoration(
      hintText: '0',
      hintStyle: TextStyle(color: csc.onSurfaceVariant.withValues(alpha: 0.4), fontWeight: FontWeight.normal),
      isDense: true,
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      filled: true,
      fillColor: csc.surfaceContainerHighest.withValues(alpha: 0.5),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: csc.outlineVariant.withValues(alpha: 0.3))),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: csc.outlineVariant.withValues(alpha: 0.3))),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: csc.primary, width: 2)),
    );

    Widget sectionLabel(String title) => Row(
      children: [
        Container(width: 3, height: 16, decoration: BoxDecoration(color: cs.primary, borderRadius: BorderRadius.circular(2))),
        const SizedBox(width: 8),
        Text(title, style: textTheme.labelMedium?.copyWith(fontWeight: FontWeight.w800, color: cs.primary, letterSpacing: 1.2)),
      ],
    );

    Widget rowField(String label, TextEditingController ctrl, TextInputType kbType) => Row(
      children: [
        Expanded(child: Text(label, style: textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600))),
        SizedBox(
          width: 130,
          child: TextField(
            controller: ctrl,
            keyboardType: kbType,
            textAlign: TextAlign.right,
            onChanged: (_) => _onChanged(),
            style: textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
            decoration: fieldDeco(cs),
          ),
        ),
      ],
    );

    Widget rowFieldWithAmt(String label, TextEditingController ctrl, double amt) => Row(
      children: [
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(label, style: textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600)),
            const SizedBox(height: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
              decoration: BoxDecoration(
                color: amt > 0 ? Colors.red.shade50 : cs.surfaceContainerHighest.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: amt > 0 ? Colors.red.shade200 : cs.outlineVariant.withValues(alpha: 0.4), width: 0.8),
              ),
              child: Text('- ₹${amt.toStringAsFixed(2)}', style: textTheme.labelSmall?.copyWith(color: amt > 0 ? Colors.red.shade700 : cs.outline, fontWeight: FontWeight.w700)),
            ),
          ]),
        ),
        const SizedBox(width: 12),
        SizedBox(
          width: 130,
          child: TextField(
            controller: ctrl,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            textAlign: TextAlign.right,
            onChanged: (_) => _onChanged(),
            style: textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
            decoration: fieldDeco(cs),
          ),
        ),
      ],
    );

    Widget infoChip(String label, IconData icon, Color color) => Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(20), border: Border.all(color: color.withValues(alpha: 0.25))),
      child: Row(mainAxisSize: MainAxisSize.min, children: [Icon(icon, size: 13, color: color), const SizedBox(width: 4), Text(label, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: color))]),
    );

    Widget summaryRow(String label, String value, {bool isNegative = false}) => Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: textTheme.bodySmall?.copyWith(color: cs.onSurfaceVariant, fontWeight: FontWeight.w500)),
        Text(value, style: textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w700, color: isNegative ? Colors.red.shade600 : cs.onSurface)),
      ],
    );

    return AnimatedPadding(
      duration: const Duration(milliseconds: 150),
      curve: Curves.easeOut,
      padding: MediaQuery.of(context).viewInsets,
      child: Container(
        decoration: BoxDecoration(color: cs.surface, borderRadius: const BorderRadius.vertical(top: Radius.circular(24))),
        child: DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.92,
          minChildSize: 0.5,
          maxChildSize: 0.95,
          builder: (ctx, scroll) => Column(children: [
            Container(margin: const EdgeInsets.only(top: 12, bottom: 4), width: 40, height: 4, decoration: BoxDecoration(color: cs.outlineVariant, borderRadius: BorderRadius.circular(2))),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 12, 12),
              child: Row(children: [
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(widget.item.name, style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800), maxLines: 2, overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 2),
                  Text(widget.item.mfg ?? '', style: textTheme.bodySmall?.copyWith(color: cs.onSurfaceVariant)),
                ])),
                IconButton.filledTonal(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.close_rounded, size: 18), style: IconButton.styleFrom(minimumSize: const Size(36, 36), padding: EdgeInsets.zero)),
              ]),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
              child: Wrap(spacing: 8, runSpacing: 6, children: [
                infoChip('₹${(widget.item.rate ?? 0).toStringAsFixed(2)}', Icons.sell_outlined, cs.primary),
                if ((widget.item.mrp ?? 0) > 0) infoChip('MRP ₹${(widget.item.mrp ?? 0).toStringAsFixed(2)}', Icons.price_change_outlined, cs.secondary),
                infoChip(available > 0 ? 'Stock: $available' : 'Out of Stock', available > 0 ? Icons.inventory_2_outlined : Icons.remove_shopping_cart_outlined, available > 0 ? Colors.green.shade600 : cs.error),
              ]),
            ),
            Divider(height: 1, thickness: 0.5, color: cs.outlineVariant),
            Expanded(child: SingleChildScrollView(
              controller: scroll,
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                sectionLabel('ORDER DETAILS'), const SizedBox(height: 14),
                rowField('Quantity', qtyController, TextInputType.number), const SizedBox(height: 12),
                if (showFreeQty) ...[
                  rowField('Free Quantity', freeQtyController, TextInputType.number), const SizedBox(height: 12),
                ],
                if (showScheme) ...[
                  Row(children: [
                    Expanded(child: Text('Scheme', style: textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600))),
                    SizedBox(width: 56, child: TextField(controller: schemeController, keyboardType: TextInputType.number, textAlign: TextAlign.center, onChanged: (_) => _onChanged(), style: textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700), decoration: fieldDeco(cs))),
                    Padding(padding: const EdgeInsets.symmetric(horizontal: 6), child: Text('+', style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700, color: cs.primary))),
                    SizedBox(width: 56, child: TextField(controller: dSchemeController, keyboardType: TextInputType.number, textAlign: TextAlign.center, onChanged: (_) => _onChanged(), style: textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700), decoration: fieldDeco(cs))),
                  ]),
                  const SizedBox(height: 12),
                ],
                if (showPrice) ...[
                  rowField('Price', priceController, const TextInputType.numberWithOptions(decimal: true)),
                  const SizedBox(height: 20),
                ],
                if (showDiscPcs || showDiscPer || showAddDiscPer) ...[
                  sectionLabel('DISCOUNTS'), const SizedBox(height: 14),
                  if (showDiscPcs) ...[
                    rowFieldWithAmt('Discount (Pcs)', discPcsController, widget.item.disc2Amt ?? 0.0), const SizedBox(height: 12),
                  ],
                  if (showDiscPer) ...[
                    rowFieldWithAmt('Discount (%)',   discPerController,  widget.item.discAmt  ?? 0.0), const SizedBox(height: 12),
                  ],
                  if (showAddDiscPer) ...[
                    rowFieldWithAmt('Add. Discount (%)', addDiscPerController, widget.item.disc1Amt ?? 0.0),
                  ],
                  const SizedBox(height: 20),
                ],
                if (showRemark) ...[
                  Text('Add Remark (Optional)', style: textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 8),
                  TextField(controller: remarkController, maxLength: 200, maxLines: 2, style: textTheme.bodyMedium,
                    decoration: fieldDeco(cs).copyWith(hintText: 'Type here...', contentPadding: const EdgeInsets.all(12), counterText: '')),
                  const SizedBox(height: 24),
                ],
                // Summary - Conditional rendering based on flag
                if (showAddDetailsBottomSheet) ...[
                  Container(
                    decoration: BoxDecoration(color: cs.surfaceContainerLow, borderRadius: BorderRadius.circular(16), border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.3))),
                    child: Column(children: [
                      Padding(padding: const EdgeInsets.fromLTRB(16, 14, 16, 10), child: Column(children: [
                        summaryRow('Goods Value',    '₹${_goodsValue.toStringAsFixed(2)}'),    const SizedBox(height: 8),
                        summaryRow('Scheme Value',   '₹${_schemeValue.toStringAsFixed(2)}'),   const SizedBox(height: 8),
                        summaryRow('Discount Value', '-₹${_discountValue.toStringAsFixed(2)}', isNegative: true), const SizedBox(height: 8),
                        summaryRow('GST (Excl.)',    '₹${_gst.toStringAsFixed(2)}'),
                      ])),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                        decoration: BoxDecoration(color: cs.primary.withValues(alpha: 0.08), borderRadius: const BorderRadius.vertical(bottom: Radius.circular(16)), border: Border(top: BorderSide(color: cs.primary.withValues(alpha: 0.15)))),
                        child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                          Text('Net Value', style: textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800, color: cs.primary)),
                          Text('₹${_netValue.toStringAsFixed(2)}', style: textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900, color: cs.primary, letterSpacing: -0.5)),
                        ]),
                      ),
                    ]),
                  ),
                  const SizedBox(height: 24),
                ],
                if (_loading) ...[const SizedBox(height: 12), const LinearProgressIndicator(minHeight: 3)],
                const SizedBox(height: 24),
                Row(children: [
                  Expanded(child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 14), side: BorderSide(color: cs.outlineVariant), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                    child: Text('CLOSE', style: textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w700, letterSpacing: 0.8)),
                  )),
                  const SizedBox(width: 12),
                  Expanded(flex: 2, child: FilledButton(
                    onPressed: () async {
                      if ((int.tryParse(qtyController.text) ?? 0) <= 0) {
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Quantity must be greater than 0')));
                        return;
                      }
                      await _submit();
                    },
                    style: FilledButton.styleFrom(backgroundColor: cs.secondary, foregroundColor: cs.onSecondary, padding: const EdgeInsets.symmetric(vertical: 14), elevation: 0, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                    child: Text('UPDATE CART', style: textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w800, letterSpacing: 0.8)),
                  )),
                ]),
              ]),
            )),
          ]),
        ),
      ),
    );
  }

}




