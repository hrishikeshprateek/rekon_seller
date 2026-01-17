import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';
import 'dart:io';
import 'dart:typed_data';
import 'package:path_provider/path_provider.dart';
import 'package:cross_file/cross_file.dart';

import '../auth_service.dart';
import '../models/account_model.dart';
import '../models/ledger_entry_model.dart';
import 'select_account_page.dart';
import 'outstanding_details_page.dart';

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

  // Data
  double _openingBalance = 0;
  double _closingBalance = 0;
  final List<LedgerEntry> _entries = [];

  // Paging
  static const int _pageSize = 50;
  int _pageNo = 1;
  bool _hasMore = true;

  // UI state
  bool _isLoading = false;
  bool _isLoadingMore = false;
  String? _error;

  // FAB state
  bool _fabExpanded = false;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    // Automatically open select account page when statement page is opened directly
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _pickAccount();
    });
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

  Future<void> _pickAccount() async {
    final account = await SelectAccountPage.show(context,
        title: 'Select Party', showBalance: true);
    if (account != null && mounted) {
      setState(() {
        _selectedAccount = account;
      });
      await _fetchLedger(reset: true);
    }
  }

  Future<void> _pickFromDate() async {
    final now = DateTime.now();
    final initial = _fromDate ?? now.subtract(const Duration(days: 30));
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(now.year - 5),
      lastDate: DateTime(now.year + 1),
    );
    if (picked != null && mounted) {
      setState(() => _fromDate = picked);
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
      setState(() => _toDate = picked);
      await _fetchLedger(reset: true);
    }
  }

  Future<void> _fetchLedger({bool reset = false}) async {
    if (_selectedAccount == null) {
      if (mounted) {
        setState(() {
          _openingBalance = 0;
          _closingBalance = 0;
          _entries.clear();
          _error = null;
          _hasMore = false;
        });
      }
      return;
    }

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
            orElse: () =>
            stores.isNotEmpty ? stores.first : (throw 'no_store'));
        firmCode = primary.firmCode;
      } catch (_) {
        firmCode = '';
      }

      final df = DateFormat('yyyy-MM-dd');
      final from = _fromDate != null ? df.format(_fromDate!) : '';
      final till = _toDate != null ? df.format(_toDate!) : '';

      final accountCode = _selectedAccount!.code ?? _selectedAccount!.id;

      final payload = {
        'lLicNo': auth.currentUser?.licenseNumber ?? '',
        'lAcNo': accountCode,
        'lFromDate': from,
        'lTillDate': till,
        'lFirmCode': firmCode,
        'lPageNo': _pageNo,
        'lSize': _pageSize,
        'lExecuteTotalRows': 1,
        'lSharePdf': 0,
      };

      debugPrint('[Statement] Payload: ${jsonEncode(payload)}');

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
      debugPrint('[Statement] Error: $e');
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

  // --- ACCOUNT DETAILS (BOTTOM SHEET + SHARE) ---

  String _formatAccountShareText(Account account) {
    final lines = <String>[];

    void add(String label, String? value) {
      final v = (value ?? '').trim();
      if (v.isEmpty) return;
      lines.add('$label: $v');
    }

    // Name first
    final name = account.name.trim();
    if (name.isNotEmpty) lines.add(name);

    add('Account ID', account.id);
    add('Account Code', account.code);
    add('Type', account.type);
    add('Mobile', account.phone);
    add('Email', account.email);
    add('Address', account.address);
    add('GSTIN', account.gstNumber);

    if (account.closBal != null) {
      final bal = account.closBal!;
      lines.add('Balance: ₹${bal.abs().toStringAsFixed(2)} ${bal < 0 ? 'Dr' : 'Cr'}');
    } else if (account.balance != null) {
      add('Balance', '₹${account.balance}');
    }

    return lines.join('\n');
  }

  void _showSelectedAccountDetailsSheet(Account account) {
    final cs = Theme.of(context).colorScheme;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        minChildSize: 0.4,
        maxChildSize: 0.9,
        builder: (_, controller) => Container(
          decoration: BoxDecoration(
            color: cs.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: SafeArea(
            top: false,
            child: Column(
              children: [
                Container(
                  margin: const EdgeInsets.only(top: 12, bottom: 14),
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: cs.outlineVariant,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                Expanded(
                  child: ListView(
                    controller: controller,
                    padding: const EdgeInsets.symmetric(horizontal: 18),
                    children: [
                      Text(
                        account.name,
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
                        textAlign: TextAlign.center,
                      ),
                      if (account.type.trim().isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Center(child: Chip(label: Text(account.type))),
                      ],
                      const SizedBox(height: 16),

                      _accountDetailRow('Account ID', account.id, cs),
                      _accountDetailRow('Account Code', account.code, cs),
                      _accountDetailRow('Mobile', account.phone, cs),
                      _accountDetailRow('Email', account.email, cs),
                      _accountDetailRow('Address', account.address, cs, multiline: true),
                      _accountDetailRow('GSTIN', account.gstNumber, cs),
                      if (account.closBal != null)
                        _accountDetailRow(
                          'Balance',
                          '₹${account.closBal!.abs().toStringAsFixed(2)} ${account.closBal! < 0 ? 'Dr' : 'Cr'}',
                          cs,
                        )
                      else
                        _accountDetailRow('Balance', account.balance?.toString(), cs),

                      const SizedBox(height: 20),

                      Row(
                        children: [
                          Expanded(
                            child: SizedBox(
                              height: 46,
                              child: OutlinedButton.icon(
                                onPressed: () async {
                                  final text = _formatAccountShareText(account);
                                  try {
                                    await Share.share(text, subject: account.name);
                                  } catch (_) {
                                    await Clipboard.setData(ClipboardData(text: text));
                                    if (mounted) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(content: Text('Could not open share sheet. Details copied to clipboard.')),
                                      );
                                    }
                                  }
                                },
                                icon: const Icon(Icons.share_outlined, size: 18),
                                label: const Text('Share'),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: SizedBox(
                              height: 46,
                              child: FilledButton(
                                onPressed: () => Navigator.pop(ctx),
                                child: const Text('Close'),
                              ),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 16),
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

  Widget _accountDetailRow(String label, String? value, ColorScheme cs, {bool multiline = false}) {
    final v = (value ?? '').trim();
    if (v.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: multiline ? CrossAxisAlignment.start : CrossAxisAlignment.center,
        children: [
          SizedBox(
            width: 110,
            child: Text(
              label,
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: cs.onSurfaceVariant),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              v,
              style: TextStyle(fontSize: 12, color: cs.onSurface),
              textAlign: TextAlign.right,
            ),
          ),
        ],
      ),
    );
  }

  // --- COMPACT UI WIDGETS ---

  Widget _buildFilterBar(ColorScheme colorScheme) {
    Color balanceColor = colorScheme.onSurfaceVariant;

    if (_selectedAccount != null) {
      final bal = _selectedAccount!.closBal ?? 0;
      balanceColor = bal >= 0 ? const Color(0xFF1B5E20) : const Color(0xFFB71C1C);
    }

    final balanceText = _selectedAccount != null ? 'Bal: ₹${_selectedAccount!.closBal?.abs().toStringAsFixed(2) ?? '0.00'} ${_selectedAccount!.closBal != null && _selectedAccount!.closBal! < 0 ? 'Dr' : 'Cr'}' : '';

    return Container(
      color: colorScheme.surface,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Column(
        children: [
          // Account Selector + Info button OUTSIDE
          Row(
            children: [
              Expanded(
                child: InkWell(
                  onTap: _pickAccount,
                  borderRadius: BorderRadius.circular(6),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
                    decoration: BoxDecoration(
                      color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: colorScheme.outlineVariant),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.person, size: 24, color: colorScheme.primary),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                _selectedAccount?.name ?? 'Select Account',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: _selectedAccount == null
                                      ? colorScheme.onSurfaceVariant
                                      : colorScheme.onSurface,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              if (_selectedAccount != null) ...[
                                const SizedBox(height: 2),
                                RichText(
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  text: TextSpan(
                                    style: TextStyle(fontSize: 12, color: colorScheme.onSurfaceVariant),
                                    children: [
                                      WidgetSpan(
                                        child: Icon(Icons.phone_android, size: 12, color: Colors.grey),
                                        alignment: PlaceholderAlignment.baseline,
                                        baseline: TextBaseline.alphabetic,
                                      ),
                                      TextSpan(text: ' ${_selectedAccount?.phone ?? "-"}   '),
                                      TextSpan(
                                        text: balanceText,
                                        style: TextStyle(
                                          fontWeight: FontWeight.w700,
                                          color: balanceColor,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                        Icon(Icons.arrow_drop_down, size: 18, color: colorScheme.onSurfaceVariant),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                visualDensity: VisualDensity.compact,
                constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
                onPressed: _selectedAccount == null
                    ? null
                    : () {
                        final acc = _selectedAccount;
                        if (acc == null) return;
                        _showSelectedAccountDetailsSheet(acc);
                      },
                icon: Icon(Icons.info_outline, size: 22, color: _selectedAccount == null ? colorScheme.outline : colorScheme.primary),
                tooltip: 'Account details',
              ),
            ],
          ),

          const SizedBox(height: 8),
          // Date Pickers
          Row(
            children: [
              Expanded(
                child: _buildCompactDateBtn(
                  label: 'Start',
                  date: _fromDate,
                  onTap: _pickFromDate,
                  colorScheme: colorScheme,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildCompactDateBtn(
                  label: 'End',
                  date: _toDate,
                  onTap: _pickToDate,
                  colorScheme: colorScheme,
                ),
              ),
              const SizedBox(width: 8),
              SizedBox(
                height: 36,
                child: OutlinedButton.icon(
                  onPressed: _selectedAccount == null ? null : _openOutstanding,
                  icon: const Icon(Icons.receipt_long_outlined, size: 16),
                  label: const Text('Outstanding'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    textStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCompactDateBtn({
    required String label,
    required DateTime? date,
    required VoidCallback onTap,
    required ColorScheme colorScheme,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(6),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        decoration: BoxDecoration(
          border: Border.all(color: colorScheme.outlineVariant),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Row(
          children: [
            Text('$label: ', style: TextStyle(fontSize: 11, color: colorScheme.onSurfaceVariant)),
            Expanded(
              child: Text(
                date != null ? DateFormat('dd/MM/yy').format(date) : '-',
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Icon(Icons.calendar_today, size: 12, color: colorScheme.primary),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryCard(ColorScheme colorScheme) {
    if (_selectedAccount == null) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.fromLTRB(12, 4, 12, 8),
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
      decoration: BoxDecoration(
        color: colorScheme.secondaryContainer.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: colorScheme.outlineVariant.withValues(alpha: 0.6)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _buildBalanceItem('Open', _openingBalance, colorScheme),
          Container(width: 1, height: 24, color: colorScheme.outlineVariant),
          _buildBalanceItem('Close', _closingBalance, colorScheme, isBold: true),
        ],
      ),
    );
  }

  Widget _buildBalanceItem(String title, double amount, ColorScheme cs, {bool isBold = false}) {
    final color = amount >= 0 ? const Color(0xFF1B5E20) : const Color(0xFFB71C1C);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.baseline,
      textBaseline: TextBaseline.alphabetic,
      children: [
        Text(
          '$title: ',
          style: TextStyle(fontSize: 11, color: cs.onSurfaceVariant),
        ),
        Text(
          '₹${amount.abs().toStringAsFixed(2)} ${amount < 0 ? 'Dr' : 'Cr'}',
          style: TextStyle(
            fontSize: 14,
            fontWeight: isBold ? FontWeight.w800 : FontWeight.w600,
            color: color,
          ),
        ),
      ],
    );
  }

  Widget _buildTransactionRow(LedgerEntry entry, ColorScheme cs) {
    final df = DateFormat('dd/MM/yyyy');
    final dateStr = entry.date != null ? df.format(entry.date!) : (entry.tranId ?? '');

    final dr = _toDouble(entry.drAmt);
    final cr = _toDouble(entry.crAmt);
    final isCredit = cr > 0;
    final amount = isCredit ? cr : dr;
    final runningAmount = _toDouble(entry.runningAmt);

    final amtColor = isCredit ? const Color(0xFF1B5E20) : const Color(0xFFB71C1C);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: cs.surfaceContainerLow,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.3)),
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          tilePadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          childrenPadding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
          leading: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: amtColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Center(
              child: Icon(
                isCredit ? Icons.arrow_downward : Icons.arrow_upward,
                color: amtColor,
                size: 20,
              ),
            ),
          ),
          title: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      entry.tranType ?? 'TRANSACTION',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: cs.primary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Bill No: ${(entry.entryNo)} ',
                      style: TextStyle(
                        fontSize: 11,
                        color: cs.onSurfaceVariant,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '₹${amount.toStringAsFixed(2)}',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      color: amtColor,
                    ),
                  ),
                  Text(
                    isCredit ? 'Credit' : 'Debit',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: amtColor.withValues(alpha: 0.7),
                    ),
                  ),
                ],
              ),
            ],
          ),
          subtitle: Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(
              dateStr,
              style: TextStyle(fontSize: 10, color: cs.onSurfaceVariant),
            ),
          ),
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: cs.surfaceContainerHighest.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Column(
                children: [
                  _buildDetailRow('Entry No', entry.entryNo ?? '-', cs),
                  _buildDetailRow('Voucher Number', entry.vchNumber ?? '-', cs),
                  _buildDetailRow('Transaction Number', entry.tranNumber ?? '-', cs),
                  _buildDetailRow('Key Entry No', entry.keyEntryNo ?? '-', cs),
                  _buildDetailRow('Transaction ID', entry.tranId ?? '-', cs),
                  _buildDetailRow('Transaction Firm', entry.tranFirm ?? '-', cs),
                  _buildDetailRow('Date', dateStr, cs),

                  const Divider(height: 16),

                  Row(
                    children: [
                      Expanded(
                        child: _buildAmountCard('Debit', dr, const Color(0xFFB71C1C), cs),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _buildAmountCard('Credit', cr, const Color(0xFF1B5E20), cs),
                      ),
                    ],
                  ),

                  const SizedBox(height: 8),

                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: cs.primaryContainer.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: cs.primary.withValues(alpha: 0.3)),
                    ),
                    child: Column(
                      children: [
                        Text(
                          'Running Balance',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: cs.onSurfaceVariant,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '₹${runningAmount.abs().toStringAsFixed(2)} ${runningAmount < 0 ? 'Dr' : 'Cr'}',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: runningAmount >= 0 ? const Color(0xFF1B5E20) : const Color(0xFFB71C1C),
                          ),
                        ),
                      ],
                    ),
                  ),

                  if (entry.rCount != null) ...[
                    const SizedBox(height: 8),
                    _buildDetailRow('Record Count', entry.rCount.toString(), cs),
                  ],

                  if (entry.keyEntrySrNo != null)
                    _buildDetailRow('Key Entry Sr No', entry.keyEntrySrNo.toString(), cs),

                  if (entry.isEntryRecord != null)
                    _buildDetailRow('Is Entry Record', entry.isEntryRecord.toString(), cs),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, ColorScheme cs) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: cs.onSurfaceVariant,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 11,
                color: cs.onSurface,
              ),
              textAlign: TextAlign.right,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAmountCard(String label, double amount, Color color, ColorScheme cs) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: cs.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '₹${amount.toStringAsFixed(2)}',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  // Helper: download PDF from GetOutstandingDetails (lSharePdf=1) and open share sheet
  Future<void> _downloadAndSharePdf({required Account acc, bool preferWhatsapp = false}) async {
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
      } else {
        // Try to parse common JSON wrappers or base64 strings
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
      final file = File('${dir.path}/statement_${acc.id}_${DateTime.now().millisecondsSinceEpoch}.pdf');
      await file.writeAsBytes(bytes, flush: true);

      final xfile = XFile(file.path, mimeType: 'application/pdf');

      // Show share sheet. User can pick WhatsApp from the UI if available.
      await Share.shareXFiles([xfile], text: acc.name);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not fetch/share PDF: $e')),
        );
      }
    }
  }

  Future<void> _shareSelectedAccount() async {
    final acc = _selectedAccount;
    if (acc == null) return;

    await _downloadAndSharePdf(acc: acc, preferWhatsapp: false);
  }

  Future<void> _shareSelectedAccountOnWhatsapp() async {
    final acc = _selectedAccount;
    if (acc == null) return;

    await _downloadAndSharePdf(acc: acc, preferWhatsapp: true);
  }

  Widget _buildExpandableFab(ColorScheme cs) {
    final canShare = _selectedAccount != null;

    return Stack(
      alignment: Alignment.bottomRight,
      children: [
        // NOTE: Dimming is handled by the full-page ModalBarrier in the Scaffold body.
        // Keeping this stack overlay-free avoids double-dimming behind the FAB.
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
                                  await _shareSelectedAccountOnWhatsapp();
                                }
                              : null,
                          cs: cs,
                        ),
                        const SizedBox(height: 10),
                        _fabAction(
                          label: 'Share',
                          icon: Icons.share_outlined,
                          onTap: canShare
                              ? () async {
                                  setState(() => _fabExpanded = false);
                                  await _shareSelectedAccount();
                                }
                              : null,
                          cs: cs,
                        ),
                        const SizedBox(height: 10),
                      ],
                    ),
            ),
            FloatingActionButton(
              heroTag: 'statement-fab',
              onPressed: () => setState(() => _fabExpanded = !_fabExpanded),
              backgroundColor: cs.primary,
              foregroundColor: cs.onPrimary,
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

  Widget _fabAction({
    required String label,
    required IconData icon,
    required VoidCallback? onTap,
    required ColorScheme cs,
  }) {
    final enabled = onTap != null;
    final iconToUse = icon;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: cs.surface,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.8)),
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
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: enabled ? cs.onSurface : cs.onSurfaceVariant,
            ),
          ),
        ),
        const SizedBox(width: 10),
        Material(
          color: enabled ? cs.secondaryContainer : cs.surfaceContainerHighest,
          shape: const CircleBorder(),
          child: InkWell(
            customBorder: const CircleBorder(),
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Icon(
                iconToUse,
                size: 20,
                color: enabled ? cs.onSecondaryContainer : cs.onSurfaceVariant,
              ),
            ),
          ),
        ),
      ],
    );
  }

  void _openOutstanding() {
    final acc = _selectedAccount;
    if (acc == null) return;

    // OutstandingDetailsPage expects an account number.
    // In other parts of the app we pass `account.id`, so keep it consistent.
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => OutstandingDetailsPage(
          accountNo: acc.id,
          accountName: acc.name,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    // Keep some space so the last ledger entry isn't hidden behind the FAB.
    // (Accounts for main FAB + the expanded actions stack.)
    const double _listBottomPadding = 140;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        title: const Text('Account Statement', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
        centerTitle: true,
        backgroundColor: colorScheme.surface,
        scrolledUnderElevation: 2,
        toolbarHeight: 48,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, size: 22),
            onPressed: () => _fetchLedger(reset: true),
          ),
        ],
      ),
      floatingActionButton: _buildExpandableFab(colorScheme),
      body: Stack(
        children: [
          Column(
            children: [
              _buildFilterBar(colorScheme),

              if (_error != null)
                Container(
                  width: double.infinity,
                  color: colorScheme.errorContainer,
                  padding: const EdgeInsets.all(8),
                  child: Text(
                    _error!,
                    style: TextStyle(color: colorScheme.onErrorContainer, fontSize: 11),
                    textAlign: TextAlign.center,
                  ),
                ),

              if (_selectedAccount != null) ...[
                _buildSummaryCard(colorScheme),
              ],

              Expanded(
                child: _isLoading
                    ? const Center(child: SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2)))
                    : _selectedAccount == null
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.receipt_long_outlined, size: 48, color: colorScheme.outline.withValues(alpha: 0.5)),
                                const SizedBox(height: 12),
                                Text(
                                  'Select a party',
                                  style: TextStyle(color: colorScheme.onSurfaceVariant, fontSize: 14),
                                ),
                              ],
                            ),
                          )
                        : RefreshIndicator(
                            onRefresh: () => _fetchLedger(reset: true),
                            child: ListView.builder(
                              controller: _scrollController,
                              padding: const EdgeInsets.only(bottom: _listBottomPadding),
                              itemCount: _entries.length + (_isLoadingMore ? 1 : 0) + 1,
                              itemBuilder: (context, index) {
                                // Extra spacer at the end.
                                if (index == _entries.length + (_isLoadingMore ? 1 : 0)) {
                                  return const SizedBox(height: _listBottomPadding);
                                }

                                if (_isLoadingMore && index == _entries.length) {
                                  return const Padding(
                                    padding: EdgeInsets.all(12.0),
                                    child: Center(child: SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))),
                                  );
                                }

                                return _buildTransactionRow(_entries[index], colorScheme);
                              },
                            ),
                          ),
              ),
            ],
          ),

          // Full-page dim overlay when expanded (covers filter + list). FAB stays above as it's outside body.
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
        ],
      ),
    );
  }
}
