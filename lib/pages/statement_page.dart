import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:cross_file/cross_file.dart';

import '../auth_service.dart';
import '../models/account_model.dart';
import '../models/ledger_entry_model.dart';
import '../services/account_selection_service.dart';
import 'select_account_page.dart';
import 'outstanding_details_page.dart';
import 'transaction_detail_page.dart';

class StatementPage extends StatefulWidget {
  const StatementPage({Key? key}) : super(key: key);

  @override
  State<StatementPage> createState() => _StatementPageState();
}

class _StatementPageState extends State<StatementPage> {
  final ScrollController _scrollController = ScrollController();

  Account? _selectedAccount;
  DateTime? _fromDate;
  DateTime? _toDate;

  // Default filter is 'All'
  String _selectedFilter = 'All';

  // Data
  double _openingBalance = 0;
  double _closingBalance = 0;
  final List<LedgerEntry> _entries = [];

  // Search State
  bool _isSearching = false;
  final TextEditingController _txnSearchController = TextEditingController();
  String _txnSearchText = '';

  // Paging
  static const int _pageSize = 50;
  int _pageNo = 1;
  bool _hasMore = true;

  // UI state
  bool _isLoading = false;
  bool _isLoadingMore = false;
  String? _error;

  // FAB State
  bool _fabExpanded = false;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);

    // Default dates null for 'All'
    _fromDate = null;
    _toDate = null;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Get account from service (set by SelectAccountPage)
      final accountService = Provider.of<AccountSelectionService>(context, listen: false);
      if (accountService.hasSelectedAccount) {
        setState(() {
          _selectedAccount = accountService.selectedAccount;
        });
        _fetchLedger(reset: true);
      } else {
        // No account selected, show account picker
        _pickAccount();
      }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _txnSearchController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_scrollController.hasClients ||
        _isLoading ||
        _isLoadingMore ||
        !_hasMore ||
        _txnSearchText.isNotEmpty) return;
    final threshold = 200.0;
    final max = _scrollController.position.maxScrollExtent;
    final cur = _scrollController.position.pixels;
    if (max - cur <= threshold) {
      _fetchLedger(reset: false);
    }
  }

  // --- LOGIC ---

  void _clearSearch() {
    if (_isSearching || _txnSearchText.isNotEmpty) {
      _txnSearchController.clear();
      _txnSearchText = '';
      _isSearching = false;
    }
  }

  void _applyQuickFilter(String? type) {
    _clearSearch();
    if (type == null) return;

    if (type == 'All') {
      setState(() {
        _selectedFilter = 'All';
        _fromDate = null;
        _toDate = null;
      });
      _fetchLedger(reset: true);
      return;
    }

    if (type == 'Custom') {
      setState(() {
        _selectedFilter = type;
        if (_fromDate == null) _fromDate = DateTime.now().subtract(const Duration(days: 30));
        if (_toDate == null) _toDate = DateTime.now();
      });
      return;
    }

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    // Rolling windows: Today = last 1 day, This Week = last 7 days, This Month = last 30 days, This Year = last 365 days
    Duration range;
    switch (type) {
      case 'Today':
        range = const Duration(days: 1);
        break;
      case 'This Week':
        range = const Duration(days: 7);
        break;
      case 'This Month':
        range = const Duration(days: 30);
        break;
      case 'This Year':
        range = const Duration(days: 365);
        break;
      default:
        range = const Duration(days: 0);
    }

    final start = today.subtract(range - const Duration(days: 1));
    final end = today;

    debugPrint('Filter: $type, From: $start, To: $end');

    setState(() {
      _selectedFilter = type;
      _fromDate = start;
      _toDate = end;
    });
    _fetchLedger(reset: true);
  }

  Future<void> _pickAccount() async {
    // Push SelectAccountPage on top and wait for account selection
    final result = await Navigator.of(context).push<Account>(
      MaterialPageRoute(
        builder: (_) => SelectAccountPage(
          title: 'Select Party',
          showBalance: true,
        ),
      ),
    );

    if (result != null && mounted) {
      setState(() {
        _selectedAccount = result;
        _txnSearchController.clear();
        _txnSearchText = '';
        _isSearching = false;
      });
      await _fetchLedger(reset: true);
    }
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
      _clearSearch();
      setState(() {
        _fromDate = picked;
        _selectedFilter = 'Custom'; // Switch to custom if picking manually
      });
      await _fetchLedger(reset: true);
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
      _clearSearch();
      setState(() {
        _toDate = picked;
        _selectedFilter = 'Custom'; // Switch to custom if picking manually
      });
      await _fetchLedger(reset: true);
    }
  }

  Future<void> _fetchLedger({bool reset = false}) async {
    if (_selectedAccount == null) return;

    if (reset) {
      if (mounted) {
        setState(() {
          _isLoading = true;
          _error = null;
          _pageNo = 1;
          _hasMore = true;
          _entries.clear();
        });
      }
    } else {
      if (_isLoadingMore || !_hasMore) return;
      if (mounted) {
        setState(() => _isLoadingMore = true);
      }
    }

    try {
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

      final df = DateFormat('yyyy-MM-dd');
      // Send selected dates as-is (no +1 day) to match backend custom/date picker behavior
      final apiFrom = _fromDate != null ? df.format(_fromDate!) : '';
      final apiTill = _toDate != null ? df.format(_toDate!) : '';

      final accountCode = _selectedAccount!.code ?? _selectedAccount!.id;

      final payload = {
        'lLicNo': auth.currentUser?.licenseNumber ?? '',
        'lAcNo': accountCode,
        'lFromDate': apiFrom,
        'lTillDate': apiTill,
        'lFirmCode': firmCode,
        'lPageNo': _pageNo,
        'lSize': _pageSize,
        'lExecuteTotalRows': 1,
        'lSharePdf': 0,
      };

      debugPrint('GetAccountLedger human dates: from=${_fromDate}, to=${_toDate}');
      debugPrint('GetAccountLedger payload: ${jsonEncode(payload)}');

      final response = await dio.post(
        '/GetAccountLedger',
        data: payload,
        options: Options(
          headers: {
            'Content-Type': 'application/json',
            'package_name': auth.packageNameHeader,
            if (auth.getAuthHeader() != null)
              'Authorization': auth.getAuthHeader(),
          },
        ),
      );

      String raw = response.data?.toString() ?? '';
      String clean = raw.replaceAll(RegExp(r'[\x00-\x1F\x7F]'), '').trim();
      Map<String, dynamic> data;
      try {
        final decoded = jsonDecode(clean);
        data = decoded is Map<String, dynamic>
            ? decoded
            : {'Message': decoded.toString()};
      } catch (_) {
        data = {'Message': clean};
      }

      final oppBal = _toDouble(data['OppBal']);

      final closingBal = _toDouble(data['ClosingBal']);
      final list = (data['Ledger'] as List<dynamic>? ?? []);
      final fetched = list
          .map((e) => _safeMap(e))
          .map((m) => LedgerEntry.fromJson(m))
          .toList();

      if (!mounted) return;
      setState(() {
        if (reset) {
          _openingBalance = oppBal;
        }
        _closingBalance = closingBal;
        _entries.addAll(fetched);
        _hasMore = fetched.length >= _pageSize;
        if (_hasMore) _pageNo += 1;
        _isLoading = false;
        _isLoadingMore = false;
      });
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
          _isLoadingMore = false;
        });
      }
    }
  }

  Map<String, dynamic> _safeMap(dynamic e) {
    if (e is Map<String, dynamic>) return e;
    try {
      return Map<String, dynamic>.from(e as Map);
    } catch (_) {
      return {};
    }
  }

  double _toDouble(dynamic v) {
    if (v == null) return 0;
    if (v is num) return v.toDouble();
    return double.tryParse(v.toString()) ?? 0;
  }

  // --- HELPERS ---

  Future<void> _downloadAndSharePdf({required Account acc, bool preferWhatsapp = false}) async {
    final auth = Provider.of<AuthService>(context, listen: false);
    final dio = auth.getDioClient();
    String firmCode = '';
    try {
      final stores = auth.currentUser?.stores ?? [];
      final primary = stores.firstWhere((s) => s.primary, orElse: () => stores.isNotEmpty ? stores.first : (throw 'no_store'));
      firmCode = primary.firmCode;
    } catch (_) {
      firmCode = '';
    }

    final payload = {
      'lLicNo': auth.currentUser?.licenseNumber ?? '',
      'lAcNo': acc.code ?? acc.id,
      'lPageNo': 1,
      'lSize': 50,
      'lExecuteTotalRows': 1,
      'lSharePdf': 1,
      'firm_code': firmCode,
      'lSearchFieldValue': '',
      'lFromDate': '',
      'lTillDate': ''
    };

    try {
      final response = await dio.post(
        '/GetAccountLedger',
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
      }

      if (bytes == null || bytes.isEmpty) throw 'No PDF data received.';

      final dir = await getTemporaryDirectory();
      final file = File('${dir.path}/statement_${acc.id}_${DateTime.now().millisecondsSinceEpoch}.pdf');
      await file.writeAsBytes(bytes, flush: true);
      final xfile = XFile(file.path, mimeType: 'application/pdf');
      await Share.shareXFiles([xfile], text: acc.name);
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  void _openOutstanding() {
    if (_selectedAccount == null) return;
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => OutstandingDetailsPage(
          accountNo: _selectedAccount!.id,
          accountName: _selectedAccount!.name,
        ),
      ),
    );
  }

  // --- UI COMPONENTS ---

  Widget _buildPassbookHeader(ColorScheme cs) {
    return Container(
      color: const Color(0xFFE8EAF6),
      padding: const EdgeInsets.symmetric(horizontal: 0, vertical: 10),
      child: Row(
        children: [
          SizedBox(
            width: 75,
            child: Text('DATE', textAlign: TextAlign.center, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: cs.primary)),
          ),
          Container(width: 1, height: 16, color: Colors.grey[400]),
          Expanded(
            flex: 4,
            child: Padding(
              padding: const EdgeInsets.only(left: 12),
              child: Text('PARTICULARS', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: cs.primary)),
            ),
          ),
          Container(width: 1, height: 16, color: Colors.grey[400]),
          Expanded(
            flex: 2,
            child: Text('AMOUNT', textAlign: TextAlign.right, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: cs.primary)),
          ),
          const SizedBox(width: 4),
          Container(width: 1, height: 16, color: Colors.grey[400]),
          Expanded(
            flex: 2,
            child: Text('BALANCE', textAlign: TextAlign.right, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: cs.primary)),
          ),
          const SizedBox(width: 12),
        ],
      ),
    );
  }

  Widget _buildPassbookRow(LedgerEntry entry, ColorScheme cs, int index) {
    final df = DateFormat('dd-MMM\nyy');
    final dateStr = entry.date != null ? df.format(entry.date!) : (entry.tranId ?? '');
    final dr = _toDouble(entry.drAmt);
    final cr = _toDouble(entry.crAmt);
    final runningAmount = _toDouble(entry.runningAmt);

    // --- BACKGROUND COLOR LOGIC ---
    Color bgColor;
    if (cr > 0) {
      bgColor = const Color(0xFFF1F8E9); // Light Green Tint
    } else if (dr > 0) {
      bgColor = const Color(0xFFFEF2F2); // Light Red Tint
    } else {
      bgColor = index % 2 == 0 ? Colors.white : const Color(0xFFF9FAFB);
    }

    final balanceText = runningAmount.toStringAsFixed(2);

    return InkWell(
      onTap: () => _loadAndShowTranDetail(entry, cs),
      child: Container(
        color: bgColor,
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Column(
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  width: 75,
                  child: Padding(
                    padding: const EdgeInsets.only(left: 4),
                    child: Text(
                      dateStr,
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Colors.black87, height: 1.2),
                    ),
                  ),
                ),
                Container(width: 1, height: 40, color: Colors.grey[300]),
                Expanded(
                  flex: 4,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          entry.tranType ?? 'TRANSACTION',
                          style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: cs.primary.withValues(alpha: 0.9)),
                          maxLines: 1, overflow: TextOverflow.ellipsis,
                        ),
                        if (entry.entryNo != null && entry.entryNo!.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(top: 3),
                            child: Text(
                              'Entry No: ${entry.entryNo}',
                              style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w500, color: Colors.black87),
                            ),
                          ),
                        if (entry.narration != null && entry.narration!.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(top: 3),
                            child: Text(
                              entry.narration!,
                              style: TextStyle(fontSize: 11, color: Colors.grey[700], fontStyle: FontStyle.italic),
                              maxLines: 1, overflow: TextOverflow.ellipsis,
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
                Container(width: 1, height: 40, color: Colors.grey[300]),
                // AMOUNT column: show debit or credit amount in black
                Expanded(
                  flex: 2,
                  child: Text(
                    '₹${(dr > 0 ? dr : cr).toStringAsFixed(2)}',
                    textAlign: TextAlign.right,
                    style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: Colors.black87),
                  ),
                ),
                const SizedBox(width: 4),
                Container(width: 1, height: 40, color: Colors.grey[300]),
                // BALANCE column: show running balance with sign, black text
                Expanded(
                  flex: 2,
                  child: Text(
                    '₹$balanceText',
                    textAlign: TextAlign.right,
                    style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: Colors.black87),
                  ),
                ),
                const SizedBox(width: 12),
              ],
            ),
            const SizedBox(height: 4),
            Divider(height: 1, thickness: 0.5, color: Colors.grey[300]),
          ],
        ),
      ),
    );
  }

  // --- FILTER BAR (with ALL button) ---

  Widget _buildFilterBar(ColorScheme cs) {
    final bool isAllSelected = _selectedFilter == 'All';

    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Row 1: Account Selector
          InkWell(
            onTap: _pickAccount,
            borderRadius: BorderRadius.circular(8),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: cs.surfaceContainerHighest.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(Icons.person, size: 18, color: cs.primary),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _selectedAccount?.name ?? 'Select Account',
                      style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                      maxLines: 1, overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (_selectedAccount != null) ...[
                    const SizedBox(width: 8),
                    Text('${_selectedAccount!.phone ?? ""}', style: TextStyle(fontSize: 11, color: Colors.grey[600])),
                  ],
                  const SizedBox(width: 8),
                  Icon(Icons.keyboard_arrow_down, size: 18, color: Colors.grey[600]),
                ],
              ),
            ),
          ),

          const SizedBox(height: 8),

          // Show full address (Address1/Address2/Address3) when account selected
          if (_selectedAccount != null) ...[
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: Colors.grey[200]!),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Prefer the assembled `address` (Address1+2+3) if available
                  if ((_selectedAccount!.address ?? '').trim().isNotEmpty)
                    Text(_selectedAccount!.address!, style: const TextStyle(fontSize: 12, color: Colors.black87)),

                  // Otherwise, show address2 and address3 separately if present
                  if ((_selectedAccount!.address ?? '').trim().isEmpty) ...[
                    if ((_selectedAccount!.address2 ?? '').trim().isNotEmpty)
                      Text(_selectedAccount!.address2!, style: const TextStyle(fontSize: 12, color: Colors.black87)),
                    if ((_selectedAccount!.address3 ?? '').trim().isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 4.0),
                        child: Text(_selectedAccount!.address3!, style: const TextStyle(fontSize: 12, color: Colors.black87)),
                      ),
                  ],

                  // Pincode (if available)
                  if ((_selectedAccount!.pincode ?? '').trim().isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 6.0),
                      child: Text('Pincode: ${_selectedAccount!.pincode!}', style: const TextStyle(fontSize: 12, color: Colors.black54)),
                    ),
                ],
              ),
            ),

            const SizedBox(height: 8),
          ],

          // Row 2: All Button | Date Dropdown | Bills Button
          Row(
            children: [
              // 'All' Button
              SizedBox(
                height: 36,
                child: OutlinedButton(
                  onPressed: () => _applyQuickFilter('All'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    backgroundColor: isAllSelected ? cs.primary : Colors.white,
                    side: BorderSide(color: isAllSelected ? cs.primary : Colors.grey[300]!),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                  ),
                  child: Text(
                      'All',
                      style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: isAllSelected ? Colors.white : Colors.grey[800]
                      )
                  ),
                ),
              ),

              const SizedBox(width: 8),

              // Date Dropdown
              Expanded(
                child: Container(
                  height: 36,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey[300]!),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: _selectedFilter,
                      icon: const Icon(Icons.calendar_today, size: 16, color: Colors.grey),
                      isDense: true,
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.grey[800]),
                      items: ['All', 'Today', 'This Week', 'This Month', 'This Year', 'Custom']
                          .map((String value) {
                        return DropdownMenuItem<String>(
                          value: value,
                          child: Text(value),
                        );
                      }).toList(),
                      onChanged: _applyQuickFilter,
                    ),
                  ),
                ),
              ),

              const SizedBox(width: 8),

              // Bills Button
              SizedBox(
                height: 36,
                child: OutlinedButton(
                  onPressed: _selectedAccount != null ? _openOutstanding : null,
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    visualDensity: VisualDensity.compact,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                    side: BorderSide(color: cs.primary.withValues(alpha: 0.5)),
                  ),
                  child: const Text('Outstanding', style: TextStyle(fontSize: 11)),
                ),
              ),
            ],
          ),

          // Row 3: Custom Date Range (Only visible if 'Custom' is selected)
          if (_selectedFilter == 'Custom') ...[
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(child: _buildDateBox(_fromDate, _pickFromDate)),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 4),
                  child: Text("-", style: TextStyle(color: Colors.grey)),
                ),
                Expanded(child: _buildDateBox(_toDate, _pickToDate)),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildDateBox(DateTime? date, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Container(
        height: 36,
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

  Widget _buildPassbookSummary() {
    if (_selectedAccount == null || _isSearching) return const SizedBox.shrink();
    return Container(
      color: const Color(0xFFFAFAFA),
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('OPENING', style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Colors.grey, letterSpacing: 0.5)),
              const SizedBox(height: 2),
              Text(
                '₹${_openingBalance.toStringAsFixed(2)}',
                style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13, color: Colors.black87),
              ),
            ],
          ),
          Container(width: 1, height: 20, color: Colors.grey[300]),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              const Text('CLOSING', style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Colors.grey, letterSpacing: 0.5)),
              const SizedBox(height: 2),
              Text(
                '₹${_closingBalance.toStringAsFixed(2)}',
                style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13, color: _closingBalance < 0 ? const Color(0xFFD32F2F) : const Color(0xFF388E3C)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // Fetch transaction detail from API
  Future<Map<String, dynamic>?> _fetchTranDetailFromApi(LedgerEntry entry) async {
    try {
      final auth = Provider.of<AuthService>(context, listen: false);
      final dio = auth.getDioClient();

      final keyEntryNo = entry.keyEntryNo ?? entry.entryNo ?? entry.tranId ?? entry.vchNumber ?? '';

      final payload = {
        'lLicNo': auth.currentUser?.licenseNumber ?? '',
        'lKeyEntryNo': keyEntryNo,
        'lIsEntryRecord': (entry.isEntryRecord != null) ? entry.isEntryRecord.toString() : '1',
        'lKeyEntrySrNo': entry.keyEntrySrNo,
      };

      try {
        debugPrint('GetTranDetail payload: ${jsonEncode(payload)}');
      } catch (_) {
        debugPrint('GetTranDetail payload: $payload');
      }

      // Use full URL as provided in the curl. If your Dio base is set to different host, this will still work.
      final url = 'http://mobileappsandbox.reckonsales.com:8080/reckon-biz/api/reckonpwsorder/GetTranDetail';

      final response = await dio.post(
        url,
        data: payload,
        options: Options(headers: {
          'Content-Type': 'application/json',
          'package_name': auth.packageNameHeader,
          if (auth.getAuthHeader() != null) 'Authorization': auth.getAuthHeader(),
        }),
      );

      debugPrint('GetTranDetail raw response type: ${response.data.runtimeType}');

      dynamic raw = response.data;
      Map<String, dynamic> parsed = {};

      if (raw is Map<String, dynamic>) parsed = raw;
      else if (raw is String) {
        final clean = raw.trim();
        try {
          final dec = jsonDecode(clean);
          if (dec is Map<String, dynamic>) parsed = dec;
          else parsed = {'data': dec};
        } catch (_) {
          parsed = {'data': clean};
        }
      } else {
        try {
          final s = utf8.decode(raw as List<int>);
          final dec = jsonDecode(s);
          if (dec is Map<String, dynamic>) parsed = dec;
          else parsed = {'data': dec};
        } catch (_) {
          parsed = {'data': raw.toString()};
        }
      }

      debugPrint('GetTranDetail parsed keys: ${parsed.keys.toList()}');

      return parsed;
    } catch (e, st) {
      debugPrint('GetTranDetail error: $e');
      debugPrint(st.toString());
      return {'error': e.toString()};
    }
  }

  // Show transaction detail in a full page instead of bottom sheet
  void _loadAndShowTranDetail(LedgerEntry entry, ColorScheme cs) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => TransactionDetailPage(
          entry: entry,
          fetchDetail: _fetchTranDetailFromApi,
          colorScheme: cs,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    final List<LedgerEntry> displayEntries;
    if (_txnSearchText.isEmpty) {
      displayEntries = _entries;
    } else {
      final q = _txnSearchText.toLowerCase();
      displayEntries = _entries.where((e) {
        return (e.vchNumber?.toLowerCase().contains(q) ?? false) ||
            (e.entryNo?.toLowerCase().contains(q) ?? false) ||
            (e.narration?.toLowerCase().contains(q) ?? false) ||
            (e.drAmt?.toString().contains(q) ?? false) ||
            (e.crAmt?.toString().contains(q) ?? false);
      }).toList();
    }

    return Scaffold(
      backgroundColor: Colors.white,
        appBar: AppBar(
          title: _isSearching
              ? Container(
          height: 40,
          decoration: BoxDecoration(
            color: Colors.grey[100],
            borderRadius: BorderRadius.circular(8),
          ),
          child: TextField(
            controller: _txnSearchController,
            autofocus: true,
            textAlignVertical: TextAlignVertical.center,
            decoration: InputDecoration(
                hintText: 'Search Amount, Entry No...',
                hintStyle: TextStyle(color: Colors.grey[500], fontSize: 14),
                border: InputBorder.none,
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(horizontal: 12),
                suffixIcon: IconButton(
                    icon: const Icon(Icons.close, size: 18, color: Colors.grey),
                    onPressed: () {
                      setState(() {
                        _txnSearchController.clear();
                        _txnSearchText = '';
                      });
                    }
                )
            ),
            style: const TextStyle(fontSize: 14, color: Colors.black87),
            onChanged: (val) => setState(() => _txnSearchText = val),
          ),
        )
            : const Text('Account Statement', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700)),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        scrolledUnderElevation: 2,
        actions: [
          IconButton(
            icon: Icon(_isSearching ? Icons.close : Icons.search),
            onPressed: () {
              setState(() {
                if (_isSearching) {
                  _isSearching = false;
                  _txnSearchText = '';
                  _txnSearchController.clear();
                } else {
                  _isSearching = true;
                }
              });
            },
          ),
          if (!_isSearching
          )
            IconButton(icon: const Icon(Icons.refresh), onPressed: () => _fetchLedger(reset: true)),
        ],
      ),
      floatingActionButton: _fabExpanded ? Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.end,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          FloatingActionButton.small(
            heroTag: "wa",
            onPressed: () async {
              await _downloadAndSharePdf(acc: _selectedAccount!, preferWhatsapp: true);
            },
            backgroundColor: const Color(0xFF25D366),
            child: const Icon(Icons.chat, color: Colors.white),
          ),
          const SizedBox(height: 12),
          FloatingActionButton.small(
            heroTag: "sh",
            onPressed: () async {
              await _downloadAndSharePdf(acc: _selectedAccount!, preferWhatsapp: false);
            },
            backgroundColor: Colors.blue,
            child: const Icon(Icons.share, color: Colors.white),
          ),
          const SizedBox(height: 12),
          FloatingActionButton(
            heroTag: "main",
            onPressed: () => setState(() => _fabExpanded = false),
            backgroundColor: Colors.grey[800],
            child: const Icon(Icons.close, color: Colors.white),
          ),
        ],
      ) : FloatingActionButton(
        heroTag: "main",
        onPressed: _selectedAccount != null ? () => setState(() => _fabExpanded = true) : null,
        backgroundColor: cs.primary,
        child: const Icon(Icons.share),
      ),
      body: Column(
        children: [
          AnimatedCrossFade(
            firstChild: _buildFilterBar(cs),
            secondChild: const SizedBox.shrink(),
            crossFadeState: _isSearching ? CrossFadeState.showSecond : CrossFadeState.showFirst,
            duration: const Duration(milliseconds: 200),
          ),

          if (_error != null)
            Container(color: Colors.red[50], padding: const EdgeInsets.all(8), width: double.infinity, child: Text(_error!, style: const TextStyle(color: Colors.red))),

          if (!_isSearching) ...[
            const Divider(height: 1, thickness: 1, color: Color(0xFFEEEEEE)),
            _buildPassbookSummary(),
          ],

          const Divider(height: 1, thickness: 1, color: Color(0xFFEEEEEE)),
          if (displayEntries.isNotEmpty || _entries.isNotEmpty) _buildPassbookHeader(cs),

          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _selectedAccount == null
                ? const Center(child: Text("Select an account to view statement", style: TextStyle(color: Colors.grey)))
                : displayEntries.isEmpty
                ? const Center(child: Text("No transactions found", style: TextStyle(color: Colors.grey)))
                : RefreshIndicator(
              onRefresh: () => _fetchLedger(reset: true),
              child: ListView.builder(
                controller: _scrollController,
                padding: const EdgeInsets.only(bottom: 100),
                itemCount: displayEntries.length + (_isLoadingMore && !_isSearching ? 1 : 0),
                itemBuilder: (context, index) {
                  if (index >= displayEntries.length) {
                    return const Padding(padding: EdgeInsets.all(16), child: Center(child: CircularProgressIndicator()));
                  }

                  return _buildPassbookRow(displayEntries[index], cs, index);
                 },
              ),
            ),
          ),
        ],
      ),
    );
  }
}

