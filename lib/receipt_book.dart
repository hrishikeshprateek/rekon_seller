import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:dio/dio.dart';
import 'dart:convert';
import 'auth_service.dart';
import 'pages/receipt_details_page.dart';

class ReceiptBookPage extends StatefulWidget {
  const ReceiptBookPage({super.key});

  @override
  State<ReceiptBookPage> createState() => _ReceiptBookPageState();
}

class _ReceiptBookPageState extends State<ReceiptBookPage> {
  // API state
  List<Map<String, dynamic>> _receipts = [];
  bool _isLoading = false;
  String? _error;

  // Filter state
  String _selectedMode = 'All';
  final List<String> _modeOptions = ['All', 'Bank', 'CASH'];

  String _selectedDateFilter = 'All';
  final List<String> _dateFilterOptions = [
    'All',
    'Today',
    'Yesterday',
    'This Week',
    'This Month',
    'This Year',
    'Custom',
  ];
  DateTime? _fromDate;
  DateTime? _toDate;

  // Firm filter state
  String _selectedFirmName = 'All';

  List<String> get _firmNames {
    final names = <String>{};
    for (final r in _receipts) {
      final name = (r['FirmName']?.toString().trim() ?? '');
      if (name.isNotEmpty) names.add(name);
    }
    final list = names.toList()..sort();
    return ['All', ...list];
  }

  List<Map<String, dynamic>> get _visibleReceipts {
    if (_selectedFirmName == 'All') return _receipts;
    return _receipts.where((r) => (r['FirmName']?.toString().trim() ?? '') == _selectedFirmName).toList();
  }

  @override
  void initState() {
    super.initState();
    _fetchReceipts();
  }

  Future<void> _fetchReceipts() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final auth = Provider.of<AuthService>(context, listen: false);
      final dio = auth.getDioClient();

      String firmCode = '';

      try {
        final stores = auth.currentUser?.stores ?? [];
        debugPrint('[ReceiptBook] User has ${stores.length} stores');

        if (stores.isNotEmpty) {
          // Debug each store
          for (var i = 0; i < stores.length; i++) {
            debugPrint('[ReceiptBook] Store $i: firmCode=${stores[i].firmCode}, primary=${stores[i].primary}');
          }

          final primary = stores.firstWhere((s) => s.primary,
              orElse: () => stores.first);
          firmCode = primary.firmCode;
          debugPrint('[ReceiptBook] Selected firmCode: $firmCode');
        } else {
          debugPrint('[ReceiptBook] No stores found for user');
        }
      } catch (e) {
        debugPrint('[ReceiptBook] Error getting firmCode: $e');
        firmCode = '';
      }

      debugPrint('[ReceiptBook] User ID: ${auth.currentUser?.userId}');
      debugPrint('[ReceiptBook] Mobile Number: ${auth.currentUser?.mobileNumber}');
      debugPrint('[ReceiptBook] License: ${auth.currentUser?.licenseNumber}');

      final payload = {
        'lLicNo': auth.currentUser?.licenseNumber ?? '',
        'lUserId': auth.currentUser?.mobileNumber ?? '',
        'lFirmCode': firmCode,
        'lStatus': 0,
        'AcCode': '',
        'from_date': _fromDate != null ? DateFormat('yyyy-MM-dd').format(_fromDate!) : '',
        'till_date': _toDate != null ? DateFormat('yyyy-MM-dd').format(_toDate!) : '',
        'mode': _selectedMode,
      };

      debugPrint('[ReceiptBook] GetReceiptBook payload: ${jsonEncode(payload)}');

      final response = await dio.post(
        '/GetReceiptBook',
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

      String raw = response.data?.toString() ?? '';
      String clean = raw.replaceAll(RegExp(r'[\x00-\x1F\x7F]'), '').trim();
      Map<String, dynamic> data;
      try {
        final decoded = jsonDecode(clean);
        data = decoded is Map<String, dynamic>
            ? decoded
            : {'Message': decoded.toString()};
      } catch (_) {
        data = {'Message': clean};
      }

      debugPrint('[ReceiptBook] Response: ${jsonEncode(data)}');

      if (data['success'] == true) {
        debugPrint('[ReceiptBook] Response has success=true');
        debugPrint('[ReceiptBook] data keys: ${data['data']?.keys.toList()}');

        final items = (data['data']?['Item'] as List<dynamic>? ?? [])
            .map((e) => Map<String, dynamic>.from(e as Map))
            .toList();

        debugPrint('[ReceiptBook] Parsed ${items.length} items from response');

        // Debug: Print each receipt
        for (var i = 0; i < items.length; i++) {
          debugPrint('[ReceiptBook] Receipt $i: ID=${items[i]['id']}, Amount=${items[i]['amount']}, Name=${items[i]['acName']}');
        }

        setState(() {
          _receipts = items;
          _isLoading = false;
        });

        debugPrint('[ReceiptBook] Loaded ${_receipts.length} receipts into state');
      } else {
        setState(() {
          _error = data['message'] ?? 'Failed to load receipts';
          _isLoading = false;
        });
      }
    } catch (e, stackTrace) {
      debugPrint('[ReceiptBook] Error: $e');
      debugPrint('[ReceiptBook] Stack trace: $stackTrace');
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  double get _totalAmount {
    return _receipts.fold(0.0, (sum, item) {
      final amount = item['amount'];
      if (amount is num) return sum + amount.toDouble();
      return sum + (double.tryParse(amount?.toString() ?? '0') ?? 0.0);
    });
  }

  void _applyDateFilter(String? type) {
    if (type == null) return;

    if (type == 'All') {
      setState(() {
        _selectedDateFilter = 'All';
        _fromDate = null;
        _toDate = null;
      });
      _fetchReceipts();
      return;
    }

    if (type == 'Custom') {
      setState(() {
        _selectedDateFilter = type;
        if (_fromDate == null) _fromDate = DateTime.now().subtract(const Duration(days: 30));
        if (_toDate == null) _toDate = DateTime.now();
      });
      return;
    }

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    DateTime start;
    DateTime end;

    switch (type) {
      case 'Today':
        start = today;
        end = today;
        break;
      case 'Yesterday':
        start = today.subtract(const Duration(days: 1));
        end = today.subtract(const Duration(days: 1));
        break;
      case 'This Week':
        start = today.subtract(const Duration(days: 6));
        end = today;
        break;
      case 'This Month':
        start = today.subtract(const Duration(days: 29));
        end = today;
        break;
      case 'This Year':
        start = today.subtract(const Duration(days: 364));
        end = today;
        break;
      default:
        start = today;
        end = today;
    }

    setState(() {
      _selectedDateFilter = type;
      _fromDate = start;
      _toDate = end;
    });
    _fetchReceipts();
  }

  Future<void> _pickFromDate() async {
    final now = DateTime.now();
    final initial = _fromDate ?? now;
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(now.year - 5),
      lastDate: DateTime(now.year + 1),
    );
    if (picked != null && mounted) {
      setState(() {
        _fromDate = picked;
        _selectedDateFilter = 'Custom';
      });
      _fetchReceipts();
    }
  }

  Future<void> _pickToDate() async {
    final now = DateTime.now();
    final initial = _toDate ?? now;
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(now.year - 5),
      lastDate: DateTime(now.year + 1),
    );
    if (picked != null && mounted) {
      setState(() {
        _toDate = picked;
        _selectedDateFilter = 'Custom';
      });
      _fetchReceipts();
    }
  }

  Widget _buildDateBox(DateTime? date, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Container(
        height: 40,
        padding: const EdgeInsets.symmetric(horizontal: 8),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: Colors.grey[300]!),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.calendar_month, size: 14, color: Colors.grey),
            const SizedBox(width: 4),
            Text(
              date != null ? DateFormat('dd/MM/yy').format(date) : 'Date',
              style: const TextStyle(fontSize: 11, color: Colors.black87, fontWeight: FontWeight.w500),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        title: const Text(
          'Receipt Book',
          style: TextStyle(fontWeight: FontWeight.w700, fontSize: 20),
        ),
        centerTitle: true,
        backgroundColor: colorScheme.surface,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 22),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Column(
        children: [
          // --- FILTER ---
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Container(
                        height: 48,
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        decoration: BoxDecoration(
                          color: colorScheme.surfaceContainerLow,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: colorScheme.outlineVariant.withValues(alpha: 0.4)),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            value: _selectedMode,
                            isExpanded: true,
                            icon: Icon(Icons.keyboard_arrow_down_rounded, size: 22, color: colorScheme.onSurfaceVariant),
                            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: colorScheme.onSurface),
                            items: _modeOptions.map((e) => DropdownMenuItem(
                              value: e,
                              child: Row(
                                children: [
                                  Icon(Icons.payment_outlined, size: 18, color: colorScheme.primary.withValues(alpha: 0.8)),
                                  const SizedBox(width: 8),
                                  Expanded(child: Text(e, overflow: TextOverflow.ellipsis)),
                                ],
                              ),
                            )).toList(),
                            onChanged: (value) {
                              if (value == null) return;
                              setState(() => _selectedMode = value);
                              _fetchReceipts();
                            },
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Container(
                        height: 48,
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        decoration: BoxDecoration(
                          color: colorScheme.surfaceContainerLow,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: colorScheme.outlineVariant.withValues(alpha: 0.4)),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            value: _selectedDateFilter,
                            isExpanded: true,
                            icon: Icon(Icons.keyboard_arrow_down_rounded, size: 22, color: colorScheme.onSurfaceVariant),
                            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: colorScheme.onSurface),
                            items: _dateFilterOptions.map((e) => DropdownMenuItem(
                              value: e,
                              child: Row(
                                children: [
                                  Icon(Icons.calendar_month, size: 18, color: colorScheme.primary.withValues(alpha: 0.8)),
                                  const SizedBox(width: 8),
                                  Expanded(child: Text(e, overflow: TextOverflow.ellipsis)),
                                ],
                              ),
                            )).toList(),
                            onChanged: _applyDateFilter,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                if (_selectedDateFilter == 'Custom') ...[
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(child: _buildDateBox(_fromDate, _pickFromDate)),
                      const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 4),
                        child: Text('-', style: TextStyle(color: Colors.grey)),
                      ),
                      Expanded(child: _buildDateBox(_toDate, _pickToDate)),
                    ],
                  ),
                ],
              ],
            ),
          ),

          const SizedBox(height: 12),
          // Firm filter
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Container(
              height: 48,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainerLow,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: colorScheme.outlineVariant.withValues(alpha: 0.4)),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: _selectedFirmName,
                  isExpanded: true,
                  icon: Icon(Icons.keyboard_arrow_down_rounded, size: 22, color: colorScheme.onSurfaceVariant),
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: colorScheme.onSurface),
                  items: _firmNames.map((e) => DropdownMenuItem(
                    value: e,
                    child: Row(
                      children: [
                        Icon(Icons.business_center, size: 18, color: colorScheme.primary.withValues(alpha: 0.8)),
                        const SizedBox(width: 8),
                        Expanded(child: Text(e, overflow: TextOverflow.ellipsis)),
                      ],
                    ),
                  )).toList(),
                  onChanged: (value) {
                    if (value == null) return;
                    setState(() => _selectedFirmName = value);
                  },
                ),
              ),
            ),
          ),

          // --- LIST ---
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _error != null
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.error_outline, size: 64, color: Colors.red[300]),
                            const SizedBox(height: 16),
                            Text(
                              'Error loading receipts',
                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: colorScheme.onSurface),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              _error!,
                              style: TextStyle(fontSize: 14, color: colorScheme.onSurfaceVariant),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 24),
                            FilledButton.icon(
                              onPressed: _fetchReceipts,
                              icon: const Icon(Icons.refresh),
                              label: const Text('Retry'),
                            ),
                          ],
                        ),
                      )
                    : _visibleReceipts.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.receipt_long_outlined, size: 64, color: colorScheme.outlineVariant),
                                const SizedBox(height: 16),
                                Text(
                                  'No receipts found',
                                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: colorScheme.onSurface),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Try adjusting your filters',
                                  style: TextStyle(fontSize: 14, color: colorScheme.onSurfaceVariant),
                                ),
                              ],
                            ),
                          )
                        : ListView.separated(
                            padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
                            itemCount: _visibleReceipts.length,
                            separatorBuilder: (context, index) => const SizedBox(height: 12),
                            itemBuilder: (context, index) {
                              final receipt = _visibleReceipts[index];
                              return _buildReceiptCard(context, receipt);
                            },
                          ),
          ),
        ],
      ),

      bottomSheet: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
        decoration: BoxDecoration(
          color: colorScheme.surfaceContainerLow,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 12,
              offset: const Offset(0, -4),
            ),
          ],
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Row(
          children: [
            Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Total Amount",
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  "₹${NumberFormat('#,##0.00').format(_totalAmount)}",
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: colorScheme.primary,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _openReceiptDetails(BuildContext context, Map<String, dynamic> receipt) async {
    final receiptId = receipt['id'];

    if (receiptId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Invalid receipt ID'), backgroundColor: Colors.red),
      );
      return;
    }

    // Show loading dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    try {
      final auth = Provider.of<AuthService>(context, listen: false);
      final dio = auth.getDioClient();

      final payload = {
        'lLicNo': auth.currentUser?.licenseNumber ?? '',
        'lUserId': auth.currentUser?.mobileNumber ?? '',
        'lid': receiptId,
        'lStatus': -1,
        'lFirm': '',
      };

      debugPrint('[ReceiptBook] GetReceiptDetail payload: ${jsonEncode(payload)}');

      final response = await dio.post(
        '/GetReceiptDetail',
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

      String raw = response.data?.toString() ?? '';
      String clean = raw.replaceAll(RegExp(r'[\x00-\x1F\x7F]'), '').trim();
      Map<String, dynamic> data;
      try {
        final decoded = jsonDecode(clean);
        data = decoded is Map<String, dynamic>
            ? decoded
            : {'Message': decoded.toString()};
      } catch (_) {
        data = {'Message': clean};
      }

      debugPrint('[ReceiptBook] GetReceiptDetail Response: ${jsonEncode(data)}');

      // Close loading dialog
      if (mounted) Navigator.pop(context);

      if (data['success'] == true && data['data'] != null) {
        final responseData = data['data'] as Map<String, dynamic>;
        Map<String, dynamic> detailedReceipt = {};

        // Check if Receipt is an array and extract the first item
        if (responseData['Receipt'] is List && (responseData['Receipt'] as List).isNotEmpty) {
          detailedReceipt = Map<String, dynamic>.from((responseData['Receipt'] as List)[0] as Map);
          debugPrint('[ReceiptBook] Extracted receipt from Receipt array');
        } else {
          // Fallback: use the entire data object
          detailedReceipt = responseData;
          debugPrint('[ReceiptBook] Using full data object as receipt');
        }

        debugPrint('[ReceiptBook] Detailed receipt keys: ${detailedReceipt.keys.toList()}');

        if (mounted) {
          // ignore: use_build_context_synchronously
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ReceiptDetailsPage(receipt: detailedReceipt),
            ),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(data['message'] ?? 'Failed to load receipt details'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e, stackTrace) {
      debugPrint('[ReceiptBook] GetReceiptDetail Error: $e');
      debugPrint('[ReceiptBook] Stack trace: $stackTrace');

      // Close loading dialog
      if (mounted) Navigator.pop(context);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Widget _buildReceiptCard(BuildContext context, Map<String, dynamic> receipt) {
    final colorScheme = Theme.of(context).colorScheme;

    // Parse amount
    final amount = receipt['amount'];
    final amountValue = amount is num ? amount.toDouble() : (double.tryParse(amount?.toString() ?? '0') ?? 0.0);

    // Parse date
    DateTime? receiptDate;
    try {
      receiptDate = DateTime.parse(receipt['date'] ?? '');
    } catch (_) {
      receiptDate = null;
    }

    return InkWell(
      onTap: () => _openReceiptDetails(context, receipt),
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: colorScheme.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: colorScheme.outlineVariant.withValues(alpha: 0.3)),
          boxShadow: [
            BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 8, offset: const Offset(0, 3)),
          ],
        ),
        child: Column(
          children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      receipt['acName'] ?? 'Unknown Party',
                      style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16, color: colorScheme.onSurface),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        'ID: ${receipt['id']}',
                        style: TextStyle(fontSize: 11, color: colorScheme.onSurfaceVariant, fontWeight: FontWeight.w600),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Text(
                "₹${NumberFormat('#,##0.00').format(amountValue)}",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: colorScheme.primary),
              ),
            ],
          ),

          const SizedBox(height: 16),
          Divider(height: 1, color: colorScheme.outlineVariant.withValues(alpha: 0.3)),
          const SizedBox(height: 16),

          Row(
            children: [
              Expanded(
                flex: 3,
                child: _buildCardDetailItem(
                  context,
                  "Mode",
                  receipt['type'] ?? 'N/A',
                  Icons.payment
                ),
              ),
              Expanded(
                flex: 3,
                child: _buildCardDetailItem(
                  context,
                  "Date",
                  receiptDate != null ? DateFormat('dd MMM yyyy').format(receiptDate) : 'N/A',
                  Icons.calendar_today
                ),
              ),
              Expanded(
                flex: 3,
                child: _buildCardDetailItem(
                  context,
                  "Doc No",
                  receipt['docno']?.isNotEmpty == true ? receipt['docno'] : '-',
                  Icons.description,
                  alignEnd: true
                ),
              ),
            ],
          ),

          // Firm info
          if (receipt['FirmName'] != null && receipt['FirmName'].toString().isNotEmpty) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(Icons.business, size: 14, color: colorScheme.onSurfaceVariant),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    receipt['FirmName'],
                    style: TextStyle(
                      fontSize: 11,
                      color: colorScheme.onSurfaceVariant,
                      fontWeight: FontWeight.w500,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ],
            ],
        ),
      ),
    );
  }

  Widget _buildCardDetailItem(BuildContext context, String label, String value, IconData icon, {bool alignEnd = false}) {
    final colorScheme = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: alignEnd ? CrossAxisAlignment.end : CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (!alignEnd) Icon(icon, size: 14, color: colorScheme.onSurfaceVariant),
            if (!alignEnd) const SizedBox(width: 4),
            Text(label, style: TextStyle(fontSize: 11, color: colorScheme.onSurfaceVariant, fontWeight: FontWeight.w500)),
            if (alignEnd) const SizedBox(width: 4),
            if (alignEnd) Icon(icon, size: 14, color: colorScheme.onSurfaceVariant),
          ],
        ),
        const SizedBox(height: 4),
        Text(value, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: colorScheme.onSurface.withValues(alpha: 0.9))),
      ],
    );
  }
}