import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/dummy_data.dart';
import '../providers/app_providers.dart';
import '../providers/currency_provider.dart';
import '../utils/currency_format.dart';
import 'tags_screen.dart';

enum AddTransactionTab { spend, income, transfer, preset }

// Dashboard-matching palette: black, white, grey
const Color _kBgGrey = Color(0xFFF2F2F7);
const Color _kCardWhite = Color(0xFFFAFAFA);
const Color _kTextDark = Color(0xFF1C1C1E);
const Color _kBorderGrey = Color(0xFFE5E5EA);

/// Sentinels for "clear" action in category/subcategory picker sheets.
class _ClearCategoryMarker {}

class _ClearSubcategoryMarker {}

/// Add Transaction screen: 4 tabs, amount/time, account, category, subcategory,
/// description, date/time, swipe to save. Uses app theme; responsive.
/// If [duplicateFrom] is set, form is pre-filled from that transaction with current date.
/// If [editFrom] is set, form is pre-filled and saving updates that transaction instead of adding.
class AddTransactionScreen extends ConsumerStatefulWidget {
  const AddTransactionScreen({super.key, this.duplicateFrom, this.editFrom});

  final TransactionItem? duplicateFrom;
  final TransactionItem? editFrom;

  @override
  ConsumerState<AddTransactionScreen> createState() =>
      _AddTransactionScreenState();
}

class _AddTransactionScreenState extends ConsumerState<AddTransactionScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;
  static const List<String> _tabLabels = [
    'Spend',
    'Income',
    'Transfer',
    'Preset',
  ];

  final _amountController = TextEditingController(text: '0');
  final _descriptionController = TextEditingController();

  AccountItem? _selectedAccount;
  AccountItem? _selectedFromAccount;
  AccountItem? _selectedToAccount;
  TransactionCategory? _selectedCategory;
  SubcategoryItem? _selectedSubcategory;
  DateTime _selectedDate = DateTime.now();
  TimeOfDay _selectedTime = TimeOfDay.now();
  List<String> _selectedTagIds = [];
  bool _duplicateApplied = false;
  bool _editApplied = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _amountController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null && mounted) setState(() => _selectedDate = picked);
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime,
    );
    if (picked != null && mounted) setState(() => _selectedTime = picked);
  }

  Future<void> _saveTransaction() async {
    final tabIndex = _tabController.index;
    if (tabIndex == 3) {
      // Preset tab: presets only pre-fill; user must use Spend/Income/Transfer to save
      Navigator.of(context).pop();
      return;
    }
    final amountStr = _amountController.text.trim().replaceAll(
      RegExp(r'[^\d.]'),
      '',
    );
    final amount = double.tryParse(amountStr) ?? 0;
    if (amount <= 0) {
      Navigator.of(context).pop();
      return;
    }
    final isTransfer = tabIndex == 2;
    if (isTransfer) {
      if (_selectedFromAccount == null || _selectedToAccount == null) {
        Navigator.of(context).pop();
        return;
      }
    } else {
      if (_selectedAccount == null || _selectedCategory == null) {
        Navigator.of(context).pop();
        return;
      }
    }
    final currencyCode = ref.read(selectedCurrencyCodeProvider);
    final categoryName = isTransfer
        ? 'Transfer'
        : (_selectedSubcategory?.name ??
            _selectedCategory?.name ??
            'Uncategorized');
    final emoji = isTransfer
        ? '💸'
        : (_selectedSubcategory?.emoji ?? _selectedCategory?.emoji ?? '📌');
    TransactionType type;
    String amountDisplay;
    String? accountId;
    switch (tabIndex) {
      case 0:
        type = TransactionType.deducted;
        amountDisplay = formatAmountWithCurrency(-amount, currencyCode);
        accountId = _selectedAccount?.id;
        break;
      case 1:
        type = TransactionType.added;
        amountDisplay = formatAmountWithCurrency(amount, currencyCode);
        accountId = _selectedAccount?.id;
        break;
      case 2:
        type = TransactionType.transferred;
        amountDisplay = formatAmountWithCurrency(amount, currencyCode);
        accountId = _selectedToAccount?.id;
        break;
      default:
        type = TransactionType.deducted;
        amountDisplay = formatAmountWithCurrency(-amount, currencyCode);
        accountId = _selectedAccount?.id;
    }
    const monthNames = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    final dateStr =
        '${monthNames[_selectedDate.month - 1]} ${_selectedDate.day} ${_selectedDate.year}';
    final hour = _selectedTime.hourOfPeriod == 0
        ? 12
        : _selectedTime.hourOfPeriod;
    final minute = _selectedTime.minute.toString().padLeft(2, '0');
    final period = _selectedTime.period == DayPeriod.am ? 'AM' : 'PM';
    final timeStr = '$hour:$minute $period';
    final description = _descriptionController.text.trim().isEmpty
        ? null
        : _descriptionController.text.trim();
    final notifier = ref.read(transactionsProvider.notifier);
    if (isTransfer) {
      final list = ref.read(transactionsProvider).value ?? [];
      final editingTransfer =
          widget.editFrom != null && widget.editFrom!.transferPairId != null;
      TransactionItem? otherLeg;
      if (editingTransfer) {
        for (final t in list) {
          if (t.transferPairId == widget.editFrom!.transferPairId &&
              t.id != widget.editFrom!.id) {
            otherLeg = t;
            break;
          }
        }
      }
      if (editingTransfer && otherLeg != null) {
        // Edit transfer: replace both legs.
        final outId = widget.editFrom!.amount.trimLeft().startsWith('-')
            ? widget.editFrom!.id
            : otherLeg.id;
        final inId = widget.editFrom!.amount.trimLeft().startsWith('-')
            ? otherLeg.id
            : widget.editFrom!.id;
        final pairId = widget.editFrom!.transferPairId!;
        await notifier.replaceById(
          outId,
          TransactionItem(
            id: outId,
            categoryName: categoryName,
            description: description,
            emoji: emoji,
            amount: formatAmountWithCurrency(-amount, currencyCode),
            type: TransactionType.transferred,
            date: dateStr,
            time: timeStr,
            accountId: _selectedFromAccount?.id,
            transferPairId: pairId,
            tagIds: _selectedTagIds,
          ),
        );
        await notifier.replaceById(
          inId,
          TransactionItem(
            id: inId,
            categoryName: categoryName,
            description: description,
            emoji: emoji,
            amount: formatAmountWithCurrency(amount, currencyCode),
            type: TransactionType.transferred,
            date: dateStr,
            time: timeStr,
            accountId: _selectedToAccount?.id,
            transferPairId: pairId,
            tagIds: _selectedTagIds,
          ),
        );
      } else {
        // New transfer: save two legs (out from source account, in to destination account).
        final idOut = notifier.nextId();
        await notifier.add(TransactionItem(
          id: idOut,
          categoryName: categoryName,
          description: description,
          emoji: emoji,
          amount: formatAmountWithCurrency(-amount, currencyCode),
          type: TransactionType.transferred,
          date: dateStr,
          time: timeStr,
          accountId: _selectedFromAccount?.id,
          transferPairId: idOut,
          tagIds: _selectedTagIds,
        ));
        final idIn = notifier.nextId();
        await notifier.add(TransactionItem(
          id: idIn,
          categoryName: categoryName,
          description: description,
          emoji: emoji,
          amount: formatAmountWithCurrency(amount, currencyCode),
          type: TransactionType.transferred,
          date: dateStr,
          time: timeStr,
          accountId: _selectedToAccount?.id,
          transferPairId: idOut,
          tagIds: _selectedTagIds,
        ));
      }
    } else {
      final id = widget.editFrom != null
          ? widget.editFrom!.id
          : notifier.nextId();
      final item = TransactionItem(
        id: id,
        categoryName: categoryName,
        description: description,
        emoji: emoji,
        amount: amountDisplay,
        type: type,
        date: dateStr,
        time: timeStr,
        accountId: accountId,
        tagIds: _selectedTagIds,
      );
      if (widget.editFrom != null) {
        await notifier.replaceById(widget.editFrom!.id, item);
      } else {
        await notifier.add(item);
      }
    }
    if (mounted) Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    if (widget.editFrom != null && !_editApplied) {
      _editApplied = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && widget.editFrom != null) {
          _applyEdit(widget.editFrom!);
        }
      });
    } else if (widget.duplicateFrom != null && !_duplicateApplied) {
      _duplicateApplied = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && widget.duplicateFrom != null) {
          _applyDuplicate(widget.duplicateFrom!);
        }
      });
    }
    final theme = Theme.of(context);
    final media = MediaQuery.of(context);
    final width = media.size.width;
    final isNarrow = width < 360;
    final horizontalPadding = _horizontalPadding(width);
    final cardPadding = isNarrow ? 14.0 : 18.0;
    final fontSize = isNarrow ? 14.0 : 16.0;

    return Scaffold(
      backgroundColor: _kBgGrey,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          widget.editFrom != null ? 'Edit Transaction' : 'Add Transaction',
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(48),
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: horizontalPadding,
              vertical: 8,
            ),
            child: TabBar(
              controller: _tabController,
              tabAlignment: TabAlignment.center,
              isScrollable: false,
              dividerColor: Colors.transparent,
              indicatorColor: Colors.grey,
              tabs: _tabLabels.map((l) => Tab(text: l)).toList(),
              labelColor: Colors.white,
              unselectedLabelColor: Colors.grey,
              labelStyle: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: isNarrow ? 13 : 14,
              ),
              unselectedLabelStyle: TextStyle(
                fontWeight: FontWeight.w500,
                fontSize: isNarrow ? 13 : 14,
              ),
            ),
          ),
        ),
      ),
      body: Container(
        color: _kBgGrey,
        child: TabBarView(
          controller: _tabController,
          children: List.generate(
            4,
            (index) => _buildForm(
              context,
              isNarrow,
              horizontalPadding,
              cardPadding,
              fontSize,
              tabIndex: index,
            ),
          ),
        ),
      ),
    );
  }

  double _horizontalPadding(double width) {
    if (width < 360) return 16;
    if (width > 600) return 24;
    return 20;
  }

  String get _dateTimeText {
    final today = DateTime.now();
    final isToday =
        _selectedDate.year == today.year &&
        _selectedDate.month == today.month &&
        _selectedDate.day == today.day;
    final dateStr = isToday
        ? 'Today'
        : '${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}';
    final hour = _selectedTime.hourOfPeriod == 0
        ? 12
        : _selectedTime.hourOfPeriod;
    final min = _selectedTime.minute.toString().padLeft(2, '0');
    final period = _selectedTime.period == DayPeriod.am ? 'am' : 'pm';
    return '$dateStr, $hour:$min $period';
  }

  String _amountLabelForTab(int tabIndex) {
    switch (tabIndex) {
      case 0:
        return 'Enter Spent Amount';
      case 1:
        return 'Enter Income Amount';
      case 2:
        return 'Enter Transfer Amount';
      case 3:
        return 'Enter Amount';
    }
    return 'Enter Amount';
  }

  void _applyPreset(PresetItem preset) {
    final targetTab = preset.transactionType == TransactionType.deducted
        ? 0
        : preset.transactionType == TransactionType.added
        ? 1
        : 2;
    setState(() {
      _selectedCategory = null;
      _selectedSubcategory = null;
      _selectedAccount = null;
      _selectedFromAccount = null;
      _selectedToAccount = null;
      final accounts = ref.read(accountsProvider).value ?? [];
      final categories = ref.read(categoriesForPickerProvider);
      if (preset.transactionType == TransactionType.transferred) {
        if (preset.fromAccountId != null) {
          try {
            _selectedFromAccount = accounts.firstWhere(
              (a) => a.id == preset.fromAccountId,
            );
          } catch (_) {}
        }
        if (preset.toAccountId != null) {
          try {
            _selectedToAccount = accounts.firstWhere(
              (a) => a.id == preset.toAccountId,
            );
          } catch (_) {}
        }
      } else {
        if (preset.accountId != null) {
          try {
            _selectedAccount = accounts.firstWhere(
              (a) => a.id == preset.accountId,
            );
          } catch (_) {}
        }
        if (preset.categoryId != null) {
          try {
            _selectedCategory = categories.firstWhere(
              (c) => c.id == preset.categoryId,
            );
            if (preset.subcategoryName != null) {
              try {
                _selectedSubcategory = _selectedCategory!.subcategories
                    .firstWhere((s) => s.name == preset.subcategoryName);
              } catch (_) {}
            }
          } catch (_) {}
        }
      }
      _descriptionController.text = preset.description ?? '';
      if (preset.includeAmount &&
          preset.amount != null &&
          preset.amount!.isNotEmpty) {
        _amountController.text = preset.amount!;
      }
    });
    _tabController.animateTo(targetTab);
  }

  void _applyEdit(TransactionItem item) {
    final amountStr = item.amount.replaceAll(RegExp(r'[^\d.]'), '');
    final amount = amountStr.isEmpty
        ? '0'
        : formatAmountTruncated(double.tryParse(amountStr) ?? 0);
    final targetTab = item.type == TransactionType.deducted
        ? 0
        : item.type == TransactionType.added
        ? 1
        : 2;
    final categories = ref.read(categoriesForPickerProvider);
    TransactionCategory? cat;
    SubcategoryItem? sub;
    for (final c in categories) {
      try {
        sub = c.subcategories.firstWhere((s) => s.name == item.categoryName);
        cat = c;
        break;
      } catch (_) {}
      if (c.name == item.categoryName) {
        cat = c;
        break;
      }
    }
    final accounts = ref.read(accountsProvider).value ?? [];
    AccountItem? account;
    if (item.accountId != null) {
      try {
        account = accounts.firstWhere((a) => a.id == item.accountId);
      } catch (_) {}
    }
    if (account == null && accounts.isNotEmpty) account = accounts.first;
    AccountItem? fromAcc;
    AccountItem? toAcc;
    if (targetTab == 2 && item.transferPairId != null) {
      final list = ref.read(transactionsProvider).value ?? [];
      for (final t in list) {
        if (t.transferPairId == item.transferPairId && t.id != item.id) {
          try {
            final otherAccount = accounts.firstWhere((a) => a.id == t.accountId);
            if (t.amount.trimLeft().startsWith('-')) {
              fromAcc = otherAccount;
              toAcc = account;
            } else {
              fromAcc = account;
              toAcc = otherAccount;
            }
          } catch (_) {}
          break;
        }
      }
      fromAcc ??= account;
      toAcc ??= accounts.length > 1 ? accounts[1] : account;
    }
    final dt = _parseStoredDate(item.date);
    setState(() {
      _amountController.text = amount;
      _descriptionController.text = item.description ?? '';
      _selectedDate = dt;
      _selectedTime = _parseStoredTime(item.time);
      _selectedCategory = cat;
      _selectedSubcategory = sub;
      _selectedAccount = account;
      _selectedTagIds = List<String>.from(item.tagIds);
      if (targetTab == 2 && fromAcc != null && toAcc != null) {
        _selectedFromAccount = fromAcc;
        _selectedToAccount = toAcc;
      } else {
        _selectedFromAccount = _selectedFromAccount ?? account;
        _selectedToAccount =
            _selectedToAccount ?? (accounts.length > 1 ? accounts[1] : account);
      }
    });
    _tabController.animateTo(targetTab);
  }

  static DateTime _parseStoredDate(String dateStr) {
    const months = {
      'Jan': 1,
      'Feb': 2,
      'Mar': 3,
      'Apr': 4,
      'May': 5,
      'Jun': 6,
      'Jul': 7,
      'Aug': 8,
      'Sep': 9,
      'Oct': 10,
      'Nov': 11,
      'Dec': 12,
    };
    final parts = dateStr.trim().split(RegExp(r'\s+'));
    if (parts.length < 2) return DateTime.now();
    final m = months[parts[0]];
    final d = int.tryParse(parts[1]);
    final y = parts.length >= 3
        ? (int.tryParse(parts[2]) ?? DateTime.now().year)
        : DateTime.now().year;
    if (m == null || d == null) return DateTime.now();
    try {
      return DateTime(y, m, d);
    } catch (_) {
      return DateTime.now();
    }
  }

  static TimeOfDay _parseStoredTime(String timeStr) {
    final match = RegExp(
      r'(\d{1,2}):(\d{2})\s*(AM|PM)?',
      caseSensitive: false,
    ).firstMatch(timeStr);
    if (match == null) return TimeOfDay.now();
    var h = int.tryParse(match.group(1) ?? '') ?? 12;
    final m = int.tryParse(match.group(2) ?? '') ?? 0;
    final pm = (match.group(3) ?? '').toUpperCase() == 'PM';
    if (!pm && h == 12) h = 0;
    if (pm && h != 12) h += 12;
    return TimeOfDay(hour: h.clamp(0, 23), minute: m.clamp(0, 59));
  }

  void _applyDuplicate(TransactionItem item) {
    final amountStr = item.amount.replaceAll(RegExp(r'[^\d.]'), '');
    final amount = amountStr.isEmpty
        ? '0'
        : formatAmountTruncated(double.tryParse(amountStr) ?? 0);
    final targetTab = item.type == TransactionType.deducted
        ? 0
        : item.type == TransactionType.added
        ? 1
        : 2;
    final categories = ref.read(categoriesForPickerProvider);
    TransactionCategory? cat;
    SubcategoryItem? sub;
    for (final c in categories) {
      try {
        sub = c.subcategories.firstWhere((s) => s.name == item.categoryName);
        cat = c;
        break;
      } catch (_) {}
      if (c.name == item.categoryName) {
        cat = c;
        break;
      }
    }
    final accounts = ref.read(accountsProvider).value ?? [];
    AccountItem? account;
    if (item.accountId != null) {
      try {
        account = accounts.firstWhere((a) => a.id == item.accountId);
      } catch (_) {}
    }
    if (account == null && accounts.isNotEmpty) account = accounts.first;
    final now = DateTime.now();
    setState(() {
      _amountController.text = amount;
      _descriptionController.text = item.description ?? '';
      _selectedDate = now;
      _selectedTime = TimeOfDay.fromDateTime(now);
      _selectedCategory = cat;
      _selectedSubcategory = sub;
      _selectedAccount = account;
      _selectedTagIds = List<String>.from(item.tagIds);
      _selectedFromAccount = _selectedFromAccount ?? account;
      _selectedToAccount =
          _selectedToAccount ?? (accounts.length > 1 ? accounts[1] : account);
    });
    _tabController.animateTo(targetTab);
  }

  Widget _buildForm(
    BuildContext context,
    bool isNarrow,
    double horizontalPadding,
    double cardPadding,
    double fontSize, {
    required int tabIndex,
  }) {
    if (tabIndex == 3) {
      return _buildPresetTab(horizontalPadding, isNarrow);
    }
    final isTransfer = tabIndex == 2;

    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(
        horizontalPadding,
        16,
        horizontalPadding,
        32,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildAmountCard(cardPadding, fontSize, isNarrow, tabIndex),
          const SizedBox(height: 16),
          if (isTransfer) ...[
            _buildFromAccountCard(cardPadding, fontSize),
            const SizedBox(height: 12),
            _buildToAccountCard(cardPadding, fontSize),
          ] else ...[
            _buildAccountCard(cardPadding, fontSize),
            const SizedBox(height: 12),
            if (_selectedCategory == null)
              _buildCategoryCard(cardPadding, fontSize)
            else
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: _buildCategoryCard(cardPadding, fontSize)),
                  const SizedBox(width: 12),
                  Expanded(child: _buildSubcategoryCard(cardPadding, fontSize)),
                ],
              ),
          ],
          const SizedBox(height: 12),
          _buildDescriptionCard(cardPadding, fontSize),
          const SizedBox(height: 12),
          _buildChooseTagsCard(cardPadding, fontSize),
          const SizedBox(height: 12),
          _buildDateTimeCard(cardPadding, fontSize),
          const SizedBox(height: 28),
          _SwipeToSave(
            onSwipeComplete: _saveTransaction,
            height: isNarrow ? 52 : 56,
          ),
        ],
      ),
    );
  }

  Widget _buildPresetTab(double horizontalPadding, bool isNarrow) {
    final presets = ref.watch(presetsProvider).value ?? [];
    if (presets.isEmpty) {
      return Center(
        child: Padding(
          padding: EdgeInsets.all(horizontalPadding * 2),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.bookmark_border_rounded,
                size: 56,
                color: Colors.grey[400],
              ),
              const SizedBox(height: 16),
              Text(
                'No presets',
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey[700],
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Create presets from Presets in the menu, or save a transaction as preset.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 14, color: Colors.grey[600]),
              ),
            ],
          ),
        ),
      );
    }
    return ListView.builder(
      padding: EdgeInsets.fromLTRB(
        horizontalPadding,
        16,
        horizontalPadding,
        32,
      ),
      itemCount: presets.length,
      itemBuilder: (context, index) {
        final preset = presets[index];
        TransactionCategory? cat;
        if (preset.categoryId != null) {
          try {
            cat = ref
                .read(categoriesForPickerProvider)
                .firstWhere((c) => c.id == preset.categoryId);
          } catch (_) {}
        }
        final emoji = cat?.emoji ?? '📌';
        final subLabel = preset.subcategoryName ?? cat?.name ?? '';
        String typeLabel;
        switch (preset.transactionType) {
          case TransactionType.deducted:
            typeLabel = 'Spend';
            break;
          case TransactionType.added:
            typeLabel = 'Income';
            break;
          case TransactionType.transferred:
            typeLabel = 'Transfer';
            break;
        }
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Material(
            color: _kCardWhite,
            borderRadius: BorderRadius.circular(16),
            child: InkWell(
              onTap: () => _applyPreset(preset),
              borderRadius: BorderRadius.circular(16),
              child: Padding(
                padding: EdgeInsets.all(isNarrow ? 14 : 18),
                child: Row(
                  children: [
                    Container(
                      width: isNarrow ? 48 : 56,
                      height: isNarrow ? 48 : 56,
                      decoration: BoxDecoration(
                        color: _kBgGrey,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        emoji,
                        style: TextStyle(fontSize: isNarrow ? 26 : 30),
                      ),
                    ),
                    SizedBox(width: isNarrow ? 14 : 18),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            preset.name,
                            style: TextStyle(
                              fontSize: isNarrow ? 17 : 18,
                              fontWeight: FontWeight.w600,
                              color: _kTextDark,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '$typeLabel${subLabel.isNotEmpty ? ' · $subLabel' : ''}',
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ),
                    Icon(
                      Icons.chevron_right_rounded,
                      color: Colors.grey[400],
                      size: 28,
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildAmountCard(
    double cardPadding,
    double fontSize,
    bool isNarrow,
    int tabIndex,
  ) {
    return Container(
      padding: EdgeInsets.all(cardPadding),
      decoration: BoxDecoration(
        color: _kCardWhite,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _kBorderGrey),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _amountLabelForTab(tabIndex),
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: fontSize - 1,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _amountController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            style: TextStyle(
              fontSize: isNarrow ? 26 : 30,
              fontWeight: FontWeight.w600,
              color: _kTextDark,
            ),
            decoration: InputDecoration(
              prefixText: 'BDT ',
              prefixStyle: TextStyle(
                fontSize: isNarrow ? 22 : 26,
                fontWeight: FontWeight.w600,
                color: _kTextDark,
              ),
              border: InputBorder.none,
              contentPadding: EdgeInsets.zero,
              isDense: true,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAccountCard(double cardPadding, double fontSize) {
    return _SelectCard(
      label: 'Payment',
      value: _selectedAccount?.name ?? 'Choose account',
      leading: Icon(
        Icons.account_balance_wallet_rounded,
        size: 22,
        color: Colors.grey[600],
      ),
      onTap: () async {
        final account = await showModalBottomSheet<AccountItem>(
          context: context,
          backgroundColor: Colors.white,
          builder: (ctx) => _AccountPickerSheet(
            accounts: ref.read(accountsProvider).value ?? [],
            selected: _selectedAccount,
            exclude: null,
          ),
        );
        if (account != null && mounted) {
          setState(() => _selectedAccount = account);
        }
      },
      padding: cardPadding,
      fontSize: fontSize,
    );
  }

  Widget _buildFromAccountCard(double cardPadding, double fontSize) {
    return _SelectCard(
      label: 'From account',
      value: _selectedFromAccount?.name ?? 'Choose account',
      leading: Icon(
        Icons.account_balance_wallet_rounded,
        size: 22,
        color: Colors.grey[600],
      ),
      onTap: () async {
        final account = await showModalBottomSheet<AccountItem>(
          context: context,
          backgroundColor: Colors.white,
          builder: (ctx) => _AccountPickerSheet(
            accounts: ref.read(accountsProvider).value ?? [],
            selected: _selectedFromAccount,
            exclude: _selectedToAccount,
          ),
        );
        if (account != null && mounted) {
          setState(() => _selectedFromAccount = account);
        }
      },
      padding: cardPadding,
      fontSize: fontSize,
    );
  }

  Widget _buildToAccountCard(double cardPadding, double fontSize) {
    return _SelectCard(
      label: 'To account',
      value: _selectedToAccount?.name ?? 'Choose account',
      leading: Icon(
        Icons.account_balance_wallet_rounded,
        size: 22,
        color: Colors.grey[600],
      ),
      onTap: () async {
        final account = await showModalBottomSheet<AccountItem>(
          context: context,
          backgroundColor: Colors.white,
          builder: (ctx) => _AccountPickerSheet(
            accounts: ref.read(accountsProvider).value ?? [],
            selected: _selectedToAccount,
            exclude: _selectedFromAccount,
          ),
        );
        if (account != null && mounted) {
          setState(() => _selectedToAccount = account);
        }
      },
      padding: cardPadding,
      fontSize: fontSize,
    );
  }

  Widget _buildCategoryCard(double cardPadding, double fontSize) {
    return _SelectCard(
      label: 'Category',
      value: _selectedCategory?.name ?? 'Choose category',
      leading: _selectedCategory != null
          ? Text(_selectedCategory!.emoji, style: const TextStyle(fontSize: 22))
          : null,
      trailing: Icon(Icons.add_rounded, size: 22, color: _kTextDark),
      onTap: () async {
        final result = await showModalBottomSheet<Object>(
          context: context,
          backgroundColor: Colors.white,
          builder: (ctx) => _CategoryPickerSheet(
            categories: ref.read(categoriesForPickerProvider),
            selected: _selectedCategory,
          ),
        );
        if (!mounted) return;
        if (result is _ClearCategoryMarker) {
          setState(() {
            _selectedCategory = null;
            _selectedSubcategory = null;
          });
        } else if (result is TransactionCategory) {
          setState(() {
            _selectedCategory = result;
            _selectedSubcategory = null;
          });
        }
      },
      padding: cardPadding,
      fontSize: fontSize,
    );
  }

  Widget _buildSubcategoryCard(double cardPadding, double fontSize) {
    return _SelectCard(
      label: 'Subcategory',
      value: _selectedSubcategory?.name ?? 'Choose subcategory',
      leading: _selectedSubcategory != null
          ? Text(
              _selectedSubcategory!.emoji,
              style: const TextStyle(fontSize: 22),
            )
          : null,
      onTap: () async {
        if (_selectedCategory == null) return;
        final result = await showModalBottomSheet<Object>(
          context: context,
          backgroundColor: Colors.white,
          builder: (ctx) => _SubcategoryPickerSheet(
            subcategories: _selectedCategory!.subcategories,
            selected: _selectedSubcategory,
          ),
        );
        if (!mounted) return;
        if (result is _ClearSubcategoryMarker) {
          setState(() => _selectedSubcategory = null);
        } else if (result is SubcategoryItem) {
          setState(() => _selectedSubcategory = result);
        }
      },
      padding: cardPadding,
      fontSize: fontSize,
    );
  }

  Widget _buildDescriptionCard(double cardPadding, double fontSize) {
    return Container(
      padding: EdgeInsets.all(cardPadding),
      decoration: BoxDecoration(
        color: _kCardWhite,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _kBorderGrey),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Description (optional)',
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: fontSize - 1,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _descriptionController,
            style: TextStyle(fontSize: fontSize, color: _kTextDark),
            decoration: InputDecoration(
              hintText: 'Add a note',
              hintStyle: TextStyle(color: Colors.grey[400]),
              border: InputBorder.none,
              contentPadding: EdgeInsets.zero,
              isDense: true,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChooseTagsCard(double cardPadding, double fontSize) {
    final tags = ref.watch(tagsProvider).value ?? [];
    final selectedTags = tags.where((t) => _selectedTagIds.contains(t.id)).toList();
    final valueText = selectedTags.isEmpty
        ? 'Choose tags'
        : selectedTags.map((t) => t.name).join(', ');
    return _SelectCard(
      label: 'Tags',
      value: valueText,
      leading: Icon(
        Icons.label_outline_rounded,
        size: 22,
        color: Colors.grey[600],
      ),
      onTap: () async {
        final result = await Navigator.of(context).push<List<String>>(
          MaterialPageRoute(
            builder: (context) => TagsScreen(
              initialSelectedIds: _selectedTagIds,
              onDone: (_) {},
              selectedCategoryId: _selectedCategory?.id,
            ),
          ),
        );
        if (result != null && mounted) {
          setState(() => _selectedTagIds = result);
        }
      },
      padding: cardPadding,
      fontSize: fontSize,
    );
  }

  Widget _buildDateTimeCard(double cardPadding, double fontSize) {
    return Material(
      color: _kCardWhite,
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: EdgeInsets.all(cardPadding),
        child: Row(
          children: [
            Expanded(
              child: InkWell(
                onTap: () async {
                  await _pickDate();
                  if (mounted) await _pickTime();
                },
                borderRadius: BorderRadius.circular(12),
                child: Row(
                  children: [
                    Icon(
                      Icons.calendar_today_rounded,
                      size: 22,
                      color: _kTextDark,
                    ),
                    const SizedBox(width: 12),
                    Text(
                      _dateTimeText,
                      style: TextStyle(fontSize: fontSize, color: _kTextDark),
                    ),
                  ],
                ),
              ),
            ),
            TextButton(
              onPressed: () => setState(() {
                _selectedDate = DateTime.now();
                _selectedTime = TimeOfDay.now();
              }),
              child: Text('Clear', style: TextStyle(color: Colors.grey[700])),
            ),
          ],
        ),
      ),
    );
  }
}

class _SelectCard extends StatelessWidget {
  const _SelectCard({
    required this.label,
    required this.value,
    required this.onTap,
    this.leading,
    this.trailing,
    required this.padding,
    required this.fontSize,
  });

  final String label;
  final String value;
  final VoidCallback onTap;
  final Widget? leading;
  final Widget? trailing;
  final double padding;
  final double fontSize;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: _kCardWhite,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _kBorderGrey),
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: EdgeInsets.all(padding),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (leading != null) ...[leading!, const SizedBox(width: 8)],
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        label,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: fontSize - 2,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        value,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: fontSize,
                          fontWeight: FontWeight.w500,
                          color: value.startsWith('Choose')
                              ? Colors.grey[500]
                              : _kTextDark,
                        ),
                      ),
                    ],
                  ),
                ),
                trailing ??
                    Icon(
                      Icons.keyboard_arrow_down_rounded,
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

class _AccountPickerSheet extends StatelessWidget {
  const _AccountPickerSheet({
    required this.accounts,
    this.selected,
    this.exclude,
  });

  final List<AccountItem> accounts;
  final AccountItem? selected;
  final AccountItem? exclude;

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);

    return SafeArea(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxHeight: media.size.height * 0.6),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                'Choose account',
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
            Flexible(
              child: ListView.builder(
                itemCount: accounts.length,
                itemBuilder: (context, i) {
                  final a = accounts[i];
                  final isExcluded = exclude?.id == a.id;
                  return ListTile(
                    leading: Text(
                      a.emojis,
                      style: const TextStyle(fontSize: 24),
                    ),
                    title: Text(a.name),
                    subtitle: Text(a.accountType),
                    selected: selected?.id == a.id,
                    enabled: !isExcluded,
                    onTap: isExcluded
                        ? null
                        : () => Navigator.of(context).pop(a),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CategoryPickerSheet extends StatelessWidget {
  const _CategoryPickerSheet({required this.categories, this.selected});

  final List<TransactionCategory> categories;
  final TransactionCategory? selected;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final media = MediaQuery.of(context);

    return SafeArea(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxHeight: media.size.height * 0.6),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Choose category', style: theme.textTheme.titleMedium),
                  TextButton(
                    onPressed: () =>
                        Navigator.of(context).pop(_ClearCategoryMarker()),
                    child: const Text('Clear'),
                  ),
                ],
              ),
            ),
            Flexible(
              child: ListView.builder(
                itemCount: categories.length,
                itemBuilder: (context, i) {
                  final c = categories[i];
                  return ListTile(
                    leading: Text(
                      c.emoji,
                      style: const TextStyle(fontSize: 24),
                    ),
                    title: Text(c.name),
                    selected: selected?.id == c.id,
                    onTap: () => Navigator.of(context).pop(c),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SubcategoryPickerSheet extends StatelessWidget {
  const _SubcategoryPickerSheet({required this.subcategories, this.selected});

  final List<SubcategoryItem> subcategories;
  final SubcategoryItem? selected;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final media = MediaQuery.of(context);

    return SafeArea(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxHeight: media.size.height * 0.6),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Choose subcategory',
                    style: theme.textTheme.titleMedium,
                  ),
                  TextButton(
                    onPressed: () =>
                        Navigator.of(context).pop(_ClearSubcategoryMarker()),
                    child: const Text('Clear'),
                  ),
                ],
              ),
            ),
            Flexible(
              child: ListView.builder(
                itemCount: subcategories.length,
                itemBuilder: (context, i) {
                  final s = subcategories[i];
                  return ListTile(
                    leading: Text(
                      s.emoji,
                      style: const TextStyle(fontSize: 24),
                    ),
                    title: Text(s.name),
                    selected: selected?.name == s.name,
                    onTap: () => Navigator.of(context).pop(s),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SwipeToSave extends StatefulWidget {
  const _SwipeToSave({required this.onSwipeComplete, this.height = 56});

  final VoidCallback onSwipeComplete;
  final double height;

  @override
  State<_SwipeToSave> createState() => _SwipeToSaveState();
}

class _SwipeToSaveState extends State<_SwipeToSave> {
  double _dragOffset = 0;
  double _maxDrag = 0;

  @override
  Widget build(BuildContext context) {
    final height = widget.height;

    return LayoutBuilder(
      builder: (context, constraints) {
        final thumbSize = height - 6;
        _maxDrag = (constraints.maxWidth - thumbSize - 6).clamp(
          0.0,
          double.infinity,
        );
        if (_maxDrag < 0) _maxDrag = 0;
        final filledWidth = 6 + _dragOffset.clamp(0.0, _maxDrag) + thumbSize;

        return ClipRRect(
          borderRadius: BorderRadius.circular(height / 2),
          child: Container(
            height: height,
            decoration: BoxDecoration(
              color: Colors.black,
              borderRadius: BorderRadius.circular(height / 2),
            ),
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                if (filledWidth > 6)
                  Positioned(
                    left: 0,
                    top: 0,
                    bottom: 0,
                    width: filledWidth,
                    child: Container(
                      decoration: BoxDecoration(
                        color: const Color(0xFF34C759),
                        borderRadius: BorderRadius.circular(height / 2),
                      ),
                    ),
                  ),
                Center(
                  child: Padding(
                    padding: EdgeInsets.only(left: height * 0.6),
                    child: Text(
                      'Swipe to save',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: height * 0.28,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
                Positioned(
                  left: 6 + _dragOffset.clamp(0.0, _maxDrag),
                  top: 6,
                  child: GestureDetector(
                    onHorizontalDragUpdate: (d) {
                      setState(() {
                        _dragOffset += d.delta.dx;
                        _dragOffset = _dragOffset.clamp(0.0, _maxDrag);
                      });
                    },
                    onHorizontalDragEnd: (d) {
                      if (_dragOffset >= _maxDrag * 0.85) {
                        widget.onSwipeComplete();
                      } else {
                        setState(() => _dragOffset = 0);
                      }
                    },
                    child: Container(
                      width: height - 12,
                      height: height - 12,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.12),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      alignment: Alignment.center,
                      child: Icon(
                        Icons.arrow_forward_rounded,
                        color: Colors.black87,
                        size: (height - 12) * 0.52,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
