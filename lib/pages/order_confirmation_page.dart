import 'package:flutter/material.dart';

class OrderConfirmationPage extends StatelessWidget {
  /// Pass the `data` object from your API response here.
  /// Example: parsedResponse['data']
  final Map<String, dynamic> orderData;

  const OrderConfirmationPage({Key? key, required this.orderData}) : super(key: key);

  // --- UI HELPER WIDGETS ---

  Widget _buildSectionHeader(String title, IconData icon, ColorScheme cs) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: cs.primaryContainer.withAlpha((0.6 * 255).toInt()),
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

  Widget _buildDetailRow(String label, String? value, ColorScheme cs, {bool isBold = false, Color? valueColor}) {
    if (value == null || value.trim().isEmpty || value == 'null') return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
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
        border: Border.all(color: cs.outlineVariant.withAlpha((0.6 * 255).toInt())),
        boxShadow: [
          BoxShadow(
            color: cs.shadow.withAlpha((0.03 * 255).toInt()),
            blurRadius: 10,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: child,
    );
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    // Safely extract financial data to avoid null errors
    final itemAmt = orderData['ItemAmt']?.toString() ?? '0.00';
    final schAmt = orderData['SchAmt']?.toString() ?? '0.00';
    final discAmt = orderData['DiscAmt']?.toString() ?? '0.00';
    final disc1Amt = orderData['Disc1Amt']?.toString() ?? '0.00';
    final disc2Amt = orderData['Disc2Amt']?.toString() ?? '0.00';
    final taxAmt = orderData['TaxAmt']?.toString() ?? '0.00';
    final orderValue = orderData['OrderValue']?.toString() ?? '0.00';

    return Scaffold(
      backgroundColor: cs.surfaceContainerLowest,
      appBar: AppBar(
        automaticallyImplyLeading: false, // Remove default back button for a confirmation screen
        title: const Text('Order Confirmed', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 18)),
        centerTitle: true,
        backgroundColor: cs.surfaceContainerLowest,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // --- SUCCESS BANNER ---
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.fromLTRB(20, 10, 20, 30),
                    decoration: BoxDecoration(
                      color: cs.surfaceContainerLowest,
                      border: Border(bottom: BorderSide(color: cs.outlineVariant.withAlpha((0.5 * 255).toInt()))),
                    ),
                    child: Column(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.green.shade50,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(Icons.check_circle_rounded, size: 64, color: Colors.green.shade600),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Order Placed Successfully!',
                          style: TextStyle(fontWeight: FontWeight.w900, fontSize: 22, color: cs.onSurface),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Your order #${orderData['OrderId'] ?? ''} is currently ${orderData['OrderStatus'] ?? 'Pending'}.',
                          style: TextStyle(fontSize: 14, color: cs.onSurfaceVariant),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  // --- SECTION 1: ORDER INFO ---
                  _buildCard(
                    cs: cs,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildSectionHeader('Order Information', Icons.receipt_long_rounded, cs),
                        _buildDetailRow('Order ID', '#${orderData['OrderId']}', cs, isBold: true, valueColor: cs.primary),
                        _buildDetailRow('Placed On', orderData['PlacedOn'], cs),
                        _buildDetailRow('Status', orderData['OrderStatus'], cs, valueColor: Colors.orange.shade700, isBold: true),
                        _buildDetailRow('Firm Name', orderData['firm_name'], cs),
                      ],
                    ),
                  ),

                  // --- SECTION 2: DELIVERY INFO ---
                  _buildCard(
                    cs: cs,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildSectionHeader('Delivery Details', Icons.local_shipping_outlined, cs),
                        _buildDetailRow('Delivery Mode', orderData['DeliveryMode'], cs),
                        _buildDetailRow('Expected Date', orderData['DeliveryDate'], cs),
                        _buildDetailRow('Slot Time', orderData['SlotTime'], cs),
                        const SizedBox(height: 8),
                        Divider(color: cs.outlineVariant.withAlpha((100)), height: 1),
                        const SizedBox(height: 8),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(Icons.location_on_outlined, size: 16, color: cs.onSurfaceVariant),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                orderData['DelAdd'] ?? 'No address provided',
                                style: TextStyle(fontSize: 13.5, color: cs.onSurface, height: 1.4, fontWeight: FontWeight.w500),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  // --- SECTION 3: PAYMENT & BILLING ---
                  _buildCard(
                    cs: cs,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildSectionHeader('Payment & Billing', Icons.payments_outlined, cs),

                        _buildDetailRow('Payment Mode', orderData['PaymentMode'], cs, isBold: true),
                        const SizedBox(height: 8),

                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: cs.surfaceContainerHighest.withAlpha((0.3 * 255).toInt()),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Column(
                            children: [
                              _buildDetailRow('Item Amount', '₹$itemAmt', cs),
                              if (schAmt != '0.0' && schAmt != '0')
                                _buildDetailRow('Scheme Amount', '- ₹$schAmt', cs, valueColor: Colors.green.shade700),
                              if (discAmt != '0.0' && discAmt != '0')
                                _buildDetailRow('Discount', '- ₹$discAmt', cs, valueColor: Colors.green.shade700),
                              if (disc1Amt != '0.0' && disc1Amt != '0')
                                _buildDetailRow('Extra Discount 1', '- ₹$disc1Amt', cs, valueColor: Colors.green.shade700),
                              if (disc2Amt != '0.0' && disc2Amt != '0')
                                _buildDetailRow('Extra Discount 2', '- ₹$disc2Amt', cs, valueColor: Colors.green.shade700),

                              _buildDetailRow('Tax Amount', '+ ₹$taxAmt', cs),

                              Padding(
                                padding: const EdgeInsets.symmetric(vertical: 8),
                                child: Divider(color: cs.outlineVariant, thickness: 1, height: 1),
                              ),

                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  Text('Net Order Value', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: cs.onSurface)),
                                  Text(
                                    '₹$orderValue',
                                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: cs.primary),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),

          // --- BOTTOM ACTION BUTTON ---
          SafeArea(
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: cs.surface,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withAlpha((0.05 * 255).toInt()),
                    blurRadius: 10,
                    offset: const Offset(0, -5),
                  )
                ],
              ),
              child: SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () {
                    // Navigate back to the home/dashboard route
                    Navigator.of(context).popUntil((route) => route.isFirst);
                  },
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text('Back to Home', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: 0.5)),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}