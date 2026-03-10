import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/dummy_data.dart';
import '../data/models.dart';
import '../providers/app_providers.dart';
import '../providers/currency_provider.dart';
import '../utils/currency_format.dart';
import 'add_edit_preset_screen.dart';
import 'add_transaction_screen.dart';

/// Shows transaction detail in a modal bottom sheet (handle, title, close, details, Update/Delete).
Future<void> showTransactionDetailSheet(BuildContext context, TransactionItem item) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (sheetContext) => _TransactionDetailSheetContent(item: item, parentContext: context),
  );
}

/// For a transfer transaction, returns [From account] and [To account] rows.
List<Widget> _transferAccountRows(
  TransactionItem item,
  List<TransactionItem> transactions,
  List<AccountItem> accounts,
) {
  String fromName = '—';
  String toName = '—';
  if (item.transferPairId != null) {
    TransactionItem? other;
    for (final t in transactions) {
      if (t.transferPairId == item.transferPairId && t.id != item.id) {
        other = t;
        break;
      }
    }
    if (other != null) {
      final fromId = item.amount.trimLeft().startsWith('-') ? item.accountId : other.accountId;
      final toId = item.amount.trimLeft().startsWith('-') ? other.accountId : item.accountId;
      for (final a in accounts) {
        if (a.id == fromId) fromName = a.name;
        if (a.id == toId) toName = a.name;
      }
    }
  }
  return [
    _DetailRow(label: 'From account', value: fromName),
    const SizedBox(height: 12),
    _DetailRow(label: 'To account', value: toName),
  ];
}

String _tagNamesForIds(List<TagItem> allTags, List<String> ids) {
  if (ids.isEmpty) return '—';
  final byId = {for (final t in allTags) t.id: t.name};
  return ids.map((id) => byId[id] ?? '(removed)').join(', ');
}

/// Content of the transaction detail bottom sheet.
class _TransactionDetailSheetContent extends ConsumerWidget {
  const _TransactionDetailSheetContent({required this.item, required this.parentContext});

  final TransactionItem item;
  final BuildContext parentContext;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final media = MediaQuery.of(context);
    final width = media.size.width;
    final isNarrow = width < 360;
    final horizontalPadding = _horizontalPadding(width);
    final bottomPadding = media.padding.bottom;
    final transactions = ref.watch(transactionsProvider).value ?? [];
    final accounts = ref.watch(accountsProvider).value ?? [];

    return Container(
      constraints: BoxConstraints(maxHeight: media.size.height * 0.85),
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
            padding: EdgeInsets.fromLTRB(horizontalPadding, 16, horizontalPadding, 8),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    _typeLabel(item.type),
                    style: const TextStyle(
                      color: Color(0xFF1C1C1E),
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: Icon(Icons.close, color: Colors.grey[700], size: 24),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
                ),
              ],
            ),
          ),
          Flexible(
            child: SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(horizontalPadding, 8, horizontalPadding, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _DetailCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Center(
                          child: Container(
                            width: isNarrow ? 64 : 72,
                            height: isNarrow ? 64 : 72,
                            decoration: BoxDecoration(
                              color: const Color(0xFFF2F2F7),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            alignment: Alignment.center,
                            child: Text(
                              item.type == TransactionType.transferred ? '💸' : item.emoji,
                              style: TextStyle(fontSize: isNarrow ? 32 : 36),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        if (item.type == TransactionType.transferred) ...[
                          ..._transferAccountRows(item, transactions, accounts),
                        ] else ...[
                          _DetailRow(label: 'Category', value: item.categoryName),
                        ],
                        if (item.description != null && item.description!.isNotEmpty) ...[
                          const SizedBox(height: 12),
                          _DetailRow(label: 'Description', value: item.description!),
                        ],
                        if (item.tagIds.isNotEmpty) ...[
                          const SizedBox(height: 12),
                          _DetailRow(
                            label: 'Tags',
                            value: _tagNamesForIds(ref.watch(tagsProvider).value ?? [], item.tagIds),
                          ),
                        ],
                        const SizedBox(height: 12),
                        _DetailRow(label: 'Amount', value: formatStoredAmountWithCurrency(item.amount, ref.watch(selectedCurrencyCodeProvider))),
                        const SizedBox(height: 12),
                        _DetailRow(label: 'Date', value: item.date),
                        const SizedBox(height: 12),
                        _DetailRow(label: 'Time', value: item.time),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => _onSaveAsPreset(context, item),
                          icon: const Icon(Icons.bookmark_add_outlined, size: 20),
                          label: const Text('Save as preset'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: const Color(0xFF1C1C1E),
                            side: const BorderSide(color: Color(0xFFE5E5EA)),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => _onDuplicate(context, item),
                          icon: const Icon(Icons.copy_rounded, size: 20),
                          label: const Text('Duplicate'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: const Color(0xFF1C1C1E),
                            side: const BorderSide(color: Color(0xFFE5E5EA)),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => _onUpdate(context, item),
                          icon: const Icon(Icons.edit_rounded, size: 20),
                          label: const Text('Update'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: const Color(0xFF1C1C1E),
                            side: const BorderSide(color: Color(0xFFE5E5EA)),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: FilledButton.icon(
                          onPressed: () => _onDelete(context, item, parentContext),
                          icon: const Icon(Icons.delete_outline_rounded, size: 20),
                          label: const Text('Delete'),
                          style: FilledButton.styleFrom(
                            backgroundColor: const Color(0xFFFF3B30),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: bottomPadding + 8),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  static String _typeLabel(TransactionType type) {
    switch (type) {
      case TransactionType.deducted:
        return 'Spend';
      case TransactionType.added:
        return 'Income';
      case TransactionType.transferred:
        return 'Transfer';
    }
  }

  static double _horizontalPadding(double width) {
    if (width < 360) return 16;
    if (width > 600) return 24;
    return 20;
  }

  static void _onUpdate(BuildContext context, TransactionItem item) {
    Navigator.of(context).pop();
    Navigator.of(context).push(
      MaterialPageRoute<bool>(
        builder: (context) => AddTransactionScreen(editFrom: item),
      ),
    );
  }

  static void _onDuplicate(BuildContext context, TransactionItem item) {
    Navigator.of(context).pop();
    Navigator.of(context).push(
      MaterialPageRoute<bool>(
        builder: (context) => AddTransactionScreen(duplicateFrom: item),
      ),
    );
  }

  static void _onSaveAsPreset(BuildContext context, TransactionItem item) {
    Navigator.of(context).pop();
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (context) => AddEditPresetScreen(fromTransaction: item),
      ),
    );
  }

  static Future<void> _onDelete(BuildContext context, TransactionItem item, BuildContext parentContext) async {
    final currencyCode = ProviderScope.containerOf(parentContext).read(selectedCurrencyCodeProvider);
    final formattedAmount = formatStoredAmountWithCurrency(item.amount, currencyCode);
    final label = item.type == TransactionType.transferred ? 'Transfer' : item.categoryName;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete transaction?'),
        content: Text('$label – $formattedAmount will be removed.'),
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
    if (confirmed == true && context.mounted) {
      ProviderScope.containerOf(parentContext).read(transactionsProvider.notifier).removeById(item.id);
      Navigator.of(context).pop();
    }
  }
}

/// Full-screen transaction detail (kept for route /transaction-detail).
class TransactionDetailScreen extends ConsumerWidget {
  const TransactionDetailScreen({super.key});

  static const String routeName = '/transaction-detail';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final item = ModalRoute.of(context)!.settings.arguments! as TransactionItem;
    final media = MediaQuery.of(context);
    final width = media.size.width;
    final isNarrow = width < 360;
    final horizontalPadding = _horizontalPadding(width);

    return Scaffold(
      backgroundColor: const Color(0xFFF2F2F7),
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          'Transaction',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: EdgeInsets.all(horizontalPadding),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 20),
                  _DetailCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Center(
                          child: Container(
                            width: isNarrow ? 64 : 72,
                            height: isNarrow ? 64 : 72,
                            decoration: BoxDecoration(
                              color: const Color(0xFFF2F2F7),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            alignment: Alignment.center,
                            child: Text(
                              item.type == TransactionType.transferred ? '💸' : item.emoji,
                              style: TextStyle(fontSize: isNarrow ? 32 : 36),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        if (item.type == TransactionType.transferred) ...[
                          ..._transferAccountRows(item, ref.watch(transactionsProvider).value ?? [], ref.watch(accountsProvider).value ?? []),
                        ] else ...[
                          _DetailRow(label: 'Category', value: item.categoryName),
                        ],
                        if (item.description != null && item.description!.isNotEmpty) ...[
                          const SizedBox(height: 12),
                          _DetailRow(label: 'Description', value: item.description!),
                        ],
                        const SizedBox(height: 12),
                        _DetailRow(label: 'Amount', value: formatStoredAmountWithCurrency(item.amount, ref.watch(selectedCurrencyCodeProvider))),
                        const SizedBox(height: 12),
                        _DetailRow(label: 'Date', value: item.date),
                        const SizedBox(height: 12),
                        _DetailRow(label: 'Time', value: item.time),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
            Container(
              padding: EdgeInsets.fromLTRB(horizontalPadding, 16, horizontalPadding, 16 + media.padding.bottom),
              decoration: BoxDecoration(
                color: const Color(0xFFFAFAFA),
                border: Border(top: BorderSide(color: const Color(0xFFE5E5EA))),
              ),
              child: SafeArea(
                top: false,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () => _onSaveAsPresetFullScreen(context, item),
                            icon: const Icon(Icons.bookmark_add_outlined, size: 20),
                            label: const Text('Save as preset'),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: const Color(0xFF1C1C1E),
                              side: const BorderSide(color: Color(0xFFE5E5EA)),
                              padding: const EdgeInsets.symmetric(vertical: 14),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () => _onDuplicateFullScreen(context, item),
                            icon: const Icon(Icons.copy_rounded, size: 20),
                            label: const Text('Duplicate'),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: const Color(0xFF1C1C1E),
                              side: const BorderSide(color: Color(0xFFE5E5EA)),
                              padding: const EdgeInsets.symmetric(vertical: 14),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () => _onUpdate(context, item),
                            icon: const Icon(Icons.edit_rounded, size: 20),
                            label: const Text('Update'),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: const Color(0xFF1C1C1E),
                              side: const BorderSide(color: Color(0xFFE5E5EA)),
                              padding: const EdgeInsets.symmetric(vertical: 14),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: FilledButton.icon(
                            onPressed: () => _onDelete(context, item, context),
                            icon: const Icon(Icons.delete_outline_rounded, size: 20),
                            label: const Text('Delete'),
                            style: FilledButton.styleFrom(
                              backgroundColor: const Color(0xFFFF3B30),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  double _horizontalPadding(double width) {
    if (width < 360) return 16;
    if (width > 600) return 24;
    return 20;
  }

  void _onDuplicateFullScreen(BuildContext context, TransactionItem item) {
    Navigator.of(context).push(
      MaterialPageRoute<bool>(
        builder: (context) => AddTransactionScreen(duplicateFrom: item),
      ),
    );
  }

  void _onUpdate(BuildContext context, TransactionItem item) {
    Navigator.of(context).push(
      MaterialPageRoute<bool>(
        builder: (context) => AddTransactionScreen(editFrom: item),
      ),
    ).then((_) {});
  }

  void _onSaveAsPresetFullScreen(BuildContext context, TransactionItem item) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (context) => AddEditPresetScreen(fromTransaction: item),
      ),
    );
  }

  Future<void> _onDelete(BuildContext context, TransactionItem item, BuildContext providerContext) async {
    final currencyCode = ProviderScope.containerOf(providerContext).read(selectedCurrencyCodeProvider);
    final formattedAmount = formatStoredAmountWithCurrency(item.amount, currencyCode);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete transaction?'),
        content: Text(
          '${item.type == TransactionType.transferred ? "Transfer" : item.categoryName} – $formattedAmount will be removed.',
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
      ProviderScope.containerOf(providerContext).read(transactionsProvider.notifier).removeById(item.id);
      Navigator.of(context).pop();
    }
  }
}

class _DetailCard extends StatelessWidget {
  const _DetailCard({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFFFAFAFA),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE5E5EA)),
      ),
      child: child,
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 100,
          child: Text(
            label,
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 14,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              color: Color(0xFF1C1C1E),
              fontSize: 15,
              fontWeight: FontWeight.w400,
            ),
          ),
        ),
      ],
    );
  }
}
