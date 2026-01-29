import 'package:flutter/material.dart';
import '../models/ledger_entry_model.dart';

/// Full-screen transaction detail page that fetches detail via provided callback
/// Matches the Android app SaleVoucherFragment UI structure
class TransactionDetailPage extends StatefulWidget {
  final LedgerEntry entry;
  final Future<Map<String, dynamic>?> Function(LedgerEntry) fetchDetail;
  final ColorScheme colorScheme;

  const TransactionDetailPage({
    super.key,
    required this.entry,
    required this.fetchDetail,
    required this.colorScheme,
  });

  @override
  State<TransactionDetailPage> createState() => _TransactionDetailPageState();
}

class _TransactionDetailPageState extends State<TransactionDetailPage> {
  late Future<Map<String, dynamic>?> _future;

  @override
  void initState() {
    super.initState();
    _future = widget.fetchDetail(widget.entry);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        title: const Text('Transaction Details', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 17)),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 1,
      ),
      body: FutureBuilder<Map<String, dynamic>?>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError || snapshot.data == null) {
            final err = snapshot.error ?? 'Unable to fetch transaction details';
            return _errorState(err.toString());
          }

          final result = snapshot.data!;
          if (result.containsKey('error')) {
            return _errorState(result['error'].toString());
          }

          final data = result['data'] ?? result;
          final Map<String, dynamic> d = data is Map<String, dynamic>
              ? data
              : <String, dynamic>{'data': data.toString()};

          // Check transaction type to render appropriate UI
          final tranType = _getValue(d['TranType']).toUpperCase();

          if (tranType == 'RC') {
            // Receipt (RC) transaction
            return _buildReceiptUI(d);
          } else {
            // Sale/Purchase transaction (SALE, PUR, etc.)
            return _buildSaleUI(d);
          }
        },
      ),
    );
  }

  // Receipt (RC) Transaction UI
  Widget _buildReceiptUI(Map<String, dynamic> d) {
    return SingleChildScrollView(
      child: Column(
        children: [
          const SizedBox(height: 12),
          _buildHeaderCard(d),
          const SizedBox(height: 12),
          _buildReceiptDetailsCard(d),
          const SizedBox(height: 24),
          _buildViewBillButton(),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  // Sale/Purchase Transaction UI
  Widget _buildSaleUI(Map<String, dynamic> d) {
    return SingleChildScrollView(
      child: Column(
        children: [
          const SizedBox(height: 12),
          _buildHeaderCard(d),
          const SizedBox(height: 12),
          _buildBillDetailsCard(d),
          const SizedBox(height: 12),
          _buildDispatchDetailsCard(d),
          const SizedBox(height: 24),
          _buildViewBillButton(),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  // Receipt Details Card (for RC transactions)
  Widget _buildReceiptDetailsCard(Map<String, dynamic> d) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Detail Section Title
            const Text(
              'Detail',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 12),
            const Divider(height: 1, thickness: 1, color: Color(0xFFEEEEEE)),
            const SizedBox(height: 12),

            // Receipt Detail Items
            _buildTextRow('Collected By', _getValue(d['CollectedBy'])),
            _buildTextRow('Mode', _getValue(d['MODE'])),
            _buildTextRow('Bank Name', _getValue(d['BankName'])),
            _buildTextRow('Branch', _getValue(d['BranchName'])),
            _buildTextRow('Document No', _getValue(d['DocumentNo'])),
            _buildTextRow('Document Date', _getValue(d['DocumentDate'])),
            _buildTextRow('Amount', _formatAmount(d['Amount'])),

            const SizedBox(height: 16),

            // Adjustment Detail Section
            const Text(
              'Adjustment Detail',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 12),
            const Divider(height: 1, thickness: 1, color: Color(0xFFEEEEEE)),
            const SizedBox(height: 12),

            // Adjustment items - support new `AdjustmentDetail` array or fallbacks
            ..._buildAdjustmentWidgets(d),

            const SizedBox(height: 12),
            const Divider(height: 1, thickness: 2, color: Color(0xFFEEEEEE)),
            const SizedBox(height: 12),

            // Total Amount
            _buildTotalRow('Total Received', d['Amount']),
          ],
        ),
      ),
    );
  }

  // Build adjustment widgets from various possible payload shapes
  List<Widget> _buildAdjustmentWidgets(Map<String, dynamic> d) {
    final List<Widget> rows = [];

    // Case A: new API field 'AdjustmentDetail' => list of objects with Particular and AdjAmt
    if (d.containsKey('AdjustmentDetail') && d['AdjustmentDetail'] is List) {
      final List list = d['AdjustmentDetail'] as List;
      if (list.isNotEmpty) {
        for (final item in list) {
          if (item is Map) {
            final part = item['Particular'] ?? item['particular'] ?? '';
            final adj = item['AdjAmt'] ?? item['Adjamt'] ?? item['adjAmt'] ?? item['adjamt'] ?? 0;
            rows.add(_buildAdjustmentRow(_getValue(part), adj));
          }
        }
        return rows;
      }
    }

    // Case B: older shape - Particular and AdjAmt may be lists or strings
    final partic = d['Particular'];
    final adj = d['AdjAmt'];

    // If both are lists, pair them
    if (partic is List && adj is List) {
      final max = partic.length > adj.length ? partic.length : adj.length;
      for (var i = 0; i < max; i++) {
        final p = i < partic.length ? partic[i] : '';
        final a = i < adj.length ? adj[i] : 0;
        rows.add(_buildAdjustmentRow(_getValue(p), a));
      }
      return rows;
    }

    // If AdjAmt is a list but Particular is single, pair accordingly
    if (partic is String && adj is List) {
      for (var a in adj) {
        rows.add(_buildAdjustmentRow(_getValue(partic), a));
      }
      return rows;
    }

    // If Particular is a list but AdjAmt is single
    if (partic is List && (adj is String || adj is num)) {
      for (var p in partic) {
        rows.add(_buildAdjustmentRow(_getValue(p), adj));
      }
      return rows;
    }

    // If both are comma/newline separated strings, split them
    if (partic is String && adj is String) {
      final parts = partic.split(RegExp(r"[\n,;]+")).map((s) => s.trim()).where((s) => s.isNotEmpty).toList();
      final amts = adj.split(RegExp(r"[\n,;]+")).map((s) => s.trim()).where((s) => s.isNotEmpty).toList();
      final max = parts.length > amts.length ? parts.length : amts.length;
      for (var i = 0; i < max; i++) {
        final p = i < parts.length ? parts[i] : '';
        final aStr = i < amts.length ? amts[i] : '0';
        final a = double.tryParse(aStr.replaceAll(',', '')) ?? 0.0;
        rows.add(_buildAdjustmentRow(_getValue(p), a));
      }
      return rows;
    }

    // Fallback: single pair
    rows.add(_buildAdjustmentRow(_getValue(partic), adj));
    return rows;
  }

  // Header Section - Account Information Card
  Widget _buildHeaderCard(Map<String, dynamic> d) {
    final tranType = _getValue(d['TranType']).toUpperCase();
    final isReceipt = tranType == 'RC';

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Firm Name (acc_name)
            Text(
              _getValue(d['NAME']),
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 12),

            // Transaction Type Badge (transection_type)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: const Color(0xFFE8F5E9),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                isReceipt ? 'Receipt Voucher' : _getValue(d['TranType']),
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF2E7D32),
                ),
              ),
            ),
            const SizedBox(height: 12),

            // Bill Number/Receipt Voucher and Date
            _buildInfoRow(isReceipt ? 'Receipt Voucher' : 'Bill No', _getValue(d['Number'])),
            const Divider(height: 20, color: Color(0xFFEEEEEE)),
            _buildInfoRow(isReceipt ? 'Paid' : 'Date', _getValue(d['Date'])),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 13,
            color: Colors.black54,
            fontWeight: FontWeight.w500,
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
      ],
    );
  }

  // Bill Details Section Card
  Widget _buildBillDetailsCard(Map<String, dynamic> d) {
    // Build items list dynamically
    List<Map<String, dynamic>> items = [];

    // Add basic items - show all fields including 0 values
    items.add({'title': 'Goods Value', 'value': d['ITEMAMT'] ?? 0});
    items.add({'title': 'Scheme', 'value': d['ASchemeAmt'] ?? 0});
    items.add({'title': 'Product Discount', 'value': d['DISCAMT'] ?? 0});
    items.add({'title': 'Bill Discount', 'value': d['BILLDISC'] ?? 0});

    // Add taxable value
    items.add({'title': 'Taxable Value', 'value': d['TAXABLE'] ?? 0});

    // Tax fields mapping:
    // SGST -> TAXAMT
    // CGST -> ATAXAMT (fallback to OTAXAMT)
    // If ATAXAMT == 0 then show IGST instead of SGST (IGST = TAXAMT)
    final taxAmt = _toDouble(d['TAXAMT']);
    final aTaxAmt = _toDouble(d['ATAXAMT'] ?? d['OTAXAMT']);

    if (aTaxAmt == 0.0) {
      // Inter-state: show IGST (use TAXAMT)
      items.add({'title': 'IGST', 'value': taxAmt});
    } else {
      // Intra-state: show SGST (TAXAMT) and CGST (ATAXAMT)
      items.add({'title': 'SGST', 'value': taxAmt});
      items.add({'title': 'CGST', 'value': aTaxAmt});
    }

    // Add other tax items - show all including 0 values
    items.add({'title': 'Cess', 'value': d['EDUCESS'] ?? 0});
    items.add({'title': 'Special Cess', 'value': d['HEDUCESS'] ?? 0});

    // Add TCS, Add/Less, Round Off - show all
    items.add({'title': 'TCS', 'value': d['Tcs'] ?? 0});
    items.add({'title': 'Add/Less', 'value': d['AddLess'] ?? 0});
    items.add({'title': 'Round Off', 'value': d['RoundAmt'] ?? 0});

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Section Title
            const Text(
              'Bill Details',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 12),
            const Divider(height: 1, thickness: 1, color: Color(0xFFEEEEEE)),
            const SizedBox(height: 12),

            // Dynamic items list
            ...items.map((item) => _buildDetailRow(item['title'], item['value'])),

            const SizedBox(height: 12),
            const Divider(height: 1, thickness: 2, color: Color(0xFFEEEEEE)),
            const SizedBox(height: 12),

            // Total Amount Row (matching total section from Android)
            _buildTotalRow('Total Value', d['BillAmt']),
          ],
        ),
      ),
    );
  }

  // Dispatch Details Section Card
  Widget _buildDispatchDetailsCard(Map<String, dynamic> d) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Section Title
            const Text(
              'Dispatch Details',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 12),
            const Divider(height: 1, thickness: 1, color: Color(0xFFEEEEEE)),
            const SizedBox(height: 12),

            // Dispatch Detail Items (matching Android app structure)
            _buildTextRow('Delivery By', _getValue(d['DeliverdBy'])),
            _buildTextRow('Transporter', _getValue(d['TransporterName'])),
            _buildTextRow('LR No', _getValue(d['LRNO'])),
            _buildTextRow('LR Date', _getValue(d['LRDate'])),
            _buildTextRow('No Of Cases', _getValue(d['NoOfCase'])),
            _buildTextRow('E-Way Bill No', _getValue(d['EwayBill'])),
          ],
        ),
      ),
    );
  }

  // Detail Row for Bill Details (with rupee symbol)
  Widget _buildDetailRow(String label, dynamic value) {
    final amount = _formatAmount(value);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 2,
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w400,
                color: Colors.black87,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Text(
            '₹$amount',
            textAlign: TextAlign.right,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
        ],
      ),
    );
  }

  // Text Row for Dispatch Details (without rupee symbol)
  Widget _buildTextRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 2,
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w400,
                color: Colors.black87,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Total Row (highlighted, matching Android total section)
  Widget _buildTotalRow(String label, dynamic value) {
    final amount = _formatAmount(value);

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFF5F5F5),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text(
            'Total Value',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: Colors.black87,
            ),
          ),
          Text(
            '₹$amount',
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: Colors.black87,
            ),
          ),
        ],
      ),
    );
  }

  // Adjustment Row (for receipt adjustments) - kept as separate method for reuse
  Widget _buildAdjustmentRow(String particular, dynamic adjAmount) {
    final amount = _formatAmount(adjAmount);
    final displayPart = particular.trim().isEmpty ? '-' : (particular.startsWith('*') ? particular : '*$particular');

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 2,
            child: Text(
              displayPart,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w400,
                color: Colors.black87,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Text(
            '₹${amount}',
            textAlign: TextAlign.right,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
        ],
      ),
    );
  }

  String _getValue(dynamic value) {
    if (value == null) return '-';
    final str = value.toString().trim();
    if (str.isEmpty || str.toLowerCase() == 'null') return '-';
    return str;
  }

  String _formatAmount(dynamic value) {
    if (value == null) return '0.0';

    final str = value.toString().trim();
    if (str.isEmpty || str.toLowerCase() == 'null') return '0.0';

    final numVal = num.tryParse(str);
    if (numVal != null) {
      // Format with 2 decimal places
      return numVal.toStringAsFixed(2);
    }

    return '0.0';
  }

  // Helper to convert dynamic value to double
  double _toDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is double) return value;
    if (value is int) return value.toDouble();

    final str = value.toString().trim();
    if (str.isEmpty || str.toLowerCase() == 'null') return 0.0;

    return double.tryParse(str) ?? 0.0;
  }

  Widget _errorState(String message) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, color: Colors.red, size: 48),
            const SizedBox(height: 16),
            const Text(
              'Error',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.black54,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.black87,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              child: const Text('Close'),
            ),
          ],
        ),
      ),
    );
  }

  // View Bill Button
  Widget _buildViewBillButton() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12),
      width: double.infinity,
      child: ElevatedButton(
        onPressed: () {
          // TODO: Implement view bill functionality
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('View Bill feature coming soon')),
          );
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF1976D2),
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          elevation: 0,
        ),
        child: const Text(
          'View Bill',
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.5,
          ),
        ),
      ),
    );
  }
}
