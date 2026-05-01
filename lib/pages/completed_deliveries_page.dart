import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:dio/dio.dart';
import 'dart:convert';
import 'package:intl/intl.dart';

import '../auth_service.dart';
import 'delivery_detail_page.dart';
import 'delivery_filter_page.dart';

class DeliveryBill {
  final String acname,
      mobile,
      billno,
      billdate,
      station,
      acno,
      remark,
      area,
      route,
      statusName,
      status,
      updatedat; // New field for delivery timestamp
  final String address;
  final String keyno;
  final double billamt;
  final int item, qty;
  final String? latitude;
  final String? longitude;
  final Map<String, dynamic> rawData; // Store all raw data for detail page

  DeliveryBill({
    required this.acname,
    required this.address,
    required this.mobile,
    required this.billno,
    required this.billdate,
    required this.billamt,
    required this.item,
    required this.qty,
    required this.station,
    required this.acno,
    required this.remark,
    required this.area,
    required this.route,
    required this.statusName,
    required this.status,
    required this.keyno,
    required this.updatedat,
    this.latitude,
    this.longitude,
    required this.rawData,
  });

  factory DeliveryBill.fromJson(Map<String, dynamic> json) {
    String str(String key) {
      final val = json[key];
      if (val == null) return 'NA';
      final s = val.toString().trim();
      if (s.toLowerCase() == 'null' || s.isEmpty) return 'NA';
      return s;
    }

    String? strNullable(String key) {
      final val = json[key];
      if (val == null) return null;
      final s = val.toString().trim();
      if (s.toLowerCase() == 'null' || s.isEmpty) return null;
      return s;
    }

    double dbl(String key) {
      if (json[key] == null) return 0.0;
      return double.tryParse(json[key].toString()) ?? 0.0;
    }

    int integer(String key) {
      final v = json[key];
      if (v == null) return 0;
      if (v is int) return v;
      if (v is double) return v.toInt();
      final s = v.toString();
      final i = int.tryParse(s);
      if (i != null) return i;
      final d = double.tryParse(s);
      if (d != null) return d.toInt();
      return 0;
    }

    List<String> validAddrParts = [];
    if (json['address1'] != null && json['address1'].toString().isNotEmpty) {
      validAddrParts.add(json['address1'].toString());
    }
    if (json['address2'] != null && json['address2'].toString().isNotEmpty) {
      validAddrParts.add(json['address2'].toString());
    }
    if (json['address3'] != null && json['address3'].toString().isNotEmpty) {
      validAddrParts.add(json['address3'].toString());
    }

    String fullAddress =
        validAddrParts.where((s) => s.trim().isNotEmpty).join(', ');
    if (fullAddress.isEmpty) fullAddress = "NA";

    return DeliveryBill(
      acname: str('acname'),
      address: fullAddress,
      mobile: str('mobile'),
      billno: str('billno'),
      billdate: str('billdate'),
      billamt: dbl('billamt'),
      item: integer('item'),
      qty: integer('qty'),
      station: str('station'),
      acno: str('acno'),
      remark: str('remark'),
      area: str('area'),
      route: str('route'),
      statusName: str('statusname'),
      status: str('status'),
      keyno: str('keyno'),
      updatedat: str('updatedat'), // Parse updatedat from API
      latitude: strNullable('latitude'),
      longitude: strNullable('longitude'),
      rawData: json, // Store all raw data
    );
  }
}

class CompletedDeliveriesPage extends StatefulWidget {
  const CompletedDeliveriesPage({super.key});

  @override
  State<CompletedDeliveriesPage> createState() => _CompletedDeliveriesPageState();
}

class _CompletedDeliveriesPageState extends State<CompletedDeliveriesPage> {
  static const int _pageSize = 10;

  final ScrollController _scrollController = ScrollController();
  final List<DeliveryBill> _bills = [];
  List<DeliveryBill> _filteredBills = [];
  bool _isLoading = false;
  int _pageNo = 1;
  bool _hasMore = true;

  List<Map<String, dynamic>> _apiFilters = [];
  String _searchQuery = '';

  // Date Filter
  String _selectedDateFilter = 'Today';
  final List<String> _dateFilterOptions = [
    'Today',
    'Yesterday',
    'This Week',
    'This Month',
    'Previous Month',
    'This Year',
    'Custom',
  ];
  DateTime? _fromDate;
  DateTime? _toDate;

  // Delivery Status Filter
  final Map<int, String> _deliveryStatusMap = {
    1: 'Delivered',
    2: 'Part Delivered',
    4: 'Not delivered',
    5: 'Return',
  };
  late List<int> _selectedDeliveryStatus;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);

    _selectedDeliveryStatus = _deliveryStatusMap.keys.toList();

    // Set default to Today's date
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    _selectedDateFilter = 'Today';
    _fromDate = today;
    _toDate = today;

    _loadBills(reset: true);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  /// Format the updatedat timestamp for display
  /// Input format: "2026-02-18 14:44:45.297"
  /// Output format: "18 Feb 2:44 PM"
  String _formatDeliveryTime(String updatedat) {
    try {
      if (updatedat.isEmpty || updatedat == 'NA') return 'NA';

      // Parse the timestamp
      final dateTime = DateTime.parse(updatedat.replaceAll(' ', 'T'));

      // Format as "18 Feb 2:44 PM"
      final day = dateTime.day.toString().padLeft(2, '0');
      final month = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'][dateTime.month - 1];
      final hour = dateTime.hour > 12 ? (dateTime.hour - 12) : (dateTime.hour == 0 ? 12 : dateTime.hour);
      final minute = dateTime.minute.toString().padLeft(2, '0');
      final period = dateTime.hour >= 12 ? 'PM' : 'AM';

      return '$day $month $hour:$minute $period';
    } catch (e) {
      debugPrint('[CompletedDeliveries] Error formatting timestamp: $e');
      return updatedat;
    }
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
            _scrollController.position.maxScrollExtent - 200 &&
        !_isLoading &&
        _hasMore) {
      _loadBills();
    }
  }

  void _applyDateFilter(String? type) {
    if (type == null) return;


    if (type == 'Custom') {
      setState(() {
        _selectedDateFilter = type;
        if (_fromDate == null) _fromDate = DateTime.now().subtract(const Duration(days: 30));
        if (_toDate == null) _toDate = DateTime.now();
      });
      debugPrint('[CompletedDeliveries] Date filter set to Custom');
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
        final daysToSubtract = today.weekday - 1;
        start = today.subtract(Duration(days: daysToSubtract));
        end = today;
        break;
      case 'This Month':
        start = DateTime(today.year, today.month, 1);
        end = today;
        break;
      case 'Previous Month':
        final firstDayOfCurrentMonth = DateTime(today.year, today.month, 1);
        final lastDayOfPreviousMonth = firstDayOfCurrentMonth.subtract(const Duration(days: 1));
        start = DateTime(lastDayOfPreviousMonth.year, lastDayOfPreviousMonth.month, 1);
        end = lastDayOfPreviousMonth;
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
    debugPrint('[CompletedDeliveries] Date filter set to $type: ${DateFormat('yyyy-MM-dd').format(start)} to ${DateFormat('yyyy-MM-dd').format(end)}');
    _loadBills(reset: true);
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
      _loadBills(reset: true);
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
      _loadBills(reset: true);
    }
  }

  Future<void> _openDeliveryStatusFilter() async {
    // Create a mutable copy to track changes in the dialog
    Set<int> tempSelected = Set.from(_selectedDeliveryStatus);

    await showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Select Delivery Status'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: _deliveryStatusMap.entries.map((entry) {
                return CheckboxListTile(
                  value: tempSelected.contains(entry.key),
                  onChanged: (bool? checked) {
                    setDialogState(() {
                      if (checked == true) {
                        tempSelected.add(entry.key);
                        debugPrint('[CompletedDeliveries] Added ${entry.key} - ${entry.value}');
                      } else {
                        tempSelected.remove(entry.key);
                        debugPrint('[CompletedDeliveries] Removed ${entry.key} - ${entry.value}');
                      }
                      debugPrint('[CompletedDeliveries] Current selected: $tempSelected');
                    });
                  },
                  title: Text(entry.value),
                );
              }).toList(),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                // Apply the selected statuses to the main state - convert Set to List and remove duplicates
                setState(() {
                  _selectedDeliveryStatus = tempSelected.toList();
                  debugPrint('[CompletedDeliveries] Applied delivery status filter: $_selectedDeliveryStatus');
                });
                Navigator.pop(context);
                _loadBills(reset: true);
              },
              child: const Text('Apply'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _loadBills({bool reset = false}) async {
    if (reset) {
      if (mounted) {
        setState(() {
          _isLoading = true;
          _bills.clear();
          _pageNo = 1;
          _hasMore = true;
        });
      }
    }

    try {
      final auth = Provider.of<AuthService>(context, listen: false);
      final dio = auth.getDioClient();

      List<int> areaIds = [];
      List<int> routeIds = [];

      for (final filter in _apiFilters) {
        final categoryId = filter['id'] as int;
        final items = filter['items'] as List<dynamic>;

        if (categoryId == 2 && items.isNotEmpty) {
          areaIds = items
              .map((e) => e is int ? e : int.tryParse(e.toString()) ?? 0)
              .toList();
        } else if (categoryId == 3 && items.isNotEmpty) {
          routeIds = items
              .map((e) => e is int ? e : int.tryParse(e.toString()) ?? 0)
              .toList();
        }
      }

      final List<int> deliveryStatus = List<int>.from(Set<int>.from(_selectedDeliveryStatus));

      debugPrint('[CompletedDeliveries] Delivery Status Array (deduplicated): $deliveryStatus');

      String lFromDate = '';
      String lTillDate = '';

      if (_fromDate != null) {
        lFromDate = DateFormat('yyyy-MM-dd').format(_fromDate!);
      }

      if (_toDate != null) {
        lTillDate = DateFormat('yyyy-MM-dd').format(_toDate!);
      }

      final payload = jsonEncode({
        'lLicNo': auth.currentUser?.licenseNumber ?? '',
        'luserid':
            auth.currentUser?.mobileNumber ?? auth.currentUser?.userId ?? '',
        'lPageNo': _pageNo,
        'lSize': _pageSize,
        'laid': areaIds,
        'lrtid': routeIds,
        'ldeliveryStatus': deliveryStatus,
        'lSearch': '',
        'lFromDate': lFromDate,
        'lTillDate': lTillDate,
        'lExecuteTotalRows': 1,
      });

      debugPrint('[CompletedDeliveries] ===== API REQUEST =====');
      debugPrint('[CompletedDeliveries] Payload: $payload');
      debugPrint('[CompletedDeliveries] Delivery Status Array: $deliveryStatus');
      debugPrint('[CompletedDeliveries] Date Range: $lFromDate to $lTillDate');
      debugPrint('[CompletedDeliveries] =======================');

      final headers = {
        'Content-Type': 'application/json',
        'Authorization': auth.getAuthHeader() ?? '',
        'package_name': auth.packageNameHeader,
      };

      final response = await dio.post('/getdeleveredbillList',
          data: payload, options: Options(headers: headers));

      debugPrint('[CompletedDeliveries] Response status: ${response.statusCode}');
      debugPrint('[CompletedDeliveries] Response data: ${response.data}');

      String cleanJson = response.data
          .toString()
          .replaceAll(RegExp(r'[\x00-\x1F\x7F]'), '')
          .trim();
      final decoded = jsonDecode(cleanJson);
      debugPrint('[CompletedDeliveries] Decoded: $decoded');

      final Map<String, dynamic> root =
          decoded is Map<String, dynamic> ? decoded : {};
      final Map<String, dynamic> container =
          root['data'] is Map<String, dynamic>
              ? root['data'] as Map<String, dynamic>
              : root;

      final bool apiSuccess = root['success'] == true ||
          root['Status'] == true ||
          container['Status'] == true;

      debugPrint('[CompletedDeliveries] API success: $apiSuccess');
      debugPrint('[CompletedDeliveries] Root keys: ${root.keys}');
      debugPrint('[CompletedDeliveries] Container keys: ${container.keys}');

      if (!apiSuccess) {
        throw Exception(root['message'] ?? root['Message'] ?? 'Server failure');
      }

      List rawList = [];
      if (container['data'] is List) {
        rawList = container['data'] as List;
        debugPrint('[CompletedDeliveries] Found data in container[data]');
      } else if (container['DBILL'] is List) {
        rawList = container['DBILL'] as List;
        debugPrint('[CompletedDeliveries] Found data in container[DBILL]');
      } else if (container['DeliverBills'] is List) {
        rawList = container['DeliverBills'] as List;
        debugPrint('[CompletedDeliveries] Found data in container[DeliverBills]');
      } else if (root['data'] is List) {
        rawList = root['data'] as List;
        debugPrint('[CompletedDeliveries] Found data in root[data]');
      } else {
        debugPrint('[CompletedDeliveries] No data found in expected locations');
        debugPrint('[CompletedDeliveries] Container: $container');
      }

      debugPrint('[CompletedDeliveries] Raw list length: ${rawList.length}');

      final newBills = rawList.map((e) {
        try {
          if (e is Map<String, dynamic>) return DeliveryBill.fromJson(e);
          final parsed = (e is String)
              ? jsonDecode(e) as Map<String, dynamic>
              : Map<String, dynamic>.from(e);
          return DeliveryBill.fromJson(parsed);
        } catch (_) {
          return DeliveryBill(
              acname: 'Unknown',
              address: 'NA',
              mobile: 'NA',
              billno: 'NA',
              billdate: 'NA',
              updatedat: 'NA',
              billamt: 0.0,
              item: 0,
              qty: 0,
              station: 'NA',
              acno: 'NA',
              remark: 'NA',
              area: 'NA',
              route: 'NA',
              statusName: 'NA',
              status: 'NA',
              keyno: 'NA',
              latitude: null,
              longitude: null,
              rawData: e is Map<String, dynamic> ? e : {});
        }
      }).toList();

      debugPrint('[CompletedDeliveries] Parsed ${newBills.length} bills');

      if (mounted) {
        setState(() {
          _bills.addAll(newBills);
          _filteredBills = List.from(_bills);

          // Log the statuses of bills returned
          debugPrint('[CompletedDeliveries] ===== BILL STATUSES =====');
          for (var bill in newBills) {
            debugPrint('[CompletedDeliveries] Bill: ${bill.acname}, Status: ${bill.status} (${bill.statusName})');
          }
          debugPrint('[CompletedDeliveries] =======================');

          _hasMore = newBills.length >= _pageSize;
          if (_hasMore) _pageNo++;
          _isLoading = false; // Set to false after successful load
        });
        debugPrint('[CompletedDeliveries] State updated: ${_bills.length} bills loaded');
      }
    } catch (e) {
      debugPrint('[CompletedDeliveries] Error: $e');
      debugPrint('[CompletedDeliveries] Error stack trace: ${StackTrace.current}');
      if (mounted) {
        setState(() => _isLoading = false);
        if (_bills.isEmpty) {
          ScaffoldMessenger.of(context)
              .showSnackBar(SnackBar(content: Text("Error: ${e.toString()}")));
        }
      }
    }
  }

  void _applySearch() {
    if (_searchQuery.isEmpty) {
      _filteredBills = List.from(_bills);
    } else {
      final query = _searchQuery.toLowerCase();
      _filteredBills = _bills.where((bill) {
        return bill.acname.toLowerCase().contains(query) ||
            bill.billno.toLowerCase().contains(query) ||
            bill.station.toLowerCase().contains(query) ||
            bill.area.toLowerCase().contains(query) ||
            bill.route.toLowerCase().contains(query);
      }).toList();
    }
  }

  Future<void> _openFilterPage() async {
    final result = await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => DeliveryFilterPage(
          initialSelectedFilters: _apiFilters,
        ),
      ),
    );

    if (result != null && result is List<Map<String, dynamic>>) {
      setState(() {
        _apiFilters = result;
      });
      _loadBills(reset: true);
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

    if (_isLoading && _bills.isEmpty) {
      return Scaffold(
        backgroundColor: colorScheme.surface,
        appBar: AppBar(
          title: const Text('Delivery Book'),
          backgroundColor: colorScheme.surface,
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    final bool hasActiveFilters = _apiFilters.isNotEmpty;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        title: const Text(
          'Delivery Book',
          style: TextStyle(fontWeight: FontWeight.w700, fontSize: 20),
        ),
        centerTitle: true,
        backgroundColor: colorScheme.surface,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 22),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          Stack(
            alignment: Alignment.center,
            children: [
              IconButton(
                icon: const Icon(Icons.tune),
                onPressed: _openFilterPage,
                tooltip: 'Filters',
              ),
              if (hasActiveFilters)
                Positioned(
                  right: 12,
                  top: 12,
                  child: Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                      color: Colors.red,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Column(
        children: [
          // --- FILTER SECTION (Same style as receipt_book_page) ---
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
            child: Column(
              children: [
                Row(
                  children: [
                    // Date Filter Dropdown
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
                    const SizedBox(width: 8),
                    // Delivery Status Filter Button
                    Expanded(
                      child: Container(
                        height: 48,
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        decoration: BoxDecoration(
                          color: colorScheme.surfaceContainerLow,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: colorScheme.outlineVariant.withValues(alpha: 0.4)),
                        ),
                        child: InkWell(
                          onTap: _openDeliveryStatusFilter,
                          borderRadius: BorderRadius.circular(12),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Icon(Icons.filter_list, size: 18, color: colorScheme.primary.withValues(alpha: 0.8)),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'Status (${_selectedDeliveryStatus.length})',
                                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: colorScheme.onSurface),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              Icon(Icons.keyboard_arrow_down_rounded, size: 22, color: colorScheme.onSurfaceVariant),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                // Custom Date Pickers (shown only when Custom is selected)
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
          // --- SEARCH BAR ---
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: Container(
              height: 44,
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(12),
              ),
              child: TextField(
                decoration: InputDecoration(
                  hintText: 'Search deliveries...',
                  hintStyle: TextStyle(
                    fontSize: 14,
                    color: colorScheme.onSurfaceVariant,
                  ),
                  prefixIcon: Icon(
                    Icons.search,
                    color: colorScheme.onSurfaceVariant,
                    size: 20,
                  ),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                ),
                style: TextStyle(
                  fontSize: 14,
                  color: colorScheme.onSurface,
                ),
                onChanged: (value) {
                  setState(() {
                    _searchQuery = value;
                    _applySearch();
                  });
                },
              ),
            ),
          ),
          // --- CONTENT ---
          Expanded(
            child: _filteredBills.isEmpty
                ? _buildEmptyState(colorScheme)
                : ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              itemCount: _filteredBills.length +
                  (_hasMore && _filteredBills.isNotEmpty ? 1 : 0),
              itemBuilder: (context, index) {
                if (index == _filteredBills.length) {
                  return _filteredBills.isNotEmpty && _isLoading && _hasMore
                      ? const Center(
                    child: Padding(
                      padding: EdgeInsets.all(24),
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  )
                      : const SizedBox.shrink();
                }
                return _buildDeliveryCard(
                    _filteredBills[index], index + 1, colorScheme);
              },
            ),
          ),
        ],
      ),
    );
  }

  // ...existing code...

  Widget _buildDeliveryCard(
      DeliveryBill bill, int index, ColorScheme colorScheme) {
    // Determine status text and color based on status number
    String statusText = 'Unknown';
    Color statusBgColor = Colors.grey.shade200;
    Color statusTextColor = Colors.grey.shade700;

    final statusInt = int.tryParse(bill.status) ?? 0;

    switch (statusInt) {
      case 1:
        statusText = 'Delivered';
        statusBgColor = const Color(0xFFF1F8E9); // Light green
        statusTextColor = const Color(0xFF558B2F); // Dark green
        break;
      case 2:
        statusText = 'Part Delivered';
        statusBgColor = const Color(0xFFFFF3E0); // Light orange
        statusTextColor = const Color(0xFFE65100); // Dark orange
        break;
      case 3:
        statusText = 'Cancel';
        statusBgColor = const Color(0xFFFFEBEE); // Light red
        statusTextColor = const Color(0xFFC62828); // Dark red
        break;
      case 4:
        statusText = 'Not Delivered';
        statusBgColor = const Color(0xFFF3E5F5); // Light purple
        statusTextColor = const Color(0xFF6A1B9A); // Dark purple
        break;
      case 5:
        statusText = 'Return';
        statusBgColor = const Color(0xFFE0F2F1); // Light teal
        statusTextColor = const Color(0xFF00695C); // Dark teal
        break;
      default:
        statusText = bill.statusName != 'NA' ? bill.statusName : 'Unknown';
        statusBgColor = Colors.grey.shade200;
        statusTextColor = Colors.grey.shade700;
    }

    debugPrint('[CompletedDeliveries] Status: $statusInt -> $statusText');

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => DeliveryDetailPage(deliveryData: bill.rawData),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          children: [
            // Card Header
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: const Color(0xFFFAFAFA),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(12),
                  topRight: Radius.circular(12),
                ),
                border: Border(
                  bottom: BorderSide(color: Colors.grey.shade200),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFF07666A).withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          "#$index",
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF07666A),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      // Display "Delivered at" using updatedat timestamp
                      Text(
                        bill.updatedat != 'NA'
                            ? 'Updated at ${_formatDeliveryTime(bill.updatedat)}'
                            : 'Updated at ${bill.billdate}',
                        style: const TextStyle(
                          fontSize: 12,
                          color: Color(0xFF616161),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: statusBgColor,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      statusText.toUpperCase(),
                      style: TextStyle(
                        color: statusTextColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 10,
                        letterSpacing: 0.5,
                      ),
                    ),
                  )
                ],
              ),
            ),
            // Card Body
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    bill.acname,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF212121),
                      height: 1.2,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.location_on_outlined,
                          size: 16, color: Color(0xFF757575)),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              bill.station != 'NA' ? bill.station : 'N/A',
                              style: const TextStyle(
                                fontSize: 13,
                                color: Color(0xFF616161),
                                fontWeight: FontWeight.w600,
                                height: 1.3,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            if (bill.area != 'NA' || bill.route != 'NA')
                              Padding(
                                padding: const EdgeInsets.only(top: 8.0),
                                child: Row(
                                  children: [
                                    if (bill.area != 'NA')
                                      Expanded(
                                        child: RichText(
                                          text: TextSpan(
                                            children: [
                                              const TextSpan(
                                                text: 'Area: ',
                                                style: TextStyle(
                                                  fontSize: 12,
                                                  color: Color(0xFF757575),
                                                  fontWeight: FontWeight.w500,
                                                ),
                                              ),
                                              TextSpan(
                                                text: bill.area,
                                                style: const TextStyle(
                                                  fontSize: 12,
                                                  color: Color(0xFF212121),
                                                  fontWeight: FontWeight.w600,
                                                ),
                                              ),
                                            ],
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    if (bill.area != 'NA' && bill.route != 'NA')
                                      const Padding(
                                        padding: EdgeInsets.symmetric(
                                            horizontal: 8.0),
                                        child: Text(
                                          '•',
                                          style: TextStyle(
                                            color: Color(0xFF757575),
                                            fontSize: 10,
                                          ),
                                        ),
                                      ),
                                    if (bill.route != 'NA')
                                      Expanded(
                                        child: RichText(
                                          text: TextSpan(
                                            children: [
                                              const TextSpan(
                                                text: 'Route: ',
                                                style: TextStyle(
                                                  fontSize: 12,
                                                  color: Color(0xFF757575),
                                                  fontWeight: FontWeight.w500,
                                                ),
                                              ),
                                              TextSpan(
                                                text: bill.route,
                                                style: const TextStyle(
                                                  fontSize: 12,
                                                  color: Color(0xFF212121),
                                                  fontWeight: FontWeight.w600,
                                                ),
                                              ),
                                            ],
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF5F7FA),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _buildInfoItem(
                            "Bill No", bill.billno, colorScheme, false),
                        Container(
                            width: 1,
                            height: 24,
                            color: Colors.grey[300]),
                        _buildInfoItem("Amount",
                            "₹${bill.billamt.toStringAsFixed(0)}", colorScheme, true),
                        Container(
                            width: 1,
                            height: 24,
                            color: Colors.grey[300]),
                        _buildInfoItem("Items", "${bill.item}", colorScheme, false),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoItem(
      String label, String value, ColorScheme colorScheme, bool isAmount) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: isAmount ? Colors.black : colorScheme.onSurface,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(ColorScheme colorScheme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: const Color(0xFF4CAF50).withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.check_circle_outline,
                size: 48, color: Color(0xFF4CAF50)),
          ),
          const SizedBox(height: 16),
          Text("No completed deliveries found",
              style: TextStyle(
                  fontSize: 16,
                  color: colorScheme.onSurface,
                  fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          Text("Completed deliveries will appear here",
              style:
                  TextStyle(fontSize: 13, color: colorScheme.onSurfaceVariant)),
        ],
      ),
    );
  }
}

