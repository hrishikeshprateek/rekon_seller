import 'package:flutter/material.dart';
import '../models/account_model.dart';
import '../models/product_model.dart';
import '../models/cart_item_model.dart';

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
    final endIndex = startIndex + _pageSize;

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

  void _addToCart(Product product) {
    setState(() {
      final existingIndex = _cart.indexWhere((item) => item.product.id == product.id);

      if (existingIndex >= 0) {
        _cart[existingIndex] = _cart[existingIndex].copyWith(
          quantity: _cart[existingIndex].quantity + 1
        );
      } else {
        _cart.add(CartItem(product: product));
      }
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${product.name} added to cart'),
        backgroundColor: Colors.green,
        duration: const Duration(milliseconds: 800),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _removeFromCart(Product product) {
    setState(() {
      _cart.removeWhere((item) => item.product.id == product.id);
    });
  }

  void _updateQuantity(Product product, int newQuantity) {
    if (newQuantity <= 0) {
      _removeFromCart(product);
      return;
    }

    setState(() {
      final index = _cart.indexWhere((item) => item.product.id == product.id);
      if (index >= 0) {
        _cart[index] = _cart[index].copyWith(quantity: newQuantity);
      }
    });
  }

  int _getCartQuantity(Product product) {
    final item = _cart.firstWhere(
      (item) => item.product.id == product.id,
      orElse: () => CartItem(product: product, quantity: 0),
    );
    return item.quantity;
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
                  onPressed: () => _showCartSummary(),
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
                fillColor: colorScheme.surfaceContainerHighest.withOpacity(0.5),
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
              ? colorScheme.primary.withOpacity(0.5)
              : colorScheme.outlineVariant.withOpacity(0.3),
          width: isInCart ? 2 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
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
                color: colorScheme.primaryContainer.withOpacity(0.3),
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
                          color: colorScheme.secondaryContainer.withOpacity(0.5),
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

            // Add/Update Quantity Controls
            const SizedBox(width: 8),

            if (isInCart)
              Container(
                decoration: BoxDecoration(
                  color: colorScheme.primaryContainer.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: colorScheme.primary),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.remove),
                      iconSize: 20,
                      onPressed: () => _updateQuantity(product, inCartQuantity - 1),
                      padding: const EdgeInsets.all(4),
                      constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      child: Text(
                        '$inCartQuantity',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: colorScheme.primary,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.add),
                      iconSize: 20,
                      onPressed: () => _updateQuantity(product, inCartQuantity + 1),
                      padding: const EdgeInsets.all(4),
                      constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                    ),
                  ],
                ),
              )
            else
              ElevatedButton.icon(
                onPressed: product.isInStock ? () => _addToCart(product) : null,
                icon: const Icon(Icons.add_shopping_cart, size: 16),
                label: const Text('Add'),
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

  Widget _buildCartSummaryBar() {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.primaryContainer,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
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
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: colorScheme.onPrimaryContainer,
                    ),
                  ),
                ],
              ),
            ),
            ElevatedButton.icon(
              onPressed: () => _showCartSummary(),
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

  void _showCartSummary() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        maxChildSize: 0.9,
        minChildSize: 0.5,
        builder: (_, controller) => Container(
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              // Handle
              Container(
                margin: const EdgeInsets.symmetric(vertical: 12),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.onSurfaceVariant.withOpacity(0.4),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),

              // Header
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Cart Summary',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(ctx),
                    ),
                  ],
                ),
              ),

              const Divider(),

              // Cart Items
              Expanded(
                child: ListView.builder(
                  controller: controller,
                  padding: const EdgeInsets.all(20),
                  itemCount: _cart.length,
                  itemBuilder: (context, index) {
                    final item = _cart[index];
                    return _buildCartItemCard(item);
                  },
                ),
              ),

              // Total & Checkout
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surfaceContainerHighest,
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                ),
                child: SafeArea(
                  top: false,
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Total:', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                          Text(
                            '₹${_cartTotal.toStringAsFixed(2)}',
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: () {
                            Navigator.pop(ctx);
                            _proceedToCheckout();
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Theme.of(context).colorScheme.primary,
                            foregroundColor: Theme.of(context).colorScheme.onPrimary,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                          ),
                          child: const Text('Proceed to Checkout', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
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

  Widget _buildCartItemCard(CartItem item) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.product.name,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  '₹${item.priceAtAddition.toStringAsFixed(2)} × ${item.quantity}',
                  style: TextStyle(fontSize: 12, color: colorScheme.onSurfaceVariant),
                ),
              ],
            ),
          ),
          Text(
            '₹${item.total.toStringAsFixed(2)}',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: colorScheme.primary,
            ),
          ),
        ],
      ),
    );
  }

  void _proceedToCheckout() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Order created with ${_cart.length} products for ${widget.selectedAccount.name}'),
        backgroundColor: Colors.green,
      ),
    );
    Navigator.pop(context, _cart);
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
          Icon(Icons.search_off, size: 80, color: colorScheme.onSurfaceVariant.withOpacity(0.3)),
          const SizedBox(height: 16),
          Text(
            'No products found',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: colorScheme.onSurfaceVariant),
          ),
          const SizedBox(height: 8),
          Text(
            'Try a different search term',
            style: TextStyle(fontSize: 14, color: colorScheme.onSurfaceVariant.withOpacity(0.7)),
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

