/// Shared models and JSON serialization for Try mode persistence.
library;

enum TransactionType { deducted, added, transferred }

extension TransactionTypeJson on TransactionType {
  static TransactionType fromString(String s) {
    switch (s) {
      case 'deducted':
        return TransactionType.deducted;
      case 'added':
        return TransactionType.added;
      case 'transferred':
        return TransactionType.transferred;
      default:
        return TransactionType.deducted;
    }
  }
  String toJson() => name;
}

class SubcategoryItem {
  const SubcategoryItem({
    required this.name,
    required this.emoji,
    this.id,
    this.isHidden = false,
    this.isUserCreated = false,
  });
  final String name;
  final String emoji;
  final String? id;
  final bool isHidden;
  final bool isUserCreated;

  SubcategoryItem copyWith({
    String? name,
    String? emoji,
    String? id,
    bool? isHidden,
    bool? isUserCreated,
  }) {
    return SubcategoryItem(
      name: name ?? this.name,
      emoji: emoji ?? this.emoji,
      id: id ?? this.id,
      isHidden: isHidden ?? this.isHidden,
      isUserCreated: isUserCreated ?? this.isUserCreated,
    );
  }

  Map<String, dynamic> toJson() => {
        'name': name,
        'emoji': emoji,
        'id': id,
        'isHidden': isHidden,
        'isUserCreated': isUserCreated,
      };

  static SubcategoryItem fromJson(Map<String, dynamic> json) {
    return SubcategoryItem(
      name: json['name'] as String,
      emoji: json['emoji'] as String,
      id: json['id'] as String?,
      isHidden: json['isHidden'] as bool? ?? false,
      isUserCreated: json['isUserCreated'] as bool? ?? false,
    );
  }
}

class TransactionCategory {
  const TransactionCategory({
    required this.id,
    required this.name,
    required this.emoji,
    required this.subcategories,
    this.isUserCreated = false,
  });
  final String id;
  final String name;
  final String emoji;
  final List<SubcategoryItem> subcategories;
  final bool isUserCreated;

  TransactionCategory copyWith({
    String? id,
    String? name,
    String? emoji,
    List<SubcategoryItem>? subcategories,
    bool? isUserCreated,
  }) {
    return TransactionCategory(
      id: id ?? this.id,
      name: name ?? this.name,
      emoji: emoji ?? this.emoji,
      subcategories: subcategories ?? this.subcategories,
      isUserCreated: isUserCreated ?? this.isUserCreated,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'emoji': emoji,
        'subcategories': subcategories.map((s) => s.toJson()).toList(),
        'isUserCreated': isUserCreated,
      };

  static TransactionCategory fromJson(Map<String, dynamic> json) {
    return TransactionCategory(
      id: json['id'] as String,
      name: json['name'] as String,
      emoji: json['emoji'] as String,
      subcategories: (json['subcategories'] as List<dynamic>)
          .map((e) => SubcategoryItem.fromJson(e as Map<String, dynamic>))
          .toList(),
      isUserCreated: json['isUserCreated'] as bool? ?? false,
    );
  }
}

class BudgetCategoryEntry {
  const BudgetCategoryEntry({
    required this.categoryId,
    required this.categoryName,
    required this.emoji,
    required this.budgetAmount,
  });
  final String categoryId;
  final String categoryName;
  final String emoji;
  final double budgetAmount;

  Map<String, dynamic> toJson() => {
        'categoryId': categoryId,
        'categoryName': categoryName,
        'emoji': emoji,
        'budgetAmount': budgetAmount,
      };

  static BudgetCategoryEntry fromJson(Map<String, dynamic> json) {
    return BudgetCategoryEntry(
      categoryId: json['categoryId'] as String,
      categoryName: json['categoryName'] as String,
      emoji: json['emoji'] as String,
      budgetAmount: (json['budgetAmount'] as num).toDouble(),
    );
  }
}

class MonthlyBudget {
  const MonthlyBudget({
    required this.id,
    required this.month,
    required this.year,
    required this.regularIncome,
    required this.entries,
  });
  final String id;
  final int month;
  final int year;
  final double regularIncome;
  final List<BudgetCategoryEntry> entries;

  double get totalBudgeted =>
      entries.fold(0.0, (sum, e) => sum + e.budgetAmount);
  double get remaining => regularIncome - totalBudgeted;

  static const List<String> monthNames = [
    'January', 'February', 'March', 'April', 'May', 'June',
    'July', 'August', 'September', 'October', 'November', 'December',
  ];
  String get monthYearLabel => '${monthNames[month - 1]} $year';

  Map<String, dynamic> toJson() => {
        'id': id,
        'month': month,
        'year': year,
        'regularIncome': regularIncome,
        'entries': entries.map((e) => e.toJson()).toList(),
      };

  static MonthlyBudget fromJson(Map<String, dynamic> json) {
    return MonthlyBudget(
      id: json['id'] as String,
      month: json['month'] as int,
      year: json['year'] as int,
      regularIncome: (json['regularIncome'] as num).toDouble(),
      entries: (json['entries'] as List<dynamic>)
          .map((e) => BudgetCategoryEntry.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}

class AccountItem {
  const AccountItem({
    required this.id,
    required this.name,
    required this.accountType,
    required this.monthExpense,
    required this.monthIncome,
    required this.emojis,
    this.initialBalance = 0,
  });
  final String id;
  final String name;
  final String accountType;
  final String monthExpense;
  final String monthIncome;
  final String emojis;
  final double initialBalance;

  AccountItem copyWith({
    String? id,
    String? name,
    String? accountType,
    String? monthExpense,
    String? monthIncome,
    String? emojis,
    double? initialBalance,
  }) {
    return AccountItem(
      id: id ?? this.id,
      name: name ?? this.name,
      accountType: accountType ?? this.accountType,
      monthExpense: monthExpense ?? this.monthExpense,
      monthIncome: monthIncome ?? this.monthIncome,
      emojis: emojis ?? this.emojis,
      initialBalance: initialBalance ?? this.initialBalance,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'accountType': accountType,
        'monthExpense': monthExpense,
        'monthIncome': monthIncome,
        'emojis': emojis,
        'initialBalance': initialBalance,
      };

  static AccountItem fromJson(Map<String, dynamic> json) {
    return AccountItem(
      id: json['id'] as String,
      name: json['name'] as String,
      accountType: json['accountType'] as String,
      monthExpense: json['monthExpense'] as String,
      monthIncome: json['monthIncome'] as String,
      emojis: json['emojis'] as String,
      initialBalance: (json['initialBalance'] as num?)?.toDouble() ?? 0,
    );
  }
}

class TransactionItem {
  const TransactionItem({
    required this.id,
    required this.categoryName,
    this.description,
    required this.emoji,
    required this.amount,
    required this.type,
    required this.date,
    required this.time,
    this.accountId,
  });
  final String id;
  final String categoryName;
  final String? description;
  final String emoji;
  final String amount;
  final TransactionType type;
  final String date;
  final String time;
  final String? accountId;

  Map<String, dynamic> toJson() => {
        'id': id,
        'categoryName': categoryName,
        'description': description,
        'emoji': emoji,
        'amount': amount,
        'type': type.toJson(),
        'date': date,
        'time': time,
        'accountId': accountId,
      };

  static TransactionItem fromJson(Map<String, dynamic> json) {
    return TransactionItem(
      id: json['id'] as String,
      categoryName: json['categoryName'] as String,
      description: json['description'] as String?,
      emoji: json['emoji'] as String,
      amount: json['amount'] as String,
      type: TransactionTypeJson.fromString(json['type'] as String),
      date: json['date'] as String,
      time: json['time'] as String,
      accountId: json['accountId'] as String?,
    );
  }
}

class PresetItem {
  const PresetItem({
    required this.id,
    required this.name,
    required this.transactionType,
    this.accountId,
    this.fromAccountId,
    this.toAccountId,
    this.categoryId,
    this.subcategoryName,
    this.description,
    this.includeAmount = false,
    this.amount,
  });
  final String id;
  final String name;
  final TransactionType transactionType;
  final String? accountId;
  final String? fromAccountId;
  final String? toAccountId;
  final String? categoryId;
  final String? subcategoryName;
  final String? description;
  final bool includeAmount;
  final String? amount;

  PresetItem copyWith({
    String? id,
    String? name,
    TransactionType? transactionType,
    String? accountId,
    String? fromAccountId,
    String? toAccountId,
    String? categoryId,
    String? subcategoryName,
    String? description,
    bool? includeAmount,
    String? amount,
  }) {
    return PresetItem(
      id: id ?? this.id,
      name: name ?? this.name,
      transactionType: transactionType ?? this.transactionType,
      accountId: accountId ?? this.accountId,
      fromAccountId: fromAccountId ?? this.fromAccountId,
      toAccountId: toAccountId ?? this.toAccountId,
      categoryId: categoryId ?? this.categoryId,
      subcategoryName: subcategoryName ?? this.subcategoryName,
      description: description ?? this.description,
      includeAmount: includeAmount ?? this.includeAmount,
      amount: amount ?? this.amount,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'transactionType': transactionType.toJson(),
        'accountId': accountId,
        'fromAccountId': fromAccountId,
        'toAccountId': toAccountId,
        'categoryId': categoryId,
        'subcategoryName': subcategoryName,
        'description': description,
        'includeAmount': includeAmount,
        'amount': amount,
      };

  static PresetItem fromJson(Map<String, dynamic> json) {
    return PresetItem(
      id: json['id'] as String,
      name: json['name'] as String,
      transactionType: TransactionTypeJson.fromString(json['transactionType'] as String),
      accountId: json['accountId'] as String?,
      fromAccountId: json['fromAccountId'] as String?,
      toAccountId: json['toAccountId'] as String?,
      categoryId: json['categoryId'] as String?,
      subcategoryName: json['subcategoryName'] as String?,
      description: json['description'] as String?,
      includeAmount: json['includeAmount'] as bool? ?? false,
      amount: json['amount'] as String?,
    );
  }
}
