import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:dio/dio.dart';
import 'dart:convert';
import 'package:url_launcher/url_launcher.dart';

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
      status;
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
    if (_scrollController.position.pixels >=
            _scrollController.position.maxScrollExtent - 200 &&
        !_isLoading &&
        _hasMore) {
      _loadBills();
    }
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

      final List<int> deliveryStatus = [1];

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

      if (mounted) {
        setState(() {
          _bills.addAll(newBills);
          _hasMore = newBills.length >= _pageSize;
          if (_hasMore) _pageNo++;
          _applySearch();
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

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    if (_isLoading && _bills.isEmpty) {
      return Scaffold(
        backgroundColor: colorScheme.surface,
        appBar: AppBar(
          title: const Text('Completed Deliveries'),
          backgroundColor: const Color(0xFF1A237E),
          foregroundColor: Colors.white,
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    final totalValue = _bills.fold(0.0, (sum, bill) => sum + bill.billamt);
    final bool hasActiveFilters = _apiFilters.isNotEmpty;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(140),
        child: _buildAppBar(totalValue, colorScheme, hasActiveFilters),
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
                          return _filteredBills.isNotEmpty && _isLoading && _hasMore
                              ? const Center(
                                  child: Padding(
                                    padding: EdgeInsets.all(24),
                                    child: CircularProgressIndicator(
                                        strokeWidth: 2),
                                  ),
                                )
                              : const SizedBox.shrink();
                        }
                        return _buildDeliveryCard(
                            _filteredBills[index], index + 1, colorScheme);
                      },
                      childCount: _filteredBills.length +
                          (_hasMore && _filteredBills.isNotEmpty ? 1 : 0),
                    ),
                  ),
                ),
        ],
      ),
    );
  }

  AppBar _buildAppBar(
      double value, ColorScheme colorScheme, bool hasActiveFilters) {
    return AppBar(
      backgroundColor: Colors.transparent,
      elevation: 0,
      toolbarHeight: 120,
      automaticallyImplyLeading: false,
      flexibleSpace: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFFE65100),
              Color(0xFFFF6F00),
              Color(0xFF1976D2),
            ],
            stops: [0.0, 0.5, 1.0],
          ),
        ),
        child: SafeArea(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: IconButton(
                        icon: const Icon(Icons.arrow_back, color: Colors.white),
                        onPressed: () => Navigator.of(context).pop(),
                        padding: const EdgeInsets.all(8),
                        constraints: const BoxConstraints(),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Completed Deliveries',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              const Icon(Icons.check_circle,
                                  size: 14, color: Colors.white),
                              const SizedBox(width: 4),
                              Text(
                                '${_filteredBills.length} deliveries',
                                style: const TextStyle(
                                  fontSize: 13,
                                  color: Colors.white,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const SizedBox(width: 12),
                              const Icon(Icons.currency_rupee,
                                  size: 14, color: Colors.white),
                              Text(
                                '${(value / 1000).toStringAsFixed(1)}k',
                                style: const TextStyle(
                                  fontSize: 13,
                                  color: Colors.white,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: Container(
                        height: 44,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: TextField(
                          decoration: const InputDecoration(
                            hintText: 'Search deliveries...',
                            hintStyle: TextStyle(
                              fontSize: 14,
                              color: Colors.white70,
                            ),
                            prefixIcon: Icon(
                              Icons.search,
                              color: Colors.white,
                              size: 20,
                            ),
                            border: InputBorder.none,
                            contentPadding: EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 12,
                            ),
                          ),
                          style: const TextStyle(
                            fontSize: 14,
                            color: Colors.white,
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
                    const SizedBox(width: 12),
                    Container(
                      height: 44,
                      decoration: BoxDecoration(
                        color: hasActiveFilters
                            ? Colors.white
                            : Colors.white.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          IconButton(
                            icon: Icon(
                              Icons.tune,
                              color: hasActiveFilters
                                  ? Colors.orange.shade700
                                  : Colors.white,
                            ),
                            onPressed: _openFilterPage,
                            tooltip: 'Filters',
                            padding: const EdgeInsets.all(10),
                          ),
                          if (hasActiveFilters)
                            Positioned(
                              right: 6,
                              top: 6,
                              child: Container(
                                width: 8,
                                height: 8,
                                decoration: BoxDecoration(
                                  color: Colors.blue.shade700,
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
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDeliveryCard(
      DeliveryBill bill, int index, ColorScheme colorScheme) {
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
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: colorScheme.surfaceContainerLowest,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: colorScheme.shadow.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: const Color(0xFF1976D2).withValues(alpha: 0.05),
                border: Border(
                  bottom: BorderSide(
                    color: colorScheme.outlineVariant.withValues(alpha: 0.3),
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
                          color: const Color(0xFF1976D2).withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          "#$index",
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF1976D2),
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
                      color: const Color(0xFFFFF3E0),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Text(
                      "COMPLETED",
                      style: TextStyle(
                        color: Color(0xFFE65100),
                        fontWeight: FontWeight.bold,
                        fontSize: 10,
                        letterSpacing: 0.5,
                      ),
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
                            if (bill.area != 'NA' || bill.route != 'NA')
                              Padding(
                                padding: const EdgeInsets.only(top: 4.0),
                                child: Row(
                                  children: [
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
                      color: colorScheme.surfaceContainerHigh
                          .withValues(alpha: 0.3),
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
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: SizedBox(
                width: double.infinity,
                height: 48,
                child: OutlinedButton.icon(
                  onPressed: () => _openMapsNavigation(bill),
                  style: OutlinedButton.styleFrom(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    side: BorderSide(color: colorScheme.outlineVariant),
                    foregroundColor: const Color(0xFF1A237E),
                  ),
                  icon: const Icon(Icons.near_me_outlined, size: 20),
                  label: const Text(
                    "View on Map",
                    style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                  ),
                ),
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
              color: colorScheme.surfaceContainerHighest
                  .withValues(alpha: 0.5),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.check_circle_outline,
                size: 48, color: colorScheme.outline),
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

  Future<void> _openMapsNavigation(DeliveryBill bill) async {
    // Try to use lat/long if available
    if (bill.latitude != null && bill.longitude != null) {
      final googleMapsUrl = Uri.parse(
          'google.navigation:q=${bill.latitude},${bill.longitude}&mode=d');
      if (await canLaunchUrl(googleMapsUrl)) {
        await launchUrl(googleMapsUrl, mode: LaunchMode.externalApplication);
        return;
      }
    }

    // Fallback to station name search
    final queryParts = <String>[];
    if (bill.station != 'NA') queryParts.add(bill.station);
    if (queryParts.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Location not available')),
        );
      }
      return;
    }

    final query = Uri.encodeComponent(queryParts.join(', '));
    final googleMapsUrl = Uri.parse('google.navigation:q=$query&mode=d');
    if (await canLaunchUrl(googleMapsUrl)) {
      await launchUrl(googleMapsUrl, mode: LaunchMode.externalApplication);
    }
  }
}

