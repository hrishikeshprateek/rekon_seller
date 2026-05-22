import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';
import '../auth_service.dart';

/// Sectioned order-detail screen.
///
/// Layout (top to bottom): blue app bar, account-name strip, a 4-step status
/// stepper, an "ORDER DETAILS" card, an optional "INVOICE DETAILS" card (with a
/// share-PDF action) and a collapsible "ITEM PURCHASED" card.
class OrderDetailPage extends StatefulWidget {
  final Map<String, dynamic> orderDetail;
  final List<dynamic> products;

  const OrderDetailPage({
    super.key,
    required this.orderDetail,
    this.products = const [],
  });

  @override
  State<OrderDetailPage> createState() => _OrderDetailPageState();
}

class _OrderDetailPageState extends State<OrderDetailPage> {
  static const Color _blue = Color(0xFF1E88E5);
  static const Color _bg = Color(0xFFF5F7FA);

  bool _itemsExpanded = true;
  bool _isSharingInvoice = false;

  Map<String, dynamic> get _order => widget.orderDetail;
  List<dynamic> get _products => widget.products;

  // --- HELPERS ---

  /// Parse any API value into a double, defaulting to 0.
  double _num(dynamic v) => double.tryParse(v?.toString() ?? '') ?? 0;

  /// Format a numeric value with 2 decimal places, prefixed with a rupee sign.
  String _money(dynamic v) => '₹${_num(v).toStringAsFixed(2)}';

  /// Whether a string field actually carries a value (not null / empty / "null").
  bool _hasValue(dynamic v) {
    final s = v?.toString().trim() ?? '';
    return s.isNotEmpty && s.toLowerCase() != 'null';
  }

  /// Resolve the active stepper index from the order status text.
  int _statusIndex(String status) {
    final s = status.toLowerCase();
    if (s.contains('deliver')) return 3;
    if (s.contains('ship')) return 2;
    if (s.contains('invoic')) return 1;
    return 0; // placed / pending / anything else
  }

  // --- PDF SHARE ---

  /// Fetches the invoice as a PDF and opens the OS share sheet.
  ///
  /// Best-effort: hits `/GetTranDetail` with `lSharePdf: 1` (the same endpoint
  /// the transaction screen uses). The order API does not expose a dedicated
  /// invoice-PDF endpoint, so this may need adjustment if the backend changes.
  Future<void> _viewInvoice() async {
    if (_isSharingInvoice) return;
    setState(() => _isSharingInvoice = true);
    try {
      final auth = Provider.of<AuthService>(context, listen: false);
      final dio = auth.getDioClient();

      final invNo = _order['InvNo']?.toString() ?? '';
      final payload = {
        'lLicNo': auth.currentUser?.licenseNumber ?? '',
        'lKeyEntryNo':
            _order['TMNO']?.toString() ?? _order['InvNo']?.toString() ?? '',
        'lIsEntryRecord': '1',
        'lSharePdf': 1,
      };

      final response = await dio.post(
        '/GetTranDetail',
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
      }

      if (bytes == null || bytes.isEmpty) {
        throw 'No PDF data received.';
      }

      final dir = await getTemporaryDirectory();
      final safeNo = invNo.replaceAll(RegExp(r'[^A-Za-z0-9]'), '_');
      final file = File(
          '${dir.path}/invoice_${safeNo}_${DateTime.now().millisecondsSinceEpoch}.pdf');
      await file.writeAsBytes(bytes, flush: true);

      final xfile = XFile(file.path, mimeType: 'application/pdf');
      await Share.shareXFiles([xfile], text: 'Invoice $invNo');
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Unable to open invoice: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isSharingInvoice = false);
    }
  }

  // --- BUILD ---

  @override
  Widget build(BuildContext context) {
    final firmName = _hasValue(_order['F_FirmName'])
        ? _order['F_FirmName'].toString()
        : 'ORDER';

    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        backgroundColor: _blue,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        title: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              firmName,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const Text(
              'ORDER DETAILS',
              style: TextStyle(
                fontSize: 12,
                color: Colors.white,
                letterSpacing: 1.0,
              ),
            ),
          ],
        ),
      ),
      body: ListView(
        children: [
          _buildAccountStrip(),
          _buildStepper(),
          _buildOrderDetailsCard(),
          _buildInvoiceCard(),
          _buildItemsCard(),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  // --- ACCOUNT STRIP ---

  Widget _buildAccountStrip() {
    final acName = _order['Ac_Name']?.toString() ?? '';
    return Container(
      width: double.infinity,
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Text(
        acName,
        textAlign: TextAlign.center,
        style: const TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.bold,
          color: Colors.black87,
        ),
      ),
    );
  }

  // --- STATUS STEPPER ---

  Widget _buildStepper() {
    final status = _order['OrderStatus']?.toString() ?? '';
    final current = _statusIndex(status);

    const steps = <_StepInfo>[
      _StepInfo('Placed', Icons.shopping_bag_outlined),
      _StepInfo('Invoiced', Icons.receipt_long_outlined),
      _StepInfo('Shipped', Icons.local_shipping_outlined),
      _StepInfo('Delivered', Icons.check_circle_outline),
    ];

    final List<Widget> row = [];
    for (int i = 0; i < steps.length; i++) {
      final active = i <= current;
      row.add(Expanded(child: _buildStep(steps[i], active)));
      if (i < steps.length - 1) {
        final connectorActive = (i + 1) <= current;
        row.add(Expanded(
          child: Container(
            height: 2,
            margin: const EdgeInsets.only(bottom: 22),
            color: connectorActive ? _blue : Colors.grey.shade300,
          ),
        ));
      }
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: row,
      ),
    );
  }

  Widget _buildStep(_StepInfo step, bool active) {
    final color = active ? _blue : Colors.grey.shade400;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: active ? _blue : Colors.grey.shade200,
            shape: BoxShape.circle,
          ),
          child: Icon(
            step.icon,
            size: 19,
            color: active ? Colors.white : Colors.grey.shade500,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          step.label,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 11,
            fontWeight: active ? FontWeight.bold : FontWeight.w500,
            color: color,
          ),
        ),
      ],
    );
  }

  // --- ORDER DETAILS CARD ---

  Widget _buildOrderDetailsCard() {
    final orderId = _order['OrderId']?.toString() ?? '';
    // DiscValue is the all-inclusive discount total — it already contains the
    // Disc1/Disc2 breakdowns, so it must NOT be summed with them.
    final discTotal = _num(_order['DiscValue']);

    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _sectionHeader('ORDER DETAILS'),
          const SizedBox(height: 12),
          if (_hasValue(orderId))
            _detailRow('Order Id', '#$orderId', emphasiseValue: true),
          _detailRow('Placed On', _order['PlacedOn']?.toString()),
          _detailRow('Number Of Items', '${_products.length}',
              emphasiseValue: true),
          _amountRow('Product Value', _money(_order['ItemAmt'])),
          _amountRow('Scheme', _money(_order['SchAmt'])),
          _amountRow('Discount', _money(discTotal)),
          _amountRow('Delivery Charges', _money(_order['DelCharges'])),
          _amountRow('GST Amount', _money(_order['TaxAmt'])),
          const Divider(height: 24),
          _amountRow('Total Amount', _money(_order['OrderValue']),
              isTotal: true),
          const SizedBox(height: 4),
          _detailRow('Delivery Date', _order['DeliveryDate']?.toString()),
          _detailRow('Delivery Mode', _order['DeliveryMode']?.toString()),
          _detailRow('Status', _order['OrderStatus']?.toString()),
        ],
      ),
    );
  }

  // --- INVOICE DETAILS CARD ---

  Widget _buildInvoiceCard() {
    if (!_hasValue(_order['InvNo'])) return const SizedBox.shrink();

    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _sectionHeader('INVOICE DETAILS'),
          const SizedBox(height: 12),
          _detailRow('Invoice Number', _order['InvNo']?.toString(),
              emphasiseValue: true),
          _detailRow('Invoice Date', _order['INVDt']?.toString()),
          _amountRow('Invoice Amount', _money(_order['InvAmt'])),
          const SizedBox(height: 12),
          Center(
            child: InkWell(
              onTap: _isSharingInvoice ? null : _viewInvoice,
              borderRadius: BorderRadius.circular(8),
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                child: _isSharingInvoice
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.red,
                        ),
                      )
                    : Row(
                        mainAxisSize: MainAxisSize.min,
                        children: const [
                          Icon(Icons.receipt_long,
                              size: 18, color: Colors.red),
                          SizedBox(width: 6),
                          Text(
                            'View Invoice',
                            style: TextStyle(
                              color: Colors.red,
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
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

  // --- ITEM PURCHASED CARD ---

  Widget _buildItemsCard() {
    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          InkWell(
            onTap: () => setState(() => _itemsExpanded = !_itemsExpanded),
            child: Row(
              children: [
                const Expanded(
                  child: Text(
                    'ITEM PURCHASED',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: _blue,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
                Icon(
                  _itemsExpanded
                      ? Icons.keyboard_arrow_up
                      : Icons.keyboard_arrow_down,
                  color: _blue,
                ),
              ],
            ),
          ),
          if (_itemsExpanded) ...[
            const SizedBox(height: 8),
            if (_products.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Text(
                  'No items',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey.shade600),
                ),
              )
            else
              for (int i = 0; i < _products.length; i++)
                _buildItem(_products[i] as Map<String, dynamic>,
                    isLast: i == _products.length - 1),
          ],
        ],
      ),
    );
  }

  Widget _buildItem(Map<String, dynamic> product, {required bool isLast}) {
    final name = product['Name']?.toString() ?? '';
    final mfg = product['MfgComp']?.toString() ?? '';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 8),
        Text(
          name,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: _blue,
          ),
        ),
        if (_hasValue(mfg))
          Padding(
            padding: const EdgeInsets.only(top: 2),
            child: Text(
              mfg.toUpperCase(),
              style: TextStyle(
                fontSize: 11,
                color: Colors.grey.shade600,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _inlineStat('Price', _money(product['Rate'])),
            _inlineStat('Value', _money(product['Amt']), alignEnd: true),
          ],
        ),
        const SizedBox(height: 10),
        Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: _blue.withValues(alpha: 0.06),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            children: [
              Expanded(
                child: _qtyStat('Order Qty', product['Qty']),
              ),
              Expanded(
                child: _qtyStat('Invoice Qty', product['InvQty']),
              ),
              Expanded(
                child: _qtyStat('Balance Qty', product['BalQty']),
              ),
            ],
          ),
        ),
        if (!isLast)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 4),
            child: Divider(height: 16),
          ),
      ],
    );
  }

  Widget _inlineStat(String label, String value, {bool alignEnd = false}) {
    return Column(
      crossAxisAlignment:
          alignEnd ? CrossAxisAlignment.end : CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
      ],
    );
  }

  Widget _qtyStat(String label, dynamic value) {
    final n = _num(value);
    // Show whole numbers without decimals (e.g. "5 Unit", "0 Unit").
    final qtyStr = n == n.truncateToDouble()
        ? n.toInt().toString()
        : n.toStringAsFixed(2);
    return Column(
      children: [
        Text(
          label,
          style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
        ),
        const SizedBox(height: 3),
        Text(
          '$qtyStr Unit',
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
      ],
    );
  }

  // --- SHARED UI HELPERS ---

  Widget _card({required Widget child}) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: child,
    );
  }

  Widget _sectionHeader(String title) {
    return Text(
      title,
      textAlign: TextAlign.center,
      style: const TextStyle(
        fontSize: 15,
        fontWeight: FontWeight.bold,
        color: _blue,
        letterSpacing: 0.5,
      ),
    );
  }

  /// A label/value row. Hidden entirely when [value] is null/empty/"null".
  Widget _detailRow(String label, String? value,
      {bool emphasiseValue = false}) {
    if (!_hasValue(value)) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              value!,
              textAlign: TextAlign.right,
              style: TextStyle(
                fontSize: 13.5,
                fontWeight: FontWeight.bold,
                color: emphasiseValue ? _blue : Colors.black87,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// An amount row. Always rendered (shows ₹0.00 when there is no value).
  Widget _amountRow(String label, String value, {bool isTotal = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: isTotal ? 14.5 : 13,
              color: isTotal ? Colors.black87 : Colors.grey.shade600,
              fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: TextStyle(
                fontSize: isTotal ? 17 : 13.5,
                fontWeight: FontWeight.bold,
                color: _blue,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Static description of one stepper step.
class _StepInfo {
  final String label;
  final IconData icon;
  const _StepInfo(this.label, this.icon);
}
