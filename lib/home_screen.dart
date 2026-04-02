import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:cached_network_image/cached_network_image.dart';
import 'package:provider/provider.dart';
import 'package:reckon_seller_2_0/pages/account_statement_wrapper.dart';
import 'package:reckon_seller_2_0/pages/cart_page.dart';
import 'package:reckon_seller_2_0/pages/completed_deliveries_page.dart';
import 'package:reckon_seller_2_0/pages/account_outstanding_list_page.dart';
import 'package:reckon_seller_2_0/receipt_book.dart';
import 'dart:async';

import 'auth_service.dart';
import 'dashboard_service.dart' as api;
import 'services/salesman_flags_service.dart';
import 'login_screen.dart';
import 'receipt_entry.dart';
import 'pages/order_entry_page.dart';
import 'pages/my_cart_page.dart';
import 'pages/order_book_page.dart';
import 'pages/order_status_page.dart';
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
import 'pages/settings_page.dart';
import 'pages/do_account_selector_page.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
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
      final dashboardService = Provider.of<api.DashboardService>(context, listen: false);
      final authService = Provider.of<AuthService>(context, listen: false);

      // Reload salesman flags when dashboard opens
      debugPrint('[HomeScreen] Reloading salesman flags...');
      final flagsService = Provider.of<SalesmanFlagsService>(context, listen: false);
      final flagsSuccess = await flagsService.fetchAndCacheSalesmanFlags(
        authService: authService,
        packageName: authService.packageNameHeader,
      );

      if (flagsSuccess) {
        debugPrint('[HomeScreen] ✅ Salesman flags reloaded successfully');
      } else {
        debugPrint('[HomeScreen] ⚠️ Failed to reload salesman flags: ${flagsService.error}');
      }

      final response = await dashboardService.getDashboard();

      if (response.success && response.data != null) {
        if (mounted) {
          setState(() {
            _config = _convertApiDataToConfig(response.data!);
            _isLoading = false;
          });
          if (_config?.bannerList.visible ?? false) {
            _startBannerAutoPlay();
          }
        }
      } else {
        await _loadLocalConfig();
      }
    } catch (e) {
      debugPrint('Error loading dashboard from API: $e');
      await _loadLocalConfig();
    }
  }

  Future<void> _loadLocalConfig() async {
    try {
      final String jsonString = await rootBundle.loadString('assets/config/dashboard_config.json');
      if (mounted) {
        setState(() {
          _config = DashboardConfig.fromJsonString(jsonString);
          _isLoading = false;
        });
        if (_config?.bannerList.visible ?? false) {
          _startBannerAutoPlay();
        }
      }
    } catch (e) {
      debugPrint('Error loading local config: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  DashboardConfig _convertApiDataToConfig(api.DashboardData apiData) {
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

    // Map API banners (from dashboard_service) to config banners (dashboard_config_model)
    final banners = apiData.bannerList.banners.map((banner) {
      return BannerItem(
        id: banner.apId,
        image: 'https://via.placeholder.com/800x300?text=Banner+${banner.apId}',
        title: 'Banner ${banner.apId}',
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
      'prem_identity': Icons.perm_identity,
      'view_list': Icons.view_list,
      'autorenew': Icons.autorenew,
      'error_outline': Icons.error_outline,
      'checklist': Icons.checklist,
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

    final suffixes = ['_outlined', '_rounded', '_sharp', '_filled'];
    for (final c in List<String>.from(candidates)) {
      for (final suf in suffixes) {
        candidates.add('${c}$suf');
      }
    }

    for (final k in candidates) {
      if (k.isEmpty) continue;
      if (iconMap.containsKey(k)) return iconMap[k]!;
    }

    for (final entry in iconMap.entries) {
      final ekey = entry.key.replaceAll('_', '');
      if (noUnderscore.isNotEmpty && ekey == noUnderscore) return entry.value;
      if (ekey.contains(noUnderscore) || noUnderscore.contains(ekey)) return entry.value;
    }

    return Icons.help_outline;
  }

  Widget? _getRouteWidget(String? routeName, {String? label}) {
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
      'orderentry': const OrderEntryPage(),
      'draftorder': DraftOrderHandler(), // Updated to handle account selection and cart opening
      'orderbook': const OrderBookPage(),
      'orderstatus': const OrderStatusPage(),
      'receiptentry': const CreateReceiptScreen(),
      'receiptbook': const ReceiptBookPage(),
      'statement': const AccountStatementWrapper(),
      'receivables': const AccountOutstandingListPage(),
      'debtors': const OutstandingPage(),
      'creditors': const OutstandingPage(),
      'payables': const OutstandingPage(),
      'assigneddelivery': const DeliveryBookPage(), // Assigned Delivery -> DeliveryBookPage
      'pendingdeliveries': const DeliveryBookPage(),
      'deliverybook': const CompletedDeliveriesPage(), // Delivery Book -> CompletedDeliveriesPage
      'deliverystaus': const CompletedDeliveriesPage(), // Completed Deliveries
      'deliveryperformance': const DeliveryCollectionPage(),
      'deliveryreport': const DeliveryCollectionPage(),
      'pobook': const POBookPage(),
      'stocksales': const StockSalesPage(),
      'nearexpirystock': const NearExpiryPage(),
      'stocknotsold': const ShortagePage(),
      'dumpstock': const DumpStockPage(),
      'salesummary': const ItemwiseSalePage(),
      'partywisesale': const PartywiseSalePage(),
      'productwisesale': const ItemwiseSalePage(),
      'newlyreceived': const NotificationPage(),
      'profitoverview': const TrialBalancePage(),
      'storewisegp': const TrialBalancePage(),
      'lrupdateentry': const DeliveryCollectionPage(),
      'markasdelivered': const DeliveryCollectionPage(),
      'transportreport': const DeliveryCollectionPage(),
      // Existing mappings
      'mycart': const MyCartPage(),
      'outstanding': const OutstandingPage(),
      'trialbalance': const TrialBalancePage(),
      'bank': const BankPage(),
      'deliverycollection': const DeliveryCollectionPage(),
      'closingstock': const ClosingStockPage(),
      'shortage': const ShortagePage(),
      'itemwisesale': const ItemwiseSalePage(),
      'notification': const NotificationPage(),
      'referandearn': const ReferAndEarnPage(),
      'contactsupport': const ContactSupportPage(),

      // Add new routes here, e.g.:
      // 'newpage': const NewPage(),
    };

    if (normalizedRoute.isNotEmpty && routeMap.containsKey(normalizedRoute)) return routeMap[normalizedRoute];
    if (normalizedLabel.isNotEmpty && routeMap.containsKey(normalizedLabel)) return routeMap[normalizedLabel];

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
              backgroundColor: Colors.grey.shade700,
            ),
            child: const Text('Logout'),
          ),
        ],
      ),
    );

    if (shouldLogout == true) {
      if (!mounted) return;
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: CircularProgressIndicator(),
        ),
      );

      await authService.logout();

      if (!mounted) return;
      Navigator.pop(context);
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
      backgroundColor: const Color(0xFFF8F9FA),
      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) => [
          // --- MATERIAL DESIGN SLIVER APP BAR WITH APP LOGO ---
          SliverAppBar(
            pinned: true,
            floating: false,
            snap: false,
            elevation: 0,
            scrolledUnderElevation: 1,
            toolbarHeight: 70,
            backgroundColor: Colors.white,
            foregroundColor: Colors.black,
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                color: Colors.white,
                child: Align(
                  alignment: Alignment.bottomCenter,
                  child: Container(
                    height: 1,
                    color: Colors.grey.shade200,
                  ),
                ),
              ),
            ),
            title: Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              child: Row(
                children: [
                  // Reckon Logo
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(10),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.08),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: Image.asset(
                        'assets/images/reckon.png',
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            color: const Color(0xFF1E88E5),
                            child: const Icon(
                              Icons.business_rounded,
                              size: 22,
                              color: Colors.white,
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  // App Title and User Info
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          _config!.appTitle,
                          style: const TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF212121),
                            letterSpacing: 0.2,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${_config!.userInfo.loginLabel} • ${_config!.userInfo.roleLabel}',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w500,
                            color: Colors.grey.shade700,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              if (_config!.appBar?.showSearch ?? true)
                IconButton(
                  onPressed: _openSpotlightSearch,
                  icon: const Icon(Icons.search_rounded),
                  color: Colors.black87,
                  tooltip: 'Search',
                  splashRadius: 24,
                ),
              Consumer<AuthService>(
                builder: (context, authService, child) {
                  final user = authService.currentUser;
                  return PopupMenuButton(
                    icon: const Icon(Icons.more_vert_rounded, color: Colors.black87),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    color: Colors.white,
                    elevation: 2,
                    offset: const Offset(0, 50),
                    itemBuilder: (context) => [
                      if (user != null)
                        PopupMenuItem(
                          enabled: false,
                          child: Container(
                            padding: const EdgeInsets.only(bottom: 12),
                            decoration: BoxDecoration(
                              border: Border(
                                bottom: BorderSide(
                                  color: Colors.grey.shade200,
                                  width: 1,
                                ),
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  user.fullName.isNotEmpty ? user.fullName : 'User',
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w700,
                                    color: Color(0xFF212121),
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  user.mobileNumber,
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                    color: Colors.grey.shade700,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'License: ${user.licenseNumber}',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w400,
                                    color: Colors.grey.shade600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      PopupMenuItem(
                        onTap: () => _handleLogout(context, authService),
                        child: Row(
                          children: [
                            const Icon(Icons.logout_rounded, size: 18, color: Colors.redAccent),
                            const SizedBox(width: 12),
                            const Text(
                              'Logout',
                              style: TextStyle(
                                color: Colors.redAccent,
                                fontWeight: FontWeight.w600,
                                fontSize: 13,
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
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 100),
          children: [
            if (_config!.bannerList.visible && _config!.bannerList.banners.where((b) => b.visible).isNotEmpty)
              _buildBannerCarousel(),

            ..._config!.sections.where((s) => s.visible).map((section) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSectionHeader(context, section.title, bgColor: section.bgColor, levelColor: section.levelColor),
                  _buildIconGridFromConfig(context, section.items.where((item) => item.visible).toList()),
                  const SizedBox(height: 12),
                ],
              );
            }),

            if (_config!.extras.where((item) => item.visible && item.isActive).isNotEmpty) ...[
              _buildSectionHeader(context, 'More'),
              _buildIconGridFromConfig(context, _config!.extras.where((item) => item.visible && item.isActive).toList()),
            ],
          ],
        ),
      ),
      floatingActionButton: Container(
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF1E88E5),
              Color(0xFF1565C0),
            ],
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF1E88E5).withValues(alpha: 0.4),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: FloatingActionButton.extended(
          onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const SettingsPage())),
          backgroundColor: Colors.transparent,
          elevation: 0,
          icon: const Icon(Icons.settings, color: Colors.white),
          label: const Text(
            'Settings',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.5,
            ),
          ),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
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
                margin: const EdgeInsets.symmetric(horizontal: 6.0, vertical: 8.0),
                decoration: BoxDecoration(
                  color: _parseColor(_config!.bannerList.bgColor),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF1E88E5).withValues(alpha: 0.12),
                      blurRadius: 16,
                      offset: const Offset(0, 6),
                    ),
                    BoxShadow(
                      color: const Color(0xFFFF6F00).withValues(alpha: 0.08),
                      blurRadius: 12,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: Stack(
                    children: [
                      CachedNetworkImage(
                        imageUrl: banner.image,
                        fit: BoxFit.cover,
                        width: double.infinity,
                        height: double.infinity,
                        placeholder: (c, u) => Container(
                          color: Theme.of(context).colorScheme.surfaceContainerHighest,
                          child: const Center(child: CircularProgressIndicator()),
                        ),
                        errorWidget: (c, u, e) => Container(
                          color: Theme.of(context).colorScheme.surfaceContainerHighest,
                          child: Center(
                            child: Icon(
                              Icons.broken_image_outlined,
                              color: Theme.of(context).colorScheme.outline,
                            ),
                          ),
                        ),
                      ),
                      // Overlay gradient for better text readability
                      Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.bottomCenter,
                            end: Alignment.topCenter,
                            colors: [
                              Colors.black.withValues(alpha: 0.2),
                              Colors.transparent,
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 12),
        // Enhanced indicator dots
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(visibleBanners.length, (i) {
            final active = i == _currentBannerIndex;
            return AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              width: active ? 28 : 8,
              height: 8,
              margin: const EdgeInsets.symmetric(horizontal: 4),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(4),
                color: active
                    ? const Color(0xFF1E88E5)
                    : const Color(0xFF1E88E5).withValues(alpha: 0.3),
                boxShadow: active
                    ? [
                        BoxShadow(
                          color: const Color(0xFF1E88E5).withValues(alpha: 0.4),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ]
                    : [],
              ),
            );
          }),
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title, {String? bgColor, String? levelColor}) {
    // Default to blue for primary sections, orange for secondary
    Color headerColor;
    if (levelColor != null) {
      headerColor = _parseColor(levelColor);
    } else {
      // Alternate between blue and orange for visual interest
      headerColor = const Color(0xFF1E88E5); // Default blue
    }

    return Padding(
      padding: const EdgeInsets.only(top: 16, bottom: 12),
      child: Row(
        children: [
          // Colored accent bar
          Container(
            width: 4,
            height: 18,
            decoration: BoxDecoration(
              color: headerColor,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 12),
          Text(
            title.toUpperCase(),
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w800,
              color: headerColor,
              letterSpacing: 1.0,
            ),
          ),
          const SizedBox(width: 12),
          // Expanded decorative line
          Expanded(
            child: Container(
              height: 1.5,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                  colors: [
                    headerColor.withValues(alpha: 0.3),
                    headerColor.withValues(alpha: 0.05),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildIconGridFromConfig(BuildContext context, List<DashboardItem> items) {
    final screenWidth = MediaQuery.of(context).size.width;
    const horizontalMargin = 16.0 * 2;
    const defaultSpacing = 12.0;
    const preferredTileWidth = 100.0;
    final usableWidth = screenWidth - horizontalMargin;

    int crossAxisCount = (usableWidth + defaultSpacing) ~/ (preferredTileWidth + defaultSpacing);
    if (crossAxisCount < 3) crossAxisCount = 3;
    if (crossAxisCount > 5) crossAxisCount = 5;

    final totalSpacing = defaultSpacing * (crossAxisCount - 1);
    final actualTileWidth = (usableWidth - totalSpacing) / crossAxisCount;

    const targetTileHeight = 110.0;
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

    // Modern color palette - alternate between blue and orange accents
    final accentColor = item.label.length % 2 == 0 ? const Color(0xFF1E88E5) : const Color(0xFFFF6F00);

    // Determine card background - use subtle gradient if white
    final cardColor = cardBgColor == const Color(0xFFFFFFFF)
        ? const Color(0xFFFAFBFC)
        : cardBgColor;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () {
          final widget = _getRouteWidget(item.route, label: item.label);
          if (widget != null) Navigator.of(context).push(MaterialPageRoute(builder: (_) => widget));
        },
        child: Container(
          decoration: BoxDecoration(
            color: cardColor,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: accentColor.withValues(alpha: 0.15),
              width: 1.2,
            ),
            boxShadow: [
              BoxShadow(
                color: accentColor.withValues(alpha: 0.08),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(12.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Icon container with gradient background
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        accentColor.withValues(alpha: 0.15),
                        accentColor.withValues(alpha: 0.05),
                      ],
                    ),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    _getIconData(item.icon),
                    size: 24,
                    color: accentColor,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  item.label,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: colorScheme.onSurface,
                    height: 1.2,
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

class DraftOrderHandler extends StatefulWidget {
  const DraftOrderHandler({Key? key}) : super(key: key);

  @override
  State<DraftOrderHandler> createState() => _DraftOrderHandlerState();
}

class _DraftOrderHandlerState extends State<DraftOrderHandler> {
  @override
  void initState() {
    super.initState();
    // Open account selector immediately after first frame
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await _handleAccountSelection(context);
    });
  }

  @override
  Widget build(BuildContext context) {
    // Show loading while account selection is happening
    return Scaffold(
      appBar: AppBar(
        title: const Text('Draft Order Handler'),
      ),
      body: const Center(child: CircularProgressIndicator()),
    );
  }

  Future<void> _handleAccountSelection(BuildContext context) async {
    debugPrint('[DraftOrderHandler] ===== ACCOUNT SELECTION STARTED =====');
    debugPrint('[DraftOrderHandler] Opening DoAccountSelectorPage');
    final selectedAccount = await DoAccountSelectorPage.show(
      context,
      fromDo: 1,
    );

    debugPrint('[DraftOrderHandler] Selected Account Details:');
    if (selectedAccount != null) {
      debugPrint('[DraftOrderHandler]   - Name: ${selectedAccount.name}');
      debugPrint('[DraftOrderHandler]   - ID: ${selectedAccount.id}');
      debugPrint('[DraftOrderHandler]   - Code: ${selectedAccount.code}');
      debugPrint('[DraftOrderHandler]   - Phone: ${selectedAccount.phone}');
      debugPrint('[DraftOrderHandler]   - Address: ${selectedAccount.address}');
      debugPrint('[DraftOrderHandler]   - Type: ${selectedAccount.type}');
    } else {
      debugPrint('[DraftOrderHandler]   - No account selected (null)');
    }

    if (!mounted) {
      debugPrint('[DraftOrderHandler] Widget not mounted, cannot proceed');
      return;
    }

    if (selectedAccount != null) {
      final acCode = selectedAccount.code ?? selectedAccount.id;
      debugPrint('[DraftOrderHandler] Navigating to CartPage with acCode: $acCode');

      // Use Navigator.pushReplacement to replace DraftOrderHandler with CartPage
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (context) {
            debugPrint('[DraftOrderHandler] Building CartPage for account: $acCode');
            return CartPage(
              acCode: acCode,
              selectedAccount: selectedAccount,
            );
          },
        ),
      );
      debugPrint('[DraftOrderHandler] ===== ACCOUNT SELECTION COMPLETED =====');
    } else {
      debugPrint('[DraftOrderHandler] No account selected, popping to home');
      // Pop back to home if no account was selected
      Navigator.of(context).pop();
      debugPrint('[DraftOrderHandler] ===== ACCOUNT SELECTION CANCELLED =====');
    }
  }
}

class DraftOrder {
  final String name;
  final String details;
  final String accountId;

  DraftOrder({required this.name, required this.details, required this.accountId});
}
