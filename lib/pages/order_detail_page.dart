import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class OrderDetailPage extends StatelessWidget {
  final Map<String, dynamic> orderDetail;

  const OrderDetailPage({Key? key, required this.orderDetail}) : super(key: key);

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
            style: TextStyle(
              color: color,
              fontSize: 11,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.5,
            ),
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
          Text(
            title,
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: cs.onSurface, letterSpacing: 0.3),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String? value, ColorScheme cs, {IconData? icon, bool isBold = false, Color? valueColor}) {
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
          Text(
            label,
            style: TextStyle(fontSize: 13.5, color: cs.onSurfaceVariant, fontWeight: FontWeight.w500),
          ),
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
          BoxShadow(
            color: cs.shadow.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: child,
    );
  }

  // Mini summary box for Qty and Rate
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

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    final shippingAddress = [orderDetail['Ac_Address1'], orderDetail['Ac_Address2'], orderDetail['Ac_Address3']]
        .where((e) => e != null && e.toString().trim().isNotEmpty).join(', ');

    final firmAddress = [orderDetail['F_FirmAdd1'], orderDetail['F_FirmAdd2'], orderDetail['F_FirmAdd3']]
        .where((e) => e != null && e.toString().trim().isNotEmpty).join(', ');

    final String orderId = orderDetail['OrderId']?.toString() ?? 'N/A';

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
                        child: Text(
                          orderDetail['Name'] ?? 'Order Item',
                          style: TextStyle(fontWeight: FontWeight.w900, fontSize: 24, color: cs.onSurface, height: 1.2),
                        ),
                      ),
                      const SizedBox(width: 12),
                      _buildStatusChip(orderDetail['OrderStatus']),
                    ],
                  ),
                  const SizedBox(height: 12),
                  if ((orderDetail['MfgComp'] ?? '').isNotEmpty)
                    Row(
                      children: [
                        Icon(Icons.precision_manufacturing_rounded, size: 16, color: cs.primary),
                        const SizedBox(width: 6),
                        Text(
                          orderDetail['MfgComp'] ?? '',
                          style: TextStyle(fontSize: 14, color: cs.primary, fontWeight: FontWeight.w700),
                        ),
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

                  // Copyable Order ID row
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    margin: const EdgeInsets.only(bottom: 12),
                    decoration: BoxDecoration(
                        color: cs.surfaceContainerHighest.withOpacity(0.4),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: cs.outlineVariant.withOpacity(0.5))
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
                        IconButton(
                          icon: const Icon(Icons.copy_rounded, size: 18),
                          color: cs.primary,
                          onPressed: () {
                            Clipboard.setData(ClipboardData(text: orderId));
                            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Order ID copied to clipboard'), behavior: SnackBarBehavior.floating));
                          },
                        )
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

            // --- SECTION 2: FINANCIAL INVOICE SUMMARY ---
            _buildCard(
              cs: cs,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSectionHeader('Financial Summary', Icons.receipt_long_rounded, cs),

                  // Highlight Box for Qty & Rate
                  Container(
                    padding: const EdgeInsets.all(16),
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: cs.primaryContainer.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _buildMiniStat('QTY', orderDetail['Qty']?.toString() ?? '0', cs),
                        _buildMiniStat('FREE QTY', orderDetail['FQty']?.toString() ?? '0', cs),
                        _buildMiniStat('RATE', '₹${orderDetail['Rate']?.toString() ?? '0'}', cs),
                      ],
                    ),
                  ),

                  _buildDetailRow('Base Amount', '₹${orderDetail['Amt']?.toString() ?? '0'}', cs),

                  if ((orderDetail['DiscAmt'] ?? '').toString().isNotEmpty && orderDetail['DiscAmt'].toString() != '0')
                    _buildDetailRow('Discount', '- ₹${orderDetail['DiscAmt']}', cs, valueColor: Colors.green.shade700),

                  if ((orderDetail['SchAmt'] ?? '').toString().isNotEmpty && orderDetail['SchAmt'].toString() != '0')
                    _buildDetailRow('Scheme Amount', '- ₹${orderDetail['SchAmt']}', cs, valueColor: Colors.green.shade700),

                  _buildDetailRow('Tax Amount', '+ ₹${orderDetail['TaxAmt']?.toString() ?? '0'}', cs),
                  _buildDetailRow('Delivery Charges', '+ ₹${orderDetail['DelCharges']?.toString() ?? '0'}', cs),

                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    child: Divider(color: cs.outlineVariant, thickness: 1, height: 1),
                  ),

                  // Grand Total Block
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Text('Net Payable', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: cs.onSurface)),
                      Text(
                        '₹${orderDetail['OrderValue']?.toString() ?? '0.00'}',
                        style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: cs.primary),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // --- SECTION 3: ACCOUNT & FIRM ---
            _buildCard(
              cs: cs,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSectionHeader('Parties Involved', Icons.storefront_outlined, cs),

                  // Account Info
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

                  // Firm Info
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
}