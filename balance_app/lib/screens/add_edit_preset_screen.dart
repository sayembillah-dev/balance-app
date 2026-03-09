import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/dummy_data.dart';
import '../providers/app_providers.dart';
import '../providers/currency_provider.dart';

const Color _kBgGrey = Color(0xFFF2F2F7);
const Color _kTextDark = Color(0xFF1C1C1E);
const Color _kBorderGrey = Color(0xFFE5E5EA);

/// Add or edit a preset. Optionally prefilled from [fromTransaction] (Save as preset).
class AddEditPresetScreen extends ConsumerStatefulWidget {
  const AddEditPresetScreen({this.preset, this.fromTransaction, super.key});

  final PresetItem? preset;
  final TransactionItem? fromTransaction;

  @override
  ConsumerState<AddEditPresetScreen> createState() => _AddEditPresetScreenState();
}

class _AddEditPresetScreenState extends ConsumerState<AddEditPresetScreen> {
  late TextEditingController _nameController;
  late TextEditingController _descriptionController;
  late TextEditingController _amountController;
  TransactionType _transactionType = TransactionType.deducted;
  AccountItem? _selectedAccount;
  AccountItem? _selectedFromAccount;
  AccountItem? _selectedToAccount;
  TransactionCategory? _selectedCategory;
  SubcategoryItem? _selectedSubcategory;
  bool _includeAmount = false;
  bool _inited = false;

  bool get _isEdit => widget.preset != null;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _descriptionController = TextEditingController();
    _amountController = TextEditingController(text: '0');
  }

  void _initFromTransaction(TransactionItem t, List<AccountItem> accounts, List<TransactionCategory> categories) {
    _nameController.text = t.categoryName;
    _descriptionController.text = t.description ?? '';
    _transactionType = t.type;
    if (t.accountId != null) {
      try {
        _selectedAccount = accounts.firstWhere((a) => a.id == t.accountId);
      } catch (_) {}
    }
    _resolveCategoryFromName(t.categoryName, categories);
    final amountStr = t.amount.replaceAll(RegExp(r'[^\d.]'), '');
    if (amountStr.isNotEmpty) {
      _includeAmount = true;
      _amountController.text = amountStr;
    }
  }

  void _resolveCategoryFromName(String categoryName, List<TransactionCategory> categories) {
    for (final c in categories) {
      if (c.name == categoryName) {
        _selectedCategory = c;
        _selectedSubcategory = null;
        return;
      }
      for (final s in c.subcategories) {
        if (s.name == categoryName) {
          _selectedCategory = c;
          _selectedSubcategory = s;
          return;
        }
      }
    }
  }

  void _initFromPreset(PresetItem p, List<AccountItem> accounts, List<TransactionCategory> categories) {
    _nameController.text = p.name;
    _descriptionController.text = p.description ?? '';
    _transactionType = p.transactionType;
    _includeAmount = p.includeAmount;
    _amountController.text = p.amount ?? '0';
    if (p.accountId != null) {
      try {
        _selectedAccount = accounts.firstWhere((a) => a.id == p.accountId);
      } catch (_) {}
    }
    if (p.fromAccountId != null) {
      try {
        _selectedFromAccount = accounts.firstWhere((a) => a.id == p.fromAccountId);
      } catch (_) {}
    }
    if (p.toAccountId != null) {
      try {
        _selectedToAccount = accounts.firstWhere((a) => a.id == p.toAccountId);
      } catch (_) {}
    }
    if (p.categoryId != null) {
      try {
        _selectedCategory = categories.firstWhere((c) => c.id == p.categoryId);
        if (p.subcategoryName != null) {
          try {
            _selectedSubcategory = _selectedCategory!.subcategories
                .firstWhere((s) => s.name == p.subcategoryName);
          } catch (_) {}
        }
      } catch (_) {}
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter a preset name')),
      );
      return;
    }
    if (_transactionType != TransactionType.transferred) {
      if (_selectedAccount == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Select an account')),
        );
        return;
      }
      if (_selectedCategory == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Select a category')),
        );
        return;
      }
    } else {
      if (_selectedFromAccount == null || _selectedToAccount == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Select from and to accounts')),
        );
        return;
      }
    }
    final notifier = ref.read(presetsProvider.notifier);
    final preset = PresetItem(
      id: widget.preset?.id ?? notifier.nextId(),
      name: name,
      transactionType: _transactionType,
      accountId: _transactionType != TransactionType.transferred ? _selectedAccount?.id : null,
      fromAccountId: _transactionType == TransactionType.transferred ? _selectedFromAccount?.id : null,
      toAccountId: _transactionType == TransactionType.transferred ? _selectedToAccount?.id : null,
      categoryId: _selectedCategory?.id,
      subcategoryName: _selectedSubcategory?.name,
      description: _descriptionController.text.trim().isEmpty ? null : _descriptionController.text.trim(),
      includeAmount: _includeAmount,
      amount: _includeAmount ? _amountController.text.trim() : null,
    );
    if (_isEdit) {
      await notifier.replace(preset.id, preset);
    } else {
      await notifier.add(preset);
    }
    if (mounted) Navigator.of(context).pop(true);
  }

  void _delete() {
    if (!_isEdit) return;
    showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete preset?'),
        content: Text('${widget.preset!.name} will be removed.'),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text('Cancel')),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: FilledButton.styleFrom(backgroundColor: const Color(0xFFFF3B30)),
            child: const Text('Delete'),
          ),
        ],
      ),
    ).then((ok) async {
      if (ok == true && mounted) {
        await ref.read(presetsProvider.notifier).remove(widget.preset!.id);
        if (mounted) Navigator.of(context).pop(true);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final accounts = ref.watch(accountsProvider).value ?? [];
    final categories = ref.watch(categoriesForPickerProvider);
    if (!_inited) {
      _inited = true;
      if (widget.fromTransaction != null) {
        _initFromTransaction(widget.fromTransaction!, accounts, categories);
      } else if (widget.preset != null) {
        _initFromPreset(widget.preset!, accounts, categories);
      }
    }
    final media = MediaQuery.of(context);
    final width = media.size.width;
    final isNarrow = width < 360;
    final padding = isNarrow ? 16.0 : 20.0;
    final isTransfer = _transactionType == TransactionType.transferred;

    return Scaffold(
      backgroundColor: _kBgGrey,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.close_rounded),
          onPressed: () => Navigator.of(context).pop(false),
        ),
        title: Text(
          widget.fromTransaction != null
              ? 'Save as preset'
              : (_isEdit ? 'Edit preset' : 'New preset'),
          style: const TextStyle(
            color: _kTextDark,
            fontWeight: FontWeight.w600,
          ),
        ),
        backgroundColor: Colors.white,
        foregroundColor: _kTextDark,
        elevation: 0,
        actions: [
          if (_isEdit)
            IconButton(
              icon: const Icon(Icons.delete_outline_rounded, color: Color(0xFFFF3B30)),
              onPressed: _delete,
            ),
          TextButton(
            onPressed: _save,
            child: const Text('Save', style: TextStyle(fontWeight: FontWeight.w600)),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(padding, 24, padding, 24 + media.padding.bottom),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _label('Preset name'),
            const SizedBox(height: 8),
            _textField(_nameController, 'e.g. Coffee run'),
            const SizedBox(height: 24),
            _label('Transaction type'),
            const SizedBox(height: 10),
            Row(
              children: [
                _typeChip('Spend', TransactionType.deducted),
                const SizedBox(width: 8),
                _typeChip('Income', TransactionType.added),
                const SizedBox(width: 8),
                _typeChip('Transfer', TransactionType.transferred),
              ],
            ),
            const SizedBox(height: 24),
            if (isTransfer) ...[
              _label('From account'),
              const SizedBox(height: 8),
              _accountTile(
                value: _selectedFromAccount?.name ?? 'Choose account',
                onTap: () async {
                  final a = await _showAccountPicker(exclude: _selectedToAccount);
                  if (a != null && mounted) setState(() => _selectedFromAccount = a);
                },
              ),
              const SizedBox(height: 12),
              _label('To account'),
              const SizedBox(height: 8),
              _accountTile(
                value: _selectedToAccount?.name ?? 'Choose account',
                onTap: () async {
                  final a = await _showAccountPicker(exclude: _selectedFromAccount);
                  if (a != null && mounted) setState(() => _selectedToAccount = a);
                },
              ),
            ] else ...[
              _label('Account'),
              const SizedBox(height: 8),
              _accountTile(
                value: _selectedAccount?.name ?? 'Choose account',
                onTap: () async {
                  final a = await _showAccountPicker();
                  if (a != null && mounted) setState(() => _selectedAccount = a);
                },
              ),
              const SizedBox(height: 12),
              _label('Category'),
              const SizedBox(height: 8),
              _accountTile(
                value: _selectedCategory?.name ?? 'Choose category',
                leading: _selectedCategory != null
                    ? Text(_selectedCategory!.emoji, style: const TextStyle(fontSize: 22))
                    : null,
                onTap: () async {
                  final c = await _showCategoryPicker();
                  if (c != null && mounted) {
                    setState(() {
                      _selectedCategory = c;
                      _selectedSubcategory = null;
                    });
                  }
                },
              ),
              if (_selectedCategory != null) ...[
                const SizedBox(height: 12),
                _label('Subcategory'),
                const SizedBox(height: 8),
                _accountTile(
                  value: _selectedSubcategory?.name ?? 'Choose subcategory',
                  leading: _selectedSubcategory != null
                      ? Text(_selectedSubcategory!.emoji, style: const TextStyle(fontSize: 22))
                      : null,
                  onTap: () async {
                    final s = await _showSubcategoryPicker(_selectedCategory!);
                    if (s != null && mounted) setState(() => _selectedSubcategory = s);
                  },
                ),
              ],
            ],
            const SizedBox(height: 24),
            _label('Description (optional)'),
            const SizedBox(height: 8),
            _textField(_descriptionController, 'Add a note'),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Include amount',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                      color: _kTextDark,
                    ),
                  ),
                ),
                Switch(
                  value: _includeAmount,
                  onChanged: (v) => setState(() => _includeAmount = v),
                ),
              ],
            ),
            if (_includeAmount) ...[
              const SizedBox(height: 12),
              _label('Default amount (${ref.watch(selectedCurrencyCodeProvider)})'),
              const SizedBox(height: 8),
              _textField(_amountController, '0', keyboardType: TextInputType.number),
            ],
          ],
        ),
      ),
    );
  }

  Widget _label(String text) {
    return Text(
      text,
      style: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: Colors.grey[700],
      ),
    );
  }

  Widget _textField(TextEditingController c, String hint, {TextInputType? keyboardType}) {
    return TextField(
      controller: c,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        hintText: hint,
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: _kBorderGrey),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
    );
  }

  Widget _typeChip(String label, TransactionType type) {
    final selected = _transactionType == type;
    return FilterChip(
      label: Text(label),
      selected: selected,
      onSelected: (v) => setState(() => _transactionType = type),
      selectedColor: Colors.black,
      checkmarkColor: Colors.white,
      labelStyle: TextStyle(
        color: selected ? Colors.white : _kTextDark,
        fontWeight: FontWeight.w500,
      ),
    );
  }

  Widget _accountTile({
    required String value,
    required VoidCallback onTap,
    Widget? leading,
  }) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: _kBorderGrey),
          ),
          child: Row(
            children: [
              if (leading != null) ...[
                leading,
                const SizedBox(width: 12),
              ],
              Expanded(
                child: Text(
                  value,
                  style: TextStyle(
                    fontSize: 16,
                    color: value.startsWith('Choose') ? Colors.grey[500] : _kTextDark,
                  ),
                ),
              ),
              Icon(Icons.keyboard_arrow_down_rounded, color: Colors.grey[600]),
            ],
          ),
        ),
      ),
    );
  }

  Future<AccountItem?> _showAccountPicker({AccountItem? exclude}) async {
    return showModalBottomSheet<AccountItem>(
      context: context,
      backgroundColor: Colors.white,
      builder: (ctx) {
        final accounts = ref.read(accountsProvider).value ?? [];
        final filtered = accounts.where((a) => a.id != exclude?.id).toList();
        final media = MediaQuery.of(ctx);
        return SafeArea(
          child: ConstrainedBox(
            constraints: BoxConstraints(maxHeight: media.size.height * 0.6),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Padding(
                  padding: EdgeInsets.all(16),
                  child: Text('Choose account', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
                ),
                Flexible(
                  child: ListView.builder(
                    itemCount: filtered.length,
                    itemBuilder: (_, i) {
                      final a = filtered[i];
                      return ListTile(
                        leading: Text(a.emojis, style: const TextStyle(fontSize: 24)),
                        title: Text(a.name),
                        subtitle: Text(a.accountType),
                        onTap: () => Navigator.of(ctx).pop(a),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<TransactionCategory?> _showCategoryPicker() async {
    return showModalBottomSheet<TransactionCategory>(
      context: context,
      backgroundColor: Colors.white,
      builder: (ctx) {
        final categories = ref.read(categoriesForPickerProvider);
        final media = MediaQuery.of(ctx);
        return SafeArea(
          child: ConstrainedBox(
            constraints: BoxConstraints(maxHeight: media.size.height * 0.6),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Padding(
                  padding: EdgeInsets.all(16),
                  child: Text('Choose category', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
                ),
                Flexible(
                  child: ListView.builder(
                    itemCount: categories.length,
                    itemBuilder: (_, i) {
                      final c = categories[i];
                      return ListTile(
                        leading: Text(c.emoji, style: const TextStyle(fontSize: 24)),
                        title: Text(c.name),
                        onTap: () => Navigator.of(ctx).pop(c),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<SubcategoryItem?> _showSubcategoryPicker(TransactionCategory category) async {
    return showModalBottomSheet<SubcategoryItem>(
      context: context,
      backgroundColor: Colors.white,
      builder: (ctx) {
        final subs = category.subcategories.where((s) => !s.isHidden).toList();
        final media = MediaQuery.of(ctx);
        return SafeArea(
          child: ConstrainedBox(
            constraints: BoxConstraints(maxHeight: media.size.height * 0.6),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Padding(
                  padding: EdgeInsets.all(16),
                  child: Text('Choose subcategory', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
                ),
                Flexible(
                  child: ListView.builder(
                    itemCount: subs.length,
                    itemBuilder: (_, i) {
                      final s = subs[i];
                      return ListTile(
                        leading: Text(s.emoji, style: const TextStyle(fontSize: 24)),
                        title: Text(s.name),
                        onTap: () => Navigator.of(ctx).pop(s),
                      );
                    },
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
