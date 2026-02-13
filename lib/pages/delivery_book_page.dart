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

class _DeliveryBookPageState extends State<DeliveryBookPage> {
  static const int _pageSize = 10;

  final ScrollController _scrollController = ScrollController();
  final List<DeliveryBill> _bills = [];
  List<DeliveryBill> _filteredBills = [];

  bool _isLoading = false;
  int _pageNo = 1;
  bool _hasMore = true;

  // API Filters - matches new format from DeliveryFilterPage
  List<Map<String, dynamic>> _apiFilters = [];
  bool _sortByLocation = true;

  // UI Status Filter
  TaskStatus? _statusFilter;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    _loadBills(reset: true);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 200 &&
        !_isLoading && _hasMore) {
      _loadBills();
    }
  }

  // --- LOAD BILLS WITH WORKING PAGINATION ---
  Future<void> _loadBills({bool reset = false}) async {
    if (reset) {
      if (mounted) setState(() { _isLoading = true; _bills.clear(); _pageNo = 1; _hasMore = true; });
    }

    try {
      final auth = Provider.of<AuthService>(context, listen: false);
      // Use auth.getDioClient() to get Dio with 401 interceptor
      final dio = auth.getDioClient();

      // _apiFilters is already in the correct format: List<Map<String, dynamic>>
      // Each map has 'id' (categoryId) and 'items' (list of itemIds)

      final payload = jsonEncode({
        'lLicNo': auth.currentUser?.licenseNumber ?? '',
        'luserid': auth.currentUser?.mobileNumber ?? auth.currentUser?.userId ?? '',
        'lPageNo': _pageNo.toString(),
        'lSize': _pageSize.toString(),
        'laid': 0,
        'lrtid': 0,
        'lExecuteTotalRows': 1,
        'filters': _apiFilters,
      });

      debugPrint('[DeliveryBook] Loading page $_pageNo with size $_pageSize and ${_apiFilters.length} filter categories');

      final headers = {
        'Content-Type': 'application/json',
        'Authorization': auth.getAuthHeader() ?? '',
        'package_name': auth.packageNameHeader,
      };

      final response = await dio.post('/getdeleveredbillList', data: payload, options: Options(headers: headers));

      String cleanJson = response.data.toString().replaceAll(RegExp(r'[\x00-\x1F\x7F]'), '').trim();
      final decoded = jsonDecode(cleanJson);
      final Map<String, dynamic> root = decoded is Map<String, dynamic> ? decoded : {};
      final Map<String, dynamic> container = root['data'] is Map<String, dynamic>
          ? root['data'] as Map<String, dynamic>
          : root;

      final bool apiSuccess = root['success'] == true || root['Status'] == true || container['Status'] == true;
      if (!apiSuccess) {
        throw Exception(root['message'] ?? root['Message'] ?? 'Server failure');
      }

      // Extract the bills list - try multiple keys
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
          final parsed = (e is String) ? jsonDecode(e) as Map<String, dynamic> : Map<String, dynamic>.from(e);
          return DeliveryBill.fromJson(parsed);
        } catch (_) {
          return DeliveryBill.fromJson({});
        }
      }).toList();

      debugPrint('[DeliveryBook] Loaded ${newBills.length} bills for page $_pageNo');

      if (mounted) {
        setState(() {
          _bills.addAll(newBills);
          _sortTasks();
          _applyStatusFilter();
          _hasMore = newBills.length >= _pageSize;
          if (_hasMore) _pageNo++;
          _isLoading = false;
        });
        debugPrint('[DeliveryBook] Total bills: ${_bills.length}, hasMore: $_hasMore, nextPage: $_pageNo');
      }
    } catch (e) {
      debugPrint('[DeliveryBook] Error: $e');
      if (mounted) {
        setState(() => _isLoading = false);
        if (_bills.isEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: ${e.toString()}")));
        }
      }
    }
  }

  TaskStatus _statusFromBill(DeliveryBill bill) {
    final raw = (bill.statusName != 'NA' ? bill.statusName : bill.status).toLowerCase();
    if (raw.contains('return')) return TaskStatus.returnTask;
    if (raw.contains('deliver') || raw.contains('done') || raw.contains('complete')) return TaskStatus.done;
    if (raw == '1') return TaskStatus.done;
    if (raw == '2') return TaskStatus.returnTask;
    if (raw.contains('pending') || raw == '0' || raw.isEmpty) return TaskStatus.pending;
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
    setState(() {
      if (_statusFilter == null) {
        _filteredBills = List.from(_bills);
      } else {
        _filteredBills = _bills.where((bill) => _statusFromBill(bill) == _statusFilter).toList();
      }
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
      _loadBills(reset: true); // Reload with new filters
    }
  }

  // --- REDESIGNED BUILD METHOD ---
  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    if (_isLoading && _bills.isEmpty) {
      return Scaffold(
        backgroundColor: colorScheme.surface,
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    final pendingCount = _bills.where((bill) => _statusFromBill(bill) == TaskStatus.pending).length;
    final totalValue = _bills.fold(0.0, (sum, bill) => sum + bill.billamt);
    final bool hasActiveFilters = _apiFilters.isNotEmpty;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      body: CustomScrollView(
        controller: _scrollController,
        physics: const BouncingScrollPhysics(),
        slivers: [
          _buildSliverAppBar(pendingCount, totalValue, colorScheme, hasActiveFilters),

          // Status Filter Pills
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                child: Row(
                  children: [
                    _buildStatusChip('All', _statusFilter == null, () {
                      setState(() {
                        _statusFilter = null;
                        _applyStatusFilter();
                      });
                    }, colorScheme),
                    const SizedBox(width: 8),
                    _buildStatusChip('Pending', _statusFilter == TaskStatus.pending, () {
                      setState(() {
                        _statusFilter = TaskStatus.pending;
                        _applyStatusFilter();
                      });
                    }, colorScheme),
                    const SizedBox(width: 8),
                    _buildStatusChip('Completed', _statusFilter == TaskStatus.done, () {
                      setState(() {
                        _statusFilter = TaskStatus.done;
                        _applyStatusFilter();
                      });
                    }, colorScheme),
                    const SizedBox(width: 8),
                    _buildStatusChip('Return', _statusFilter == TaskStatus.returnTask, () {
                      setState(() {
                        _statusFilter = TaskStatus.returnTask;
                        _applyStatusFilter();
                      });
                    }, colorScheme),
                  ],
                ),
              ),
            ),
          ),

          _filteredBills.isEmpty
              ? SliverFillRemaining(child: _buildEmptyState(colorScheme))
              : SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
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
                        return _buildModernTaskCard(_filteredBills[index], index + 1, colorScheme);
                      },
                      childCount: _filteredBills.length + (_hasMore && _filteredBills.isNotEmpty ? 1 : 0),
                    ),
                  ),
                ),

          const SliverPadding(padding: EdgeInsets.only(bottom: 80)),
        ],
      ),
    );
  }

  Widget _buildSliverAppBar(int count, double value, ColorScheme colorScheme, bool hasActiveFilters) {
    final userName = (Provider.of<AuthService>(context, listen: false).currentUser?.fullName ?? '').trim();
    final displayName = userName.isEmpty ? 'Driver' : userName;

    return SliverAppBar(
      expandedHeight: 220.0,
      floating: false,
      pinned: true,
      backgroundColor: const Color(0xFF1A237E), // Deep Blue theme color
      iconTheme: const IconThemeData(color: Colors.white),
      actions: [
        // Filter Button with Badge
        Stack(
          alignment: Alignment.center,
          children: [
            IconButton(
              icon: const Icon(Icons.filter_list),
              onPressed: _openFilterPage,
              tooltip: 'Filters',
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
        const SizedBox(width: 8),
      ],
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                const Color(0xFF1A237E), // Deep Blue
                const Color(0xFFFF6F00), // Orange
              ],
            ),
          ),
          child: Stack(
            children: [
              Positioned(
                top: -50, right: -50,
                child: Container(
                  width: 200, height: 200,
                  decoration: BoxDecoration(
                    color: colorScheme.onPrimary.withValues(alpha: 0.05),
                    shape: BoxShape.circle,
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(left: 20, right: 20, top: 80),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        CircleAvatar(
                          radius: 26,
                          backgroundColor: colorScheme.secondaryContainer,
                          child: Text(
                            displayName.substring(0, 1),
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: colorScheme.onSecondaryContainer,
                              fontSize: 20,
                            ),
                          ),
                        ),
                        const SizedBox(width: 15),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text("Hello,", style: TextStyle(color: colorScheme.onPrimary.withValues(alpha: 0.7), fontSize: 14)),
                            Text(
                              displayName,
                              style: TextStyle(color: colorScheme.onPrimary, fontSize: 20, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 25),
                    Container(
                      padding: const EdgeInsets.all(15),
                      decoration: BoxDecoration(
                        color: colorScheme.onPrimary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: colorScheme.onPrimary.withValues(alpha: 0.1)),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          _buildStatItem("Pending", "$count Tasks", Icons.assignment_late, Colors.orange, colorScheme),
                          Container(width: 1, height: 30, color: colorScheme.onPrimary.withValues(alpha: 0.2)),
                          _buildStatItem("Total Value", "₹${(value/1000).toStringAsFixed(1)}k", Icons.currency_rupee, Colors.blue.shade400, colorScheme),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      title: const Text("Delivery Book", style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
      centerTitle: true,
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon, Color iconColor, ColorScheme colorScheme) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(color: iconColor.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(8)),
          child: Icon(icon, color: iconColor, size: 18),
        ),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: TextStyle(color: colorScheme.onPrimary.withValues(alpha: 0.7), fontSize: 11)),
            Text(value, style: TextStyle(color: colorScheme.onPrimary, fontWeight: FontWeight.bold, fontSize: 15)),
          ],
        )
      ],
    );
  }

  Widget _buildStatusChip(String label, bool isSelected, VoidCallback onTap, ColorScheme colorScheme) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF1A237E) : colorScheme.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? const Color(0xFF1A237E) : colorScheme.outlineVariant,
          ),
          boxShadow: isSelected ? [
            BoxShadow(
              color: const Color(0xFF1A237E).withValues(alpha: 0.3),
              blurRadius: 4,
              offset: const Offset(0, 2),
            )
          ] : [],
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : colorScheme.onSurface,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
            fontSize: 13,
          ),
        ),
      ),
    );
  }


  Widget _buildModernTaskCard(DeliveryBill bill, int index, ColorScheme colorScheme) {
    final bool isDone = _statusFromBill(bill) == TaskStatus.done;

    Color statusBgColor;
    String statusText;
    if (_statusFromBill(bill) == TaskStatus.done) {
      statusBgColor = Colors.green;
      statusText = "COMPLETED";
    } else if (_statusFromBill(bill) == TaskStatus.returnTask) {
      statusBgColor = Colors.red;
      statusText = "RETURN";
    } else {
      statusBgColor = Colors.amber.shade700;
      statusText = "PENDING";
    }

    final typeColor = Colors.blue;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(color: colorScheme.shadow.withValues(alpha: 0.05), blurRadius: 15, offset: const Offset(0, 5)),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: typeColor.withValues(alpha: 0.05),
                border: Border(bottom: BorderSide(color: colorScheme.outlineVariant.withValues(alpha: 0.3))),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                              color: typeColor.withValues(alpha: 0.1),
                              shape: BoxShape.circle
                          ),
                          child: Icon(
                            Icons.local_shipping,
                            size: 16,
                            color: typeColor.withValues(alpha: 0.8),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            "DELIVERY #$index",
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.5,
                              color: typeColor.withValues(alpha: 0.9),
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: statusBgColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      statusText,
                      style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 10),
                    ),
                  )
                ],
              ),
            ),

            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    bill.acname,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: colorScheme.onSurface,
                      height: 1.2,
                    ),
                  ),
                  const SizedBox(height: 6),

                  Row(
                    children: [
                      Icon(Icons.location_on_outlined, size: 16, color: colorScheme.onSurfaceVariant),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          '${bill.area} • ${bill.station}',
                          style: TextStyle(fontSize: 13, color: colorScheme.onSurfaceVariant, height: 1.4),
                          maxLines: 1, overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),

                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    child: Divider(height: 1, color: colorScheme.outlineVariant.withValues(alpha: 0.5)),
                  ),
                  Row(
                    children: [
                      _buildDetailColumn("BILL NO", bill.billno, colorScheme),
                      const Spacer(),
                      _buildDetailColumn("AMOUNT", "₹${bill.billamt.toStringAsFixed(0)}", colorScheme, isHighlight: true),
                      const Spacer(),
                      _buildDetailColumn("ITEMS", "${bill.item}", colorScheme),
                    ],
                  ),
                ],
              ),
            ),

            if (!isDone)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                child: Row(
                  children: [
                    Expanded(
                      flex: 1,
                      child: OutlinedButton(
                        onPressed: () => _openMapsNavigation(bill),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          side: BorderSide(color: colorScheme.outlineVariant),
                          foregroundColor: colorScheme.onSurface,
                        ),
                        child: const Icon(Icons.near_me, size: 20),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 3,
                      child: ElevatedButton(
                        onPressed: () => _navigateToDetails(bill),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF1A237E),
                          foregroundColor: Colors.white,
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: const Text(
                          "Mark Delivered",
                          style: TextStyle(fontWeight: FontWeight.w600),
                        ),
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

  Widget _buildDetailColumn(String label, String value, ColorScheme colorScheme, {bool isHighlight = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: colorScheme.onSurfaceVariant, letterSpacing: 0.5),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: Colors.black,
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState(ColorScheme colorScheme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.filter_none, size: 60, color: colorScheme.outlineVariant),
          const SizedBox(height: 16),
          Text("No tasks found", style: TextStyle(fontSize: 16, color: colorScheme.onSurfaceVariant, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  Future<void> _openMapsNavigation(DeliveryBill bill) async {
    final queryParts = <String>[];
    if (bill.address != 'NA') queryParts.add(bill.address);
    if (bill.area != 'NA') queryParts.add(bill.area);
    if (bill.station != 'NA') queryParts.add(bill.station);
    if (queryParts.isEmpty) return;

    final query = Uri.encodeComponent(queryParts.join(', '));
    final googleMapsUrl = Uri.parse('google.navigation:q=$query&mode=d');
    if (await canLaunchUrl(googleMapsUrl)) {
      await launchUrl(googleMapsUrl, mode: LaunchMode.externalApplication);
    }
  }

  void _navigateToDetails(DeliveryBill bill) {
    // Logic remains exactly the same
    DateTime billDate = DateTime.now();
    if (bill.billdate != "NA") {
      try {
        final parts = bill.billdate.split('/');
        if (parts.length == 3) {
          final day = int.tryParse(parts[0]);
          final monthStr = parts[1].toLowerCase();
          final year = int.tryParse(parts[2]);
          final monthMap = {'jan': 1, 'feb': 2, 'mar': 3, 'apr': 4, 'may': 5, 'jun': 6, 'jul': 7, 'aug': 8, 'sep': 9, 'oct': 10, 'nov': 11, 'dec': 12, 'january': 1, 'february': 2, 'march': 3, 'april': 4, 'june': 6, 'july': 7, 'august': 8, 'september': 9, 'october': 10, 'november': 11, 'december': 12};
          final month = monthMap[monthStr];
          if (day != null && month != null && year != null) {
            billDate = DateTime(year, month, day);
          }
        }
      } catch (_) {
        try { billDate = DateTime.parse(bill.billdate); } catch (_) {}
      }
    }

    Navigator.of(context).push(MaterialPageRoute(
      builder: (context) => MarkDeliveredPage(
        task: DeliveryTask(
          id: bill.keyno, // Use full keyno instead of just billno
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
          latitude: null, longitude: null, paymentType: PaymentType.cash,
          mobile: bill.mobile == "NA" ? null : bill.mobile,
        ),
      ),
    ));
  }
}

// --- DATA MODEL (Kept exactly as provided) ---

class DeliveryBill {
  final String acname, billno, billdate, acno, mobile, station;
  final String address, remark, area, route, statusName, status;
  final String keyno; // Full bill key like "20250401/SALE  /AMPL  /O000001"
  final double billamt;
  final int item, qty;

  DeliveryBill({
    required this.acname, required this.address, required this.mobile,
    required this.billno, required this.billdate, required this.billamt,
    required this.item, required this.qty, required this.station,
    required this.acno, required this.remark, required this.area,
    required this.route, required this.statusName, required this.status,
    required this.keyno,
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
    if (json['address1'] != null) validAddrParts.add(json['address1'].toString());
    if (json['address2'] != null) validAddrParts.add(json['address2'].toString());
    if (json['address3'] != null) validAddrParts.add(json['address3'].toString());

    String fullAddress = validAddrParts.where((s) => s.trim().isNotEmpty).join(', ');
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
      statusName: str('stausname'),
      status: str('status'),
      keyno: str('keyno'),
    );
  }
}