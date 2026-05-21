import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:convert';
import 'dart:async';
import 'package:dio/dio.dart';
import '../auth_service.dart';
import '../models/account_model.dart' as models;

class DoAccountSelectorPage extends StatefulWidget {
  final int fromDo;

  const DoAccountSelectorPage({super.key, this.fromDo = 0});

  /// Push this page and get back a selected [models.Account].
  static Future<models.Account?> show(BuildContext context, {int fromDo = 0}) {
    return Navigator.of(context).push<models.Account>(
      MaterialPageRoute(builder: (_) => DoAccountSelectorPage(fromDo: fromDo)),
    );
  }

  @override
  State<DoAccountSelectorPage> createState() => _DoAccountSelectorPageState();
}

class _DoAccountSelectorPageState extends State<DoAccountSelectorPage> {
  final TextEditingController _searchCtrl = TextEditingController();
  final ScrollController _scrollCtrl = ScrollController();

  List<models.Account> _accounts = [];
  bool _isLoading = false;
  bool _isLoadingMore = false;
  bool _hasMore = true;
  int _page = 1;
  static const int _pageSize = 20;
  String _searchQuery = '';
  Timer? _debounce;

  // Firm selection
  List<_Firm> _firms = [];
  _Firm? _selectedFirm;
  bool _isLoadingFirms = false;

  @override
  void initState() {
    super.initState();
    _scrollCtrl.addListener(_onScroll);
    _init();
  }

  Future<void> _init() async {
    await _loadFirms();
    await _loadAccounts(reset: true);
  }

  /// Fetch the list of firms for the current licence and pre-select the one
  /// matching the user's primary store (falls back to the first firm).
  Future<void> _loadFirms() async {
    setState(() => _isLoadingFirms = true);
    try {
      final auth = Provider.of<AuthService>(context, listen: false);
      final dio = auth.getDioClient();
      final user = auth.currentUser;

      final response = await dio.post(
        '/GetFirmList',
        data: {
          'lLicNo': user?.licenseNumber ?? '',
          'lPageNo': 1,
          'lSize': 100,
          'lSearchFieldValue': '',
          'lExecuteTotalRows': 1,
        },
        options: Options(headers: {
          'Content-Type': 'application/json',
          'package_name': auth.packageNameHeader,
          if (auth.getAuthHeader() != null) 'Authorization': auth.getAuthHeader(),
        }),
      );

      dynamic raw = response.data;
      Map<String, dynamic> parsed = {};
      if (raw is Map<String, dynamic>) {
        parsed = raw;
      } else if (raw is String) {
        parsed = jsonDecode(raw.replaceAll(RegExp(r'[\x00-\x1F\x7F]'), '')) as Map<String, dynamic>;
      } else {
        parsed = jsonDecode(jsonEncode(raw)) as Map<String, dynamic>;
      }

      final List<dynamic> list = (parsed['data'] is List) ? parsed['data'] as List : [];
      final firms = list
          .map((e) => _Firm(
                code: (e['Code'] ?? '').toString(),
                name: (e['Name'] ?? '').toString(),
              ))
          .where((f) => f.code.isNotEmpty)
          .toList();

      // Pre-select the user's primary store firm if present.
      String primaryFirmCode = '';
      try {
        if (user != null && user.stores.isNotEmpty) {
          primaryFirmCode = user.stores
              .firstWhere((s) => s.primary, orElse: () => user.stores.first)
              .firmCode;
        }
      } catch (_) {}

      setState(() {
        _firms = firms;
        _selectedFirm = firms.isEmpty
            ? null
            : firms.firstWhere(
                (f) => f.code == primaryFirmCode,
                orElse: () => firms.first,
              );
        _isLoadingFirms = false;
      });
    } catch (e) {
      setState(() => _isLoadingFirms = false);
      debugPrint('[GetFirmList] error: $e');
    }
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    _scrollCtrl.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollCtrl.position.pixels >= _scrollCtrl.position.maxScrollExtent - 200) {
      if (!_isLoadingMore && _hasMore) _loadAccounts();
    }
  }

  void _onSearch(String val) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 350), () {
      _searchQuery = val.trim();
      _loadAccounts(reset: true);
    });
  }

  Future<void> _loadAccounts({bool reset = false}) async {
    if (reset) {
      setState(() {
        _page = 1;
        _accounts = [];
        _hasMore = true;
        _isLoading = true;
      });
    } else {
      if (_isLoadingMore || !_hasMore) return;
      setState(() => _isLoadingMore = true);
    }

    try {
      final auth = Provider.of<AuthService>(context, listen: false);
      final dio = auth.getDioClient();
      final user = auth.currentUser;

      // Prefer the firm picked in the selector; fall back to the primary store.
      String firmCode = _selectedFirm?.code ?? '';
      if (firmCode.isEmpty) {
        try {
          if (user != null && user.stores.isNotEmpty) {
            final primary = user.stores.firstWhere((s) => s.primary, orElse: () => user.stores.first);
            firmCode = primary.firmCode;
          }
        } catch (_) {}
      }

      final payload = {
        'lLicNo': user?.licenseNumber ?? '',
        'lUserId': user?.mobileNumber ?? user?.userId ?? '',
        'FirmCode': firmCode,
        'lPageNo': reset ? 1 : _page,
        'lSize': _pageSize,
        'lSearchFieldValue': _searchQuery,
        'lExecuteTotalRows': 1,
        'FromDo': widget.fromDo,
      };

      final headers = {
        'Content-Type': 'application/json',
        'package_name': auth.packageNameHeader,
        if (auth.getAuthHeader() != null) 'Authorization': auth.getAuthHeader(),
      };

      final response = await dio.post(
        '/GetDoAccount',
        data: payload,
        options: Options(headers: headers),
      );

      debugPrint('===== GetDoAccount API RESPONSE =====');
      debugPrint('RAW RESPONSE: ${response.data}');
      debugPrint('=====================================');

      dynamic raw = response.data;
      Map<String, dynamic> parsed = {};
      if (raw is Map<String, dynamic>) {
        parsed = raw;
      } else if (raw is String) {
        final clean = raw.replaceAll(RegExp(r'[\x00-\x1F\x7F]'), '');
        parsed = jsonDecode(clean) as Map<String, dynamic>;
      } else {
        parsed = jsonDecode(jsonEncode(raw)) as Map<String, dynamic>;
      }

      final List<dynamic> items =
          (parsed['data'] is Map && parsed['data']['Account'] is List)
              ? parsed['data']['Account'] as List
              : [];

      debugPrint('[GetDoAccount] PARSED RESPONSE: $parsed');
      debugPrint('[GetDoAccount] Total Accounts Found: ${items.length}');
      for (int i = 0; i < items.length; i++) {
        final item = items[i];
        debugPrint('[GetDoAccount] Account $i: ${item['Name']} (${item['Code']})');
      }

      final newAccounts = items.map((e) {
        final m = e is Map<String, dynamic> ? e : Map<String, dynamic>.from(e as Map);
        return models.Account(
          id: m['Code']?.toString() ?? '',
          name: m['Name']?.toString() ?? '',
          type: 'Party',
          code: m['Code']?.toString(),
          phone: m['Mobile']?.toString(),
          email: m['Email']?.toString(),
          address: m['Address1']?.toString(),
          address2: m['Address2']?.toString(),
          address3: m['Address3']?.toString(),
          pincode: m['PinCode']?.toString(),
          gstNumber: m['GstNumber']?.toString(),
          rcount: int.tryParse(m['RCount']?.toString() ?? ''),
        );
      }).toList();

      setState(() {
        if (reset) {
          _accounts = newAccounts;
          _page = 2;
        } else {
          _accounts.addAll(newAccounts);
          _page++;
        }
        _hasMore = newAccounts.length >= _pageSize;
        _isLoading = false;
        _isLoadingMore = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _isLoadingMore = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load accounts: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: cs.surface,
      appBar: AppBar(
        backgroundColor: cs.surface,
        scrolledUnderElevation: 0,
        title: Text(
          'Select Account',
          style: tt.titleLarge?.copyWith(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          // Firm selector
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
            child: InputDecorator(
              decoration: InputDecoration(
                labelText: 'Firm',
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                prefixIcon: Icon(Icons.domain_rounded, size: 20, color: cs.primary),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: cs.outlineVariant),
                ),
              ),
              child: _isLoadingFirms
                  ? const SizedBox(
                      height: 24,
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2)),
                      ),
                    )
                  : DropdownButtonHideUnderline(
                      child: DropdownButton<_Firm>(
                        isExpanded: true,
                        value: _selectedFirm,
                        hint: const Text('Select firm'),
                        items: _firms
                            .map((f) => DropdownMenuItem<_Firm>(
                                  value: f,
                                  child: Text(
                                    f.name.isNotEmpty ? f.name : f.code,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: tt.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
                                  ),
                                ))
                            .toList(),
                        onChanged: (f) {
                          if (f == null || f.code == _selectedFirm?.code) return;
                          setState(() => _selectedFirm = f);
                          _loadAccounts(reset: true);
                        },
                      ),
                    ),
            ),
          ),

          // Search bar
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
            child: TextField(
              controller: _searchCtrl,
              onChanged: _onSearch,
              style: const TextStyle(fontSize: 14),
              decoration: InputDecoration(
                hintText: 'Search accounts...',
                hintStyle: TextStyle(
                  color: cs.onSurfaceVariant.withValues(alpha: 0.6),
                  fontSize: 14,
                ),
                prefixIcon: Icon(Icons.search, color: cs.onSurfaceVariant, size: 20),
                suffixIcon: _searchCtrl.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, size: 18),
                        onPressed: () {
                          _searchCtrl.clear();
                          _onSearch('');
                        },
                      )
                    : null,
                filled: true,
                fillColor: cs.surfaceContainerHighest.withValues(alpha: 0.4),
                contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 16),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
          const Divider(height: 1),

          // Account list
          Expanded(
            child: _isLoading
                ? Center(child: CircularProgressIndicator(color: cs.primary, strokeWidth: 2))
                : _accounts.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.person_search_outlined, size: 56, color: cs.outline),
                            const SizedBox(height: 12),
                            Text(
                              'No accounts found',
                              style: tt.bodyMedium?.copyWith(color: cs.onSurfaceVariant),
                            ),
                          ],
                        ),
                      )
                    : ListView.separated(
                        controller: _scrollCtrl,
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        itemCount: _accounts.length + (_isLoadingMore ? 1 : 0),
                        separatorBuilder: (_, __) => Divider(
                          height: 1,
                          indent: 72,
                          color: cs.outlineVariant.withValues(alpha: 0.5),
                        ),
                        itemBuilder: (context, i) {
                          if (i == _accounts.length) {
                            return const Padding(
                              padding: EdgeInsets.all(16),
                              child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
                            );
                          }
                          final acc = _accounts[i];
                          final initials = acc.name.isNotEmpty
                              ? acc.name.trim().split(' ').take(2).map((w) => w[0].toUpperCase()).join()
                              : '?';
                          final address = [acc.address, acc.address2, acc.address3]
                              .where((s) => s != null && s.isNotEmpty)
                              .join(', ');

                          return ListTile(
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                            leading: CircleAvatar(
                              radius: 22,
                              backgroundColor: cs.primaryContainer,
                              child: Text(
                                initials,
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                  color: cs.onPrimaryContainer,
                                ),
                              ),
                            ),
                            title: Text(
                              acc.name,
                              style: tt.bodyMedium?.copyWith(fontWeight: FontWeight.w700),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                if (address.isNotEmpty) ...[
                                  const SizedBox(height: 2),
                                  Text(
                                    address,
                                    style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                                if ((acc.phone ?? '').isNotEmpty) ...[
                                  const SizedBox(height: 2),
                                  Row(
                                    children: [
                                      Icon(Icons.phone_outlined, size: 12, color: cs.outline),
                                      const SizedBox(width: 4),
                                      Text(
                                        acc.phone!,
                                        style: tt.labelSmall?.copyWith(color: cs.outline),
                                      ),
                                    ],
                                  ),
                                ],
                              ],
                            ),
                            trailing: Icon(Icons.chevron_right, color: cs.outline, size: 20),
                            onTap: () => Navigator.of(context).pop(acc),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}

/// A firm returned by /GetFirmList.
class _Firm {
  final String code;
  final String name;

  const _Firm({required this.code, required this.name});

  @override
  bool operator ==(Object other) => other is _Firm && other.code == code;

  @override
  int get hashCode => code.hashCode;
}

