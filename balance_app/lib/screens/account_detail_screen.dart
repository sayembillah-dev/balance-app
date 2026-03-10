import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/dummy_data.dart';
import '../providers/app_providers.dart';
import '../providers/currency_provider.dart';
import '../utils/currency_format.dart';
import 'transaction_card.dart';
import 'transaction_detail_screen.dart';
import 'transaction_skeleton.dart';
import 'add_edit_account_screen.dart';

/// Time filter for account transactions.
enum _AccountTimeFilter {
  d7,
  d10,
  d30,
  m3,
  m6,
  thisYear,
  all,
}

extension on _AccountTimeFilter {
  String get label {
    switch (this) {
      case _AccountTimeFilter.d7: return '7d';
      case _AccountTimeFilter.d10: return '10d';
      case _AccountTimeFilter.d30: return '30d';
      case _AccountTimeFilter.m3: return '3 Month';
      case _AccountTimeFilter.m6: return '6 Month';
      case _AccountTimeFilter.thisYear: return 'This year';
      case _AccountTimeFilter.all: return 'All time';
    }
  }

  DateTime? get startDate {
    final now = DateTime.now();
    switch (this) {
      case _AccountTimeFilter.d7: return now.subtract(const Duration(days: 7));
      case _AccountTimeFilter.d10: return now.subtract(const Duration(days: 10));
      case _AccountTimeFilter.d30: return now.subtract(const Duration(days: 30));
      case _AccountTimeFilter.m3: return DateTime(now.year, now.month - 3, now.day);
      case _AccountTimeFilter.m6: return DateTime(now.year, now.month - 6, now.day);
      case _AccountTimeFilter.thisYear: return DateTime(now.year, 1, 1);
      case _AccountTimeFilter.all: return null;
    }
  }
}

/// Account detail: balance, time filter, transactions (infinite scroll, skeletons).
/// Edit/delete account; swipe on transaction for edit/delete.
class AccountDetailScreen extends ConsumerStatefulWidget {
  const AccountDetailScreen({super.key});

  @override
  ConsumerState<AccountDetailScreen> createState() => _AccountDetailScreenState();
}

class _AccountDetailScreenState extends ConsumerState<AccountDetailScreen> {
  static const int _pageSize = 10;

  AccountItem? _accountFallback;
  List<TransactionItem> _filteredCache = [];
  final ScrollController _scrollController = ScrollController();
  _AccountTimeFilter _timeFilter = _AccountTimeFilter.all;
  int _page = 0;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  AccountItem _currentAccount(List<AccountItem> accounts) {
    final args = ModalRoute.of(context)?.settings.arguments as AccountItem?;
    if (args == null) return _accountFallback ?? (accounts.isNotEmpty ? accounts.first : throw StateError('No accounts'));
    final list = accounts.where((a) => a.id == args.id).toList();
    return list.isNotEmpty ? list.first : args;
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  static DateTime? _parseDate(String dateStr) {
    const months = {'Jan': 1, 'Feb': 2, 'Mar': 3, 'Apr': 4, 'May': 5, 'Jun': 6, 'Jul': 7, 'Aug': 8, 'Sep': 9, 'Oct': 10, 'Nov': 11, 'Dec': 12};
    final parts = dateStr.trim().split(RegExp(r'\s+'));
    if (parts.length < 2) return null;
    final month = months[parts[0]];
    final day = int.tryParse(parts[1]);
    if (month == null || day == null) return null;
    final year = parts.length >= 3 ? (int.tryParse(parts[2]) ?? DateTime.now().year) : DateTime.now().year;
    try {
      return DateTime(year, month, day);
    } catch (_) {
      return null;
    }
  }

  double _balance(AccountItem acc, List<TransactionItem> transactions) {
    double sum = acc.initialBalance;
    for (final t in transactions.where((t) => t.accountId == acc.id)) {
      sum += getTransactionEffectiveAmount(t);
    }
    return sum;
  }

  List<TransactionItem> _filteredTransactions(AccountItem acc, List<TransactionItem> transactions) {
    var list = transactions
        .where((t) => t.accountId == acc.id)
        .toList()
      ..sort((a, b) {
        final da = _parseDate(a.date);
        final db = _parseDate(b.date);
        if (da == null && db == null) return 0;
        if (da == null) return 1;
        if (db == null) return -1;
        final cmp = db.compareTo(da);
        if (cmp != 0) return cmp;
        return a.time.compareTo(b.time);
      });
    final start = _timeFilter.startDate;
    if (start != null) {
      list = list.where((t) {
        final d = _parseDate(t.date);
        return d != null && !d.isBefore(DateTime(start.year, start.month, start.day));
      }).toList();
    }
    return list;
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;
    final pos = _scrollController.position;
    if (!_isLoading && (_page + 1) * _pageSize < _filteredCache.length && pos.pixels >= pos.maxScrollExtent - 300) {
      setState(() => _isLoading = true);
      Future.delayed(const Duration(milliseconds: 600), () {
        if (mounted) setState(() { _page++; _isLoading = false; });
      });
    }
  }

  Future<void> _deleteAccount() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete this account?'),
        content: const Text(
          'This action cannot be undone. All transactions linked to this account will remain but will no longer be associated with it. The account will be permanently removed.',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text('Cancel')),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: FilledButton.styleFrom(backgroundColor: const Color(0xFFFF3B30)),
            child: const Text('Delete account'),
          ),
        ],
      ),
    );
    if (confirmed == true && mounted) {
      final accountsList = ref.read(accountsProvider).value ?? [];
      ref.read(accountsProvider.notifier).remove(_currentAccount(accountsList).id);
      if (mounted) Navigator.of(context).popUntil((route) => route.settings.name == '/accounts' || route.isFirst);
    }
  }

  @override
  Widget build(BuildContext context) {
    final accounts = ref.watch(accountsProvider).value ?? [];
    final transactions = ref.watch(transactionsProvider).value ?? [];
    final acc = _currentAccount(accounts);
    _accountFallback = acc;
    final media = MediaQuery.of(context);
    final width = media.size.width;
    final isNarrow = width < 360;
    final padding = isNarrow ? 16.0 : 20.0;
    _filteredCache = _filteredTransactions(acc, transactions);
    final filtered = _filteredCache;
    final endIndex = ((_page + 1) * _pageSize).clamp(0, filtered.length);
    final displayed = filtered.sublist(0, endIndex);
    final initialBalanceRowIndex = displayed.length; // last row
    final totalRows = 1 + displayed.length + (_isLoading ? _pageSize : 0);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          acc.name,
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
        ),
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_rounded),
            onPressed: () async {
              final updated = await Navigator.of(context).push<bool>(
                MaterialPageRoute(
                  builder: (context) => AddEditAccountScreen(account: acc),
                ),
              );
              if (updated == true && mounted) setState(() {});
            },
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline_rounded),
            onPressed: _deleteAccount,
          ),
        ],
      ),
      body: Stack(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                width: double.infinity,
                padding: EdgeInsets.all(padding),
                color: const Color(0xFFF2F2F7),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text('Total balance', style: TextStyle(fontSize: 13, color: Colors.grey)),
                          const SizedBox(height: 4),
                          Text(
                            formatAmountWithCurrency(_balance(acc, transactions), ref.watch(selectedCurrencyCodeProvider)),
                            style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w600, color: Color(0xFF1C1C1E)),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    _TimeFilterSelector(
                      value: _timeFilter,
                      isNarrow: isNarrow,
                      onChanged: (f) => setState(() { _timeFilter = f; _page = 0; }),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: ListView.builder(
              controller: _scrollController,
              padding: EdgeInsets.only(left: padding, right: padding, bottom: 20 + media.padding.bottom),
              itemCount: totalRows,
              itemBuilder: (context, index) {
                if (index == initialBalanceRowIndex) {
                  return Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _InitialBalanceRow(
                        initialBalance: acc.initialBalance,
                        isNarrow: isNarrow,
                        currencyCode: ref.watch(selectedCurrencyCodeProvider),
                      ),
                      Divider(height: 1, thickness: 1, color: const Color(0xFFE8E8ED), indent: isNarrow ? 56 : 62),
                    ],
                  );
                }
                if (index > initialBalanceRowIndex) {
                  return TransactionSkeletonRow(isNarrow: isNarrow);
                }
                final item = displayed[index];
                return Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TransactionListRow(
                      item: item,
                      isNarrow: isNarrow,
                      displayAmount: formatStoredAmountWithCurrency(item.amount, ref.watch(selectedCurrencyCodeProvider)),
                      onTap: () {
                        showTransactionDetailSheet(context, item).then((_) {
                          if (mounted) setState(() {});
                        });
                      },
                    ),
                    Divider(height: 1, thickness: 1, color: const Color(0xFFE8E8ED), indent: isNarrow ? 56 : 62),
                  ],
                );
              },
            ),
          ),
        ],
      ),
        ],
      ),
    );
  }
}

class _InitialBalanceRow extends StatelessWidget {
  const _InitialBalanceRow({
    required this.initialBalance,
    required this.isNarrow,
    required this.currencyCode,
  });

  final double initialBalance;
  final bool isNarrow;
  final String currencyCode;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: isNarrow ? 12 : 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: isNarrow ? 42 : 46,
            height: isNarrow ? 42 : 46,
            decoration: BoxDecoration(
              color: const Color(0xFFF2F2F7),
              borderRadius: BorderRadius.circular(12),
            ),
            alignment: Alignment.center,
            child: const Text('🏦', style: TextStyle(fontSize: 22)),
          ),
          SizedBox(width: isNarrow ? 14 : 16),
          const Expanded(
            child: Text(
              'Initial balance',
              style: TextStyle(
                color: Color(0xFF1C1C1E),
                fontSize: 15,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Text(
            formatAmountWithCurrency(initialBalance, currencyCode),
            style: TextStyle(
              fontSize: isNarrow ? 15 : 16,
              fontWeight: FontWeight.w600,
              color: initialBalance >= 0
                  ? const Color.fromARGB(255, 1, 197, 50)
                  : const Color.fromARGB(255, 208, 12, 1),
            ),
          ),
        ],
      ),
    );
  }
}

class _TimeFilterSelector extends StatelessWidget {
  const _TimeFilterSelector({
    required this.value,
    required this.isNarrow,
    required this.onChanged,
  });

  final _AccountTimeFilter value;
  final bool isNarrow;
  final ValueChanged<_AccountTimeFilter> onChanged;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () async {
          final box = context.findRenderObject() as RenderBox?;
          final pos = box?.localToGlobal(Offset.zero) ?? Offset.zero;
          final size = box?.size ?? Size.zero;
          final selected = await showMenu<_AccountTimeFilter>(
            context: context,
            position: RelativeRect.fromLTRB(
              pos.dx,
              pos.dy + size.height + 6,
              pos.dx + size.width,
              pos.dy + size.height + 7,
            ),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            color: Colors.white,
            elevation: 8,
            items: _AccountTimeFilter.values.map((f) {
              final isSelected = f == value;
              return PopupMenuItem<_AccountTimeFilter>(
                value: f,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      f.label,
                      style: TextStyle(
                        fontSize: isNarrow ? 14 : 15,
                        fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                        color: const Color(0xFF1C1C1E),
                      ),
                    ),
                    if (isSelected)
                      const Icon(Icons.check_rounded, size: 20, color: Color(0xFF1C1C1E)),
                  ],
                ),
              );
            }).toList(),
          );
          if (selected != null) onChanged(selected);
        },
        borderRadius: BorderRadius.circular(12),
        child: SizedBox(
          width: 100,
          child: Container(
            padding: EdgeInsets.symmetric(
              horizontal: isNarrow ? 12 : 14,
              vertical: isNarrow ? 10 : 12,
            ),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFE5E5EA)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Flexible(
                  child: Text(
                    value.label,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF1C1C1E),
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Icon(
                  Icons.keyboard_arrow_down_rounded,
                  size: 20,
                  color: Colors.grey[600],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
