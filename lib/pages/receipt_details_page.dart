import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class ReceiptDetailsPage extends StatelessWidget {
  final Map<String, dynamic> receipt;

  const ReceiptDetailsPage({super.key, required this.receipt});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    // --- Data Mapping with safe type conversion ---
    final String amount = receipt['amount']?.toString() ?? '0';
    final String partyName = receipt['acName']?.toString() ?? receipt['party']?.toString() ?? receipt['accountName']?.toString() ?? 'Unknown Party';
    final String id = receipt['id']?.toString() ?? '0';

    String formatDate(dynamic date) {
      if (date == null) return 'N/A';
      if (date is DateTime) return DateFormat('dd/MMM/yyyy').format(date);
      try {
        final parsed = DateTime.parse(date.toString());
        return DateFormat('dd/MMM/yyyy').format(parsed);
      } catch (_) {
        return date.toString();
      }
    }

    // Extract data from details or fallback to main receipt
    final detailsData = receipt['details'];

    // Get adjustments from Item array - could be in details.Item or directly in receipt
    List<dynamic> adjustments = [];

    if (detailsData != null && detailsData is Map) {
      // First check if Item is in the details
      if (detailsData['Item'] is List) {
        adjustments = detailsData['Item'] as List;
      }
    }

    // Fallback: check if Item is directly in receipt
    if (adjustments.isEmpty && receipt['Item'] is List) {
      adjustments = receipt['Item'] as List;
    }

    debugPrint('[ReceiptDetails] Found ${adjustments.length} adjustment items');

    final String createdDate = formatDate(receipt['date'] ?? receipt['entryDate'] ?? receipt['createdDate']);
    final String paymentMode = (receipt['type'] ?? receipt['mode'] ?? receipt['paymentMode'] ?? 'N/A').toString();
    final String docNo = (receipt['docno'] ?? receipt['docNo'] ?? '-').toString();
    final String docDate = formatDate(receipt['docdt'] ?? receipt['docDate']);
    final String? narration = receipt['narration']?.toString();

    return Scaffold(
      // UPDATED: Use a neutral surface tone instead of a strong color
      backgroundColor: colorScheme.surfaceContainerHigh,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        title: Text("Transaction Details",
            style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: colorScheme.onSurface)),
        leading: IconButton(
          icon: Icon(Icons.close_rounded, color: colorScheme.onSurface),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 10, 20, 40),
        child: Column(
          children: [
            // --- THE TICKET CARD ---
            Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: colorScheme.surface, // Clean White Card
                borderRadius: BorderRadius.circular(24),
                // Deeper shadow for "floating" effect on grey background
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.08),
                    blurRadius: 24,
                    offset: const Offset(0, 12),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // --- TOP SECTION: AMOUNT & PARTY ---
                  Container(
                    padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 24),
                    decoration: BoxDecoration(
                      color: colorScheme.surface,
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                    ),
                    child: Column(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.green.withOpacity(0.1),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.check_rounded, color: Colors.green, size: 32),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          "Payment Received",
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Colors.green,
                            letterSpacing: 0.5,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          "₹${NumberFormat('#,##0').format(double.tryParse(amount.replaceAll(',', '')) ?? 0)}",
                          style: TextStyle(
                            fontSize: 42,
                            fontWeight: FontWeight.w800,
                            color: colorScheme.onSurface,
                            letterSpacing: -1.0,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          "from $partyName",
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 16,
                            color: colorScheme.onSurfaceVariant,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // --- DASHED DIVIDER ---
                  _buildDashedLine(context, colorScheme),

                  // --- MIDDLE SECTION: DETAILS ---
                  Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Row 1
                        _buildDataRow(context,
                            label1: "Created Date",
                            value1: createdDate,
                            label2: "Payment Mode",
                            value2: paymentMode),
                        const SizedBox(height: 24),

                        // Row 2
                        _buildDataRow(context,
                            label1: "Document No",
                            value1: docNo,
                            label2: "Document Date",
                            value2: docDate),
                        const SizedBox(height: 24),

                        // --- ADJUSTMENT DETAILS TABLE ---
                        Row(
                          children: [
                            Icon(Icons.list_alt_rounded, size: 16, color: colorScheme.primary),
                            const SizedBox(width: 8),
                            Text(
                              "ADJUSTMENT DETAILS",
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: colorScheme.primary,
                                letterSpacing: 1.0,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),

                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: colorScheme.surfaceContainerLow,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: colorScheme.outlineVariant.withOpacity(0.3)),
                          ),
                          child: Column(
                            children: [
                              // Table Header
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text("No.", style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: colorScheme.onSurfaceVariant)),
                                  Text("Amount", style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: colorScheme.onSurfaceVariant)),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Divider(height: 1, color: colorScheme.outlineVariant.withOpacity(0.5)),
                              const SizedBox(height: 12),

                              // Rows
                              ...adjustments.map<Widget>((adj) {
                                String no = '';
                                String amt = '';
                                if (adj is Map) {
                                  // API returns 'billnumber' and 'amount'
                                  no = (adj['billnumber'] ?? adj['no'] ?? adj['KeyNo'] ?? '').toString();
                                  final amountValue = adj['amount'];
                                  if (amountValue is num) {
                                    amt = amountValue.toStringAsFixed(2);
                                  } else {
                                    amt = amountValue?.toString() ?? '0.00';
                                  }
                                } else {
                                  no = adj.toString();
                                }

                                return Padding(
                                  padding: const EdgeInsets.only(bottom: 12.0),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Row(
                                        children: [
                                          Icon(Icons.receipt_long, size: 14, color: colorScheme.primary.withValues(alpha: 0.7)),
                                          const SizedBox(width: 8),
                                          Text(
                                            no,
                                            style: TextStyle(
                                              fontSize: 14,
                                              fontWeight: FontWeight.w600,
                                              color: colorScheme.onSurface,
                                              fontFamily: 'Monospace',
                                            ),
                                          ),
                                        ],
                                      ),
                                      Text(
                                        amt.isNotEmpty ? "₹$amt" : "",
                                        style: TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w700,
                                          color: colorScheme.onSurface,
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              }).toList(),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  // --- NARRATION SECTION ---
                  if (narration != null)
                    Container(
                      width: double.infinity,
                      margin: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: colorScheme.surfaceContainerLow,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.chat_bubble_outline, size: 16, color: colorScheme.primary),
                              const SizedBox(width: 8),
                              Text("NARRATION",
                                  style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                      color: colorScheme.primary)),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            narration,
                            style: TextStyle(
                                fontSize: 14,
                                color: colorScheme.onSurfaceVariant,
                                height: 1.4),
                          ),
                        ],
                      ),
                    ),

                  // --- FOOTER: RECEIPT ID ---
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    decoration: BoxDecoration(
                      color: colorScheme.surfaceContainerHighest.withOpacity(0.3),
                      borderRadius: const BorderRadius.vertical(bottom: Radius.circular(24)),
                    ),
                    child: Center(
                      child: Text(
                        "Receipt Id: $id",
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          fontFamily: 'Monospace',
                          color: colorScheme.onSurfaceVariant.withOpacity(0.8),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 32),

            // --- SHARE BUTTON ---
            SizedBox(
              width: double.infinity,
              height: 56,
              child: FilledButton.icon(
                onPressed: () {},
                style: FilledButton.styleFrom(
                  backgroundColor: colorScheme.primary, // Solid primary for CTA
                  foregroundColor: colorScheme.onPrimary,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  elevation: 2,
                ),
                icon: const Icon(Icons.share_rounded),
                label: const Text("Share Receipt", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- WIDGET HELPERS ---

  Widget _buildDataRow(BuildContext context,
      {required String label1,
        required String value1,
        required String label2,
        required String value2}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(child: _buildInfoColumn(context, label1, value1, CrossAxisAlignment.start)),
        Expanded(child: _buildInfoColumn(context, label2, value2, CrossAxisAlignment.end)),
      ],
    );
  }

  Widget _buildInfoColumn(BuildContext context, String label, String value, CrossAxisAlignment align) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: align,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: theme.colorScheme.onSurfaceVariant.withOpacity(0.8),
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: theme.colorScheme.onSurface,
          ),
          textAlign: align == CrossAxisAlignment.end ? TextAlign.right : TextAlign.left,
        ),
      ],
    );
  }

  Widget _buildDashedLine(BuildContext context, ColorScheme colorScheme) {
    return Row(
      children: [
        SizedBox(
          width: 20, height: 40,
          child: DecoratedBox(
            decoration: BoxDecoration(
              // Match the background color of the Scaffold (surfaceContainerHigh)
              color: colorScheme.surfaceContainerHigh,
              borderRadius: const BorderRadius.horizontal(right: Radius.circular(20)),
            ),
          ),
        ),
        Expanded(
          child: Flex(
            direction: Axis.horizontal,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: List.generate(15, (_) {
              return SizedBox(
                width: 8, height: 1,
                child: DecoratedBox(decoration: BoxDecoration(color: colorScheme.outlineVariant)),
              );
            }),
          ),
        ),
        SizedBox(
          width: 20, height: 40,
          child: DecoratedBox(
            decoration: BoxDecoration(
              // Match the background color of the Scaffold
              color: colorScheme.surfaceContainerHigh,
              borderRadius: const BorderRadius.horizontal(left: Radius.circular(20)),
            ),
          ),
        ),
      ],
    );
  }
}