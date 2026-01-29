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
              ],
            ),
          );
        },
      ),
    );
  }

  // Header Section - Account Information Card
  Widget _buildHeaderCard(Map<String, dynamic> d) {
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
            const SizedBox(height: 4),

            // Address (acc_address)
            Text(
              _getValue(d['Address1']),
              style: const TextStyle(
                fontSize: 13,
                color: Colors.black54,
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
                _getValue(d['TranType']),
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF2E7D32),
                ),
              ),
            ),
            const SizedBox(height: 12),

            // Bill Number, Code, Date
            _buildInfoRow('Bill No', _getValue(d['Number'])),
            const Divider(height: 20, color: Color(0xFFEEEEEE)),
            _buildInfoRow('Code', _getValue(d['CODE'])),
            const Divider(height: 20, color: Color(0xFFEEEEEE)),
            _buildInfoRow('Date', _getValue(d['Date'])),
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

            // Bill Detail Items (matching Android app structure)
            _buildDetailRow('Goods Value', d['ITEMAMT']),
            _buildDetailRow('Scheme', d['ASchemeAmt']),
            _buildDetailRow('Product Discount', d['DISCAMT']),
            _buildDetailRow('Bill Discount', d['BILLDISC']),

            const SizedBox(height: 8),
            const Divider(height: 1, color: Color(0xFFEEEEEE)),
            const SizedBox(height: 8),

            _buildDetailRow('Taxable Value', d['TAXABLE']),
            _buildDetailRow('SGST', d['TAXAMT']),
            _buildDetailRow('CGST', d['OTAXAMT']),
            _buildDetailRow('Cess', d['EDUCESS']),
            _buildDetailRow('Special Cess', d['HEDUCESS']),

            const SizedBox(height: 8),
            const Divider(height: 1, color: Color(0xFFEEEEEE)),
            const SizedBox(height: 8),

            _buildDetailRow('TCS', d['Tcs']),
            _buildDetailRow('Add/Less', d['AddLess']),
            _buildDetailRow('Round Off', d['RoundAmt']),

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
            amount,
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
            amount,
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
      // Format with 1 decimal place as shown in the documentation
      return numVal.toStringAsFixed(1);
    }

    return '0.0';
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
}

