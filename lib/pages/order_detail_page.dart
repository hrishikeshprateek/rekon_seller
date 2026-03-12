import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class OrderDetailPage extends StatelessWidget {
  final Map<String, dynamic> orderDetail;
  final List<dynamic> products;

  const OrderDetailPage({
    Key? key,
    required this.orderDetail,
    this.products = const [],
  }) : super(key: key);

  // --- HELPERS ---

  /// Format a numeric value from the API to a clean string (strips trailing .0000)
  String _fmt(dynamic val) {
    if (val == null) return '0';
    final d = double.tryParse(val.toString());
    if (d == null) return val.toString();
    // Show as int if whole number, else 2 decimal places
    if (d == d.truncateToDouble()) return d.toInt().toString();
    return d.toStringAsFixed(2);
  }

  bool _isNonZero(String? val) {
    if (val == null || val.isEmpty || val == 'null') return false;
    final d = double.tryParse(val);
    return d != null && d != 0;
  }

  // --- UI HELPER WIDGETS ---

  Widget _buildStatusChip(String? status) {
    final safeStatus = status ?? 'Unknown';
    final isPending = safeStatus.toLowerCase() == 'pending';
    final color = isPending ? Colors.orange.shade700 : Colors.green.shade700;
    final bgColor = isPending ? Colors.orange.shade50 : Colors.green.shade50;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(isPending ? Icons.pending_actions : Icons.check_circle_outline, size: 14, color: color),
          const SizedBox(width: 4),
          Text(
            safeStatus.toUpperCase(),
            style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w800, letterSpacing: 0.5),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon, ColorScheme cs) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: cs.primaryContainer.withOpacity(0.6),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 18, color: cs.primary),
          ),
          const SizedBox(width: 12),
          Text(title, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: cs.onSurface, letterSpacing: 0.3)),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String? value, ColorScheme cs,
      {IconData? icon, bool isBold = false, Color? valueColor}) {
    if (value == null || value.trim().isEmpty || value == 'null') return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 16, color: cs.onSurfaceVariant.withOpacity(0.7)),
            const SizedBox(width: 8),
          ],
          Text(label, style: TextStyle(fontSize: 13.5, color: cs.onSurfaceVariant, fontWeight: FontWeight.w500)),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: TextStyle(
                fontSize: isBold ? 15 : 13.5,
                color: valueColor ?? cs.onSurface,
                fontWeight: isBold ? FontWeight.w800 : FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCard({required Widget child, required ColorScheme cs}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16, left: 16, right: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: cs.outlineVariant.withOpacity(0.6)),
        boxShadow: [
          BoxShadow(color: cs.shadow.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 4))
        ],
      ),
      child: child,
    );
  }

  Widget _buildMiniStat(String label, String value, ColorScheme cs) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(fontSize: 11, color: cs.onSurfaceVariant, fontWeight: FontWeight.w600, letterSpacing: 0.5)),
        const SizedBox(height: 2),
        Text(value, style: TextStyle(fontSize: 15, color: cs.onSurface, fontWeight: FontWeight.w800)),
      ],
    );
  }

  Widget _buildProductCard(Map<String, dynamic> product, int index, ColorScheme cs) {
    final name = product['Name']?.toString() ?? 'Product ${index + 1}';
    final mfg = product['MfgComp']?.toString() ?? '';
    final qty = _fmt(product['Qty']);
    final fQty = _fmt(product['FQty']);
    final rate = _fmt(product['Rate']);
    // Amt from API is the gross value per item
    final amt = _fmt(product['Amt']);
    // SchAmt is at the order level (same across all rows), use per-product SchQty info if available
    final schAmt = _fmt(product['SchAmt']);
    // TaxAmt is at order level; per-product tax not separately available
    final taxAmt = _fmt(product['TaxAmt']);
    // NetAmt not in this API — compute from Amt + TaxAmt - discounts
    final double rawAmt = double.tryParse(product['Amt']?.toString() ?? '0') ?? 0;
    final double rawDiscAmt = double.tryParse(product['DiscAmt']?.toString() ?? '0') ?? 0;
    final double rawDisc1Amt = double.tryParse(product['Disc1Amt']?.toString() ?? '0') ?? 0;
    final double rawDisc2Amt = double.tryParse(product['Disc2Amt']?.toString() ?? '0') ?? 0;
    final double rawTaxAmt = double.tryParse(product['TaxAmt']?.toString() ?? '0') ?? 0;
    final double computedNet = rawAmt - rawDiscAmt - rawDisc1Amt - rawDisc2Amt + rawTaxAmt;
    final netAmt = computedNet.toStringAsFixed(2);
    final mrp = _fmt(product['Mrp'] ?? product['MRP']);
    final discAmt = product['DiscAmt']?.toString() ?? '';
    final discPer = product['DiscPer']?.toString() ?? '';
    final disc1Per = product['Disc1Per']?.toString() ?? '';
    final disc2Per = product['Disc2Per']?.toString() ?? '';
    final remark = product['DO_Remark']?.toString() ?? product['Remark']?.toString() ?? '';
    final icode = product['Icode']?.toString() ?? '';
    final invNo = product['InvNo']?.toString() ?? '';
    final balQty = _fmt(product['BalQty']);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: cs.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: cs.outlineVariant.withOpacity(0.7)),
        boxShadow: [
          BoxShadow(color: cs.shadow.withOpacity(0.04), blurRadius: 8, offset: const Offset(0, 3)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Product header
          Container(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
            decoration: BoxDecoration(
              color: cs.primaryContainer.withOpacity(0.2),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: cs.primary,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    '${index + 1}',
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 13),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: cs.onSurface, height: 1.3),
                      ),
                      if (mfg.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 3),
                          child: Text(mfg, style: TextStyle(fontSize: 12, color: cs.primary, fontWeight: FontWeight.w600)),
                        ),
                      if (icode.isNotEmpty)
                        Text('Code: $icode', style: TextStyle(fontSize: 11, color: cs.onSurfaceVariant)),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Qty / FQty / Rate row
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: cs.primaryContainer.withOpacity(0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildMiniStat('QTY', qty, cs),
                  Container(width: 1, height: 32, color: cs.outlineVariant),
                  _buildMiniStat('FREE QTY', fQty, cs),
                  Container(width: 1, height: 32, color: cs.outlineVariant),
                  _buildMiniStat('RATE', '₹$rate', cs),
                  if (mrp != null && mrp != '0' && mrp != '0.0' && mrp.isNotEmpty) ...[
                    Container(width: 1, height: 32, color: cs.outlineVariant),
                    _buildMiniStat('MRP', '₹$mrp', cs),
                  ],
                ],
              ),
            ),
          ),

          // Financial details
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            child: Column(
              children: [
                _buildProductDetailRow('Base Amount', '₹$amt', cs),
                if (_isNonZero(discAmt))
                  _buildProductDetailRow('Discount (Pcs)', '- ₹$discAmt', cs, valueColor: Colors.green.shade700),
                if (_isNonZero(discPer))
                  _buildProductDetailRow('Discount (%)', '$discPer%', cs, valueColor: Colors.green.shade700),
                if (_isNonZero(disc1Per))
                  _buildProductDetailRow('Disc 1 (%)', '$disc1Per%', cs, valueColor: Colors.green.shade700),
                if (_isNonZero(disc2Per))
                  _buildProductDetailRow('Add Disc (%)', '$disc2Per%', cs, valueColor: Colors.green.shade700),
                if (_isNonZero(schAmt))
                  _buildProductDetailRow('Scheme Amt', '- ₹$schAmt', cs, valueColor: Colors.green.shade700),
                _buildProductDetailRow('Tax Amount', '+ ₹$taxAmt', cs),
                if (balQty != '0' && balQty.isNotEmpty)
                  _buildProductDetailRow('Balance Qty', balQty, cs),
                if (invNo.isNotEmpty && invNo != 'null')
                  _buildProductDetailRow('Invoice No', invNo, cs),
                if (remark.isNotEmpty && remark != 'null')
                  _buildProductDetailRow('Remark', remark, cs),
              ],
            ),
          ),

          // Net Amount footer
          Container(
            margin: const EdgeInsets.fromLTRB(16, 10, 16, 14),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: cs.primary.withOpacity(0.08),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Net Amount', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: cs.onSurface)),
                Text(
                  '₹$netAmt',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: cs.primary),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProductDetailRow(String label, String value, ColorScheme cs, {Color? valueColor}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5.0),
      child: Row(
        children: [
          Text(label, style: TextStyle(fontSize: 13, color: cs.onSurfaceVariant, fontWeight: FontWeight.w500)),
          const Spacer(),
          Text(
            value,
            style: TextStyle(fontSize: 13, color: valueColor ?? cs.onSurface, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    final shippingAddress = [orderDetail['Ac_Address1'], orderDetail['Ac_Address2'], orderDetail['Ac_Address3']]
        .where((e) => e != null && e.toString().trim().isNotEmpty)
        .join(', ');

    final firmAddress = [orderDetail['F_FirmAdd1'], orderDetail['F_FirmAdd2'], orderDetail['F_FirmAdd3']]
        .where((e) => e != null && e.toString().trim().isNotEmpty)
        .join(', ');

    final String orderId = orderDetail['OrderId']?.toString() ?? 'N/A';

    // Compute totals across all products
    // NetAmt isn't in this API; use Amt - discounts + TaxAmt per row
    // But TaxAmt & SchAmt are order-level (same for all rows) so only take from first row
    double totalGoodsAmt = 0;
    double totalDiscAmt = 0;
    for (final p in products) {
      totalGoodsAmt += (double.tryParse(p['Amt']?.toString() ?? '0') ?? 0);
      totalDiscAmt += (double.tryParse(p['DiscAmt']?.toString() ?? '0') ?? 0)
          + (double.tryParse(p['Disc1Amt']?.toString() ?? '0') ?? 0)
          + (double.tryParse(p['Disc2Amt']?.toString() ?? '0') ?? 0);
    }
    // TaxAmt and SchAmt are order-level (same in every row), take from first product
    final double orderTaxAmt = double.tryParse(orderDetail['TaxAmt']?.toString() ?? '0') ?? 0;
    final double orderSchAmt = double.tryParse(orderDetail['SchAmt']?.toString() ?? '0') ?? 0;
    final double totalNetAmt = totalGoodsAmt - totalDiscAmt - orderSchAmt + orderTaxAmt;

    return Scaffold(
      backgroundColor: cs.surfaceContainerLowest,
      appBar: AppBar(
        title: const Text('Order Details', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 17)),
        centerTitle: true,
        backgroundColor: cs.surfaceContainerLowest,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // --- HERO HEADER ---
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(20, 10, 20, 24),
              decoration: BoxDecoration(
                color: cs.surfaceContainerLowest,
                border: Border(bottom: BorderSide(color: cs.outlineVariant.withOpacity(0.5))),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
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
                              orderDetail['Ac_Name'] ?? 'Order',
                              style: TextStyle(fontWeight: FontWeight.w900, fontSize: 22, color: cs.onSurface, height: 1.2),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Order ID: #$orderId',
                              style: TextStyle(fontSize: 13, color: cs.primary, fontWeight: FontWeight.w600),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      _buildStatusChip(orderDetail['OrderStatus']),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      _buildInfoChip(Icons.inventory_2_outlined, '${products.length} item${products.length == 1 ? '' : 's'}', cs),
                      const SizedBox(width: 8),
                      _buildInfoChip(Icons.currency_rupee, orderDetail['OrderValue']?.toString() ?? totalNetAmt.toStringAsFixed(2), cs),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // --- SECTION 1: LOGISTICS ---
            _buildCard(
              cs: cs,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSectionHeader('Logistics & Tracking', Icons.local_shipping_outlined, cs),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    margin: const EdgeInsets.only(bottom: 12),
                    decoration: BoxDecoration(
                      color: cs.surfaceContainerHighest.withOpacity(0.4),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: cs.outlineVariant.withOpacity(0.5)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('ORDER ID', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: cs.onSurfaceVariant, letterSpacing: 0.5)),
                            const SizedBox(height: 2),
                            Text(orderId, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: cs.onSurface)),
                          ],
                        ),
                        Builder(
                          builder: (context) => IconButton(
                            icon: const Icon(Icons.copy_rounded, size: 18),
                            color: cs.primary,
                            onPressed: () {
                              Clipboard.setData(ClipboardData(text: orderId));
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Order ID copied to clipboard'), behavior: SnackBarBehavior.floating),
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                  _buildDetailRow('Placed On', orderDetail['PlacedOn'], cs, icon: Icons.calendar_today_rounded),
                  _buildDetailRow('Delivery Date', orderDetail['DeliveryDate'], cs, icon: Icons.event_available_rounded),
                  _buildDetailRow('Delivery Mode', orderDetail['DeliveryMode'], cs, icon: Icons.directions_car_rounded),
                  _buildDetailRow('Payment Mode', orderDetail['PaymentMode'], cs, icon: Icons.payments_outlined),
                ],
              ),
            ),

            // --- SECTION 2: PRODUCTS LIST ---
            Container(
              margin: const EdgeInsets.only(bottom: 8, left: 16, right: 16),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: cs.primaryContainer.withOpacity(0.6),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(Icons.medication_outlined, size: 18, color: cs.primary),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'Products (${products.length})',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: cs.onSurface, letterSpacing: 0.3),
                  ),
                ],
              ),
            ),

            // Product cards
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                children: [
                  for (int i = 0; i < products.length; i++)
                    _buildProductCard(products[i] as Map<String, dynamic>, i, cs),
                ],
              ),
            ),

            const SizedBox(height: 8),

            // --- SECTION 3: ORDER SUMMARY ---
            _buildCard(
              cs: cs,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSectionHeader('Order Summary', Icons.receipt_long_rounded, cs),
                  _buildDetailRow('Item Amount', '₹${totalGoodsAmt.toStringAsFixed(2)}', cs),
                  if (totalDiscAmt != 0)
                    _buildDetailRow('Total Discount', '- ₹${totalDiscAmt.toStringAsFixed(2)}', cs, valueColor: Colors.green.shade700),
                  if (orderSchAmt != 0)
                    _buildDetailRow('Scheme Amount', '- ₹${orderSchAmt.toStringAsFixed(2)}', cs, valueColor: Colors.green.shade700),
                  _buildDetailRow('Tax Amount', '+ ₹${orderTaxAmt.toStringAsFixed(2)}', cs),
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    child: Divider(color: cs.outlineVariant, thickness: 1, height: 1),
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Net Payable', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: cs.onSurface)),
                      Text(
                        '₹${orderDetail['OrderValue']?.toString() ?? totalNetAmt.toStringAsFixed(2)}',
                        style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: cs.primary),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // --- SECTION 4: ACCOUNT & FIRM ---
            _buildCard(
              cs: cs,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSectionHeader('Parties Involved', Icons.storefront_outlined, cs),
                  Row(
                    children: [
                      Icon(Icons.person_outline, size: 16, color: cs.primary),
                      const SizedBox(width: 8),
                      Text('ACCOUNT DETAILS', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: cs.primary, letterSpacing: 1)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  _buildDetailRow('Name', orderDetail['Ac_Name'], cs, isBold: true),
                  _buildDetailRow('Account No.', orderDetail['Ac_AcNo'], cs),
                  _buildDetailRow('GSTIN', orderDetail['AC_GST_NUMBER'], cs),
                  _buildDetailRow('Shipping Address', shippingAddress, cs),
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    child: Divider(color: cs.outlineVariant.withOpacity(0.5)),
                  ),
                  Row(
                    children: [
                      Icon(Icons.domain_rounded, size: 16, color: cs.primary),
                      const SizedBox(width: 8),
                      Text('FIRM DETAILS', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: cs.primary, letterSpacing: 1)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  _buildDetailRow('Name', orderDetail['F_FirmName'], cs, isBold: true),
                  _buildDetailRow('GSTIN', orderDetail['F_GST_Number'], cs),
                  _buildDetailRow('Mobile', orderDetail['F_Firm_Mobile']?.toString(), cs),
                  _buildDetailRow('Firm Address', firmAddress, cs),
                ],
              ),
            ),

            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoChip(IconData icon, String label, ColorScheme cs) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: cs.primaryContainer.withOpacity(0.4),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: cs.primary),
          const SizedBox(width: 5),
          Text(label, style: TextStyle(fontSize: 12, color: cs.primary, fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }
}

