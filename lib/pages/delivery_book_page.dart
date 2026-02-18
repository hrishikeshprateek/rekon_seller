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

  // API Filters
  List<Map<String, dynamic>> _apiFilters = [];
  bool _sortByLocation = true;

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

  // --- API LOADING LOGIC ---
  Future<void> _loadBills({bool reset = false}) async {
    if (reset) {
      if (mounted) {
        setState(() {
          _isLoading = true;
          _bills.clear();
          _filteredBills.clear();
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

      // Payload (Keeping deliveryStatus empty as per original logic for Pending)
      final payload = jsonEncode({
        'lLicNo': auth.currentUser?.licenseNumber ?? '',
        'luserid':
        auth.currentUser?.mobileNumber ?? auth.currentUser?.userId ?? '',
        'lPageNo': _pageNo,
        'lSize': _pageSize,
        'laid': areaIds,
        'lrtid': routeIds,
        'ldeliveryStatus': [],
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
        if (e is Map<String, dynamic>) {
          final bill = DeliveryBill.fromJson(e);
          debugPrint('[DeliveryBook] Bill: ${bill.acname}, Lat: ${bill.latitude}, Lng: ${bill.longitude}');
          return bill;
        }
        try {
          final parsed = (e is String)
              ? jsonDecode(e) as Map<String, dynamic>
              : Map<String, dynamic>.from(e);
          final bill = DeliveryBill.fromJson(parsed);
          debugPrint('[DeliveryBook] Bill: ${bill.acname}, Lat: ${bill.latitude}, Lng: ${bill.longitude}');
          return bill;
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
              longitude: null);
        }
      }).toList();

      if (mounted) {
        setState(() {
          _bills.addAll(newBills);

          // SORTING
          if (_sortByLocation) {
            _bills.sort((a, b) {
              final areaCompare = a.area.compareTo(b.area);
              if (areaCompare != 0) return areaCompare;
              return a.acname.compareTo(b.acname);
            });
          } else {
            _bills.sort((a, b) => a.acname.compareTo(b.acname));
          }

          // FILTER: STRICTLY PENDING ONLY
          _filteredBills = _bills
              .where((bill) => _statusFromBill(bill) == TaskStatus.pending)
              .toList();

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
    // Anything else is Pending
    return TaskStatus.pending;
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

  // --- SIMPLE BUILD METHOD ---
  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    if (_isLoading && _bills.isEmpty) {
      return Scaffold(
        backgroundColor: colorScheme.surface,
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    final bool hasActiveFilters = _apiFilters.isNotEmpty;
    final userName = (Provider.of<AuthService>(context, listen: false)
        .currentUser
        ?.fullName ??
        '')
        .trim();
    final displayName = userName.isEmpty ? 'Driver' : userName;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1A237E), // Navy Blue
        foregroundColor: Colors.white,
        elevation: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              displayName,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            Text(
              '${_filteredBills.length} Pending Tasks',
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w400),
            ),
          ],
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
      body: _filteredBills.isEmpty
          ? _buildEmptyState(colorScheme)
          : ListView.builder(
        controller: _scrollController,
        padding: const EdgeInsets.all(16),
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
          return _buildModernTaskCard(
              _filteredBills[index], index + 1, colorScheme);
        },
      ),
    );
  }

  Widget _buildModernTaskCard(
      DeliveryBill bill, int index, ColorScheme colorScheme) {
    // Styling constants
    final statusBgColor = const Color(0xFFFFF8E1); // Light Amber
    final statusTextColor = const Color(0xFFEF6C00); // Dark Orange
    final typeColor = const Color(0xFF1A237E);

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
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
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    "PENDING",
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
                      child: Text(
                        '${bill.area != 'NA' ? bill.area : ''} ${bill.area != 'NA' && bill.station != 'NA' ? '•' : ''} ${bill.station != 'NA' ? bill.station : ''}',
                        style: const TextStyle(
                          fontSize: 13,
                          color: Color(0xFF616161),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                // Area and Route information
                Row(
                  children: [
                    // Area
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
                              text: bill.area != 'NA' ? bill.area : 'N/A',
                              style: const TextStyle(
                                fontSize: 12,
                                color: Color(0xFF212121),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    // Route
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
                              text: bill.route != 'NA' ? bill.route : 'N/A',
                              style: const TextStyle(
                                fontSize: 12,
                                color: Color(0xFF212121),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
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
                      _buildInfoItem("Bill No", bill.billno, false),
                      Container(width: 1, height: 24, color: Colors.grey[300]),
                      _buildInfoItem("Amount",
                          "₹${bill.billamt.toStringAsFixed(0)}", true),
                      Container(width: 1, height: 24, color: Colors.grey[300]),
                      _buildInfoItem("Items", "${bill.item}", false),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Actions
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Row(
              children: [
                SizedBox(
                  width: 48,
                  height: 48,
                  child: OutlinedButton(
                    onPressed: (bill.latitude != null && bill.longitude != null &&
                                 bill.latitude!.trim().isNotEmpty && bill.longitude!.trim().isNotEmpty)
                        ? () => _openMapsNavigation(bill)
                        : null, // Disable if no coordinates
                    style: OutlinedButton.styleFrom(
                      padding: EdgeInsets.zero,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      side: BorderSide(
                          color: (bill.latitude != null && bill.longitude != null &&
                                  bill.latitude!.trim().isNotEmpty && bill.longitude!.trim().isNotEmpty)
                              ? Colors.grey.shade300
                              : Colors.grey.shade200,
                          width: 1.5),
                      foregroundColor: (bill.latitude != null && bill.longitude != null &&
                                       bill.latitude!.trim().isNotEmpty && bill.longitude!.trim().isNotEmpty)
                          ? Colors.black
                          : Colors.grey.shade400, // Grey out when disabled
                    ),
                    child: const Icon(Icons.near_me_outlined),
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
                            fontWeight: FontWeight.bold, fontSize: 14),
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

  Widget _buildInfoItem(String label, String value, bool isAmount) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            label.toUpperCase(),
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: Colors.grey[600],
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w800,
              color: isAmount ? const Color(0xFF1A237E) : Colors.black87,
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
          Icon(Icons.assignment_turned_in_outlined,
              size: 56, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text("No pending tasks",
              style: TextStyle(
                  fontSize: 18,
                  color: Colors.grey[800],
                  fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Text("You're all caught up!",
              style: TextStyle(fontSize: 14, color: Colors.grey[600])),
        ],
      ),
    );
  }

  Future<void> _openMapsNavigation(DeliveryBill bill) async {
    try {
      debugPrint('[DeliveryBook] _openMapsNavigation called for: ${bill.acname}');
      debugPrint('[DeliveryBook] Latitude: ${bill.latitude}, Longitude: ${bill.longitude}');

      // Check if coordinates are available
      if (bill.latitude == null || bill.longitude == null) {
        debugPrint('[DeliveryBook] Latitude or longitude is null');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Location coordinates not available'),
              backgroundColor: Colors.red,
            ),
          );
        }
        return;
      }

      final lat = bill.latitude!.trim();
      final lng = bill.longitude!.trim();

      debugPrint('[DeliveryBook] Trimmed Latitude: "$lat", Longitude: "$lng"');

      if (lat.isEmpty || lng.isEmpty) {
        debugPrint('[DeliveryBook] Latitude or longitude is empty after trim');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Location coordinates not available'),
              backgroundColor: Colors.red,
            ),
          );
        }
        return;
      }

      debugPrint('[DeliveryBook] Opening Google Maps with coordinates: $lat, $lng');

      // Try multiple URL schemes for Google Maps
      final urlSchemes = [
        'google.navigation:q=$lat,$lng&mode=d',  // Google Maps navigation
        'geo:$lat,$lng',                          // Geo URI
        'https://www.google.com/maps/@$lat,$lng,17z', // Web fallback
      ];

      for (final urlScheme in urlSchemes) {
        try {
          debugPrint('[DeliveryBook] Attempting to launch: $urlScheme');
          final uri = Uri.parse(urlScheme);
          debugPrint('[DeliveryBook] Parsed URI: ${uri.toString()}');
          await launchUrl(uri, mode: LaunchMode.externalApplication);
          debugPrint('[DeliveryBook] Successfully launched maps');
          return;
        } catch (e) {
          debugPrint('[DeliveryBook] Failed with scheme: $urlScheme, error: $e');
          continue;
        }
      }

      // All schemes failed
      debugPrint('[DeliveryBook] All URL schemes failed for coordinates');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Could not open Google Maps. Please check if it is installed.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      debugPrint('[DeliveryBook] Unexpected error opening maps: $e');
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
            'jan': 1, 'feb': 2, 'mar': 3, 'apr': 4, 'may': 5, 'jun': 6,
            'jul': 7, 'aug': 8, 'sep': 9, 'oct': 10, 'nov': 11, 'dec': 12,
            'january': 1, 'february': 2, 'march': 3, 'april': 4,
            'june': 6, 'july': 7, 'august': 8, 'september': 9,
            'october': 10, 'november': 11, 'december': 12
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
          latitude: bill.latitude != null ? double.tryParse(bill.latitude!) : null,
          longitude: bill.longitude != null ? double.tryParse(bill.longitude!) : null,
          paymentType: PaymentType.cash,
          mobile: bill.mobile == "NA" ? null : bill.mobile,
        ),
      ),
    )).then((result) {
      // When MarkDeliveredPage returns true (delivery was marked successfully),
      // refresh the delivery list
      if (result == true) {
        debugPrint('[DeliveryBook] Delivery marked successfully, refreshing list...');
        _loadBills(reset: true);
      }
    });
  }
}

// --- DATA MODEL (Unchanged) ---
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