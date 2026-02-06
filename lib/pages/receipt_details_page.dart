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
    final String partyName = receipt['acName']?.toString() ?? receipt['party']?.toString() ?? 'Unknown Party';
    final String id = receipt['id']?.toString() ?? '0';
    final String acno = receipt['acno']?.toString() ?? '';
    final String paymentType = receipt['type']?.toString() ?? 'N/A';
    final String customerName = receipt['customerName']?.toString() ?? '';
    final String firmName = receipt['firmName']?.toString() ?? '';
    final String firmAdd1 = receipt['firmAdd1']?.toString() ?? '';
    final String firmAdd2 = receipt['firmAdd2']?.toString() ?? '';
    final String narration = receipt['narration']?.toString() ?? '';
    final String docno = receipt['docno']?.toString() ?? '';
    final String docdt = receipt['docdt']?.toString() ?? '';

    String formatDate(dynamic date) {
      if (date == null || date == '') return 'N/A';
      if (date is DateTime) return DateFormat('dd/MMM/yyyy').format(date);
      try {
        if (date.toString().isEmpty) return 'N/A';
        final parsed = DateTime.parse(date.toString());
        return DateFormat('dd/MMM/yyyy').format(parsed);
      } catch (_) {
        return date.toString();
      }
    }

    final createdDate = formatDate(receipt['date']);
    final docDate = formatDate(docdt);

    // Get adjustments from Item array
    List<dynamic> adjustments = [];
    if (receipt['Item'] is List) {
      adjustments = receipt['Item'] as List;
      debugPrint('[ReceiptDetails] Found ${adjustments.length} adjustment items');
    }

    return Scaffold(
      backgroundColor: colorScheme.surfaceContainerHigh,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        title: Text("Receipt Details",
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
                color: colorScheme.surface,
                borderRadius: BorderRadius.circular(24),
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
                  // --- TOP SECTION: RECEIPT ID & AMOUNT ---
                  Container(
                    padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 24),
                    decoration: BoxDecoration(
                      color: colorScheme.surface,
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                    ),
                    child: Column(
                      children: [
                        Text(
                          "Receipt ID: $id",
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: colorScheme.primary,
                            letterSpacing: 0.5,
                            fontFamily: 'Monospace',
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          "₹${NumberFormat('#,##0.00').format(double.tryParse(amount.replaceAll(',', '')) ?? 0)}",
                          style: TextStyle(
                            fontSize: 36,
                            fontWeight: FontWeight.w800,
                            color: colorScheme.onSurface,
                            letterSpacing: -0.5,
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
                        // Row 1: Created Date & Account Name
                        _buildDataRow(context,
                            label1: "Created Date",
                            value1: createdDate,
                            label2: "Account Name",
                            value2: partyName.trim()),
                        const SizedBox(height: 24),

                        // Row 2: Payment Mode & Amount
                        _buildDataRow(context,
                            label1: "Payment Mode",
                            value1: paymentType,
                            label2: "Amount",
                            value2: "₹${NumberFormat('#,##0.00').format(double.tryParse(amount.replaceAll(',', '')) ?? 0)}"),
                        const SizedBox(height: 24),

                        // Row 3: Discount Amount
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "Discount Amount",
                              style: TextStyle(
                                fontSize: 12,
                                color: colorScheme.onSurfaceVariant.withOpacity(0.8),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              "₹${NumberFormat('#,##0.00').format(double.tryParse(receipt['disc_amount']?.toString().replaceAll(',', '') ?? '0') ?? 0)}",
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                                color: colorScheme.onSurface,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),

                        // --- ADJUSTMENT DETAILS TABLE ---
                        if (adjustments.isNotEmpty) ...[
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
                                    Text("Key No.", style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: colorScheme.onSurfaceVariant)),
                                    Text("Amount", style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: colorScheme.onSurfaceVariant)),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Divider(height: 1, color: colorScheme.outlineVariant.withOpacity(0.5)),
                                const SizedBox(height: 12),

                                // Rows
                                ...adjustments.map<Widget>((adj) {
                                  String keyNo = '';
                                  String amt = '';
                                  if (adj is Map) {
                                    keyNo = (adj['KeyNo'] ?? adj['keyNo'] ?? adj['billnumber'] ?? '').toString();
                                    final amountValue = adj['amount'];
                                    if (amountValue is num) {
                                      amt = amountValue.toStringAsFixed(2);
                                    } else {
                                      amt = amountValue?.toString() ?? '0.00';
                                    }
                                  } else {
                                    keyNo = adj.toString();
                                  }

                                  return Padding(
                                    padding: const EdgeInsets.only(bottom: 12.0),
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Expanded(
                                          child: Row(
                                            children: [
                                              Icon(Icons.receipt_long, size: 14, color: colorScheme.primary.withValues(alpha: 0.7)),
                                              const SizedBox(width: 8),
                                              Expanded(
                                                child: Text(
                                                  keyNo.trim(),
                                                  style: TextStyle(
                                                    fontSize: 14,
                                                    fontWeight: FontWeight.w600,
                                                    color: colorScheme.onSurface,
                                                    fontFamily: 'Monospace',
                                                  ),
                                                  overflow: TextOverflow.ellipsis,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        Text(
                                          amt.isNotEmpty ? "₹$amt" : "₹0.00",
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
                          const SizedBox(height: 24),
                        ],
                      ],
                    ),
                  ),

                  // --- NARRATION SECTION ---
                  if (narration.isNotEmpty)
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
                  backgroundColor: colorScheme.primary,
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
              color: colorScheme.surfaceContainerHigh,
              borderRadius: const BorderRadius.horizontal(left: Radius.circular(20)),
            ),
          ),
        ),
      ],
    );
  }
}