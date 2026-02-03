import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'auth_service.dart';
import 'dart:convert';
import 'package:dio/dio.dart';

class CreateReceiptScreen extends StatefulWidget {
  final String? accountNo;
  final String? accountName;
  final List<Map<String, dynamic>>? selectedBills;

  const CreateReceiptScreen({
    super.key,
    this.accountNo,
    this.accountName,
    this.selectedBills,
  });

  @override
  State<CreateReceiptScreen> createState() => _CreateReceiptScreenState();
}

class _BillLine {
  bool included;
  String entryNo;
  String date;
  double outstanding;
  double payment;
  String keyEntryNo;
  String dueDate;
  String trantype;

  _BillLine({
    required this.included,
    required this.entryNo,
    required this.date,
    required this.outstanding,
    required this.payment,
    required this.keyEntryNo,
    required this.dueDate,
    required this.trantype,
  });
}

class _CreateReceiptScreenState extends State<CreateReceiptScreen> {
  final _formKey = GlobalKey<FormState>();

  // Controllers
  final _amountController = TextEditingController();
  final _docNoController = TextEditingController();
  final _narrationController = TextEditingController();
  final _discountController = TextEditingController(text: '0.00');

  // State
  String? _selectedAccount;
  String? _selectedPaymentMode;
  DateTime? _docDate;
  final DateTime _entryDate = DateTime.now();

  // Account options come from the selected account passed into this screen
  final List<String> _paymentModes = ['Cash', 'Bank'];

  // Bill lines from selection
  List<_BillLine> _lines = [];

  @override
  void initState() {
    super.initState();
    // Debug: Log received data
    print('[ReceiptEntry] Received accountNo: ${widget.accountNo}');
    print('[ReceiptEntry] Received accountName: ${widget.accountName}');
    print('[ReceiptEntry] Received selectedBills count: ${widget.selectedBills?.length ?? 0}');

    // If bills were passed, initialize lines
    if (widget.selectedBills != null && widget.selectedBills!.isNotEmpty) {
      _lines = widget.selectedBills!.map((b) {
        final amt = (b['amount'] is num) ? (b['amount'] as num).toDouble() : double.tryParse(b['amount']?.toString() ?? '0') ?? 0.0;
        return _BillLine(
          included: true,
          entryNo: b['entryNo']?.toString() ?? '',
          date: b['date']?.toString() ?? '',
          outstanding: amt,
          payment: amt,
          keyEntryNo: b['keyEntryNo']?.toString() ?? '',
          dueDate: b['dueDate']?.toString() ?? '',
          trantype: b['trantype']?.toString() ?? '',
        );
      }).toList();

      // Prefill amount controller with sum of payments
      final total = _lines.fold<double>(0, (s, l) => s + (l.included ? l.payment : 0));
      _amountController.text = total.toStringAsFixed(2);
      print('[ReceiptEntry] Bills loaded: ${_lines.length}, Total: $total');
    }

    // Prefill selected account name/number if provided
    final hasName = widget.accountName != null && widget.accountName!.isNotEmpty;
    final hasNo = widget.accountNo != null && widget.accountNo!.isNotEmpty;

    if (hasName) {
      _selectedAccount = widget.accountName;
      print('[ReceiptEntry] Account set to: $_selectedAccount (from name)');
    } else if (hasNo) {
      _selectedAccount = widget.accountNo;
      print('[ReceiptEntry] Account set to: $_selectedAccount (from number)');
    } else {
      print('[ReceiptEntry] WARNING: No account info received!');
    }
  }

  @override
  void dispose() {
    _amountController.dispose();
    _docNoController.dispose();
    _narrationController.dispose();
    _discountController.dispose();
    super.dispose();
  }

  Future<void> _pickDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: Theme.of(context).colorScheme.primary,
              surface: Theme.of(context).colorScheme.surfaceContainerHigh,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() => _docDate = picked);
    }
  }

  double get _linesTotal => _lines.fold<double>(0, (s, l) => s + (l.included ? l.payment : 0));

  void _onLinePaymentChanged(int idx, String v) {
    final parsed = double.tryParse(v.replaceAll(',', '')) ?? 0.0;
    setState(() {
      _lines[idx].payment = parsed;
      _amountController.text = _linesTotal.toStringAsFixed(2);
    });
  }

  void _toggleLineIncluded(int idx, bool? val) {
    setState(() {
      _lines[idx].included = val ?? false;
      if (!_lines[idx].included) _lines[idx].payment = 0.0;
      // Update total
      _amountController.text = _linesTotal.toStringAsFixed(2);
    });
  }

  Future<void> _submit() async {
    if (_formKey.currentState == null) return;
    if (!_formKey.currentState!.validate()) return;

    // Build payload expected by SubmitReceipt API
    final auth = Provider.of<AuthService>(context, listen: false);
    final dio = auth.getDioClient();

    final adjustmentDetails = _lines.where((l) => l.included && l.payment > 0).map((l) => {
      'id': l.entryNo,
      'amount': l.payment,
      'bill_number': l.entryNo,
    }).toList();

    final payload = {
      'lLicNo': auth.currentUser?.licenseNumber ?? '',
      'lFirmCode': (auth.currentUser?.stores.isNotEmpty == true) ? auth.currentUser!.stores.first.firmCode : '',
      'lUserId': auth.currentUser?.userId ?? '',
      'lAcNo': widget.accountNo ?? '',
      'entry_date': DateFormat('dd/MMM/yyyy').format(_entryDate),
      'receipt_date': _docDate != null ? DateFormat('dd/MMM/yyyy').format(_docDate!) : DateFormat('dd/MMM/yyyy').format(_entryDate),
      'amount': double.tryParse(_amountController.text.replaceAll(',', '')) ?? 0.0,
      'discount': double.tryParse(_discountController.text.replaceAll(',', '')) ?? 0.0,
      'mode': _selectedPaymentMode ?? 'Cash',
      'doc_number': _docNoController.text.trim(),
      'narration': _narrationController.text.trim(),
      'adjustment_details': adjustmentDetails,
    };

    // Debug: Print complete request
    print('═══════════════════════════════════════════════════');
    print('📤 SUBMIT RECEIPT API REQUEST');
    print('═══════════════════════════════════════════════════');
    print('Endpoint: /SubmitReceipt');
    print('Headers:');
    print('  - Content-Type: application/json');
    print('  - package_name: ${auth.packageNameHeader}');
    print('  - Authorization: ${auth.getAuthHeader()?.substring(0, 20)}...');
    print('Payload:');
    print(jsonEncode(payload));
    print('═══════════════════════════════════════════════════\n');

    try {
      final response = await dio.post(
        '/SubmitReceipt',
        data: payload,
        options: Options(
          headers: {
            'Content-Type': 'application/json',
            'package_name': auth.packageNameHeader,
            if (auth.getAuthHeader() != null) 'Authorization': auth.getAuthHeader(),
          },
        ),
      );

      // Debug: Print complete response
      print('═══════════════════════════════════════════════════');
      print('📥 SUBMIT RECEIPT API RESPONSE');
      print('═══════════════════════════════════════════════════');
      print('Status Code: ${response.statusCode}');
      print('Response Type: ${response.data.runtimeType}');
      print('Raw Response:');
      print(response.data);
      print('═══════════════════════════════════════════════════\n');

      // Normalize response
      dynamic raw = response.data;
      Map<String, dynamic> normalized;
      if (raw is Map<String, dynamic>) {
        normalized = raw;
      } else if (raw is String) {
        try {
          final decoded = jsonDecode(raw);
          normalized = decoded is Map<String, dynamic> ? decoded : {'Message': raw};
        } catch (_) {
          normalized = {'Message': raw};
        }
      } else {
        try {
          normalized = Map<String, dynamic>.from(raw);
        } catch (_) {
          normalized = {'Message': response.toString()};
        }
      }

      // Debug: Print normalized response
      print('📋 Normalized Response:');
      print(jsonEncode(normalized));
      print('Success Check: success=${normalized['success']}, Status=${normalized['Status']}');
      print('═══════════════════════════════════════════════════\n');

      if (normalized['success'] == true || normalized['Status'] == true) {
        print('✅ Receipt submitted successfully!');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Receipt submitted successfully'), backgroundColor: Colors.green),
          );
          Navigator.of(context).pop(true);
        }
      } else {
        final errorMsg = normalized['Message'] ?? normalized['message'] ?? 'Unknown';
        print('❌ Receipt submission failed: $errorMsg');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to submit receipt: $errorMsg')),
          );
        }
      }
    } catch (e, stackTrace) {
      print('═══════════════════════════════════════════════════');
      print('❌ SUBMIT RECEIPT API ERROR');
      print('═══════════════════════════════════════════════════');
      print('Error: $e');
      print('Stack Trace:');
      print(stackTrace);
      print('═══════════════════════════════════════════════════\n');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Network error: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        title: const Text(
          "Create Receipt",
          style: TextStyle(fontWeight: FontWeight.w700, fontSize: 18),
        ),
        centerTitle: true,
        backgroundColor: colorScheme.surface,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // --- 1. Entry Date (Styled like Home Screen Badge) ---
                    Align(
                      alignment: Alignment.centerRight,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: colorScheme.primaryContainer,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.calendar_today_rounded, size: 14, color: colorScheme.onPrimaryContainer),
                            const SizedBox(width: 8),
                            Text(
                              "Entry: ${DateFormat('dd MMM yyyy').format(_entryDate)}",
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: colorScheme.onPrimaryContainer,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // --- 1.5 Party Summary ---
                    if (widget.accountName != null && widget.accountName!.isNotEmpty ||
                        widget.accountNo != null && widget.accountNo!.isNotEmpty)
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        margin: const EdgeInsets.only(bottom: 12),
                        decoration: BoxDecoration(
                          color: colorScheme.surfaceContainerLow,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (widget.accountName != null && widget.accountName!.isNotEmpty)
                              Text(widget.accountName!, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
                            if (widget.accountNo != null && widget.accountNo!.isNotEmpty)
                              Padding(
                                padding: const EdgeInsets.only(top: 4),
                                child: Text('Account No: ${widget.accountNo}', style: const TextStyle(fontSize: 12, color: Colors.black54)),
                              ),
                          ],
                        ),
                      ),

                    // --- 2. Select Account (dropdown removed, showing only party details above) ---
                    // Keeping the section commented for reference
                    const SizedBox(height: 20),

                    // --- 2.5 Selected Bills (if any) ---
                    if (_lines.isNotEmpty) ...[
                      _buildLabel(context, 'Selected Bills'),
                      const SizedBox(height: 8),
                      ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: _lines.length,
                        separatorBuilder: (_, __) => const Divider(height: 1),
                        itemBuilder: (context, idx) {
                          final l = _lines[idx];
                          return ListTile(
                            contentPadding: const EdgeInsets.symmetric(horizontal: 0, vertical: 6),
                            leading: Checkbox(
                              value: l.included,
                              onChanged: (v) => _toggleLineIncluded(idx, v),
                              visualDensity: VisualDensity.compact,
                              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            ),
                            title: Text('${l.entryNo}  •  ${l.date}'),
                            subtitle: Text('Outstanding: ₹${l.outstanding.toStringAsFixed(2)}'),
                            trailing: SizedBox(
                              width: 120,
                              child: TextFormField(
                                initialValue: l.payment.toStringAsFixed(2),
                                keyboardType: TextInputType.numberWithOptions(decimal: true),
                                onChanged: (v) => _onLinePaymentChanged(idx, v),
                                decoration: InputDecoration(
                                  isDense: true,
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Lines total', style: TextStyle(fontSize: 13, color: Colors.black54, fontWeight: FontWeight.w600)),
                          Text('₹${_linesTotal.toStringAsFixed(2)}', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: colorScheme.primary)),
                        ],
                      ),
                      const SizedBox(height: 20),
                    ],

                    // --- 3. Amount ---
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildLabel(context, "Amount"),
                        TextFormField(
                          controller: _amountController,
                          keyboardType: TextInputType.number,
                          style: TextStyle(fontWeight: FontWeight.w700, color: colorScheme.primary, fontSize: 16),
                          decoration: _homeThemeDecoration(context, "₹ 0.00", Icons.currency_rupee_rounded),
                          validator: (v) => (v?.isEmpty ?? true) ? 'Required' : null,
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // --- 3.5 Discount (added back per request) ---
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildLabel(context, "Discount"),
                        TextFormField(
                          controller: _discountController,
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                          decoration: _homeThemeDecoration(context, "₹ 0.00", Icons.percent),
                          // Discount is optional; keep numeric formatting to 2 decimals when submitting
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // --- 4. Payment Mode ---
                    _buildLabel(context, "Payment Mode"),
                    DropdownButtonFormField<String>(
                      initialValue: _selectedPaymentMode,
                      items: _paymentModes.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
                      onChanged: (v) => setState(() => _selectedPaymentMode = v),
                      decoration: _homeThemeDecoration(context, "Select Mode", Icons.payment_rounded),
                      validator: (v) => v == null ? 'Required' : null,
                    ),
                    const SizedBox(height: 20),

                    // --- 5. Doc No & Date ---
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildLabel(context, "Doc No."),
                              TextFormField(
                                controller: _docNoController,
                                decoration: _homeThemeDecoration(context, "Ref No.", Icons.numbers_rounded),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildLabel(context, "Doc Date"),
                              InkWell(
                                onTap: () => _pickDate(context),
                                borderRadius: BorderRadius.circular(12),
                                child: IgnorePointer(
                                  child: TextFormField(
                                    key: ValueKey(_docDate),
                                    initialValue: _docDate != null ? DateFormat('dd/MM/yyyy').format(_docDate!) : null,
                                    decoration: _homeThemeDecoration(context, "Select", Icons.event_rounded),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // --- 6. Add Bills (Button styled like Home Cards) ---
                    // Hide the "Attach Bills / Invoices" button when bills were passed into this screen
                    if (_lines.isEmpty)
                      SizedBox(
                        width: double.infinity,
                        height: 52,
                        child: FilledButton.tonalIcon(
                          onPressed: () {},
                          style: FilledButton.styleFrom(
                            backgroundColor: colorScheme.surfaceContainerLow, // Same as input bg
                            foregroundColor: colorScheme.primary,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            elevation: 0,
                          ),
                          icon: const Icon(Icons.add_circle_outline_rounded),
                          label: const Text("Attach Bills / Invoices", style: TextStyle(fontWeight: FontWeight.w600)),
                        ),
                      ),
                    const SizedBox(height: 24),

                    // --- 7. Narration ---
                    _buildLabel(context, "Narration"),
                    TextFormField(
                      controller: _narrationController,
                      maxLines: 3,
                      decoration: _homeThemeDecoration(context, "Add remarks...", Icons.edit_note_rounded),
                    ),
                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
          ),

          // --- Bottom Action Bar ---
          Container(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
            decoration: BoxDecoration(
              color: colorScheme.surface,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 10,
                  offset: const Offset(0, -4),
                ),
              ],
            ),
            child: SizedBox(
              width: double.infinity,
              height: 54,
              child: FilledButton(
                onPressed: _submit,
                style: FilledButton.styleFrom(
                  backgroundColor: colorScheme.primary,
                  foregroundColor: colorScheme.onPrimary,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 2,
                ),
                child: const Text(
                  "SUBMIT RECEIPT",
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: 0.5),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // --- WIDGET HELPERS ---

  Widget _buildLabel(BuildContext context, String label) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.8),
        ),
      ),
    );
  }

  // Uses the exact same style as the Home Screen Cards
  InputDecoration _homeThemeDecoration(BuildContext context, String hint, IconData icon) {
    final colorScheme = Theme.of(context).colorScheme;
    return InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(color: colorScheme.onSurfaceVariant.withValues(alpha: 0.4), fontSize: 14),

      // Icon inside a tonal box (Matches Home Screen Icon Tiles)
      prefixIcon: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Container(
          decoration: BoxDecoration(
            color: colorScheme.surface, // Icon bg is surface (white) to pop against container
            borderRadius: BorderRadius.circular(8),
          ),
          padding: const EdgeInsets.all(6),
          child: Icon(icon, size: 20, color: colorScheme.primary),
        ),
      ),

      // Background matches Home Screen Card Background
      filled: true,
      fillColor: colorScheme.surfaceContainerLow,

      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      isDense: true,

      // Border Radius matches Home Screen Tiles (12px - 16px)
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: colorScheme.primary.withValues(alpha: 0.5), width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: colorScheme.error.withValues(alpha: 0.5)),
      ),
    );
  }
}
