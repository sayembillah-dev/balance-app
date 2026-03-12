import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/dummy_data.dart';
import '../data/local_storage.dart';
import 'currency_provider.dart';
import '../utils/currency_format.dart';

// --- Accounts ---

/// Applies saved order to accounts. Default: oldest first (by id), so newest last.
List<AccountItem> _applyAccountOrder(List<AccountItem> accounts, List<String> orderIds) {
  if (accounts.isEmpty) return accounts;
  if (orderIds.isEmpty) {
    final sorted = List<AccountItem>.from(accounts);
    sorted.sort((a, b) => (int.tryParse(a.id) ?? 0).compareTo(int.tryParse(b.id) ?? 0));
    return sorted;
  }
  final byId = {for (final a in accounts) a.id: a};
  final ordered = <AccountItem>[];
  for (final id in orderIds) {
    if (byId.containsKey(id)) ordered.add(byId[id]!);
  }
  for (final a in accounts) {
    if (!orderIds.contains(a.id)) ordered.add(a);
  }
  return ordered;
}

class AccountsNotifier extends AsyncNotifier<List<AccountItem>> {
  @override
  Future<List<AccountItem>> build() async {
    final list = await loadAccounts();
    final orderIds = await loadAccountOrder();
    return _applyAccountOrder(list, orderIds);
  }

  Future<void> add(AccountItem a) async {
    final list = state.value ?? [];
    final newList = [...list, a];
    state = AsyncValue.data(newList);
    await saveAccounts(newList);
    await saveAccountOrder(newList.map((e) => e.id).toList());
  }

  Future<void> updateAccount(AccountItem a) async {
    final list = state.value ?? [];
    final i = list.indexWhere((e) => e.id == a.id);
    if (i < 0) return;
    final newList = [...list];
    newList[i] = a;
    state = AsyncValue.data(newList);
    await saveAccounts(state.value!);
  }

  Future<void> remove(String id) async {
    final list = state.value ?? [];
    final newList = list.where((e) => e.id != id).toList();
    state = AsyncValue.data(newList);
    await saveAccounts(newList);
    await saveAccountOrder(newList.map((e) => e.id).toList());
  }

  /// Reorder accounts (e.g. from ReorderableListView). Persists order for Accounts page and Dashboard.
  Future<void> reorder(int oldIndex, int newIndex) async {
    final list = state.value ?? [];
    if (oldIndex < 0 || oldIndex >= list.length || newIndex < 0 || newIndex >= list.length) return;
    if (oldIndex == newIndex) return;
    int insertIndex = newIndex;
    if (newIndex > oldIndex) insertIndex = newIndex - 1;
    final item = list[oldIndex];
    final newList = List<AccountItem>.from(list)..removeAt(oldIndex)..insert(insertIndex, item);
    state = AsyncValue.data(newList);
    await saveAccountOrder(newList.map((e) => e.id).toList());
  }

  String nextId() {
    final list = state.value ?? [];
    final ids = list.map((e) => int.tryParse(e.id) ?? 0);
    return ((ids.isEmpty ? 0 : ids.reduce((a, b) => a > b ? a : b)) + 1).toString();
  }
}

final accountsProvider =
    AsyncNotifierProvider<AccountsNotifier, List<AccountItem>>(AccountsNotifier.new);

// --- Transactions ---

class TransactionsNotifier extends AsyncNotifier<List<TransactionItem>> {
  @override
  Future<List<TransactionItem>> build() async => await loadTransactions();

  Future<void> add(TransactionItem t) async {
    final list = state.value ?? [];
    state = AsyncValue.data([t, ...list]);
    await saveTransactions(state.value!);
  }

  Future<void> removeById(String id) async {
    final list = state.value ?? [];
    final idsToRemove = <String>{id};
    TransactionItem? removed;
    for (final e in list) {
      if (e.id == id) { removed = e; break; }
    }
    if (removed?.transferPairId != null) {
      final pairId = removed!.transferPairId!;
      for (final t in list) {
        if (t.transferPairId == pairId && t.id != id) idsToRemove.add(t.id);
      }
    }
    state = AsyncValue.data(list.where((e) => !idsToRemove.contains(e.id)).toList());
    await saveTransactions(state.value!);
  }

  Future<void> replaceById(String id, TransactionItem t) async {
    final list = state.value ?? [];
    final i = list.indexWhere((e) => e.id == id);
    if (i < 0) return;
    final newList = [...list];
    newList[i] = t;
    state = AsyncValue.data(newList);
    await saveTransactions(state.value!);
  }

  String nextId() {
    final list = state.value ?? [];
    final ids = list.map((e) => int.tryParse(e.id) ?? 0);
    return ((ids.isEmpty ? 0 : ids.reduce((a, b) => a > b ? a : b)) + 1).toString();
  }
}

final transactionsProvider =
    AsyncNotifierProvider<TransactionsNotifier, List<TransactionItem>>(TransactionsNotifier.new);

// --- Presets ---

class PresetsNotifier extends AsyncNotifier<List<PresetItem>> {
  @override
  Future<List<PresetItem>> build() async => await loadPresets();

  Future<void> add(PresetItem p) async {
    final list = state.value ?? [];
    state = AsyncValue.data([...list, p]);
    await savePresets(state.value!);
  }

  Future<void> replace(String id, PresetItem p) async {
    final list = state.value ?? [];
    final i = list.indexWhere((e) => e.id == id);
    if (i < 0) return;
    final newList = [...list];
    newList[i] = p;
    state = AsyncValue.data(newList);
    await savePresets(state.value!);
  }

  Future<void> remove(String id) async {
    final list = state.value ?? [];
    state = AsyncValue.data(list.where((e) => e.id != id).toList());
    await savePresets(state.value!);
  }

  String nextId() {
    final list = state.value ?? [];
    int max = 0;
    for (final e in list) {
      final n = int.tryParse(e.id.replaceFirst('p', '')) ?? 0;
      if (n > max) max = n;
    }
    return 'p${max + 1}';
  }
}

final presetsProvider =
    AsyncNotifierProvider<PresetsNotifier, List<PresetItem>>(PresetsNotifier.new);

// --- Monthly budgets ---

class MonthlyBudgetsNotifier extends AsyncNotifier<List<MonthlyBudget>> {
  @override
  Future<List<MonthlyBudget>> build() async => await loadMonthlyBudgets();

  Future<void> add(MonthlyBudget b) async {
    final list = state.value ?? [];
    state = AsyncValue.data([...list, b]);
    await saveMonthlyBudgets(state.value!);
  }

  Future<void> replaceById(String id, MonthlyBudget b) async {
    final list = state.value ?? [];
    final i = list.indexWhere((e) => e.id == id);
    if (i < 0) return;
    final newList = [...list];
    newList[i] = b;
    state = AsyncValue.data(newList);
    await saveMonthlyBudgets(state.value!);
  }

  Future<void> remove(String id) async {
    final list = state.value ?? [];
    state = AsyncValue.data(list.where((e) => e.id != id).toList());
    await saveMonthlyBudgets(state.value!);
  }

  String nextId() {
    final list = state.value ?? [];
    int max = 0;
    for (final e in list) {
      final n = int.tryParse(e.id.replaceFirst('mb', '')) ?? 0;
      if (n > max) max = n;
    }
    return 'mb${max + 1}';
  }
}

final monthlyBudgetsProvider =
    AsyncNotifierProvider<MonthlyBudgetsNotifier, List<MonthlyBudget>>(MonthlyBudgetsNotifier.new);

/// Current month's budget (first match by month/year). Used for ensure tags and add-transaction.
final currentMonthBudgetProvider = Provider<MonthlyBudget?>((ref) {
  final list = ref.watch(monthlyBudgetsProvider).value ?? [];
  final now = DateTime.now();
  for (final b in list) {
    if (b.month == now.month && b.year == now.year) return b;
  }
  return null;
});

/// Tag-aware spending per budget entry. Keys are categoryId; only transactions with the budget's single tag count.
final budgetSpendingByEntryProvider =
    Provider.family<Map<String, double>, String>((ref, budgetId) {
  final budgets = ref.watch(monthlyBudgetsProvider).value ?? [];
  MonthlyBudget? budget;
  for (final b in budgets) {
    if (b.id == budgetId) {
      budget = b;
      break;
    }
  }
  if (budget == null) return {};
  final tagId = budget.budgetTagId;
  if (tagId == null) {
    return {for (final e in budget.entries) e.categoryId: 0.0};
  }
  final transactions = ref.watch(transactionsProvider).value ?? [];
  final categories = ref.watch(categoriesProvider).value ?? [];
  final result = <String, double>{};
  for (final e in budget.entries) {
    double spent = 0;
    for (final t in transactions) {
      if (t.type != TransactionType.deducted) continue;
      final dt = _parseTransactionDate(t.date);
      if (dt == null || dt.month != budget.month || dt.year != budget.year) continue;
      if (!t.tagIds.contains(tagId)) continue;
      final categoryId = _categoryNameToCategoryId(t.categoryName, categories);
      if (categoryId != e.categoryId) continue;
      final amt = _parseAmount(t.amount);
      spent += amt < 0 ? -amt : amt;
    }
    result[e.categoryId] = spent;
  }
  return result;
});

/// Ensures the budget has one "Budget" tag (current month only). Recreates if missing. Call after save or when opening budget detail.
Future<void> ensureBudgetTags(WidgetRef ref, MonthlyBudget budget) async {
  final now = DateTime.now();
  if (budget.month != now.month || budget.year != now.year) return;
  final tagsNotifier = ref.read(tagsProvider.notifier);
  final budgetsNotifier = ref.read(monthlyBudgetsProvider.notifier);
  final tags = ref.read(tagsProvider).value ?? [];
  final tagIds = tags.map((e) => e.id).toSet();
  String? budgetTagId = budget.budgetTagId;
  if (budgetTagId == null || !tagIds.contains(budgetTagId)) {
    budgetTagId = tagsNotifier.nextId();
    final tag = TagItem(
      id: budgetTagId,
      name: 'Budget',
      budgetId: budget.id,
    );
    await tagsNotifier.add(tag);
    final newBudget = MonthlyBudget(
      id: budget.id,
      month: budget.month,
      year: budget.year,
      regularIncome: budget.regularIncome,
      entries: budget.entries,
      budgetTagId: budgetTagId,
    );
    await budgetsNotifier.replaceById(budget.id, newBudget);
  }
  // Migrate away from old per-entry tags: delete any entry.tagId tags and clear them
  final hasOldEntryTags = budget.entries.any((e) => e.tagId != null);
  if (hasOldEntryTags) {
    for (final e in budget.entries) {
      if (e.tagId != null) await tagsNotifier.remove(e.tagId!);
    }
    final newEntries = budget.entries.map((e) => BudgetCategoryEntry(
      categoryId: e.categoryId,
      categoryName: e.categoryName,
      emoji: e.emoji,
      budgetAmount: e.budgetAmount,
      tagId: null,
    )).toList();
    final newBudget = MonthlyBudget(
      id: budget.id,
      month: budget.month,
      year: budget.year,
      regularIncome: budget.regularIncome,
      entries: newEntries,
      budgetTagId: budget.budgetTagId ?? budgetTagId,
    );
    await budgetsNotifier.replaceById(budget.id, newBudget);
  }
}

/// Deletes the budget tag for past-month budgets. Call when budgets screen loads.
Future<void> cleanupPastMonthBudgetTags(WidgetRef ref) async {
  final now = DateTime.now();
  final budgets = ref.read(monthlyBudgetsProvider).value ?? [];
  final tagsNotifier = ref.read(tagsProvider.notifier);
  final budgetsNotifier = ref.read(monthlyBudgetsProvider.notifier);
  for (final b in budgets) {
    if (b.year < now.year || (b.year == now.year && b.month < now.month)) {
      if (b.budgetTagId == null) continue;
      await tagsNotifier.remove(b.budgetTagId!);
      final newBudget = MonthlyBudget(
        id: b.id,
        month: b.month,
        year: b.year,
        regularIncome: b.regularIncome,
        entries: b.entries,
        budgetTagId: null,
      );
      await budgetsNotifier.replaceById(b.id, newBudget);
    }
  }
}

// --- Receivables & Payables ---

class ReceivablesPayablesNotifier
    extends AsyncNotifier<List<ReceivablePayableItem>> {
  @override
  Future<List<ReceivablePayableItem>> build() async {
    return await loadReceivablesPayables();
  }

  Future<void> add(ReceivablePayableItem item) async {
    final list = state.value ?? [];
    final newList = [...list, item];
    state = AsyncValue.data(newList);
    await saveReceivablesPayables(newList);
  }

  Future<void> replaceById(String id, ReceivablePayableItem item) async {
    final list = state.value ?? [];
    final i = list.indexWhere((e) => e.id == id);
    if (i < 0) return;
    final newList = [...list];
    newList[i] = item;
    state = AsyncValue.data(newList);
    await saveReceivablesPayables(newList);
  }

  Future<void> removeById(String id) async {
    final list = state.value ?? [];
    final newList = list.where((e) => e.id != id).toList();
    state = AsyncValue.data(newList);
    await saveReceivablesPayables(newList);
  }

  Future<void> toggleStatus(String id) async {
    final list = state.value ?? [];
    final i = list.indexWhere((e) => e.id == id);
    if (i < 0) return;
    final current = list[i];
    final now = DateTime.now();
    final nextStatus = current.status == ReceivablePayableStatus.pending
        ? ReceivablePayableStatus.completed
        : ReceivablePayableStatus.pending;
    final updated = current.copyWith(
      status: nextStatus,
      completedAt: nextStatus == ReceivablePayableStatus.completed ? now : null,
    );
    final newList = [...list];
    newList[i] = updated;
    state = AsyncValue.data(newList);
    await saveReceivablesPayables(newList);
  }

  String nextId() {
    final list = state.value ?? [];
    final ids = list.map((e) => int.tryParse(e.id) ?? 0);
    return ((ids.isEmpty ? 0 : ids.reduce((a, b) => a > b ? a : b)) + 1)
        .toString();
  }
}

final receivablesPayablesProvider = AsyncNotifierProvider<
    ReceivablesPayablesNotifier,
    List<ReceivablePayableItem>>(ReceivablesPayablesNotifier.new);

// --- Notes ---

class NotesNotifier extends AsyncNotifier<List<NoteItem>> {
  @override
  Future<List<NoteItem>> build() async {
    final list = await loadNotes();
    return _sorted(list);
  }

  List<NoteItem> _sorted(List<NoteItem> list) {
    final notes = [...list];
    notes.sort((a, b) {
      if (a.isPinned != b.isPinned) {
        return a.isPinned ? -1 : 1;
      }
      return b.updatedAt.compareTo(a.updatedAt);
    });
    return notes;
  }

  Future<void> add(NoteItem note) async {
    final list = state.value ?? [];
    final newList = _sorted([...list, note]);
    state = AsyncValue.data(newList);
    await saveNotes(newList);
  }

  Future<void> replaceById(String id, NoteItem note) async {
    final list = state.value ?? [];
    final i = list.indexWhere((e) => e.id == id);
    if (i < 0) return;
    final newList = [...list];
    newList[i] = note;
    final sorted = _sorted(newList);
    state = AsyncValue.data(sorted);
    await saveNotes(sorted);
  }

  Future<void> removeById(String id) async {
    final list = state.value ?? [];
    final newList = list.where((e) => e.id != id).toList();
    final sorted = _sorted(newList);
    state = AsyncValue.data(sorted);
    await saveNotes(sorted);
  }

  Future<void> togglePinned(String id) async {
    final list = state.value ?? [];
    final i = list.indexWhere((e) => e.id == id);
    if (i < 0) return;
    final current = list[i];
    final updated = current.copyWith(
      isPinned: !current.isPinned,
      updatedAt: DateTime.now(),
    );
    final newList = [...list];
    newList[i] = updated;
    final sorted = _sorted(newList);
    state = AsyncValue.data(sorted);
    await saveNotes(sorted);
  }

  String nextId() {
    final list = state.value ?? [];
    final ids = list.map((e) => int.tryParse(e.id) ?? 0);
    return ((ids.isEmpty ? 0 : ids.reduce((a, b) => a > b ? a : b)) + 1)
        .toString();
  }
}

final notesProvider =
    AsyncNotifierProvider<NotesNotifier, List<NoteItem>>(NotesNotifier.new);

// --- Categories ---

List<TransactionCategory> _seedCategories() {
  return defaultTransactionCategories.map((c) {
    return TransactionCategory(
      id: c.id,
      name: c.name,
      emoji: c.emoji,
      isUserCreated: false,
      subcategories: c.subcategories.map((s) => SubcategoryItem(
        name: s.name,
        emoji: s.emoji,
        isHidden: false,
        isUserCreated: false,
      )).toList(),
    );
  }).toList();
}

class CategoriesNotifier extends AsyncNotifier<List<TransactionCategory>> {
  @override
  Future<List<TransactionCategory>> build() async {
    final list = await loadCategories();
    if (list.isEmpty) {
      final seed = _seedCategories();
      await saveCategories(seed);
      return seed;
    }
    return list;
  }

  Future<void> add(TransactionCategory c) async {
    final list = state.value ?? [];
    state = AsyncValue.data([...list, c]);
    await saveCategories(state.value!);
  }

  Future<void> replaceAt(int index, TransactionCategory c) async {
    final list = state.value ?? [];
    if (index < 0 || index >= list.length) return;
    final newList = [...list];
    newList[index] = c;
    state = AsyncValue.data(newList);
    await saveCategories(state.value!);
  }

  Future<void> replaceById(String id, TransactionCategory c) async {
    final list = state.value ?? [];
    final i = list.indexWhere((e) => e.id == id);
    if (i < 0) return;
    final newList = [...list];
    newList[i] = c;
    state = AsyncValue.data(newList);
    await saveCategories(state.value!);
  }

  Future<void> removeUserCategory(String id) async {
    final list = state.value ?? [];
    state = AsyncValue.data(list.where((e) => !(e.id == id && e.isUserCreated)).toList());
    await saveCategories(state.value!);
  }

  Future<void> reorder(int from, int to) async {
    final list = state.value ?? [];
    if (from < 0 || from >= list.length || to < 0 || to >= list.length) return;
    final item = list[from];
    final newList = [...list];
    newList.removeAt(from);
    newList.insert(to, item);
    state = AsyncValue.data(newList);
    await saveCategories(state.value!);
  }

  String nextUserCategoryId() {
    final list = state.value ?? [];
    final existing = list.where((c) => c.isUserCreated).map((c) => c.id).toSet();
    int n = 1;
    while (existing.contains('u$n')) { n++; }
    return 'u$n';
  }

  String nextUserSubcategoryId() {
    final list = state.value ?? [];
    String? max;
    for (final c in list) {
      for (final s in c.subcategories) {
        if (s.id != null) {
          final num = int.tryParse(s.id!.replaceFirst('s', '')) ?? 0;
          if (max == null || (int.tryParse(max.replaceFirst('s', '')) ?? 0) < num) max = s.id;
        }
      }
    }
    final next = (int.tryParse(max?.replaceFirst('s', '') ?? '0') ?? 0) + 1;
    return 's$next';
  }
}

final categoriesProvider =
    AsyncNotifierProvider<CategoriesNotifier, List<TransactionCategory>>(CategoriesNotifier.new);

/// Categories for picker (hidden subcategories filtered out).
final categoriesForPickerProvider = Provider<List<TransactionCategory>>((ref) {
  final asyncCategories = ref.watch(categoriesProvider);
  return asyncCategories.when(
    data: (list) => list.map((c) => c.copyWith(
      subcategories: c.subcategories.where((s) => !s.isHidden).toList(),
    )).toList(),
    loading: () => [],
    error: (_, Object? _) => [],
  );
});

// --- Tags ---

class TagsNotifier extends AsyncNotifier<List<TagItem>> {
  @override
  Future<List<TagItem>> build() async => await loadTags();

  Future<void> add(TagItem tag) async {
    final list = state.value ?? [];
    state = AsyncValue.data([...list, tag]);
    await saveTags(state.value!);
  }

  Future<void> replaceById(String id, TagItem tag) async {
    final list = state.value ?? [];
    final i = list.indexWhere((e) => e.id == id);
    if (i < 0) return;
    final newList = [...list];
    newList[i] = tag;
    state = AsyncValue.data(newList);
    await saveTags(state.value!);
  }

  Future<void> remove(String id) async {
    final list = state.value ?? [];
    state = AsyncValue.data(list.where((e) => e.id != id).toList());
    await saveTags(state.value!);
    // Keep orphan references: transactions retain the tag id in tagIds.
  }

  String nextId() {
    final list = state.value ?? [];
    final ids = list.map((e) => int.tryParse(e.id) ?? 0);
    return ((ids.isEmpty ? 0 : ids.reduce((a, b) => a > b ? a : b)) + 1).toString();
  }
}

final tagsProvider =
    AsyncNotifierProvider<TagsNotifier, List<TagItem>>(TagsNotifier.new);

// --- Balance (computed from accounts + transactions) ---

double _parseAmount(String amount) {
  final cleaned = amount.replaceAll(RegExp(r'[^\d.-]'), '');
  if (cleaned.isEmpty) return 0;
  final neg = amount.trimLeft().startsWith('-');
  final v = double.tryParse(cleaned) ?? 0;
  return neg ? -v : v;
}

/// Returns the effective amount for balance/totals: sign from transaction type so
/// deducted = negative, added = positive, transferred = use stored sign (each leg stored correctly).
double getTransactionEffectiveAmount(TransactionItem t) {
  final parsed = _parseAmount(t.amount);
  final abs = parsed.abs();
  switch (t.type) {
    case TransactionType.deducted:
      return -abs;
    case TransactionType.added:
      return abs;
    case TransactionType.transferred:
      return parsed; // each leg stored with correct sign
  }
}

final balanceProvider = Provider<String>((ref) {
  final accountsAsync = ref.watch(accountsProvider);
  final transactionsAsync = ref.watch(transactionsProvider);
  final currencyCode = ref.watch(selectedCurrencyCodeProvider);
  final accountsList = accountsAsync.value ?? <AccountItem>[];
  final transactionsList = transactionsAsync.value ?? <TransactionItem>[];
  double total = 0;
  for (final a in accountsList) {
    total += a.initialBalance;
  }
  for (final t in transactionsList) {
    total += getTransactionEffectiveAmount(t);
  }
  return formatAmountWithCurrency(total, currencyCode);
});

/// Raw numeric balance value (same as [balanceProvider] but without formatting).
final balanceValueProvider = Provider<double>((ref) {
  final accountsAsync = ref.watch(accountsProvider);
  final transactionsAsync = ref.watch(transactionsProvider);
  final accountsList = accountsAsync.value ?? <AccountItem>[];
  final transactionsList = transactionsAsync.value ?? <TransactionItem>[];
  double total = 0;
  for (final a in accountsList) {
    total += a.initialBalance;
  }
  for (final t in transactionsList) {
    total += getTransactionEffectiveAmount(t);
  }
  return total;
});

// --- Account monthly totals (monthExpense / monthIncome computed for current month) ---

class AccountTotals {
  const AccountTotals({required this.monthExpense, required this.monthIncome});
  final String monthExpense;
  final String monthIncome;
}

final accountTotalsProvider = Provider<Map<String, AccountTotals>>((ref) {
  final accountsAsync = ref.watch(accountsProvider);
  final transactionsAsync = ref.watch(transactionsProvider);
  final currencyCode = ref.watch(selectedCurrencyCodeProvider);
  final accountsList = accountsAsync.value ?? <AccountItem>[];
  final transactionsList = transactionsAsync.value ?? <TransactionItem>[];
  final now = DateTime.now();
  final result = <String, AccountTotals>{};
  for (final a in accountsList) {
    double expense = 0;
    double income = 0;
    for (final t in transactionsList) {
      if (t.accountId != a.id) { continue; }
      final dt = _parseTransactionDate(t.date);
      if (dt == null || dt.year != now.year || dt.month != now.month) { continue; }
      final amt = getTransactionEffectiveAmount(t);
      if (amt < 0) {
        expense += -amt;
      } else {
        income += amt;
      }
    }
    result[a.id] = AccountTotals(
      monthExpense: formatAmountWithCurrency(expense, currencyCode),
      monthIncome: formatAmountWithCurrency(income, currencyCode),
    );
  }
  return result;
});

/// Spending by category for a given month/year (only type == deducted).
/// Keys are category IDs; values are total spent (positive). Used by budget detail.
String? _categoryNameToCategoryId(String name, List<TransactionCategory> categories) {
  final normalized = name.trim().toLowerCase();
  if (normalized.isEmpty) return null;
  for (final c in categories) {
    if (c.name.trim().toLowerCase() == normalized) return c.id;
    for (final s in c.subcategories) {
      if (s.name.trim().toLowerCase() == normalized) return c.id;
    }
  }
  return null;
}

final monthlySpendingByCategoryProvider =
    Provider.family<Map<String, double>, (int month, int year)>((ref, key) {
  final month = key.$1;
  final year = key.$2;
  final transactions = ref.watch(transactionsProvider).value ?? [];
  // Use full category list (including hidden subcategories) so spending is attributed correctly
  final categories = ref.watch(categoriesProvider).value ?? [];
  final result = <String, double>{};
  for (final t in transactions) {
    if (t.type != TransactionType.deducted) continue;
    final dt = _parseTransactionDate(t.date);
    if (dt == null || dt.month != month || dt.year != year) continue;
    final amt = _parseAmount(t.amount);
    final spent = amt < 0 ? -amt : amt;
    final categoryId = _categoryNameToCategoryId(t.categoryName, categories);
    if (categoryId != null) {
      result[categoryId] = (result[categoryId] ?? 0) + spent;
    }
  }
  return result;
});

DateTime? _parseTransactionDate(String dateStr) {
  const months = {'Jan': 1, 'Feb': 2, 'Mar': 3, 'Apr': 4, 'May': 5, 'Jun': 6, 'Jul': 7, 'Aug': 8, 'Sep': 9, 'Oct': 10, 'Nov': 11, 'Dec': 12};
  final parts = dateStr.trim().split(RegExp(r'\s+'));
  if (parts.length < 2) return null;
  final m = months[parts[0]];
  final d = int.tryParse(parts[1]);
  if (m == null || d == null) return null;
  final year = parts.length >= 3 ? (int.tryParse(parts[2]) ?? DateTime.now().year) : DateTime.now().year;
  return DateTime(year, m, d);
}
