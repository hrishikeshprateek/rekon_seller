import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:geolocator/geolocator.dart';
import 'package:dio/dio.dart';
import 'dart:convert';
import 'package:provider/provider.dart';
import '../models/account_model.dart';
import '../auth_service.dart';

class SelectAccountPage extends StatefulWidget {
  final String title;
  final String? accountType; // Filter by type: 'Party', 'Bank', 'Cash', null = all
  final bool showBalance;
  final Account? selectedAccount; // Pre-selected account (optional)

  const SelectAccountPage({
    super.key,
    this.title = 'Select Account',
    this.accountType,
    this.showBalance = true,
    this.selectedAccount,
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

  @override
  void initState() {
    super.initState();
    _loadAccounts();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // --- REAL API IMPLEMENTATION ---

  Future<void> _loadAccounts() async {
    setState(() => _isLoading = true);

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
        'lPageNo': '1',
        'lSize': '20',
        'lSearchFieldValue': '',
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

      if (accountsData != null) {
        _allAccounts = accountsData.map((json) => Account.fromApiJson(json as Map<String, dynamic>)).toList();
      } else {
        _allAccounts = [];
      }

      _filteredAccounts = _allAccounts;

    } catch (e) {
      debugPrint('Error loading accounts: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to load accounts: $e'), backgroundColor: Colors.red));
      }
      _allAccounts = [];
      _filteredAccounts = [];
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _performSearch(String query) {
    if (query.isEmpty) {
      setState(() => _filteredAccounts = _allAccounts);
      return;
    }
    final lowerQuery = query.toLowerCase();
    setState(() {
      _filteredAccounts = _allAccounts.where((account) {
        return account.name.toLowerCase().contains(lowerQuery) ||
            account.id.toLowerCase().contains(lowerQuery) ||
            (account.phone?.contains(query) ?? false);
      }).toList();
    });
  }

  void _selectAccount(Account account) {
    Navigator.of(context).pop(account);
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
    if (account.latitude == null || account.longitude == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Location not available for this account'),
          backgroundColor: Colors.grey,
        ),
      );
      return;
    }

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
              // Map Header
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primaryContainer,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(16),
                    topRight: Radius.circular(16),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(Icons.location_on_rounded, color: Theme.of(context).colorScheme.primary),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            account.name,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Theme.of(context).colorScheme.onSurface,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          if (account.address != null)
                            Text(
                              account.address!,
                              style: TextStyle(
                                fontSize: 12,
                                color: Theme.of(context).colorScheme.onSurfaceVariant,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close_rounded),
                      onPressed: () => Navigator.pop(ctx),
                    ),
                  ],
                ),
              ),
              // OpenStreetMap
              ClipRRect(
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(0),
                  bottomRight: Radius.circular(0),
                ),
                child: SizedBox(
                  height: 350,
                  child: FlutterMap(
                    options: MapOptions(
                      initialCenter: LatLng(account.latitude!, account.longitude!),
                      initialZoom: 15.0,
                      minZoom: 5.0,
                      maxZoom: 18.0,
                    ),
                    children: [
                      TileLayer(
                        urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                        userAgentPackageName: 'com.reckon.reckonbiz',
                        tileProvider: NetworkTileProvider(),
                      ),
                      MarkerLayer(
                        markers: [
                          Marker(
                            point: LatLng(account.latitude!, account.longitude!),
                            width: 80,
                            height: 80,
                            child: Column(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: Theme.of(context).colorScheme.primary,
                                    borderRadius: BorderRadius.circular(8),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.3),
                                        blurRadius: 4,
                                        offset: const Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                  child: Text(
                                    account.name,
                                    style: TextStyle(
                                      color: Theme.of(context).colorScheme.onPrimary,
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    textAlign: TextAlign.center,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Icon(
                                  Icons.location_on,
                                  color: Theme.of(context).colorScheme.error,
                                  size: 40,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      RichAttributionWidget(
                        attributions: [
                          TextSourceAttribution(
                            'OpenStreetMap contributors',
                            onTap: () => launchUrl(Uri.parse('https://openstreetmap.org/copyright')),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              // Action Buttons
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => Navigator.pop(ctx),
                        icon: const Icon(Icons.close_rounded),
                        label: const Text('Close'),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () {
                          Navigator.pop(ctx);
                          _openMapsNavigation(account);
                        },
                        icon: const Icon(Icons.navigation_rounded),
                        label: const Text('Navigate'),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          backgroundColor: Theme.of(context).colorScheme.primary,
                          foregroundColor: Theme.of(context).colorScheme.onPrimary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // UI IMPLEMENTATION
  // ---------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        title: Text(
          widget.title,
          style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 18),
        ),
        centerTitle: true,
        backgroundColor: colorScheme.surface,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: _loadAccounts,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: Column(
        children: [
          // Search Bar
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
            child: TextField(
              controller: _searchController,
              onChanged: _performSearch,
              style: TextStyle(
                fontSize: 16,
                color: colorScheme.onSurface,
              ),
              decoration: InputDecoration(
                hintText: 'Search by name, ID, or phone...',
                hintStyle: TextStyle(
                  color: colorScheme.onSurfaceVariant.withOpacity(0.5),
                  fontSize: 14,
                ),
                prefixIcon: Icon(
                  Icons.search_rounded,
                  color: colorScheme.primary,
                  size: 24,
                ),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                  icon: Icon(Icons.clear_rounded, color: colorScheme.onSurfaceVariant),
                  onPressed: () {
                    _searchController.clear();
                    _performSearch('');
                  },
                )
                    : null,
                filled: true,
                fillColor: colorScheme.surfaceContainerHighest.withOpacity(0.5),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: colorScheme.primary.withOpacity(0.5), width: 1.5),
                ),
              ),
            ),
          ),

          // Filter Chips
          if (widget.accountType == null)
            SizedBox(
              height: 50,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                children: [
                  _buildFilterChip(context, 'All', null),
                  const SizedBox(width: 8),
                  _buildFilterChip(context, 'Parties', 'Party'),
                  const SizedBox(width: 8),
                  _buildFilterChip(context, 'Banks', 'Bank'),
                  const SizedBox(width: 8),
                  _buildFilterChip(context, 'Cash', 'Cash'),
                ],
              ),
            ),

          const Divider(height: 1),

          // Results count
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            child: Row(
              children: [
                Text(
                  '${_filteredAccounts.length} account${_filteredAccounts.length == 1 ? '' : 's'}',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),

          // Account List
          Expanded(
            child: _isLoading
                ? _buildLoadingState(context)
                : _filteredAccounts.isEmpty
                ? _buildEmptyState(context)
                : ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              itemCount: _filteredAccounts.length,
              itemBuilder: (context, index) {
                final account = _filteredAccounts[index];
                final isSelected = widget.selectedAccount?.id == account.id;
                return _buildAccountCard(context, account, isSelected);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(BuildContext context, String label, String? type) {
    final colorScheme = Theme.of(context).colorScheme;
    final isSelected = widget.accountType == type;

    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {},
      labelStyle: TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w600,
        color: isSelected ? colorScheme.onPrimaryContainer : colorScheme.onSurfaceVariant,
      ),
      backgroundColor: colorScheme.surfaceContainerHighest.withOpacity(0.5),
      selectedColor: colorScheme.primaryContainer,
      side: BorderSide.none,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
    );
  }

  Widget _buildAccountCard(BuildContext context, Account account, bool isSelected) {
    final colorScheme = Theme.of(context).colorScheme;
    final hasNegativeBalance = (account.balance ?? 0) < 0;

    // NOTE: If you are seeing "No Location" even if your DB has it,
    // ensure your Account model correctly parses 'Latitude' and 'Longitude' from JSON.
    final hasLocation = (account.latitude != null && account.longitude != null && account.latitude != 0 && account.longitude != 0);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: isSelected ? colorScheme.primaryContainer.withOpacity(0.3) : colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isSelected
              ? colorScheme.primary
              : colorScheme.outlineVariant.withOpacity(0.3),
          width: isSelected ? 2 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: Column(
          children: [
            // Main card content
            InkWell(
              onTap: () => _selectAccount(account),
              // If location exists, round only top corners, else all corners
              borderRadius: BorderRadius.vertical(
                top: const Radius.circular(16),
                bottom: const Radius.circular(16), // Simplified radius to avoid visual glitches if map is forced
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    // Icon/Avatar
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: _getAccountTypeColor(account.type, colorScheme).withOpacity(0.15),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        _getAccountTypeIcon(account.type),
                        color: _getAccountTypeColor(account.type, colorScheme),
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 16),

                    // Account Details
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Name
                          Text(
                            account.name,
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: colorScheme.onSurface,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),

                          // Type & ID
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  color: _getAccountTypeColor(account.type, colorScheme).withOpacity(0.15),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  account.type,
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    color: _getAccountTypeColor(account.type, colorScheme),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'ID: ${account.id}',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: colorScheme.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ),

                          // Phone
                          if (account.phone != null) ...[
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                Icon(Icons.phone_rounded, size: 12, color: colorScheme.onSurfaceVariant),
                                const SizedBox(width: 4),
                                Text(
                                  account.phone!,
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: colorScheme.onSurfaceVariant,
                                  ),
                                ),
                              ],
                            ),
                          ],

                          // Address with location indicator
                          if (account.address != null) ...[
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                Icon(
                                  hasLocation ? Icons.location_on_rounded : Icons.location_off_rounded,
                                  size: 12,
                                  color: hasLocation ? Colors.green : colorScheme.onSurfaceVariant,
                                ),
                                const SizedBox(width: 4),
                                Expanded(
                                  child: Text(
                                    account.address!,
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: colorScheme.onSurfaceVariant,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ],
                      ),
                    ),

                    // Balance
                    if (widget.showBalance && account.balance != null) ...[
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            hasNegativeBalance ? 'You Owe' : 'Balance',
                            style: TextStyle(
                              fontSize: 10,
                              color: colorScheme.onSurfaceVariant,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '₹${account.balance!.abs().toStringAsFixed(0)}',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: hasNegativeBalance ? colorScheme.error : Colors.green,
                            ),
                          ),
                        ],
                      ),
                    ],

                    // Selected indicator
                    if (isSelected) ...[
                      const SizedBox(width: 8),
                      Icon(
                        Icons.check_circle_rounded,
                        color: colorScheme.primary,
                        size: 24,
                      ),
                    ],
                  ],
                ),
              ),
            ),

            // Map preview section - FORCED VISIBLE FOR UI CONSISTENCY
            const Divider(height: 1),
            InkWell(
              onTap: hasLocation ? () => _showMapDialog(account) : null,
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(16),
                bottomRight: Radius.circular(16),
              ),
              child: Container(
                padding: const EdgeInsets.all(12),
                child: Row(
                  children: [
                    // Small map thumbnail
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Container(
                        width: 80,
                        height: 60,
                        color: colorScheme.surfaceContainerHighest,
                        child: Stack(
                          children: [
                            // Static map placeholder
                            Container(
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                  colors: [
                                    colorScheme.primaryContainer.withOpacity(hasLocation ? 0.3 : 0.1),
                                    colorScheme.tertiaryContainer.withOpacity(hasLocation ? 0.3 : 0.1),
                                  ],
                                ),
                              ),
                            ),
                            Center(
                              child: Icon(
                                hasLocation ? Icons.map_rounded : Icons.location_off_rounded,
                                color: hasLocation ? colorScheme.primary : Colors.grey,
                                size: 30,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),

                    // Location info
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            hasLocation ? 'Location Available' : 'No Location Data',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: hasLocation ? colorScheme.onSurface : Colors.grey,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            hasLocation ? 'Tap to view on map' : 'Map unavailable',
                            style: TextStyle(
                              fontSize: 10,
                              color: colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Navigation button
                    IconButton(
                      onPressed: hasLocation ? () => _openMapsNavigation(account) : null,
                      icon: const Icon(Icons.navigation_rounded),
                      color: colorScheme.primary,
                      tooltip: 'Navigate',
                      style: IconButton.styleFrom(
                        backgroundColor: colorScheme.primaryContainer.withOpacity(hasLocation ? 0.5 : 0.1),
                        disabledBackgroundColor: Colors.grey.withOpacity(0.1),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingState(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircularProgressIndicator(color: colorScheme.primary),
          const SizedBox(height: 16),
          Text(
            'Loading accounts...',
            style: TextStyle(
              fontSize: 14,
              color: colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.account_balance_wallet_outlined,
              size: 80,
              color: colorScheme.onSurfaceVariant.withOpacity(0.3),
            ),
            const SizedBox(height: 24),
            Text(
              'No accounts found',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _searchController.text.isEmpty
                  ? 'No accounts available'
                  : 'Try a different search term',
              style: TextStyle(
                fontSize: 14,
                color: colorScheme.onSurfaceVariant.withOpacity(0.7),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  IconData _getAccountTypeIcon(String type) {
    switch (type) {
      case 'Party':
        return Icons.people_rounded;
      case 'Bank':
        return Icons.account_balance_rounded;
      case 'Cash':
        return Icons.payments_rounded;
      default:
        return Icons.account_circle_rounded;
    }
  }

  Color _getAccountTypeColor(String type, ColorScheme colorScheme) {
    switch (type) {
      case 'Party':
        return colorScheme.primary;
      case 'Bank':
        return Colors.blue;
      case 'Cash':
        return Colors.green;
      default:
        return colorScheme.secondary;
    }
  }
}