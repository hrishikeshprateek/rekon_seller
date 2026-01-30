import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:geolocator/geolocator.dart';
import 'package:dio/dio.dart';
import 'dart:convert';
import 'dart:async';
import 'package:provider/provider.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart'; // Ensure share_plus is in pubspec.yaml
import '../models/account_model.dart';
import '../auth_service.dart';
import 'location_picker_sheet.dart';
import 'account_filter_page.dart';

class SelectAccountPage extends StatefulWidget {
  final String title;
  final String? accountType;
  final bool showBalance;
  final Account? selectedAccount;
  final Function(Account)? onAccountSelected;

  const SelectAccountPage({
    super.key,
    this.title = 'Select Account',
    this.accountType,
    this.showBalance = true,
    this.selectedAccount,
    this.onAccountSelected,
  });

  static Future<Account?> show(
      BuildContext context, {
        String title = 'Select Account',
        String? accountType,
        bool showBalance = true,
        Account? selectedAccount,
      }) async {
    return Navigator.of(context).push<Account>(
      MaterialPageRoute(
        builder: (_) => SelectAccountPage(
          title: title,
          accountType: accountType,
          showBalance: showBalance,
          selectedAccount: selectedAccount,
        ),
      ),
    );
  }

  @override
  State<SelectAccountPage> createState() => _SelectAccountPageState();
}

class _SelectAccountPageState extends State<SelectAccountPage> {
  final TextEditingController _searchController = TextEditingController();
  List<Account> _allAccounts = [];
  List<Account> _filteredAccounts = [];
  bool _isLoading = true;
  int _pageNo = 1;
  final int _pageSize = 20;
  bool _hasMore = true;
  bool _isLoadingMore = false;
  late ScrollController _scrollController;
  String _searchQuery = '';
  Timer? _searchDebounce;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController()..addListener(_onScroll);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadAccounts(reset: true);
    });
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadAccounts({bool reset = false}) async {
    if (!mounted) return;

    if (reset) {
      _pageNo = 1;
      _hasMore = true;
    }
    if (!reset && !_hasMore) return;

    if (mounted) {
      if (reset) {
        setState(() {
          _isLoading = true;
          _isLoadingMore = false;
        });
      } else {
        setState(() {
          _isLoadingMore = true;
        });
      }
    }

    try {
      final auth = Provider.of<AuthService>(context, listen: false);
      if (auth.currentUser == null) throw 'User not logged in';

      Position? position;
      try {
        var permission = await Geolocator.checkPermission();
        if (permission == LocationPermission.denied) {
          permission = await Geolocator.requestPermission();
        }
        if (permission == LocationPermission.whileInUse || permission == LocationPermission.always) {
          position = await Geolocator.getCurrentPosition(
            desiredAccuracy: LocationAccuracy.high,
            timeLimit: const Duration(seconds: 10),
          );
        }
      } catch (e) {
        debugPrint('Location error: $e');
      }

      String mobile = auth.currentUser!.mobileNumber.replaceAll(RegExp(r'[^0-9]'), '');
      if (mobile.length > 10) mobile = mobile.substring(mobile.length - 10);

      final payload = {
        'lApkName': 'com.reckon.reckonbiz',
        'lLicNo': auth.currentUser!.licenseNumber,
        'lUserId': mobile,
        'lPageNo': _pageNo.toString(),
        'lSize': _pageSize.toString(),
        'lSearchFieldValue': _searchQuery,
        'lExecuteTotalRows': '1',
        'lMr': '',
        'lArea': '',
        'lCUID': auth.currentUser!.userId,
        'ltype': '0',
        'device_id': auth.deviceId,
        'device_name': auth.deviceName,
        'v_code': 31,
        'version_name': '1.7.23',
        'app_role': 'SalesMan',
        'cu_id': auth.currentUser!.userId,
        'latitude': position?.latitude.toString() ?? '',
        'longitude': position?.longitude.toString() ?? '',
      };

      final dio = Dio(BaseOptions(baseUrl: AuthService.baseUrl, connectTimeout: const Duration(seconds: 30), receiveTimeout: const Duration(seconds: 30)));
      final response = await dio.post(
        '/GetAccount',
        data: payload,
        options: Options(
          headers: {
            'Content-Type': 'application/json',
            'package_name': auth.packageNameHeader,
            if (auth.getAuthHeader() != null) 'Authorization': auth.getAuthHeader(),
          },
        ),
      );

      dynamic raw = response.data;
      Map<String, dynamic> data;
      if (raw is Map<String, dynamic>) {
        data = raw;
      } else if (raw is String) {
        try {
          final decoded = jsonDecode(raw);
          data = decoded is Map<String, dynamic> ? decoded : {'Message': raw};
        } catch (_) {
          data = {'Message': raw};
        }
      } else {
        data = {'Message': 'Unknown response format'};
      }

      final accountsData = data['Account'] as List<dynamic>?;

      final List<Account> fetched = accountsData != null
          ? accountsData.map((json) => Account.fromApiJson(json as Map<String, dynamic>)).toList()
          : [];

      if (!mounted) return;

      if (reset) {
        _allAccounts = fetched;
      } else {
        _allAccounts.addAll(fetched);
      }

      _hasMore = fetched.length >= _pageSize;
      _filteredAccounts = List<Account>.from(_allAccounts);
      if (fetched.isNotEmpty) _pageNo += 1;

    } catch (e) {
      debugPrint('Error loading accounts: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to load accounts: $e'), backgroundColor: Colors.red));
      }
      if (reset) {
        _allAccounts = [];
        _filteredAccounts = [];
        _hasMore = false;
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _isLoadingMore = false;
        });
      }
    }
  }

  void _performSearch(String query) {
    _searchDebounce?.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 250), () {
      _searchQuery = query.trim();
      _loadAccounts(reset: true);
    });
  }

  void _onScroll() {
    if (!_scrollController.hasClients || _isLoading || _isLoadingMore || !_hasMore) return;
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 200) {
      _loadAccounts(reset: false);
    }
  }

  void _selectAccount(Account account) {
    if (widget.onAccountSelected != null) {
      // If callback is provided, use it (keeps SelectAccountPage in stack)
      widget.onAccountSelected!(account);
    } else {
      // Otherwise, pop with result (normal behavior)
      Navigator.of(context).pop(account);
    }
  }

  void _showLocationPicker(BuildContext context, Account account) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => LocationPickerSheet(
        account: account,
        onLocationAdded: (updatedAccount) {
          // Update the account in the list
          final index = _allAccounts.indexWhere((a) => a.id == updatedAccount.id);
          if (index != -1) {
            _allAccounts[index] = updatedAccount;
            _filteredAccounts = List<Account>.from(_allAccounts);
            setState(() {});
          }
        },
      ),
    );
  }

  Future<void> _openMapsNavigation(Account account) async {
    if (account.latitude == null || account.longitude == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Location not available'), backgroundColor: Colors.orange));
      return;
    }
    final lat = account.latitude!;
    final lng = account.longitude!;
    final googleMapsUrl = Uri.parse('google.navigation:q=$lat,$lng&mode=d');
    final webMapsUrl = Uri.parse('https://www.google.com/maps/dir/?api=1&destination=$lat,$lng');

    try {
      if (await canLaunchUrl(googleMapsUrl)) {
        await launchUrl(googleMapsUrl, mode: LaunchMode.externalApplication);
      } else if (await canLaunchUrl(webMapsUrl)) {
        await launchUrl(webMapsUrl, mode: LaunchMode.externalApplication);
      } else {
        throw 'Could not open maps';
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red));
    }
  }

  void _showMapDialog(Account account) {
    if (account.latitude == null || account.longitude == null) return;

    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(20),
        child: Container(
          constraints: const BoxConstraints(maxWidth: 500),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primaryContainer,
                  borderRadius: const BorderRadius.only(topLeft: Radius.circular(16), topRight: Radius.circular(16)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        account.name,
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(ctx),
                    ),
                  ],
                ),
              ),
              ClipRRect(
                child: SizedBox(
                  height: 350,
                  child: FlutterMap(
                    options: MapOptions(
                      initialCenter: LatLng(account.latitude!, account.longitude!),
                      initialZoom: 15.0,
                    ),
                    children: [
                      TileLayer(
                        urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                        userAgentPackageName: 'com.reckon.reckonbiz',
                      ),
                      MarkerLayer(
                        markers: [
                          Marker(
                            point: LatLng(account.latitude!, account.longitude!),
                            width: 80,
                            height: 80,
                            child: Icon(Icons.location_on, color: Colors.red, size: 40),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: FilledButton.icon(
                    onPressed: () {
                      Navigator.pop(ctx);
                      _openMapsNavigation(account);
                    },
                    icon: const Icon(Icons.navigation),
                    label: const Text('Start Navigation'),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Helper to format share text
  String _formatAccountShareText(Account account) {
    final lines = <String>[];
    lines.add('Firm Name: ${account.name}');

    final address = (account.address ?? '').trim();
    if (address.isNotEmpty) lines.add('Address: $address');

    final pincode = (account.pincode ?? '').trim();
    if (pincode.isNotEmpty) lines.add('Pincode: $pincode');

    final phone = (account.phone ?? '').trim();
    if (phone.isNotEmpty) lines.add('Mobile: $phone');

    final email = (account.email ?? '').trim();
    if (email.isNotEmpty) lines.add('Email id: $email');

    if (account.latitude != null && account.longitude != null) {
      lines.add('Map Location: https://www.google.com/maps/search/?api=1&query=${account.latitude},${account.longitude}');
    }

    return lines.join('\n');
  }

  // --- UI IMPLEMENTATION ---

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: const Color(0xFFF2F4F7),
      appBar: AppBar(
        title: Text(widget.title, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 18)),
        centerTitle: true,
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black87),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.black87),
            onPressed: () => _loadAccounts(reset: true),
          ),
          IconButton(
            icon: const Icon(Icons.filter_list, color: Colors.black87),
            onPressed: () async {
              // open filter page and wait for result
              final result = await Navigator.of(context).push<Map<String, dynamic>>(MaterialPageRoute(builder: (_) => const AccountFilterPage()));
              if (result != null) {
                // apply filters by setting search or triggering reload as needed
                debugPrint('Filters applied: $result');
                // TODO: map selected filters to request payload fields (e.g., lArea, lStation, lRoute)
                // For now we simply reload accounts
                _loadAccounts(reset: true);
              }
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Container(
            color: Colors.white,
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            child: Column(
              children: [
                TextField(
                  controller: _searchController,
                  onChanged: (value) {
                    setState(() {});
                    _performSearch(value);
                  },
                  decoration: InputDecoration(
                    hintText: 'Search Account / ID...',
                    prefixIcon: const Icon(Icons.search, color: Colors.grey),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                      icon: const Icon(Icons.clear, color: Colors.grey),
                      onPressed: () {
                        setState(() { _searchController.clear(); });
                        _performSearch('');
                      },
                    )
                        : null,
                    filled: true,
                    fillColor: const Color(0xFFF1F3F4),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                  ),
                ),
                if (widget.accountType == null) ...[
                  const SizedBox(height: 12),
                  SizedBox(
                    height: 36,
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      children: [
                        _buildFilterChip('All', null),
                        const SizedBox(width: 8),
                        _buildFilterChip('Parties', 'Party'),
                        const SizedBox(width: 8),
                        _buildFilterChip('Banks', 'Bank'),
                        const SizedBox(width: 8),
                        _buildFilterChip('Cash', 'Cash'),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
          Expanded(
            child: _isLoading
                ? Center(child: CircularProgressIndicator(color: colorScheme.primary))
                : _filteredAccounts.isEmpty
                ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.search_off, size: 64, color: Colors.grey[300]),
                  const SizedBox(height: 16),
                  const Text('No accounts found', style: TextStyle(color: Colors.grey)),
                ],
              ),
            )
                : RefreshIndicator(
              onRefresh: () async => await _loadAccounts(reset: true),
              child: ListView.separated(
                controller: _scrollController,
                padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                separatorBuilder: (_, __) => const SizedBox(height: 8),
                itemCount: _filteredAccounts.length + (_isLoadingMore ? 1 : 0),
                itemBuilder: (context, index) {
                  if (index >= _filteredAccounts.length) {
                    return Padding(
                      padding: const EdgeInsets.all(16),
                      child: Center(child: _isLoadingMore ? const CircularProgressIndicator(strokeWidth: 2) : const SizedBox.shrink()),
                    );
                  }
                  return _buildProfessionalCard(context, _filteredAccounts[index]);
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, String? type) {
    final isSelected = widget.accountType == type;
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (_) {},
      showCheckmark: false,
      labelStyle: TextStyle(
        fontSize: 13,
        fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
        color: isSelected ? Colors.white : Colors.black87,
      ),
      backgroundColor: Colors.white,
      selectedColor: Colors.black87,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: isSelected ? Colors.transparent : Colors.grey.shade300),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 4),
    );
  }

  Widget _buildProfessionalCard(BuildContext context, Account account) {
    final isSelected = widget.selectedAccount?.id == account.id;
    final hasLocation = (account.latitude != null && account.longitude != null && account.latitude != 0 && account.longitude != 0);
    final displayBalance = account.closBal ?? account.balance ?? 0.0;
    final isNegative = displayBalance < 0;

    return Card(
      elevation: 0,
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: isSelected ? Theme.of(context).primaryColor : const Color(0xFFE0E0E0), width: isSelected ? 2 : 1),
      ),
      child: InkWell(
        onTap: () => _selectAccount(account),
        borderRadius: BorderRadius.circular(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  CircleAvatar(
                    radius: 20,
                    backgroundColor: _getTypeColor(account.type).withOpacity(0.1),
                    child: Text(
                      account.name.isNotEmpty ? account.name[0].toUpperCase() : '?',
                      style: TextStyle(fontWeight: FontWeight.bold, color: _getTypeColor(account.type)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          account.name,
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF202124)),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(color: Colors.grey[100], borderRadius: BorderRadius.circular(4)),
                              child: Text(account.type.toUpperCase(), style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey)),
                            ),
                            const SizedBox(width: 8),
                            Text('ID: ${account.id}', style: const TextStyle(fontSize: 12, color: Colors.grey)),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const Divider(height: 1, indent: 16, endIndent: 16, color: Color(0xFFEEEEEE)),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(
                    child: account.phone != null
                        ? Row(
                      children: [
                        const Icon(Icons.phone_iphone, size: 18, color: Colors.black54),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            account.phone!,
                            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: Color(0xFF333333)),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    )
                        : const Text("No Phone", style: TextStyle(fontSize: 14, color: Colors.grey)),
                  ),
                  if (widget.showBalance)
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          '₹${displayBalance.abs().toStringAsFixed(0)}',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: isNegative ? Colors.red[700] : Colors.green[700]),
                        ),
                        Text(
                          'Balance',
                          style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: isNegative ? Colors.red[700] : Colors.green[700]),
                        ),
                      ],
                    ),
                ],
              ),
            ),
            if (account.address != null)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Padding(padding: EdgeInsets.only(top: 2), child: Icon(Icons.location_on_outlined, size: 16, color: Colors.grey)),
                    const SizedBox(width: 8),
                    Expanded(child: Text(account.address!, style: const TextStyle(fontSize: 13, color: Color(0xFF5F6368)), maxLines: 1, overflow: TextOverflow.ellipsis)),
                  ],
                ),
              ),
            if (hasLocation)
              InkWell(
                onTap: () => _showMapDialog(account),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: const BoxDecoration(
                    color: Color(0xFFF1F8FF),
                    border: Border(top: BorderSide(color: Color(0xFFE1E4E8)), bottom: BorderSide(color: Color(0xFFE1E4E8))),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: const [
                      Icon(Icons.map_outlined, size: 16, color: Color(0xFF0366D6)),
                      SizedBox(width: 8),
                      Text("View location on map", style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF0366D6))),
                    ],
                  ),
                ),
              ),
            Row(
              children: [
                _buildGridAction(context, icon: Icons.call, label: "Call", isEnabled: account.phone != null, onTap: () async {
                  final raw = account.phone!.replaceAll(RegExp(r'[^0-9+]'), '');
                  String tel = raw;
                  if (!tel.startsWith('+') && tel.length == 10) tel = '+91$tel';
                  final uri = Uri.parse('tel:$tel');
                  if (await canLaunchUrl(uri)) launchUrl(uri);
                }),
                _buildVerticalDivider(),
                if (hasLocation)
                  _buildGridAction(context, icon: Icons.directions, label: "Navigate", isEnabled: true, onTap: () => _openMapsNavigation(account))
                else
                  _buildGridAction(context, icon: Icons.add_location, label: "Add Location", isEnabled: true, onTap: () => _showLocationPicker(context, account)),
                _buildVerticalDivider(),
                _buildGridAction(context, icon: Icons.info_outline, label: "Details", isEnabled: true, onTap: () => _showAccountDetailsSheet(context, account)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVerticalDivider() => Container(width: 1, height: 24, color: const Color(0xFFEEEEEE));

  Widget _buildGridAction(BuildContext context, {required IconData icon, required String label, required bool isEnabled, required VoidCallback onTap}) {
    return Expanded(
      child: InkWell(
        onTap: isEnabled ? onTap : null,
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(12)),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 18, color: isEnabled ? Colors.black54 : Colors.grey[300]),
              const SizedBox(width: 8),
              Text(label, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: isEnabled ? Colors.black87 : Colors.grey[300])),
            ],
          ),
        ),
      ),
    );
  }

  void _showAccountDetailsSheet(BuildContext context, Account account) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        minChildSize: 0.4,
        maxChildSize: 0.9,
        builder: (_, controller) => Container(
          decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
          child: Column(
            children: [
              Container(margin: const EdgeInsets.only(top: 12, bottom: 20), width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2))),
              Expanded(
                child: ListView(
                  controller: controller,
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  children: [
                    Text(account.name, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold), textAlign: TextAlign.center),
                    const SizedBox(height: 8),
                    Center(child: Chip(label: Text(account.type))),
                    const SizedBox(height: 32),
                    _detailRow("Account ID", account.id),
                    if (account.phone != null) _detailRow("Phone Number", account.phone!),
                    if (account.email != null) _detailRow("Email", account.email!),
                    if (account.address != null) _detailRow("Address", account.address!),
                    if (account.pincode != null) _detailRow("Pincode", account.pincode!),
                    if (account.gstNumber != null) _detailRow("GSTIN", account.gstNumber!),
                    if (account.accountCreditDays != null) _detailRow("Credit Days", account.accountCreditDays.toString()),
                    const SizedBox(height: 40),
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: OutlinedButton.icon(
                        onPressed: () async {
                          final text = _formatAccountShareText(account);
                          try { await Share.share(text, subject: account.name); } catch (_) { await Clipboard.setData(ClipboardData(text: text)); if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Copied!'))); }
                        },
                        icon: const Icon(Icons.share_outlined),
                        label: const Text('Share Details'),
                        style: OutlinedButton.styleFrom(shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _detailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(width: 120, child: Text(label, style: const TextStyle(fontSize: 13, color: Colors.grey, fontWeight: FontWeight.w500))),
          Expanded(child: Text(value, style: const TextStyle(fontSize: 14, color: Colors.black87, fontWeight: FontWeight.w500))),
        ],
      ),
    );
  }

  Widget _buildLoadingState(BuildContext context) => const Center(child: CircularProgressIndicator());
  Widget _buildEmptyState(BuildContext context) => const Center(child: Text("No accounts found"));

  Color _getTypeColor(String type) {
    switch (type) {
      case 'Party': return Colors.blue;
      case 'Bank': return Colors.purple;
      case 'Cash': return Colors.green;
      default: return Colors.grey;
    }
  }
}

