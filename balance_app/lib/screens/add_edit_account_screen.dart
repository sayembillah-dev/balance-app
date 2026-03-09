import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/dummy_data.dart';
import '../providers/app_providers.dart';

/// Add new account or edit existing. Emoji, title, account type, initial balance.
class AddEditAccountScreen extends ConsumerStatefulWidget {
  const AddEditAccountScreen({this.account, super.key});

  final AccountItem? account;

  @override
  ConsumerState<AddEditAccountScreen> createState() => _AddEditAccountScreenState();
}

class _AddEditAccountScreenState extends ConsumerState<AddEditAccountScreen> {
  late TextEditingController _nameController;
  late TextEditingController _balanceController;
  late String _selectedType;
  String? _selectedEmoji; // null = none selected (add flow); edit keeps existing emoji
  bool get _isEdit => widget.account != null;

  @override
  void initState() {
    super.initState();
    final a = widget.account;
    _nameController = TextEditingController(text: a?.name ?? '');
    _balanceController = TextEditingController(text: a != null ? a.initialBalance.toStringAsFixed(0) : '');
    _selectedType = a?.accountType ?? accountTypeOptions.first;
    _selectedEmoji = a?.emojis; // edit: keep existing; add: no emoji by default
  }

  @override
  void dispose() {
    _nameController.dispose();
    _balanceController.dispose();
    super.dispose();
  }

  void _openAccountTypeSheet(BuildContext context) {
    showModalBottomSheet<String>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Container(
        constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.6),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 12),
            Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
              child: Row(
                children: [
                  const Text(
                    'Account type',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF1C1C1E),
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: Icon(Icons.close_rounded, color: Colors.grey[700], size: 24),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
                  ),
                ],
              ),
            ),
            Flexible(
              child: ListView.builder(
                shrinkWrap: true,
                padding: EdgeInsets.fromLTRB(20, 8, 20, 20 + MediaQuery.of(context).padding.bottom),
                itemCount: accountTypeOptions.length,
                itemBuilder: (context, index) {
                  final type = accountTypeOptions[index];
                  final selected = type == _selectedType;
                  return Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () => Navigator.of(context).pop(type),
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                        margin: const EdgeInsets.only(bottom: 6),
                        decoration: BoxDecoration(
                          color: selected ? const Color(0xFFF2F2F7) : Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: selected ? const Color(0xFF1C1C1E) : const Color(0xFFE5E5EA),
                            width: selected ? 1.5 : 1,
                          ),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                color: const Color(0xFFF2F2F7),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              alignment: Alignment.center,
                              child: Text(
                                _emojiForAccountType(type),
                                style: const TextStyle(fontSize: 22),
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Text(
                                type,
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
                                  color: const Color(0xFF1C1C1E),
                                ),
                              ),
                            ),
                            if (selected)
                              Icon(Icons.check_rounded, size: 22, color: Colors.grey[700]),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    ).then((value) {
      if (value != null && mounted) {
        setState(() {
          _selectedType = value;
          // If user hasn't picked an emoji yet, use the type's default emoji
          _selectedEmoji ??= _emojiForAccountType(value);
        });
      }
    });
  }

  static String _emojiForAccountType(String type) {
    switch (type) {
      case 'Mobile Finance':
        return '📱';
      case 'Bank':
        return '🏦';
      case 'Debit Card':
        return '💳';
      case 'Credit Card':
        return '💳';
      case 'Savings':
        return '🐷';
      case 'Cash':
        return '💵';
      case 'Investment':
        return '📈';
      case 'Wallet':
        return '👛';
      case 'Other':
        return '📂';
      default:
        return '💰';
    }
  }

  void _save() {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Enter account title')));
      return;
    }
    final balance = double.tryParse(_balanceController.text.trim());
    final initialBalance = balance ?? 0;

    final notifier = ref.read(accountsProvider.notifier);
    if (_isEdit && widget.account != null) {
      final acc = widget.account!.copyWith(
        name: name,
        accountType: _selectedType,
        initialBalance: initialBalance,
        emojis: _selectedEmoji ?? _emojiForAccountType(_selectedType),
      );
      notifier.updateAccount(acc);
      if (mounted) Navigator.of(context).pop(true);
    } else {
      notifier.add(AccountItem(
        id: notifier.nextId(),
        name: name,
        accountType: _selectedType,
        monthExpense: 'BDT 0',
        monthIncome: 'BDT 0',
        emojis: _selectedEmoji ?? _emojiForAccountType(_selectedType),
        initialBalance: initialBalance,
      ));
      if (mounted) Navigator.of(context).pop(true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isNarrow = MediaQuery.of(context).size.width < 360;
    final padding = isNarrow ? 16.0 : 20.0;

    return Scaffold(
      backgroundColor: const Color(0xFFF2F2F7),
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.close_rounded),
          onPressed: () => Navigator.of(context).pop(false),
        ),
        title: Text(_isEdit ? 'Edit account' : 'Add account'),
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        actions: [
          TextButton(
            onPressed: _save,
            child: const Text('Save'),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(padding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 8),
            const Text('Emoji', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
            const SizedBox(height: 10),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: accountEmojiOptions.map((e) {
                final selected = _selectedEmoji != null && _selectedEmoji == e;
                return GestureDetector(
                  onTap: () => setState(() => _selectedEmoji = e),
                  child: Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: selected ? Colors.grey[300] : Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: selected ? Colors.black54 : Colors.grey[300]!),
                    ),
                    alignment: Alignment.center,
                    child: Text(e, style: const TextStyle(fontSize: 24)),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 24),
            const Text('Account title', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            TextField(
              controller: _nameController,
              decoration: InputDecoration(
                hintText: 'e.g. EBL, Bkash',
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              ),
            ),
            const SizedBox(height: 20),
            const Text('Account type', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            Material(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              child: InkWell(
                onTap: () => _openAccountTypeSheet(context),
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFE5E5EA)),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: const Color(0xFFF2F2F7),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          _selectedEmoji ?? _emojiForAccountType(_selectedType),
                          style: const TextStyle(fontSize: 20),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          _selectedType,
                          style: const TextStyle(fontSize: 16, color: Color(0xFF1C1C1E)),
                        ),
                      ),
                      Icon(Icons.keyboard_arrow_down_rounded, color: Colors.grey[600], size: 24),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),
            const Text('Initial balance', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            TextField(
              controller: _balanceController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: InputDecoration(
                hintText: '0',
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              ),
            ),
            if (_isEdit) ...[
              const SizedBox(height: 32),
              TextButton.icon(
                onPressed: () async {
                  final ok = await showDialog<bool>(
                    context: context,
                    builder: (ctx) => AlertDialog(
                      title: const Text('Delete this account?'),
                      content: const Text('This cannot be undone. The account will be permanently removed.'),
                      actions: [
                        TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text('Cancel')),
                        FilledButton(
                          onPressed: () => Navigator.of(ctx).pop(true),
                          style: FilledButton.styleFrom(backgroundColor: const Color(0xFFFF3B30)),
                          child: const Text('Delete'),
                        ),
                      ],
                    ),
                  );
                  if (ok == true && mounted) {
                    final acc = widget.account;
                    if (acc != null) {
                      await ref.read(accountsProvider.notifier).remove(acc.id);
                      if (context.mounted) Navigator.of(context).popUntil((r) => r.settings.name == '/accounts' || r.isFirst);
                    }
                  }
                },
                icon: const Icon(Icons.delete_outline_rounded, color: Color(0xFFFF3B30)),
                label: const Text('Delete account', style: TextStyle(color: Color(0xFFFF3B30))),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
