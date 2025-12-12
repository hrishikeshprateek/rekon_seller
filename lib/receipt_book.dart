import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'pages/receipt_details_page.dart'; // Import the new page

class ReceiptBookPage extends StatefulWidget {
  const ReceiptBookPage({super.key});

  @override
  State<ReceiptBookPage> createState() => _ReceiptBookPageState();
}

class _ReceiptBookPageState extends State<ReceiptBookPage> {
  // --- STATE VARIABLES ---
  String _selectedAccount = 'All Accounts';
  String _selectedMode = 'All Modes';
  DateTimeRange? _selectedDateRange;

  // Mock Data Source
  final List<Map<String, dynamic>> _allReceipts = List.generate(20, (i) => {
    'id': 'RCPT-${1000 + i}',
    'party': 'Party Name ${i + 1}',
    'amount': (500 + i * 150),
    'mode': ['Cash', 'UPI', 'Cheque', 'NEFT'][i % 4],
    'account': ['Cash Account', 'HDFC Bank', 'SBI Bank'][i % 3],
    'docNo': 'INV-2025-${800 + i}',
    'docDate': DateTime.now().subtract(Duration(days: i + 2)),
    'entryDate': DateTime.now().subtract(Duration(days: i)),
    'narration': 'Payment received for invoice #${800 + i}. Thank you.',
  });

  // --- FILTERS & LOGIC ---
  List<String> get _accountOptions => ['All Accounts', 'Cash Account', 'HDFC Bank', 'SBI Bank'];
  List<String> get _modeOptions => ['All Modes', 'Cash', 'UPI', 'Cheque', 'NEFT'];

  List<Map<String, dynamic>> get _filteredReceipts {
    return _allReceipts.where((r) {
      final matchAccount = _selectedAccount == 'All Accounts' || r['account'] == _selectedAccount;
      final matchMode = _selectedMode == 'All Modes' || r['mode'] == _selectedMode;
      return matchAccount && matchMode;
    }).toList();
  }

  double get _totalAmount {
    return _filteredReceipts.fold(0, (sum, item) => sum + (item['amount'] as int));
  }

  Future<void> _pickDateRange() async {
    final DateTimeRange? picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(primary: Theme.of(context).colorScheme.primary),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() => _selectedDateRange = picked);
    }
  }

  // --- NAVIGATION LOGIC ---
  void _openDetails(BuildContext context, Map<String, dynamic> receipt) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ReceiptDetailsPage(receipt: receipt),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final receipts = _filteredReceipts;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        title: const Text(
          'Receipt Book',
          style: TextStyle(fontWeight: FontWeight.w700, fontSize: 20),
        ),
        centerTitle: true,
        backgroundColor: colorScheme.surface,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 22),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Column(
        children: [
          // --- FILTERS ---
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: colorScheme.surface,
              border: Border(bottom: BorderSide(color: colorScheme.outlineVariant.withOpacity(0.2))),
            ),
            child: Row(
              children: [
                Expanded(
                  child: _buildFilterDropdown(
                    context,
                    value: _selectedAccount,
                    items: _accountOptions,
                    onChanged: (v) => setState(() => _selectedAccount = v!),
                    icon: Icons.account_balance_wallet_outlined,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildFilterDropdown(
                    context,
                    value: _selectedMode,
                    items: _modeOptions,
                    onChanged: (v) => setState(() => _selectedMode = v!),
                    icon: Icons.payment_outlined,
                  ),
                ),
              ],
            ),
          ),

          // --- LIST ---
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              itemCount: receipts.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final receipt = receipts[index];
                return _buildReceiptCard(context, receipt);
              },
            ),
          ),

          const SizedBox(height: 80),
        ],
      ),

      floatingActionButton: FloatingActionButton(
        onPressed: _pickDateRange,
        backgroundColor: colorScheme.primary,
        foregroundColor: colorScheme.onPrimary,
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: const Icon(Icons.calendar_month_rounded),
      ),

      bottomSheet: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
        decoration: BoxDecoration(
          color: colorScheme.surfaceContainerLow,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 12,
              offset: const Offset(0, -4),
            ),
          ],
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Row(
          children: [
            Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Total Amount",
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  "₹${NumberFormat('#,##0').format(_totalAmount)}",
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: colorScheme.primary,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // --- WIDGET HELPERS ---

  Widget _buildFilterDropdown(BuildContext context, {
    required String value,
    required List<String> items,
    required ValueChanged<String?> onChanged,
    required IconData icon,
  }) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      height: 48,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colorScheme.outlineVariant.withOpacity(0.4)),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          isExpanded: true,
          icon: Icon(Icons.keyboard_arrow_down_rounded, size: 22, color: colorScheme.onSurfaceVariant),
          style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: colorScheme.onSurface),
          items: items.map((e) => DropdownMenuItem(
            value: e,
            child: Row(
              children: [
                Icon(icon, size: 18, color: colorScheme.primary.withOpacity(0.8)),
                const SizedBox(width: 8),
                Expanded(child: Text(e, overflow: TextOverflow.ellipsis)),
              ],
            ),
          )).toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }

  Widget _buildReceiptCard(BuildContext context, Map<String, dynamic> receipt) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colorScheme.outlineVariant.withOpacity(0.3)),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 8, offset: const Offset(0, 3)),
        ],
      ),
      child: InkWell(
        onTap: () => _openDetails(context, receipt), // Navigation Logic
        borderRadius: BorderRadius.circular(16),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        receipt['party'],
                        style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16, color: colorScheme.onSurface),
                        maxLines: 1, overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: colorScheme.surfaceContainerHighest.withOpacity(0.5),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          receipt['id'],
                          style: TextStyle(fontSize: 11, color: colorScheme.onSurfaceVariant, fontWeight: FontWeight.w600),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  "₹${NumberFormat('#,##0').format(receipt['amount'])}",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: colorScheme.primary),
                ),
              ],
            ),

            const SizedBox(height: 16),
            Divider(height: 1, color: colorScheme.outlineVariant.withOpacity(0.3)),
            const SizedBox(height: 16),

            Row(
              children: [
                Expanded(
                  flex: 3,
                  child: _buildCardDetailItem(context, "Mode", receipt['mode'], Icons.payment),
                ),
                Expanded(
                  flex: 3,
                  child: _buildCardDetailItem(context, "Doc Date", DateFormat('dd MMM').format(receipt['docDate']), Icons.calendar_today),
                ),
                Expanded(
                  flex: 3,
                  child: _buildCardDetailItem(context, "Doc No", receipt['docNo'], Icons.description, alignEnd: true),
                ),
              ],
            )
          ],
        ),
      ),
    );
  }

  Widget _buildCardDetailItem(BuildContext context, String label, String value, IconData icon, {bool alignEnd = false}) {
    final colorScheme = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: alignEnd ? CrossAxisAlignment.end : CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (!alignEnd) Icon(icon, size: 14, color: colorScheme.onSurfaceVariant),
            if (!alignEnd) const SizedBox(width: 4),
            Text(label, style: TextStyle(fontSize: 11, color: colorScheme.onSurfaceVariant, fontWeight: FontWeight.w500)),
            if (alignEnd) const SizedBox(width: 4),
            if (alignEnd) Icon(icon, size: 14, color: colorScheme.onSurfaceVariant),
          ],
        ),
        const SizedBox(height: 4),
        Text(value, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: colorScheme.onSurface.withOpacity(0.9))),
      ],
    );
  }
}