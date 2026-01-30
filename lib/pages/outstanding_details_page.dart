import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:dio/dio.dart';
import 'dart:convert';
import '../auth_service.dart';
import '../receipt_entry.dart';
import 'package:share_plus/share_plus.dart';
import 'dart:io';
import 'dart:typed_data';
import 'package:path_provider/path_provider.dart';
import 'package:cross_file/cross_file.dart';
import 'package:flutter/services.dart';

class OutstandingDetailsPage extends StatefulWidget {
  final String accountNo;
  final String accountName;

  const OutstandingDetailsPage({
    super.key,
    required this.accountNo,
    required this.accountName,
  });

  @override
  State<OutstandingDetailsPage> createState() => _OutstandingDetailsPageState();
}

class _OutstandingDetailsPageState extends State<OutstandingDetailsPage> {
  final ScrollController _scrollController = ScrollController();

  OutstandingData? _outstandingData;
  bool _isLoading = false;
  String? _errorMessage;

  final int _pageSize = 30;
  int _currentPage = 1;
  bool _hasMore = true;

  final Set<int> _selectedIndexes = <int>{};
  bool _selectionMode = true;

  @override
  void initState() {
    super.initState();
    _loadOutstandingDetails(reset: true);
    // Attach scroll listener for pagination
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    // Remove listener then dispose
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  double get _selectedTotal {
    final data = _outstandingData;
    if (data == null) return 0;

    double sum = 0;
    for (final idx in _selectedIndexes) {
      if (idx >= 0 && idx < data.items.length) {
        sum += data.items[idx].amount;
      }
    }
    return sum;
  }

  void _toggleSelection(int listIndex) {
    setState(() {
      if (_selectedIndexes.contains(listIndex)) {
        _selectedIndexes.remove(listIndex);
      } else {
        _selectedIndexes.add(listIndex);
      }
    });
  }

  void _goToReceiptEntry() {
    if (_selectedIndexes.isEmpty) return;

    final data = _outstandingData;
    if (data == null) return;

    final selectedBills = _selectedIndexes
        .where((i) => i >= 0 && i < data.items.length)
        .map((i) {
          final it = data.items[i];
          return {
            'entryNo': it.entryNo,
            'date': it.date,
            'amount': it.amount,
            'keyEntryNo': it.keyEntryNo,
            'dueDate': it.dueDate,
            'trantype': it.trantype,
          };
        })
        .toList();

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => CreateReceiptScreen(
          accountNo: widget.accountNo,
          accountName: widget.accountName,
          selectedBills: selectedBills,
        ),
      ),
    );
  }

  // Called when the list is scrolled. Triggers loading next page when near bottom.
  void _onScroll() {
    try {
      if (!_scrollController.hasClients) return;
      final threshold = 200.0; // px before the end to trigger load
      final maxScroll = _scrollController.position.maxScrollExtent;
      final current = _scrollController.position.pixels;
      // If content doesn't overflow, don't trigger pagination
      if (maxScroll <= 0) return;
      if (current >= (maxScroll - threshold)) {
        // near the bottom
        if (!_isLoading && _hasMore) {
          _loadOutstandingDetails(reset: false);
        }
      }
    } catch (_) {
      // ignore any scroll errors
    }
  }

  Future<void> _loadOutstandingDetails({bool reset = false}) async {
    // Prevent concurrent loads; allow reset to force reload.
    if (!reset && (_isLoading || !_hasMore)) {
      print('[Outstanding] Skipping load: isLoading=$_isLoading, hasMore=$_hasMore, page=$_currentPage');
      return;
    }

    if (reset) {
      if (mounted) {
        setState(() {
          _isLoading = true;
          _errorMessage = null;
          _currentPage = 1;
          _hasMore = true;
          _outstandingData = null;
          _selectedIndexes.clear();
          _selectionMode = true;
        });
      }
    } else {
      if (mounted) setState(() => _isLoading = true);
    }

    try {
      final auth = Provider.of<AuthService>(context, listen: false);
      final dio = auth.getDioClient();

      final payload = jsonEncode({
        'lLicNo': auth.currentUser?.licenseNumber ?? '',
        'lAcNo': widget.accountNo,
        'lPageNo': _currentPage,
        'lSize': _pageSize,
        'lExecuteTotalRows': 1,
        'lSharePdf': 0,
        'firm_code': '',
        'lSearchFieldValue': '',
        'lFromDate': '',
        'lTillDate': '',
      });

      print('[Outstanding] Requesting page=$_currentPage size=$_pageSize for ac=${widget.accountNo}');
      print('[Outstanding] Payload: $payload');

      final response = await dio.post(
        '/GetOutstandingDetails',
        data: payload,
        options: Options(
          headers: {
            'Content-Type': 'application/json',
            'Authorization': auth.getAuthHeader() ?? '',
            'package_name': 'com.reckon.reckonbiz',
          },
        ),
      );

      String cleanJson = response.data
          .toString()
          .replaceAll(RegExp(r'[\x00-\x1F\x7F]'), '')
          .trim();
      final data = jsonDecode(cleanJson) as Map<String, dynamic>;

      final newData = OutstandingData.fromJson(data);

      if (reset) {
        _outstandingData = newData;
      } else {
        _outstandingData?.items.addAll(newData.items);
      }

      // If returned items count matches page size, assume more pages exist
      _hasMore = newData.items.length >= _pageSize;
      if (_hasMore) _currentPage++;

      print('[Outstanding] Received ${newData.items.length} items; hasMore=$_hasMore; nextPage=$_currentPage; totalLoaded=${_outstandingData?.items.length ?? newData.items.length}');

      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = null;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = e.toString();
        });
      }
    }
  }

  Future<void> _fetchAndShowDetails(OutstandingItem item) async {
    // Show loading indicator
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => const SizedBox(
        height: 150,
        child: Center(child: CircularProgressIndicator()),
      ),
    );

    try {
      final auth = Provider.of<AuthService>(context, listen: false);
      final dio = auth.getDioClient();

      final payload = {
        "lLicNo": auth.currentUser?.licenseNumber ?? "",
        "lKeyEntryNo": item.keyEntryNo,
        "lIsEntryRecord": "1",
        "lKeyEntrySrNo": null,
      };

      final response = await dio.post(
        '/reckonpwsorder/GetTranDetail',
        data: payload,
        options: Options(
          headers: {
            'Content-Type': 'application/json',
            'package_name': 'com.reckon.reckonbiz',
            'Authorization': auth.getAuthHeader(),
          },
        ),
      );

      if (mounted) Navigator.pop(context); // Close loading sheet

      // Parse Response
      String cleanJson = response.data
          .toString()
          .replaceAll(RegExp(r'[\x00-\x1F\x7F]'), '')
          .trim();
      final jsonResponse = jsonDecode(cleanJson);

      if (jsonResponse['success'] == true && jsonResponse['data'] != null) {
        if (mounted) _showDataSheet(jsonResponse['data']);
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                jsonResponse['message'] ?? 'Failed to fetch details',
              ),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context); // Close loading
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("Error fetching details: $e")));
      }
    }
  }

  void _showDataSheet(Map<String, dynamic> data) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        minChildSize: 0.4,
        maxChildSize: 0.9,
        expand: false,
        builder: (_, controller) => Padding(
          padding: const EdgeInsets.all(24.0),
          child: ListView(
            controller: controller,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              const Center(
                child: Text(
                  "Transaction Details",
                  style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18),
                ),
              ),
              const SizedBox(height: 20),
              const Divider(),
              _detailRow("Date", data['Date']),
              _detailRow("Voucher No", data['Number']),
              _detailRow("Type", data['TranType']),
              _detailRow("Party Name", data['NAME']),
              _detailRow("Address", data['Address1']),
              const Divider(),
              _detailRow(
                "Item Amount",
                data['ITEMAMT']?.toString(),
                isAmount: true,
              ),
              _detailRow(
                "Tax Amount",
                data['TAXAMT']?.toString(),
                isAmount: true,
              ),
              _detailRow(
                "Bill Amount",
                data['BillAmt']?.toString(),
                isAmount: true,
                isBold: true,
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: FilledButton(
                  onPressed: () => Navigator.pop(ctx),
                  style: FilledButton.styleFrom(
                    backgroundColor: Colors.blueGrey.shade800,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text("Close"),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _detailRow(
    String label,
    String? value, {
    bool isAmount = false,
    bool isBold = false,
  }) {
    if (value == null || value.isEmpty || value == "0.0" || value == "0")
      return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: Colors.grey,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(width: 16),
          Flexible(
            child: Text(
              isAmount ? "₹$value" : value,
              textAlign: TextAlign.right,
              style: TextStyle(
                fontWeight: isBold ? FontWeight.w800 : FontWeight.w600,
                fontSize: isBold ? 16 : 14,
                color: isAmount ? Colors.black87 : Colors.black87,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _downloadAndSharePdf({bool preferWhatsapp = false}) async {
    final auth = Provider.of<AuthService>(context, listen: false);
    final dio = auth.getDioClient();

    String firmCode = '';
    try {
      final stores = auth.currentUser?.stores ?? [];
      final primary = stores.firstWhere(
        (s) => s.primary,
        orElse: () => stores.isNotEmpty ? stores.first : (throw 'no_store'),
      );
      firmCode = primary.firmCode;
    } catch (_) {
      firmCode = '';
    }

    final payload = {
      'lLicNo': auth.currentUser?.licenseNumber ?? '',
      'lAcNo': widget.accountNo,
      'lPageNo': 1,
      'lSize': 30,
      'lExecuteTotalRows': 1,
      'lSharePdf': 1,
      'firm_code': firmCode,
      'lSearchFieldValue': '',
      'lFromDate': '',
      'lTillDate': '',
    };

    try {
      final response = await dio.post(
        '/GetOutstandingDetails',
        data: payload,
        options: Options(
          responseType: ResponseType.bytes,
          headers: {
            'Content-Type': 'application/json',
            'package_name': auth.packageNameHeader,
            if (auth.getAuthHeader() != null)
              'Authorization': auth.getAuthHeader(),
          },
        ),
      );

      Uint8List? bytes;
      if (response.data is Uint8List) {
        bytes = response.data as Uint8List;
      } else if (response.data is List<int>) {
        bytes = Uint8List.fromList(List<int>.from(response.data));
      } else {
        // Fallback for wrapped responses
        try {
          final raw = response.data;
          if (raw is String) {
            try {
              bytes = base64Decode(raw);
            } catch (_) {}
          } else if (raw is Map) {
            if (raw['Pdf'] is String)
              bytes = base64Decode(raw['Pdf']);
            else if (raw['Message'] is String)
              bytes = base64Decode(raw['Message']);
          }
        } catch (_) {}
      }

      if (bytes == null || bytes.isEmpty)
        throw 'No PDF data received from server.';

      final dir = await getTemporaryDirectory();
      final file = File(
        '${dir.path}/outstanding_${widget.accountNo}_${DateTime.now().millisecondsSinceEpoch}.pdf',
      );
      await file.writeAsBytes(bytes, flush: true);

      final xfile = XFile(file.path, mimeType: 'application/pdf');

      await Share.shareXFiles([xfile], text: widget.accountName);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not fetch/share PDF: $e')),
        );
      }
    }
  }

  void _showShareOptions() {
    if (_outstandingData == null) return;
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),
            ListTile(
              leading: const Icon(Icons.chat, color: Colors.green),
              title: const Text('Share via WhatsApp'),
              onTap: () {
                Navigator.pop(ctx);
                _downloadAndSharePdf(preferWhatsapp: true);
              },
            ),
            ListTile(
              leading: const Icon(Icons.share, color: Colors.blue),
              title: const Text('Share PDF'),
              onTap: () {
                Navigator.pop(ctx);
                _downloadAndSharePdf(preferWhatsapp: false);
              },
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  // --- UI IMPLEMENTATION ---

  @override
  Widget build(BuildContext context) {
    final primaryColor = Colors.blueGrey.shade800;
    final scaffoldBg = Colors.grey.shade100;
    final selectedTotal = _selectedTotal;
    final currencyFormat = NumberFormat.simpleCurrency(
      locale: 'en_IN',
      decimalDigits: 2,
    );

    return Scaffold(
      backgroundColor: scaffoldBg,
      appBar: AppBar(
        backgroundColor: primaryColor,
        elevation: 0,
        centerTitle: false,
        title: const Text(
          "Outstanding Bill wise",
          style: TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.5,
          ),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            onPressed: _outstandingData != null ? _showShareOptions : null,
            icon: const Icon(Icons.share),
          ),
          IconButton(
            onPressed: () => _loadOutstandingDetails(reset: true),
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
      body: Stack(
        children: [
          Padding(
            padding: EdgeInsets.only(bottom: _selectedIndexes.isEmpty ? 0 : 72),
            child: _buildBody(),
          ),
          if (_selectedIndexes.isNotEmpty)
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: SafeArea(
                top: false,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.08),
                        blurRadius: 12,
                        offset: const Offset(0, -4),
                      ),
                    ],
                    border: Border(
                      top: BorderSide(color: Colors.grey.shade200),
                    ),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${_selectedIndexes.length} selected',
                              style: const TextStyle(
                                fontSize: 11,
                                color: Colors.black54,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Total: ${currencyFormat.format(selectedTotal)}',
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 10),
                      SizedBox(
                        height: 42,
                        child: FilledButton.icon(
                          onPressed: _goToReceiptEntry,
                          icon: const Icon(
                            Icons.receipt_long_outlined,
                            size: 18,
                          ),
                          label: const Text('Receipt Entry'),
                          style: FilledButton.styleFrom(
                            backgroundColor: primaryColor,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                            textStyle: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildBody() {
    if (_errorMessage != null && _outstandingData == null)
      return Center(
        child: Text(_errorMessage!, style: const TextStyle(fontSize: 12)),
      );
    if (_isLoading && _outstandingData == null)
      return const Center(child: CircularProgressIndicator(strokeWidth: 2));
    if (_outstandingData == null)
      return const Center(child: Text("No records found"));

    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.only(bottom: 24),
      itemCount: _outstandingData!.items.length + 2,
      itemBuilder: (context, index) {
        if (index == 0) return _LedgerHeader(data: _outstandingData!);
        if (index == _outstandingData!.items.length + 1) {
          if (_isLoading) {
            return const Center(child: Padding(padding: EdgeInsets.all(24), child: CircularProgressIndicator(strokeWidth: 2)));
          }
          // when not loading: if more pages expected, render a small placeholder so scrolling can trigger load
          if (_hasMore) {
            return const SizedBox(height: 48);
          }
          // no more pages
          return const Padding(
            padding: EdgeInsets.all(16.0),
            child: Center(child: Text("--- END OF REPORT ---", style: TextStyle(color: Colors.grey, fontSize: 10, letterSpacing: 1))),
          );
        }
        final itemIndex = index - 1;
        final item = _outstandingData!.items[itemIndex];
        final isSelected = _selectedIndexes.contains(itemIndex);

        return _LedgerItem(
          item: item,
          isSelected: isSelected,
          selectionMode: _selectionMode,
          onToggleSelected: () => _toggleSelection(itemIndex),
          // Card tap intentionally disabled: no action should be performed on single tap
          onItemTap: () {},
          onLongPress: () => _toggleSelection(itemIndex),
        );
      },
    );
  }
}

class _LedgerHeader extends StatelessWidget {
  final OutstandingData data;

  const _LedgerHeader({required this.data});

  @override
  Widget build(BuildContext context) {
    final currencyFormat = NumberFormat.simpleCurrency(
      locale: 'en_IN',
      decimalDigits: 2,
    );
    return Container(
      color: Colors.white,
      margin: const EdgeInsets.only(bottom: 8),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
            decoration: BoxDecoration(color: Colors.blueGrey.shade800),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.business, color: Colors.white70, size: 18),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        data.accName,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          height: 1.2,
                        ),
                      ),
                    ),
                  ],
                ),
                if (data.accAddress.isNotEmpty &&
                    data.accAddress != 'Address not available') ...[
                  const SizedBox(height: 8),
                  Padding(
                    padding: const EdgeInsets.only(left: 30),
                    child: Text(
                      data.accAddress,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.white70,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "TOTAL OUTSTANDING",
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey,
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        currencyFormat.format(data.outstandingAmount),
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.blueGrey.shade900,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(width: 1, height: 30, color: Colors.grey.shade300),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "INVOICES",
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey,
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        "${data.totalItems}",
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1, thickness: 1),
        ],
      ),
    );
  }
}

class _LedgerItem extends StatelessWidget {
  final OutstandingItem item;
  final bool selectionMode;
  final bool isSelected;
  final VoidCallback onToggleSelected;
  final VoidCallback onItemTap;
  final VoidCallback? onLongPress;

  const _LedgerItem({
    required this.item,
    required this.selectionMode,
    required this.isSelected,
    required this.onToggleSelected,
    required this.onItemTap,
    this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    final currencyFormat = NumberFormat.simpleCurrency(
      locale: 'en_IN',
      decimalDigits: 2,
    );
    final isNegative = item.amount < 0;
    final isOverdue = item.overDue.isNotEmpty && item.overDue != "0";
    const labelStyle = TextStyle(fontSize: 11, color: Color(0xFF757575));
    const valueStyle = TextStyle(
      fontSize: 12,
      color: Color(0xFF212121),
      fontWeight: FontWeight.w500,
    );
    // Use a neutral strip color (no green/red) per request
    final Color stripColor = Colors.grey.shade300;

    return InkWell(
      onTap: onItemTap, // Tap opens details
      onLongPress: onLongPress, // Long press toggles selection
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(2),
          border: isSelected
              ? Border.all(
                  color: Theme.of(context).colorScheme.primary,
                  width: 1.2,
                )
              : null,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 2,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        child: Stack(
          children: [
            IntrinsicHeight(
              child: Row(
                children: [
                  Container(width: 4, color: stripColor),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Text(
                                  item.date,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13,
                                    color: Colors.black87,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              const SizedBox(width: 10),
                              Padding(
                                padding: EdgeInsets.only(
                                  right: selectionMode ? 34 : 0,
                                ),
                                child: Text(
                                  currencyFormat.format(item.amount),
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                    color: Colors.black87,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          const Divider(height: 1, thickness: 0.5),
                          const SizedBox(height: 8),
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                flex: 4,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    _RichInfo(
                                      label: "",
                                      value: item.entryNo,
                                      labelStyle: labelStyle,
                                      valueStyle: valueStyle,
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                flex: 5,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    const SizedBox(height: 2),
                                    // Show transaction type code (RC / SALE / OPP / etc.) if provided by API.
                                    // Fall back to CREDIT/DEBIT for backward compatibility.
                                    Builder(builder: (context) {
                                      final rawType = item.trantype.trim();
                                      final display = rawType.isNotEmpty
                                          ? rawType.toUpperCase()
                                          : (isNegative ? 'CREDIT' : 'DEBIT');
                                      return Text(
                                        display,
                                        style: TextStyle(
                                          fontSize: 10,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.black87,
                                        ),
                                      );
                                    }),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Flexible(
                                child: Row(
                                  children: [
                                    const Icon(
                                      Icons.calendar_today_outlined,
                                      size: 12,
                                      color: Colors.grey,
                                    ),
                                    const SizedBox(width: 4),
                                    Expanded(
                                      child: Text(
                                        "Due: ${item.dueDate.isEmpty ? 'NA' : item.dueDate}",
                                        style: const TextStyle(
                                          fontSize: 11,
                                          color: Colors.black54,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              if (isOverdue)
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 4,
                                    vertical: 1,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.grey.shade100,
                                    borderRadius: BorderRadius.circular(2),
                                    border: Border.all(
                                      color: Colors.grey.shade300,
                                    ),
                                  ),
                                  child: Text(
                                    "${item.overDue} DAYS OVERDUE",
                                    style: const TextStyle(
                                      fontSize: 9,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.black87,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            if (selectionMode)
              Positioned(
                top: 2,
                right: 2,
                child: SizedBox(
                  width: 36,
                  height: 36,
                  child: Checkbox(
                    value: isSelected,
                    onChanged: (_) => onToggleSelected(),
                    // Checkbox toggles selection
                    visualDensity: VisualDensity.compact,
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _RichInfo extends StatelessWidget {
  final String label;
  final String value;
  final TextStyle labelStyle;
  final TextStyle valueStyle;

  const _RichInfo({
    required this.label,
    required this.value,
    required this.labelStyle,
    required this.valueStyle,
  });

  @override
  Widget build(BuildContext context) {
    return RichText(
      textAlign: TextAlign.start,
      text: TextSpan(
        children: [
          TextSpan(text: "$label: ", style: labelStyle),
          TextSpan(text: value, style: valueStyle),
        ],
      ),
    );
  }
}

class OutstandingData {
  final String accName, accAddress, lastPaymentDate;
  final double outstandingAmount;
  final int totalItems;
  final List<OutstandingItem> items;

  OutstandingData({
    required this.accName,
    required this.accAddress,
    required this.lastPaymentDate,
    required this.outstandingAmount,
    required this.totalItems,
    required this.items,
  });

  factory OutstandingData.fromJson(Map<String, dynamic> json) {
    String str(String k) =>
        (json[k]?.toString().trim() ?? '').replaceAll('null', '');
    double dbl(String k) => double.tryParse(json[k]?.toString() ?? '0') ?? 0.0;
    int integer(String k) => int.tryParse(json[k]?.toString() ?? '0') ?? 0;
    return OutstandingData(
      accName: str('acc_name').isEmpty ? 'Unknown Account' : str('acc_name'),
      accAddress: str('acc_address'),
      lastPaymentDate: str('last_payment_date'),
      outstandingAmount: dbl('outstanding_amount'),
      totalItems: integer('total_items'),
      items: (json['Items'] as List? ?? [])
          .map((e) => OutstandingItem.fromJson(e))
          .toList(),
    );
  }
}

class OutstandingItem {
  final String date, entryNo, overDue, keyEntryNo, dueDate, trantype;
  final double amount;

  OutstandingItem({
    required this.date,
    required this.entryNo,
    required this.overDue,
    required this.amount,
    required this.keyEntryNo,
    required this.dueDate,
    required this.trantype,
  });

  factory OutstandingItem.fromJson(Map<String, dynamic> json) {
    String str(String k) =>
        (json[k]?.toString().trim() ?? '').replaceAll('null', '');
    double dbl(String k) => double.tryParse(json[k]?.toString() ?? '0') ?? 0.0;
    return OutstandingItem(
      date: str('date'),
      entryNo: str('entryNo'),
      overDue: str('Over_due'),
      amount: dbl('amount'),
      keyEntryNo: str('keyentryno'),
      dueDate: str('due_date'),
      trantype: str('trantype'),
    );
  }
}
