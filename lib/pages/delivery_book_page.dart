import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:dio/dio.dart';
import 'dart:convert';
import 'package:intl/intl.dart';

// --- YOUR EXISTING IMPORTS ---
// Adjust these paths if necessary
import '../auth_service.dart';
import 'mark_delivered_page.dart';
import '../models/delivery_task_model.dart';

class DeliveryBookPage extends StatefulWidget {
  const DeliveryBookPage({super.key});

  @override
  State<DeliveryBookPage> createState() => _DeliveryBookPageState();
}

class _DeliveryBookPageState extends State<DeliveryBookPage> {
  final ScrollController _scrollController = ScrollController();
  final List<DeliveryBill> _bills = [];

  bool _isLoading = false;
  int _pageNo = 1;
  bool _hasMore = true;

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
      if (mobile.length == 10) mobile = '91$mobile';

      final payload = jsonEncode({
        'lLicNo': auth.currentUser?.licenseNumber ?? '',
        'lPageNo': _pageNo.toString(),
        'lSize': "10",
        'luserid': mobile,
        'laid': 0,
        'lrtid': 0,
      });

      final response = await dio.post('/getdeleveredbillList', data: payload,
          options: Options(headers: {
            'Content-Type': 'application/json',
            'Authorization': auth.getAuthHeader() ?? '',
            'package_name': 'com.reckon.reckonbiz',
          }));

      String cleanJson = response.data.toString().replaceAll(RegExp(r'[\x00-\x1F\x7F]'), '').trim();
      final data = jsonDecode(cleanJson);

      if (data is Map && (data['Status'] == false || data['Status'] == 'False')) {
        throw Exception(data['Message'] ?? 'Server failure');
      }

      final List rawList = (data is Map && data['DBILL'] is List) ? data['DBILL'] : [];
      final newBills = rawList.map((e) => DeliveryBill.fromJson(e)).toList();

      if (mounted) {
        setState(() {
          _bills.addAll(newBills);
          _hasMore = newBills.length >= 10;
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

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: scheme.surface,
      appBar: AppBar(
        scrolledUnderElevation: 0,
        backgroundColor: scheme.surface,
        title: Text(
          'Deliveries',
          style: TextStyle(fontWeight: FontWeight.bold, color: scheme.onSurface),
        ),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 16),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: scheme.primaryContainer,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              '${_bills.length}',
              style: TextStyle(color: scheme.onPrimaryContainer, fontWeight: FontWeight.bold),
            ),
          )
        ],
      ),
      body: _bills.isEmpty && !_isLoading
          ? Center(child: Text("No data available", style: TextStyle(color: scheme.onSurfaceVariant)))
          : ListView.separated(
        controller: _scrollController,
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 40),
        itemCount: _bills.length + (_hasMore ? 1 : 0),
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          if (index == _bills.length) {
            return const Center(child: Padding(padding: EdgeInsets.all(16), child: CircularProgressIndicator()));
          }
          return _RichDetailCard(
            bill: _bills[index],
            onTap: () => _navigateToDetails(_bills[index]),
          );
        },
      ),
    );
  }

  void _navigateToDetails(DeliveryBill bill) {
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
          billDate: DateTime.now(), // Uses current time as API date format varies
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

// --- UI WIDGETS ---

class _RichDetailCard extends StatelessWidget {
  final DeliveryBill bill;
  final VoidCallback onTap;

  const _RichDetailCard({required this.bill, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final currencyFormat = NumberFormat.simpleCurrency(locale: 'en_IN', decimalDigits: 0);

    // Safe Date Parsing
    String day = "NA";
    String month = "";
    if (bill.billdate != "NA") {
      try {
        final parts = bill.billdate.split('/');
        if (parts.length >= 2) {
          day = parts[0];
          month = parts[1].toUpperCase().substring(0, 3);
        }
      } catch (_) {}
    }

    return Card(
      elevation: 0,
      color: scheme.surfaceContainerLow,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        side: BorderSide(color: scheme.outlineVariant.withAlpha((0.5 * 255).round())),
        borderRadius: BorderRadius.circular(16),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. TOP SECTION: Date, Name, Amount
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Date Box
                  Container(
                    width: 48,
                    height: 50,
                    decoration: BoxDecoration(
                      color: scheme.surface,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: scheme.outlineVariant.withAlpha((0.4 * 255).round())),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(day, style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                        if (month.isNotEmpty)
                          Text(month, style: textTheme.labelSmall?.copyWith(fontSize: 10, color: scheme.primary)),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Name & Remark
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          bill.acname == "NA" ? "Unknown Party" : bill.acname,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                            color: bill.acname == "NA" ? scheme.outline : scheme.onSurface,
                          ),
                        ),
                        if (bill.remark != "NA")
                          Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Text(
                              "Note: ${bill.remark}",
                              style: textTheme.bodySmall?.copyWith(color: scheme.error, fontStyle: FontStyle.italic),
                              maxLines: 1,
                            ),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Amount
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

              // 2. MIDDLE SECTION: Address & Location
              _InfoRow(icon: Icons.location_on_outlined, text: bill.address, scheme: scheme),
              const SizedBox(height: 8),

              Row(
                children: [
                  Expanded(child: _InfoRow(icon: Icons.map, text: bill.station, scheme: scheme)),
                  if (bill.area != "NA") ...[
                    const SizedBox(width: 8),
                    Expanded(child: _InfoRow(icon: Icons.directions_bus, text: bill.area, scheme: scheme)),
                  ],
                ],
              ),

              const SizedBox(height: 16),
              Divider(height: 1, color: scheme.outlineVariant.withAlpha((0.5 * 255).round())),
              const SizedBox(height: 12),

              // 3. BOTTOM SECTION: Statistics Grid
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _StatItem(label: "Bill No", value: bill.billno, scheme: scheme),
                  _StatItem(label: "Items", value: "${bill.item}", scheme: scheme),
                  _StatItem(label: "Qty", value: "${bill.qty}", scheme: scheme),
                  if (bill.mobile != "NA")
                    _StatItem(label: "Mobile", value: bill.mobile.length > 10 ? bill.mobile.substring(0, 10) : bill.mobile, scheme: scheme, isHighlight: true),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String text;
  final ColorScheme scheme;

  const _InfoRow({required this.icon, required this.text, required this.scheme});

  @override
  Widget build(BuildContext context) {
    bool isNA = text == "NA";
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 14, color: isNA ? scheme.outline.withAlpha((0.5 * 255).round()) : scheme.onSurfaceVariant),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            text,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 12,
              color: isNA ? scheme.outline.withAlpha((0.5 * 255).round()) : scheme.onSurfaceVariant,
              fontStyle: isNA ? FontStyle.italic : FontStyle.normal,
            ),
          ),
        ),
      ],
    );
  }
}

class _StatItem extends StatelessWidget {
  final String label;
  final String value;
  final ColorScheme scheme;
  final bool isHighlight;

  const _StatItem({required this.label, required this.value, required this.scheme, this.isHighlight = false});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(fontSize: 10, color: scheme.outline)),
        const SizedBox(height: 2),
        Text(
          value,
          style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: isHighlight ? scheme.primary : scheme.onSurface
          ),
        ),
      ],
    );
  }
}

// --- ROBUST DATA MODEL ---

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
    // Helper to safely extract String or return "NA"
    String str(String key) {
      final val = json[key];
      if (val == null) return 'NA';
      final s = val.toString().trim();
      if (s.toLowerCase() == 'null' || s.isEmpty) return 'NA';
      return s;
    }

    // Helper for Double
    double dbl(String key) {
      if (json[key] == null) return 0.0;
      return double.tryParse(json[key].toString()) ?? 0.0;
    }

    // Helper for Int
    int integer(String key) {
      if (json[key] == null) return 0;
      return int.tryParse(json[key].toString()) ?? 0;
    }

    // Address Parsing: Joins non-null parts
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