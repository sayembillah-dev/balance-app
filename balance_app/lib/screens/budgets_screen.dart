import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/dummy_data.dart';
import '../providers/app_providers.dart';
import '../providers/currency_provider.dart';
import '../utils/currency_format.dart';
import '../widgets/app_drawer.dart';
import 'add_monthly_budget_screen.dart';
import 'monthly_budget_detail_screen.dart';

/// Budgets list: cards for each budget. Tap monthly budget to open detail; FAB to add.
class BudgetsScreen extends ConsumerStatefulWidget {
  const BudgetsScreen({super.key});

  @override
  ConsumerState<BudgetsScreen> createState() => _BudgetsScreenState();
}

class _BudgetsScreenState extends ConsumerState<BudgetsScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _drawerController;
  late Animation<double> _drawerAnimation;

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
  }

  @override
  void dispose() {
    _drawerController.dispose();
    super.dispose();
  }

  void _openDrawer() => _drawerController.forward();
  void _closeDrawer() => _drawerController.reverse();

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    final width = media.size.width;
    final isNarrow = width < 360;
    final padding = isNarrow ? 16.0 : 20.0;
    final size = MediaQuery.sizeOf(context);
    final drawerWidth = (size.width * 0.68).clamp(260.0, 320.0);
    const cardRadius = 20.0;
    final monthlyBudgets = ref.watch(monthlyBudgetsProvider).value ?? [];

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
                      color: const Color(0xFFF2F2F7),
                      child: Scaffold(
                        backgroundColor: const Color(0xFFF2F2F7),
                        appBar: AppBar(
                          leading: const SizedBox.shrink(),
                          leadingWidth: 0,
                          title: const Align(
                            alignment: Alignment.centerLeft,
                            child: Text(
                              'Budgets',
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
                        body: monthlyBudgets.isEmpty
                            ? Center(
                                child: Padding(
                                  padding: const EdgeInsets.all(24),
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        Icons.savings_outlined,
                                        size: 64,
                                        color: Colors.grey[400],
                                      ),
                                      const SizedBox(height: 16),
                                      Text(
                                        'No budgets yet',
                                        style: TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.w600,
                                          color: Colors.grey[700],
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        'Tap + to create a Monthly Budget or Particular Budget',
                                        textAlign: TextAlign.center,
                                        style: TextStyle(
                                          fontSize: 14,
                                          color: Colors.grey[600],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              )
                            : _BudgetListContent(
                                monthlyBudgets: monthlyBudgets,
                                isNarrow: isNarrow,
                                padding: padding,
                                bottomPadding: 24 + media.padding.bottom,
                                currencyCode: ref.watch(selectedCurrencyCodeProvider),
                                onBudgetTap: (budget) => Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (context) =>
                                        MonthlyBudgetDetailScreen(
                                      budget: budget,
                                    ),
                                  ),
                                ).then((_) {
                                  if (mounted) setState(() {});
                                }),
                              ),
                        floatingActionButton: FloatingActionButton(
                          onPressed: () async {
                            final added = await Navigator.of(context).push<bool>(
                              MaterialPageRoute(
                                builder: (context) =>
                                    const AddMonthlyBudgetScreen(),
                              ),
                            );
                            if (added == true && mounted) setState(() {});
                          },
                          backgroundColor: Colors.black,
                          foregroundColor: Colors.white,
                          child: const Icon(Icons.add, size: 28),
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
}

/// Splits budgets into current/upcoming vs archived (past months) and shows section headers.
class _BudgetListContent extends StatelessWidget {
  const _BudgetListContent({
    required this.monthlyBudgets,
    required this.isNarrow,
    required this.padding,
    required this.bottomPadding,
    required this.currencyCode,
    required this.onBudgetTap,
  });

  final List<MonthlyBudget> monthlyBudgets;
  final bool isNarrow;
  final double padding;
  final double bottomPadding;
  final String currencyCode;
  final ValueChanged<MonthlyBudget> onBudgetTap;

  static bool _isArchived(MonthlyBudget b) {
    final now = DateTime.now();
    if (b.year < now.year) return true;
    if (b.year == now.year && b.month < now.month) return true;
    return false;
  }

  @override
  Widget build(BuildContext context) {
    final currentAndUpcoming = monthlyBudgets.where((b) => !_isArchived(b)).toList()
      ..sort((a, b) {
        final cmp = a.year.compareTo(b.year);
        return cmp != 0 ? cmp : a.month.compareTo(b.month);
      });
    final archived = monthlyBudgets.where(_isArchived).toList()
      ..sort((a, b) {
        final cmp = b.year.compareTo(a.year);
        return cmp != 0 ? cmp : b.month.compareTo(a.month);
      });

    return ListView(
      padding: EdgeInsets.fromLTRB(padding, 16, padding, bottomPadding),
      children: [
        if (currentAndUpcoming.isNotEmpty) ...[
          if (archived.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Text(
                'Current & upcoming',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey[600],
                  letterSpacing: 0.2,
                ),
              ),
            ),
          ...currentAndUpcoming.map((budget) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _BudgetListCard(
                  budget: budget,
                  isNarrow: isNarrow,
                  incomeSubtitle: formatAmountWithCurrency(budget.regularIncome, currencyCode),
                  onTap: () => onBudgetTap(budget),
                ),
              )),
          if (archived.isNotEmpty) SizedBox(height: isNarrow ? 20 : 24),
        ],
        if (archived.isNotEmpty) ...[
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Text(
              'Archived',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Colors.grey[600],
                letterSpacing: 0.2,
              ),
            ),
          ),
          ...archived.map((budget) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _BudgetListCard(
                  budget: budget,
                  isNarrow: isNarrow,
                  incomeSubtitle: formatAmountWithCurrency(budget.regularIncome, currencyCode),
                  onTap: () => onBudgetTap(budget),
                ),
              )),
        ],
      ],
    );
  }
}

class _BudgetListCard extends StatelessWidget {
  const _BudgetListCard({
    required this.budget,
    required this.isNarrow,
    required this.incomeSubtitle,
    required this.onTap,
  });

  final MonthlyBudget budget;
  final bool isNarrow;
  final String incomeSubtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: EdgeInsets.all(isNarrow ? 14 : 18),
          child: Row(
            children: [
              Container(
                width: isNarrow ? 48 : 56,
                height: isNarrow ? 48 : 56,
                decoration: BoxDecoration(
                  color: const Color(0xFFF2F2F7),
                  borderRadius: BorderRadius.circular(14),
                ),
                alignment: Alignment.center,
                child: const Icon(
                  Icons.calendar_month_rounded,
                  size: 28,
                  color: Color(0xFF1C1C1E),
                ),
              ),
              SizedBox(width: isNarrow ? 14 : 18),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Monthly Budget',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      budget.monthYearLabel,
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF1C1C1E),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '$incomeSubtitle income · ${budget.entries.length} categories',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right_rounded, color: Colors.grey[400], size: 28),
            ],
          ),
        ),
      ),
    );
  }
}
