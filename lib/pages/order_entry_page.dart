import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:convert';
import 'package:dio/dio.dart';
import '../auth_service.dart';
import '../models/account_model.dart' as models;
import '../models/product_model.dart';
import '../models/cart_item_model.dart';
import '../models/item_model.dart';
import 'select_account_page.dart';
import 'item_filter_page.dart';

class OrderEntryPage extends StatefulWidget {
  const OrderEntryPage({super.key});

  @override
  State<OrderEntryPage> createState() => _OrderEntryPageState();
}

class _OrderEntryPageState extends State<OrderEntryPage> {
  models.Account? _selectedAccount;
  bool _hasSelectedAccount = false;
  // Selected filters from ItemFilterPage: List of maps {id: categoryId, items: [itemIds]}
  List<Map<String, dynamic>> _selectedFilters = [];

  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  List<Product> _allProducts = [];
  List<Product> _displayedProducts = [];
  List<CartItem> _cart = [];

  bool _isLoadingProducts = false;
  bool _isLoadingMore = false;
  bool _hasMoreData = true;
  bool _isSubmittingDraft = false;

  int _currentPage = 1;
  final int _pageSize = 20;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _openSelectAccount();
    });
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 200) {
      if (!_isLoadingMore && _hasMoreData && _selectedAccount != null) {
        _loadMoreProducts();
      }
    }
  }

  Future<void> _openSelectAccount() async {
    // Loop the account selection so that when a user picks an account that the
    // server rejects (Status=false), we return them to the selector instead of
    // popping back to the Home page. If the user cancels the selector and we
    // have no previously selected account, then close this page.
    while (mounted && !_hasSelectedAccount) {
      final models.Account? result = await SelectAccountPage.show(
        context,
        title: 'Select Party',
        accountType: 'Party',
        showBalance: true,
        selectedAccount: _selectedAccount,
      );

      // User cancelled the selector
      if (result == null) {
        if (!_hasSelectedAccount && mounted) Navigator.of(context).pop();
        return;
      }

      // Verify selected account with server
      final statusCheck = await _checkAccountStatus(result);
      if (!mounted) return;

      if (statusCheck['ok'] == true) {
        setState(() {
          _selectedAccount = result;
          _hasSelectedAccount = true;
        });
        if (mounted) _loadProducts();
        return; // done
      }

      // Server rejected the selection: show message and loop back to selector
      final msg = statusCheck['message']?.toString() ?? 'Account is not available';
      await showDialog<void>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Account unavailable'),
          content: Text(msg),
          actions: [
            TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('OK')),
          ],
        ),
      );

      // continue loop to show selector again
    }
  }

  // Helper to call GetAccountStatus API and return a map {ok: bool, message: String?}
  Future<Map<String, dynamic>> _checkAccountStatus(models.Account account) async {
    try {
      final auth = Provider.of<AuthService>(context, listen: false);
      final dio = auth.getDioClient();

      // Use local reference to currentUser to avoid repeated null-aware calls
      final user = auth.currentUser;
      final lUserId = user?.userId ?? user?.mobileNumber ?? '';
      final accountId = account.acIdCol ?? int.tryParse(account.id) ?? 0;

      final payload = {
        'lLicNo': auth.currentUser?.licenseNumber ?? '',
        // As per requirement the lUserId should be the login Id (Id from login response) if available
        'lUserId': lUserId,
        'account_id': accountId,
      };

      final headers = {
        'Content-Type': 'application/json',
        'package_name': auth.packageNameHeader,
        if (auth.getAuthHeader() != null) 'Authorization': auth.getAuthHeader(),
      };

      // Perform POST
      final response = await dio.post('/GetAccountStatus', data: payload, options: Options(headers: headers));
      dynamic raw = response.data;
      Map<String, dynamic> parsed = {};

      if (raw is Map<String, dynamic>) parsed = raw;
      else if (raw is String) {
        final clean = raw.replaceAll(RegExp(r'[\x00-\x1F\x7F]'), '');
        parsed = jsonDecode(clean) as Map<String, dynamic>;
      } else {
        parsed = jsonDecode(jsonEncode(raw)) as Map<String, dynamic>;
      }

      // Check parsed structure
      if (parsed['success'] == true && parsed['data'] != null) {
        final data = parsed['data'];
        final status = (data['Status'] == true);
        final message = data['Message']?.toString() ?? parsed['message']?.toString();
        return {'ok': status, 'message': message};
      }

      // fallback: if 'data' contains Status
      if (parsed['data'] != null && parsed['data'] is Map && parsed['data']['Status'] != null) {
        final data = parsed['data'] as Map<String, dynamic>;
        return {'ok': data['Status'] == true, 'message': data['Message']?.toString()};
      }

      return {'ok': false, 'message': parsed['message']?.toString() ?? 'Unable to verify account status'};
    } catch (e) {
      return {'ok': false, 'message': e.toString()};
    }
  }

  // Replace _loadProducts and _loadMoreProducts to call real API
  Future<void> _loadProducts() async {
    if (_selectedAccount == null) return;
    setState(() {
      _isLoadingProducts = true;
      _currentPage = 1; // will represent the last loaded page
      _hasMoreData = true;
      _allProducts = [];
      _displayedProducts = [];
    });

    try {
      final auth = Provider.of<AuthService>(context, listen: false);
      final dio = auth.getDioClient();

      final payload = {
        'lLicNo': auth.currentUser?.licenseNumber ?? '',
        'lUserId': auth.currentUser?.mobileNumber ?? auth.currentUser?.userId ?? '',
        'lFirmCode': '',
        'lPageNo': _currentPage,
        'lSize': _pageSize,
        'lSearchFieldValue': _searchQuery,
        'lExecuteTotalRows': true,
        'lRateType': 'A',
        'CMIDCOL': -1,
        'IDCOL': 0,
        'Wsch': 0,
        'MCIDCOL': 0,
        'AcCode': _selectedAccount?.acIdCol?.toString() ?? '',
        'NewArrival': false,
        'lSearchFieldName': 'I_NAME',
        'filters': _selectedFilters
      };

      final headers = {
        'Content-Type': 'application/json',
        'package_name': auth.packageNameHeader,
        if (auth.getAuthHeader() != null) 'Authorization': auth.getAuthHeader(),
      };

      final response = await dio.post('/GetItemList', data: payload, options: Options(headers: headers));
      dynamic raw = response.data;

      // normalize to list
      List<dynamic> items = [];
      if (raw is List) {
        items = raw;
      } else if (raw is String) {
        final clean = raw.replaceAll(RegExp(r'[\x00-\x1F\x7F]'), '');
        final decoded = jsonDecode(clean);
        if (decoded is List) items = decoded;
      } else if (raw is Map && raw['data'] is List) {
        items = raw['data'];
      } else if (raw is Map && raw['Item'] is List) {
        items = raw['Item'];
      }

      final parsedProducts = items.map((e) {
        final map = e is Map<String, dynamic> ? e : (e is String ? jsonDecode(e) as Map<String, dynamic> : Map<String, dynamic>.from(e));
        final item = ItemModel.fromJson(map);
        return _itemToProduct(item);
      }).toList();

      setState(() {
        // For server-side pagination, treat this as page 1
        _allProducts = parsedProducts;
        _displayedProducts = List<Product>.from(_allProducts);
        // If we received at least pageSize items, there may be more
        _hasMoreData = parsedProducts.length >= _pageSize;
        // Keep _currentPage as 1 (last loaded page)
        _isLoadingProducts = false;
      });
    } catch (e) {
      if (mounted) {
        setState(() => _isLoadingProducts = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to load products: $e')));
      }
    }
  }

  Future<void> _loadMoreProducts() async {
    if (_isLoadingMore || !_hasMoreData) return;
    setState(() => _isLoadingMore = true);

    try {
      final nextPage = _currentPage + 1;
      final auth = Provider.of<AuthService>(context, listen: false);
      final dio = auth.getDioClient();

      final payload = {
        'lLicNo': auth.currentUser?.licenseNumber ?? '',
        'lUserId': auth.currentUser?.mobileNumber ?? auth.currentUser?.userId ?? '',
        'lFirmCode': '',
        'lPageNo': nextPage,
        'lSize': _pageSize,
        'lSearchFieldValue': _searchQuery,
        'lExecuteTotalRows': true,
        'lRateType': 'A',
        'CMIDCOL': -1,
        'IDCOL': 0,
        'Wsch': 0,
        'MCIDCOL': 0,
        'AcCode': _selectedAccount?.acIdCol?.toString() ?? '',
        'NewArrival': false,
        'lSearchFieldName': 'I_NAME',
        'filters': _selectedFilters
      };

      final headers = {
        'Content-Type': 'application/json',
        'package_name': auth.packageNameHeader,
        if (auth.getAuthHeader() != null) 'Authorization': auth.getAuthHeader(),
      };

      final response = await dio.post('/GetItemList', data: payload, options: Options(headers: headers));
      dynamic raw = response.data;

      List<dynamic> items = [];
      if (raw is List) {
        items = raw;
      } else if (raw is String) {
        final clean = raw.replaceAll(RegExp(r'[\x00-\x1F\x7F]'), '');
        final decoded = jsonDecode(clean);
        if (decoded is List) items = decoded;
      } else if (raw is Map && raw['data'] is List) {
        items = raw['data'];
      } else if (raw is Map && raw['Item'] is List) {
        items = raw['Item'];
      }

      final moreProducts = items.map((e) {
        final map = e is Map<String, dynamic> ? e : (e is String ? jsonDecode(e) as Map<String, dynamic> : Map<String, dynamic>.from(e));
        final item = ItemModel.fromJson(map);
        return _itemToProduct(item);
      }).toList();

      setState(() {
        if (moreProducts.isNotEmpty) {
          _allProducts.addAll(moreProducts);
          _displayedProducts = List<Product>.from(_allProducts);
          _currentPage = nextPage; // update last loaded page
        }
        // If received less than pageSize, no more data
        _hasMoreData = moreProducts.length >= _pageSize;
        _isLoadingMore = false;
      });
    } catch (e) {
      if (mounted) setState(() => _isLoadingMore = false);
    }
  }

  // When user types search, call server
  void _performSearch(String query) {
    _searchQuery = query.trim();
    // debounce simple: cancel previous timer? For simplicity call load after short delay
    Future.delayed(const Duration(milliseconds: 300), () {
      if (mounted && _searchQuery == query.trim()) {
        _loadProducts();
      }
    });
  }

  // Convert ItemModel to Product (maps fields conservatively)
  Product _itemToProduct(ItemModel item) {
    return Product(
      id: item.iidcol.toString(),
      name: item.name,
      category: 'Medicine',
      price: item.rateA,
      mrp: item.mrp,
      unit: item.packing.isNotEmpty ? item.packing : 'Unit',
      stockQuantity: item.stock.toInt(),
      manufacturer: item.mfgComp,
      salt: item.salt.isNotEmpty ? item.salt : null,
      batchNumber: null,
      expiryDate: null,
      description: '',
      imageUrl: null,
    );
  }

  void _addToCart(Product product) {
    setState(() {
      final existingIndex = _cart.indexWhere((item) => item.product.id == product.id);
      if (existingIndex >= 0) {
        _cart[existingIndex] = _cart[existingIndex].copyWith(quantity: _cart[existingIndex].quantity + 1);
      } else {
        _cart.add(CartItem(product: product));
      }
    });
  }

  void _updateQuantity(Product product, int newQuantity) {
    setState(() {
      if (newQuantity <= 0) {
        _cart.removeWhere((item) => item.product.id == product.id);
      } else {
        final index = _cart.indexWhere((item) => item.product.id == product.id);
        if (index >= 0) {
          _cart[index] = _cart[index].copyWith(quantity: newQuantity);
        }
      }
    });
  }

  int _getCartQuantity(Product product) {
    final item = _cart.firstWhere((item) => item.product.id == product.id, orElse: () => CartItem(product: product, quantity: 0));
    return item.quantity;
  }

  double get _cartTotal => _cart.fold(0, (sum, item) => sum + item.total);
  int get _cartItemCount => _cart.fold(0, (sum, item) => sum + item.quantity);

  Future<void> _submitDraftOrder() async {
    if (_cart.isEmpty || _selectedAccount == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Cart is empty or party not selected')));
      return;
    }

    setState(() => _isSubmittingDraft = true);
    final auth = Provider.of<AuthService>(context, listen: false);
    final dio = auth.getDioClient();

    final headers = {
      'Content-Type': 'application/json',
      'package_name': auth.packageNameHeader,
      if (auth.getAuthHeader() != null) 'Authorization': auth.getAuthHeader(),
    };

    int successCount = 0;
    final failures = <String>[];

    for (final cartItem in _cart) {
      try {
        final product = cartItem.product;

        // Build payload. Use best-effort mappings from available fields.
        // Determine firm code from user's stores (pick primary or first)
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

        final acCodeValue = _selectedAccount?.code ?? (_selectedAccount?.acIdCol != null ? _selectedAccount!.acIdCol.toString() : _selectedAccount?.id ?? '');
        final itemCodeValue = product.id;
        final cuIdValue = int.tryParse(auth.currentUser?.userId ?? '') ?? 0;

        final payload = {
          'UserId': auth.currentUser?.mobileNumber ?? auth.currentUser?.userId ?? '',
          'LicNo': auth.currentUser?.licenseNumber ?? '',
          'lFirmCode': firmCode,
          'AcCode': acCodeValue,
          'ItemCode': itemCodeValue,
          'ItemQty': cartItem.quantity.toString(),
          'ItemRate': (cartItem.priceAtAddition).toString(),
          'IdCol': int.tryParse(product.id) ?? 0,
          'cu_id': cuIdValue,
          'ItemFQty': '',
          'ItemSchQty': '0.0',
          'ItemDSchQty': '0.0',
          'ItemAmt': cartItem.total.toStringAsFixed(2),
          'discount_percentage': '',
          'discount_percentage1': '',
          'discount_pcs': '0.0',
          'remark': cartItem.product.name,
          'insert_record': 1,
          'default_hit': true,
        };

        final response = await dio.post('/AddDraftOrder', data: payload, options: Options(headers: headers));
        dynamic raw = response.data;
        Map<String, dynamic> parsed = {};
        if (raw is Map<String, dynamic>) parsed = raw;
        else if (raw is String) {
          final clean = raw.replaceAll(RegExp(r'[\x00-\x1F\x7F]'), '');
          parsed = jsonDecode(clean) as Map<String, dynamic>;
        } else {
          parsed = jsonDecode(jsonEncode(raw)) as Map<String, dynamic>;
        }

        if (parsed['success'] == true || parsed['Status'] == true || parsed['status'] == true) {
          successCount++;
        } else if (parsed['rs'] == 1) {
          successCount++;
        } else {
          final msg = parsed['message']?.toString() ?? parsed['data']?.toString() ?? 'Unknown error';
          failures.add('Item ${product.name}: $msg');
        }
      } catch (e) {
        failures.add('${cartItem.product.name}: $e');
      }
    }

    if (!mounted) return;
    setState(() => _isSubmittingDraft = false);

    if (successCount == _cart.length) {
      // Clear cart and show success
      setState(() {
        _cart.clear();
      });
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Saved ${successCount} items as draft')));
    } else {
      final msg = 'Saved $successCount/${_cart.length}. ${failures.isNotEmpty ? failures.join('\n') : ''}';
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        title: const Text('New Order', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        centerTitle: true,
        backgroundColor: colorScheme.surface,
        scrolledUnderElevation: 0,
        actions: [
          if (_selectedAccount != null)
            Padding(
              padding: const EdgeInsets.only(right: 8.0),
              child: IconButton(
                icon: const Icon(Icons.person_search_rounded),
                onPressed: _openSelectAccount,
                tooltip: 'Change Party',
              ),
            ),
        ],
      ),
      body: Column(
        children: [
          // --- SELECTED PARTY HEADER ---
          if (_selectedAccount != null)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              color: colorScheme.surfaceContainerLow,
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 18,
                    backgroundColor: colorScheme.primaryContainer,
                    child: Text(_selectedAccount!.name[0], style: TextStyle(fontWeight: FontWeight.bold, color: colorScheme.onPrimaryContainer)),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _selectedAccount!.name,
                          style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: colorScheme.onSurface),
                          maxLines: 1, overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          "Balance: ₹${_selectedAccount!.balance?.toStringAsFixed(2) ?? '0.00'}",
                          style: TextStyle(fontSize: 12, color: colorScheme.primary, fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

          // --- SEARCH BAR ---
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    onChanged: _performSearch,
                    style: const TextStyle(fontSize: 14),
                    decoration: InputDecoration(
                      hintText: 'Search products...',
                      hintStyle: TextStyle(color: colorScheme.onSurfaceVariant.withOpacity(0.6), fontSize: 14),
                      prefixIcon: Icon(Icons.search, color: colorScheme.onSurfaceVariant, size: 20),
                      suffixIcon: _searchController.text.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear, size: 18),
                              onPressed: () {
                                _searchController.clear();
                                _performSearch('');
                              },
                            )
                          : null,
                      filled: true,
                      fillColor: colorScheme.surfaceContainerHighest.withOpacity(0.3),
                      contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 16),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.filter_list),
                  onPressed: () async {
                    final result = await Navigator.push<List<Map<String, dynamic>>?>(
                      context,
                      // Pass currently selected filters so the filter page restores selection
                      MaterialPageRoute(builder: (_) => ItemFilterPage(initialSelectedFilters: _selectedFilters)),
                    );
                    if (result != null) {
                      setState(() {
                        _selectedFilters = result;
                      });
                      _loadProducts();
                    }
                  },
                ),
              ],
            ),
          ),

          // --- PRODUCT LIST ---
          Expanded(
            child: _isLoadingProducts
                ? Center(child: CircularProgressIndicator(color: colorScheme.primary, strokeWidth: 2))
                : ListView.separated(
              controller: _scrollController,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              itemCount: _displayedProducts.length + (_isLoadingMore ? 1 : 0),
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (context, index) {
                if (index == _displayedProducts.length) {
                  return const Padding(padding: EdgeInsets.all(16), child: Center(child: CircularProgressIndicator(strokeWidth: 2)));
                }
                final product = _displayedProducts[index];
                // Pass index to generate mock ratings
                return _buildCompactProductCard(product, index);
              },
            ),
          ),

          // --- CART SUMMARY FOOTER ---
          if (_cart.isNotEmpty)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: colorScheme.inverseSurface,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 4, offset: const Offset(0, -2))],
              ),
              child: SafeArea(
                top: false,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          "$_cartItemCount Items",
                          style: TextStyle(color: colorScheme.onInverseSurface.withOpacity(0.7), fontSize: 11),
                        ),
                        Text(
                          "₹${_cartTotal.toStringAsFixed(2)}",
                          style: TextStyle(color: colorScheme.onInverseSurface, fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    ElevatedButton.icon(
                      onPressed: () => _showCartSheet(context),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: colorScheme.primaryContainer,
                        foregroundColor: colorScheme.onPrimaryContainer,
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      ),
                      icon: const Icon(Icons.shopping_bag_outlined, size: 18),
                      label: const Text("View Cart", style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                    )
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  // Updated to accept index for mock ratings
  Widget _buildCompactProductCard(Product product, int index) {
    final colorScheme = Theme.of(context).colorScheme;
    final qty = _getCartQuantity(product);
    final bool hasStock = product.stockQuantity > 0;

    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: qty > 0 ? colorScheme.primary.withOpacity(0.5) : colorScheme.outlineVariant.withOpacity(0.3)),
      ),
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          // --- NEW: Medicine Icon Container ---
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: colorScheme.secondaryContainer.withOpacity(0.4),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(Icons.medication_outlined, size: 20, color: colorScheme.secondary),
          ),
          const SizedBox(width: 12),

          // Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('${product.name}, ${product.unit}', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                const SizedBox(height: 6),
                if ((product.manufacturer ?? '').isNotEmpty)
                  Text(product.manufacturer ?? '', style: TextStyle(fontSize: 11, color: colorScheme.onSurfaceVariant)),
                if ((product.salt ?? '').isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 4.0),
                    child: Text(product.salt!, style: TextStyle(fontSize: 11, color: colorScheme.onSurfaceVariant)),
                  ),
              ],
            ),
          ),

          // Action + Stock shown below the action (Add or qty control)
          if (qty == 0)
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  height: 32,
                  child: OutlinedButton(
                    onPressed: hasStock ? () => _addToCart(product) : null,
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      side: BorderSide(color: hasStock ? colorScheme.primary : colorScheme.outlineVariant),
                    ),
                    child: Text(hasStock ? "ADD" : "NO STOCK", style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: hasStock ? colorScheme.primary : colorScheme.outline)),
                  ),
                ),
                const SizedBox(height: 6),
                Text('Stock: ${product.stockQuantity}', style: TextStyle(fontSize: 11, color: colorScheme.onSurfaceVariant)),
              ],
            )
          else
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  height: 32,
                  decoration: BoxDecoration(
                    color: colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.remove, size: 16),
                        onPressed: () => _updateQuantity(product, qty - 1),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                        color: colorScheme.onPrimaryContainer,
                      ),
                      Text("$qty", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: colorScheme.onPrimaryContainer)),
                      IconButton(
                        icon: const Icon(Icons.add, size: 16),
                        onPressed: () => _updateQuantity(product, qty + 1),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                        color: colorScheme.onPrimaryContainer,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 6),
                Text('Stock: ${product.stockQuantity}', style: TextStyle(fontSize: 11, color: colorScheme.onSurfaceVariant)),
              ],
            ),
        ],
      ),
    );
  }

  void _showCartSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        maxChildSize: 0.9,
        minChildSize: 0.4,
        builder: (_, scrollControl) => Container(
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              const SizedBox(height: 12),
              Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2))),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text("Current Order", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(ctx)),
                  ],
                ),
              ),
              const Divider(height: 1),
              Expanded(
                child: ListView.separated(
                  controller: scrollControl,
                  padding: const EdgeInsets.all(16),
                  itemCount: _cart.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (ctx, i) {
                    final item = _cart[i];
                    return Row(
                      children: [
                        // --- NEW: Small Icon in Cart View too ---
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.surfaceContainerHighest,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(Icons.medication_outlined, size: 16, color: Theme.of(context).colorScheme.onSurfaceVariant),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(item.product.name, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                              Text("₹${item.priceAtAddition} x ${item.quantity}", style: const TextStyle(fontSize: 11, color: Colors.grey)),
                            ],
                          ),
                        ),
                        Text("₹${item.total.toStringAsFixed(2)}", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                      ],
                    );
                  },
                ),
              ),
              SafeArea(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: FilledButton(
                      onPressed: _isSubmittingDraft
                          ? null
                          : () async {
                              Navigator.pop(ctx);
                              await _submitDraftOrder();
                            },
                      style: FilledButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 12)),
                      child: _isSubmittingDraft ? const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2)) : const Text("Confirm Order", style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
