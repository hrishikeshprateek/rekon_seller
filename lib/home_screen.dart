import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:cached_network_image/cached_network_image.dart';
import 'package:provider/provider.dart';
import 'package:reckon_seller_2_0/pages/account_statement_wrapper.dart';
import 'package:reckon_seller_2_0/pages/outstanding_details_page.dart';
import 'package:reckon_seller_2_0/pages/account_outstanding_list_page.dart';
import 'package:reckon_seller_2_0/receipt_book.dart';
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
import 'pages/settings_page.dart';

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
      final dashboardService = Provider.of<api.DashboardService>(context, listen: false);
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

    final apiBanners = apiData.bannerList.banners ?? <dynamic>[];
    final banners = apiBanners.map((banner) {
      final apId = (banner is Map && banner.containsKey('Ap_Id')) ? banner['Ap_Id'] : (banner?.apId ?? 0);
      return BannerItem(
        id: apId is int ? apId : (int.tryParse(apId.toString()) ?? 0),
        image: 'https://via.placeholder.com/800x300?text=Banner+${apId}',
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
      'draftorder': const OrderEntryPage(), // Map to OrderEntryPage for now
      'orderbook': const OrderBookPage(),
      'orderstatus': const OrderStatusPage(),
      'receiptentry': const CreateReceiptScreen(),
      'receiptbook': const ReceiptBookPage(),
      'statement': const AccountStatementWrapper(),
      'receivables': const AccountOutstandingListPage(),
      'debtors': const OutstandingPage(),
      'creditors': const OutstandingPage(),
      'payables': const OutstandingPage(),
      'pendingdeliveries': const DeliveryBookPage(),
      'deliverystaus': const AccountOutstandingListPage(), // Assuming Delivery Status
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
      'deliverybook': const DeliveryBookPage(),
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

    final appBarBg = _parseColor(_config!.appBar?.bgColor ?? _config!.bgColor);
    final appBarText = _parseColor(_config!.appBar?.textColor ?? '#000000');

    return Scaffold(
      backgroundColor: _parseColor(_config!.bgColor),
      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) => [
          // --- PINNED SLIVER APP BAR ---
          SliverAppBar(
            pinned: true,
            floating: false,
            snap: false,
            elevation: 0,
            scrolledUnderElevation: 0,
            toolbarHeight: 70,
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                color: appBarBg,
              ),
            ),
            title: Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              child: Row(
                children: [
                  Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: colorScheme.shadow.withOpacity(0.08),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: CircleAvatar(
                      radius: 20,
                      backgroundColor: colorScheme.primaryContainer,
                      child: Icon(Icons.person, size: 22, color: colorScheme.onPrimaryContainer),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          _config!.appTitle,
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            color: appBarText,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Wrap(
                          spacing: 8,
                          runSpacing: 4,
                          children: [
                            _buildProfileBadge(theme, _config!.userInfo.loginLabel, colorScheme.secondaryContainer, colorScheme.onSecondaryContainer),
                            _buildProfileBadge(theme, _config!.userInfo.roleLabel, colorScheme.tertiaryContainer, colorScheme.onTertiaryContainer),
                          ],
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
                  icon: const Icon(Icons.search),
                  color: colorScheme.onSurfaceVariant,
                  tooltip: 'Search',
                ),
              Consumer<AuthService>(
                builder: (context, authService, child) {
                  final user = authService.currentUser;
                  return PopupMenuButton(
                    icon: Icon(Icons.more_vert, color: colorScheme.onSurfaceVariant),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    offset: const Offset(0, 50),
                    itemBuilder: (context) => [
                      if (user != null)
                        PopupMenuItem(
                          enabled: false,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                user.fullName.isNotEmpty ? user.fullName : 'User',
                                style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(height: 4),
                              Text(user.mobileNumber, style: theme.textTheme.bodySmall),
                              Text('License: ${user.licenseNumber}', style: theme.textTheme.bodySmall),
                              const Divider(height: 16),
                            ],
                          ),
                        ),
                      PopupMenuItem(
                        onTap: () => _handleLogout(context, authService),
                        child: Row(
                          children: [
                            Icon(Icons.logout, size: 18, color: Colors.grey.shade700),
                            const SizedBox(width: 12),
                            Text('Logout', style: TextStyle(color: Colors.grey.shade700, fontWeight: FontWeight.w600)),
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
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const SettingsPage())),
        icon: const Icon(Icons.settings),
        label: const Text('Settings'),
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
          height: 150,
          child: PageView.builder(
            controller: _bannerPageController,
            itemCount: visibleBanners.length,
            onPageChanged: (index) => setState(() => _currentBannerIndex = index),
            itemBuilder: (context, index) {
              final banner = visibleBanners[index];
              return Container(
                margin: const EdgeInsets.symmetric(horizontal: 4.0, vertical: 4.0),
                decoration: BoxDecoration(
                  color: _parseColor(_config!.bannerList.bgColor),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Theme.of(context).colorScheme.shadow.withOpacity(0.06),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    )
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: CachedNetworkImage(
                    imageUrl: banner.image,
                    fit: BoxFit.cover,
                    placeholder: (c, u) => Container(color: Theme.of(context).colorScheme.surfaceContainerHighest, child: const Center(child: CircularProgressIndicator())),
                    errorWidget: (c, u, e) => Container(
                      color: Theme.of(context).colorScheme.surfaceContainerHighest,
                      child: Center(child: Icon(Icons.broken_image_outlined, color: Theme.of(context).colorScheme.outline)),
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
              width: active ? 24 : 8,
              height: 6,
              margin: const EdgeInsets.symmetric(horizontal: 3),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(3),
                color: active ? Theme.of(context).colorScheme.primary : Theme.of(context).colorScheme.surfaceContainerHighest,
              ),
            );
          }),
        ),
        const SizedBox(height: 8),
      ],
    );
  }

  Widget _buildProfileBadge(ThemeData theme, String text, Color bg, Color fg) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: bg.withOpacity(0.5),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: bg.withOpacity(0.8), width: 0.5),
      ),
      child: Text(
        text,
        style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: fg),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title, {String? bgColor, String? levelColor}) {
    final colorScheme = Theme.of(context).colorScheme;
    final headerColor = levelColor != null ? _parseColor(levelColor) : colorScheme.primary;
    return Padding(
      padding: const EdgeInsets.only(top: 12, bottom: 8),
      child: Row(
        children: [
          // Restored horizontal line
          Container(width: 3, height: 14, decoration: BoxDecoration(color: headerColor, borderRadius: BorderRadius.circular(2))),
          const SizedBox(width: 8),
          Text(
            title.toUpperCase(),
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: headerColor,
              letterSpacing: 0.8,
            ),
          ),
          const SizedBox(width: 12),
          // Expanded Title Line (Overflow Safe)
          Expanded(
            child: Container(
              height: 1,
              color: headerColor.withOpacity(0.15),
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
    final titleColor = _parseColor(item.colorTitle);

    final cardColor = cardBgColor == const Color(0xFFFFFFFF)
        ? colorScheme.surfaceContainerLow
        : cardBgColor;

    return Material(
      color: cardColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: colorScheme.outlineVariant.withOpacity(0.4), width: 1),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () {
          final widget = _getRouteWidget(item.route, label: item.label);
          if (widget != null) Navigator.of(context).push(MaterialPageRoute(builder: (_) => widget));
        },
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: titleColor.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(_getIconData(item.icon), size: 22, color: titleColor),
              ),
              const SizedBox(height: 8),
              Text(
                item.label,
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: colorScheme.onSurface,
                  height: 1.1,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

