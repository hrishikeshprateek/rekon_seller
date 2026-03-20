import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:dio/dio.dart';
import '../auth_service.dart';
import '../models/product_model.dart';
import '../models/account_model.dart';
import '../services/salesman_flags_service.dart';

/// Quick quantity adjuster widget - allows adding/removing 1 quantity at a time directly to cart
class QuickQuantityAdjuster extends StatefulWidget {
  final Product product;
  final int currentQuantity;
  final Account selectedAccount;
  final VoidCallback onQuantityChanged;

  const QuickQuantityAdjuster({
    Key? key,
    required this.product,
    required this.currentQuantity,
    required this.selectedAccount,
    required this.onQuantityChanged,
  }) : super(key: key);

  @override
  State<QuickQuantityAdjuster> createState() => _QuickQuantityAdjusterState();
}

class _QuickQuantityAdjusterState extends State<QuickQuantityAdjuster> {
  bool _isLoading = false;

  Future<void> _addToCart(int newQuantity) async {
    if (newQuantity < 0) {
      // Don't allow negative quantity
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Quantity cannot be negative')),
      );
      return;
    }

    // If trying to set to 0, don't send to API
    if (newQuantity == 0) {
      return;
    }

    setState(() => _isLoading = true);

    try {
      final auth = Provider.of<AuthService>(context, listen: false);
      final dio = auth.getDioClient();

      // Get firm code
      String firmCode = '';
      try {
        final stores = auth.currentUser?.stores;
        if (stores != null && stores.isNotEmpty) {
          final primary = stores.firstWhere((s) => s.primary == true, orElse: () => stores.first);
          firmCode = primary.firmCode;
        }
      } catch (_) {
        firmCode = '';
      }

      final acCode = widget.selectedAccount.code ??
          (widget.selectedAccount.acIdCol != null ? widget.selectedAccount.acIdCol.toString() : widget.selectedAccount.id ?? '');
      final cuId = int.tryParse(auth.currentUser?.userId ?? '') ?? 0;

      final payload = {
        'UserId': auth.currentUser?.mobileNumber ?? auth.currentUser?.userId ?? '',
        'LicNo': auth.currentUser?.licenseNumber ?? '',
        'lFirmCode': firmCode,
        'AcCode': acCode,
        'ItemCode': widget.product.code ?? widget.product.id,
        'ItemQty': newQuantity.toString(),
        'ItemRate': widget.product.price.toStringAsFixed(2),
        'IdCol': widget.product.iidcol ?? int.tryParse(widget.product.id) ?? 0,
        'cu_id': cuId,
        'ItemFQty': '',
        'ItemSchQty': '0.0',
        'ItemDSchQty': '0.0',
        'ItemAmt': '0.0',
        'discount_percentage': '',
        'discount_percentage1': '',
        'discount_pcs': '0.0',
        'remark': '',
        'insert_record': 1,
        'default_hit': true,
      };

      final headers = {
        'Content-Type': 'application/json',
        'package_name': auth.packageNameHeader,
        if (auth.getAuthHeader() != null) 'Authorization': auth.getAuthHeader(),
      };

      debugPrint('[QuickQuantityAdjuster] Adding ${widget.product.name} with qty: $newQuantity');

      final response = await dio.post(
        '/AddDraftOrder',
        data: payload,
        options: Options(headers: headers),
      );

      if (mounted) {
        final success = response.statusCode == 200;
        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('${widget.product.name}: Qty = $newQuantity'),
              duration: const Duration(milliseconds: 800),
            ),
          );
          widget.onQuantityChanged();
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Failed to update quantity')),
          );
        }
      }
    } catch (e) {
      debugPrint('[QuickQuantityAdjuster] Error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final cs = colorScheme;
    final hasStock = widget.product.stockQuantity > 0;


    // Check flag: only show if ShowIncreaseDecreaseButton_SalesMan is true
    final showIncreaseDecreaseButton = context.watch<SalesmanFlagsService>().flags?.showIncreaseDecreaseButtonSalesMan ?? true;
    if (!showIncreaseDecreaseButton) {
      return const SizedBox.shrink();
    }

    return Container(
      decoration: BoxDecoration(
        color: cs.surfaceContainerLow,
        borderRadius: BorderRadius.circular(8),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Minus button
          SizedBox(
            width: 28,
            height: 28,
            child: IconButton(
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
              icon: const Icon(Icons.remove, size: 14),
              onPressed: _isLoading || widget.currentQuantity <= 0 ? null : () {
                final newQty = widget.currentQuantity - 1;
                _addToCart(newQty);
              },
              style: IconButton.styleFrom(
                backgroundColor: cs.errorContainer.withValues(alpha: 0.5),
                foregroundColor: cs.error,
                disabledBackgroundColor: cs.outlineVariant.withValues(alpha: 0.2),
              ),
            ),
          ),
          const SizedBox(width: 6),
          // Quantity display
          SizedBox(
            width: 28,
            child: Center(
              child: Text(
                '${widget.currentQuantity}',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: cs.onSurface,
                ),
              ),
            ),
          ),
          const SizedBox(width: 6),
          // Plus button
          SizedBox(
            width: 28,
            height: 28,
            child: IconButton(
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
              icon: const Icon(Icons.add, size: 14),
              onPressed: _isLoading || !hasStock ? null : () {
                final newQty = widget.currentQuantity + 1;
                if (newQty <= widget.product.stockQuantity) {
                  _addToCart(newQty);
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Only ${widget.product.stockQuantity} in stock'),
                    ),
                  );
                }
              },
              style: IconButton.styleFrom(
                backgroundColor: cs.primaryContainer.withValues(alpha: 0.5),
                foregroundColor: cs.primary,
                disabledBackgroundColor: cs.outlineVariant.withValues(alpha: 0.2),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

