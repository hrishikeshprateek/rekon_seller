import 'package:flutter/material.dart';
import '../models/account_model.dart' as models;
import '../models/product_model.dart';
import '../models/cart_item_model.dart';
import 'select_account_page.dart';

class OrderEntryPage extends StatefulWidget {
  const OrderEntryPage({super.key});

  @override
  State<OrderEntryPage> createState() => _OrderEntryPageState();
}

class _OrderEntryPageState extends State<OrderEntryPage> {
  models.Account? _selectedAccount;
  bool _hasSelectedAccount = false;

  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  List<Product> _allProducts = [];
  List<Product> _displayedProducts = [];
  List<CartItem> _cart = [];

  bool _isLoadingProducts = false;
  bool _isLoadingMore = false;
  bool _hasMoreData = true;

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
    final models.Account? result = await SelectAccountPage.show(
      context,
      title: 'Select Party',
      accountType: 'Party',
      showBalance: true,
      selectedAccount: _selectedAccount,
    );

    if (result != null) {
      setState(() {
        _selectedAccount = result;
        _hasSelectedAccount = true;
      });
      if (mounted) _loadProducts();
    } else if (!_hasSelectedAccount && mounted) {
      Navigator.of(context).pop();
    }
  }

  Future<void> _loadProducts() async {
    setState(() => _isLoadingProducts = true);
    await Future.delayed(const Duration(milliseconds: 800));
    _allProducts = _generateMockProducts();
    _displayedProducts = _allProducts.take(_pageSize).toList();
    _hasMoreData = _displayedProducts.length < _allProducts.length;
    setState(() => _isLoadingProducts = false);
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
        p.name.toLowerCase().contains(_searchQuery.toLowerCase())).toList();

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
            p.name.toLowerCase().contains(query.toLowerCase())).toList();
        _displayedProducts = filtered.take(_pageSize).toList();
        _hasMoreData = _displayedProducts.length < filtered.length;
      }
    });
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

  List<Product> _generateMockProducts() {
    return List.generate(100, (index) {
      final mrp = 100.0 + (index * 10);
      return Product(
        id: 'MED${1000 + index}',
        name: 'Medicine ${String.fromCharCode(65 + (index % 26))}${index + 1}',
        category: 'Tablet',
        price: mrp * 0.8,
        mrp: mrp,
        unit: 'Strip',
        stockQuantity: 50 + (index % 100),
        manufacturer: 'Pharma Co.',
        batchNumber: 'B00$index',
        expiryDate: DateTime.now().add(const Duration(days: 365)),
        description: 'Desc',
      );
    });
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

    // Generate mock rating data based on index so it stays consistent while scrolling
    final double mockRating = 3.5 + (index % 15) * 0.1; // Ratings between 3.5 and 4.9
    final int mockRatingCount = 50 + (index * 7);

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
                Text(product.name, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                const SizedBox(height: 2),
                Text(product.manufacturer ?? '', style: TextStyle(fontSize: 11, color: colorScheme.onSurfaceVariant)),

                // --- NEW: Ratings Row ---
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(Icons.star_rounded, size: 14, color: Colors.amber.shade600),
                    const SizedBox(width: 4),
                    Text(mockRating.toStringAsFixed(1), style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: colorScheme.onSurface)),
                    const SizedBox(width: 4),
                    Text("($mockRatingCount)", style: TextStyle(fontSize: 11, color: colorScheme.onSurfaceVariant)),
                  ],
                ),
                const SizedBox(height: 6),

                // Prices Row
                Row(
                  children: [
                    Text("₹${product.price.toStringAsFixed(2)}", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: colorScheme.primary)),
                    const SizedBox(width: 8),
                    if (product.mrp > product.price)
                      Text("₹${product.mrp.toStringAsFixed(2)}", style: TextStyle(decoration: TextDecoration.lineThrough, fontSize: 11, color: colorScheme.outline)),
                  ],
                ),
              ],
            ),
          ),

          // Action
          if (qty == 0)
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
            )
          else
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
                      onPressed: () {
                        Navigator.pop(ctx);
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Order Placed Successfully!")));
                      },
                      child: const Text("Confirm Order", style: TextStyle(fontWeight: FontWeight.bold)),
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