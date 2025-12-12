import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class CreateReceiptScreen extends StatefulWidget {
  const CreateReceiptScreen({super.key});

  @override
  State<CreateReceiptScreen> createState() => _CreateReceiptScreenState();
}

class _CreateReceiptScreenState extends State<CreateReceiptScreen> {
  final _formKey = GlobalKey<FormState>();

  // Controllers
  final _amountController = TextEditingController();
  final _discAmtController = TextEditingController();
  final _docNoController = TextEditingController();
  final _narrationController = TextEditingController();

  // State
  String? _selectedAccount;
  String? _selectedPaymentMode;
  DateTime? _docDate;
  final DateTime _entryDate = DateTime.now();

  // Mock Data
  final List<String> _accounts = ['Cash Account', 'HDFC Bank', 'SBI Bank', 'Customer A'];
  final List<String> _paymentModes = ['Cash', 'Cheque', 'UPI', 'NEFT/RTGS'];

  @override
  void dispose() {
    _amountController.dispose();
    _discAmtController.dispose();
    _docNoController.dispose();
    _narrationController.dispose();
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

  void _submit() {
    if (_formKey.currentState!.validate()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Receipt Created'), backgroundColor: Colors.green),
      );
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

                    // --- 2. Account ---
                    _buildLabel(context, "Select Account"),
                    DropdownButtonFormField<String>(
                      value: _selectedAccount,
                      items: _accounts.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
                      onChanged: (v) => setState(() => _selectedAccount = v),
                      decoration: _homeThemeDecoration(context, "Choose Party / Bank", Icons.person_rounded),
                      validator: (v) => v == null ? 'Required' : null,
                    ),
                    const SizedBox(height: 20),

                    // --- 3. Amount & Discount ---
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          flex: 3,
                          child: Column(
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
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          flex: 2,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildLabel(context, "Disc Amt"),
                              TextFormField(
                                controller: _discAmtController,
                                keyboardType: TextInputType.number,
                                decoration: _homeThemeDecoration(context, "₹ 0", Icons.percent_rounded),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // --- 4. Payment Mode ---
                    _buildLabel(context, "Payment Mode"),
                    DropdownButtonFormField<String>(
                      value: _selectedPaymentMode,
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
                  color: Colors.black.withOpacity(0.05),
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
          color: Theme.of(context).colorScheme.onSurface.withOpacity(0.8),
        ),
      ),
    );
  }

  // Uses the exact same style as the Home Screen Cards
  InputDecoration _homeThemeDecoration(BuildContext context, String hint, IconData icon) {
    final colorScheme = Theme.of(context).colorScheme;
    return InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(color: colorScheme.onSurfaceVariant.withOpacity(0.4), fontSize: 14),

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
        borderSide: BorderSide(color: colorScheme.primary.withOpacity(0.5), width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: colorScheme.error.withOpacity(0.5)),
      ),
    );
  }
}