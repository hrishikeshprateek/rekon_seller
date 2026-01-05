import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:dio/dio.dart';
import 'dart:convert';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

// --- YOUR EXISTING IMPORTS ---
import '../auth_service.dart';
import 'mark_delivered_page.dart';
import '../models/delivery_task_model.dart';

class DeliveryBookPage extends StatefulWidget {
  const DeliveryBookPage({super.key});

  @override
  State<DeliveryBookPage> createState() => _DeliveryBookPageState();
}

class _DeliveryBookPageState extends State<DeliveryBookPage> {
  static const int _pageSize = 10;

  final ScrollController _scrollController = ScrollController();
  final List<DeliveryBill> _bills = [];

  bool _isLoading = false;
  int _pageNo = 1;
  bool _hasMore = true;
  int? _totalCount;

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

  // --- LOGIC REMAINS EXACTLY THE SAME ---
  Future<void> _loadBills({bool reset = false}) async {
    if (reset) {
      if (mounted) setState(() { _isLoading = true; _bills.clear(); _pageNo = 1; _hasMore = true; });
    }

    try {
      final auth = Provider.of<AuthService>(context, listen: false);
      final dio = Dio(BaseOptions(
        baseUrl: AuthService.baseUrl,
        responseType: ResponseType.plain,
        connectTimeout: const Duration(seconds: 15),
      ));

      String mobile = (auth.currentUser?.mobileNumber ?? '').replaceAll(RegExp(r'[^0-9]'), '');
      if (mobile.length >= 10) {
        final last10 = mobile.substring(mobile.length - 10);
        mobile = '91$last10';
      } else if (mobile.length == 0) {
        mobile = '';
      } else {
        mobile = '91$mobile';
      }

      final payload = jsonEncode({
        'lLicNo': auth.currentUser?.licenseNumber ?? '',
        'lPageNo': _pageNo.toString(),
        'lSize': _pageSize.toString(),
        'luserid': mobile,
        'laid': 0,
        'lrtid': 0,
      });

      Map<String, String> headers = {
        'Content-Type': 'application/json',
        'Authorization': auth.getAuthHeader() ?? '',
        'package_name': 'com.reckon.reckonbiz',
      };

      Response response;
      try {
        response = await dio.post('/getdeleveredbillList', data: payload, options: Options(headers: headers));
      } on DioException catch (e) {
        if (e.response?.statusCode == 401) {
          final refreshResult = await auth.refreshAccessToken();
          if (refreshResult['success'] == true) {
            headers['Authorization'] = auth.getAuthHeader() ?? '';
            response = await dio.post('/getdeleveredbillList', data: payload, options: Options(headers: headers));
          } else {
            throw Exception('Session expired. Please login again.');
          }
        } else {
          rethrow;
        }
      }

      String cleanJson = response.data.toString().replaceAll(RegExp(r'[\x00-\x1F\x7F]'), '').trim();
      final data = jsonDecode(cleanJson);

      if (data is Map && (data['Status'] == false || data['Status'] == 'False')) {
        throw Exception(data['Message'] ?? 'Server failure');
      }

      if (data is Map && data['RCount'] != null) {
        _totalCount = int.tryParse(data['RCount'].toString());
      }

      List rawList = [];
      try {
        if (data is Map) {
          if (data['DeliverBills'] is List) {
            rawList = data['DeliverBills'] as List;
          } else if (data['DBILL'] is List) {
            rawList = data['DBILL'] as List;
          } else if (data['data'] is Map && data['data']['DeliverBills'] is List) {
            rawList = data['data']['DeliverBills'] as List;
          } else if (data['data'] is Map && data['data']['DBILL'] is List) {
            rawList = data['data']['DBILL'] as List;
          }
          else if (data['DeliverBills'] is String) {
            rawList = jsonDecode(data['DeliverBills']) as List;
          } else if (data['DBILL'] is String) {
            rawList = jsonDecode(data['DBILL']) as List;
          }
        } else if (data is List) {
          rawList = data;
        }
      } catch (e) {
        rawList = [];
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

      if (mounted) {
        setState(() {
          _bills.addAll(newBills);
          _hasMore = newBills.length >= _pageSize;
          if (_totalCount != null) {
            _hasMore = _bills.length < _totalCount!;
          }
          if (_hasMore) _pageNo++;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        if (_bills.isEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: ${e.toString()}")));
        }
      }
    }
  }

  // --- REDESIGNED BUILD METHOD ---
  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: scheme.surface,
      body: CustomScrollView(
        controller: _scrollController,
        slivers: [
          // Modern App Bar
          SliverAppBar(
            floating: true,
            snap: true,
            backgroundColor: scheme.surface,
            surfaceTintColor: Colors.transparent,
            title: Text(
              'Delivery Book',
              style: TextStyle(
                  fontWeight: FontWeight.w800,
                  color: scheme.onSurface,
                  letterSpacing: -0.5
              ),
            ),
            actions: [
              // Subtle Counter Pill
              Container(
                margin: const EdgeInsets.only(right: 16),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: scheme.surfaceContainerHigh,
                  borderRadius: BorderRadius.circular(100),
                ),
                child: Row(
                  children: [
                    Icon(Icons.inventory_2_outlined, size: 14, color: scheme.onSurfaceVariant),
                    const SizedBox(width: 6),
                    Text(
                      _totalCount != null ? '${_bills.length} / $_totalCount' : '${_bills.length}',
                      style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: scheme.onSurfaceVariant
                      ),
                    ),
                  ],
                ),
              )
            ],
          ),

          // Loading / Empty States
          if (_bills.isEmpty && !_isLoading)
            SliverFillRemaining(
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.inbox_outlined, size: 48, color: scheme.outline),
                    const SizedBox(height: 16),
                    Text("No deliveries found", style: TextStyle(color: scheme.outline)),
                  ],
                ),
              ),
            ),

          // List Items
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 40),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate(
                    (context, index) {
                  if (index == _bills.length) {
                    return const Center(
                        child: Padding(
                            padding: EdgeInsets.all(24),
                            child: CircularProgressIndicator(strokeWidth: 2)
                        )
                    );
                  }
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _ModernDeliveryCard(
                      bill: _bills[index],
                      onTap: () => _navigateToDetails(_bills[index]),
                    ),
                  );
                },
                childCount: _bills.length + (_hasMore ? 1 : 0),
              ),
            ),
          ),
        ],
      ),
    );
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
          id: bill.billno,
          type: TaskType.delivery,
          status: TaskStatus.pending,
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

// --- NEW MODERN UI WIDGETS ---

class _ModernDeliveryCard extends StatelessWidget {
  final DeliveryBill bill;
  final VoidCallback onTap;

  const _ModernDeliveryCard({required this.bill, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final currencyFormat = NumberFormat.simpleCurrency(locale: 'en_IN', decimalDigits: 0);

    return Container(
      decoration: BoxDecoration(
        color: scheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: scheme.outlineVariant.withOpacity(0.4), width: 1),
      ),
      clipBehavior: Clip.antiAlias,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          splashColor: scheme.primary.withOpacity(0.05),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 1. Header: Date Pill & Bill No
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _DatePill(dateStr: bill.billdate),
                    Text(
                      "#${bill.billno}",
                      style: TextStyle(
                        fontFamily: 'Monospace', // or standard if unavailable
                        fontSize: 12,
                        color: scheme.outline,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 12),

                // 2. Main Content: Name & Amount
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            bill.acname == "NA" ? "Unknown Party" : bill.acname,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w800,
                                color: scheme.onSurface,
                                height: 1.2
                            ),
                          ),
                          if (bill.remark != "NA")
                            Padding(
                              padding: const EdgeInsets.only(top: 4),
                              child: Text(
                                bill.remark,
                                style: textTheme.bodySmall?.copyWith(
                                    color: scheme.error,
                                    fontStyle: FontStyle.italic
                                ),
                                maxLines: 1,
                              ),
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      currencyFormat.format(bill.billamt),
                      style: textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w900,
                        color: scheme.primary,
                        letterSpacing: -0.5,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                // 3. Location Strip (Address / Area / Station)
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: scheme.surface, // Inner contrast
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    children: [
                      // Address
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(Icons.storefront_outlined, size: 14, color: scheme.onSurfaceVariant),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              bill.address == "NA" ? "No Address Provided" : bill.address,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(fontSize: 12, color: scheme.onSurfaceVariant),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      // Divider
                      Divider(height: 1, thickness: 0.5, color: scheme.outlineVariant),
                      const SizedBox(height: 8),
                      // Station & Area
                      Row(
                        children: [
                          Expanded(child: _IconText(Icons.map_outlined, bill.station, scheme)),
                          if(bill.area != "NA") ...[
                            Container(width: 1, height: 12, color: scheme.outlineVariant, margin: const EdgeInsets.symmetric(horizontal: 10)),
                            Expanded(child: _IconText(Icons.directions_bus_outlined, bill.area, scheme)),
                          ]
                        ],
                      )
                    ],
                  ),
                ),

                const SizedBox(height: 12),

                // 4. Footer: Stats pills & Action
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        _StatBadge(label: "Items", value: "${bill.item}", scheme: scheme),
                        const SizedBox(width: 8),
                        _StatBadge(label: "Qty", value: "${bill.qty}", scheme: scheme),
                      ],
                    ),

                    if (bill.mobile != "NA")
                      Material(
                        color: scheme.primaryContainer,
                        borderRadius: BorderRadius.circular(8),
                        child: InkWell(
                          onTap: () async {
                            final phoneNumber = bill.mobile.replaceAll(RegExp(r'[^0-9+]'), '');
                            final uri = Uri.parse('tel:$phoneNumber');
                            if (await canLaunchUrl(uri)) await launchUrl(uri);
                          },
                          borderRadius: BorderRadius.circular(8),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            child: Row(
                              children: [
                                Icon(Icons.call, size: 16, color: scheme.onPrimaryContainer),
                                const SizedBox(width: 6),
                                Text(
                                  "Call",
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: scheme.onPrimaryContainer,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                  ],
                )
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// Helper Widgets for the Card

class _DatePill extends StatelessWidget {
  final String dateStr;
  const _DatePill({required this.dateStr});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    // Quick parsing for display
    String displayDate = dateStr;
    try {
      if (dateStr != "NA") {
        final parts = dateStr.split('/');
        if (parts.length >= 2) {
          displayDate = "${parts[0]} ${parts[1].substring(0, 3)}";
        }
      }
    } catch (_) {}

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.calendar_today_outlined, size: 10, color: scheme.primary),
          const SizedBox(width: 4),
          Text(
            displayDate.toUpperCase(),
            style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                color: scheme.primary
            ),
          ),
        ],
      ),
    );
  }
}

class _IconText extends StatelessWidget {
  final IconData icon;
  final String text;
  final ColorScheme scheme;

  const _IconText(this.icon, this.text, this.scheme);

  @override
  Widget build(BuildContext context) {
    bool isNA = text == "NA" || text.isEmpty;
    return Row(
      children: [
        Icon(icon, size: 12, color: isNA ? scheme.outline : scheme.secondary),
        const SizedBox(width: 4),
        Expanded(
          child: Text(
            isNA ? "-" : text,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: isNA ? scheme.outline : scheme.onSurfaceVariant,
            ),
          ),
        ),
      ],
    );
  }
}

class _StatBadge extends StatelessWidget {
  final String label;
  final String value;
  final ColorScheme scheme;

  const _StatBadge({required this.label, required this.value, required this.scheme});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: scheme.outlineVariant.withOpacity(0.5)),
      ),
      child: RichText(
        text: TextSpan(
          style: TextStyle(fontSize: 11, color: scheme.onSurfaceVariant),
          children: [
            TextSpan(text: "$label: "),
            TextSpan(
                text: value,
                style: TextStyle(fontWeight: FontWeight.bold, color: scheme.onSurface)
            ),
          ],
        ),
      ),
    );
  }
}

// --- DATA MODEL (Kept exactly as provided) ---

class DeliveryBill {
  final String acname, billno, billdate, acno, mobile, station;
  final String address, remark, area, route, statusName, status;
  final double billamt;
  final int item, qty;

  DeliveryBill({
    required this.acname, required this.address, required this.mobile,
    required this.billno, required this.billdate, required this.billamt,
    required this.item, required this.qty, required this.station,
    required this.acno, required this.remark, required this.area,
    required this.route, required this.statusName, required this.status,
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
    );
  }
}