# Core Features Audit — Balance App

## Summary

| Area | Status | Notes |
|------|--------|--------|
| **Dashboard** | ✅ Functional | Balance, accounts, recent transactions, FAB add transaction |
| **Transactions** | ⚠️ Partial | Add, duplicate, delete work; **Update (edit) does not** |
| **Add Transaction** | ⚠️ Partial | **Edit flow not wired**; duplicate works |
| **Accounts** | ✅ Functional | List, add, edit, delete, detail with transactions |
| **Categories** | ✅ Functional | List, add/edit, reorder, hide, detail |
| **Presets** | ✅ Functional | Add, edit, delete; save from transaction |
| **Budgets** | ⚠️ Partial | Add works; **no edit/delete** for monthly budgets |
| **Settings** | ✅ Functional | Currency picker persisted |
| **Persistence** | ⚠️ Partial | **Transaction date has no year** → wrong for past/future years |
| **Server / Sign-in** | 🔲 Placeholder | Try mode only; sign-in not implemented |

---

## 1. Edit Transaction — **NOT IMPLEMENTED** (fixed in code)

- **Transaction detail** (sheet): "Update" calls `Navigator.pushNamed('/add-transaction')` with **no arguments**.
- **AddTransactionScreen** only has `duplicateFrom`; no `editFrom` or `transactionToEdit`.
- **TransactionsNotifier** has `add` and `removeById` only — **no `update`/`replace`**.
- **Result**: User taps "Update" and gets an empty form; saving creates a **new** transaction instead of updating the existing one.

**Fix**: Add `TransactionsNotifier.replaceById(id, item)`, `AddTransactionScreen(editFrom: item)`, and in `_saveTransaction` call replaceById when editing; wire "Update" to push `AddTransactionScreen(editFrom: item)`. (Done.)

---

## 2. Transaction Date — **YEAR MISSING** (fixed in code)

- **Stored format**: `"Jan 15"` (month + day only) in `add_transaction_screen.dart`.
- **Parsing**: `_parseTransactionDate` in `app_providers.dart`, `_parseDate` in `account_detail_screen.dart` and `transactions_screen.dart` use `DateTime.now().year`.
- **Result**: All dates are treated as **current year**. Historical or future-year transactions are wrong (e.g. "Dec 25" is always this year’s Dec 25).

**Fix**: Store date with year (e.g. `"Jan 15 2024"`), and parse all three parts in every `_parseDate` / `_parseTransactionDate` usage. (Done; old "Jan 15" data still parses with current year.)

---

## 3. Monthly Budgets — **NO EDIT/DELETE**

- **MonthlyBudgetsNotifier**: Only `add()` and `nextId()`; **no `update` or `remove`**.
- **MonthlyBudgetDetailScreen**: Read-only; no edit or delete actions.
- **Result**: Users can create monthly budgets but cannot change or remove them.

**Recommendation**: Add `replaceById(id, MonthlyBudget)` and `remove(id)` to the notifier; add Edit/Delete in budget detail (or list) and wire to new flows. (Provider methods added; UI can be added when needed.)

---

## 4. Other Checks

- **Navigation**: Named routes and drawer are consistent. Transaction detail is shown via **bottom sheet** everywhere (dashboard, transactions, account detail); full-screen `/transaction-detail` route exists but is not used with arguments (would crash if opened without arguments).
- **Balance / account totals**: Computed from accounts + transactions; correct for current-month filtering. Date bug above affects which month is “current” when parsing.
- **Categories**: Hidden subcategories filtered in picker; reorder and remove user categories work.
- **Presets**: Full CRUD; save from transaction works.
- **Currency**: Persisted; used in formatting across the app.
- **No TODOs/FIXMEs** in `lib/` for app logic.

---

## 5. Implemented Fixes (in code)

1. **Edit transaction**: `TransactionsNotifier.replaceById`, `AddTransactionScreen(editFrom)`, `_applyEdit`, `_saveTransaction` update path, and "Update" (sheet + full-screen) passing `editFrom`. App bar title shows "Edit Transaction" when editing.
2. **Transaction date with year**: Stored as `"Jan 15 2024"`; all parsers (`app_providers`, `account_detail_screen`, `transactions_screen`) accept 3-part date with fallback to current year for legacy "Jan 15" data.
3. **Monthly budgets**: Provider has `replaceById` and `remove` so edit/delete UI can be wired when needed.
