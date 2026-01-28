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
  // FAB expanded state for expandable actions (Share / WhatsApp)
  bool _fabExpanded = false;

  OutstandingData? _outstandingData;
  bool _isLoading = false;
  String? _errorMessage;

  final int _pageSize = 30;
  int _currentPage = 1;
  bool _hasMore = true;

  final Set<int> _selectedIndexes = <int>{};
  bool _selectionMode = false;

  @override
  void initState() {
    super.initState();
    _loadOutstandingDetails(reset: true);
  }

  @override
  void dispose() {
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
      _selectionMode = true;
      if (_selectedIndexes.contains(listIndex)) {
        _selectedIndexes.remove(listIndex);
      } else {
        _selectedIndexes.add(listIndex);
      }

      if (_selectedIndexes.isEmpty) {
        _selectionMode = false;
      }
    });
  }

  void _clearSelection() {
    setState(() {
      _selectedIndexes.clear();
      _selectionMode = false;
    });
  }

  void _goToReceiptEntry() {
    if (_selectedIndexes.isEmpty) return;

    // Build a serializable list of selected bills to pass to receipt screen
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
    }).toList();

    // Debug: Log outgoing data
    print('[OutstandingDetails] Navigating to ReceiptEntry with:');
    print('[OutstandingDetails]   accountNo: ${widget.accountNo}');
    print('[OutstandingDetails]   accountName: ${widget.accountName}');
    print('[OutstandingDetails]   selectedBills: ${selectedBills.length} items');
    selectedBills.forEach((b) => print('[OutstandingDetails]     - ${b['entryNo']}: ₹${b['amount']}'));

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

  Future<void> _loadOutstandingDetails({bool reset = false}) async {
    if (reset) {
      if (mounted) {
        setState(() {
          _isLoading = true;
          _errorMessage = null;
          _currentPage = 1;
          _hasMore = true;
          _outstandingData = null;
          _selectedIndexes.clear();
          _selectionMode = false;
        });
      }
    } else {
      if (mounted) setState(() => _isLoading = true);
    }

    try {
      final auth = Provider.of<AuthService>(context, listen: false);

      // Use auth.getDioClient() to get Dio with 401 interceptor
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

      String cleanJson = response.data.toString().replaceAll(RegExp(r'[\x00-\x1F\x7F]'), '').trim();
      final data = jsonDecode(cleanJson) as Map<String, dynamic>;

      final newData = OutstandingData.fromJson(data);

      if (reset) {
        _outstandingData = newData;
      } else {
        _outstandingData?.items.addAll(newData.items);
      }

      _hasMore = newData.items.length >= _pageSize;
      if (_hasMore) _currentPage++;

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

  // Helper: download PDF from GetOutstandingDetails (lSharePdf=1) and open share sheet
  Future<void> _downloadAndSharePdf({bool preferWhatsapp = false}) async {
    final auth = Provider.of<AuthService>(context, listen: false);
    final dio = auth.getDioClient();

    String firmCode = '';
    try {
      final stores = auth.currentUser?.stores ?? [];
      final primary = stores.firstWhere((s) => s.primary,
          orElse: () => stores.isNotEmpty ? stores.first : (throw 'no_store'));
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
      'lTillDate': ''
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
            if (auth.getAuthHeader() != null) 'Authorization': auth.getAuthHeader(),
          },
        ),
      );

      Uint8List? bytes;
      if (response.data is Uint8List) {
        bytes = response.data as Uint8List;
      } else if (response.data is List<int>) {
        bytes = Uint8List.fromList(List<int>.from(response.data));
      } else {
        try {
          final raw = response.data;
          if (raw is String) {
            try {
              bytes = base64Decode(raw);
            } catch (_) {}
          } else if (raw is Map) {
            if (raw['Pdf'] != null && raw['Pdf'] is String) {
              try {
                bytes = base64Decode(raw['Pdf']);
              } catch (_) {}
            } else if (raw['Message'] != null && raw['Message'] is String) {
              try {
                bytes = base64Decode(raw['Message']);
              } catch (_) {}
            }
          }
        } catch (_) {}
      }

      if (bytes == null || bytes.isEmpty) throw 'No PDF data received from server.';

      final dir = await getTemporaryDirectory();
      final file = File('${dir.path}/outstanding_${widget.accountNo}_${DateTime.now().millisecondsSinceEpoch}.pdf');
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

  Future<void> _shareOutstanding() async {
    await _downloadAndSharePdf(preferWhatsapp: false);
  }

  Future<void> _shareOutstandingOnWhatsapp() async {
    await _downloadAndSharePdf(preferWhatsapp: true);
  }

  // --- UI IMPLEMENTATION ---

  @override
  Widget build(BuildContext context) {
    // Professional Accounting Palette
    final primaryColor = Colors.blueGrey.shade800;
    final scaffoldBg = Colors.grey.shade100;

    final selectedTotal = _selectedTotal;
    final currencyFormat = NumberFormat.simpleCurrency(locale: 'en_IN', decimalDigits: 2);

    return Scaffold(
      backgroundColor: scaffoldBg,
      appBar: AppBar(
        backgroundColor: primaryColor,
        elevation: 0,
        centerTitle: false,
        title: const Text(
          "Ledger Book",
          style: TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.5,
          ),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          if (_outstandingData != null)
            IconButton(
              tooltip: _selectionMode ? 'Clear selection' : 'Select bills',
              onPressed: _selectionMode ? _clearSelection : () => setState(() => _selectionMode = true),
              icon: Icon(_selectionMode ? Icons.close_rounded : Icons.checklist_rounded),
            ),
          IconButton(
            onPressed: () => _loadOutstandingDetails(reset: true),
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
      floatingActionButton: _buildExpandableFab(primaryColor),
      body: Stack(
        children: [
          Padding(
            padding: EdgeInsets.only(bottom: _selectedIndexes.isEmpty ? 0 : 72),
            child: _buildBody(),
          ),

          // Full-page dim overlay when FAB is expanded
          if (_fabExpanded)
            Positioned.fill(
              child: GestureDetector(
                onTap: () => setState(() => _fabExpanded = false),
                child: const ModalBarrier(
                  dismissible: false,
                  color: Color(0x73000000), // ~45% black
                ),
              ),
            ),

          if (_selectedIndexes.isNotEmpty)
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: SafeArea(
                top: false,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.08),
                        blurRadius: 12,
                        offset: const Offset(0, -4),
                      )
                    ],
                    border: Border(top: BorderSide(color: Colors.grey.shade200)),
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
                              style: const TextStyle(fontSize: 11, color: Colors.black54, fontWeight: FontWeight.w600),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Total: ${currencyFormat.format(selectedTotal.abs())} ${selectedTotal < 0 ? 'Cr' : 'Dr'}',
                              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 10),
                      SizedBox(
                        height: 42,
                        child: FilledButton.icon(
                          onPressed: _goToReceiptEntry,
                          icon: const Icon(Icons.receipt_long_outlined, size: 18),
                          label: const Text('Receipt Entry'),
                          style: FilledButton.styleFrom(
                            backgroundColor: primaryColor,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
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
    if (_errorMessage != null && _outstandingData == null) {
      return Center(child: Text(_errorMessage!, style: const TextStyle(fontSize: 12)));
    }
    if (_isLoading && _outstandingData == null) {
      return const Center(child: CircularProgressIndicator(strokeWidth: 2));
    }
    if (_outstandingData == null) {
      return const Center(child: Text("No records found"));
    }

    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.only(bottom: 24),
      itemCount: _outstandingData!.items.length + 2,
      itemBuilder: (context, index) {
        // 1. LEDGER HEADER
        if (index == 0) {
          return _LedgerHeader(data: _outstandingData!);
        }

        // 2. LOADER
        if (index == _outstandingData!.items.length + 1) {
          return _hasMore
              ? const Center(child: Padding(padding: EdgeInsets.all(24), child: CircularProgressIndicator(strokeWidth: 2)))
              : const Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Center(child: Text("--- END OF REPORT ---", style: TextStyle(color: Colors.grey, fontSize: 10, letterSpacing: 1))),
                );
        }

        // 3. BILL ITEMS
        final itemIndex = index - 1;
        final item = _outstandingData!.items[itemIndex];
        final isSelected = _selectedIndexes.contains(itemIndex);

        return _LedgerItem(
          item: item,
          isSelected: isSelected,
          selectionMode: _selectionMode,
          onToggleSelected: () => _toggleSelection(itemIndex),
          onLongPress: () => _toggleSelection(itemIndex),
        );
      },
    );
  }

  Widget _buildExpandableFab(Color primaryColor) {
    final canShare = _outstandingData != null;

    return Stack(
      alignment: Alignment.bottomRight,
      children: [
        Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 160),
              child: !_fabExpanded
                  ? const SizedBox.shrink()
                  : Column(
                      key: const ValueKey('expanded-actions'),
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        _fabAction(
                          label: 'WhatsApp',
                          icon: Icons.chat,
                          onTap: canShare
                              ? () async {
                                  setState(() => _fabExpanded = false);
                                  await _shareOutstandingOnWhatsapp();
                                }
                              : null,
                        ),
                        const SizedBox(height: 10),
                        _fabAction(
                          label: 'Share',
                          icon: Icons.share_outlined,
                          onTap: canShare
                              ? () async {
                                  setState(() => _fabExpanded = false);
                                  await _shareOutstanding();
                                }
                              : null,
                        ),
                        const SizedBox(height: 10),
                      ],
                    ),
            ),
            FloatingActionButton(
              heroTag: 'outstanding-fab',
              onPressed: () => setState(() => _fabExpanded = !_fabExpanded),
              backgroundColor: primaryColor,
              foregroundColor: Colors.white,
              child: AnimatedRotation(
                duration: const Duration(milliseconds: 160),
                turns: _fabExpanded ? 0.125 : 0,
                child: Icon(_fabExpanded ? Icons.close : Icons.share),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _fabAction({required String label, required IconData icon, required VoidCallback? onTap}) {
    final enabled = onTap != null;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.grey.withValues(alpha: 0.3)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.08),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Text(
            label,
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: enabled ? Colors.black : Colors.grey),
          ),
        ),
        const SizedBox(width: 10),
        Material(
          color: enabled ? Colors.white : Colors.grey.shade200,
          shape: const CircleBorder(),
          child: InkWell(
            customBorder: const CircleBorder(),
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Icon(icon, size: 20, color: enabled ? Colors.black87 : Colors.grey),
            ),
          ),
        ),
      ],
    );
  }
}

// --- WIDGETS ---

class _LedgerHeader extends StatelessWidget {
  final OutstandingData data;
  const _LedgerHeader({required this.data});

  @override
  Widget build(BuildContext context) {
    final currencyFormat = NumberFormat.simpleCurrency(locale: 'en_IN', decimalDigits: 2);

    return Container(
      color: Colors.white,
      margin: const EdgeInsets.only(bottom: 8),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
            decoration: BoxDecoration(
              color: Colors.blueGrey.shade800,
            ),
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
                        style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.white, height: 1.2),
                      ),
                    ),
                  ],
                ),
                if(data.accAddress.isNotEmpty && data.accAddress != 'Address not available') ...[
                  const SizedBox(height: 8),
                  Padding(
                    padding: const EdgeInsets.only(left: 30),
                    child: Text(
                      data.accAddress,
                      style: const TextStyle(fontSize: 12, color: Colors.white70),
                    ),
                  ),
                ]
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
                      const Text("TOTAL OUTSTANDING", style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey, letterSpacing: 0.5)),
                      const SizedBox(height: 4),
                      Text(
                        currencyFormat.format(data.outstandingAmount),
                        style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.blueGrey.shade900),
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
                      const Text("INVOICES", style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey, letterSpacing: 0.5)),
                      const SizedBox(height: 4),
                      Text("${data.totalItems}", style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                      if(data.lastPaymentDate.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text("Last Pay: ${data.lastPaymentDate}", style: const TextStyle(fontSize: 11, color: Colors.black54)),
                      ]
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
  final VoidCallback? onLongPress;

  const _LedgerItem({
    required this.item,
    required this.selectionMode,
    required this.isSelected,
    required this.onToggleSelected,
    this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    final currencyFormat = NumberFormat.simpleCurrency(locale: 'en_IN', decimalDigits: 2);
    final isNegative = item.amount < 0;
    final isOverdue = item.overDue.isNotEmpty && item.overDue != "0";

    // Compact layout constants
    const labelStyle = TextStyle(fontSize: 11, color: Color(0xFF757575));
    const valueStyle = TextStyle(fontSize: 12, color: Color(0xFF212121), fontWeight: FontWeight.w500);

    // Status Strip Color
    final Color stripColor = isNegative
        ? Colors.green.shade600
        : (isOverdue ? Colors.red.shade700 : Colors.blueGrey.shade300);

    return InkWell(
      onTap: selectionMode ? onToggleSelected : null,
      onLongPress: onLongPress,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(2),
          border: isSelected
              ? Border.all(color: Theme.of(context).colorScheme.primary, width: 1.2)
              : null,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 2,
              offset: const Offset(0, 1),
            )
          ],
        ),
        child: Stack(
          children: [
            IntrinsicHeight(
              child: Row(
                children: [
                  // 1. Status Strip
                  Container(width: 4, color: stripColor),

                  // 2. Content (full width; wraps naturally)
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Header Row: Date & Amount
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
                                  right: selectionMode ? 34 : 0, // leave room for top-right checkbox
                                ),
                                child: Text(
                                  currencyFormat.format(item.amount.abs()),
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                    color: isNegative ? Colors.green.shade800 : Colors.black87,
                                  ),
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 8),
                          const Divider(height: 1, thickness: 0.5),
                          const SizedBox(height: 8),

                          // Grid Data
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                flex: 4,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    _RichInfo(
                                      label: "Bill No",
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
                                    if (isNegative)
                                      const Text(
                                        "CREDIT",
                                        style: TextStyle(
                                          fontSize: 10,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.green,
                                        ),
                                      )
                                    else
                                      const Text(
                                        "DEBIT",
                                        style: TextStyle(
                                          fontSize: 10,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.black45,
                                        ),
                                      )
                                  ],
                                ),
                              )
                            ],
                          ),

                          const SizedBox(height: 8),

                          // Footer Row
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Flexible(
                                child: Row(
                                  children: [
                                    const Icon(Icons.calendar_today_outlined, size: 12, color: Colors.grey),
                                    const SizedBox(width: 4),
                                    Expanded(
                                      child: Text(
                                        "Due: ${item.dueDate.isEmpty ? 'NA' : item.dueDate}",
                                        style: const TextStyle(fontSize: 11, color: Colors.black54),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              if (isOverdue)
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                                  decoration: BoxDecoration(
                                    color: Colors.red.shade50,
                                    borderRadius: BorderRadius.circular(2),
                                    border: Border.all(color: Colors.red.shade100),
                                  ),
                                  child: Text(
                                    "${item.overDue} DAYS OVERDUE",
                                    style: TextStyle(
                                      fontSize: 9,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.red.shade800,
                                    ),
                                  ),
                                )
                            ],
                          )
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Top-right checkbox, overlayed.
            // We don't reserve layout space for it, so the content can wrap "around" it.
            // Only the checkbox itself should capture taps.
            if (selectionMode)
              Positioned(
                top: 2,
                right: 2,
                child: IgnorePointer(
                  ignoring: false,
                  child: SizedBox(
                    width: 36,
                    height: 36,
                    child: Checkbox(
                      value: isSelected,
                      onChanged: (_) => onToggleSelected(),
                      visualDensity: VisualDensity.compact,
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// Helper for wrapping text properly
class _RichInfo extends StatelessWidget {
  final String label;
  final String value;
  final TextStyle labelStyle;
  final TextStyle valueStyle;
  final bool alignRight;

  const _RichInfo({
    required this.label,
    required this.value,
    required this.labelStyle,
    required this.valueStyle,
    this.alignRight = false,
  });

  @override
  Widget build(BuildContext context) {
    // RichText allows the label and value to flow together and wrap if needed
    return RichText(
      textAlign: alignRight ? TextAlign.end : TextAlign.start,
      text: TextSpan(
        children: [
          TextSpan(text: "$label: ", style: labelStyle),
          TextSpan(text: value, style: valueStyle),
        ],
      ),
    );
  }
}

// --- MODELS (UNCHANGED) ---
class OutstandingData {
  final String accName, accAddress, lastPaymentDate;
  final double outstandingAmount;
  final int totalItems;
  final List<OutstandingItem> items;

  OutstandingData({
    required this.accName, required this.accAddress, required this.lastPaymentDate,
    required this.outstandingAmount, required this.totalItems, required this.items,
  });

  factory OutstandingData.fromJson(Map<String, dynamic> json) {
    String str(String k) => (json[k]?.toString().trim() ?? '').replaceAll('null', '');
    double dbl(String k) => double.tryParse(json[k]?.toString() ?? '0') ?? 0.0;
    int integer(String k) => int.tryParse(json[k]?.toString() ?? '0') ?? 0;

    return OutstandingData(
      accName: str('acc_name').isEmpty ? 'Unknown Account' : str('acc_name'),
      accAddress: str('acc_address'),
      lastPaymentDate: str('last_payment_date'),
      outstandingAmount: dbl('outstanding_amount'),
      totalItems: integer('total_items'),
      items: (json['Items'] as List? ?? []).map((e) => OutstandingItem.fromJson(e)).toList(),
    );
  }
}

class OutstandingItem {
  final String date, entryNo, overDue, keyEntryNo, dueDate, trantype;
  final double amount;

  OutstandingItem({
    required this.date, required this.entryNo, required this.overDue,
    required this.amount, required this.keyEntryNo, required this.dueDate, required this.trantype,
  });

  factory OutstandingItem.fromJson(Map<String, dynamic> json) {
    String str(String k) => (json[k]?.toString().trim() ?? '').replaceAll('null', '');
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

