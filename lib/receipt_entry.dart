import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'auth_service.dart';
import 'pages/select_account_page.dart';
import 'pages/attach_bills_page.dart';
import 'models/account_model.dart' as models;
import 'dart:convert';
import 'package:dio/dio.dart';
import 'dart:io';
import 'dart:typed_data';
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:cross_file/cross_file.dart';

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
  String? _selectedAccountNo;
  String? _selectedPaymentMode;
  DateTime? _docDate = DateTime.now(); // Default to today's date
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

    // Add listener to amount controller to trigger state updates
    _amountController.addListener(() {
      setState(() {
        // Rebuild to update button enabled state
      });
    });

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

      // When bills are passed, prefill amount with total bill payments.
      final total = _lines.fold<double>(0, (s, l) => s + (l.included ? l.payment : 0));
      _amountController.text = total.toStringAsFixed(2);
      print('[ReceiptEntry] Bills loaded: ${_lines.length}, Total: $total');
    }

    // Prefill selected account name/number if provided
    final hasName = widget.accountName != null && widget.accountName!.isNotEmpty;
    final hasNo = widget.accountNo != null && widget.accountNo!.isNotEmpty;

    if (hasName) {
      _selectedAccount = widget.accountName;
      _selectedAccountNo = widget.accountNo;
      print('[ReceiptEntry] Account set to: $_selectedAccount (from name)');
    } else if (hasNo) {
      _selectedAccount = widget.accountNo;
      _selectedAccountNo = widget.accountNo;
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

  // Helper to check if Add Bills button should be enabled
  bool get _canAddBills {
    final hasAccount = _selectedAccount != null && _selectedAccount!.isNotEmpty;
    final hasAmount = _amountController.text.trim().isNotEmpty &&
                      (double.tryParse(_amountController.text.replaceAll(',', '')) ?? 0) > 0;
    return hasAccount && hasAmount;
  }

  void _onLinePaymentChanged(int idx, String v) {
    final parsed = double.tryParse(v.replaceAll(',', '')) ?? 0.0;
    setState(() {
      _lines[idx].payment = parsed;
      // Only update amount if bills were passed from previous screen
      // If bills were added manually after entering amount, keep the original amount
      if (widget.selectedBills != null && widget.selectedBills!.isNotEmpty) {
        _amountController.text = _linesTotal.toStringAsFixed(2);
      }
    });
  }

  void _toggleLineIncluded(int idx, bool? val) {
    setState(() {
      _lines[idx].included = val ?? false;
      if (!_lines[idx].included) _lines[idx].payment = 0.0;
      // Only update amount if bills were passed from previous screen
      // If bills were added manually after entering amount, keep the original amount
      if (widget.selectedBills != null && widget.selectedBills!.isNotEmpty) {
        _amountController.text = _linesTotal.toStringAsFixed(2);
      }
    });
  }

  Future<void> _submit() async {
    if (_formKey.currentState == null) return;
    if (!_formKey.currentState!.validate()) return;

    // Show confirmation dialog first
    final confirmed = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text(
            'Submit Receipt Alert!',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(height: 16),
                Icon(
                  Icons.warning_rounded,
                  size: 64,
                  color: Theme.of(context).colorScheme.error,
                ),
                const SizedBox(height: 20),
                Text(
                  'This is an irreversible process, you can\'t change this later. Please verify all the details before final submitting.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    color: Theme.of(context).colorScheme.onSurface,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          actions: [
            SizedBox(
              width: 100,
              child: OutlinedButton(
                onPressed: () => Navigator.of(context).pop(false),
                style: OutlinedButton.styleFrom(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                child: const Text('Change'),
              ),
            ),
            const SizedBox(width: 12),
            SizedBox(
              width: 100,
              child: FilledButton(
                onPressed: () => Navigator.of(context).pop(true),
                style: FilledButton.styleFrom(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                child: const Text('Submit'),
              ),
            ),
          ],
        );
      },
    );

    // If user didn't confirm, return without submitting
    if (confirmed != true) {
      return;
    }

    // Proceed with actual submission
    await _submitReceipt();
  }

  Future<void> _submitReceipt() async {

    // Build payload expected by SubmitReceipt API
    final auth = Provider.of<AuthService>(context, listen: false);
    final dio = auth.getDioClient();

    final adjustmentDetails = _lines.where((l) => l.included && l.payment != 0).map((l) => {
      'id': l.keyEntryNo, //keyentryno
      'amount': l.payment,
      'bill_number': l.entryNo,
    }).toList();

    // Parse amount and discount values
    final baseAmount = double.tryParse(_amountController.text.replaceAll(',', '')) ?? 0.0;
    final discountAmount = double.tryParse(_discountController.text.replaceAll(',', '')) ?? 0.0;

    // Don't combine discount with amount - send them separately
    // (Keeping them separate as per requirement)

    // Get firmCode from user's stores
    String firmCode = '';
    try {
      final stores = auth.currentUser?.stores ?? [];
      if (stores.isNotEmpty) {
        // Find primary store or use first store
        final primary = stores.firstWhere(
          (s) => s.primary,
          orElse: () => stores.first,
        );
        firmCode = primary.firmCode;
        print('[ReceiptEntry] Using firmCode from stores: $firmCode');
      } else {
        print('[ReceiptEntry] No stores found for user');
      }
    } catch (e) {
      print('[ReceiptEntry] Error getting firmCode: $e');
    }

    final payload = {
      'lLicNo': auth.currentUser?.licenseNumber ?? '',
      'lFirmCode': firmCode,
      'lUserId': auth.currentUser?.mobileNumber ?? '',
      'lAcNo': _selectedAccountNo ?? widget.accountNo ?? '',
      'entry_date': DateFormat('dd/MMM/yyyy').format(_entryDate),
      'receipt_date': _docDate != null ? DateFormat('dd/MMM/yyyy').format(_docDate!) : DateFormat('dd/MMM/yyyy').format(_entryDate),
      'amount': baseAmount,  // Send base amount separately
      'disc_amount': discountAmount,  // Send discount separately
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

          // Get the response data
          final responseData = normalized['data'] as Map<String, dynamic>? ?? {};

          // Navigate to confirmation page with the response data
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(
              builder: (context) => ReceiptSubmissionConfirmation(
                receiptData: responseData,
                adjustmentDetails: adjustmentDetails,
                selectedAccountName: _selectedAccount ?? 'N/A',
              ),
            ),
          );
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
    // Move local display vars here so they are not declared inside the widget children
    final displayName = _selectedAccount ?? widget.accountName;
    final displayNo = _selectedAccountNo ?? widget.accountNo;

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

                    // --- 1.5 Party Summary / Select Account ---
                    // Always show a select-account area: prefer local selection if present,
                    // otherwise fall back to widget-provided account info.
                    if ((displayName != null && displayName.isNotEmpty) || (displayNo != null && displayNo.isNotEmpty))
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
                            if (displayName != null && displayName.isNotEmpty)
                              Text(displayName, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
                            if (displayNo != null && displayNo.isNotEmpty)
                              Padding(
                                padding: const EdgeInsets.only(top: 4),
                                child: Text('Account No: ${displayNo}', style: const TextStyle(fontSize: 12, color: Colors.black54)),
                              ),
                          ],
                        ),
                      )
                    else
                      // No account selected: give user a clear CTA to select one
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        margin: const EdgeInsets.only(bottom: 12),
                        decoration: BoxDecoration(
                          color: colorScheme.surfaceContainerLow,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                'No account selected',
                                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: colorScheme.onSurface),
                              ),
                            ),
                            FilledButton.icon(
                              onPressed: () async {
                                // Open SelectAccountPage and wait for selection
                                final models.Account? result = await SelectAccountPage.show(context);
                                if (result != null) {
                                  setState(() {
                                    _selectedAccount = result.name;
                                    _selectedAccountNo = result.id;
                                  });
                                  // Debug
                                  print('[ReceiptEntry] Selected account: ${result.name} (${result.id})');
                                }
                              },
                              icon: const Icon(Icons.search),
                              label: const Text('Select Account'),
                            ),
                          ],
                        ),
                      ),

                    // --- 2. Select Account (dropdown removed, showing only party details above) ---
                    // Keeping the section commented for reference
                    const SizedBox(height: 20),


                    // --- 3. Amount ---
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildLabel(context, "Amount"),
                        TextFormField(
                          controller: _amountController,
                          keyboardType: TextInputType.number,
                          enabled: _selectedAccount != null && _selectedAccount!.isNotEmpty,
                          style: TextStyle(fontWeight: FontWeight.w700, color: colorScheme.primary, fontSize: 16),
                          decoration: _homeThemeDecoration(
                            context,
                            "₹ 0.00",
                            Icons.currency_rupee_rounded,
                            isDisabled: _selectedAccount == null || _selectedAccount!.isEmpty,
                          ),
                          validator: (v) => (v?.isEmpty ?? true) ? 'Required' : null,
                        ),
                        if (_selectedAccount == null || _selectedAccount!.isEmpty)
                          Padding(
                            padding: const EdgeInsets.only(top: 8, left: 4),
                            child: Text(
                              'Select an account first to enter amount',
                              style: TextStyle(fontSize: 12, color: colorScheme.error),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // --- 3.5 Discount (added back per request) ---
                    if (!(widget.selectedBills != null && widget.selectedBills!.isNotEmpty)) ...[
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildLabel(context, "Discount"),
                          TextFormField(
                            controller: _discountController,
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                            decoration: _homeThemeDecoration(context, "₹ 0.00", Icons.currency_rupee_rounded),
                            // Discount is optional; keep numeric formatting to 2 decimals when submitting
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                    ],

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
                                validator: (v) {
                                  // Make doc number required when Bank is selected
                                  if (_selectedPaymentMode == 'Bank' && (v == null || v.trim().isEmpty)) {
                                    return 'Required for Bank';
                                  }
                                  return null;
                                },
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
                                    validator: (v) {
                                      // Make doc date required when Bank is selected
                                      if (_selectedPaymentMode == 'Bank' && _docDate == null) {
                                        return 'Required for Bank';
                                      }
                                      return null;
                                    },
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
                    if (_lines.isEmpty) ...[
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          SizedBox(
                            width: double.infinity,
                            height: 52,
                            child: FilledButton.tonalIcon(
                              onPressed: _canAddBills ? () async {
                                print('[ReceiptEntry] Attach Bills tapped for account: $_selectedAccount');

                                // Parse amount and discount
                                final baseAmount = double.tryParse(_amountController.text.replaceAll(',', '')) ?? 0.0;
                                final discountAmount = double.tryParse(_discountController.text.replaceAll(',', '')) ?? 0.0;

                                // Send total amount (base + discount) to AttachBillsPage for bill adjustment
                                final totalAmount = baseAmount + discountAmount;

                                // Navigate to AttachBillsPage with total amount (base + discount)
                                final result = await Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => AttachBillsPage(
                                      accountNo: _selectedAccountNo ?? '',
                                      accountName: _selectedAccount ?? '',
                                      amount: totalAmount,  // Pass total amount (base + discount) for bill adjustment
                                    ),
                                  ),
                                );

                                // Handle result if bills were selected
                                if (result != null && result is List<Map<String, dynamic>>) {
                                  print('[ReceiptEntry] Received bills from AttachBillsPage: $result');
                                  setState(() {
                                    // Convert the returned bills to _BillLine objects
                                    _lines = result.map((b) {
                                      final paymentAmt = (b['payment'] is num)
                                          ? (b['payment'] as num).toDouble()
                                          : double.tryParse(b['payment']?.toString() ?? '0') ?? 0.0;
                                      final outstandingAmt = (b['outstanding'] is num)
                                          ? (b['outstanding'] as num).toDouble()
                                          : double.tryParse(b['outstanding']?.toString() ?? '0') ?? 0.0;

                                      return _BillLine(
                                        included: true,
                                        entryNo: b['entryNo']?.toString() ?? '',
                                        date: b['date']?.toString() ?? '',
                                        outstanding: outstandingAmt,
                                        payment: paymentAmt, // This contains the adjusted amount
                                        keyEntryNo: b['keyEntryNo']?.toString() ?? '',
                                        dueDate: b['dueDate']?.toString() ?? '',
                                        trantype: b['trantype']?.toString() ?? '',
                                      );
                                    }).toList();

                                    // Don't update amount controller - keep the user-entered amount
                                    // Just add the bills to the list without changing amount/discount
                                  });
                                  print('[ReceiptEntry] Bills added: ${_lines.length}, Amount kept as: ${_amountController.text}');
                                }
                              } : null,
                              style: FilledButton.styleFrom(
                                backgroundColor: _canAddBills
                                    ? colorScheme.surfaceContainerLow
                                    : colorScheme.surfaceContainerLow,
                                foregroundColor: _canAddBills
                                    ? colorScheme.primary
                                    : colorScheme.onSurface.withValues(alpha: 0.38),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                elevation: 0,
                              ),
                              icon: const Icon(Icons.add_circle_outline_rounded),
                              label: const Text("Attach Bills / Invoices", style: TextStyle(fontWeight: FontWeight.w600)),
                            ),
                          ),
                          if (!_canAddBills) ...[
                            const SizedBox(height: 8),
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 4),
                              child: Text(
                                _selectedAccount == null || _selectedAccount!.isEmpty
                                    ? 'Select an account first to attach bills.'
                                    : 'Enter an amount to attach bills.',
                                style: TextStyle(fontSize: 12, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6)),
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 24),
                    ],

                    // --- 6.5 Selected Bills (if any) - Moved here from top ---
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
                      const SizedBox(height: 24),
                    ],

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
  InputDecoration _homeThemeDecoration(
    BuildContext context,
    String hint,
    IconData icon, {
    bool isDisabled = false,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    final disabledOpacity = isDisabled ? 0.5 : 1.0;

    return InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(
        color: colorScheme.onSurfaceVariant.withValues(alpha: isDisabled ? 0.2 : 0.4),
        fontSize: 14,
      ),

      // Icon inside a tonal box (Matches Home Screen Icon Tiles)
      prefixIcon: Opacity(
        opacity: disabledOpacity,
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Container(
            decoration: BoxDecoration(
              color: colorScheme.surface,
              borderRadius: BorderRadius.circular(8),
            ),
            padding: const EdgeInsets.all(6),
            child: Icon(icon, size: 20, color: colorScheme.primary),
          ),
        ),
      ),

      // Background matches Home Screen Card Background
      filled: true,
      fillColor: isDisabled
          ? colorScheme.surfaceContainerLow.withValues(alpha: 0.5)
          : colorScheme.surfaceContainerLow,

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
      disabledBorder: OutlineInputBorder(
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

// ============================================================================
// RECEIPT SUBMISSION CONFIRMATION PAGE
// ============================================================================

class ReceiptSubmissionConfirmation extends StatefulWidget {
  final Map<String, dynamic> receiptData;
  final List<Map<String, dynamic>> adjustmentDetails;
  final String selectedAccountName;

  const ReceiptSubmissionConfirmation({
    super.key,
    required this.receiptData,
    required this.adjustmentDetails,
    required this.selectedAccountName,
  });

  @override
  State<ReceiptSubmissionConfirmation> createState() =>
      _ReceiptSubmissionConfirmationState();
}

class _ReceiptSubmissionConfirmationState
    extends State<ReceiptSubmissionConfirmation> {
  bool _isLoadingPdf = false;

  Future<void> _downloadAndSharePdf() async {
    final auth = Provider.of<AuthService>(context, listen: false);
    final dio = auth.getDioClient();

    // Get receipt ID from receiptData
    final receiptId = widget.receiptData['no']?.toString() ?? '';
    if (receiptId.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Receipt ID not found'),
            duration: Duration(seconds: 2),
          ),
        );
      }
      return;
    }

    setState(() => _isLoadingPdf = true);

    try {
      // Parse receipt ID as integer
      final lid = int.tryParse(receiptId) ?? 0;

      final payload = {
        'lLicNo': auth.currentUser?.licenseNumber ?? '',
        'lUserId': auth.currentUser?.mobileNumber ?? '',
        'lid': lid,
        'lStatus': -1,
        'lFirm': '',
        'lSharePdf': 1,
      };

      debugPrint('[ReceiptConfirmation] GetReceiptDetail payload: $payload');

      final response = await dio.post(
        'http://mobileappsandbox.reckonsales.com:8080/reckon-biz/api/reckonpwsorder/GetReceiptDetail',
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
        throw 'No PDF data received from server.';
      }

      final dir = await getTemporaryDirectory();
      final file = File(
        '${dir.path}/receipt_${receiptId}_${DateTime.now().millisecondsSinceEpoch}.pdf',
      );
      await file.writeAsBytes(bytes, flush: true);

      final xfile = XFile(file.path, mimeType: 'application/pdf');

      if (mounted) {
        await Share.shareXFiles(
          [xfile],
          text: 'Receipt - ${widget.selectedAccountName}',
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Could not fetch/share PDF: $e'),
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoadingPdf = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    // Extract data from API response
    final receiptId = widget.receiptData['no']?.toString() ?? 'N/A';
    final createdDate = widget.receiptData['date']?.toString() ?? 'N/A';
    final accountName = widget.selectedAccountName;
    final accountCode = widget.receiptData['acCode']?.toString() ?? 'N/A';
    final paymentMode = widget.receiptData['mode']?.toString() ?? 'N/A';
    final amount = widget.receiptData['amount'] ?? 0.0;
    final discAmount = widget.receiptData['disc_amount'] ?? 0.0;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        backgroundColor: colorScheme.surface,
        elevation: 0,
        centerTitle: true,
        title: const Text(
          "Receipt Confirmation",
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
        leading: IconButton(
          icon: const Icon(Icons.close_rounded),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Success Message
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.green[50],
                border: Border.all(color: Colors.green[200]!),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Icon(Icons.check_circle_rounded, color: Colors.green[600], size: 24),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Receipt Submitted Successfully',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Colors.green[700],
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Receipt ID: $receiptId',
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.green[600],
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Account Name Section
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainerLow,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Account',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    accountName,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: colorScheme.onSurface,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Details Section
            Card(
              elevation: 0,
              color: colorScheme.surfaceContainerLow,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Receipt Details',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 16),
                    _buildDetailRow(context, 'Created Date', createdDate),
                    const SizedBox(height: 12),
                    _buildDetailRow(context, 'Account Code', accountCode),
                    const SizedBox(height: 12),
                    _buildDetailRow(context, 'Payment Mode', paymentMode),
                    const SizedBox(height: 12),
                    _buildDetailRow(context, 'Amount', '₹${NumberFormat('#,##0.00').format(amount)}'),
                    const SizedBox(height: 12),
                    _buildDetailRow(context, 'Discount Amount', '₹${NumberFormat('#,##0.00').format(discAmount)}'),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Adjustment Details
            if (widget.adjustmentDetails.isNotEmpty) ...[
              Text(
                'Adjustment Details',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 12),
              Card(
                elevation: 0,
                color: colorScheme.surfaceContainerLow,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      // Header
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              'Bill No.',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ),
                          Text(
                            'Amount',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                      const Divider(height: 16),
                      // Items
                      ...widget.adjustmentDetails.asMap().entries.map((entry) {
                        final idx = entry.key;
                        final item = entry.value;
                        final billNo = item['bill_number']?.toString() ?? 'N/A';
                        final adjAmount = item['amount'] ?? 0.0;

                        return Column(
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Text(
                                    billNo,
                                    style: const TextStyle(fontSize: 13),
                                  ),
                                ),
                                Text(
                                  '₹${NumberFormat('#,##0.00').format(adjAmount)}',
                                  style: const TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                            if (idx < widget.adjustmentDetails.length - 1)
                              const Divider(height: 16),
                          ],
                        );
                      }).toList(),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
            ],

            // Share Button
            SizedBox(
              width: double.infinity,
              height: 48,
              child: FilledButton.icon(
                onPressed: _isLoadingPdf ? null : _downloadAndSharePdf,
                icon: _isLoadingPdf
                    ? SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            colorScheme.onPrimary,
                          ),
                        ),
                      )
                    : const Icon(Icons.share_rounded, size: 20),
                label: Text(_isLoadingPdf ? 'Loading PDF...' : 'SHARE NOW'),
                style: FilledButton.styleFrom(
                  backgroundColor: colorScheme.primary,
                  disabledBackgroundColor: colorScheme.primary.withValues(alpha: 0.5),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(BuildContext context, String label, String value) {
    final colorScheme = Theme.of(context).colorScheme;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 13,
            color: colorScheme.onSurfaceVariant,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: colorScheme.onSurface,
          ),
        ),
      ],
    );
  }
}

