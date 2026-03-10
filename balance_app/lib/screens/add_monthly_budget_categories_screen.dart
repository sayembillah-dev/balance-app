import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/dummy_data.dart';
import '../providers/app_providers.dart';
import '../providers/currency_provider.dart';

const Color _kBgGrey = Color(0xFFF2F2F7);
const Color _kCardWhite = Color(0xFFFAFAFA);
const Color _kTextDark = Color(0xFF1C1C1E);
const Color _kBorderGrey = Color(0xFFE5E5EA);

/// Step 2: Add expense categories (min 3) with budget amounts. Save / Previous / Cancel.
/// If [editBudget] is set, entries are pre-filled and saving updates that budget.
class AddMonthlyBudgetCategoriesScreen extends ConsumerStatefulWidget {
  const AddMonthlyBudgetCategoriesScreen({
    super.key,
    required this.month,
    required this.year,
    required this.regularIncome,
    this.editBudget,
  });

  final int month;
  final int year;
  final double regularIncome;
  final MonthlyBudget? editBudget;

  @override
  ConsumerState<AddMonthlyBudgetCategoriesScreen> createState() =>
      _AddMonthlyBudgetCategoriesScreenState();
}

class _AddMonthlyBudgetCategoriesScreenState
    extends ConsumerState<AddMonthlyBudgetCategoriesScreen> {
  final List<_EntryRow> _entries = [];
  bool _editPreloadDone = false;

  @override
  void initState() {
    super.initState();
    if (widget.editBudget == null) _addRow();
  }

  void _addRow() {
    setState(() {
      _entries.add(_EntryRow(
        category: null,
        amountController: TextEditingController(text: '0'),
      ));
    });
  }

  void _removeRow(int index) {
    if (_entries.length <= 1) return;
    setState(() {
      _entries[index].amountController.dispose();
      _entries.removeAt(index);
    });
  }

  Future<void> _save() async {
    final valid = <BudgetCategoryEntry>[];
    for (final row in _entries) {
      if (row.category == null) continue;
      final amount = double.tryParse(row.amountController.text.trim());
      if (amount == null || amount < 0) continue;
      valid.add(BudgetCategoryEntry(
        categoryId: row.category!.id,
        categoryName: row.category!.name,
        emoji: row.category!.emoji,
        budgetAmount: amount,
      ));
    }
    if (valid.length < 3) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Add at least 3 categories with valid amounts')),
      );
      return;
    }
    final notifier = ref.read(monthlyBudgetsProvider.notifier);
    final budget = MonthlyBudget(
      id: widget.editBudget?.id ?? notifier.nextId(),
      month: widget.month,
      year: widget.year,
      regularIncome: widget.regularIncome,
      entries: valid,
      budgetTagId: widget.editBudget?.budgetTagId,
    );
    if (widget.editBudget != null) {
      await notifier.replaceById(widget.editBudget!.id, budget);
    } else {
      await notifier.add(budget);
    }
    await ensureBudgetTags(ref, budget);
    if (mounted) Navigator.of(context).pop(true);
  }

  @override
  void dispose() {
    for (final row in _entries) {
      row.amountController.dispose();
    }
    super.dispose();
  }

  void _preloadEditEntries() {
    if (widget.editBudget == null || _editPreloadDone) return;
    final categories = ref.read(categoriesForPickerProvider);
    final budget = widget.editBudget!;
    final newEntries = <_EntryRow>[];
    for (final e in budget.entries) {
      TransactionCategory? cat;
      try {
        cat = categories.firstWhere((c) => c.id == e.categoryId);
      } catch (_) {}
      if (cat != null) {
        newEntries.add(_EntryRow(
          category: cat,
          amountController: TextEditingController(
            text: e.budgetAmount.toStringAsFixed(e.budgetAmount.truncateToDouble() == e.budgetAmount ? 0 : 2),
          ),
        ));
      }
    }
    if (newEntries.length < 3) {
      newEntries.add(_EntryRow(category: null, amountController: TextEditingController(text: '0')));
    }
    _editPreloadDone = true;
    setState(() => _entries
      ..clear()
      ..addAll(newEntries));
  }

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    final padding = media.size.width < 360 ? 16.0 : 20.0;
    if (widget.editBudget != null && !_editPreloadDone && _entries.isEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _preloadEditEntries());
    }

    return Scaffold(
      backgroundColor: _kBgGrey,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.close_rounded),
          onPressed: () => Navigator.of(context).pop(false),
        ),
        title: const Text(
          'Categories & amounts',
          style: TextStyle(
            color: _kTextDark,
            fontWeight: FontWeight.w600,
          ),
        ),
        backgroundColor: Colors.white,
        foregroundColor: _kTextDark,
        elevation: 0,
      ),
      body: Column(
        children: [
          Padding(
            padding: EdgeInsets.fromLTRB(padding, 16, padding, 8),
            child: Text(
              'Step 2 of 2 · Add at least 3 expense categories and their monthly budget.',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[700],
              ),
            ),
          ),
          Expanded(
            child: ListView.builder(
              padding: EdgeInsets.fromLTRB(padding, 8, padding, 16),
              itemCount: _entries.length + 1,
              itemBuilder: (context, index) {
                if (index == _entries.length) {
                  return Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: OutlinedButton.icon(
                      onPressed: _addRow,
                      icon: const Icon(Icons.add_rounded, size: 20),
                      label: const Text('Add category'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: _kTextDark,
                        side: const BorderSide(color: _kBorderGrey),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                    ),
                  );
                }
                final row = _entries[index];
                return _CategoryEntryTile(
                  entry: row,
                  currencyCode: ref.watch(selectedCurrencyCodeProvider),
                  entryCategories: ref.watch(categoriesForPickerProvider),
                  usedCategoryIds: _entries
                      .where((e) => e.category != null && e != row)
                      .map((e) => e.category!.id)
                      .toSet(),
                  onCategorySelected: (c) {
                    setState(() => row.category = c);
                  },
                  onRemove: _entries.length > 1 ? () => _removeRow(index) : null,
                );
              },
            ),
          ),
          Container(
            padding: EdgeInsets.fromLTRB(padding, 16, padding, 16 + media.padding.bottom),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border(top: BorderSide(color: _kBorderGrey)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.of(context).pop(false),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: _kTextDark,
                      side: const BorderSide(color: _kBorderGrey),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    child: const Text('Previous'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: FilledButton(
                    onPressed: _save,
                    style: FilledButton.styleFrom(
                      backgroundColor: Colors.black,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    child: const Text('Save budget'),
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

class _EntryRow {
  _EntryRow({this.category, required this.amountController});
  TransactionCategory? category;
  final TextEditingController amountController;
}

class _CategoryEntryTile extends StatelessWidget {
  const _CategoryEntryTile({
    required this.entry,
    required this.currencyCode,
    required this.entryCategories,
    required this.usedCategoryIds,
    required this.onCategorySelected,
    this.onRemove,
  });

  final _EntryRow entry;
  final String currencyCode;
  final List<TransactionCategory> entryCategories;
  final Set<String> usedCategoryIds;
  final ValueChanged<TransactionCategory> onCategorySelected;
  final VoidCallback? onRemove;

  @override
  Widget build(BuildContext context) {
    final categories = entryCategories
        .where((c) => !usedCategoryIds.contains(c.id))
        .toList();

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      color: _kCardWhite,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: const BorderSide(color: _kBorderGrey),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Material(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    child: InkWell(
                      onTap: () => _pickCategory(context, categories),
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 12),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: _kBorderGrey),
                        ),
                        child: Row(
                          children: [
                            if (entry.category != null)
                              Text(
                                entry.category!.emoji,
                                style: const TextStyle(fontSize: 22),
                              ),
                            if (entry.category != null) const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                entry.category?.name ?? 'Choose category',
                                style: TextStyle(
                                  fontSize: 15,
                                  color: entry.category != null
                                      ? _kTextDark
                                      : Colors.grey[500],
                                ),
                              ),
                            ),
                            Icon(Icons.keyboard_arrow_down_rounded,
                                color: Colors.grey[600], size: 22),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                if (onRemove != null) ...[
                  const SizedBox(width: 8),
                  IconButton(
                    onPressed: onRemove,
                    icon: const Icon(Icons.remove_circle_outline_rounded),
                    color: Colors.grey[600],
                    style: IconButton.styleFrom(
                      minimumSize: const Size(40, 40),
                    ),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 10),
            TextField(
              controller: entry.amountController,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              decoration: InputDecoration(
                hintText: 'Budget amount ($currencyCode)',
                prefixText: '$currencyCode ',
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: _kBorderGrey),
                ),
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                isDense: true,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickCategory(
      BuildContext context, List<TransactionCategory> categories) async {
    if (categories.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('All categories are already added')),
      );
      return;
    }
    final media = MediaQuery.of(context);
    final c = await showModalBottomSheet<TransactionCategory>(
      context: context,
      backgroundColor: Colors.white,
      builder: (ctx) => SafeArea(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxHeight: media.size.height * 0.5),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Padding(
                padding: EdgeInsets.all(16),
                child: Text(
                  'Choose category',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Flexible(
                child: ListView.builder(
                  itemCount: categories.length,
                  itemBuilder: (_, i) {
                    final cat = categories[i];
                    return ListTile(
                      leading: Text(cat.emoji, style: const TextStyle(fontSize: 24)),
                      title: Text(cat.name),
                      onTap: () => Navigator.of(ctx).pop(cat),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
    if (c != null) onCategorySelected(c);
  }
}
