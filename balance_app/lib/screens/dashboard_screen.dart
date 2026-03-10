import 'dart:ui' show lerpDouble;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/dummy_data.dart';
import '../providers/app_providers.dart';
import '../providers/currency_provider.dart';
import '../utils/currency_format.dart';
import '../widgets/app_drawer.dart';
import 'transaction_card.dart';
import 'transaction_skeleton.dart';
import 'transaction_detail_screen.dart';
import 'add_edit_account_screen.dart';
import 'add_transaction_screen.dart';

/// Dashboard: dark header, accounts middle card, recent transactions masonry grid.
/// Flat design. Infinite scroll with skeleton loading.
class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen>
    with SingleTickerProviderStateMixin {
  static const int _pageSize = 6;
  static const double _morphProgressEpsilon = 0.003;

  final ScrollController _scrollController = ScrollController();
  final ValueNotifier<double> _morphProgressNotifier = ValueNotifier<double>(
    0.0,
  );
  final List<TransactionItem> _displayedTransactions = [];
  bool _isLoading = false;
  bool _hasMore = true;
  int _page = 0;
  bool _balanceVisible = false;
  late AnimationController _drawerController;
  late Animation<double> _drawerAnimation;

  @override
  void initState() {
    super.initState();
    _loadMore();
    _scrollController.addListener(_onScroll);
    _drawerController = AnimationController(
      duration: const Duration(milliseconds: 280),
      vsync: this,
    );
    _drawerAnimation = CurvedAnimation(
      parent: _drawerController,
      curve: Curves.easeInOut,
    );
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    _morphProgressNotifier.dispose();
    _drawerController.dispose();
    super.dispose();
  }

  void _openDrawer() => _drawerController.forward();
  void _closeDrawer() => _drawerController.reverse();

  void _onScroll() {
    if (!_scrollController.hasClients) return;

    final pos = _scrollController.position;

    // Load more when near bottom
    if (!_isLoading && _hasMore && pos.pixels >= pos.maxScrollExtent - 300) {
      _loadMore();
    }

    // Morph progress from scroll (responsive range; start after 24px)
    const double morphStartThreshold = 24.0;
    final viewportHeight = pos.viewportDimension;
    final morphScrollRange = (viewportHeight * 0.22).clamp(160.0, 220.0);
    final effectivePixels = (pos.pixels - morphStartThreshold).clamp(
      0.0,
      double.infinity,
    );
    final raw = (effectivePixels / morphScrollRange).clamp(0.0, 1.0);
    final newProgress = Curves.easeInOut.transform(raw);

    if ((newProgress - _morphProgressNotifier.value).abs() >
        _morphProgressEpsilon) {
      _morphProgressNotifier.value = newProgress;
    }
  }

  Future<void> _loadMore() async {
    if (_isLoading || !_hasMore) return;
    setState(() => _isLoading = true);

    // Simulate network delay; replace with backend pagination later
    await Future.delayed(const Duration(milliseconds: 800));

    if (!mounted) return;
    final all = ref.read(transactionsProvider).value ?? [];
    final start = _page * _pageSize;
    final end = (start + _pageSize).clamp(0, all.length);
    if (start >= all.length) {
      setState(() {
        _hasMore = false;
        _isLoading = false;
      });
      return;
    }
    final next = all.sublist(start, end);
    setState(() {
      _displayedTransactions.addAll(next);
      _page++;
      _hasMore = end < all.length;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final transactionsAsync = ref.watch(transactionsProvider);
    final accountsAsync = ref.watch(accountsProvider);
    final balance = ref.watch(balanceProvider);
    final accountTotals = ref.watch(accountTotalsProvider);
    // Initial load: only when we have data, nothing displayed yet, and we still expect more (avoids re-triggering when list is empty).
    if (transactionsAsync.value != null && _displayedTransactions.isEmpty && _page == 0 && !_isLoading && _hasMore) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _loadMore();
      });
    }
    final media = MediaQuery.of(context);
    final width = media.size.width;
    final isNarrow = width < 360;
    final horizontalPadding = _horizontalPadding(width);

    final size = MediaQuery.sizeOf(context);
    final drawerWidth = (size.width * 0.68).clamp(260.0, 320.0);
    const cardRadius = 20.0;
    final accounts = accountsAsync.value ?? [];
    final hasAccounts = accounts.isNotEmpty;

    return Scaffold(
      backgroundColor: Colors.black,
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          if (!hasAccounts) {
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Add at least one account to create a transaction'),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            }
            return;
          }
          final result = await Navigator.of(context).push<bool?>(
            MaterialPageRoute<bool>(
              builder: (context) => const AddTransactionScreen(),
            ),
          );
          if (result == true && mounted) {
            setState(() {
              _displayedTransactions.clear();
              _page = 0;
              _hasMore = true;
            });
            _loadMore();
          }
        },
        backgroundColor: hasAccounts ? Colors.black : Colors.grey,
        foregroundColor: Colors.white,
        elevation: 2,
        focusElevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: const Icon(Icons.add, size: 28),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
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
                    behavior: progress > 0 ? HitTestBehavior.opaque : HitTestBehavior.translucent,
                    onTap: progress > 0 ? _closeDrawer : null,
                    child: Container(
                      color: const Color(0xFFF2F2F7),
                      child: SafeArea(
                        child: ValueListenableBuilder<double>(
                          valueListenable: _morphProgressNotifier,
                          child: _buildTransactionsSection(
                            context,
                            isNarrow,
                            horizontalPadding,
                          ),
                          builder: (context, p, child) {
                            const double headerHeightFull = 140;
                            const double headerHeightCompact = 88;
                            const double cardOverlapFull = 28;
                            const double cardOverlapCompact = 16;
                            final headerHeight = lerpDouble(
                              headerHeightFull,
                              headerHeightCompact,
                              p,
                            )!;
                            final cardOverlap = lerpDouble(
                              cardOverlapFull,
                              cardOverlapCompact,
                              p,
                            )!;
                            final gapBelowCard = lerpDouble(16, 8, p)!;

                            return RepaintBoundary(
                              child: Stack(
                                clipBehavior: Clip.none,
                                children: [
                                  Positioned(
                                    top: 0,
                                    left: 0,
                                    right: 0,
                                    height: headerHeight,
                                    child: _buildHeader(
                                      context,
                                      isNarrow,
                                      p,
                                      balance: balance,
                                      balanceVisible: _balanceVisible,
                                      onBalanceVisibilityTap: () => setState(() => _balanceVisible = !_balanceVisible),
                                      onMenuTap: _openDrawer,
                                    ),
                                  ),
                                  Positioned(
                                    top: headerHeight,
                                    left: 0,
                                    right: 0,
                                    bottom: 0,
                                    child: ClipRRect(
                                      borderRadius: const BorderRadius.only(
                                        topLeft: Radius.circular(cardRadius),
                                        topRight: Radius.circular(cardRadius),
                                      ),
                                      child: Container(
                                        width: double.infinity,
                                        height: double.infinity,
                                        color: const Color(0xFFF2F2F7),
                                      ),
                                    ),
                                  ),
                                  Positioned(
                                    top: headerHeight - cardOverlap,
                                    left: 0,
                                    right: 0,
                                    bottom: 0,
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.stretch,
                                      children: [
                                        Padding(
                                          padding: EdgeInsets.symmetric(
                                            horizontal: horizontalPadding,
                                          ),
                                          child: _buildMiddleCard(
                                            context,
                                            p,
                                            accounts: accountsAsync.value ?? [],
                                            accountTotals: accountTotals,
                                          ),
                                        ),
                                        SizedBox(height: gapBelowCard),
                                        Expanded(child: child!),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
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

  Widget _buildTransactionsSection(
    BuildContext context,
    bool isNarrow,
    double horizontalPadding,
  ) {
    final allTransactions = ref.read(transactionsProvider).value ?? [];
    final showEmptyTransactions = allTransactions.isEmpty && !_isLoading;

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFFFAFAFA),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 12,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: EdgeInsets.fromLTRB(
                isNarrow ? 18 : 22,
                isNarrow ? 18 : 20,
                isNarrow ? 18 : 22,
                isNarrow ? 14 : 16,
              ),
              child: Text(
                'Recent Transaction',
                style: TextStyle(
                  color: const Color(0xFF1C1C1E),
                  fontSize: isNarrow ? 17 : 19,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            Expanded(
              child: showEmptyTransactions
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Text(
                          'No transaction yet :)',
                          style: TextStyle(
                            color: const Color(0xFF8E8E93),
                            fontSize: isNarrow ? 16 : 17,
                          ),
                        ),
                      ),
                    )
                  : ListView.separated(
                      controller: _scrollController,
                      padding: EdgeInsets.only(
                        left: isNarrow ? 18 : 22,
                        right: isNarrow ? 18 : 22,
                        bottom: isNarrow ? 16 : 20,
                      ),
                      itemCount:
                          _displayedTransactions.length +
                          (_isLoading ? _pageSize : 0),
                      separatorBuilder: (_, _) => Divider(
                        height: 1,
                        thickness: 1,
                        color: const Color(0xFFE8E8ED),
                        indent: isNarrow ? 56 : 62,
                        endIndent: 0,
                      ),
                      itemBuilder: (context, index) {
                        if (index >= _displayedTransactions.length) {
                          return TransactionSkeletonRow(isNarrow: isNarrow);
                        }
                        final currencyCode = ref.watch(selectedCurrencyCodeProvider);
                        final item = _displayedTransactions[index];
                        return TransactionListRow(
                          item: item,
                          isNarrow: isNarrow,
                          displayAmount: formatStoredAmountWithCurrency(item.amount, currencyCode),
                          onTap: () => showTransactionDetailSheet(context, item),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  double _horizontalPadding(double width) {
    if (width < 360) return 16;
    if (width > 600) return 24;
    return 20;
  }

  Widget _buildHeader(
    BuildContext context,
    bool isNarrow,
    double morphProgress, {
    required String balance,
    required bool balanceVisible,
    required VoidCallback onBalanceVisibilityTap,
    required VoidCallback onMenuTap,
  }) {
    final width = MediaQuery.of(context).size.width;
    final hPad = _horizontalPadding(width);
    final topPad = lerpDouble(20, 10, morphProgress)!;
    final bottomPad = lerpDouble(24, 12, morphProgress)!;
    final balanceLabelSize = lerpDouble(isNarrow ? 13 : 14, 11, morphProgress)!;
    final amountSize = lerpDouble(
      isNarrow ? 20 : 24,
      isNarrow ? 15 : 17,
      morphProgress,
    )!;
    final eyeSize = lerpDouble(isNarrow ? 20 : 22, 18, morphProgress)!;

    return Container(
      width: double.infinity,
      height: double.infinity,
      padding: EdgeInsets.fromLTRB(hPad, topPad, hPad, bottomPad),
      decoration: const BoxDecoration(color: Colors.black),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Balance',
                  style: TextStyle(
                    color: Colors.grey[400],
                    fontSize: balanceLabelSize,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                SizedBox(height: lerpDouble(4, 2, morphProgress)!),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Text(
                      balanceVisible ? balance : '••••••••',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: amountSize,
                        fontWeight: FontWeight.w600,
                        letterSpacing: balanceVisible ? null : 6,
                      ),
                    ),
                    SizedBox(width: lerpDouble(6, 4, morphProgress)!),
                    Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: onBalanceVisibilityTap,
                        borderRadius: BorderRadius.circular(12),
                        child: Padding(
                          padding: const EdgeInsets.all(8),
                          child: Icon(
                            balanceVisible
                                ? Icons.visibility_rounded
                                : Icons.visibility_off_rounded,
                            color: Colors.grey[400],
                            size: eyeSize,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          _buildMenuIcon(isNarrow, morphProgress, onMenuTap),
        ],
      ),
    );
  }

  Widget _buildMenuIcon(
    bool isNarrow,
    double morphProgress,
    VoidCallback onMenuTap,
  ) {
    final sizeFull = isNarrow ? 40.0 : 44.0;
    final sizeCompact = isNarrow ? 32.0 : 36.0;
    final size = lerpDouble(sizeFull, sizeCompact, morphProgress)!;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onMenuTap,
        borderRadius: BorderRadius.circular(size / 2),
        child: Container(
          width: size,
          height: size,
          alignment: Alignment.center,
          child: Icon(
            Icons.menu_rounded,
            color: Colors.white,
            size: size * 0.55,
          ),
        ),
      ),
    );
  }

  Widget _buildMiddleCard(
    BuildContext context,
    double morphProgress, {
    required List<AccountItem> accounts,
    required Map<String, AccountTotals> accountTotals,
  }) {
    final media = MediaQuery.of(context);
    final width = media.size.width;
    final height = media.size.height;
    final isNarrow = width < 360;

    final contentHeightFull = (height * 0.20).clamp(160.0, 220.0);
    final contentHeightCompact = (height * 0.12).clamp(72.0, 96.0);
    final contentHeight = lerpDouble(
      contentHeightFull,
      contentHeightCompact,
      morphProgress,
    )!;
    final paddingFull = isNarrow ? 8.0 : 10.0;
    final paddingCompact = 6.0;
    final padding = lerpDouble(paddingFull, paddingCompact, morphProgress)!;

    return Container(
      width: double.infinity,
      constraints: BoxConstraints(minHeight: contentHeight + padding * 2),
      padding: EdgeInsets.all(padding),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: accounts.isEmpty
          ? SizedBox(
              width: double.infinity,
              height: contentHeight,
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'No account yet :)',
                        style: TextStyle(
                          color: const Color(0xFF8E8E93),
                          fontSize: isNarrow ? 15 : 16,
                        ),
                      ),
                      const SizedBox(height: 12),
                      FilledButton.icon(
                        onPressed: () {
                          Navigator.of(context).push(
                            MaterialPageRoute<void>(
                              builder: (context) => const AddEditAccountScreen(),
                            ),
                          );
                        },
                        icon: const Icon(Icons.add_rounded, size: 20),
                        label: const Text('Create account'),
                        style: FilledButton.styleFrom(
                          backgroundColor: Colors.black,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            )
          : accounts.length == 1
          ? SizedBox(
              width: double.infinity,
              height: contentHeight,
              child: _AccountCard(
                item: accounts.first,
                totals: accountTotals[accounts.first.id],
                isNarrow: isNarrow,
                morphProgress: morphProgress,
                onTap: () => Navigator.of(context).pushNamed('/account-detail', arguments: accounts.first),
              ),
            )
          : SizedBox(
              width: double.infinity,
              height: contentHeight,
              child: _AccountsCarousel(
                accounts: accounts,
                accountTotals: accountTotals,
                isNarrow: isNarrow,
                morphProgress: morphProgress,
                onAccountTap: (a) => Navigator.of(context).pushNamed('/account-detail', arguments: a),
              ),
            ),
    );
  }
}

/// Account card: full layout or compact (morphed) with lerped sizes.
class _AccountCard extends StatelessWidget {
  const _AccountCard({
    required this.item,
    this.totals,
    required this.isNarrow,
    required this.morphProgress,
    this.onTap,
  });

  final AccountItem item;
  final AccountTotals? totals;
  final bool isNarrow;
  final double morphProgress;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: LayoutBuilder(
      builder: (context, constraints) {
        final cardWidth = constraints.maxWidth;
        final cardHeight = constraints.maxHeight;
        final p = morphProgress;

        final paddingL = lerpDouble(isNarrow ? 14 : 18, isNarrow ? 10 : 12, p)!;
        final paddingT = lerpDouble(isNarrow ? 14 : 18, isNarrow ? 8 : 10, p)!;
        final paddingR = lerpDouble(64, 52, p)!;
        final nameSize = lerpDouble(isNarrow ? 22 : 26, isNarrow ? 16 : 18, p)!;
        final typeSize = lerpDouble(isNarrow ? 12 : 13, 11, p)!;
        final amountSize = lerpDouble(
          isNarrow ? 14 : 15,
          isNarrow ? 12 : 13,
          p,
        )!;
        final iconSize = lerpDouble(isNarrow ? 16 : 18, 14, p)!;
        final emojiSize = lerpDouble(
          (cardWidth * 0.22).clamp(64.0, 88.0),
          0.0,
          p,
        )!;
        final thisMonthTop = lerpDouble(
          isNarrow ? 14 : 18,
          isNarrow ? 8 : 10,
          p,
        )!;
        final thisMonthSize = lerpDouble(isNarrow ? 12 : 13, 11, p)!;
        final spacing1 = lerpDouble(isNarrow ? 2 : 4, 2, p)!;
        final spacing2 = lerpDouble(isNarrow ? 4 : 6, 3, p)!;

        return ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: Container(
            width: cardWidth,
            height: cardHeight,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xFFE5E5EA), width: 1),
            ),
            clipBehavior: Clip.hardEdge,
            child: Stack(
            children: [
              Padding(
                padding: EdgeInsets.fromLTRB(
                  paddingL,
                  paddingT,
                  paddingR,
                  paddingT,
                ),
                child: SizedBox(
                  height: (cardHeight - 2 * paddingT).clamp(
                    0.0,
                    double.infinity,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    mainAxisSize: MainAxisSize.max,
                    children: [
                      Flexible(
                        child: LayoutBuilder(
                          builder: (context, constraints) {
                            final maxH = constraints.maxHeight;
                            return SizedBox(
                              height: maxH,
                              child: FittedBox(
                                fit: BoxFit.scaleDown,
                                alignment: Alignment.centerLeft,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisSize: MainAxisSize.min,
                                  mainAxisAlignment: MainAxisAlignment.start,
                                  children: [
                                    Text(
                                      item.name,
                                      style: TextStyle(
                                        color: const Color(0xFF1C1C1E),
                                        fontSize: nameSize,
                                        fontWeight: FontWeight.w600,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    SizedBox(height: spacing1),
                                    Text(
                                      item.accountType,
                                      style: TextStyle(
                                        color: Colors.grey[600],
                                        fontSize: typeSize,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Text(
                                totals?.monthIncome ?? item.monthIncome,
                                style: TextStyle(
                                  color: const Color(0xFF1C1C1E),
                                  fontSize: amountSize,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(width: 4),
                              Icon(
                                Icons.arrow_upward_rounded,
                                size: iconSize,
                                color: const Color(0xFF34C759),
                              ),
                            ],
                          ),
                          SizedBox(height: spacing2),
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Text(
                                totals?.monthExpense ?? item.monthExpense,
                                style: TextStyle(
                                  color: const Color(0xFF1C1C1E),
                                  fontSize: amountSize,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(width: 4),
                              Icon(
                                Icons.arrow_downward_rounded,
                                size: iconSize,
                                color: const Color(0xFFFF3B30),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              Positioned(
                top: thisMonthTop,
                right: paddingL,
                child: Text(
                  'This Month',
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: thisMonthSize,
                  ),
                ),
              ),
              if (emojiSize > 4)
                Positioned(
                  right: -12,
                  bottom: -12,
                  child: Text(
                    item.emojis,
                    style: TextStyle(
                      fontSize: emojiSize,
                      height: 1.0,
                      letterSpacing: -4,
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
    );
  }
}

/// Material-style horizontal carousel with next item peeking from the right.
class _AccountsCarousel extends StatelessWidget {
  const _AccountsCarousel({
    required this.accounts,
    required this.accountTotals,
    required this.isNarrow,
    required this.morphProgress,
    required this.onAccountTap,
  });

  final List<AccountItem> accounts;
  final Map<String, AccountTotals> accountTotals;
  final bool isNarrow;
  final double morphProgress;
  final void Function(AccountItem) onAccountTap;

  @override
  Widget build(BuildContext context) {
    return PageView.builder(
      controller: PageController(viewportFraction: 0.92),
      itemCount: accounts.length,
      padEnds: false,
      itemBuilder: (context, index) {
        final account = accounts[index];
        return Padding(
          padding: EdgeInsets.only(right: index < accounts.length - 1 ? 10 : 0),
          child: _AccountCard(
            item: account,
            totals: accountTotals[account.id],
            isNarrow: isNarrow,
            morphProgress: morphProgress,
            onTap: () => onAccountTap(account),
          ),
        );
      },
    );
  }
}
