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

          // Debug: print the parsed transaction payload so we can verify available keys
          try { debugPrint('TransactionDetail parsed payload: ${d}'); } catch (_) {}

          // Determine transaction type (prefer explicit keys, else infer from payload)
          final rawTran = d['TranType'] ?? d['tran_type'] ?? d['tranType'] ?? d['TranType'];
          // If API didn't provide tran type, fallback to ledger entry's tranType
          final entryTran = widget.entry.tranType;
          final rawTranCandidate = (rawTran ?? entryTran) ?? '';
          final tranType = _getValue(rawTranCandidate).toUpperCase();
          // Detect receipt only by explicit TranType codes or presence of adjustments list
          final bool isReceipt = tranType == 'RC' || tranType == 'RCV' || d.containsKey('adjustments');

          if (isReceipt) {
            return _buildReceiptUI(d);
          } else {
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
            _buildTextRow('Collected By', _getValue(d['collected_by'] ?? d['CollectedBy'])),
            _buildTextRow('Mode', _getValue(d['mode'] ?? d['MODE'])),
            _buildTextRow('Bank Name', _getValue(d['bank_name'] ?? d['BankName'])),
            _buildTextRow('Branch', _getValue(d['branch_name'] ?? d['BranchName'])),
            _buildTextRow('Document No', _getValue(d['document_no'] ?? d['DocumentNo'])),
            _buildTextRow('Document Date', _getValue(d['document_date'] ?? d['DocumentDate'])),
            _buildTextRow('Amount', _formatAmount(d['amount'] ?? d['Amount'])),

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

  // Bill Details Section Card
  Widget _buildBillDetailsCard(Map<String, dynamic> d) {
    // Build items list dynamically
    List<Map<String, dynamic>> items = [];

    // Add basic items - show all fields including 0 values
    items.add({'title': 'Goods Value', 'value': d['ITEMAMT'] ?? d['goods_value'] ?? 0});
    items.add({'title': 'Scheme', 'value': d['ASchemeAmt'] ?? d['scheme_amt'] ?? 0});
    items.add({'title': 'Product Discount', 'value': d['DISCAMT'] ?? d['product_discount'] ?? 0});
    items.add({'title': 'Bill Discount', 'value': d['BILLDISC'] ?? d['bill_discount'] ?? 0});

    // Add taxable value
    items.add({'title': 'Taxable Value', 'value': d['TAXABLE'] ?? d['taxable_value'] ?? 0});

    // Tax fields mapping: prefer new dedicated keys (sgst/cgst)
    // If new keys not present, fallback to TAXAMT/ATAXAMT logic used earlier
    final bool hasNewTaxKeys = d.containsKey('sgst') || d.containsKey('cgst');
    if (hasNewTaxKeys) {
      final sgstVal = _toDouble(d['sgst'] ?? d['SGST']);
      final cgstVal = _toDouble(d['cgst'] ?? d['CGST']);
      // If cgst is zero (or missing) treat as IGST case: show IGST = sgstVal (or taxable tax total)
      if (cgstVal == 0.0) {
        items.add({'title': 'IGST', 'value': sgstVal});
      } else {
        items.add({'title': 'SGST', 'value': sgstVal});
        items.add({'title': 'CGST', 'value': cgstVal});
      }
    } else {
      // Fallback to older TAXAMT/ATAXAMT behaviour
      final taxAmt = _toDouble(d['TAXAMT'] ?? d['TaxAmt'] ?? d['taxAmt']);
      final aTaxAmt = _toDouble(d['ATAXAMT'] ?? d['OTAXAMT'] ?? d['ATaxAmt'] ?? d['aTaxAmt']);

      if (aTaxAmt == 0.0) {
        // Inter-state: show IGST (use TAXAMT)
        items.add({'title': 'IGST', 'value': taxAmt});
      } else {
        // Intra-state: show SGST (TAXAMT) and CGST (ATAXAMT)
        items.add({'title': 'SGST', 'value': taxAmt});
        items.add({'title': 'CGST', 'value': aTaxAmt});
      }
    }

    // Add other tax items - support both snake_case and original names
    items.add({'title': 'Cess', 'value': d['EDUCESS'] ?? d['cess'] ?? 0});
    items.add({'title': 'Special Cess', 'value': d['HEDUCESS'] ?? d['special_cess'] ?? 0});

    // Add TCS, Add/Less, Round Off - show all
    items.add({'title': 'TCS', 'value': d['Tcs'] ?? d['tcs'] ?? 0});
    items.add({'title': 'Add/Less', 'value': d['AddLess'] ?? d['add_less'] ?? 0});
    items.add({'title': 'Round Off', 'value': d['RoundAmt'] ?? d['round_off'] ?? 0});

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
            _buildTotalRow('Total Value', d['BillAmt'] ?? d['bill_amt'] ?? d['BillAmt']),
          ],
        ),
      ),
    );
  }

  // Dispatch Details Section Card
  Widget _buildDispatchDetailsCard(Map<String, dynamic> d) {
    // Prefer snake_case fields from updated API, fallback to legacy keys
    final deliveredBy = d['delivered_by'] ?? d['DeliverdBy'] ?? d['DeliveredBy'];
    final transporter = d['transporter_name'] ?? d['TransporterName'] ?? d['Transporter'];
    final lrNo = d['lr_no'] ?? d['LRNO'] ?? d['LRNo'] ?? d['LR_NO'];
    final lrDate = d['lr_date'] ?? d['LRDate'] ?? d['LR_Date'];
    final noOfCase = d['no_of_case'] ?? d['NoOfCase'] ?? d['NoOfCases'] ?? d['NoOfCase'];
    final eway = d['eway_bill'] ?? d['EwayBill'] ?? d['EWayBill'] ?? d['Eway'];

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

            // Dispatch Detail Items
            _buildTextRow('Delivery By', _getValue(deliveredBy)),
            _buildTextRow('Transporter', _getValue(transporter)),
            _buildTextRow('LR No', _getValue(lrNo)),
            _buildTextRow('LR Date', _getValue(lrDate)),
            _buildTextRow('No Of Cases', _getValue(noOfCase)),
            _buildTextRow('E-Way Bill No', _getValue(eway)),
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

  // Header Section - Account Information Card
  Widget _buildHeaderCard(Map<String, dynamic> d) {
    // Prefer API tran type keys, fallback to ledger entry's tranType
    final rawTran = d['TranType'] ?? d['tran_type'] ?? d['tranType'] ?? d['type'];
    final entryTran = widget.entry.tranType;
    final rawTranCandidate = (rawTran ?? entryTran) ?? '';
    final tranType = _getValue(rawTranCandidate).toUpperCase();
    final isReceipt = tranType == 'RC' || tranType == 'RCV' || d.containsKey('adjustments');

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
              _getValue(d['acc_name'] ?? d['NAME'] ?? d['Name'] ?? d['name']),
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
                isReceipt ? 'Receipt Voucher' : 'Sale',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF2E7D32),
                ),
              ),
            ),
            const SizedBox(height: 12),

            // Bill Number/Receipt Voucher and Date
            _buildInfoRow(isReceipt ? 'Receipt Voucher' : 'Bill No', _getValue(d['number'] ?? d['Number'] ?? d['Number'])),
            const Divider(height: 20, color: Color(0xFFEEEEEE)),
            _buildInfoRow(isReceipt ? 'Paid' : 'Date', _getValue(d['date'] ?? d['Date'] ?? d['Date'])),
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

  // Build adjustment widgets from various possible payload shapes
  List<Widget> _buildAdjustmentWidgets(Map<String, dynamic> d) {
    final List<Widget> rows = [];

    // Case A: new API field 'adjustments' => list of objects with particular and adj_amt
    if (d.containsKey('adjustments') && d['adjustments'] is List) {
      final List list = d['adjustments'] as List;
      if (list.isNotEmpty) {
        for (final item in list) {
          if (item is Map) {
            final part = item['particular'] ?? item['Particular'] ?? '';
            final adj = item['adj_amt'] ?? item['AdjAmt'] ?? item['adjAmt'] ?? item['Adjamt'] ?? 0;
            rows.add(_buildAdjustmentRow(_getValue(part), adj));
          }
        }
        return rows;
      }
    }

    // Case B: existing 'AdjustmentDetail' (old API) => list of objects
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

    // Case C: older shape - Particular and AdjAmt may be lists or strings (legacy fallback)
    final partic = d['Particular'] ?? d['particular'];
    final adj = d['AdjAmt'] ?? d['adj_amt'] ?? d['Adjamt'] ?? d['adjAmt'];

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

  // Helper: produce a readable transaction label from raw code
  String _friendlyTranLabelFromRaw(dynamic raw, {required bool isReceipt}) {
    if (isReceipt) return 'Receipt Voucher';
    if (raw == null) return 'Sale';
    final s = raw.toString().trim();
    if (s.isEmpty || s == '-' || s.toLowerCase() == 'null') return 'Sale';
    final up = s.toUpperCase();
    if (up.contains('SALE') || up.contains('OUT') || up == 'S') return 'Sale';
    if (up.contains('PUR') || up.contains('IN')) return 'Purchase';
    if (up.startsWith('RC')) return 'Receipt Voucher';
    // Otherwise return raw cleaned (capitalize first letter)
    return s[0].toUpperCase() + (s.length > 1 ? s.substring(1) : '');
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
