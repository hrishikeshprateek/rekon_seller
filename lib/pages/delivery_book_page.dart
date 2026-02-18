import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:dio/dio.dart';
import 'dart:convert';
import 'package:url_launcher/url_launcher.dart';

// --- YOUR EXISTING IMPORTS ---
import '../auth_service.dart';
import 'mark_delivered_page.dart';
import '../models/delivery_task_model.dart';
import 'delivery_filter_page.dart';

class DeliveryBookPage extends StatefulWidget {
  const DeliveryBookPage({super.key});

  @override
  State<DeliveryBookPage> createState() => _DeliveryBookPageState();
}

class _DeliveryBookPageState extends State<DeliveryBookPage>
    with TickerProviderStateMixin {
  static const int _pageSize = 10;

  final ScrollController _scrollController = ScrollController();
  final List<DeliveryBill> _bills = [];
  List<DeliveryBill> _filteredBills = [];

  bool _isLoading = false;
  int _pageNo = 1;
  bool _hasMore = true;

  // API Filters
  List<Map<String, dynamic>> _apiFilters = [];
  bool _sortByLocation = true;

  // Tab Controller
  late TabController _tabController;

  // Status mapping: 0=Pending, 1=Completed, 2=Return
  final List<TaskStatus> _tabStatuses = [
    TaskStatus.pending,
    TaskStatus.done,
    TaskStatus.returnTask
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(_onTabChanged);
    _scrollController.addListener(_onScroll);
    _loadBills(reset: true);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _tabController.dispose();
    super.dispose();
  }

  void _onTabChanged() {
    debugPrint('[DeliveryBook] Tab changed to index: ${_tabController.index}');
    _loadBills(reset: true);
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200 &&
        !_isLoading &&
        _hasMore) {
      _loadBills();
    }
  }

  // --- API LOADING LOGIC ---
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

      // Determine delivery status based on current tab
      // Tab 0 = Pending (no status filter, empty array)
      // Tab 1 = Completed (status 1)
      // Tab 2 = Return (status 0)
      List<int> deliveryStatus = [];
      String tabName = 'Pending';
      if (_tabController.index == 1) {
        deliveryStatus = [1]; // Completed
        tabName = 'Completed';
      } else if (_tabController.index == 2) {
        deliveryStatus = [0]; // Return
        tabName = 'Return';
      }
      // For Pending (index 0), keep empty array

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
        'lExecuteTotalRows': 1,
      });

      debugPrint('[DeliveryBook] Tab: $tabName (index: ${_tabController.index})');
      debugPrint('[DeliveryBook] Status Filter: $deliveryStatus');
      debugPrint('[DeliveryBook] Payload: $payload');

      final headers = {
        'Content-Type': 'application/json',
        'Authorization': auth.getAuthHeader() ?? '',
        'package_name': auth.packageNameHeader,
      };

      final response = await dio.post('/getdeleveredbillList',
          data: payload, options: Options(headers: headers));

      String cleanJson = response.data
          .toString()
          .replaceAll(RegExp(r'[\x00-\x1F\x7F]'), '')
          .trim();
      final decoded = jsonDecode(cleanJson);
      final Map<String, dynamic> root =
      decoded is Map<String, dynamic> ? decoded : {};
      final Map<String, dynamic> container =
      root['data'] is Map<String, dynamic>
          ? root['data'] as Map<String, dynamic>
          : root;

      final bool apiSuccess = root['success'] == true ||
          root['Status'] == true ||
          container['Status'] == true;
      if (!apiSuccess) {
        throw Exception(root['message'] ?? root['Message'] ?? 'Server failure');
      }

      List rawList = [];
      if (container['data'] is List) {
        rawList = container['data'] as List;
      } else if (container['DBILL'] is List) {
        rawList = container['DBILL'] as List;
      } else if (container['DeliverBills'] is List) {
        rawList = container['DeliverBills'] as List;
      } else if (root['data'] is List) {
        rawList = root['data'] as List;
      }

      final newBills = rawList.map((e) {
        if (e is Map<String, dynamic>) return DeliveryBill.fromJson(e);
        try {
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
              keyno: 'NA');
        }
      }).toList();

      if (mounted) {
        setState(() {
          _bills.addAll(newBills);
          _sortTasks();
          _applyStatusFilter();
          _hasMore = newBills.length >= _pageSize;
          if (_hasMore) _pageNo++;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        if (_bills.isEmpty) {
          ScaffoldMessenger.of(context)
              .showSnackBar(SnackBar(content: Text("Error: ${e.toString()}")));
        }
      }
    }
  }

  TaskStatus _statusFromBill(DeliveryBill bill) {
    final raw =
    (bill.statusName != 'NA' ? bill.statusName : bill.status).toLowerCase();
    if (raw.contains('return')) return TaskStatus.returnTask;
    if (raw.contains('deliver') ||
        raw.contains('done') ||
        raw.contains('complete')) return TaskStatus.done;
    if (raw == '1') return TaskStatus.done;
    if (raw == '2') return TaskStatus.returnTask;
    if (raw.contains('pending') || raw == '0' || raw.isEmpty)
      return TaskStatus.pending;
    return TaskStatus.pending;
  }

  void _sortTasks() {
    if (_sortByLocation) {
      _bills.sort((a, b) {
        final areaCompare = a.area.compareTo(b.area);
        if (areaCompare != 0) return areaCompare;
        return a.acname.compareTo(b.acname);
      });
    } else {
      _bills.sort((a, b) => a.acname.compareTo(b.acname));
    }
  }

  void _applyStatusFilter() {
    final selectedStatus = _tabStatuses[_tabController.index];
    setState(() {
      _filteredBills = _bills
          .where((bill) => _statusFromBill(bill) == selectedStatus)
          .toList();
    });
  }

  Future<void> _openFilterPage() async {
    final result = await Navigator.push(
      context,
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

  // --- BUILD METHOD ---
  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    if (_isLoading && _bills.isEmpty) {
      return Scaffold(
        backgroundColor: colorScheme.surface,
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    final pendingCount = _bills
        .where((bill) => _statusFromBill(bill) == TaskStatus.pending)
        .length;
    final totalValue = _bills.fold(0.0, (sum, bill) => sum + bill.billamt);
    final bool hasActiveFilters = _apiFilters.isNotEmpty;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: PreferredSize(
        // COMPACT HEIGHT: 140 (Toolbar) + 45 (TabBar) = 185
        preferredSize: const Size.fromHeight(185),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildSliverAppBar(
                pendingCount, totalValue, colorScheme, hasActiveFilters),
            // Status Tabs Container
            SizedBox(
              height: 45,
              child: Container(
                decoration: BoxDecoration(
                  color: colorScheme.surface,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(24),
                    topRight: Radius.circular(24),
                  ),
                ),
                child: TabBar(
                  controller: _tabController,
                  labelColor: const Color(0xFF1A237E),
                  unselectedLabelColor: colorScheme.onSurfaceVariant,
                  indicatorColor: const Color(0xFF1A237E),
                  indicatorWeight: 3,
                  overlayColor: WidgetStateProperty.all(Colors.transparent),
                  labelPadding: EdgeInsets.zero,
                  indicatorPadding: const EdgeInsets.symmetric(horizontal: 16),
                  labelStyle: const TextStyle(
                      fontWeight: FontWeight.w700, fontSize: 14),
                  unselectedLabelStyle: const TextStyle(
                      fontWeight: FontWeight.w500, fontSize: 14),
                  indicatorSize: TabBarIndicatorSize.tab,
                  tabs: const [
                    Tab(text: 'Pending'),
                    Tab(text: 'Completed'),
                    Tab(text: 'Return'),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      body: CustomScrollView(
        controller: _scrollController,
        physics: const BouncingScrollPhysics(),
        slivers: [
          _filteredBills.isEmpty
              ? SliverFillRemaining(child: _buildEmptyState(colorScheme))
              : SliverPadding(
            padding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate(
                    (context, index) {
                  if (index == _filteredBills.length) {
                    return _filteredBills.isNotEmpty &&
                        _isLoading &&
                        _hasMore
                        ? const Center(
                      child: Padding(
                        padding: EdgeInsets.all(24),
                        child: CircularProgressIndicator(
                            strokeWidth: 2),
                      ),
                    )
                        : const SizedBox.shrink();
                  }
                  return _buildModernTaskCard(
                      _filteredBills[index], index + 1, colorScheme);
                },
                childCount: _filteredBills.length +
                    (_hasMore && _filteredBills.isNotEmpty ? 1 : 0),
              ),
            ),
          ),
          const SliverPadding(padding: EdgeInsets.only(bottom: 80)),
        ],
      ),
    );
  }

  AppBar _buildSliverAppBar(
      int count, double value, ColorScheme colorScheme, bool hasActiveFilters) {
    final userName = (Provider.of<AuthService>(context, listen: false)
        .currentUser
        ?.fullName ??
        '')
        .trim();
    final displayName = userName.isEmpty ? 'Driver' : userName;

    return AppBar(
      automaticallyImplyLeading: false,
      backgroundColor: Colors.transparent,
      elevation: 0,
      // COMPACT TOOLBAR HEIGHT
      toolbarHeight: 140,
      actions: [
        // Forces the filter icon to the Top Right
        Column(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 12.0, right: 8.0),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  IconButton(
                    icon: const Icon(Icons.filter_list, color: Colors.white),
                    onPressed: _openFilterPage,
                    tooltip: 'Filters',
                    constraints: const BoxConstraints(), // Removes default padding
                    padding: const EdgeInsets.all(8),
                  ),
                  if (hasActiveFilters)
                    Positioned(
                      right: 8,
                      top: 8,
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
            ),
          ],
        ),
      ],
      flexibleSpace: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFFE65100), // Dark Orange
              Color(0xFFFF6F00), // Orange
              Color(0xFF1976D2), // Blue
            ],
            stops: [0.0, 0.5, 1.0],
          ),
        ),
        child: Padding(
          // COMPACT PADDING: Reduced top padding for better header-tab separation
          padding: const EdgeInsets.fromLTRB(20, 60, 20, 9),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // User Profile Row
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  CircleAvatar(
                    radius: 20, // Reduced from 24
                    backgroundColor: Colors.white.withOpacity(0.2),
                    child: Text(
                      displayName.isEmpty ? 'D' : displayName.substring(0, 1),
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        fontSize: 18,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Hello,',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.8),
                            fontSize: 12,
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                        Text(
                          displayName.isEmpty ? 'Driver' : displayName,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.3,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8), // Reduced gap for better compactness
              // Stats Cards Row
              Row(
                children: [
                  Expanded(
                    child: _buildStatCard(
                      "Pending",
                      "$count",
                      Icons.assignment_late_outlined,
                      const Color(0xFFFF6F00), // Orange to match theme
                      const Color(0xFFE65100), // Dark Orange
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _buildStatCard(
                      "Total",
                      "₹${(value / 1000).toStringAsFixed(1)}k",
                      Icons.account_balance_wallet_outlined,
                      const Color(0xFF42A5F5), // Light Blue to match theme
                      const Color(0xFF1976D2), // Blue
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatCard(String label, String value, IconData icon,
      Color bgColor, Color iconColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(5),
            decoration: BoxDecoration(
              color: bgColor.withOpacity(0.2),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Icon(icon, color: bgColor, size: 16),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  value,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  label,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.7),
                    fontSize: 10,
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
    );
  }

  Widget _buildModernTaskCard(
      DeliveryBill bill, int index, ColorScheme colorScheme) {
    final bool isDone = _statusFromBill(bill) == TaskStatus.done;

    Color statusBgColor;
    Color statusTextColor;
    String statusText;
    if (_statusFromBill(bill) == TaskStatus.done) {
      statusBgColor = const Color(0xFFE8F5E9);
      statusTextColor = const Color(0xFF2E7D32);
      statusText = "COMPLETED";
    } else if (_statusFromBill(bill) == TaskStatus.returnTask) {
      statusBgColor = const Color(0xFFFFEBEE);
      statusTextColor = const Color(0xFFC62828);
      statusText = "RETURN";
    } else {
      statusBgColor = const Color(0xFFFFF8E1);
      statusTextColor = const Color(0xFFEF6C00);
      statusText = "PENDING";
    }

    final typeColor = const Color(0xFF1976D2);

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: colorScheme.shadow.withOpacity(0.08),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          // Header Section
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainerLowest,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
              border: Border(
                bottom: BorderSide(
                  color: colorScheme.outlineVariant.withOpacity(0.3),
                  width: 1,
                ),
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
                        color: typeColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        "#$index",
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: typeColor,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      bill.billdate != 'NA' ? bill.billdate : '',
                      style: TextStyle(
                        fontSize: 12,
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
                Container(
                  padding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusBgColor,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    statusText,
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

          // Body Section
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  bill.acname,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: colorScheme.onSurface,
                    height: 1.2,
                  ),
                ),
                const SizedBox(height: 8),

                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.location_on_outlined,
                        size: 16, color: colorScheme.onSurfaceVariant),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Station - Primary info
                          Text(
                            bill.station != 'NA' ? bill.station : 'N/A',
                            style: TextStyle(
                              fontSize: 13,
                              color: colorScheme.onSurface,
                              fontWeight: FontWeight.w600,
                              height: 1.3,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          // Area and Route - Horizontal layout
                          if (bill.area != 'NA' || bill.route != 'NA')
                            Padding(
                              padding: const EdgeInsets.only(top: 4.0),
                              child: Row(
                                children: [
                                  // Area with label
                                  if (bill.area != 'NA')
                                    Expanded(
                                      child: Text(
                                        'Area: ${bill.area}',
                                        style: TextStyle(
                                          fontSize: 11,
                                          color: colorScheme.onSurfaceVariant,
                                          height: 1.2,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  // Divider
                                  if (bill.area != 'NA' && bill.route != 'NA')
                                    Padding(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 6.0),
                                      child: Text(
                                        '•',
                                        style: TextStyle(
                                          color:
                                              colorScheme.onSurfaceVariant,
                                          fontSize: 10,
                                        ),
                                      ),
                                    ),
                                  // Route with label
                                  if (bill.route != 'NA')
                                    Expanded(
                                      child: Text(
                                        'Route: ${bill.route}',
                                        style: TextStyle(
                                          fontSize: 11,
                                          color: colorScheme.onSurfaceVariant,
                                          height: 1.2,
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
                    color: colorScheme.surfaceContainerHigh.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildInfoItem(
                          "Bill No", bill.billno, colorScheme, false),
                      Container(
                          width: 1,
                          height: 24,
                          color: colorScheme.outlineVariant),
                      _buildInfoItem("Amount",
                          "₹${bill.billamt.toStringAsFixed(0)}", colorScheme, true),
                      Container(
                          width: 1,
                          height: 24,
                          color: colorScheme.outlineVariant),
                      _buildInfoItem("Items", "${bill.item}", colorScheme, false),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Actions
          if (!isDone)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Row(
                children: [
                  SizedBox(
                    width: 48,
                    height: 48,
                    child: OutlinedButton(
                      onPressed: () => _openMapsNavigation(bill),
                      style: OutlinedButton.styleFrom(
                        padding: EdgeInsets.zero,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        side: BorderSide(color: colorScheme.outlineVariant),
                      ),
                      child: Icon(Icons.near_me_outlined,
                          color: colorScheme.onSurface),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: SizedBox(
                      height: 48,
                      child: ElevatedButton.icon(
                        onPressed: () => _navigateToDetails(bill),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF1A237E),
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        icon: const Icon(Icons.check_circle_outline, size: 20),
                        label: const Text(
                          "Mark Delivered",
                          style: TextStyle(
                              fontWeight: FontWeight.w600, fontSize: 14),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
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
              color: isAmount ? const Color(0xFF1A237E) : colorScheme.onSurface,
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
              color: colorScheme.surfaceContainerHighest.withOpacity(0.5),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.inventory_2_outlined,
                size: 48, color: colorScheme.outline),
          ),
          const SizedBox(height: 16),
          Text("No tasks found",
              style: TextStyle(
                  fontSize: 16,
                  color: colorScheme.onSurface,
                  fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          Text("Try adjusting filters or checking back later",
              style:
              TextStyle(fontSize: 13, color: colorScheme.onSurfaceVariant)),
        ],
      ),
    );
  }

  Future<void> _openMapsNavigation(DeliveryBill bill) async {
    try {
      // Try using coordinates first
      if (bill.latitude != null && bill.longitude != null) {
        final googleMapsUrl = Uri.parse(
            'google.navigation:q=${bill.latitude},${bill.longitude}&mode=d');
        await launchUrl(googleMapsUrl, mode: LaunchMode.externalApplication);
        return;
      }

      // Fallback to address-based navigation
      final queryParts = <String>[];
      if (bill.station != 'NA') queryParts.add(bill.station);
      if (bill.area != 'NA') queryParts.add(bill.area);

      if (queryParts.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Location not available for this delivery'),
              duration: Duration(seconds: 2),
            ),
          );
        }
        return;
      }

      final query = Uri.encodeComponent(queryParts.join(', '));
      final googleMapsUrl = Uri.parse('google.navigation:q=$query&mode=d');
      await launchUrl(googleMapsUrl, mode: LaunchMode.externalApplication);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Could not open Google Maps. Please make sure it is installed.'),
            duration: Duration(seconds: 3),
          ),
        );
      }
    }
  }

  void _navigateToDetails(DeliveryBill bill) {
    DateTime billDate = DateTime.now();
    if (bill.billdate != "NA") {
      try {
        final parts = bill.billdate.split('/');
        if (parts.length == 3) {
          final day = int.tryParse(parts[0]);
          final monthStr = parts[1].toLowerCase();
          final year = int.tryParse(parts[2]);
          final monthMap = {
            'jan': 1,
            'feb': 2,
            'mar': 3,
            'apr': 4,
            'may': 5,
            'jun': 6,
            'jul': 7,
            'aug': 8,
            'sep': 9,
            'oct': 10,
            'nov': 11,
            'dec': 12,
            'january': 1,
            'february': 2,
            'march': 3,
            'april': 4,
            'june': 6,
            'july': 7,
            'august': 8,
            'september': 9,
            'october': 10,
            'november': 11,
            'december': 12
          };
          final month = monthMap[monthStr];
          if (day != null && month != null && year != null) {
            billDate = DateTime(year, month, day);
          }
        }
      } catch (_) {
        try {
          billDate = DateTime.parse(bill.billdate);
        } catch (_) {}
      }
    }

    Navigator.of(context).push(MaterialPageRoute(
      builder: (context) => MarkDeliveredPage(
        task: DeliveryTask(
          id: bill.keyno,
          type: TaskType.delivery,
          status: _statusFromBill(bill),
          partyName: bill.acname,
          partyId: bill.acno,
          station: bill.station,
          billNo: bill.billno,
          billDate: billDate,
          billAmount: bill.billamt,
          itemCount: bill.item,
          area: bill.area == "NA" ? "" : bill.area,
          latitude: null,
          longitude: null,
          paymentType: PaymentType.cash,
          mobile: bill.mobile == "NA" ? null : bill.mobile,
        ),
      ),
    ));
  }
}

// --- DATA MODEL ---

class DeliveryBill {
  final String acname, billno, billdate, acno, mobile, station;
  final String address, remark, area, route, statusName, status;
  final String keyno;
  final double billamt;
  final int item, qty;
  final String? latitude;
  final String? longitude;

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
    this.latitude,
    this.longitude,
  });

  factory DeliveryBill.fromJson(Map<String, dynamic> json) {
    String str(String key) {
      final val = json[key];
      if (val == null) return 'NA';
      final s = val.toString().trim();
      if (s.toLowerCase() == 'null' || s.isEmpty) return 'NA';
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
    if (json['address1'] != null)
      validAddrParts.add(json['address1'].toString());
    if (json['address2'] != null)
      validAddrParts.add(json['address2'].toString());
    if (json['address3'] != null)
      validAddrParts.add(json['address3'].toString());

    String fullAddress =
    validAddrParts.where((s) => s.trim().isNotEmpty).join(', ');
    if (fullAddress.isEmpty) fullAddress = "NA";

    String? strNullable(String key) {
      final val = json[key];
      if (val == null) return null;
      final s = val.toString().trim();
      if (s.isEmpty || s.toLowerCase() == 'null') return null;
      return s;
    }

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
      statusName: str('stausname'),
      status: str('status'),
      keyno: str('keyno'),
      latitude: strNullable('latitude'),
      longitude: strNullable('longitude'),
    );
  }
}


