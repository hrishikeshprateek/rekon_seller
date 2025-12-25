import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:cached_network_image/cached_network_image.dart';
import 'package:provider/provider.dart';
import 'dart:async';

import 'auth_service.dart';
import 'dashboard_service.dart' as api;
import 'login_screen.dart';
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
import 'models/dashboard_config_model.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedBottomIndex = 0;
  int _currentBannerIndex = 0;
  DashboardConfig? _config;
  bool _isLoading = true;
  late PageController _bannerPageController;
  Timer? _bannerTimer;

  @override
  void initState() {
    super.initState();
    _bannerPageController = PageController(viewportFraction: 0.92);
    _loadConfig();
  }

  @override
  void dispose() {
    _bannerPageController.dispose();
    _bannerTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadConfig() async {
    try {
      // Fetch from API
      final dashboardService = Provider.of<api.DashboardService>(context, listen: false);
      final response = await dashboardService.getDashboard();

      if (response.success && response.data != null) {
        // Convert API data to local DashboardConfig format
        setState(() {
          _config = _convertApiDataToConfig(response.data!);
          _isLoading = false;
        });

        if (_config?.bannerList.visible ?? false) {
          _startBannerAutoPlay();
        }
      } else {
        // Fallback to local JSON if API fails
        await _loadLocalConfig();
      }
    } catch (e) {
      debugPrint('Error loading dashboard from API: $e');
      // Fallback to local JSON
      await _loadLocalConfig();
    }
  }

  Future<void> _loadLocalConfig() async {
    try {
      final String jsonString = await rootBundle.loadString('assets/config/dashboard_config.json');
      setState(() {
        _config = DashboardConfig.fromJsonString(jsonString);
        _isLoading = false;
      });

      if (_config?.bannerList.visible ?? false) {
        _startBannerAutoPlay();
      }
    } catch (e) {
      debugPrint('Error loading local config: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  DashboardConfig _convertApiDataToConfig(api.DashboardData apiData) {
    // Convert API sections to local format
    final sections = apiData.sections.where((s) => s.visible && s.items.isNotEmpty).map((section) {
      return DashboardSection(
        id: section.id.toString(),
        title: section.title,
        visible: section.visible,
        bgColor: section.bgColor ?? '#FFFFFF',
        levelColor: section.levelColor ?? '#000000',
        items: section.items.where((item) => item.visible && item.isActive).map((item) {
          return DashboardItem(
            id: item.id.toString(),
            label: item.title,
            icon: item.icon ?? 'grid_view_outlined',
            route: item.route ?? '',
            visible: item.visible,
            isActive: item.isActive,
            bgCard: item.bgCard ?? '#FFFFFF',
            colorTitle: item.colorTitle ?? '#000000',
            type: 'menu',
            image: item.image ?? '',
          );
        }).toList(),
      );
    }).toList();

    // Create banner list from API data
    // Defensive: apiData.bannerList.banners may be null -> treat as empty list
    final apiBanners = apiData.bannerList.banners ?? <dynamic>[];
    final banners = apiBanners.map((banner) {
      // banner might be a simple map or an object; read apId defensively
      final apId = (banner is Map && banner.containsKey('Ap_Id')) ? banner['Ap_Id'] : (banner?.apId ?? 0);
      return BannerItem(
        id: apId is int ? apId : (int.tryParse(apId.toString()) ?? 0),
        image: 'https://via.placeholder.com/800x300?text=Banner+${apId}', // Placeholder
        title: 'Banner ${apId}',
        visible: true,
        link: '',
      );
    }).toList();

    return DashboardConfig(
      appTitle: apiData.appTitle,
      userInfo: UserInfo(
        loginLabel: apiData.userInfo.loginLabel,
        roleLabel: apiData.userInfo.roleLabel,
      ),
      bgColor: apiData.bgColor,
      appBar: AppBarConfig(
        bgColor: apiData.appBar.bgColor,
        textColor: apiData.appBar.textColor,
        showSearch: apiData.appBar.showSearch,
        showProfile: apiData.appBar.showProfile,
      ),
      bannerList: BannerList(
        visible: apiData.bannerList.visible,
        bgColor: apiData.bannerList.bgColor,
        banners: banners,
      ),
      orderStatus: apiData.orderStatus != null
          ? OrderStatus(
              visible: apiData.orderStatus!.visible,
              bgColor: apiData.orderStatus!.bgColor,
              levelColor: apiData.orderStatus!.levelColor,
              title: apiData.orderStatus!.title,
              date: apiData.orderStatus!.date,
              amount: apiData.orderStatus!.amount,
              currency: '₹',
              id: 0,
              status: apiData.orderStatus!.status,
            )
          : OrderStatus(
              visible: false,
              bgColor: '#13A2DF',
              levelColor: '#FFFFFF',
              title: 'Order Status',
              date: '',
              amount: 0,
              currency: '₹',
              id: 0,
              status: 'No Active Order',
            ),
      orderHistory: apiData.orderHistory != null
          ? OrderHistory(
              visible: apiData.orderHistory!.visible,
              bgColor: apiData.orderHistory!.bgColor,
              levelColor: apiData.orderHistory!.levelColor,
              title: apiData.orderHistory!.title,
              totalOrdersCount: apiData.orderHistory!.totalOrdersCount,
              totalOrdersAmount: apiData.orderHistory!.totalOrdersAmount,
              invoicesCount: apiData.orderHistory!.invoicesCount,
              invoicesAmount: apiData.orderHistory!.invoicesAmount,
            )
          : OrderHistory(
              visible: false,
              bgColor: '#FFFFFF',
              levelColor: '#000000',
              title: 'Order History',
              totalOrdersCount: 0,
              totalOrdersAmount: 0,
              invoicesCount: 0,
              invoicesAmount: 0,
            ),
      newArrival: NewArrival(
        visible: apiData.newArrival.visible,
        bgColor: apiData.newArrival.bgColor,
        levelColor: apiData.newArrival.levelColor,
        title: apiData.newArrival.title,
        arrivalList: apiData.newArrival.arrivalList,
      ),
      brands: Brands(
        visible: apiData.brands.visible,
        bgColor: apiData.brands.bgColor,
        levelColor: apiData.brands.levelColor,
        title: apiData.brands.title,
        brandList: apiData.brands.brandList,
      ),
      testimonials: Testimonials(
        visible: false,
        bgColor: '#FFFFFF',
        levelColor: '#000000',
        title: 'Testimonials',
        testimonialsList: [],
      ),
      tenantDetail: TenantDetail(
        showIncreaseDecreaseButton: true,
        showDiscPcs: true,
        showAddDetailsBottomSheet: true,
        showItemComposition: true,
        showAdditionalDiscount: true,
        enableScreenshot: true,
        showFreeQty: true,
        minOrderValue: 0,
        showStock: true,
        showRate: true,
        showDiscPer: true,
        showItemRefNumber: true,
        showItemCategory: true,
        showItemMfgComp: true,
        includeTax: 'N',
        showMrp: true,
        showScheme: apiData.tenantDetail.showScheme ?? true,
        enablePrice: true,
        negativeStock: apiData.tenantDetail.negativeStock,
        showItemRemark: true,
        showProductDesc: true,
        showLocation: true,
        showManualScheme: true,
      ),
      tags: apiData.tags,
      sections: sections,
      extras: [
        // Add extras/more items
        DashboardItem(
          id: 'notification',
          label: 'Notification',
          icon: 'notifications_outlined',
          route: 'NotificationPage',
          visible: true,
          isActive: true,
          bgCard: '#FFFFFF',
          colorTitle: '#1E5FA6',
          type: '21',
          image: '',
        ),
        DashboardItem(
          id: 'refer_and_earn',
          label: 'Refer and Earn',
          icon: 'card_giftcard_rounded',
          route: 'ReferAndEarnPage',
          visible: true,
          isActive: true,
          bgCard: '#FFFFFF',
          colorTitle: '#1E5FA6',
          type: '22',
          image: '',
        ),
        DashboardItem(
          id: 'contact_support',
          label: 'Contact Support',
          icon: 'headset_mic_outlined',
          route: 'ContactSupportPage',
          visible: true,
          isActive: true,
          bgCard: '#FFFFFF',
          colorTitle: '#1E5FA6',
          type: '23',
          image: '',
        ),
      ],
      bottomNavigation: [
        BottomNavItem(
          id: '1',
          label: 'Home',
          icon: 'grid_view_outlined',
          selectedIcon: 'grid_view_rounded',
        ),
        BottomNavItem(
          id: '2',
          label: 'Analytics',
          icon: 'analytics_outlined',
          selectedIcon: 'analytics_rounded',
        ),
        BottomNavItem(
          id: '3',
          label: 'Settings',
          icon: 'settings_outlined',
          selectedIcon: 'settings_rounded',
        ),
      ],
    );
  }

  void _startBannerAutoPlay() {
    _bannerTimer?.cancel();
    final visibleCount = _config?.bannerList.banners.where((b) => b.visible).length ?? 0;
    if (visibleCount <= 1) return;
    _bannerTimer = Timer.periodic(const Duration(seconds: 4), (timer) {
      if (!_bannerPageController.hasClients) return;
      final next = (_currentBannerIndex + 1) % visibleCount;
      _bannerPageController.animateToPage(next, duration: const Duration(milliseconds: 600), curve: Curves.easeInOut);
    });
  }

  Color _parseColor(String hexColor) {
    try {
      String color = hexColor.replaceAll('#', '');
      if (color.length == 6) color = 'FF$color';
      return Color(int.parse(color, radix: 16));
    } catch (_) {
      return Colors.white;
    }
  }

  IconData _getIconData(String iconName) {
    const iconMap = {
      'add_shopping_cart_rounded': Icons.add_shopping_cart_rounded,
      'library_books_rounded': Icons.library_books_rounded,
      'description_outlined': Icons.description_outlined,
      'account_balance_wallet_outlined': Icons.account_balance_wallet_outlined,
      'balance_rounded': Icons.balance_rounded,
      'account_balance_rounded': Icons.account_balance_rounded,
      'local_shipping_outlined': Icons.local_shipping_outlined,
      'delivery_dining_outlined': Icons.delivery_dining_outlined,
      'shopping_bag_outlined': Icons.shopping_bag_outlined,
      'inventory_2_outlined': Icons.inventory_2_outlined,
      'warehouse_outlined': Icons.warehouse_outlined,
      'delete_sweep_outlined': Icons.delete_sweep_outlined,
      'access_time_rounded': Icons.access_time_rounded,
      'trending_down_rounded': Icons.trending_down_rounded,
      'category_outlined': Icons.category_outlined,
      'people_outline_rounded': Icons.people_outline_rounded,
      'notifications_outlined': Icons.notifications_outlined,
      'card_giftcard_rounded': Icons.card_giftcard_rounded,
      'headset_mic_outlined': Icons.headset_mic_outlined,
      'grid_view_outlined': Icons.grid_view_outlined,
      'grid_view_rounded': Icons.grid_view_rounded,
      'analytics_outlined': Icons.analytics_outlined,
      'analytics_rounded': Icons.analytics_rounded,
      'settings_outlined': Icons.settings_outlined,
      'settings_rounded': Icons.settings_rounded,
      'shopping_cart_outlined': Icons.shopping_cart_outlined,
      'menu_book_rounded': Icons.menu_book_rounded,
      'pending_actions_rounded': Icons.pending_actions_rounded,
      'receipt_long_rounded': Icons.receipt_long_rounded,
      // --- backend-provided icon names (new/legacy variations) ---
      'reorder': Icons.reorder,
      'browse_gallery': Icons.photo_library,
      'all_inbox': Icons.all_inbox,
      'table_view': Icons.table_view,
      'receipt': Icons.receipt_long,
      'work_history': Icons.work_history,
      'account_balance_wallet': Icons.account_balance_wallet,
      'view_day': Icons.view_day,
      'payment': Icons.payment,
      'pending': Icons.pending,
      'clear_all': Icons.clear_all,
      'view_timeline': Icons.view_timeline,
      'list_alt': Icons.list_alt,
      'prem_identity': Icons.perm_identity, // likely typo from backend (perm_identity)
      'view_list': Icons.view_list,
      'autorenew': Icons.autorenew,
      'error_outline': Icons.error_outline,
      'checklist': Icons.checklist, // modern Material icon; fallback will apply if not available
      'signal_cellular_alt': Icons.signal_cellular_alt,
      'fact_check': Icons.fact_check,
      'assignment': Icons.assignment,
      'library_check_alt': Icons.library_add_check,
      'store': Icons.store,
      'text_fields': Icons.text_fields,
      'mark_chat_read': Icons.mark_chat_read,
      'report': Icons.report,
    };
    if (iconName.isEmpty) return Icons.help_outline;

    // Create a list of candidate keys we'll try, ordered by priority.
    final cleaned = iconName.trim();
    final snake = cleaned.toLowerCase().replaceAll(RegExp(r'[\s-]+'), '_');
    final lower = cleaned.toLowerCase();
    final noUnderscore = snake.replaceAll('_', '');
    final noPrefix = snake.replaceFirst(RegExp(r'^(ic_|icon_)'), '');
    final simplified = snake.replaceAll(RegExp(r'(_outlined|_rounded|_sharp|_filled|_two_tone|_twotone)'), '');

    final candidates = <String>{}
      ..add(snake)
      ..add(lower)
      ..add(simplified)
      ..add(noUnderscore)
      ..add(noPrefix);

    // Also try variants with common suffixes the backend may send (e.g., 'outlined', 'rounded')
    final suffixes = ['_outlined', '_rounded', '_sharp', '_filled'];
    for (final c in List<String>.from(candidates)) {
      for (final suf in suffixes) {
        candidates.add('${c}$suf');
      }
    }

    // Try all candidates against the map
    for (final k in candidates) {
      if (k.isEmpty) continue;
      if (iconMap.containsKey(k)) return iconMap[k]!;
    }

    // As a last resort, try to match by removing underscores and matching substrings
    for (final entry in iconMap.entries) {
      final ekey = entry.key.replaceAll('_', '');
      if (noUnderscore.isNotEmpty && ekey == noUnderscore) return entry.value;
      if (ekey.contains(noUnderscore) || noUnderscore.contains(ekey)) return entry.value;
    }

    // Log unmatched icon names in debug so backend can adjust naming (won't spam in release)
    assert(() {
      debugPrint('[HomeScreen] Unmapped icon name: "$iconName" (tried: ${candidates.toList()})');
      return true;
    }());

    return Icons.help_outline;
  }

  /// Robustly map a backend-provided route name (or label) to an actual widget.
  /// Tries multiple normalized forms so small differences from backend don't break navigation.
  Widget? _getRouteWidget(String? routeName, {String? label}) {
    // Helper normalization: lowercase, remove spaces/underscores, remove common suffixes
    String normalize(String? s) {
      if (s == null) return '';
      var t = s.toLowerCase().trim();
      t = t.replaceAll(RegExp(r'[_\s-]+'), '');
      t = t.replaceAll('page', '');
      t = t.replaceAll('screen', '');
      t = t.replaceAll('view', '');
      return t;
    }

    final normalizedRoute = normalize(routeName);
    final normalizedLabel = normalize(label);

    final routeMap = <String, Widget>{
      // keys are normalized forms
      'orderentry': const OrderEntryPage(),
      'mycart': const MyCartPage(),
      'orderbook': const OrderBookPage(),
      'orderstatus': const OrderStatusPage(),
      'createreceipt': const CreateReceiptScreen(),
      'receiptbook': const CreateReceiptScreen(), // fallback
      'statement': const StatementPage(),
      'outstanding': const OutstandingPage(),
      'trialbalance': const TrialBalancePage(),
      'bank': const BankPage(),
      'deliverycollection': const DeliveryCollectionPage(),
      'deliverybook': const DeliveryBookPage(),
      'pobook': const POBookPage(),
      'stocksales': const StockSalesPage(),
      'closingstock': const ClosingStockPage(),
      'dumpstock': const DumpStockPage(),
      'nearexpiry': const NearExpiryPage(),
      'shortage': const ShortagePage(),
      'itemwisesale': const ItemwiseSalePage(),
      'partywisesale': const PartywiseSalePage(),
      'notification': const NotificationPage(),
      'referandearn': const ReferAndEarnPage(),
      'contactsupport': const ContactSupportPage(),
    };

    // Try exact normalized route name first
    if (normalizedRoute.isNotEmpty && routeMap.containsKey(normalizedRoute)) return routeMap[normalizedRoute];

    // Try normalized label as fallback
    if (normalizedLabel.isNotEmpty && routeMap.containsKey(normalizedLabel)) return routeMap[normalizedLabel];

    // Try a few heuristic transforms: strip trailing s (plural), try with/without "book" suffix
    String heur(String t) => t.endsWith('s') ? t.substring(0, t.length - 1) : t;
    final h1 = heur(normalizedRoute);
    if (h1.isNotEmpty && routeMap.containsKey(h1)) return routeMap[h1];
    final h2 = heur(normalizedLabel);
    if (h2.isNotEmpty && routeMap.containsKey(h2)) return routeMap[h2];

    return null;
  }

  List<SearchableItem> _buildSearchableItems(BuildContext context) {
    final items = <SearchableItem>[];
    if (_config == null) return items;

    for (var section in _config!.sections) {
      for (var item in section.items) {
        if (item.visible && item.isActive) {
          items.add(SearchableItem(
            title: item.label,
            category: section.title,
            icon: _getIconData(item.icon),
            onTap: () {
              final widget = _getRouteWidget(item.route, label: item.label);
              if (widget != null) Navigator.of(context).push(MaterialPageRoute(builder: (_) => widget));
            },
          ));
        }
      }
    }

    for (var extra in _config!.extras) {
      if (extra.visible && extra.isActive) {
        items.add(SearchableItem(
          title: extra.label,
          category: 'General',
          icon: _getIconData(extra.icon),
          onTap: () {
            final widget = _getRouteWidget(extra.route, label: extra.label);
            if (widget != null) Navigator.of(context).push(MaterialPageRoute(builder: (_) => widget));
          },
        ));
      }
    }

    return items;
  }

  void _openSpotlightSearch() {
    SpotlightSearch.show(context, _buildSearchableItems(context));
  }

  Future<void> _handleLogout(BuildContext context, AuthService authService) async {
    // Show confirmation dialog
    final shouldLogout = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure you want to logout?'),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(
              backgroundColor: Colors.red.shade700,
            ),
            child: const Text('Logout'),
          ),
        ],
      ),
    );

    if (shouldLogout == true) {
      // Show loading indicator
      if (!mounted) return;
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: CircularProgressIndicator(),
        ),
      );

      // Logout
      await authService.logout();

      if (!mounted) return;

      // Close loading dialog
      Navigator.pop(context);

      // Navigate to login screen
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => const LoginScreen()),
        (route) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    if (_isLoading || _config == null) {
      return Scaffold(
        backgroundColor: colorScheme.surface,
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: _parseColor(_config!.bgColor),
      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) => [
          SliverAppBar(
            floating: true,
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
                      _parseColor(_config!.appBar?.bgColor ?? _config!.bgColor),
                      _parseColor(_config!.appBar?.bgColor ?? _config!.bgColor),
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
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: colorScheme.primary.withAlpha(51),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
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
                        _config!.appTitle,
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: _parseColor(_config!.appBar?.textColor ?? '#000000')),
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          _buildProfileBadge(theme, _config!.userInfo.loginLabel, colorScheme.secondaryContainer, colorScheme.onSecondaryContainer),
                          const SizedBox(width: 8),
                          _buildProfileBadge(theme, _config!.userInfo.roleLabel, colorScheme.tertiaryContainer, colorScheme.onTertiaryContainer),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
            actions: [
              if (_config!.appBar?.showSearch ?? true)
                Container(
                  margin: const EdgeInsets.only(right: 8),
                  decoration: BoxDecoration(
                    color: colorScheme.surface.withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                  ),
                  child: IconButton(
                    onPressed: _openSpotlightSearch,
                    icon: const Icon(Icons.search),
                    color: colorScheme.onSurfaceVariant,
                    tooltip: 'Search features',
                  ),
                ),
              // Profile Menu Button
              Consumer<AuthService>(
                builder: (context, authService, child) {
                  final user = authService.currentUser;
                  return PopupMenuButton(
                    icon: Icon(Icons.more_vert, color: colorScheme.onSurfaceVariant),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    offset: const Offset(0, 50),
                    itemBuilder: (context) => [
                      // User Info Header
                      if (user != null)
                        PopupMenuItem(
                          enabled: false,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                user.fullName.isNotEmpty ? user.fullName : 'User',
                                style: theme.textTheme.titleSmall?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: colorScheme.onSurface,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                user.mobileNumber,
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: colorScheme.onSurfaceVariant,
                                ),
                              ),
                              Text(
                                'License: ${user.licenseNumber}',
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: colorScheme.onSurfaceVariant,
                                ),
                              ),
                              const Divider(height: 16),
                            ],
                          ),
                        ),
                      // User Type
                      if (user != null)
                        PopupMenuItem(
                          enabled: false,
                          child: Row(
                            children: [
                              Icon(Icons.work_outline, size: 16, color: colorScheme.primary),
                              const SizedBox(width: 8),
                              Text(
                                'Role: ${user.userType}',
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: colorScheme.onSurface,
                                ),
                              ),
                            ],
                          ),
                        ),
                      // Logout Button
                      PopupMenuItem(
                        onTap: () => _handleLogout(context, authService),
                        child: Row(
                          children: [
                            Icon(Icons.logout, size: 18, color: Colors.red.shade700),
                            const SizedBox(width: 12),
                            Text(
                              'Logout',
                              style: TextStyle(
                                color: Colors.red.shade700,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  );
                },
              ),
              const SizedBox(width: 8),
            ],
          ),
        ],
        body: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 40),
          children: [
            if (_config!.bannerList.visible && (_config!.bannerList.banners?.where((b) => b.visible).isNotEmpty ?? false))
              _buildBannerCarousel(),

            const SizedBox(height: 16),

            // Render sections
            ..._config!.sections.where((s) => s.visible).map((section) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSectionHeader(context, section.title, bgColor: section.bgColor, levelColor: section.levelColor),
                  // Reduced gap between header and grid for a more compact layout
                  const SizedBox(height: 8),
                  _buildIconGridFromConfig(context, section.items.where((item) => item.visible).toList()),
                  // Slightly reduced space after each section
                  const SizedBox(height: 12),
                ],
              );
            }),

            // Extras
            if (_config!.extras.where((item) => item.visible && item.isActive).isNotEmpty) ...[
              _buildSectionHeader(context, 'More'),
              const SizedBox(height: 12),
              _buildIconGridFromConfig(context, _config!.extras.where((item) => item.visible && item.isActive).toList()),
            ],
          ],
        ),
      ),
      bottomNavigationBar: NavigationBar(
        height: 70,
        selectedIndex: _selectedBottomIndex,
        onDestinationSelected: (i) => setState(() => _selectedBottomIndex = i),
        elevation: 4,
        backgroundColor: Theme.of(context).colorScheme.surface,
        destinations: _config!.bottomNavigation.map((navItem) {
          return NavigationDestination(
            icon: Icon(_getIconData(navItem.icon)),
            selectedIcon: Icon(_getIconData(navItem.selectedIcon)),
            label: navItem.label,
          );
        }).toList(),
      ),
    );
  }

  Widget _buildBannerCarousel() {
    final visibleBanners = _config!.bannerList.banners.where((b) => b.visible).toList();
    if (visibleBanners.isEmpty) return const SizedBox.shrink();

    return Column(
      children: [
        SizedBox(
          height: 160,
          child: PageView.builder(
            controller: _bannerPageController,
            itemCount: visibleBanners.length,
            onPageChanged: (index) => setState(() => _currentBannerIndex = index),
            itemBuilder: (context, index) {
              final banner = visibleBanners[index];
              return Container(
                margin: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 8.0),
                decoration: BoxDecoration(
                  color: _parseColor(_config!.bannerList.bgColor),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [BoxShadow(color: Colors.black.withAlpha(12), blurRadius: 8, offset: const Offset(0, 4))],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: CachedNetworkImage(
                    imageUrl: banner.image,
                    fit: BoxFit.cover,
                    placeholder: (c, u) => Container(color: _parseColor(_config!.bannerList.bgColor), child: const Center(child: CircularProgressIndicator())),
                    errorWidget: (c, u, e) => Container(
                      color: _parseColor(_config!.bannerList.bgColor),
                      child: Center(child: Text(banner.title, style: const TextStyle(color: Colors.grey))),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(visibleBanners.length, (i) {
            final active = i == _currentBannerIndex;
            return AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              width: active ? 20 : 8,
              height: 8,
              margin: const EdgeInsets.symmetric(horizontal: 4),
              decoration: BoxDecoration(borderRadius: BorderRadius.circular(4), color: active ? Theme.of(context).colorScheme.primary : Colors.grey.withAlpha(120)),
            );
          }),
        ),
      ],
    );
  }

  Widget _buildProfileBadge(ThemeData theme, String text, Color bg, Color fg) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(color: bg.withValues(alpha: 0.3), borderRadius: BorderRadius.circular(8)),
      child: Text(text, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: fg)),
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title, {String? bgColor, String? levelColor}) {
    final colorScheme = Theme.of(context).colorScheme;
    final headerColor = levelColor != null ? _parseColor(levelColor) : colorScheme.primary;
    // Slightly tighter header padding to make sections more compact
    return Padding(
      padding: const EdgeInsets.only(top: 6, bottom: 4),
      child: Row(
        children: [
          Text(title.toUpperCase(), style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: headerColor, letterSpacing: 1.1)),
          const SizedBox(width: 12),
          Expanded(child: Container(height: 1, color: headerColor.withValues(alpha: 0.22))),
        ],
      ),
    );
  }

  Widget _buildIconGridFromConfig(BuildContext context, List<DashboardItem> items) {
    // Responsive grid with a capped tile width so cards don't become too wide.
    final screenWidth = MediaQuery.of(context).size.width;
    // Horizontal padding used by the surrounding ListView (left + right)
    const horizontalMargin = 16.0 * 2;
    // Slightly tighter spacing for a denser, professional layout
    const defaultSpacing = 8.0;
    // Preferred max tile width (try to keep tiles compact and evenly spaced)
    const preferredTileWidth = 120.0;
    final usableWidth = screenWidth - horizontalMargin;

    // Compute number of columns that fit the preferred width, at least 2
    int crossAxisCount = (usableWidth + defaultSpacing) ~/ (preferredTileWidth + defaultSpacing);
    if (crossAxisCount < 2) crossAxisCount = 2;
    if (crossAxisCount > 5) crossAxisCount = 5;

    // Calculate actual tile width after spacing
    final totalSpacing = defaultSpacing * (crossAxisCount - 1);
    final actualTileWidth = (usableWidth - totalSpacing) / crossAxisCount;
    // Tile height target for a pleasant aspect ratio (slightly shorter)
    const targetTileHeight = 120.0;
    final childAspectRatio = actualTileWidth / targetTileHeight;

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: items.length,
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        crossAxisSpacing: defaultSpacing,
        mainAxisSpacing: defaultSpacing,
        childAspectRatio: childAspectRatio,
      ),
      itemBuilder: (context, index) => _buildIconTileFromConfig(context, items[index]),
    );
  }

  Widget _buildIconTileFromConfig(BuildContext context, DashboardItem item) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final cardBgColor = _parseColor(item.bgCard);
    final titleColor = _parseColor(item.colorTitle);
    final iconBgColor = titleColor.withValues(alpha: 0.15);

    // Slightly tighter card styling
    final cardColor = cardBgColor == const Color(0xFFFFFFFF) ? Theme.of(context).cardColor : cardBgColor;
    final minTileHeight = 100.0; // slightly reduced for denser layout

    return Card(
      elevation: 1.5,
      color: cardColor,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () {
          final widget = _getRouteWidget(item.route, label: item.label);
          if (widget != null) Navigator.of(context).push(MaterialPageRoute(builder: (_) => widget));
        },
        child: ConstrainedBox(
          constraints: BoxConstraints(minHeight: minTileHeight),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundColor: iconBgColor,
                  child: Icon(_getIconData(item.icon), size: 20, color: titleColor),
                ),
                const SizedBox(height: 12),
                Text(
                  item.label,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: colorScheme.onSurface,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

