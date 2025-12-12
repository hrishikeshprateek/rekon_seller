import 'package:flutter/material.dart';
import 'receipt_book.dart';
import 'receipt_entry.dart';
import 'pages/order_entry_page.dart';
import 'pages/my_cart_page.dart';
import 'pages/order_book_page.dart';
import 'pages/order_status_page.dart';
import 'pages/statement_page.dart';
import 'pages/outstanding_page.dart';
import 'pages/trial_balance_page.dart';
import 'pages/bank_page.dart';
import 'pages/delivery_collection_page.dart';
import 'pages/delivery_book_page.dart';
import 'pages/po_book_page.dart';
import 'pages/stock_sales_page.dart';
import 'pages/closing_stock_page.dart';
import 'pages/dump_stock_page.dart';
import 'pages/near_expiry_page.dart';
import 'pages/shortage_page.dart';
import 'pages/itemwise_sale_page.dart';
import 'pages/partywise_sale_page.dart';
import 'pages/notification_page.dart';
import 'pages/refer_and_earn_page.dart';
import 'pages/contact_support_page.dart';
import 'widgets/spotlight_search.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedBottomIndex = 0;

  List<SearchableItem> _buildSearchableItems(BuildContext context) {
    final items = <SearchableItem>[];

    // Sale Order
    items.add(SearchableItem(
      title: 'Order Entry',
      category: 'Sale Order',
      icon: Icons.add_shopping_cart_rounded,
      onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const OrderEntryPage())),
    ));
    items.add(SearchableItem(
      title: 'My Cart',
      category: 'Sale Order',
      icon: Icons.shopping_cart_outlined,
      onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const MyCartPage())),
    ));
    items.add(SearchableItem(
      title: 'Order Book',
      category: 'Sale Order',
      icon: Icons.menu_book_rounded,
      onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const OrderBookPage())),
    ));
    items.add(SearchableItem(
      title: 'Order Status',
      category: 'Sale Order',
      icon: Icons.pending_actions_rounded,
      onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const OrderStatusPage())),
    ));

    // Receipts
    items.add(SearchableItem(
      title: 'Receipt Entry',
      category: 'Receipts',
      icon: Icons.receipt_long_rounded,
      onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const CreateReceiptScreen())),
    ));
    items.add(SearchableItem(
      title: 'Receipt Book',
      category: 'Receipts',
      icon: Icons.library_books_rounded,
      onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const ReceiptBookPage())),
    ));

    // Accounts
    items.add(SearchableItem(
      title: 'Statement',
      category: 'Accounts',
      icon: Icons.description_outlined,
      onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const StatementPage())),
    ));
    items.add(SearchableItem(
      title: 'Outstanding',
      category: 'Accounts',
      icon: Icons.account_balance_wallet_outlined,
      onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const OutstandingPage())),
    ));
    items.add(SearchableItem(
      title: 'Trial Balance',
      category: 'Accounts',
      icon: Icons.balance_rounded,
      onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const TrialBalancePage())),
    ));
    items.add(SearchableItem(
      title: 'Bank',
      category: 'Accounts',
      icon: Icons.account_balance_rounded,
      onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const BankPage())),
    ));

    // Delivery & Collection
    items.add(SearchableItem(
      title: 'Delivery & Collection',
      category: 'Delivery & Collection',
      icon: Icons.local_shipping_outlined,
      onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const DeliveryCollectionPage())),
    ));
    items.add(SearchableItem(
      title: 'Delivery Book',
      category: 'Delivery & Collection',
      icon: Icons.delivery_dining_outlined,
      onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const DeliveryBookPage())),
    ));

    // Purchase Order
    items.add(SearchableItem(
      title: 'PO Book',
      category: 'Purchase Order',
      icon: Icons.shopping_bag_outlined,
      onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const POBookPage())),
    ));

    // Stock Report
    items.add(SearchableItem(
      title: 'Stock & Sales',
      category: 'Stock Report',
      icon: Icons.inventory_2_outlined,
      onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const StockSalesPage())),
    ));
    items.add(SearchableItem(
      title: 'Closing Stock',
      category: 'Stock Report',
      icon: Icons.warehouse_outlined,
      onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const ClosingStockPage())),
    ));
    items.add(SearchableItem(
      title: 'Dump Stock',
      category: 'Stock Report',
      icon: Icons.delete_sweep_outlined,
      onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const DumpStockPage())),
    ));
    items.add(SearchableItem(
      title: 'Near Expiry',
      category: 'Stock Report',
      icon: Icons.access_time_rounded,
      onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const NearExpiryPage())),
    ));
    items.add(SearchableItem(
      title: 'Shortage',
      category: 'Stock Report',
      icon: Icons.trending_down_rounded,
      onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const ShortagePage())),
    ));

    // Sale Report
    items.add(SearchableItem(
      title: 'Itemwise Sale',
      category: 'Sale Report',
      icon: Icons.category_outlined,
      onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const ItemwiseSalePage())),
    ));
    items.add(SearchableItem(
      title: 'Partywise Sale',
      category: 'Sale Report',
      icon: Icons.people_outline_rounded,
      onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const PartywiseSalePage())),
    ));

    // General
    items.add(SearchableItem(
      title: 'Notification',
      category: 'General',
      icon: Icons.notifications_outlined,
      onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const NotificationPage())),
    ));
    items.add(SearchableItem(
      title: 'Refer and Earn',
      category: 'General',
      icon: Icons.card_giftcard_rounded,
      onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const ReferAndEarnPage())),
    ));
    items.add(SearchableItem(
      title: 'Contact Support',
      category: 'General',
      icon: Icons.headset_mic_outlined,
      onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const ContactSupportPage())),
    ));

    return items;
  }

  void _openSpotlightSearch() {
    SpotlightSearch.show(context, _buildSearchableItems(context));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    // --- 1. Main Sections (1-7) ---
    final List<Map<String, dynamic>> complexSections = [
      {
        'title': 'Sale Order',
        'items': [
          {'icon': Icons.add_shopping_cart_rounded, 'label': 'Order Entry', 'route': () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const OrderEntryPage()))},
          {'icon': Icons.shopping_cart_outlined, 'label': 'My Cart', 'route': () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const MyCartPage()))},
          {'icon': Icons.menu_book_rounded, 'label': 'Order Book', 'route': () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const OrderBookPage()))},
          {'icon': Icons.pending_actions_rounded, 'label': 'Order Status', 'route': () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const OrderStatusPage()))},
        ]
      },
      {
        'title': 'Receipts',
        'items': [
          {'icon': Icons.receipt_long_rounded, 'label': 'Receipt Entry', 'route': () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const CreateReceiptScreen()))},
          {'icon': Icons.library_books_rounded, 'label': 'Receipt Book', 'route': () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const ReceiptBookPage()))},
        ]
      },
      {
        'title': 'Accounts',
        'items': [
          {'icon': Icons.description_outlined, 'label': 'Statement', 'route': () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const StatementPage()))},
          {'icon': Icons.account_balance_wallet_outlined, 'label': 'Outstanding', 'route': () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const OutstandingPage()))},
          {'icon': Icons.balance_rounded, 'label': 'Trial Balance', 'route': () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const TrialBalancePage()))},
          {'icon': Icons.account_balance_rounded, 'label': 'Bank', 'route': () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const BankPage()))},
        ]
      },
      {
        'title': 'Delivery & Collection',
        'items': [
          {'icon': Icons.local_shipping_outlined, 'label': 'Delivery & Collection', 'route': () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const DeliveryCollectionPage()))},
          {'icon': Icons.delivery_dining_outlined, 'label': 'Delivery Book', 'route': () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const DeliveryBookPage()))},
        ]
      },
      {
        'title': 'Purchase Order',
        'items': [
          {'icon': Icons.shopping_bag_outlined, 'label': 'PO Book', 'route': () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const POBookPage()))},
        ]
      },
      {
        'title': 'Stock Report',
        'items': [
          {'icon': Icons.inventory_2_outlined, 'label': 'Stock & Sales', 'route': () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const StockSalesPage()))},
          {'icon': Icons.warehouse_outlined, 'label': 'Closing Stock', 'route': () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const ClosingStockPage()))},
          {'icon': Icons.delete_sweep_outlined, 'label': 'Dump Stock', 'route': () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const DumpStockPage()))},
          {'icon': Icons.access_time_rounded, 'label': 'Near Expiry', 'route': () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const NearExpiryPage()))},
          {'icon': Icons.trending_down_rounded, 'label': 'Shortage', 'route': () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const ShortagePage()))},
        ]
      },
      {
        'title': 'Sale Report',
        'items': [
          {'icon': Icons.category_outlined, 'label': 'Itemwise Sale', 'route': () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const ItemwiseSalePage()))},
          {'icon': Icons.people_outline_rounded, 'label': 'Partywise Sale', 'route': () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const PartywiseSalePage()))},
        ]
      },
    ];

    // --- 2. Extras (8-10) ---
    final List<Map<String, dynamic>> extras = [
      {'icon': Icons.notifications_outlined, 'label': 'Notification', 'route': () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const NotificationPage()))},
      {'icon': Icons.card_giftcard_rounded, 'label': 'Refer and Earn', 'route': () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const ReferAndEarnPage()))},
      {'icon': Icons.headset_mic_outlined, 'label': 'Contact Support', 'route': () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const ContactSupportPage()))},
    ];

    return Scaffold(
      // Fixed: Use 'background' instead of 'surfaceContainerLowest' for compatibility
      backgroundColor: colorScheme.background,
      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) => [
          SliverAppBar(
            pinned: true,
            floating: true,
            backgroundColor: colorScheme.surface,
            // Fixed: Removed 'surfaceTintColor' if it causes issues on older versions
            elevation: 0,
            scrolledUnderElevation: 0,
            toolbarHeight: 90,
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      colorScheme.surface,
                      colorScheme.background, // Smooth fade
                    ],
                  ),
                ),
              ),
            ),
            title: Padding(
              padding: const EdgeInsets.only(top: 8.0),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: colorScheme.primary.withOpacity(0.2), width: 2),
                    ),
                    child: CircleAvatar(
                      radius: 22,
                      backgroundColor: colorScheme.primaryContainer,
                      child: Icon(Icons.person, size: 24, color: colorScheme.onPrimaryContainer),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "New Dashboard Seller",
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: colorScheme.onSurface),
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          _buildProfileBadge(theme, "Login: Name", colorScheme.secondaryContainer, colorScheme.onSecondaryContainer),
                          const SizedBox(width: 8),
                          _buildProfileBadge(theme, "Role: Seller", colorScheme.tertiaryContainer, colorScheme.onTertiaryContainer),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
            actions: [
              Container(
                margin: const EdgeInsets.only(right: 16),
                decoration: BoxDecoration(
                  color: colorScheme.surfaceVariant.withOpacity(0.5), // Fixed color
                  shape: BoxShape.circle,
                ),
                child: IconButton(
                  onPressed: _openSpotlightSearch,
                  icon: const Icon(Icons.search),
                  color: colorScheme.onSurfaceVariant,
                  tooltip: 'Search features',
                ),
              ),
            ],
          ),
        ],
        body: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 40),
          children: [
            // --- Render Sections 1 to 7 ---
            ...complexSections.map((section) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSectionHeader(context, section['title']),
                  const SizedBox(height: 4),
                  _buildIconGrid(context, section['items']),
                  const SizedBox(height: 24),
                ],
              );
            }),

            // --- Render Extras ---
            _buildSectionHeader(context, 'GENERAL'),
            const SizedBox(height: 4),
            _buildIconGrid(context, extras),
          ],
        ),
      ),
      bottomNavigationBar: NavigationBar(
        height: 70,
        selectedIndex: _selectedBottomIndex,
        onDestinationSelected: (i) => setState(() => _selectedBottomIndex = i),
        elevation: 4,
        backgroundColor: colorScheme.surface,
        indicatorColor: colorScheme.primaryContainer,
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        destinations: const [
          NavigationDestination(icon: Icon(Icons.grid_view_outlined), selectedIcon: Icon(Icons.grid_view_rounded), label: 'Apps'),
          NavigationDestination(icon: Icon(Icons.analytics_outlined), selectedIcon: Icon(Icons.analytics_rounded), label: 'Reports'),
          NavigationDestination(icon: Icon(Icons.settings_outlined), selectedIcon: Icon(Icons.settings_rounded), label: 'Settings'),
        ],
      ),
    );
  }

  // --- WIDGET HELPERS ---

  Widget _buildProfileBadge(ThemeData theme, String text, Color bg, Color fg) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bg.withOpacity(0.5),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: bg, width: 0.5),
      ),
      child: Text(
        text,
        style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: fg),
      ),
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title) {
    final colorScheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(left: 4),
      child: Row(
        children: [
          Text(
            title.toUpperCase(),
            style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w800,
                color: colorScheme.primary,
                letterSpacing: 1.2
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Container(
              height: 1,
              color: colorScheme.outlineVariant.withOpacity(0.5),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildIconGrid(BuildContext context, List<Map<String, dynamic>> items) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: items.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 1.05,
      ),
      itemBuilder: (context, index) {
        return _buildIconTile(context, items[index]);
      },
    );
  }

  Widget _buildIconTile(BuildContext context, Map<String, dynamic> item) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surface, // Clean white card
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
        border: Border.all(color: colorScheme.outlineVariant.withOpacity(0.2)),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            // If the item has a route function, call it. Otherwise show a snackbar.
            if (item.containsKey('route') && item['route'] is Function) {
              (item['route'] as Function)();
              return;
            }
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(
              content: Text(item['label'] ?? ''),
              duration: const Duration(milliseconds: 500),
              behavior: SnackBarBehavior.floating,
            ));
          },
          borderRadius: BorderRadius.circular(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Icon Container
              Container(
                height: 42,
                width: 42,
                decoration: BoxDecoration(
                  color: colorScheme.primaryContainer.withOpacity(0.4),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(item['icon'], color: colorScheme.primary, size: 22),
              ),
              const SizedBox(height: 10),

              // Text Label
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: Text(
                  item['label'],
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: colorScheme.onSurface,
                    height: 1.2,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}