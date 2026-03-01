import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:dio/dio.dart';
import 'dart:convert';
import '../models/account_model.dart';
import '../models/product_model.dart';
import '../models/cart_item_model.dart';
import 'cart_page.dart';
import '../auth_service.dart';
import 'product_detail_page.dart';

class ProductListPage extends StatefulWidget {
  final Account selectedAccount;

  const ProductListPage({super.key, required this.selectedAccount});

  @override
  State<ProductListPage> createState() => _ProductListPageState();
}

class _ProductListPageState extends State<ProductListPage> {
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  List<Product> _allProducts = [];
  List<Product> _displayedProducts = [];
  List<CartItem> _cart = [];

  bool _isLoading = false;
  bool _isLoadingMore = false;
  bool _hasMoreData = true;

  int _currentPage = 1;
  final int _pageSize = 20;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadProducts();
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
      if (!_isLoadingMore && _hasMoreData) {
        _loadMoreProducts();
      }
    }
  }

  Future<void> _loadProducts() async {
    setState(() => _isLoading = true);

    // Simulate API delay
    await Future.delayed(const Duration(milliseconds: 800));

    // Mock products data
    _allProducts = _generateMockProducts();
    _displayedProducts = _allProducts.take(_pageSize).toList();
    _hasMoreData = _displayedProducts.length < _allProducts.length;

    setState(() => _isLoading = false);
  }

  Future<void> _loadMoreProducts() async {
    if (_isLoadingMore) return;

    setState(() => _isLoadingMore = true);

    await Future.delayed(const Duration(milliseconds: 500));

    _currentPage++;
    final startIndex = (_currentPage - 1) * _pageSize;

    final filtered = _searchQuery.isEmpty
        ? _allProducts
        : _allProducts.where((p) =>
            p.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
            p.category.toLowerCase().contains(_searchQuery.toLowerCase()) ||
            (p.manufacturer?.toLowerCase().contains(_searchQuery.toLowerCase()) ?? false)
          ).toList();

    if (startIndex < filtered.length) {
      final moreProducts = filtered.skip(startIndex).take(_pageSize).toList();
      setState(() {
        _displayedProducts.addAll(moreProducts);
        _hasMoreData = _displayedProducts.length < filtered.length;
        _isLoadingMore = false;
      });
    } else {
      setState(() {
        _hasMoreData = false;
        _isLoadingMore = false;
      });
    }
  }

  void _performSearch(String query) {
    setState(() {
      _searchQuery = query;
      _currentPage = 1;

      if (query.isEmpty) {
        _displayedProducts = _allProducts.take(_pageSize).toList();
      } else {
        final filtered = _allProducts.where((p) =>
          p.name.toLowerCase().contains(query.toLowerCase()) ||
          p.category.toLowerCase().contains(query.toLowerCase()) ||
          (p.manufacturer?.toLowerCase().contains(query.toLowerCase()) ?? false)
        ).toList();
        _displayedProducts = filtered.take(_pageSize).toList();
        _hasMoreData = _displayedProducts.length < filtered.length;
      }
    });
  }

  void _addToCart(Product product, int quantity) async {
    try {
      final auth = Provider.of<AuthService>(context, listen: false);
      final dio = auth.getDioClient();
      final user = auth.currentUser;
      final acCode = widget.selectedAccount.code ?? '';
      final cuId = int.tryParse(user?.userId ?? '') ?? 0;
      final itemCode = product.code ?? product.id;
      final idCol = int.tryParse(product.id) ?? 0;

      final payload = {
        'UserId': user?.mobileNumber ?? user?.userId ?? '',
        'LicNo': user?.licenseNumber ?? '',
        'lFirmCode': acCode,
        'AcCode': acCode,
        'ItemCode': itemCode,
        'Icode': itemCode,
        'IdCol': idCol,
        'ItemQty': quantity.toString(),
        'ItemRate': product.price.toStringAsFixed(2),
        'cu_id': cuId,
        'ItemFQty': '0',
        'ItemSchQty': '0',
        'ItemDSchQty': '0.0',
        'ItemAmt': (product.price * quantity).toStringAsFixed(2),
        'discount_percentage': '0',
        'discount_percentage1': '0',
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

      final response = await dio.post('/AddDraftOrder', data: payload, options: Options(headers: headers));

      // Update local cart for UI feedback
      setState(() {
        final existingIndex = _cart.indexWhere((item) => item.product.id == product.id);
        if (existingIndex >= 0) {
          _cart[existingIndex] = _cart[existingIndex].copyWith(quantity: quantity);
        } else {
          _cart.add(CartItem(product: product, quantity: quantity));
        }
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${product.name} added to cart'),
            backgroundColor: Colors.green,
            duration: const Duration(milliseconds: 800),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to add: $e')),
        );
      }
    }
  }

  void _removeFromCart(Product product) {
    setState(() {
      _cart.removeWhere((item) => item.product.id == product.id);
    });
  }

  void _updateQuantity(Product product, int newQuantity) async {
    if (newQuantity <= 0) {
      _removeFromCart(product);
      return;
    }

    try {
      final auth = Provider.of<AuthService>(context, listen: false);
      final dio = auth.getDioClient();
      final user = auth.currentUser;
      final acCode = widget.selectedAccount.code ?? '';
      final cuId = int.tryParse(user?.userId ?? '') ?? 0;
      final itemCode = product.code ?? product.id;
      final idCol = int.tryParse(product.id) ?? 0;

      final payload = {
        'UserId': user?.mobileNumber ?? user?.userId ?? '',
        'LicNo': user?.licenseNumber ?? '',
        'lFirmCode': acCode,
        'AcCode': acCode,
        'ItemCode': itemCode,
        'Icode': itemCode,
        'IdCol': idCol,
        'ItemQty': newQuantity.toString(),
        'ItemRate': product.price.toStringAsFixed(2),
        'cu_id': cuId,
        'ItemFQty': '0',
        'ItemSchQty': '0',
        'ItemDSchQty': '0.0',
        'ItemAmt': (product.price * newQuantity).toStringAsFixed(2),
        'discount_percentage': '0',
        'discount_percentage1': '0',
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

      final response = await dio.post('/AddDraftOrder', data: payload, options: Options(headers: headers));

      setState(() {
        final index = _cart.indexWhere((item) => item.product.id == product.id);
        if (index >= 0) {
          _cart[index] = _cart[index].copyWith(quantity: newQuantity);
        }
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to update: $e')),
        );
      }
    }
  }

  int _getCartQuantity(Product product) {
    try {
      return _cart.firstWhere((item) => item.product.id == product.id).quantity;
    } catch (e) {
      return 0;
    }
  }

  double get _cartTotal => _cart.fold(0, (sum, item) => sum + item.total);

  int get _cartItemCount => _cart.fold(0, (sum, item) => sum + item.quantity);

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Select Products', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
            Text(
              widget.selectedAccount.name,
              style: TextStyle(fontSize: 12, color: colorScheme.onSurfaceVariant),
            ),
          ],
        ),
        actions: [
          if (_cart.isNotEmpty)
            Stack(
              children: [
                IconButton(
                  icon: const Icon(Icons.shopping_cart),
                  // navigate to CartPage instead of showing bottom sheet
                  onPressed: () {
                    final String acCode = widget.selectedAccount.code ?? '';
                    Navigator.of(context).push(MaterialPageRoute(builder: (_) => CartPage(acCode: acCode, selectedAccount: widget.selectedAccount)));
                  },
                ),
                Positioned(
                  right: 8,
                  top: 8,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: colorScheme.error,
                      shape: BoxShape.circle,
                    ),
                    constraints: const BoxConstraints(minWidth: 18, minHeight: 18),
                    child: Text(
                      '$_cartItemCount',
                      style: TextStyle(
                        color: colorScheme.onError,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
              ],
            ),
        ],
      ),
      body: Column(
        children: [
          // Search Bar
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _searchController,
              onChanged: _performSearch,
              decoration: InputDecoration(
                hintText: 'Search medicines...',
                prefixIcon: Icon(Icons.search, color: colorScheme.primary),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          _performSearch('');
                        },
                      )
                    : null,
                filled: true,
                fillColor: colorScheme.surfaceContainerHighest.withAlpha(128),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),

          // Product List
          Expanded(
            child: _isLoading
                ? _buildLoadingState()
                : _displayedProducts.isEmpty
                    ? _buildEmptyState()
                    : ListView.builder(
                        controller: _scrollController,
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: _displayedProducts.length + (_isLoadingMore ? 1 : 0),
                        itemBuilder: (context, index) {
                          if (index == _displayedProducts.length) {
                            return _buildLoadingMoreIndicator();
                          }

                          final product = _displayedProducts[index];
                          final inCartQuantity = _getCartQuantity(product);

                          return _buildProductCard(product, inCartQuantity);
                        },
                      ),
          ),

          // Cart Summary Bar
          if (_cart.isNotEmpty) _buildCartSummaryBar(),
        ],
      ),
    );
  }

  Widget _buildProductCard(Product product, int inCartQuantity) {
    final colorScheme = Theme.of(context).colorScheme;
    final isInCart = inCartQuantity > 0;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isInCart
              ? colorScheme.primary.withAlpha((0.5 * 255).toInt())
              : colorScheme.outlineVariant.withAlpha((0.3 * 255).toInt()),
          width: isInCart ? 2 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha((0.04 * 255).toInt()),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            // Product Icon/Image
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: colorScheme.primaryContainer.withAlpha(77),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                Icons.medication_rounded,
                color: colorScheme.primary,
                size: 32,
              ),
            ),
            const SizedBox(width: 12),

            // Product Details
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product.name,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: colorScheme.onSurface,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),

                  if (product.manufacturer != null)
                    Text(
                      product.manufacturer!,
                      style: TextStyle(
                        fontSize: 11,
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),

                  const SizedBox(height: 4),

                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: colorScheme.secondaryContainer.withAlpha(77),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          product.unit,
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: colorScheme.onSecondaryContainer,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Icon(Icons.inventory_2, size: 12, color: colorScheme.onSurfaceVariant),
                      const SizedBox(width: 4),
                      Text(
                        '${product.stockQuantity} in stock',
                        style: TextStyle(
                          fontSize: 11,
                          color: product.stockQuantity < 10 ? colorScheme.error : colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 6),

                  Row(
                    children: [
                      Text(
                        '₹${product.price.toStringAsFixed(2)}',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: colorScheme.primary,
                        ),
                      ),
                      const SizedBox(width: 8),
                      if (product.discountPercent > 0)
                        Text(
                          '₹${product.mrp.toStringAsFixed(2)}',
                          style: TextStyle(
                            fontSize: 12,
                            decoration: TextDecoration.lineThrough,
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                      if (product.discountPercent > 0) ...[
                        const SizedBox(width: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.green,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            '${product.discountPercent.toStringAsFixed(0)}% OFF',
                            style: const TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),

            // Add/Update Button
            const SizedBox(width: 8),

            ElevatedButton.icon(
              onPressed: product.isInStock ? () => _showEditBottomSheet(product, inCartQuantity) : null,
              icon: Icon(isInCart ? Icons.edit : Icons.add_shopping_cart, size: 16),
              label: Text(isInCart ? 'Update' : 'Add'),
              style: ElevatedButton.styleFrom(
                backgroundColor: colorScheme.primary,
                foregroundColor: colorScheme.onPrimary,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showEditBottomSheet(Product product, int inCartQuantity) {
    // Show the same bottom sheet as used for editing/adding from details
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        TextEditingController qtyController = TextEditingController(text: inCartQuantity.toString());

        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
          ),
          child: Column(
            // mainAxisSize: MainAxisSize.min,
            children: [
              // Product Image
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.medication_rounded,
                  color: Theme.of(context).colorScheme.primary,
                  size: 40,
                ),
              ),
              const SizedBox(height: 16),

              // Product Name
              Text(
                product.name,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),

              const SizedBox(height: 8),

              // Price and Discount
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    '₹${product.price.toStringAsFixed(2)}',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                  const SizedBox(width: 8),
                  if (product.discountPercent > 0)
                    Text(
                      '₹${product.mrp.toStringAsFixed(2)}',
                      style: TextStyle(
                        fontSize: 14,
                        decoration: TextDecoration.lineThrough,
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                  if (product.discountPercent > 0) ...[
                    const SizedBox(width: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.green,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        '${product.discountPercent.toStringAsFixed(0)}% OFF',
                        style: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ],
              ),

              const SizedBox(height: 16),

              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: qtyController,
                      decoration: InputDecoration(
                        labelText: 'Quantity',
                        prefixIcon: Icon(Icons.shopping_cart, color: Theme.of(context).colorScheme.primary),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(
                            color: Theme.of(context).colorScheme.primary.withAlpha((0.5 * 255).toInt()),
                            width: 1,
                          ),
                        ),
                      ),
                      keyboardType: TextInputType.number,
                    ),
                  ),
                  const SizedBox(width: 16),
                  ElevatedButton.icon(
                    onPressed: () {
                      final quantity = int.tryParse(qtyController.text) ?? 0;
                      if (quantity > 0) {
                        if (inCartQuantity > 0) {
                          _updateQuantity(product, quantity);
                        } else {
                          _addToCart(product, quantity);
                        }
                      }
                      Navigator.of(context).pop();
                    },
                    icon: const Icon(Icons.save),
                    label: const Text('Save'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(context).colorScheme.primary,
                      foregroundColor: Theme.of(context).colorScheme.onPrimary,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // Product Details
              Text(
                'Details',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                product.description ?? '',
                style: TextStyle(
                  fontSize: 14,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
                textAlign: TextAlign.justify,
              ),

              const SizedBox(height: 16),

              // Close Button
              ElevatedButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Close'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.secondary,
                  foregroundColor: Theme.of(context).colorScheme.onSecondary,
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildCartSummaryBar() {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.primaryContainer,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(25),
            blurRadius: 10,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '$_cartItemCount item${_cartItemCount == 1 ? '' : 's'}',
                    style: TextStyle(
                      fontSize: 12,
                      color: colorScheme.onPrimaryContainer,
                    ),
                  ),
                  Text(
                    '₹${_cartTotal.toStringAsFixed(2)}',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: colorScheme.onPrimaryContainer,
                    ),
                  ),
                ],
              ),
            ),
            ElevatedButton.icon(
              onPressed: () {
                final String acCode = widget.selectedAccount.code ?? '';
                Navigator.of(context).push(MaterialPageRoute(builder: (_) => CartPage(acCode: acCode, selectedAccount: widget.selectedAccount)));
              },
              icon: const Icon(Icons.shopping_cart),
              label: const Text('View Cart'),
              style: ElevatedButton.styleFrom(
                backgroundColor: colorScheme.primary,
                foregroundColor: colorScheme.onPrimary,
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _loadCart() async {
    // TODO: Implement actual cart loading logic if needed
    setState(() {});
  }

  void _openProductDetail(Product product) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ProductDetailPage(product: product, selectedAccount: widget.selectedAccount),
      ),
    );
    if (result == true) {
      await _loadCart();
      setState(() {});
    }
  }

  Widget _buildLoadingState() {
    return const Center(child: CircularProgressIndicator());
  }

  Widget _buildLoadingMoreIndicator() {
    return const Padding(
      padding: EdgeInsets.all(16),
      child: Center(child: CircularProgressIndicator()),
    );
  }

  Widget _buildEmptyState() {
    final colorScheme = Theme.of(context).colorScheme;
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.search_off, size: 80, color: colorScheme.onSurfaceVariant.withAlpha(77)),
          const SizedBox(height: 16),
          Text(
            'No products found',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: colorScheme.onSurfaceVariant),
          ),
          const SizedBox(height: 8),
          Text(
            'Try a different search term',
            style: TextStyle(fontSize: 14, color: colorScheme.onSurfaceVariant.withAlpha(179)),
          ),
        ],
      ),
    );
  }

  List<Product> _generateMockProducts() {
    return List.generate(100, (index) {
      final categories = ['Tablet', 'Syrup', 'Injection', 'Capsule', 'Ointment'];
      final units = ['Strip', 'Box', 'Bottle', 'Tube', 'Vial'];
      final manufacturers = ['Sun Pharma', 'Cipla', 'Dr. Reddy\'s', 'Lupin', 'Torrent'];

      final category = categories[index % categories.length];
      final mrp = 100.0 + (index * 10);
      final price = mrp * (0.7 + (index % 3) * 0.1);

      return Product(
        id: 'MED${1000 + index}',
        name: 'Medicine ${String.fromCharCode(65 + (index % 26))}${index + 1}',
        category: category,
        price: price,
        mrp: mrp,
        unit: units[index % units.length],
        stockQuantity: 50 + (index % 100),
        manufacturer: manufacturers[index % manufacturers.length],
        batchNumber: 'BTH${2024 + (index % 2)}${(index % 12).toString().padLeft(2, '0')}',
        expiryDate: DateTime.now().add(Duration(days: 180 + (index % 365))),
        description: 'This is a description for Medicine ${index + 1}',
      );
    });
  }
}
