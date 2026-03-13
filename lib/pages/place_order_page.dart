import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../auth_service.dart';
import '../models/account_model.dart' as models;
import 'dart:convert';
import 'package:dio/dio.dart';
import 'order_confirmation_page.dart';

class PlaceOrderPage extends StatefulWidget {
  final models.Account account;
  final List<dynamic> cartItems;
  final double totalAmount;

  const PlaceOrderPage({
    Key? key,
    required this.account,
    required this.cartItems,
    required this.totalAmount,
  }) : super(key: key);

  @override
  State<PlaceOrderPage> createState() => _PlaceOrderPageState();
}

class _PlaceOrderPageState extends State<PlaceOrderPage> {
  late DateTime _deliveryDate;
  final TextEditingController _commentController = TextEditingController();
  bool _isSubmitting = false;

  // Add state for draft order value
  Map<String, dynamic>? _draftOrderValue;
  bool _isLoadingDraftOrderValue = true;
  String? _draftOrderValueError;

  @override
  void initState() {
    super.initState();
    // Set initial delivery date to today
    _deliveryDate = DateTime.now();
    _fetchDraftOrderValue();
  }

  Future<void> _fetchDraftOrderValue() async {
    setState(() {
      _isLoadingDraftOrderValue = true;
      _draftOrderValueError = null;
    });
    try {
      final auth = Provider.of<AuthService>(context, listen: false);
      final dio = auth.getDioClient();
      final user = auth.currentUser;
      String firmCode = '';
      try {
        if (user != null && user.stores.isNotEmpty) {
          final primary = user.stores.firstWhere((s) => s.primary, orElse: () => user.stores.first);
          firmCode = primary.firmCode;
        }
      } catch (_) {}
      // Use only code, fallback to id if code is null
      final acCode = widget.account.code ?? widget.account.id;
      final payload = {
        'lUserId': user?.mobileNumber ?? user?.userId ?? '',
        'lLicNo': user?.licenseNumber ?? '',
        'lFirmCode': firmCode,
        'AcCode': acCode,
        'app_role': 'SalesMan',
      };
      final headers = {
        'Content-Type': 'application/json',
        'package_name': auth.packageNameHeader,
        if (auth.getAuthHeader() != null) 'Authorization': auth.getAuthHeader(),
      };
      final response = await dio.post('/GetDraftOrderValue', data: payload, options: Options(headers: headers));
      final raw = response.data;
      Map<String, dynamic> parsed = {};
      if (raw is Map<String, dynamic>) {
        parsed = raw;
      } else if (raw is String) {
        final clean = raw.replaceAll(RegExp(r'[\x00-\x1F\x7F]'), '');
        parsed = jsonDecode(clean) as Map<String, dynamic>;
      } else {
        parsed = jsonDecode(jsonEncode(raw)) as Map<String, dynamic>;
      }
      if (parsed['success'] == true && parsed['data'] != null) {
        setState(() {
          _draftOrderValue = parsed['data'] as Map<String, dynamic>;
          _isLoadingDraftOrderValue = false;
        });
      } else {
        setState(() {
          _draftOrderValueError = parsed['message']?.toString() ?? 'Failed to fetch order value';
          _isLoadingDraftOrderValue = false;
        });
      }
    } catch (e) {
      setState(() {
        _draftOrderValueError = e.toString();
        _isLoadingDraftOrderValue = false;
      });
    }
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _submitOrder() async {
    if (_isSubmitting) return;
    setState(() => _isSubmitting = true);
    final scaffold = ScaffoldMessenger.of(context);
    try {
      final auth = Provider.of<AuthService>(context, listen: false);
      final dio = auth.getDioClient();
      final user = auth.currentUser;
      String firmCode = '';
      try {
        if (user != null && user.stores.isNotEmpty) {
          final primary = user.stores.firstWhere((s) => s.primary, orElse: () => user.stores.first);
          firmCode = primary.firmCode;
        }
      } catch (_) {}
      final payload = {
        'lUserId': user?.mobileNumber ?? user?.userId ?? '',
        'lLicNo': user?.licenseNumber ?? '',
        'lFirmCode': firmCode,
        'AcCode': widget.account.code ?? widget.account.id,
        'lDelMode': 0,
        'lNote': _commentController.text.trim(),
        'lSlotTime': _deliveryDate.toIso8601String().substring(0, 10),
        'lDelAdd': _fullDeliveryAddress(),
        'app_role': user?.userType ?? '',
      };
      final headers = {
        'Content-Type': 'application/json',
        'package_name': auth.packageNameHeader,
        if (auth.getAuthHeader() != null) 'Authorization': auth.getAuthHeader(),
      };
      final response = await dio.post('/SubmitOrder', data: payload, options: Options(headers: headers));
      final raw = response.data;
      Map<String, dynamic> parsed = {};
      if (raw is Map<String, dynamic>) {
        parsed = raw;
      } else if (raw is String) {
        final clean = raw.replaceAll(RegExp(r'[\x00-\x1F\x7F]'), '');
        parsed = jsonDecode(clean) as Map<String, dynamic>;
      } else {
        parsed = jsonDecode(jsonEncode(raw)) as Map<String, dynamic>;
      }
      // Print the API response in log
      print('SubmitOrder API response:');
      print(parsed);
      final success = (parsed['success'] == true || parsed['Status'] == true || parsed['status'] == true || parsed['rs'] == 1);
      if (!success) {
        throw Exception(parsed['message']?.toString() ?? parsed['data']?.toString() ?? 'Order submission failed');
      }
      if (mounted) {
        // Navigate to confirmation page with response
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (context) => OrderConfirmationPage(
              orderData: parsed['data'], // Pass orderData as required
            ),
          ),
        );
      }
    } catch (e) {
      scaffold.showSnackBar(SnackBar(content: Text('Order submission failed: $e')));
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  String _fullDeliveryAddress() {
    final parts = <String>[];
    final seen = <String>{};

    void addPart(String? value) {
      final trimmed = value?.trim() ?? '';
      if (trimmed.isEmpty) return;
      final key = trimmed.toLowerCase();
      if (seen.add(key)) parts.add(trimmed);
    }

    addPart(widget.account.address);
    addPart(widget.account.address2);
    addPart(widget.account.address3);
    if ((widget.account.pincode ?? '').trim().isNotEmpty) {
      addPart('Pincode: ${widget.account.pincode!.trim()}');
    }

    return parts.join(', ');
  }

  // --- UI HELPER WIDGETS ---

  Widget _buildSectionHeader(String title, IconData icon, ColorScheme cs) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Icon(icon, size: 20, color: cs.primary),
          const SizedBox(width: 8),
          Text(
            title,
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: 0.3, color: cs.onSurface),
          ),
        ],
      ),
    );
  }

  Widget _buildReceiptRow(String label, String value, ColorScheme cs, {bool isBold = false, Color? color}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 14,
              color: isBold ? cs.onSurface : cs.onSurfaceVariant,
              fontWeight: isBold ? FontWeight.bold : FontWeight.w500,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 14,
              color: color ?? (isBold ? cs.onSurface : cs.onSurface),
              fontWeight: isBold ? FontWeight.bold : FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final deliveryAddress = _fullDeliveryAddress();

    // Fallback success color (M3 standard doesn't officially enforce one)
    final successColor = const Color(0xFF2E7D32);

    return Scaffold(
      backgroundColor: cs.surfaceContainerLowest,
      appBar: AppBar(
        title: Text('Review Order', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 18, color: cs.onSurface)),
        centerTitle: true,
        backgroundColor: cs.surfaceContainerLowest,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        iconTheme: IconThemeData(color: cs.onSurface),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(color: cs.outlineVariant.withValues(alpha: 0.5), height: 1),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // --- DELIVERY DETAILS ---
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: cs.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: cs.outlineVariant),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildSectionHeader('Delivery Details', Icons.local_shipping_outlined, cs),

                // Address
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.location_on, size: 18, color: cs.onSurfaceVariant),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.account.name.isNotEmpty ? widget.account.name : 'Account Address',
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: cs.onSurface),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            deliveryAddress,
                            style: TextStyle(color: cs.onSurfaceVariant, fontSize: 13, height: 1.4),
                          ),
                          if ((widget.account.phone ?? '').isNotEmpty) ...[
                            const SizedBox(height: 6),
                            Row(
                              children: [
                                Icon(Icons.phone, size: 14, color: cs.onSurfaceVariant),
                                const SizedBox(width: 4),
                                Text(widget.account.phone!, style: TextStyle(color: cs.onSurfaceVariant, fontSize: 13)),
                              ],
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),

                Padding(padding: const EdgeInsets.symmetric(vertical: 12), child: Divider(height: 1, color: cs.outlineVariant)),

                // Date Picker Tile
                InkWell(
                  onTap: () async {
                    final today = DateTime.now();
                    final allowedDates = List.generate(4, (i) => DateTime(today.year, today.month, today.day).add(Duration(days: i)));
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: _deliveryDate,
                      firstDate: allowedDates.first,
                      lastDate: allowedDates.last,
                      selectableDayPredicate: (date) {
                        // Only allow exactly 4 days from today
                        return allowedDates.any((d) => d.year == date.year && d.month == date.month && d.day == date.day);
                      },
                      builder: (context, child) {
                        return Theme(
                          data: Theme.of(context).copyWith(
                            colorScheme: Theme.of(context).colorScheme.copyWith(
                              surface: Colors.white,
                            ),
                          ),
                          child: child!,
                        );
                      },
                    );
                    if (picked != null) setState(() => _deliveryDate = picked);
                  },
                  borderRadius: BorderRadius.circular(8),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Row(
                      children: [
                        Icon(Icons.calendar_month, size: 18, color: cs.onSurfaceVariant),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Expected Delivery', style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant)),
                              Text(
                                '${_deliveryDate.day.toString().padLeft(2, '0')}/${_deliveryDate.month.toString().padLeft(2, '0')}/${_deliveryDate.year}',
                                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: cs.onSurface),
                              ),
                            ],
                          ),
                        ),
                        Icon(Icons.edit_calendar, size: 18, color: cs.primary),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // --- ORDER SUMMARY ---
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: cs.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: cs.outlineVariant),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildSectionHeader('Order Summary', Icons.receipt_long_outlined, cs),

                // Items List
                ...widget.cartItems.map((item) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                            color: cs.primaryContainer,
                            borderRadius: BorderRadius.circular(6)
                        ),
                        child: Text('${item.qty}x', style: TextStyle(fontWeight: FontWeight.bold, color: cs.onPrimaryContainer, fontSize: 12)),
                      ),
                      const SizedBox(width: 10),
                      Expanded(child: Text(item.name, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: cs.onSurface))),
                      const SizedBox(width: 10),
                      Text('₹${item.amt?.toStringAsFixed(2) ?? '0.00'}', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: cs.onSurface)),
                    ],
                  ),
                )),

                const SizedBox(height: 8),
                Divider(color: cs.outlineVariant),
                const SizedBox(height: 8),

                // Base Total
                _buildReceiptRow('Items Total', '₹${widget.totalAmount.toStringAsFixed(2)}', cs, isBold: true),

                // Draft Order API Values
                if (_isLoadingDraftOrderValue)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    child: Center(child: SizedBox(height: 24, width: 24, child: CircularProgressIndicator(strokeWidth: 2, color: cs.primary))),
                  ),

                if (_draftOrderValueError != null)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Row(
                      children: [
                        Icon(Icons.error_outline, color: cs.error, size: 16),
                        const SizedBox(width: 8),
                        Expanded(child: Text(_draftOrderValueError!, style: TextStyle(color: cs.error, fontSize: 12))),
                      ],
                    ),
                  ),

                if (_draftOrderValue != null && _draftOrderValue!['Status'] == true) ...[
                  const SizedBox(height: 4),
                  if (_draftOrderValue!['Amt'] != null && _draftOrderValue!['Amt'].toString() != widget.totalAmount.toStringAsFixed(2))
                    _buildReceiptRow('Calculated Base', '₹${_draftOrderValue!['Amt']}', cs),
                  if (_draftOrderValue!['SchAmt'] != null)
                    _buildReceiptRow('Scheme Discount', '- ₹${_draftOrderValue!['SchAmt']}', cs, color: successColor),
                  if (_draftOrderValue!['DiscAmt'] != null)
                    _buildReceiptRow('Discount', '- ₹${_draftOrderValue!['DiscAmt']}', cs, color: successColor),
                  if (_draftOrderValue!['Disc1Amt'] != null)
                    _buildReceiptRow('Extra Discount 1', '- ₹${_draftOrderValue!['Disc1Amt']}', cs, color: successColor),
                  if (_draftOrderValue!['Disc2Amt'] != null)
                    _buildReceiptRow('Extra Discount 2', '- ₹${_draftOrderValue!['Disc2Amt']}', cs, color: successColor),
                  if (_draftOrderValue!['TaxAmt'] != null)
                    _buildReceiptRow('Taxes', '+ ₹${_draftOrderValue!['TaxAmt']}', cs),

                  Padding(padding: const EdgeInsets.symmetric(vertical: 8), child: Divider(color: cs.outlineVariant)),

                  if (_draftOrderValue!['NetAmt'] != null)
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Net Payable', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: cs.onSurface)),
                        Text('₹${_draftOrderValue!['NetAmt']}', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: cs.primary)),
                      ],
                    ),
                ],
              ],
            ),
          ),

          const SizedBox(height: 16),

          // --- COMMENTS ---
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: cs.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: cs.outlineVariant),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildSectionHeader('Additional Notes', Icons.notes, cs),
                TextField(
                  controller: _commentController,
                  maxLines: 3,
                  style: TextStyle(fontSize: 14, color: cs.onSurface),
                  decoration: InputDecoration(
                    hintText: 'Any special instructions for delivery...',
                    hintStyle: TextStyle(color: cs.onSurfaceVariant.withValues(alpha: 0.7)),
                    filled: true,
                    fillColor: cs.surfaceContainerHighest.withValues(alpha: 0.5),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: cs.outline),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: cs.outlineVariant),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: cs.primary, width: 1.5),
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 32),
        ],
      ),

      // --- STICKY BOTTOM BUTTON ---
      bottomNavigationBar: SafeArea(
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: cs.surfaceContainer,
            boxShadow: [
              BoxShadow(
                color: cs.shadow.withValues(alpha: 0.05),
                blurRadius: 10,
                offset: const Offset(0, -5),
              ),
            ],
          ),
          child: FilledButton(
            onPressed: _isSubmitting ? null : _submitOrder,
            style: FilledButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: _isSubmitting
                ? SizedBox(
                height: 22, width: 22,
                child: CircularProgressIndicator(strokeWidth: 2.5, color: cs.onPrimary)
            )
                : const Text(
                'Confirm & Place Order',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: 0.5)
            ),
          ),
        ),
      ),
    );
  }
}
