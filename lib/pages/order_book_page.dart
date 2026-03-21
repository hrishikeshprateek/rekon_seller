import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../auth_service.dart';
import '../models/account_model.dart' as models;
import 'do_account_selector_page.dart';
import 'dart:convert';
import 'package:dio/dio.dart';
import 'order_detail_page.dart';
import 'package:intl/intl.dart';

class OrderBookPage extends StatefulWidget {
  const OrderBookPage({Key? key}) : super(key: key);

  @override
  State<OrderBookPage> createState() => _OrderBookPageState();
}

class _OrderBookPageState extends State<OrderBookPage> {
  models.Account? _selectedAccount;
  bool _isLoading = false;
  String? _error;
  List<dynamic> _orders = [];
  bool _accountSelectionTriggered = false;
  DateTime? _fromDate;
  DateTime? _tillDate;

  @override
  void initState() {
    super.initState();
    _fromDate = DateTime.now().subtract(const Duration(days: 30)); // default 30 days ago
    _tillDate = DateTime.now(); // default today
    _fetchOrders();
  }

  // --- LOGIC REMAINS EXACTLY THE SAME ---

  Future<void> _selectAccountAndFetchOrders() async {
    final account = await DoAccountSelectorPage.show(context);
    if (account != null) {
      setState(() {
        _selectedAccount = account;
      });
      _fetchOrders();
    } else {
      // If user cancels and no account was previously selected, exit to home
      if (!mounted) return;
      if (_selectedAccount == null) Navigator.of(context).pop();
    }
  }

  Future<void> _fetchOrders() async {
    setState(() {
      _isLoading = true;
      _error = null;
      _orders = [];
    });
    try {
      final auth = Provider.of<AuthService>(context, listen: false);
      final dio = auth.getDioClient();
      final user = auth.currentUser;
      String firmCode = '';
      try {
        if (user != null && user.stores.isNotEmpty) {
          final primary = user.stores.firstWhere((s) => s.primary, orElse: () => user.stores.first);
          firmCode = primary.firmCode;
        }
      } catch (_) {}
      final acCode = _selectedAccount?.code ?? (_selectedAccount?.acIdCol?.toString() ?? _selectedAccount?.id ?? '');
      final fromDateStr = DateFormat('yyyy-MM-dd').format(_fromDate ?? DateTime.now().subtract(const Duration(days: 30)));
      final tillDateStr = DateFormat('yyyy-MM-dd').format(_tillDate ?? DateTime.now());
      final payload = {
        'lUserId': user?.mobileNumber ?? user?.userId ?? '',
        'lLicNo': user?.licenseNumber ?? '',
        'lFirmCode': firmCode,
        'lStatus': -1,
        'AcCode': acCode,
        'from_date': fromDateStr,
        'till_date': tillDateStr,
        'app_role': 'SalesMan',
      };
      final headers = {
        'Content-Type': 'application/json',
        'package_name': auth.packageNameHeader,
        if (auth.getAuthHeader() != null) 'Authorization': auth.getAuthHeader(),
      };
      final response = await dio.post('/GetOrderList', data: payload, options: Options(headers: headers));
      final raw = response.data;
      Map<String, dynamic> parsed = {};
      if (raw is Map<String, dynamic>) {
        parsed = raw;
      } else if (raw is String) {
        final clean = raw.replaceAll(RegExp(r'[\x00-\x1F\x7F]'), '');
        parsed = jsonDecode(clean) as Map<String, dynamic>;
      } else {
        parsed = jsonDecode(jsonEncode(raw)) as Map<String, dynamic>;
      }

      if (parsed['success'] == true && parsed['data'] != null && parsed['data'] is List) {
        setState(() {
          _orders = List.from(parsed['data']);
          _isLoading = false;
        });
      } else {
        setState(() {
          _error = parsed['message']?.toString() ?? 'Failed to fetch orders';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  void _openOrderDetail(dynamic order) async {
    final auth = Provider.of<AuthService>(context, listen: false);
    final dio = auth.getDioClient();
    final headers = {
      'Content-Type': 'application/json',
      'package_name': auth.packageNameHeader,
      if (auth.getAuthHeader() != null) 'Authorization': auth.getAuthHeader(),
    };
    final payload = {
      'lId': order['OrderId'],
      'app_role': 'SalesMan',
    };
    try {
      final response = await dio.post('/GetOrderDetail', data: payload, options: Options(headers: headers));
      final raw = response.data;
      debugPrint('=== GetOrderDetail RAW RESPONSE ===');
      final rawStr = raw is String ? raw : jsonEncode(raw);
      // Print in 800-char chunks to avoid truncation
      for (int i = 0; i < rawStr.length; i += 800) {
        debugPrint(rawStr.substring(i, i + 800 > rawStr.length ? rawStr.length : i + 800));
      }
      debugPrint('=== END (total ${rawStr.length} chars) ===');
      Map<String, dynamic> parsed = {};
      if (raw is Map<String, dynamic>) {
        parsed = raw;
      } else if (raw is String) {
        final clean = raw.replaceAll(RegExp(r'[\x00-\x1F\x7F]'), '');
        parsed = jsonDecode(clean) as Map<String, dynamic>;
      } else {
        parsed = jsonDecode(jsonEncode(raw)) as Map<String, dynamic>;
      }
      if (parsed['success'] == true && parsed['data'] != null && parsed['data'] is List && parsed['data'].isNotEmpty) {
        final List<dynamic> products = List.from(parsed['data']);
        if (mounted) {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => OrderDetailPage(orderDetail: products[0], products: products),
            ),
          );
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(parsed['message']?.toString() ?? 'Failed to fetch order details')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${e.toString()}')),
      );
    }
  }

  void _pickDateRange() async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      initialDateRange: DateTimeRange(
        start: _fromDate ?? DateTime.now().subtract(const Duration(days: 30)),
        end: _tillDate ?? DateTime.now(),
      ),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: Theme.of(context).colorScheme.copyWith(
              surface: Colors.white,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() {
        _fromDate = picked.start;
        _tillDate = picked.end;
      });
      _fetchOrders();
    }
  }

  // --- MODERN MATERIAL 3 UI HELPERS ---

  Widget _buildStatusChip(String? status) {
    final String safeStatus = status ?? 'Unknown';
    final bool isPending = safeStatus.toLowerCase() == 'pending';

    final Color bgColor = isPending ? Colors.orange.shade50 : Colors.green.shade50;
    final Color textColor = isPending ? Colors.orange.shade800 : Colors.green.shade800;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: textColor.withAlpha((0.2 * 255).toInt())),
      ),
      child: Text(
        safeStatus,
        style: TextStyle(
          color: textColor,
          fontSize: 12,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value, ColorScheme cs) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 16, color: cs.onSurfaceVariant.withAlpha((0.7 * 255).toInt())),
          const SizedBox(width: 8),
          Expanded(
            child: RichText(
              text: TextSpan(
                style: TextStyle(fontSize: 13, color: cs.onSurfaceVariant),
                children: [
                  TextSpan(text: '$label: '),
                  TextSpan(
                    text: value,
                    style: TextStyle(color: cs.onSurface, fontWeight: FontWeight.w500),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // --- MAIN BUILD METHOD ---

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    // Trigger account selection if not selected
    if (_selectedAccount == null && !_accountSelectionTriggered) {
      _accountSelectionTriggered = true;
      Future.microtask(_selectAccountAndFetchOrders);
    }

    final String dateRangeText = _fromDate != null && _tillDate != null
        ? '${DateFormat('MMM dd, yyyy').format(_fromDate!)} - ${DateFormat('MMM dd, yyyy').format(_tillDate!)}'
        : 'Select Date Range';

    return Scaffold(
      backgroundColor: cs.surfaceContainerLowest,
      appBar: AppBar(
        title: const Text('Order Book', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 18)),
        centerTitle: true,
        backgroundColor: cs.surfaceContainerLowest,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        actions: [
          if (_selectedAccount != null)
            IconButton(
              icon: Icon(Icons.switch_account_outlined, color: cs.primary),
              onPressed: _selectAccountAndFetchOrders,
              tooltip: 'Change Account',
            ),
        ],
      ),
      body: Column(
        children: [
          // Sleek Date Range Filter Bar
          InkWell(
            onTap: _pickDateRange,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: cs.surface,
                border: Border(
                  bottom: BorderSide(color: cs.outlineVariant.withAlpha((0.5 * 255).toInt())),
                  top: BorderSide(color: cs.outlineVariant.withAlpha((0.5 * 255).toInt())),
                ),
              ),
              child: Row(
                children: [
                  Icon(Icons.calendar_today_rounded, size: 18, color: cs.primary),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      dateRangeText,
                      style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: cs.onSurface
                      ),
                    ),
                  ),
                  Icon(Icons.arrow_drop_down, color: cs.onSurfaceVariant),
                ],
              ),
            ),
          ),

          Expanded(
            child: _isLoading
                ? Center(child: CircularProgressIndicator(color: cs.primary))
                : _error != null
                ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline, size: 48, color: cs.error),
                  const SizedBox(height: 16),
                  Text(_error!, style: TextStyle(color: cs.error, fontSize: 14)),
                ],
              ),
            )
                : _orders.isEmpty
                ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.receipt_long_outlined, size: 64, color: cs.outline),
                  const SizedBox(height: 16),
                  Text('No orders found.', style: TextStyle(color: cs.onSurfaceVariant, fontSize: 16)),
                ],
              ),
            )
                : ListView.builder(
              padding: const EdgeInsets.only(top: 12, bottom: 24),
              itemCount: _orders.length,
              itemBuilder: (context, idx) {
                final order = _orders[idx];

                return Card(
                  margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                    side: BorderSide(color: cs.outlineVariant),
                  ),
                  clipBehavior: Clip.antiAlias, // Ensures InkWell ripple respects rounded corners
                  child: InkWell(
                    onTap: () => _openOrderDetail(order),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // --- TOP SECTION: Title & Status ---
                        Padding(
                          padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      order['Ac_Name'] ?? 'Account',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                        color: cs.onSurface,
                                        height: 1.2,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'Order ID: #${order['OrderId'] ?? 'N/A'}',
                                      style: TextStyle(fontSize: 12, color: cs.primary, fontWeight: FontWeight.w600),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 8),
                              _buildStatusChip(order['OrderStatus']),
                            ],
                          ),
                        ),

                        Divider(height: 1, color: cs.outlineVariant.withAlpha((0.5 * 255).toInt())),

                        // --- MIDDLE SECTION: Details ---
                        Padding(
                          padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                          child: Column(
                            children: [
                              _buildInfoRow(Icons.calendar_today_outlined, 'Placed On', order['PlacedOn'] ?? '-', cs),
                              _buildInfoRow(
                                  Icons.local_shipping_outlined,
                                  'Delivery',
                                  '${order['DeliveryDate'] ?? '-'} (${order['DeliveryMode'] ?? '-'})',
                                  cs
                              ),
                              _buildInfoRow(Icons.shopping_bag_outlined, 'Total Items', '${order['NoOfItem'] ?? '0'}', cs),
                              _buildInfoRow(Icons.payment_outlined, 'Payment', order['PaymentMode'] ?? '-', cs),
                            ],
                          ),
                        ),

                        // --- BOTTOM SECTION: Financial Summary Box ---
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: cs.surfaceContainerHighest.withAlpha((0.3 * 255).toInt()),
                          ),
                          child: Column(
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text('Item Amt: ₹${order['ItemAmt'] ?? '0'}', style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant)),
                                  Text('Sch Amt: ₹${order['SchAmt'] ?? '0'}', style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant)),
                                  Text('Tax: ₹${order['TaxAmt'] ?? '0'}', style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant)),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text('Order Value', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: cs.onSurface)),
                                  Text(
                                    '₹${order['OrderValue'] ?? '0.00'}',
                                    style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18, color: cs.primary),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
