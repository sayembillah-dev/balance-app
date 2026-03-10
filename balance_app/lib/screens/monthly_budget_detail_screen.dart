import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/dummy_data.dart';
import '../providers/app_providers.dart';
import '../providers/currency_provider.dart';
import '../utils/currency_format.dart';
import 'add_monthly_budget_screen.dart';

const Color _kBgGrey = Color(0xFFF2F2F7);
const Color _kCardWhite = Color(0xFFFAFAFA);
const Color _kTextDark = Color(0xFF1C1C1E);
const Color _kBorderGrey = Color(0xFFE5E5EA);

/// Detail view for a monthly budget: remaining circle, category breakdown. Matches app theme.
/// Archived (past month) budgets are view-only: no edit or delete.
class MonthlyBudgetDetailScreen extends ConsumerStatefulWidget {
  const MonthlyBudgetDetailScreen({super.key, required this.budget});

  final MonthlyBudget budget;

  @override
  ConsumerState<MonthlyBudgetDetailScreen> createState() => _MonthlyBudgetDetailScreenState();
}

class _MonthlyBudgetDetailScreenState extends ConsumerState<MonthlyBudgetDetailScreen> {
  bool _ensureTagsScheduled = false;

  static bool _isArchived(MonthlyBudget b) {
    final now = DateTime.now();
    if (b.year < now.year) return true;
    if (b.year == now.year && b.month < now.month) return true;
    return false;
  }

  static const List<Color> _categoryColors = [
    Color(0xFFE6B800),
    Color(0xFFE53935),
    Color(0xFF1E88E5),
    Color(0xFF1C1C1E),
    Color(0xFF00ACC1),
    Color(0xFF43A047),
    Color(0xFF8E24AA),
    Color(0xFFFB8C00),
  ];

  @override
  Widget build(BuildContext context) {
    final budget = widget.budget;
    final ref = this.ref;
    if (!_isArchived(budget) && !_ensureTagsScheduled) {
      _ensureTagsScheduled = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ensureBudgetTags(ref, budget);
      });
    }
    final currencyCode = ref.watch(selectedCurrencyCodeProvider);
    final spendingByCategory = ref.watch(
      budgetSpendingByEntryProvider(budget.id),
    );
    final totalSpent = spendingByCategory.values.fold<double>(0, (a, b) => a + b);
    final media = MediaQuery.of(context);
    final width = media.size.width;
    final isNarrow = width < 360;
    final padding = isNarrow ? 16.0 : 20.0;
    final remaining = budget.remaining;
    final income = budget.regularIncome;
    final remainingPercent = income > 0 ? (remaining / income).clamp(0.0, 1.0) : 0.0;

    return Scaffold(
      backgroundColor: _kBgGrey,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          'Monthly Budget',
          style: TextStyle(
            color: _kTextDark,
            fontWeight: FontWeight.w600,
          ),
        ),
        backgroundColor: Colors.white,
        foregroundColor: _kTextDark,
        elevation: 0,
        actions: _isArchived(budget)
            ? null
            : [
                IconButton(
                  icon: const Icon(Icons.edit_rounded),
                  onPressed: () => _onEdit(context, budget),
                  tooltip: 'Edit',
                ),
                IconButton(
                  icon: const Icon(Icons.delete_outline_rounded),
                  onPressed: () => _onDelete(context, ref, budget, currencyCode),
                  tooltip: 'Delete',
                ),
              ],
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(padding, isNarrow ? 16 : 24, padding, 24 + media.padding.bottom),
        child: Column(
          children: [
            _monthSelector(padding),
            SizedBox(height: isNarrow ? 20 : 28),
            if (income > 0) ...[
              _remainingCircle(context, remaining, remainingPercent, currencyCode),
              if (totalSpent > 0) ...[
                SizedBox(height: isNarrow ? 16 : 20),
                Row(
                  children: [
                    Expanded(
                      child: _legendChip(
                        'Spent in ${widget.budget.monthYearLabel}',
                        formatAmountWithCurrency(totalSpent, currencyCode),
                        const Color(0xFFE53935),
                      ),
                    ),
                    SizedBox(width: isNarrow ? 8 : 12),
                    Expanded(
                      child: _legendChip(
                        'Left from income',
                        formatAmountWithCurrency(income - totalSpent, currencyCode),
                        const Color(0xFF43A047),
                      ),
                    ),
                  ],
                ),
              ],
            ] else ...[
              _noIncomeSummaryCard(context, padding, currencyCode, totalSpent, isNarrow),
            ],
            SizedBox(height: isNarrow ? 24 : 32),
            _sectionTitle('Category breakdown'),
            const SizedBox(height: 16),
            _categoryCharts(context, padding, currencyCode, spendingByCategory),
          ],
        ),
      ),
    );
  }

  static void _onEdit(BuildContext context, MonthlyBudget budget) {
    Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (context) => AddMonthlyBudgetScreen(editBudget: budget),
      ),
    ).then((updated) {
      if (updated == true && context.mounted) {
        Navigator.of(context).pop(true);
      }
    });
  }

  static Future<void> _onDelete(
    BuildContext context,
    WidgetRef ref,
    MonthlyBudget budget,
    String currencyCode,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete this budget?'),
        content: Text(
          '${budget.monthYearLabel} will be permanently removed. This cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: FilledButton.styleFrom(backgroundColor: const Color(0xFFFF3B30)),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed == true && context.mounted) {
      final tagsNotifier = ref.read(tagsProvider.notifier);
      if (budget.budgetTagId != null) {
        await tagsNotifier.remove(budget.budgetTagId!);
      }
      await ref.read(monthlyBudgetsProvider.notifier).remove(budget.id);
      if (context.mounted) Navigator.of(context).pop(true);
    }
  }

  Widget _noIncomeSummaryCard(BuildContext context, double padding, String currencyCode, double totalSpent, bool isNarrow) {
    final totalBudgeted = widget.budget.totalBudgeted;
    return Container(
      padding: EdgeInsets.all(isNarrow ? 16 : 24),
      decoration: BoxDecoration(
        color: _kCardWhite,
        borderRadius: BorderRadius.circular(isNarrow ? 16 : 20),
        border: Border.all(color: _kBorderGrey),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Expanded(
                child: _legendChip(
                  'Total budgeted',
                  formatAmountWithCurrency(totalBudgeted, currencyCode),
                  _kTextDark,
                ),
              ),
              SizedBox(width: isNarrow ? 8 : 12),
              Expanded(
                child: _legendChip(
                  'Spent in ${widget.budget.monthYearLabel}',
                  formatAmountWithCurrency(totalSpent, currencyCode),
                  const Color(0xFFE53935),
                ),
              ),
            ],
          ),
          if (totalSpent > 0 || totalBudgeted > 0) ...[
            SizedBox(height: isNarrow ? 10 : 12),
            Text(
              totalSpent > totalBudgeted
                  ? 'Over by ${formatAmountWithCurrency(totalSpent - totalBudgeted, currencyCode)}'
                  : totalSpent < totalBudgeted
                      ? 'Under by ${formatAmountWithCurrency(totalBudgeted - totalSpent, currencyCode)}'
                      : 'On track',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: totalSpent > totalBudgeted ? const Color(0xFFE53935) : const Color(0xFF43A047),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _monthSelector(double padding) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: _kCardWhite,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _kBorderGrey),
      ),
      child: Row(
        children: [
          Icon(Icons.calendar_today_rounded, size: 20, color: _kTextDark),
          const SizedBox(width: 12),
          Text(
            widget.budget.monthYearLabel,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: _kTextDark,
            ),
          ),
        ],
      ),
    );
  }

  Widget _remainingCircle(BuildContext context, double remaining, double remainingPercent, String currencyCode) {
    final isNarrow = MediaQuery.sizeOf(context).width < 360;
    final size = isNarrow ? 160.0 : 200.0;
    final padding = isNarrow ? 16.0 : 24.0;
    return Container(
      padding: EdgeInsets.all(padding),
      decoration: BoxDecoration(
        color: _kCardWhite,
        borderRadius: BorderRadius.circular(isNarrow ? 16 : 20),
        border: Border.all(color: _kBorderGrey),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: size,
            height: size,
            child: Stack(
              alignment: Alignment.center,
              children: [
                SizedBox(
                  width: size,
                  height: size,
                  child: CircularProgressIndicator(
                    value: remainingPercent,
                    strokeWidth: isNarrow ? 12 : 14,
                    backgroundColor: _kBgGrey,
                    valueColor: const AlwaysStoppedAnimation<Color>(
                      Color(0xFF43A047),
                    ),
                  ),
                ),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Remaining',
                      style: TextStyle(
                        fontSize: isNarrow ? 12 : 14,
                        color: Colors.grey[600],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 4),
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        formatAmountWithCurrency(remaining, currencyCode),
                        style: TextStyle(
                          fontSize: isNarrow ? 22 : 26,
                          fontWeight: FontWeight.w600,
                          color: _kTextDark,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          SizedBox(height: isNarrow ? 14 : 20),
          Wrap(
            alignment: WrapAlignment.center,
            spacing: 12,
            runSpacing: 8,
            children: [
              _legendChip('Income', formatAmountWithCurrency(widget.budget.regularIncome, currencyCode),
                  Colors.grey),
              _legendChip('Budgeted', formatAmountWithCurrency(widget.budget.totalBudgeted, currencyCode),
                  _kTextDark),
            ],
          ),
        ],
      ),
    );
  }

  Widget _legendChip(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: _kBgGrey,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionTitle(String text) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 17,
          fontWeight: FontWeight.w600,
          color: _kTextDark,
        ),
      ),
    );
  }

  Widget _categoryCharts(BuildContext context, double padding, String currencyCode, [Map<String, double> spendingByCategory = const {}]) {
    final entries = widget.budget.entries;
    final width = MediaQuery.sizeOf(context).width;
    final isNarrow = width < 360;
    final crossAxisCount = isNarrow ? 2 : 3;
    final cellPadding = isNarrow ? 10.0 : 14.0;
    final circleSize = isNarrow ? 44.0 : 56.0;
    final spacing = isNarrow ? 10.0 : 16.0;
    final availableWidth = width - padding * 2 - spacing * (crossAxisCount - 1);
    final cellWidth = availableWidth / crossAxisCount;
    final minCellHeight = cellPadding * 2 + circleSize + 8 + 32;
    final childAspectRatio = cellWidth / minCellHeight;

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        mainAxisSpacing: spacing,
        crossAxisSpacing: spacing,
        childAspectRatio: childAspectRatio,
      ),
      itemCount: entries.length,
      itemBuilder: (context, index) {
        final e = entries[index];
        final spent = spendingByCategory[e.categoryId] ?? 0;
        final spentPct = e.budgetAmount > 0 ? (spent / e.budgetAmount).clamp(0.0, 1.5) : 0.0;
        final color = _categoryColors[index % _categoryColors.length];
        final isOver = spent > e.budgetAmount;
        return Container(
          padding: EdgeInsets.all(cellPadding),
          decoration: BoxDecoration(
            color: _kCardWhite,
            borderRadius: BorderRadius.circular(isNarrow ? 12 : 16),
            border: Border.all(color: _kBorderGrey),
          ),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final h = constraints.maxHeight;
              final useCompact = h < 100;
              final cSize = useCompact ? 36.0 : circleSize;
              final fontSize = useCompact ? 10.0 : 12.0;
              final nameSize = useCompact ? 11.0 : 13.0;
              final amountSize = useCompact ? 10.0 : 11.0;
              return Column(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(
                    width: cSize,
                    height: cSize,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        CircularProgressIndicator(
                          value: spentPct.clamp(0.0, 1.0),
                          strokeWidth: useCompact ? 4 : 5,
                          backgroundColor: _kBgGrey,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            isOver ? const Color(0xFFE53935) : color,
                          ),
                        ),
                        Text(
                          spent > 0
                              ? '${(spentPct.clamp(0.0, 1.0) * 100).round()}%'
                              : '0%',
                          style: TextStyle(
                            fontSize: fontSize,
                            fontWeight: FontWeight.w600,
                            color: _kTextDark,
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: useCompact ? 4 : 8),
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      e.categoryName,
                      style: TextStyle(
                        fontSize: nameSize,
                        fontWeight: FontWeight.w500,
                        color: _kTextDark,
                      ),
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  SizedBox(height: useCompact ? 0 : 2),
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      '${formatAmountWithCurrency(spent, currencyCode)} / ${formatAmountWithCurrency(e.budgetAmount, currencyCode)}',
                      style: TextStyle(
                        fontSize: amountSize,
                        color: Colors.grey[600],
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  if (spent > 0 && !useCompact) ...[
                    SizedBox(height: useCompact ? 0 : 2),
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        isOver
                            ? 'Over ${formatAmountWithCurrency(spent - e.budgetAmount, currencyCode)}'
                            : 'Left ${formatAmountWithCurrency(e.budgetAmount - spent, currencyCode)}',
                        style: TextStyle(
                          fontSize: amountSize - 1,
                          fontWeight: FontWeight.w500,
                          color: isOver ? const Color(0xFFE53935) : const Color(0xFF43A047),
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ],
                ],
              );
            },
          ),
        );
      },
    );
  }
}
