import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:dio/dio.dart';
import 'dart:convert';
import '../auth_service.dart';

class AccountFilterPage extends StatefulWidget {
  final List<Map<String, dynamic>>? initialSelectedFilters;

  const AccountFilterPage({Key? key, this.initialSelectedFilters}) : super(key: key);

  @override
  State<AccountFilterPage> createState() => _AccountFilterPageState();
}

class _AccountFilterPageState extends State<AccountFilterPage> {
  bool _isLoading = true;
  String? _error;
  List<FilterCategory> _categories = [];

  // CORRECT TYPE: Map<CategoryID, Set<ItemID>>
  final Map<int, Set<int>> _selected = {};

  int _activeCategoryIndex = 0;
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadFilters();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadFilters() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });
      final auth = Provider.of<AuthService>(context, listen: false);
      final dio = auth.getDioClient();

      final payload = jsonEncode({
        'lLicNo': auth.currentUser?.licenseNumber ?? '',
        'lFlag': 'Account',
      });

      final response = await dio.post(
        '/GetFilterList',
        data: payload,
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
        final clean = raw.replaceAll(RegExp(r'[\x00-\x1F\x7F]'), '').trim();
        parsed = jsonDecode(clean) as Map<String, dynamic>;
      } else {
        parsed = jsonDecode(jsonEncode(raw)) as Map<String, dynamic>;
      }

      if (parsed['success'] == true && parsed['data'] != null) {
        final cats = (parsed['data']['categories'] as List<dynamic>?) ?? [];
        _categories = cats.map((c) => FilterCategory.fromJson(c as Map<String, dynamic>)).toList();

        // --- TYPE FIX HERE ---
        for (final cat in _categories) {
          // Explicitly initialize as Set<int>
          if (!_selected.containsKey(cat.id)) {
            _selected[cat.id] = <int>{};
          }
        }

        // If we have initial selected filters passed from caller, apply them so selections persist
        if (widget.initialSelectedFilters != null) {
          try {
            for (final f in widget.initialSelectedFilters!) {
              final int catId = (f['id'] is int) ? f['id'] as int : int.tryParse(f['id']?.toString() ?? '') ?? 0;
              final items = (f['items'] as List<dynamic>?)?.map((e) => int.tryParse(e.toString()) ?? 0).where((e) => e != 0).toSet() ?? <int>{};
              if (_selected.containsKey(catId)) {
                _selected[catId] = items;
              }
            }
          } catch (e) {
            // ignore malformed initial filters
            debugPrint('Failed to apply initialSelectedFilters: $e');
          }
        }

        if (_categories.isEmpty) {
          _error = 'No filters available';
        }
      } else {
        _error = parsed['message']?.toString() ?? 'Failed to load filters';
      }
    } catch (e) {
      _error = e.toString();
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _apply() {
    // Return selected filters as a list of {id: categoryId, items: [itemIds]}
    final List<Map<String, dynamic>> result = [];

    for (final cat in _categories) {
      final selectedIds = _selected[cat.id] ?? <int>{};
      if (selectedIds.isNotEmpty) {
        result.add({
          'id': cat.id,
          'items': selectedIds.toList(),
        });
      }
    }

    // If nothing selected, return an empty list so the caller can treat it as "no filters"
    Navigator.of(context).pop(result);
  }

  void _reset() {
    setState(() {
      for (final cat in _categories) {
        _selected[cat.id] = <int>{}; // Reset to empty Set
      }
    });
  }

  void _toggleItem(int catId, int itemId) {
    setState(() {
      // Ensure we treat it as a Set<int>
      final set = _selected[catId] ?? <int>{};
      if (set.contains(itemId)) {
        set.remove(itemId);
      } else {
        set.add(itemId);
      }
      _selected[catId] = set;
    });
  }

  void _handleTabChange(int index) {
    setState(() {
      _activeCategoryIndex = index;
      _searchQuery = '';
      _searchController.clear();
    });
  }

  Widget _buildVerticalTabs() {
    return Container(
      width: 130,
      color: Colors.grey.shade100,
      child: ListView.builder(
        itemCount: _categories.length,
        itemBuilder: (context, index) {
          final cat = _categories[index];
          final bool isActive = index == _activeCategoryIndex;
          // Safe null check
          final int selectedCount = _selected[cat.id]?.length ?? 0;

          return InkWell(
            onTap: () => _handleTabChange(index),
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
              decoration: BoxDecoration(
                color: isActive ? Colors.white : Colors.transparent,
                border: isActive
                    ? Border(left: BorderSide(color: Theme.of(context).primaryColor, width: 4))
                    : null,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    cat.title,
                    style: TextStyle(
                      fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
                      color: isActive ? Colors.black87 : Colors.grey.shade700,
                      fontSize: 13,
                    ),
                  ),
                  if (selectedCount > 0)
                    Padding(
                      padding: const EdgeInsets.only(top: 6),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: Theme.of(context).primaryColor.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          '$selectedCount',
                          style: TextStyle(fontSize: 11, color: Theme.of(context).primaryColor, fontWeight: FontWeight.w700),
                        ),
                      ),
                    )
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildActiveList() {
    if (_categories.isEmpty) return const SizedBox();

    final activeCat = _categories[_activeCategoryIndex];
    final selectedSet = _selected[activeCat.id] ?? <int>{};

    final filteredItems = activeCat.items.where((item) {
      if (_searchQuery.isEmpty) return true;
      return item.title.toLowerCase().contains(_searchQuery.toLowerCase());
    }).toList();

    return Expanded(
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search ${activeCat.title}...',
                prefixIcon: const Icon(Icons.search, size: 20, color: Colors.grey),
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: Colors.grey.shade300)),
                isDense: true,
                filled: true,
                fillColor: Colors.grey.shade50,
              ),
              onChanged: (val) => setState(() => _searchQuery = val),
            ),
          ),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 4),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text("${filteredItems.length} items", style: const TextStyle(color: Colors.grey, fontSize: 12)),
                TextButton(
                    onPressed: () {
                      setState(() {
                        if (selectedSet.length == filteredItems.length && filteredItems.isNotEmpty) {
                          for(var i in filteredItems) { selectedSet.remove(i.id); }
                        } else {
                          for(var i in filteredItems) { selectedSet.add(i.id); }
                        }
                        _selected[activeCat.id] = selectedSet;
                      });
                    },
                    style: TextButton.styleFrom(padding: EdgeInsets.zero, minimumSize: const Size(50, 30), tapTargetSize: MaterialTapTargetSize.shrinkWrap),
                    child: Text(selectedSet.length == filteredItems.length && filteredItems.isNotEmpty ? "Clear All" : "Select All")
                )
              ],
            ),
          ),

          const Divider(height: 1),

          Expanded(
            child: ListView.builder(
              itemCount: filteredItems.length,
              itemBuilder: (context, index) {
                final item = filteredItems[index];
                final isChecked = selectedSet.contains(item.id);

                return Column(
                  children: [
                    CheckboxListTile(
                      value: isChecked,
                      visualDensity: const VisualDensity(vertical: -3, horizontal: 0),
                      activeColor: Theme.of(context).primaryColor,
                      controlAffinity: ListTileControlAffinity.leading,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 4, vertical: 0),
                      title: Text(item.title, style: const TextStyle(fontSize: 14, color: Color(0xFF222222))),
                      onChanged: (_) => _toggleItem(activeCat.id, item.id),
                    ),
                    if (index < filteredItems.length - 1) const Divider(height: 1, indent: 8, endIndent: 8)
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Filter'),
        elevation: 0.5,
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _loadFilters),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
          ? Center(child: Text(_error!, style: const TextStyle(color: Colors.black87)))
          : Column(
        children: [
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildVerticalTabs(),
                Container(width: 1, color: Colors.grey.shade300),
                _buildActiveList(),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: Colors.white, boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 4, offset: const Offset(0, -2))]),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    // Immediately clear and return empty filters list to caller
                    onPressed: () => Navigator.of(context).pop(<Map<String, dynamic>>[]),
                    style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 12), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
                    child: const Text('Clear All'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _apply,
                    style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 12), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)), backgroundColor: Theme.of(context).primaryColor, foregroundColor: Colors.white),
                    child: Text('Apply (${_selected.values.fold(0, (sum, set) => sum + set.length)})'),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// --- MODELS ---

class FilterCategory {
  final int id;
  final String title;
  final int totalCount;
  final List<FilterItem> items;

  FilterCategory({required this.id, required this.title, required this.totalCount, required this.items});

  factory FilterCategory.fromJson(Map<String, dynamic> json) {
    final items = (json['items'] as List<dynamic>?)?.map((e) => FilterItem.fromJson(e as Map<String, dynamic>)).toList() ?? [];
    return FilterCategory(
        id: int.tryParse(json['id']?.toString() ?? '0') ?? 0,
        title: json['title']?.toString() ?? '',
        totalCount: int.tryParse(json['total_count']?.toString() ?? '0') ?? 0,
        items: items
    );
  }
}

class FilterItem {
  final int id;
  final String title;

  FilterItem({required this.id, required this.title});

  factory FilterItem.fromJson(Map<String, dynamic> json) => FilterItem(
      id: int.tryParse(json['id']?.toString() ?? '0') ?? 0,
      title: json['title']?.toString() ?? ''
  );
}