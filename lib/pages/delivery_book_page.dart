import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:dio/dio.dart';
import 'dart:convert';
import '../auth_service.dart';
import '../pages/mark_delivered_page.dart';
import '../login_screen.dart';

import '../models/delivery_task_model.dart';

class DeliveryBookPage extends StatefulWidget {
  const DeliveryBookPage({super.key});

  @override
  State<DeliveryBookPage> createState() => _DeliveryBookPageState();
}

class _DeliveryBookPageState extends State<DeliveryBookPage> {
  final List<DeliveryBill> _bills = [];
  bool _isLoading = false;
  String? _errorMessage;
  final ScrollController _scrollController = ScrollController();

  // Pagination variables
  int _pageNo = 1;
  final int _pageSize = 20;
  bool _hasMore = true;
  bool _isLoadingMore = false;

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
        !_isLoading &&
        !_isLoadingMore &&
        _hasMore) {
      _loadBills(reset: false);
    }
  }

  // Helper to remove null bytes (\x00) and control characters from strings
  String cleanString(String input) {
    return input.replaceAll(RegExp(r'[\x00-\x1F\x7F]'), '').trim();
  }

  Future<void> _loadBills({bool reset = false}) async {
    if (reset) {
      _pageNo = 1;
      _hasMore = true;
      setState(() {
        _isLoading = true;
        _errorMessage = null;
        _bills.clear();
      });
    } else {
      setState(() {
        _isLoadingMore = true;
      });
    }

    try {
      final auth = Provider.of<AuthService>(context, listen: false);
      // Ensure any stored tokens are loaded before making the request
      try {
        await auth.tryAutoLogin();
      } catch (_) {}

      final dio = Dio(BaseOptions(
        baseUrl: AuthService.baseUrl,
        connectTimeout: const Duration(seconds: 30),
        // Request raw string to handle server-side malformed JSON manually
        responseType: ResponseType.plain,
      ));

      // 1. Prepare & Sanitize Data
      var rawMobile = auth.currentUser?.mobileNumber ?? '';
      var rawLic = auth.currentUser?.licenseNumber ?? '';

      // Remove non-digits from mobile
      String mobile = rawMobile.replaceAll(RegExp(r'[^0-9]'), '');

      // Ensure 10-digit mobile has 91 prefix (Matching your CURL example)
      if (mobile.length == 10) mobile = '91$mobile';

      // Sanitize Strings
      final cleanMobile = cleanString(mobile);
      final cleanLic = cleanString(rawLic);

      // 2. Prepare Payload (Matches CURL exactly)
      final payload = {
        'lLicNo': cleanLic,
        'lPageNo': _pageNo,
        'lSize': _pageSize,
        'luserid': cleanMobile,
        'laid': 0,
        'lrtid': 0,
      };

      debugPrint('Payload Sending: $payload');

      // 3. Define Request with CORRECT PATH
      Future<Response> _performRequest() {
        // Build headers
        final headers = <String, String>{
          'Content-Type': 'application/json',
          'package_name': auth.packageNameHeader,
        };
        final authHeader = auth.getAuthHeader() ?? (auth.accessToken != null ? 'Bearer ${auth.accessToken}' : null);
        if (authHeader != null) headers['Authorization'] = authHeader;

        // *** FIX: Updated path based on your working CURL command ***
        return dio.post(
          '/reckon-biz/api/reckonpwsorder/getdeleveredbillList',
          data: payload,
          options: Options(
            headers: headers,
            validateStatus: (status) => true,
          ),
        );
      }

      Response response = await _performRequest();

      // If unauthorized, try refresh -> MPIN -> logout
      if (response.statusCode == 401) {
        debugPrint('Received 401 response — trying refresh flow');
        bool retried = false;
        try {
          final refreshResult = await auth.refreshAccessToken();
          if (refreshResult['success'] == true) {
            debugPrint('refreshAccessToken succeeded, retrying request');
            response = await _performRequest();
            retried = true;
          } else {
            debugPrint('refreshAccessToken returned failure: ${refreshResult['message']}');
          }
        } catch (refreshErr) {
          debugPrint('refreshAccessToken threw: $refreshErr');
        }

        if (!retried) {
          try {
            final mpinOk = await auth.promptForMpinAndRefresh(mobile: auth.currentUser?.mobileNumber ?? '');
            if (mpinOk == true) {
              debugPrint('MPIN-based refresh succeeded, retrying request');
              response = await _performRequest();
              retried = true;
            } else {
              debugPrint('MPIN-based refresh cancelled/not successful');
            }
          } catch (mpinErr) {
            debugPrint('promptForMpinAndRefresh threw: $mpinErr');
          }
        }

        if (!retried) {
          // Nothing worked: force logout and prompt login
          debugPrint('401 recovery failed — logging out and redirecting to login');
          await auth.logout();
          if (mounted) {
            Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => const LoginScreen()));
            return;
          }
        }
      }

      // 4. Handle Response
      String responseBody = response.data.toString();

      // Fix server response if it contains null bytes
      responseBody = responseBody.replaceAll(RegExp(r'[\x00-\x1F]'), '');

      final data = jsonDecode(responseBody);

      // Check logical status
      // Note: Success JSON does not always contain "Status": true, it just returns "DBILL".
      // We only check if it explicitly failed.
      if (data is Map && (data['Status'] == false || data['Status'] == 'False')) {
        throw Exception(data['Message'] ?? 'Server returned Status: False');
      }

      final List<dynamic> list = data['DBILL'] ?? [];
      final fetchedBills = list.map((e) => DeliveryBill.fromJson(e)).toList();

      setState(() {
        if (reset) {
          _bills.clear();
        }
        _bills.addAll(fetchedBills);

        // Pagination logic: If we got fewer items than requested, we are at the end
        if (fetchedBills.length < _pageSize) {
          _hasMore = false;
        } else {
          _pageNo++;
        }
      });

    } catch (e) {
      debugPrint('Error loading bills: $e');
      if (mounted) {
        setState(() => _errorMessage = e.toString());
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _isLoadingMore = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Pending Deliveries')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
          ? Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text(_errorMessage!, textAlign: TextAlign.center, style: const TextStyle(color: Colors.red)),
            ),
            ElevatedButton(
              onPressed: () => _loadBills(reset: true),
              child: const Text('Retry'),
            )
          ],
        ),
      )
          : _bills.isEmpty
          ? const Center(child: Text('No pending deliveries'))
          : RefreshIndicator(
        onRefresh: () => _loadBills(reset: true),
        child: ListView.builder(
          controller: _scrollController,
          padding: const EdgeInsets.all(12),
          itemCount: _bills.length + (_isLoadingMore ? 1 : 0),
          itemBuilder: (context, index) {
            if (index == _bills.length) {
              return const Center(child: Padding(padding: EdgeInsets.all(8.0), child: CircularProgressIndicator()));
            }

            final bill = _bills[index];
            return Card(
              margin: const EdgeInsets.only(bottom: 12),
              child: ListTile(
                title: Text(bill.acname, style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 4),
                    Text(bill.address),
                    const SizedBox(height: 4),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Date: ${bill.billdate}'),
                        Text('Amt: ₹${bill.billamt}', style: TextStyle(color: Theme.of(context).primaryColor, fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ],
                ),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {
                  // Navigate to details
                  Navigator.of(context).push(MaterialPageRoute(
                    builder: (context) => MarkDeliveredPage(
                      task: DeliveryTask(
                        id: bill.billno,
                        type: TaskType.delivery,
                        status: TaskStatus.pending,
                        partyName: bill.acname,
                        partyId: bill.acno,
                        station: bill.station,
                        area: '',
                        latitude: null,
                        longitude: null,
                        billNo: bill.billno,
                        billDate: _parseDate(bill.billdate),
                        paymentType: null,
                        billAmount: bill.billamt,
                        itemCount: bill.item,
                        distanceKm: null,
                      ),
                    ),
                  )).then((value) {
                    if (value == true) _loadBills(reset: true);
                  });
                },
              ),
            );
          },
        ),
      ),
    );
  }

  DateTime? _parseDate(String dateStr) {
    try {
      final parts = dateStr.split('/');
      if (parts.length == 3) {
        final day = int.parse(parts[0]);
        final monthStr = parts[1];
        final year = int.parse(parts[2]);

        final months = { 'Jan':1, 'Feb':2, 'Mar':3, 'Apr':4, 'May':5, 'Jun':6, 'Jul':7, 'Aug':8, 'Sep':9, 'Oct':10, 'Nov':11, 'Dec':12 };
        final month = months[monthStr] ?? 1;

        return DateTime(year, month, day);
      }
    } catch (_) {}
    return null;
  }
}

class DeliveryBill {
  final String acname;
  final String address;
  final String mobile;
  final String billno;
  final String billdate;
  final double billamt;
  final int qty;
  final int item;
  final String station;
  final String acno;

  DeliveryBill({
    required this.acname,
    required this.address,
    required this.mobile,
    required this.billno,
    required this.billdate,
    required this.billamt,
    required this.qty,
    required this.item,
    required this.station,
    required this.acno,
  });

  factory DeliveryBill.fromJson(Map<String, dynamic> json) {
    String buildAddress() {
      final parts = [
        json['address1'],
        json['address2'],
        json['address3']
      ].where((e) => e != null && e.toString().trim().isNotEmpty).join(', ');
      return parts.isEmpty ? 'No Address' : parts;
    }

    return DeliveryBill(
      acname: json['acname']?.toString() ?? 'Unknown Party',
      address: buildAddress(),
      mobile: json['mobile']?.toString() ?? '',
      billno: json['billno']?.toString() ?? '',
      billdate: json['billdate']?.toString() ?? '',
      billamt: double.tryParse(json['billamt']?.toString() ?? '0') ?? 0.0,
      qty: int.tryParse(json['qty']?.toString() ?? '0') ?? 0,
      item: int.tryParse(json['item']?.toString() ?? '0') ?? 0,
      station: json['station']?.toString() ?? '',
      acno: json['acno']?.toString() ?? '',
    );
  }
}