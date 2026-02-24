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
import 'cart_page.dart';

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
  // per-item metadata loaded from server (tax, net amt, mrp, amt etc.) keyed by product id
  Map<String, Map<String, dynamic>> _cartMeta = {};

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
        if (mounted) {
          // Load any existing draft order (cart) for this account first
          await _loadDraftOrder();
          // Then load product list
          await _loadProducts();
        }
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

  Future<void> _addToCart(Product product) async {
    // Optimistic update: prepare new CartItem (quantity 1) but don't mutate state until API returns success
    final existingIndex = _cart.indexWhere((item) => item.product.id == product.id);

    // Build a tentative CartItem to send to server
    final tentativeQuantity = (existingIndex >= 0) ? _cart[existingIndex].quantity + 1 : 1;
    final tentativeCartItem = CartItem(product: product, quantity: tentativeQuantity);

    // Show a small progress indicator via SnackBar while calling API
    final scaffold = ScaffoldMessenger.of(context);
    scaffold.showSnackBar(const SnackBar(content: Text('Adding item...'), duration: Duration(milliseconds: 700)));

    final result = await _callAddDraftOrder(tentativeCartItem);

    if (result['success'] == true) {
      setState(() {
        if (existingIndex >= 0) {
          _cart[existingIndex] = _cart[existingIndex].copyWith(quantity: tentativeQuantity);
        } else {
          _cart.add(tentativeCartItem);
        }
      });
      // refresh server-side draft metadata (tax/net) after successful add
      await _loadDraftOrder();
      scaffold.showSnackBar(const SnackBar(content: Text('Item added')));
    } else {
      scaffold.showSnackBar(SnackBar(content: Text('Failed to add item: ${result['message'] ?? 'Unknown'}')));
    }
  }

  void _updateQuantity(Product product, int newQuantity) async {
    final scaffold = ScaffoldMessenger.of(context);
    final existingIndex = _cart.indexWhere((item) => item.product.id == product.id);

    if (existingIndex < 0) return;

    // Save previous state to revert if API fails
    final previousItem = _cart[existingIndex];

    if (newQuantity <= 0) {
      // If user decreased to zero, attempt to send update with zero quantity
      final tentative = previousItem.copyWith(quantity: 0);
      scaffold.showSnackBar(const SnackBar(content: Text('Removing item...'), duration: Duration(milliseconds: 700)));
      final result = await _callAddDraftOrder(tentative);
      if (result['success'] == true) {
        setState(() => _cart.removeAt(existingIndex));
        scaffold.showSnackBar(const SnackBar(content: Text('Item removed')));
      } else {
        scaffold.showSnackBar(SnackBar(content: Text('Failed to remove item: ${result['message'] ?? 'Unknown'}')));
      }
      return;
    }

    // Optimistic update in UI
    setState(() {
      _cart[existingIndex] = _cart[existingIndex].copyWith(quantity: newQuantity);
    });

    scaffold.showSnackBar(const SnackBar(content: Text('Updating quantity...'), duration: Duration(milliseconds: 700)));
    final result = await _callAddDraftOrder(_cart[existingIndex]);

    if (result['success'] == true) {
      // refresh server-side draft metadata after quantity update
      await _loadDraftOrder();
      scaffold.showSnackBar(const SnackBar(content: Text('Quantity updated')));
    } else {
      // revert
      setState(() {
        _cart[existingIndex] = previousItem;
      });
      scaffold.showSnackBar(SnackBar(content: Text('Failed to update quantity: ${result['message'] ?? 'Unknown'}')));
    }
  }

  // Helper to call AddDraftOrder API for a single cart item. Returns map with success and message.
  Future<Map<String, dynamic>> _callAddDraftOrder(CartItem cartItem) async {
    try {
      final auth = Provider.of<AuthService>(context, listen: false);
      final dio = auth.getDioClient();

      // Determine firm code
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
      final itemCodeValue = cartItem.product.id;
      final cuIdValue = int.tryParse(auth.currentUser?.userId ?? '') ?? 0;

      final payload = {
        'UserId': auth.currentUser?.mobileNumber ?? auth.currentUser?.userId ?? '',
        'LicNo': auth.currentUser?.licenseNumber ?? '',
        'lFirmCode': firmCode,
        'AcCode': acCodeValue,
        'ItemCode': itemCodeValue,
        'ItemQty': cartItem.quantity.toString(),
        'ItemRate': (cartItem.priceAtAddition).toString(),
        'IdCol': int.tryParse(cartItem.product.id) ?? 0,
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

      final headers = {
        'Content-Type': 'application/json',
        'package_name': auth.packageNameHeader,
        if (auth.getAuthHeader() != null) 'Authorization': auth.getAuthHeader(),
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

      final success = (parsed['success'] == true || parsed['Status'] == true || parsed['status'] == true || parsed['rs'] == 1);
      final message = parsed['message']?.toString() ?? parsed['data']?.toString();
      return {'success': success, 'message': message};
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  // --- Helper getters and utilities for cart ---
  int _getCartQuantity(Product product) {
    final idx = _cart.indexWhere((c) => c.product.id == product.id);
    return idx >= 0 ? _cart[idx].quantity : 0;
  }

  int get _cartItemCount => _cart.fold<int>(0, (s, c) => s + c.quantity);

  double get _cartTotal => _cart.fold<double>(0.0, (s, c) => s + c.total);

  // Submit the draft order (simple implementation: call AddDraftOrder for each item or call a batch API if available)
  Future<void> _submitDraftOrder() async {
    if (_cart.isEmpty) return;
    setState(() => _isSubmittingDraft = true);
    try {
      // For now call existing _callAddDraftOrder for each item sequentially.
      for (final item in List<CartItem>.from(_cart)) {
        final res = await _callAddDraftOrder(item);
        if (res['success'] != true) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to submit ${item.product.name}: ${res['message'] ?? ''}')));
        }
      }
      // Optionally clear cart on success
      setState(() => _cart.clear());
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Order confirmed')));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Order submission failed: $e')));
    } finally {
      if (mounted) setState(() => _isSubmittingDraft = false);
    }
  }

  // --- UI CODE REMAINS UNCHANGED ---
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
                      hintStyle: TextStyle(color: colorScheme.onSurfaceVariant.withAlpha((0.6 * 255).round()), fontSize: 14),
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
                      fillColor: colorScheme.surfaceContainerHighest.withAlpha((0.3 * 255).round()),
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
                          style: TextStyle(color: colorScheme.onInverseSurface.withAlpha((0.7 * 255).round()), fontSize: 11),
                        ),
                        Text(
                          "₹${_cartTotal.toStringAsFixed(2)}",
                          style: TextStyle(color: colorScheme.onInverseSurface, fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    ElevatedButton.icon(
                      onPressed: () {
                        final auth = Provider.of<AuthService>(context, listen: false);
                        final user = auth.currentUser;
                        final acCode = _selectedAccount?.code ?? (user != null && user.stores.isNotEmpty ? user.stores.first.firmCode : '');
                        Navigator.of(context).push(MaterialPageRoute(builder: (_) => CartPage(acCode: acCode)));
                      },
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
        border: Border.all(color: qty > 0 ? colorScheme.primary.withAlpha((0.5 * 255).round()) : colorScheme.outlineVariant.withAlpha((0.3 * 255).round())),
      ),
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          // --- NEW: Medicine Icon Container ---
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: colorScheme.secondaryContainer.withAlpha((0.4 * 255).round()),
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

  // Helper: load draft order from server and populate _cart
  Future<Map<String, dynamic>> _loadDraftOrder() async {
    try {
      final auth = Provider.of<AuthService>(context, listen: false);
      final dio = auth.getDioClient();

      // Determine firm code
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

      final payload = {
        'lUserId': auth.currentUser?.mobileNumber ?? auth.currentUser?.userId ?? '',
        'lLicNo': auth.currentUser?.licenseNumber ?? '',
        'lFirmCode': firmCode,
        'AcCode': _selectedAccount?.code ?? (_selectedAccount?.acIdCol != null ? _selectedAccount!.acIdCol.toString() : _selectedAccount?.id ?? ''),
      };

      final headers = {
        'Content-Type': 'application/json',
        'package_name': auth.packageNameHeader,
        if (auth.getAuthHeader() != null) 'Authorization': auth.getAuthHeader(),
      };

      final response = await dio.post('/ListDraftOrder', data: payload, options: Options(headers: headers));
      dynamic raw = response.data;

      Map<String, dynamic> parsed = {};
      if (raw is Map<String, dynamic>) parsed = raw;
      else if (raw is String) {
        final clean = raw.replaceAll(RegExp(r'[\x00-\x1F\x7F]'), '');
        parsed = jsonDecode(clean) as Map<String, dynamic>;
      } else {
        parsed = jsonDecode(jsonEncode(raw)) as Map<String, dynamic>;
      }

      // Navigate parsed -> data -> DraftOrder
      final data = parsed['data'] as Map<String, dynamic>?;
      final draftList = data != null && data['DraftOrder'] is List ? (data['DraftOrder'] as List) : <dynamic>[];

      final List<CartItem> loaded = [];
      final Map<String, Map<String, dynamic>> meta = {};

      int parseInt(dynamic v) {
        if (v == null) return 0;
        if (v is int) return v;
        return int.tryParse(v.toString()) ?? 0;
      }

      double parseDouble(dynamic v) {
        if (v == null) return 0.0;
        if (v is double) return v;
        if (v is int) return v.toDouble();
        return double.tryParse(v.toString()) ?? 0.0;
      }

      for (final e in draftList) {
        final Map<String, dynamic> m = e is Map<String, dynamic> ? e : Map<String, dynamic>.from(e);
        final idCol = parseInt(m['IdCol'] ?? m['Idcol']);
        final name = (m['Name'] ?? '').toString();
        final mfg = (m['MfgComp'] ?? '').toString();
        final qty = parseDouble(m['Qty']).toInt();
        final rate = parseDouble(m['Rate']);
        final mrp = parseDouble(m['Mrp']);
        final stock = parseDouble(m['Stock']).toInt();
        final amt = parseDouble(m['Amt']);
        final taxAmt = parseDouble(m['TaxAmt']);
        final netAmt = parseDouble(m['NetAmt']);
        final discAmt = parseDouble(m['DO_DiscAmt'] ?? m['DO_DiscAmt']);
        final disc1 = parseDouble(m['DO_Disc1Amt'] ?? 0);
        final disc2 = parseDouble(m['DO_Disc2Amt'] ?? 0);

        final product = Product(
          id: idCol.toString(),
          name: name,
          category: 'Medicine',
          price: rate,
          mrp: mrp,
          unit: (m['packing'] ?? '').toString().isNotEmpty ? (m['packing'] ?? '').toString() : 'Unit',
          stockQuantity: stock,
          manufacturer: mfg,
          batchNumber: null,
          expiryDate: null,
          description: '',
          imageUrl: null,
          salt: null,
        );

        final cartItem = CartItem(product: product, quantity: qty, priceAtAddition: rate);
        loaded.add(cartItem);

        // store meta so UI can show Tax/MRP/Net values
        meta[product.id] = {
          'amt': amt,
          'tax': taxAmt,
          'net': netAmt,
          'mrp': mrp,
          'gv': amt, // gross value (display)
          'sv': disc1,
          'dv': disc2,
          'disc': discAmt,
        };
      }

      setState(() {
        _cart = loaded;
        _cartMeta = meta;
      });

      return {'success': true, 'count': loaded.length};
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  void _showCartSheet(BuildContext context) async {
    final scaffold = ScaffoldMessenger.of(context);
    scaffold.showSnackBar(const SnackBar(content: Text('Loading cart...'), duration: Duration(milliseconds: 700)));
    final res = await _loadDraftOrder();
    if (res['success'] != true) {
      scaffold.showSnackBar(SnackBar(content: Text('Failed to load cart: ${res['message'] ?? 'Unknown'}')));
      return;
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        maxChildSize: 0.95,
        minChildSize: 0.5,
        builder: (_, scrollControl) => Container(
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          ),
          child: Column(
            children: [
              const SizedBox(height: 12),
              Container(width: 32, height: 4, decoration: BoxDecoration(color: Theme.of(context).colorScheme.outlineVariant, borderRadius: BorderRadius.circular(2))),

              // --- PROFESSIONAL HEADER ---
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 12, 16),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Review Order', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, letterSpacing: -0.5, color: Theme.of(context).colorScheme.onSurface)),
                          const SizedBox(height: 4),
                          Text('$_cartItemCount items • Total Payable: ₹${_cartTotal.toStringAsFixed(2)}',
                              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: Theme.of(context).colorScheme.primary)),
                        ],
                      ),
                    ),
                    IconButton.filledTonal(
                        icon: const Icon(Icons.close, size: 20),
                        onPressed: () => Navigator.pop(ctx)
                    ),
                  ],
                ),
              ),
              const Divider(height: 1, thickness: 0.5),

              Expanded(
                child: _cart.isEmpty
                    ? Center(child: Text('Your cart is empty', style: TextStyle(color: Theme.of(context).colorScheme.outline)))
                    : ListView.builder(
                  controller: scrollControl,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
                  itemCount: _cart.length,
                  itemBuilder: (ctx, i) {
                    final item = _cart[i];
                    final meta = _cartMeta[item.product.id] ?? {};
                    final price = item.priceAtAddition;
                    final qty = item.quantity;
                    final mrp = meta['mrp'] ?? item.product.mrp ?? 0.0;
                    final gv = meta['gv'] ?? (price * qty);
                    final gst = meta['tax'] ?? 0.0;
                    final disc = meta['disc'] ?? 0.0;
                    final net = meta['net'] ?? (gv + gst - disc);

                    return Container(
                      padding: const EdgeInsets.only(bottom: 16.0),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.surface,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Theme.of(context).colorScheme.outlineVariant.withOpacity(0.5)),
                        boxShadow: [
                          BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 4))
                        ],
                      ),
                      child: Column(
                        children: [
                          // Item Header
                          Padding(
                            padding: const EdgeInsets.all(16),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(item.product.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, letterSpacing: -0.2)),
                                      if ((item.product.manufacturer ?? '').isNotEmpty)
                                        Text(item.product.manufacturer!, style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant, fontSize: 12)),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 8),
                                // Quantity Controls (Material 3 Style)
                                Container(
                                  decoration: BoxDecoration(
                                    color: Theme.of(context).colorScheme.secondaryContainer.withOpacity(0.5),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Row(
                                    children: [
                                      IconButton(
                                        icon: const Icon(Icons.remove, size: 16),
                                        onPressed: () => _updateQuantity(item.product, qty - 1),
                                        constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                                      ),
                                      Text('$qty', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                                      IconButton(
                                        icon: const Icon(Icons.add, size: 16),
                                        onPressed: () => _updateQuantity(item.product, qty + 1),
                                        constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),

                          // Financial Detail Grid
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            decoration: BoxDecoration(
                              color: Theme.of(context).colorScheme.surfaceContainerLow,
                              borderRadius: const BorderRadius.vertical(bottom: Radius.circular(16)),
                            ),
                            child: Column(
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    _buildCartDetailRow('Rate', '₹${price.toStringAsFixed(2)}'),
                                    _buildCartDetailRow('MRP', '₹${mrp.toStringAsFixed(2)}'),
                                    _buildCartDetailRow('GST', '₹${gst.toStringAsFixed(2)}'),
                                  ],
                                ),
                                const Padding(
                                  padding: EdgeInsets.symmetric(vertical: 8),
                                  child: Divider(height: 1, thickness: 0.5),
                                ),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text('Net Amount', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Theme.of(context).colorScheme.onSurfaceVariant)),
                                    Text('₹${net.toStringAsFixed(2)}', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.primary)),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),

              // --- FINAL ACTIONS ---
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surface,
                  boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 20, offset: const Offset(0, -5))],
                ),
                child: SafeArea(
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text('Grand Total', style: TextStyle(fontSize: 12, color: Theme.of(context).colorScheme.outline)),
                            Text('₹${_cartTotal.toStringAsFixed(2)}', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                          ],
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: FilledButton(
                          onPressed: _isSubmittingDraft ? null : () async {
                            Navigator.pop(ctx);
                            await _submitDraftOrder();
                          },
                          style: FilledButton.styleFrom(
                            minimumSize: const Size(double.infinity, 54),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          ),
                          child: _isSubmittingDraft
                              ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                              : const Text("Place Order", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCartDetailRow(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(fontSize: 11, color: Theme.of(context).colorScheme.outline, fontWeight: FontWeight.w500)),
        const SizedBox(height: 2),
        Text(value, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Theme.of(context).colorScheme.onSurface)),
      ],
    );
  }

  Widget _labelValueColumn(String label, String value) {
    final colorScheme = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(fontSize: 12, color: colorScheme.onSurfaceVariant)),
        const SizedBox(height: 2),
        Text(value, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: colorScheme.onSurface)),
      ],
    );
  }

  Widget _labelValueSmall(String label, String value) {
    final colorScheme = Theme.of(context).colorScheme;
    return Row(
      children: [
        Text(label, style: TextStyle(fontSize: 12, color: colorScheme.onSurfaceVariant)),
        const SizedBox(width: 4),
        Text(value, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: colorScheme.onSurface)),
      ],
    );
  }
}
