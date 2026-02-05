import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'dart:convert';

import '../auth_service.dart';
import '../models/ledger_entry_model.dart';

/// Page to attach bills/invoices to a receipt
/// This is opened from CreateReceiptScreen when user wants to add bills
class AttachBillsPage extends StatefulWidget {
  final String accountNo;
  final String accountName;
  final double amount;

  const AttachBillsPage({
    super.key,
    required this.accountNo,
    required this.accountName,
    required this.amount,
  });

  @override
  State<AttachBillsPage> createState() => _AttachBillsPageState();
}

class _AttachBillsPageState extends State<AttachBillsPage> {
  final ScrollController _scrollController = ScrollController();

  // Data
  final List<LedgerEntry> _entries = [];
  final Set<int> _selectedIndices = {};
  final Map<int, double> _partialAmounts = {}; // Tracks partial adjustments

  // Paging
  static const int _pageSize = 50;
  int _pageNo = 1;
  bool _hasMore = true;

  // UI state
  bool _isLoading = false;
  bool _isLoadingMore = false;
  String? _error;

  // Amount tracking
  double get _adjustedAmount {
    return _selectedIndices.fold<double>(0.0, (sum, index) {
      if (_partialAmounts.containsKey(index)) {
        return sum + _partialAmounts[index]!;
      }
      final entry = _entries[index];
      final dr = _toDouble(entry.drAmt);
      final cr = _toDouble(entry.crAmt);
      final amount = dr > 0 ? dr : cr;
      return sum + amount;
    });
  }

  double get _pendingAmount => widget.amount - _adjustedAmount;

  @override
  void initState() {
    super.initState();
    debugPrint('[AttachBills] Opened for account: ${widget.accountName} (${widget.accountNo})');
    debugPrint('[AttachBills] Amount: ₹${widget.amount.toStringAsFixed(2)}');

    _scrollController.addListener(_onScroll);
    _fetchLedger(reset: true);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_scrollController.hasClients ||
        _isLoading ||
        _isLoadingMore ||
        !_hasMore) return;
    final threshold = 200.0;
    final max = _scrollController.position.maxScrollExtent;
    final cur = _scrollController.position.pixels;
    if (max - cur <= threshold) {
      _fetchLedger(reset: false);
    }
  }

  Future<void> _fetchLedger({bool reset = false}) async {
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

      final payload = {
        'lLicNo': auth.currentUser?.licenseNumber ?? '',
        'lAcNo': widget.accountNo,
        'lFromDate': '',
        'lTillDate': '',
        'lFirmCode': firmCode,
        'lPageNo': _pageNo,
        'lSize': _pageSize,
        'lExecuteTotalRows': 1,
        'lSharePdf': 0,
      };

      debugPrint('[AttachBills] GetAccountLedger payload: ${jsonEncode(payload)}');

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

      final list = (data['Ledger'] as List<dynamic>? ?? []);
      final fetched = list
          .map((e) => _safeMap(e))
          .map((m) => LedgerEntry.fromJson(m))
          .toList();

      if (!mounted) return;
      setState(() {
        _entries.addAll(fetched);
        _hasMore = fetched.length >= _pageSize;
        if (_hasMore) _pageNo += 1;
        _isLoading = false;
        _isLoadingMore = false;
      });

      debugPrint('[AttachBills] Loaded ${fetched.length} bills, total: ${_entries.length}');
    } catch (e) {
      debugPrint('[AttachBills] Error: $e');
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

  void _toggleSelection(int index) {
    setState(() {
      if (_selectedIndices.contains(index)) {
        // Deselecting
        _selectedIndices.remove(index);
        _partialAmounts.remove(index); // Clear partial amount if deselected
      } else {
        // Selecting
        final entry = _entries[index];
        final dr = _toDouble(entry.drAmt);
        final cr = _toDouble(entry.crAmt);
        final amount = dr > 0 ? dr : cr;

        // Calculate what the pending amount would be if we add this bill fully
        final currentPending = _pendingAmount;

        if (amount > currentPending && currentPending > 0) {
          // Partial adjustment needed
          _selectedIndices.add(index);
          _partialAmounts[index] = currentPending; // Only adjust the pending amount
          debugPrint('[AttachBills] Partial adjustment applied: Bill amount=$amount, Adjusted amount=$currentPending');
        } else {
          // Full adjustment
          _selectedIndices.add(index);
          _partialAmounts.remove(index); // Remove any existing partial adjustment
        }
      }
    });
  }

  void _autoAdjust() {
    setState(() {
      _selectedIndices.clear();
      _partialAmounts.clear();

      double remaining = widget.amount;

      // Process bills in sequence (by their original order/index)
      for (int index = 0; index < _entries.length; index++) {
        if (remaining <= 0) break;

        final entry = _entries[index];
        final dr = _toDouble(entry.drAmt);
        final cr = _toDouble(entry.crAmt);
        final amount = dr > 0 ? dr : cr;

        if (amount > 0) {
          if (amount <= remaining) {
            // Full adjustment
            _selectedIndices.add(index);
            remaining -= amount;
          } else {
            // Partial adjustment for the last bill
            _selectedIndices.add(index);
            _partialAmounts[index] = remaining;
            remaining = 0;
          }
        }
      }
    });

    debugPrint('[AttachBills] Auto-adjusted: ${_selectedIndices.length} bills selected, Adjusted: ${_adjustedAmount.toStringAsFixed(2)}, Pending: ${_pendingAmount.toStringAsFixed(2)}');
    debugPrint('[AttachBills] Partial adjustments: $_partialAmounts');
  }

  void _confirmSelection() {
    final selectedBills = _selectedIndices.map((idx) {
      final entry = _entries[idx];
      final dr = _toDouble(entry.drAmt);
      final cr = _toDouble(entry.crAmt);
      final fullAmount = dr > 0 ? dr : cr;

      // Use partial amount if it exists, otherwise use full amount
      final paymentAmount = _partialAmounts.containsKey(idx)
          ? _partialAmounts[idx]!
          : fullAmount;

      return {
        'entryNo': entry.entryNo ?? '',
        'date': entry.date != null ? DateFormat('yyyy-MM-dd').format(entry.date!) : '',
        'amount': fullAmount,
        'outstanding': fullAmount,
        'payment': paymentAmount, // This is the actual adjusted amount
        'keyEntryNo': entry.keyEntryNo ?? '',
        'dueDate': entry.date != null ? DateFormat('yyyy-MM-dd').format(entry.date!) : '',
        'trantype': entry.tranType ?? '',
      };
    }).toList();

    debugPrint('[AttachBills] Returning ${selectedBills.length} selected bills');
    debugPrint('[AttachBills] Bills with partial adjustments: ${_partialAmounts.keys.length}');
    Navigator.pop(context, selectedBills);
  }

  Widget _buildBillRow(LedgerEntry entry, ColorScheme cs, int index) {
    final df = DateFormat('dd/MMM/yyyy');
    final dateStr = entry.date != null ? df.format(entry.date!) : '';
    final dr = _toDouble(entry.drAmt);
    final cr = _toDouble(entry.crAmt);
    final totalAmount = dr > 0 ? dr : cr;
    final isSelected = _selectedIndices.contains(index);
    final isPartial = _partialAmounts.containsKey(index);
    final adjustedAmount = isPartial ? _partialAmounts[index]! : (isSelected ? totalAmount : 0.0);
    final overdueDays = _getOverdueDays(entry.date);

    return Container(
      margin: const EdgeInsets.all(5),
      decoration: BoxDecoration(
        color: cs.primary,
        borderRadius: BorderRadius.circular(5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0),
            blurRadius: 0,
          ),
        ],
      ),
      child: Container(
        margin: const EdgeInsets.all(1),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(5),
        ),
        child: InkWell(
          onTap: () => _toggleSelection(index),
          borderRadius: BorderRadius.circular(5),
          child: Padding(
            padding: const EdgeInsets.all(0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Transaction Type
                Padding(
                  padding: const EdgeInsets.only(left: 5, top: 5, right: 5),
                  child: Text(
                    entry.tranType ?? 'TRANSACTION',
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w400,
                      color: Color(0xFF666666),
                    ),
                  ),
                ),

                // Invoice number, date, and checkbox
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Expanded(
                      child: Row(
                        children: [
                          Padding(
                            padding: const EdgeInsets.only(left: 5, right: 5),
                            child: Text(
                              entry.entryNo ?? '',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w400,
                                color: Color(0xFF666666),
                              ),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.only(right: 5),
                            child: Text(
                              dateStr,
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w400,
                                color: Colors.black87,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Checkbox on the right
                    Padding(
                      padding: const EdgeInsets.only(left: 10, top: 5, right: 10, bottom: 5),
                      child: SizedBox(
                        width: 25,
                        height: 25,
                        child: Checkbox(
                          value: isSelected,
                          onChanged: (_) => _toggleSelection(index),
                          activeColor: cs.primary,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(3),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),

                // Amount section
                Row(
                  children: [
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.only(left: 5, right: 5, bottom: 2),
                        child: Text(
                          '₹${totalAmount.toStringAsFixed(0)}',
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                            color: Colors.red,
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          if (isSelected)
                            Padding(
                              padding: const EdgeInsets.only(left: 10, right: 10),
                              child: Text(
                                '₹${adjustedAmount.toStringAsFixed(0)}',
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w700,
                                  color: isPartial ? Colors.orange[700] : const Color(0xFF666666),
                                ),
                              ),
                            ),
                          Container(
                            margin: const EdgeInsets.only(left: 70, top: 3, bottom: 5, right: 10),
                            height: 0.5,
                            color: Colors.grey,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                // Due date and overdue section
                Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Row(
                    children: [
                      Expanded(
                        child: Row(
                          children: [
                            const Padding(
                              padding: EdgeInsets.only(left: 5, right: 5),
                              child: Text(
                                'Due date:',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.black,
                                ),
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.only(right: 5),
                              child: Text(
                                dateStr,
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.black,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (overdueDays > 0)
                        Expanded(
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              const Padding(
                                padding: EdgeInsets.only(left: 5, right: 5),
                                child: Text(
                                  'Over Due:',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.black,
                                  ),
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.only(right: 5),
                                child: Text(
                                  '$overdueDays Days',
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.black,
                                  ),
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
          ),
        ),
      ),
    );
  }

  void _clearAll() {
    setState(() {
      _selectedIndices.clear();
      _partialAmounts.clear();
    });
  }

  int _getOverdueDays(DateTime? dueDate) {
    if (dueDate == null) return 0;
    final now = DateTime.now();
    final diff = now.difference(dueDate).inDays;
    return diff > 0 ? diff : 0;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        title: const Text(
          "ADD BILLS",
          style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16, letterSpacing: 0.5),
        ),
        centerTitle: false,
        backgroundColor: Colors.white,
        elevation: 1,
        shadowColor: Colors.black.withValues(alpha: 0.1),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, size: 24),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Stack(
        children: [
          Column(
            children: [
              // Adjustment Details Card with nested structure
              Container(
                width: double.infinity,
                margin: const EdgeInsets.only(bottom: 5),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(1),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.1),
                      blurRadius: 5,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Padding(
                  padding: const EdgeInsets.all(10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Adjustment Details',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF666666),
                        ),
                      ),
                      const SizedBox(height: 5),
                      // Nested card with blue border
                      Container(
                        decoration: BoxDecoration(
                          color: colorScheme.primary,
                          borderRadius: BorderRadius.circular(5),
                        ),
                        padding: const EdgeInsets.all(1),
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(5),
                          ),
                          padding: const EdgeInsets.all(5),
                          child: Column(
                            children: [
                              _buildAmountRow('Receipt Amount', widget.amount, true),
                              _buildAmountRow('Adjusted Amount', _adjustedAmount, false),
                              _buildAmountRow('Pending Amount', _pendingAmount, false),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                    ],
                  ),
                ),
              ),

              // Pending Bills Section
              Expanded(
                child: SingleChildScrollView(
                  controller: _scrollController,
                  child: Container(
                    margin: const EdgeInsets.only(top: 5),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(0),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.1),
                          blurRadius: 5,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Padding(
                            padding: EdgeInsets.symmetric(horizontal: 10),
                            child: Text(
                              'Pending Bills',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF666666),
                              ),
                            ),
                          ),
                          const SizedBox(height: 5),
                          // Action buttons
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Container(
                                    margin: const EdgeInsets.only(right: 5),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF4CAF50),
                                      borderRadius: BorderRadius.circular(5),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withValues(alpha: 0.2),
                                          blurRadius: 10,
                                          offset: const Offset(0, 2),
                                        ),
                                      ],
                                    ),
                                    child: Material(
                                      color: Colors.transparent,
                                      child: InkWell(
                                        onTap: _entries.isNotEmpty ? _autoAdjust : null,
                                        borderRadius: BorderRadius.circular(5),
                                        child: const Padding(
                                          padding: EdgeInsets.symmetric(vertical: 5),
                                          child: Text(
                                            'Auto Adjust',
                                            textAlign: TextAlign.center,
                                            style: TextStyle(
                                              fontSize: 12,
                                              fontWeight: FontWeight.w700,
                                              color: Colors.white,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                                Expanded(
                                  child: Container(
                                    margin: const EdgeInsets.only(left: 5),
                                    decoration: BoxDecoration(
                                      color: colorScheme.primary,
                                      borderRadius: BorderRadius.circular(5),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withValues(alpha: 0.2),
                                          blurRadius: 10,
                                          offset: const Offset(0, 2),
                                        ),
                                      ],
                                    ),
                                    child: Material(
                                      color: Colors.transparent,
                                      child: InkWell(
                                        onTap: _selectedIndices.isNotEmpty ? _clearAll : null,
                                        borderRadius: BorderRadius.circular(5),
                                        child: const Padding(
                                          padding: EdgeInsets.symmetric(vertical: 5),
                                          child: Text(
                                            'Clear All',
                                            textAlign: TextAlign.center,
                                            style: TextStyle(
                                              fontSize: 12,
                                              fontWeight: FontWeight.w700,
                                              color: Colors.white,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),

                          // Error message
                          if (_error != null)
                            Container(
                              color: Colors.red[50],
                              padding: const EdgeInsets.all(8),
                              width: double.infinity,
                              child: Text(_error!, style: const TextStyle(color: Colors.red)),
                            ),

                          // Bills List
                          if (_isLoading)
                            const Center(
                              child: Padding(
                                padding: EdgeInsets.all(20),
                                child: CircularProgressIndicator(),
                              ),
                            )
                          else if (_entries.isEmpty)
                            const Center(
                              child: Padding(
                                padding: EdgeInsets.all(20),
                                child: Text(
                                  "No bills found",
                                  style: TextStyle(color: Colors.grey),
                                ),
                              ),
                            )
                          else
                            Column(
                              children: [
                                ListView.builder(
                                  shrinkWrap: true,
                                  physics: const NeverScrollableScrollPhysics(),
                                  padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 5),
                                  itemCount: _entries.length,
                                  itemBuilder: (context, index) {
                                    return _buildBillRow(_entries[index], colorScheme, index);
                                  },
                                ),
                                if (_isLoadingMore)
                                  const Padding(
                                    padding: EdgeInsets.all(16),
                                    child: Center(child: CircularProgressIndicator()),
                                  ),
                              ],
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),

              // Bottom spacing for save button
              const SizedBox(height: 60),
            ],
          ),

          // Bottom Save & Add button (positioned absolutely)
          if (_selectedIndices.isNotEmpty)
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(5),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.1),
                      blurRadius: 3,
                      offset: const Offset(0, -1),
                    ),
                  ],
                ),
                padding: const EdgeInsets.all(10),
                child: Container(
                  decoration: BoxDecoration(
                    color: colorScheme.primary,
                    borderRadius: BorderRadius.circular(5),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.2),
                        blurRadius: 5,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: _confirmSelection,
                      borderRadius: BorderRadius.circular(5),
                      child: const Padding(
                        padding: EdgeInsets.symmetric(vertical: 10),
                        child: Text(
                          'Save & Add',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildAmountRow(String label, double amount, bool isBold) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 14,
              fontWeight: isBold ? FontWeight.w400 : FontWeight.w400,
              color: const Color(0xFF666666),
            ),
          ),
          Text(
            '₹${amount.toStringAsFixed(1)}',
            style: TextStyle(
              fontSize: 15,
              fontWeight: isBold ? FontWeight.w700 : FontWeight.w400,
              color: const Color(0xFF666666),
            ),
          ),
        ],
      ),
    );
  }

}

