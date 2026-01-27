import 'dart:convert';
import 'package:flutter/material.dart';
import '../models/ledger_entry_model.dart';

/// Full-screen transaction detail page that fetches detail via provided callback
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
    final cs = widget.colorScheme;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Transaction Detail', style: TextStyle(fontWeight: FontWeight.w700)),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        scrolledUnderElevation: 2,
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

          return Container(
            color: Colors.white,
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _header(cs, d),
                const SizedBox(height: 12),
                _sectionTitle('Bill Details', cs),
                _kv('Goods Value', d['ITEMAMT']),
                _kv('Scheme', d['ASchemeAmt']),
                _kv('Product Discount', d['DISCAMT']),
                _kv('Bill Discount', d['BILLDISC']),
                _kv('Taxable Value', d['TAXABLE']),
                _kv('SGST', d['TAXAMT']),
                _kv('CGST', d['OTAXAMT']),
                _kv('Cess', d['EDUCESS']),
                _kv('Special Cess', d['HEDUCESS']),
                _kv('Total Value', d['BillAmt']),
                _kv('Tcs', d['Tcs']),
                _kv('Add/Less', d['AddLess']),
                _kv('Round Off', d['RoundAmt']),
                const SizedBox(height: 12),
                _sectionTitle('Dispatch Details', cs),
                _kv('Delivery By', d['DeliverdBy']),
                _kv('Transporter', d['TransporterName']),
                _kv('LR No', d['LRNO']),
                _kv('LR Date', d['LRDate']),
                _kv('No Of Case', d['NoOfCase']),
                _kv('EWay Bill', d['EwayBill']),
                _kv('EinV', d['EinV']),
                const SizedBox(height: 24),
                FilledButton(
                  onPressed: () => Navigator.pop(context),
                  style: FilledButton.styleFrom(backgroundColor: cs.primary),
                  child: const Text('View Bill'),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _header(ColorScheme cs, Map<String, dynamic> d) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(d['NAME']?.toString() ?? widget.entry.tranType ?? 'Transaction',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
          const SizedBox(height: 6),
          if ((d['Address1'] ?? '').toString().trim().isNotEmpty)
            Text(d['Address1'].toString(), style: const TextStyle(fontSize: 13, color: Colors.black87)),
          const SizedBox(height: 6),
          Wrap(spacing: 12, runSpacing: 4, children: [
            _chip('Date', d['Date']),
            _chip('Number', d['Number']),
            _chip('Code', d['CODE']),
            _chip('Type', d['TranType']),
          ]),
        ],
      ),
    );
  }

  Widget _sectionTitle(String title, ColorScheme cs) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Text(title, style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15, color: cs.primary)),
    );
  }

  Widget _kv(String label, dynamic value) {
    final text = value == null ? '-' : value.toString();
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(child: Text(label, style: const TextStyle(color: Colors.grey, fontWeight: FontWeight.w500))),
          const SizedBox(width: 12),
          Text(_formatValue(text), textAlign: TextAlign.right, style: const TextStyle(fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }

  Widget _chip(String label, dynamic value) {
    final text = value == null ? '-' : value.toString();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text('$label: ${_formatValue(text)}', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
    );
  }

  String _formatValue(String v) {
    final trimmed = v.trim();
    if (trimmed.isEmpty || trimmed.toLowerCase() == 'null') return '-';
    // Attempt numeric formatting with rupee prefix if numeric
    final numVal = num.tryParse(trimmed);
    if (numVal != null) {
      return '₹${numVal.toStringAsFixed(2)}';
    }
    return trimmed;
  }

  Widget _errorState(String message) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, color: Colors.red, size: 36),
            const SizedBox(height: 8),
            Text(message, textAlign: TextAlign.center, style: const TextStyle(color: Colors.red)),
            const SizedBox(height: 12),
            FilledButton(onPressed: () => Navigator.pop(context), child: const Text('Close')),
          ],
        ),
      ),
    );
  }
}

