import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class SpotlightSearch extends StatefulWidget {
  final List<SearchableItem> items;

  const SpotlightSearch({super.key, required this.items});

  @override
  State<SpotlightSearch> createState() => _SpotlightSearchState();

  static Future<SearchableItem?> show(BuildContext context, List<SearchableItem> items) {
    return showGeneralDialog<SearchableItem>(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Search',
      barrierColor: Colors.black54,
      transitionDuration: const Duration(milliseconds: 200),
      pageBuilder: (context, animation, secondaryAnimation) {
        return FadeTransition(
          opacity: animation,
          child: SpotlightSearch(items: items),
        );
      },
    );
  }
}

class _SpotlightSearchState extends State<SpotlightSearch> {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  List<SearchableItem> _filteredItems = [];
  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    _filteredItems = widget.items;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _performSearch(String query) {
    if (query.isEmpty) {
      setState(() {
        _filteredItems = widget.items;
        _selectedIndex = 0;
      });
      return;
    }

    final lowerQuery = query.toLowerCase();
    final results = widget.items.where((item) {
      // Fuzzy search: check if all characters in query appear in order
      final lowerTitle = item.title.toLowerCase();
      final lowerCategory = item.category.toLowerCase();

      // Direct match
      if (lowerTitle.contains(lowerQuery) || lowerCategory.contains(lowerQuery)) {
        return true;
      }

      // Fuzzy match
      int queryIndex = 0;
      for (int i = 0; i < lowerTitle.length && queryIndex < lowerQuery.length; i++) {
        if (lowerTitle[i] == lowerQuery[queryIndex]) {
          queryIndex++;
        }
      }
      return queryIndex == lowerQuery.length;
    }).toList();

    // Sort by relevance
    results.sort((a, b) {
      final aTitle = a.title.toLowerCase();
      final bTitle = b.title.toLowerCase();

      // Exact match first
      if (aTitle.startsWith(lowerQuery) && !bTitle.startsWith(lowerQuery)) return -1;
      if (!aTitle.startsWith(lowerQuery) && bTitle.startsWith(lowerQuery)) return 1;

      // Contains match
      if (aTitle.contains(lowerQuery) && !bTitle.contains(lowerQuery)) return -1;
      if (!aTitle.contains(lowerQuery) && bTitle.contains(lowerQuery)) return 1;

      return a.title.compareTo(b.title);
    });

    setState(() {
      _filteredItems = results;
      _selectedIndex = 0;
    });
  }

  void _selectItem(SearchableItem item) {
    Navigator.of(context).pop();
    item.onTap();
  }

  void _handleKeyEvent(KeyEvent event) {
    if (event is KeyDownEvent) {
      if (event.logicalKey == LogicalKeyboardKey.arrowDown) {
        setState(() {
          _selectedIndex = (_selectedIndex + 1) % _filteredItems.length;
        });
      } else if (event.logicalKey == LogicalKeyboardKey.arrowUp) {
        setState(() {
          _selectedIndex = (_selectedIndex - 1 + _filteredItems.length) % _filteredItems.length;
        });
      } else if (event.logicalKey == LogicalKeyboardKey.enter) {
        if (_filteredItems.isNotEmpty) {
          _selectItem(_filteredItems[_selectedIndex]);
        }
      } else if (event.logicalKey == LogicalKeyboardKey.escape) {
        Navigator.of(context).pop();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final size = MediaQuery.of(context).size;

    return KeyboardListener(
      focusNode: FocusNode(),
      onKeyEvent: _handleKeyEvent,
      child: Center(
        child: Container(
          width: size.width * 0.9,
          constraints: BoxConstraints(
            maxWidth: 600,
            maxHeight: size.height * 0.7,
          ),
          margin: const EdgeInsets.symmetric(horizontal: 20),
          decoration: BoxDecoration(
            color: colorScheme.surface,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.3),
                blurRadius: 30,
                spreadRadius: 5,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Search Input
                Container(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
                  child: TextField(
                    controller: _searchController,
                    focusNode: _focusNode,
                    autofocus: true,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w500,
                      color: colorScheme.onSurface,
                    ),
                    decoration: InputDecoration(
                      hintText: 'Search features...',
                      hintStyle: TextStyle(
                        color: colorScheme.onSurfaceVariant.withOpacity(0.5),
                        fontSize: 18,
                      ),
                      prefixIcon: Icon(
                        Icons.search_rounded,
                        color: colorScheme.primary,
                        size: 28,
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
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      filled: true,
                      fillColor: colorScheme.surfaceContainerHighest.withOpacity(0.5),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    ),
                    onChanged: _performSearch,
                  ),
                ),

                // Mobile-friendly hint (hide keyboard shortcuts on mobile)
                if (size.width > 600) // Show keyboard shortcuts only on tablets/desktop
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
                    child: Row(
                      children: [
                        _buildShortcutChip(context, '↑↓', 'Navigate'),
                        const SizedBox(width: 8),
                        _buildShortcutChip(context, '↵', 'Select'),
                        const SizedBox(width: 8),
                        _buildShortcutChip(context, 'Esc', 'Close'),
                      ],
                    ),
                  )
                else // Mobile hint
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 2),

                  ),

                const Divider(height: 1),

                // Results List
                Flexible(
                  child: _filteredItems.isEmpty
                      ? _buildEmptyState(context)
                      : ListView.builder(
                          shrinkWrap: true,
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          itemCount: _filteredItems.length,
                          itemBuilder: (context, index) {
                            final item = _filteredItems[index];
                            final isSelected = index == _selectedIndex;

                            return Material(
                              color: isSelected
                                  ? colorScheme.primaryContainer.withOpacity(0.3)
                                  : Colors.transparent,
                              child: InkWell(
                                onTap: () => _selectItem(item),
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                                  child: Row(
                                    children: [
                                      // Icon
                                      Container(
                                        width: 44,
                                        height: 44,
                                        decoration: BoxDecoration(
                                          color: isSelected
                                              ? colorScheme.primaryContainer
                                              : colorScheme.surfaceContainerHighest.withOpacity(0.5),
                                          borderRadius: BorderRadius.circular(10),
                                        ),
                                        child: Icon(
                                          item.icon,
                                          color: isSelected
                                              ? colorScheme.primary
                                              : colorScheme.onSurfaceVariant,
                                          size: 22,
                                        ),
                                      ),
                                      const SizedBox(width: 16),
                                      // Text
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              item.title,
                                              style: TextStyle(
                                                fontSize: 15,
                                                fontWeight: FontWeight.w600,
                                                color: colorScheme.onSurface,
                                              ),
                                            ),
                                            const SizedBox(height: 2),
                                            Text(
                                              item.category,
                                              style: TextStyle(
                                                fontSize: 12,
                                                color: colorScheme.onSurfaceVariant,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      // Arrow
                                      if (isSelected)
                                        Icon(
                                          Icons.arrow_forward_rounded,
                                          color: colorScheme.primary,
                                          size: 20,
                                        ),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                ),

                // Footer
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  decoration: BoxDecoration(
                    color: colorScheme.surfaceContainerHighest.withOpacity(0.3),
                    borderRadius: const BorderRadius.only(
                      bottomLeft: Radius.circular(20),
                      bottomRight: Radius.circular(20),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        _filteredItems.isEmpty
                            ? 'No results'
                            : '${_filteredItems.length} feature${_filteredItems.length == 1 ? '' : 's'}',
                        style: TextStyle(
                          fontSize: 12,
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                      Text(
                        'Powered by Reckon',
                        style: TextStyle(
                          fontSize: 11,
                          color: colorScheme.onSurfaceVariant.withOpacity(0.6),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildShortcutChip(BuildContext context, String key, String label) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withOpacity(0.5),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: colorScheme.outlineVariant.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            key,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              color: colorScheme.onSurfaceVariant.withOpacity(0.7),
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
              Icons.search_off_rounded,
              size: 64,
              color: colorScheme.onSurfaceVariant.withOpacity(0.3),
            ),
            const SizedBox(height: 16),
            Text(
              'No features found',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Try a different search term',
              style: TextStyle(
                fontSize: 13,
                color: colorScheme.onSurfaceVariant.withOpacity(0.7),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class SearchableItem {
  final String title;
  final String category;
  final IconData icon;
  final VoidCallback onTap;

  const SearchableItem({
    required this.title,
    required this.category,
    required this.icon,
    required this.onTap,
  });
}

