import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:dio/dio.dart';
import 'dart:convert';

import '../auth_service.dart';
import '../models/account_model.dart' as models;

class SelectAccountReceiptPage extends StatefulWidget {
  const SelectAccountReceiptPage({super.key});

  static Future<Map<String, dynamic>?> show(BuildContext context) async {
    return await Navigator.push<Map<String, dynamic>>(
      context,
      MaterialPageRoute(
        builder: (context) => const SelectAccountReceiptPage(),
      ),
    );
  }

  @override
  State<SelectAccountReceiptPage> createState() => _SelectAccountReceiptPageState();
}

class _SelectAccountReceiptPageState extends State<SelectAccountReceiptPage> {
  final TextEditingController _searchController = TextEditingController();
  List<models.Account> _allAccounts = [];
  List<models.Account> _filteredAccounts = [];
  bool _isLoading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _fetchAccounts();
    _searchController.addListener(_filterAccounts);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<models.Account> _dedupeAccounts(List<models.Account> accounts) {
    final seen = <String>{};
    final unique = <models.Account>[];
    for (final account in accounts) {
      final id = account.id.trim();
      final name = account.name.trim();
      final key = '$id|$name';
      if (seen.add(key)) {
        unique.add(account);
      }
    }
    return unique;
  }

  Future<void> _fetchAccounts() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final auth = Provider.of<AuthService>(context, listen: false);
      final dio = auth.getDioClient();

      String firmCode = '';
      try {
        final stores = auth.currentUser?.stores ?? [];
        final primary = stores.firstWhere((s) => s.primary,
            orElse: () => stores.isNotEmpty ? stores.first : (throw 'no_store'));
        firmCode = primary.firmCode;
      } catch (_) {
        firmCode = '';
      }

      final payload = {
        'lApkName': auth.packageNameHeader,
        'lLicNo': auth.currentUser?.licenseNumber ?? '',
        'lUserId': auth.currentUser?.userId ?? '',
        'lPageNo': '1',
        'lSize': '1000',
        'lSearchFieldValue': '',
        'lExecuteTotalRows': '1',
        'lMr': '',
        'lArea': '',
        'lCUID': '',
        'ltype': '0',
        'device_id': '',
        'device_name': '',
        'v_code': 31,
        'version_name': '1.0.0',
        'app_role': 'SalesMan',
        'cu_id': '',
        'latitude': '',
        'longitude': '',
        'filters': [],
      };

      debugPrint('[SelectAccountReceipt] GetAccount payload: ${jsonEncode(payload)}');

      final response = await dio.post(
        '/GetAccount',
        data: payload,
        options: Options(
          headers: {
            'Content-Type': 'application/json',
            'package_name': auth.packageNameHeader,
            if (auth.getAuthHeader() != null)
              'Authorization': auth.getAuthHeader(),
          },
        ),
      );

      debugPrint('[SelectAccountReceipt] Response status: ${response.statusCode}');
      debugPrint('[SelectAccountReceipt] Response type: ${response.data.runtimeType}');

      String raw = response.data?.toString() ?? '';
      String clean = raw.replaceAll(RegExp(r'[\x00-\x1F\x7F]'), '').trim();
      Map<String, dynamic> data;
      try {
        final decoded = jsonDecode(clean);
        data = decoded is Map<String, dynamic>
            ? decoded
            : {'Message': decoded.toString()};
      } catch (e) {
        debugPrint('[SelectAccountReceipt] JSON decode error: $e');
        data = {'Message': clean};
      }

      debugPrint('[SelectAccountReceipt] Parsed data keys: ${data.keys.toList()}');
      debugPrint('[SelectAccountReceipt] success: ${data['success']}, Status: ${data['Status']}');

      // Check for Account key (new API response) or Outlet key (old API response)
      List<dynamic> accountList = [];
      if (data['Account'] is List) {
        accountList = data['Account'] as List<dynamic>;
        debugPrint('[SelectAccountReceipt] Found Account array with ${accountList.length} items');
      } else if (data['Outlet'] is List) {
        accountList = data['Outlet'] as List<dynamic>;
        debugPrint('[SelectAccountReceipt] Found Outlet array with ${accountList.length} items');
      } else if (data['data']?['Account'] is List) {
        accountList = data['data']['Account'] as List<dynamic>;
        debugPrint('[SelectAccountReceipt] Found data.Account array with ${accountList.length} items');
      } else if (data['data']?['Outlet'] is List) {
        accountList = data['data']['Outlet'] as List<dynamic>;
        debugPrint('[SelectAccountReceipt] Found data.Outlet array with ${accountList.length} items');
      }

      if (accountList.isNotEmpty) {
        final accounts = accountList
            .map((e) => models.Account.fromApiJson(Map<String, dynamic>.from(e as Map)))
            .toList();

        final uniqueAccounts = _dedupeAccounts(accounts);
        debugPrint('[SelectAccountReceipt] Loaded ${uniqueAccounts.length} unique accounts');

        setState(() {
          _allAccounts = uniqueAccounts;
          _filteredAccounts = uniqueAccounts;
          _isLoading = false;
        });
      } else {
        debugPrint('[SelectAccountReceipt] No accounts found in response');
        setState(() {
          _error = 'No accounts found';
          _isLoading = false;
        });
      }
    } catch (e, stackTrace) {
      debugPrint('[SelectAccountReceipt] Error: $e');
      debugPrint('[SelectAccountReceipt] Stack trace: $stackTrace');
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  void _filterAccounts() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      _filteredAccounts = _allAccounts.where((account) {
        final name = account.name.toLowerCase();
        final id = account.id.toLowerCase();
        return name.contains(query) || id.contains(query);
      }).toList();
    });
  }

  void _selectAccount(models.Account account) {
    Navigator.pop(context, {
      'id': account.id,
      'name': account.name,
      'acno': account.id,
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        title: const Text(
          'Select Account',
          style: TextStyle(fontWeight: FontWeight.w700, fontSize: 20),
        ),
        centerTitle: true,
        backgroundColor: colorScheme.surface,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 22),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Column(
        children: [
          // Search bar
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search by name or account number',
                prefixIcon: const Icon(Icons.search),
                filled: true,
                fillColor: colorScheme.surfaceContainerLow,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              ),
            ),
          ),

          // Account list
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _error != null
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.error_outline, size: 64, color: Colors.red[300]),
                            const SizedBox(height: 16),
                            Text(
                              'Error loading accounts',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: colorScheme.onSurface,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 32),
                              child: Text(
                                _error!,
                                style: TextStyle(
                                  fontSize: 13,
                                  color: colorScheme.onSurfaceVariant,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                            const SizedBox(height: 24),
                            ElevatedButton.icon(
                              onPressed: _fetchAccounts,
                              icon: const Icon(Icons.refresh),
                              label: const Text('Retry'),
                            ),
                          ],
                        ),
                      )
                    : _filteredAccounts.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.account_circle_outlined,
                                  size: 64,
                                  color: colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  'No accounts found',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    color: colorScheme.onSurface,
                                  ),
                                ),
                              ],
                            ),
                          )
                        : ListView.separated(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            itemCount: _filteredAccounts.length,
                            separatorBuilder: (context, index) => const SizedBox(height: 8),
                            itemBuilder: (context, index) {
                              final account = _filteredAccounts[index];
                              return _buildAccountCard(account, colorScheme);
                            },
                          ),
          ),
        ],
      ),
    );
  }

  Widget _buildAccountCard(models.Account account, ColorScheme colorScheme) {
    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: colorScheme.outlineVariant.withValues(alpha: 0.3),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: InkWell(
        onTap: () => _selectAccount(account),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.account_circle,
                  color: colorScheme.onPrimaryContainer,
                  size: 28,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      account.name,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: colorScheme.onSurface,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'A/C: ${account.id}',
                      style: TextStyle(
                        fontSize: 12,
                        color: colorScheme.onSurfaceVariant,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.arrow_forward_ios_rounded,
                size: 18,
                color: colorScheme.onSurfaceVariant,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
