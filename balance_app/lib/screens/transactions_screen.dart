import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/dummy_data.dart';
import '../providers/app_providers.dart';
import '../providers/currency_provider.dart';
import '../utils/currency_format.dart';
import '../widgets/app_drawer.dart';
import 'transaction_card.dart';
import 'transaction_detail_screen.dart';
import 'transaction_skeleton.dart';
import '../data/models.dart';

/// List item for grouped list: either a section header or a transaction.
class _ListEntry {
  const _ListEntry.section(this.label) : item = null;
  const _ListEntry.transaction(this.item) : label = null;
  final String? label;
  final TransactionItem? item;
  bool get isSection => label != null;
}

/// Full list of all transactions, latest to oldest. Grouped by day. Search + Filter. Infinite scroll.
class TransactionsScreen extends ConsumerStatefulWidget {
  const TransactionsScreen({super.key});

  @override
  ConsumerState<TransactionsScreen> createState() => _TransactionsScreenState();
}

/// Current filter values (null / empty = no filter).
class _TransactionFilters {
  const _TransactionFilters({
    this.type,
    this.categoryNames,
    this.tagIds,
    this.dateFrom,
    this.dateTo,
    this.amountMin,
    this.amountMax,
  });
  final TransactionType? type;
  /// Non-null and non-empty = filter by these categories.
  final List<String>? categoryNames;
  /// Non-null and non-empty = filter by these tag IDs (transaction has any).
  final List<String>? tagIds;
  final DateTime? dateFrom;
  final DateTime? dateTo;
  final double? amountMin;
  final double? amountMax;
  bool get hasAny =>
      type != null ||
      (categoryNames != null && categoryNames!.isNotEmpty) ||
      (tagIds != null && tagIds!.isNotEmpty) ||
      dateFrom != null ||
      dateTo != null ||
      amountMin != null ||
      amountMax != null;
  _TransactionFilters copyWith({
    bool clearType = false,
    bool clearCategory = false,
    bool clearTagIds = false,
    bool clearDate = false,
    bool clearAmount = false,
    TransactionType? type,
    List<String>? categoryNames,
    List<String>? tagIds,
    DateTime? dateFrom,
    DateTime? dateTo,
    double? amountMin,
    double? amountMax,
  }) {
    return _TransactionFilters(
      type: clearType ? null : (type ?? this.type),
      categoryNames: clearCategory ? null : (categoryNames ?? this.categoryNames),
      tagIds: clearTagIds ? null : (tagIds ?? this.tagIds),
      dateFrom: clearDate ? null : (dateFrom ?? this.dateFrom),
      dateTo: clearDate ? null : (dateTo ?? this.dateTo),
      amountMin: clearAmount ? null : (amountMin ?? this.amountMin),
      amountMax: clearAmount ? null : (amountMax ?? this.amountMax),
    );
  }
}

class _TransactionsScreenState extends ConsumerState<TransactionsScreen>
    with SingleTickerProviderStateMixin {
  static const int _pageSize = 10;

  final ScrollController _scrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  bool _isLoading = false;
  int _page = 0;
  double _lastKeyboardInset = 0;
  _TransactionFilters _filters = const _TransactionFilters();
  late AnimationController _drawerController;
  late Animation<double> _drawerAnimation;

  List<TransactionItem> _filteredCache = [];
  bool _hasMore() => (_page + 1) * _pageSize < _filteredCache.length;

  @override
  void initState() {
    super.initState();
    _drawerController = AnimationController(
      duration: const Duration(milliseconds: 280),
      vsync: this,
    );
    _drawerAnimation = CurvedAnimation(
      parent: _drawerController,
      curve: Curves.easeInOut,
    );
    _scrollController.addListener(_onScroll);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Future.delayed(const Duration(milliseconds: 100), () {
        if (!mounted) return;
        FocusManager.instance.primaryFocus?.unfocus();
      });
    });
  }

  @override
  void dispose() {
    _drawerController.dispose();
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  void _openDrawer() => _drawerController.forward();
  void _closeDrawer() => _drawerController.reverse();

  /// Parse "Mar 8" or "Mar 8 2024" style to DateTime. Returns null if parse fails.
  static DateTime? _parseDate(String dateStr) {
    const months = {
      'Jan': 1, 'Feb': 2, 'Mar': 3, 'Apr': 4, 'May': 5, 'Jun': 6,
      'Jul': 7, 'Aug': 8, 'Sep': 9, 'Oct': 10, 'Nov': 11, 'Dec': 12,
    };
    final parts = dateStr.trim().split(RegExp(r'\s+'));
    if (parts.length < 2) return null;
    final month = months[parts[0]];
    final day = int.tryParse(parts[1]);
    if (month == null || day == null) return null;
    final year = parts.length >= 3 ? (int.tryParse(parts[2]) ?? DateTime.now().year) : DateTime.now().year;
    if (day < 1 || day > 31) return null;
    try {
      return DateTime(year, month, day);
    } catch (_) {
      return null;
    }
  }

  static String _sectionLabel(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final d = DateTime(date.year, date.month, date.day);
    if (d == today) return 'TODAY';
    if (d == yesterday) return 'YESTERDAY';
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year.toString().substring(2)}';
  }

  /// Parse amount string (e.g. "-BDT 80", "+BDT 5,000") to numeric value (absolute for range).
  static double? _parseAmountValue(String amountStr) {
    final cleaned = amountStr.replaceAll(RegExp(r'[^\d.-]'), '').trim();
    if (cleaned.isEmpty) return null;
    final v = double.tryParse(cleaned);
    return v?.abs();
  }

  /// Full filtered list (search + type, category, date, amount). Recomputed when deps change.
  List<TransactionItem> _filteredTransactions(List<TransactionItem> allTransactions) {
    var list = allTransactions;
    final searchQuery = _searchController.text.trim().toLowerCase();
    if (searchQuery.isNotEmpty) {
      list = list.where((t) {
        return t.categoryName.toLowerCase().contains(searchQuery) ||
            (t.description?.toLowerCase().contains(searchQuery) ?? false) ||
            t.amount.toLowerCase().contains(searchQuery);
      }).toList();
    }
    if (_filters.type != null) {
      list = list.where((t) => t.type == _filters.type).toList();
    }
    if (_filters.categoryNames != null && _filters.categoryNames!.isNotEmpty) {
      final names = _filters.categoryNames!.toSet();
      list = list.where((t) => names.contains(t.categoryName)).toList();
    }
    if (_filters.tagIds != null && _filters.tagIds!.isNotEmpty) {
      final tagIdSet = _filters.tagIds!.toSet();
      list = list.where((t) =>
          t.tagIds.isNotEmpty && t.tagIds.any((tid) => tagIdSet.contains(tid))).toList();
    }
    if (_filters.dateFrom != null || _filters.dateTo != null) {
      list = list.where((t) {
        final d = _parseDate(t.date);
        if (d == null) return false;
        if (_filters.dateFrom != null && d.isBefore(DateTime(_filters.dateFrom!.year, _filters.dateFrom!.month, _filters.dateFrom!.day))) return false;
        if (_filters.dateTo != null) {
          final toEnd = DateTime(_filters.dateTo!.year, _filters.dateTo!.month, _filters.dateTo!.day, 23, 59, 59);
          if (d.isAfter(toEnd)) return false;
        }
        return true;
      }).toList();
    }
    if (_filters.amountMin != null || _filters.amountMax != null) {
      list = list.where((t) {
        final v = _parseAmountValue(t.amount);
        if (v == null) return false;
        if (_filters.amountMin != null && v < _filters.amountMin!) return false;
        if (_filters.amountMax != null && v > _filters.amountMax!) return false;
        return true;
      }).toList();
    }
    return list;
  }

  /// Build grouped entries: section headers + transactions, latest first.
  List<_ListEntry> _buildGroupedEntries(List<TransactionItem> items) {
    var list = items;
    final map = <DateTime, List<TransactionItem>>{};
    for (final t in list) {
      final d = _parseDate(t.date);
      if (d != null) {
        map.putIfAbsent(d, () => []).add(t);
      } else {
        map.putIfAbsent(DateTime(2000, 1, 1), () => []).add(t);
      }
    }
    final sortedDates = map.keys.toList()..sort((a, b) => b.compareTo(a));
    final entries = <_ListEntry>[];
    for (final date in sortedDates) {
      final group = map[date]!;
      entries.add(_ListEntry.section(_sectionLabel(date)));
      for (final t in group) {
        entries.add(_ListEntry.transaction(t));
      }
    }
    return entries;
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;
    final pos = _scrollController.position;
    if (!_isLoading && _hasMore() && pos.pixels >= pos.maxScrollExtent - 300) {
      _loadMore();
    }
  }

  Future<void> _loadMore() async {
    if (_isLoading || !_hasMore()) return;
    if ((_page + 1) * _pageSize >= _filteredCache.length) return;
    setState(() => _isLoading = true);
    await Future.delayed(const Duration(milliseconds: 600));
    if (!mounted) return;
    setState(() {
      _page++;
      _isLoading = false;
    });
  }

  void _resetPagination() {
    _page = 0;
  }

  List<Widget> _buildFilterChips(bool isNarrow) {
    final chips = <Widget>[];
    if (_filters.type != null) {
      chips.add(_filterChip(
        isNarrow,
        _typeLabel(_filters.type!),
        () => setState(() {
          _filters = _filters.copyWith(clearType: true);
          _resetPagination();
        }),
      ));
    }
    if (_filters.categoryNames != null && _filters.categoryNames!.isNotEmpty) {
      final label = _filters.categoryNames!.length == 1
          ? _filters.categoryNames!.single
          : '${_filters.categoryNames!.length} categories';
      chips.add(_filterChip(
        isNarrow,
        label,
        () => setState(() {
          _filters = _filters.copyWith(clearCategory: true);
          _resetPagination();
        }),
      ));
    }
    if (_filters.dateFrom != null || _filters.dateTo != null) {
      final from = _filters.dateFrom != null
          ? '${_filters.dateFrom!.day.toString().padLeft(2, '0')}/${_filters.dateFrom!.month.toString().padLeft(2, '0')}/${_filters.dateFrom!.year.toString().substring(2)}'
          : '—';
      final to = _filters.dateTo != null
          ? '${_filters.dateTo!.day.toString().padLeft(2, '0')}/${_filters.dateTo!.month.toString().padLeft(2, '0')}/${_filters.dateTo!.year.toString().substring(2)}'
          : '—';
      chips.add(_filterChip(
        isNarrow,
        '$from - $to',
        () => setState(() {
          _filters = _filters.copyWith(clearDate: true);
          _resetPagination();
        }),
      ));
    }
    if (_filters.amountMin != null || _filters.amountMax != null) {
      final min = _filters.amountMin != null
          ? formatAmountTruncated(_filters.amountMin!)
          : '—';
      final max = _filters.amountMax != null
          ? formatAmountTruncated(_filters.amountMax!)
          : '—';
      chips.add(_filterChip(
        isNarrow,
        '$min - $max',
        () => setState(() {
          _filters = _filters.copyWith(clearAmount: true);
          _resetPagination();
        }),
      ));
    }
    if (_filters.tagIds != null && _filters.tagIds!.isNotEmpty) {
      chips.add(_filterChip(
        isNarrow,
        _filters.tagIds!.length == 1 ? '1 tag' : '${_filters.tagIds!.length} tags',
        () => setState(() {
          _filters = _filters.copyWith(clearTagIds: true);
          _resetPagination();
        }),
      ));
    }
    return chips;
  }

  static String _typeLabel(TransactionType t) {
    switch (t) {
      case TransactionType.deducted:
        return 'Spend';
      case TransactionType.added:
        return 'Income';
      case TransactionType.transferred:
        return 'Transfer';
    }
  }

  Widget _filterChip(bool isNarrow, String label, VoidCallback onClear) {
    return Padding(
      padding: const EdgeInsets.only(right: 6),
      child: InputChip(
        label: Text(label, style: TextStyle(fontSize: isNarrow ? 12 : 13)),
        deleteIcon: Icon(Icons.close, size: isNarrow ? 16 : 18, color: Colors.grey[700]),
        onDeleted: onClear,
        backgroundColor: Colors.grey[200],
        side: BorderSide.none,
        padding: EdgeInsets.symmetric(horizontal: isNarrow ? 8 : 10, vertical: 4),
      ),
    );
  }

  Widget _clearAllChip(bool isNarrow) {
    return Padding(
      padding: const EdgeInsets.only(right: 6),
      child: ActionChip(
        label: Text('Clear all', style: TextStyle(fontSize: isNarrow ? 12 : 13, color: Colors.grey[700])),
        onPressed: () => setState(() {
          _filters = const _TransactionFilters();
          _resetPagination();
        }),
        backgroundColor: Colors.transparent,
        side: BorderSide(color: Colors.grey[400]!),
        padding: EdgeInsets.symmetric(horizontal: isNarrow ? 8 : 10, vertical: 4),
      ),
    );
  }

  void _openFilterSheet() {
    final allTransactions = ref.read(transactionsProvider).value ?? [];
    final categorySet = allTransactions.map((t) => t.categoryName).toSet();
    final categories = categorySet.toList()..sort();
    final categoryEmojis = <String, String>{};
    for (final t in allTransactions) {
      categoryEmojis[t.categoryName] ??= t.emoji;
    }
    final tags = ref.read(tagsProvider).value ?? [];
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _FilterBottomSheet(
        initialFilters: _filters,
        categories: categories,
        categoryEmojis: categoryEmojis,
        tags: tags,
        onApply: (f) {
          setState(() {
            _filters = f;
            _resetPagination();
          });
          Navigator.of(context).pop();
        },
      ),
    );
  }

  void _openDetail(TransactionItem item) {
    showTransactionDetailSheet(context, item).then((_) {
      if (mounted) setState(() {});
    });
  }

  @override
  Widget build(BuildContext context) {
    final allTransactions = ref.watch(transactionsProvider).value ?? [];
    _filteredCache = _filteredTransactions(allTransactions);
    final media = MediaQuery.of(context);
    final currentInset = media.viewInsets.bottom;
    if (_lastKeyboardInset > 50 && currentInset < 50) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _searchFocusNode.unfocus();
      });
    }
    _lastKeyboardInset = currentInset;

    final width = media.size.width;
    final isNarrow = width < 360;
    final horizontalPadding = _horizontalPadding(width);
    final size = MediaQuery.sizeOf(context);
    final drawerWidth = (size.width * 0.68).clamp(260.0, 320.0);
    const cardRadius = 20.0;

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        clipBehavior: Clip.none,
        children: [
          AppDrawerPanel(
            width: drawerWidth,
            currentRouteName: ModalRoute.of(context)?.settings.name,
            onClose: _closeDrawer,
          ),
          AnimatedBuilder(
            animation: _drawerAnimation,
            builder: (context, _) {
              final progress = _drawerAnimation.value;
              return Transform.translate(
                offset: Offset(drawerWidth * progress, 0),
                child: ClipRRect(
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(cardRadius),
                    topRight: Radius.circular(cardRadius),
                    bottomLeft: Radius.circular(cardRadius),
                  ),
                  child: GestureDetector(
                    onTap: progress > 0 ? _closeDrawer : null,
                    child: Container(
                      color: Colors.white,
                      child: Scaffold(
                        backgroundColor: Colors.white,
                        appBar: AppBar(
                          leading: const SizedBox.shrink(),
                          leadingWidth: 0,
                          title: const Align(
                            alignment: Alignment.centerLeft,
                            child: Text(
                              'Transactions',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          actions: [
                            IconButton(
                              icon: const Icon(Icons.menu_rounded),
                              onPressed: _openDrawer,
                            ),
                          ],
                          backgroundColor: Colors.black,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          scrolledUnderElevation: 0,
                        ),
                        body: _buildTransactionsBody(
                          isNarrow: isNarrow,
                          horizontalPadding: horizontalPadding,
                        ),
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildTransactionsBody({required bool isNarrow, required double horizontalPadding}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
          Padding(
            padding: EdgeInsets.fromLTRB(
              horizontalPadding,
              isNarrow ? 12 : 16,
              horizontalPadding,
              isNarrow ? 10 : 12,
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    focusNode: _searchFocusNode,
                    autofocus: false,
                    onChanged: (_) => setState(_resetPagination),
                    decoration: InputDecoration(
                      hintText: 'Search',
                      hintStyle: TextStyle(color: Colors.grey[500], fontSize: 15),
                      prefixIcon: Icon(Icons.search_rounded, color: Colors.grey[600], size: 22),
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                        borderSide: BorderSide(color: Colors.grey[300]!),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                        borderSide: BorderSide(color: Colors.grey[300]!),
                      ),
                      contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: isNarrow ? 10 : 12),
                    ),
                    style: const TextStyle(fontSize: 15, color: Color(0xFF1C1C1E)),
                  ),
                ),
                const SizedBox(width: 10),
                FilledButton.icon(
                  onPressed: _openFilterSheet,
                  icon: const Icon(Icons.tune_rounded, size: 20),
                  label: const Text('Filter'),
                  style: FilledButton.styleFrom(
                    backgroundColor: Colors.black,
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.symmetric(horizontal: isNarrow ? 14 : 18, vertical: isNarrow ? 10 : 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                  ),
                ),
              ],
            ),
          ),
          if (_filters.hasAny) ...[
            Padding(
              padding: EdgeInsets.fromLTRB(horizontalPadding, 0, horizontalPadding, isNarrow ? 8 : 10),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    ..._buildFilterChips(isNarrow),
                    const SizedBox(width: 6),
                    _clearAllChip(isNarrow),
                  ],
                ),
              ),
            ),
          ],
          Expanded(
            child: Builder(
              builder: (context) {
                final filtered = _filteredCache;
                final endIndex = ((_page + 1) * _pageSize).clamp(0, filtered.length);
                final displayed = filtered.sublist(0, endIndex);
                final entries = _buildGroupedEntries(displayed);
                final skeletonCount = _isLoading ? _pageSize : 0;
                final totalCount = entries.length + skeletonCount;

                return ListView.builder(
                  controller: _scrollController,
                  padding: EdgeInsets.only(
                    left: horizontalPadding,
                    right: horizontalPadding,
                    bottom: isNarrow ? 16 : 20,
                  ),
                  itemCount: totalCount,
                  itemBuilder: (context, index) {
                    if (index >= entries.length) {
                      return TransactionSkeletonRow(isNarrow: isNarrow);
                    }
                    final entry = entries[index];
                    if (entry.isSection) {
                      return Padding(
                        padding: EdgeInsets.only(
                          top: index == 0 ? 4 : 20,
                          bottom: 8,
                        ),
                        child: Text(
                          entry.label!,
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 15,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      );
                    }
                    final showDivider = index + 1 < entries.length && !entries[index + 1].isSection;
                    final currencyCode = ref.watch(selectedCurrencyCodeProvider);
                    final t = entry.item!;
                    return Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        TransactionListRow(
                          item: t,
                          isNarrow: isNarrow,
                          displayAmount: formatStoredAmountWithCurrency(t.amount, currencyCode),
                          onTap: () => _openDetail(t),
                        ),
                        if (showDivider)
                          Divider(
                            height: 1,
                            thickness: 1,
                            color: const Color(0xFFE8E8ED),
                            indent: isNarrow ? 56 : 62,
                            endIndent: 0,
                          ),
                      ],
                    );
                  },
                );
              },
            ),
          ),
        ],
      );
  }

  double _horizontalPadding(double width) {
    if (width < 360) return 16;
    if (width > 600) return 24;
    return 20;
  }
}

/// Filter bottom sheet: type, category, tags, date range, amount range, clear all, apply.
class _FilterBottomSheet extends StatefulWidget {
  const _FilterBottomSheet({
    required this.initialFilters,
    required this.categories,
    required this.categoryEmojis,
    required this.tags,
    required this.onApply,
  });
  final _TransactionFilters initialFilters;
  final List<String> categories;
  final Map<String, String> categoryEmojis;
  final List<TagItem> tags;
  final void Function(_TransactionFilters) onApply;

  @override
  State<_FilterBottomSheet> createState() => _FilterBottomSheetState();
}

class _FilterBottomSheetState extends State<_FilterBottomSheet> {
  late TransactionType? _type;
  late List<String> _selectedCategories;
  late List<String> _selectedTagIds;
  late DateTime? _dateFrom;
  late DateTime? _dateTo;
  late final TextEditingController _amountMinController;
  late final TextEditingController _amountMaxController;

  @override
  void initState() {
    super.initState();
    _type = widget.initialFilters.type;
    _selectedCategories = List<String>.from(widget.initialFilters.categoryNames ?? []);
    _selectedTagIds = List<String>.from(widget.initialFilters.tagIds ?? []);
    _dateFrom = widget.initialFilters.dateFrom;
    _dateTo = widget.initialFilters.dateTo;
    _amountMinController = TextEditingController(
      text: widget.initialFilters.amountMin != null
          ? formatAmountTruncated(widget.initialFilters.amountMin!)
          : '',
    );
    _amountMaxController = TextEditingController(
      text: widget.initialFilters.amountMax != null
          ? formatAmountTruncated(widget.initialFilters.amountMax!)
          : '',
    );
  }

  @override
  void dispose() {
    _amountMinController.dispose();
    _amountMaxController.dispose();
    super.dispose();
  }

  void _clearAll() {
    setState(() {
      _type = null;
      _selectedCategories = [];
      _selectedTagIds = [];
      _dateFrom = null;
      _dateTo = null;
      _amountMinController.clear();
      _amountMaxController.clear();
    });
  }

  void _toggleTag(String tagId) {
    setState(() {
      if (_selectedTagIds.contains(tagId)) {
        _selectedTagIds.remove(tagId);
      } else {
        _selectedTagIds.add(tagId);
      }
    });
  }

  void _toggleCategory(String name) {
    setState(() {
      if (_selectedCategories.contains(name)) {
        _selectedCategories.remove(name);
      } else {
        _selectedCategories.add(name);
      }
    });
  }

  void _apply() {
    final min = double.tryParse(_amountMinController.text.trim());
    final max = double.tryParse(_amountMaxController.text.trim());
    widget.onApply(_TransactionFilters(
      type: _type,
      categoryNames: _selectedCategories.isEmpty ? null : List.from(_selectedCategories),
      tagIds: _selectedTagIds.isEmpty ? null : List.from(_selectedTagIds),
      dateFrom: _dateFrom,
      dateTo: _dateTo,
      amountMin: min,
      amountMax: max,
    ));
  }

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    final bottomPad = media.padding.bottom;
    return Container(
      constraints: BoxConstraints(maxHeight: media.size.height * 0.85),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 12),
          Container(
            width: 36,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
            child: Row(
              children: [
                const Text(
                  'Filters',
                  style: TextStyle(
                    color: Color(0xFF1C1C1E),
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const Spacer(),
                TextButton(
                  onPressed: _clearAll,
                  child: const Text('Clear all'),
                ),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: Icon(Icons.close, color: Colors.grey[700], size: 24),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
                ),
              ],
            ),
          ),
          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text('Transaction type', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF1C1C1E))),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _typeChip(null, 'All'),
                      _typeChip(TransactionType.deducted, 'Spend'),
                      _typeChip(TransactionType.added, 'Income'),
                      _typeChip(TransactionType.transferred, 'Transfer'),
                    ],
                  ),
                  const SizedBox(height: 20),
                  const Text('Categories', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF1C1C1E))),
                  const SizedBox(height: 4),
                  Text('Select one or more', style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                  const SizedBox(height: 10),
                  SizedBox(
                    height: 48 * 3 + 8,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: (widget.categories.length / 3).ceil(),
                      itemBuilder: (context, colIndex) {
                        const rowHeight = 48.0;
                        const gap = 4.0;
                        final start = colIndex * 3;
                        return Padding(
                          padding: EdgeInsets.only(right: colIndex < (widget.categories.length / 3).ceil() - 1 ? 12 : 0),
                          child: SizedBox(
                            width: 160,
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                if (start < widget.categories.length)
                                  Padding(
                                    padding: const EdgeInsets.only(bottom: gap),
                                    child: _categoryRow(
                                      widget.categories[start],
                                      widget.categoryEmojis[widget.categories[start]] ?? '',
                                    ),
                                  )
                                else
                                  const SizedBox(height: rowHeight + gap),
                                if (start + 1 < widget.categories.length)
                                  Padding(
                                    padding: const EdgeInsets.only(bottom: gap),
                                    child: _categoryRow(
                                      widget.categories[start + 1],
                                      widget.categoryEmojis[widget.categories[start + 1]] ?? '',
                                    ),
                                  )
                                else
                                  const SizedBox(height: rowHeight + gap),
                                if (start + 2 < widget.categories.length)
                                  _categoryRow(
                                    widget.categories[start + 2],
                                    widget.categoryEmojis[widget.categories[start + 2]] ?? '',
                                  )
                                else
                                  const SizedBox(height: rowHeight),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  if (widget.tags.isNotEmpty) ...[
                    const SizedBox(height: 20),
                    const Text('Tags', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF1C1C1E))),
                    const SizedBox(height: 4),
                    const Text('Select one or more', style: TextStyle(fontSize: 12, color: Colors.grey)),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: widget.tags.map((tag) {
                        final selected = _selectedTagIds.contains(tag.id);
                        return FilterChip(
                          label: Text(tag.name, style: const TextStyle(fontSize: 13)),
                          selected: selected,
                          onSelected: (_) => _toggleTag(tag.id),
                          selectedColor: Colors.grey[300],
                          checkmarkColor: Colors.black,
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        );
                      }).toList(),
                    ),
                  ],
                  const SizedBox(height: 20),
                  const Text('Date range', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF1C1C1E))),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: _dateTile('From', _dateFrom, (v) => setState(() => _dateFrom = v)),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _dateTile('To', _dateTo, (v) => setState(() => _dateTo = v)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  const Text('Amount range', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF1C1C1E))),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _amountMinController,
                          keyboardType: TextInputType.number,
                          decoration: InputDecoration(
                            hintText: 'Min',
                            filled: true,
                            fillColor: Colors.white,
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                          ),
                          onChanged: (_) => setState(() {}),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextField(
                          controller: _amountMaxController,
                          keyboardType: TextInputType.number,
                          decoration: InputDecoration(
                            hintText: 'Max',
                            filled: true,
                            fillColor: Colors.white,
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                          ),
                          onChanged: (_) => setState(() {}),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          Padding(
            padding: EdgeInsets.fromLTRB(20, 12, 20, 16 + bottomPad),
            child: SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: _apply,
                style: FilledButton.styleFrom(
                  backgroundColor: Colors.black,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text('Apply filters'),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _categoryRow(String name, String emoji) {
    final selected = _selectedCategories.contains(name);
    return Material(
      color: selected ? Colors.grey[300] : Colors.grey[100],
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: () => _toggleCategory(name),
        borderRadius: BorderRadius.circular(12),
        child: SizedBox(
          height: 48,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Row(
              children: [
                if (emoji.isNotEmpty) Text(emoji, style: const TextStyle(fontSize: 22)),
                if (emoji.isNotEmpty) const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    name,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[800],
                      fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (selected) Icon(Icons.check_rounded, size: 20, color: Colors.grey[800]),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _typeChip(TransactionType? value, String label) {
    final selected = _type == value;
    return FilterChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) => setState(() => _type = value),
      selectedColor: Colors.grey[300],
      checkmarkColor: Colors.black,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
    );
  }

  Widget _dateTile(String label, DateTime? value, void Function(DateTime?) onChanged) {
    return InkWell(
      onTap: () async {
        final picked = await showDatePicker(
          context: context,
          initialDate: value ?? DateTime.now(),
          firstDate: DateTime(2020),
          lastDate: DateTime.now().add(const Duration(days: 365)),
        );
        if (picked != null) onChanged(picked);
      },
      borderRadius: BorderRadius.circular(12),
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        ),
        child: value == null
            ? const Text('Select', style: TextStyle(color: Colors.grey))
            : Text('${value.day.toString().padLeft(2, '0')}/${value.month.toString().padLeft(2, '0')}/${value.year}'),
      ),
    );
  }
}
