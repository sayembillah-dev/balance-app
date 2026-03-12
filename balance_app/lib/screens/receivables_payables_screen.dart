import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/models.dart';
import '../providers/app_providers.dart';
import '../providers/currency_provider.dart';
import '../utils/currency_format.dart';
import '../widgets/app_drawer.dart';

/// Simple placeholder screen for Receivables & Payables.
class ReceivablesPayablesScreen extends ConsumerStatefulWidget {
  const ReceivablesPayablesScreen({super.key});

  @override
  ConsumerState<ReceivablesPayablesScreen> createState() =>
      _ReceivablesPayablesScreenState();
}

class _ReceivablesPayablesScreenState
    extends ConsumerState<ReceivablesPayablesScreen>
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

  Future<void> _showAddItemSheet({
    required bool isReceivable,
    ReceivablePayableItem? existingItem,
  }) async {
    final nameController = TextEditingController();
    final amountController = TextEditingController();
    final notesController = TextEditingController();
    DateTime? selectedDueDate;
    final formKey = GlobalKey<FormState>();

    if (existingItem != null) {
      nameController.text = existingItem.name;
      amountController.text = formatAmountTruncated(existingItem.amount);
      if (existingItem.notes != null) {
        notesController.text = existingItem.notes!;
      }
      selectedDueDate = existingItem.dueDate;
    }

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        final media = MediaQuery.of(context);
        final bottomInset = media.viewInsets.bottom;
        final isNarrow = media.size.width < 360;
        final padding = isNarrow ? 16.0 : 20.0;

        return Padding(
          padding: EdgeInsets.only(
            left: padding,
            right: padding,
            top: 16,
            bottom: bottomInset + 16,
          ),
          child: StatefulBuilder(
            builder: (context, setModalState) {
              String? dueDateLabel;
              if (selectedDueDate != null) {
                final d = selectedDueDate!;
                dueDateLabel =
                    '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
              }

              return Form(
                key: formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          existingItem != null
                              ? (isReceivable
                                    ? 'Edit receivable'
                                    : 'Edit payable')
                              : (isReceivable
                                    ? 'Add receivable'
                                    : 'Add payable'),
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close_rounded),
                          onPressed: () => Navigator.of(context).pop(),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: nameController,
                      decoration: const InputDecoration(
                        labelText: 'Name / Person',
                        border: OutlineInputBorder(),
                      ),
                      textInputAction: TextInputAction.next,
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Please enter a name or person';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: amountController,
                      decoration: const InputDecoration(
                        labelText: 'Amount',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      textInputAction: TextInputAction.next,
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Please enter an amount';
                        }
                        final parsed = double.tryParse(
                          value.trim().replaceAll(',', ''),
                        );
                        if (parsed == null || parsed <= 0) {
                          return 'Enter a valid amount greater than 0';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            icon: const Icon(Icons.calendar_today_rounded),
                            label: Text(
                              dueDateLabel ?? 'Due date (optional)',
                              overflow: TextOverflow.ellipsis,
                            ),
                            onPressed: () async {
                              final now = DateTime.now();
                              final picked = await showDatePicker(
                                context: context,
                                initialDate: selectedDueDate ?? now,
                                firstDate: DateTime(now.year - 5),
                                lastDate: DateTime(now.year + 5),
                              );
                              if (picked != null) {
                                setModalState(() {
                                  selectedDueDate = picked;
                                });
                              }
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: notesController,
                      decoration: const InputDecoration(
                        labelText: 'Notes (optional)',
                        border: OutlineInputBorder(),
                      ),
                      maxLines: 3,
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton(
                        onPressed: () async {
                          if (!formKey.currentState!.validate()) return;
                          final amount = double.parse(
                            amountController.text.trim().replaceAll(',', ''),
                          );
                          final notifier = ref.read(
                            receivablesPayablesProvider.notifier,
                          );
                          if (existingItem != null) {
                            final updated = existingItem.copyWith(
                              name: nameController.text.trim(),
                              amount: amount,
                              dueDate: selectedDueDate,
                              notes: notesController.text.trim().isEmpty
                                  ? null
                                  : notesController.text.trim(),
                            );
                            await notifier.replaceById(
                              existingItem.id,
                              updated,
                            );
                          } else {
                            final id = notifier.nextId();
                            final now = DateTime.now();
                            final item = ReceivablePayableItem(
                              id: id,
                              isReceivable: isReceivable,
                              name: nameController.text.trim(),
                              amount: amount,
                              status: ReceivablePayableStatus.pending,
                              createdAt: now,
                              dueDate: selectedDueDate,
                              notes: notesController.text.trim().isEmpty
                                  ? null
                                  : notesController.text.trim(),
                              completedAt: null,
                            );
                            await notifier.add(item);
                          }
                          Navigator.of(context).pop();
                        },
                        style: FilledButton.styleFrom(
                          backgroundColor: Colors.black,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text('Save'),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    final width = media.size.width;
    final isNarrow = width < 360;
    final padding = isNarrow ? 16.0 : 20.0;
    final size = MediaQuery.sizeOf(context);
    final drawerWidth = (size.width * 0.68).clamp(260.0, 320.0);
    const cardRadius = 20.0;

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
                      child: DefaultTabController(
                        length: 2,
                        child: Scaffold(
                          backgroundColor: const Color(0xFFF2F2F7),
                          appBar: AppBar(
                            leading: const SizedBox.shrink(),
                            leadingWidth: 0,
                            title: const Align(
                              alignment: Alignment.centerLeft,
                              child: Text(
                                'Receivables & Payables',
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
                            bottom: TabBar(
                              indicatorColor: Colors.white,
                              indicatorWeight: 3,
                              labelColor: Colors.white,
                              unselectedLabelColor: const Color.fromARGB(
                                255,
                                161,
                                160,
                                160,
                              ),
                              labelStyle: const TextStyle(
                                fontWeight: FontWeight.w600,
                              ),
                              tabs: const [
                                Tab(text: 'Receivables'),
                                Tab(text: 'Payables'),
                              ],
                            ),
                            backgroundColor: Colors.black,
                            foregroundColor: Colors.white,
                            elevation: 0,
                            scrolledUnderElevation: 0,
                          ),
                          body: Builder(
                            builder: (context) {
                              final asyncItems =
                                  ref.watch(receivablesPayablesProvider);
                              final currencyCode =
                                  ref.watch(selectedCurrencyCodeProvider);
                              final totalBalance =
                                  ref.watch(balanceValueProvider);
                              final items = asyncItems.value ?? [];
                              final receivables = items
                                  .where((e) => e.isReceivable)
                                  .toList();
                              final payables = items
                                  .where((e) => !e.isReceivable)
                                  .toList();

                              return TabBarView(
                                children: [
                                  _ItemsListTab(
                                    items: receivables,
                                    padding: padding,
                                    currencyCode: currencyCode,
                                    totalLabel: 'Total receivables',
                                    emptyTitle: 'No receivables yet',
                                    emptySubtitle:
                                        'Add money that others owe you. New items start with status Pending.',
                                    onEdit: (item) {
                                      _showAddItemSheet(
                                        isReceivable: true,
                                        existingItem: item,
                                      );
                                    },
                                    onDelete: (item) {
                                      _deleteItemWithUndo(item);
                                    },
                                    onChangeStatus: (item) async {
                                      await ref
                                          .read(
                                            receivablesPayablesProvider
                                                .notifier,
                                          )
                                          .toggleStatus(item.id);
                                    },
                                  ),
                                  _ItemsListTab(
                                    items: payables,
                                    padding: padding,
                                    currencyCode: currencyCode,
                                    totalBalance: totalBalance,
                                    totalLabel: 'Total payables',
                                    emptyTitle: 'No payables yet',
                                    emptySubtitle:
                                        'Add money that you owe others. New items start with status Pending.',
                                    onEdit: (item) {
                                      _showAddItemSheet(
                                        isReceivable: false,
                                        existingItem: item,
                                      );
                                    },
                                    onDelete: (item) {
                                      _deleteItemWithUndo(item);
                                    },
                                    onChangeStatus: (item) async {
                                      await ref
                                          .read(
                                            receivablesPayablesProvider
                                                .notifier,
                                          )
                                          .toggleStatus(item.id);
                                    },
                                  ),
                                ],
                              );
                            },
                          ),
                          floatingActionButton: Builder(
                            builder: (context) {
                              final controller = DefaultTabController.of(
                                context,
                              );
                              return FloatingActionButton(
                                onPressed: () {
                                  final isReceivablesTab =
                                      controller.index == 0;
                                  _showAddItemSheet(
                                    isReceivable: isReceivablesTab,
                                  );
                                },
                                tooltip: 'Add item',
                                backgroundColor: Colors.black,
                                foregroundColor: Colors.white,
                                elevation: 2,
                                focusElevation: 4,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: const Icon(Icons.add, size: 28),
                              );
                            },
                          ),
                          floatingActionButtonLocation:
                              FloatingActionButtonLocation.endFloat,
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

  Future<void> _deleteItemWithUndo(ReceivablePayableItem item) async {
    final notifier = ref.read(receivablesPayablesProvider.notifier);
    await notifier.removeById(item.id);
    if (!mounted) return;
    final kindLabel = item.isReceivable ? 'receivable' : 'payable';
    final messenger = ScaffoldMessenger.of(context);
    late final ScaffoldFeatureController<SnackBar, SnackBarClosedReason>
    controller;
    controller = messenger.showSnackBar(
      SnackBar(
        content: Text(
          'Deleted $kindLabel "${item.name}"',
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
        action: SnackBarAction(
          label: 'UNDO',
          onPressed: () async {
            await notifier.add(item);
            controller.close();
          },
        ),
      ),
    );
    Future<void>.delayed(const Duration(seconds: 2)).then((_) {
      if (mounted) {
        controller.close();
      }
    });
  }
}

class _ItemsListTab extends StatelessWidget {
  const _ItemsListTab({
    required this.items,
    required this.padding,
    required this.currencyCode,
    this.totalBalance,
    required this.totalLabel,
    required this.emptyTitle,
    required this.emptySubtitle,
    required this.onEdit,
    required this.onDelete,
    required this.onChangeStatus,
  });

  final List<ReceivablePayableItem> items;
  final double padding;
  final String currencyCode;
  final double? totalBalance;
  final String totalLabel;
  final String emptyTitle;
  final String emptySubtitle;
  final void Function(ReceivablePayableItem item) onEdit;
  final void Function(ReceivablePayableItem item) onDelete;
  final void Function(ReceivablePayableItem item) onChangeStatus;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return Center(
        child: Padding(
          padding: EdgeInsets.all(padding),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Icon(
                Icons.assignment_outlined,
                size: 64,
                color: Colors.grey[500],
              ),
              const SizedBox(height: 16),
              Text(
                emptyTitle,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey[800],
                ),
              ),
              const SizedBox(height: 8),
              Text(
                emptySubtitle,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  height: 1.4,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
        ),
      );
    }

    final activeItems = <ReceivablePayableItem>[];
    final archivedItems = <ReceivablePayableItem>[];

    for (final item in items) {
      if (item.status == ReceivablePayableStatus.completed) {
        archivedItems.add(item);
      } else {
        activeItems.add(item);
      }
    }

    int _compareByDueThenCreated(
      ReceivablePayableItem a,
      ReceivablePayableItem b,
    ) {
      final ad = a.dueDate;
      final bd = b.dueDate;
      if (ad != null && bd != null) {
        final cmp = ad.compareTo(bd);
        if (cmp != 0) return cmp;
      } else if (ad != null && bd == null) {
        return -1;
      } else if (ad == null && bd != null) {
        return 1;
      }
      // Newest created first
      return b.createdAt.compareTo(a.createdAt);
    }

    activeItems.sort(_compareByDueThenCreated);

    archivedItems.sort((a, b) {
      final ac = a.completedAt ?? a.createdAt;
      final bc = b.completedAt ?? b.createdAt;
      return bc.compareTo(ac); // newest completed first
    });

    final total = items.fold<double>(0, (sum, e) => sum + e.amount);
    final pendingTotal =
        activeItems.fold<double>(0, (sum, e) => sum + e.amount);
    final archivedTotal =
        archivedItems.fold<double>(0, (sum, e) => sum + e.amount);
    // Only compare PENDING payables to balance; completed ones are ignored.
    final showBalanceWarning = totalBalance != null &&
        pendingTotal > (totalBalance! + 0.0001);

    Widget buildCard(ReceivablePayableItem item, {required bool isArchived}) {
      final dueDate = item.dueDate;
      String? dueLabel;
      if (dueDate != null) {
        dueLabel =
            '${dueDate.year}-${dueDate.month.toString().padLeft(2, '0')}-${dueDate.day.toString().padLeft(2, '0')}';
      }

      final baseTextColor = isArchived
          ? Colors.grey[500]
          : const Color(0xFF1C1C1E);

      return Material(
        color: isArchived ? const Color(0xFFF4F4F4) : Colors.white,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: () async {
            final action = await showModalBottomSheet<_CardAction>(
              context: context,
              backgroundColor: Colors.white,
              shape: const RoundedRectangleBorder(
                borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
              ),
              builder: (context) {
                final toggleLabel =
                    item.status == ReceivablePayableStatus.pending
                        ? 'Mark as Completed'
                        : 'Mark as Pending';
                return SafeArea(
                  top: false,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          item.name,
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: baseTextColor,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Amount: ${item.amount.toStringAsFixed(2)}',
                          style: TextStyle(fontSize: 14, color: baseTextColor),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Status: ${item.status == ReceivablePayableStatus.pending ? 'Pending' : 'Completed'}',
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey[600],
                          ),
                        ),
                        if (dueLabel != null) ...[
                          const SizedBox(height: 4),
                          Text(
                            'Due: $dueLabel',
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                        if (item.notes != null && item.notes!.isNotEmpty) ...[
                          const SizedBox(height: 6),
                          Text(
                            item.notes!,
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.grey[800],
                            ),
                          ),
                        ],
                        const SizedBox(height: 12),
                        const Divider(height: 1),
                        ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: const Icon(Icons.edit_rounded),
                          title: const Text('Edit'),
                          onTap: () =>
                              Navigator.of(context).pop(_CardAction.edit),
                        ),
                        ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: const Icon(Icons.checklist_rtl_rounded),
                          title: Text(toggleLabel),
                          onTap: () => Navigator.of(
                            context,
                          ).pop(_CardAction.toggleStatus),
                        ),
                        ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: const Icon(
                            Icons.delete_rounded,
                            color: Colors.red,
                          ),
                          title: const Text(
                            'Delete',
                            style: TextStyle(color: Colors.red),
                          ),
                          onTap: () =>
                              Navigator.of(context).pop(_CardAction.delete),
                        ),
                      ],
                    ),
                  ),
                );
              },
            );

            if (action == null) return;
            switch (action) {
              case _CardAction.edit:
                onEdit(item);
                break;
              case _CardAction.delete:
                onDelete(item);
                break;
              case _CardAction.toggleStatus:
                onChangeStatus(item);
                break;
            }
          },
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(
                  child: Text(
                    item.name,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: baseTextColor,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  formatAmountWithCurrency(item.amount, currencyCode),
                  style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w400,
                  color: isArchived ? Colors.grey[600] : Colors.grey[800],
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final listChildren = <Widget>[];

    for (var i = 0; i < activeItems.length; i++) {
      listChildren.add(buildCard(activeItems[i], isArchived: false));
      if (i != activeItems.length - 1) {
        listChildren.add(const SizedBox(height: 10));
      }
    }

    if (archivedItems.isNotEmpty) {
      if (listChildren.isNotEmpty) {
        listChildren.add(const SizedBox(height: 20));
      }
      listChildren.add(
        Text(
                    'Completed',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: Colors.grey[600],
            letterSpacing: 0.2,
          ),
        ),
      );
      listChildren.add(const SizedBox(height: 8));
      for (var i = 0; i < archivedItems.length; i++) {
        listChildren.add(buildCard(archivedItems[i], isArchived: true));
        if (i != archivedItems.length - 1) {
          listChildren.add(const SizedBox(height: 10));
        }
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: EdgeInsets.fromLTRB(padding, 12, padding, 4),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        totalLabel,
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey[600],
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        formatAmountWithCurrency(total, currencyCode),
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF1C1C1E),
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  width: 1,
                  height: 40,
                  margin: const EdgeInsets.symmetric(horizontal: 12),
                  color: Colors.grey[300],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      'Pending',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                    Text(
                      formatAmountWithCurrency(pendingTotal, currencyCode),
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFF1C1C1E),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Completed',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                    Text(
                    formatAmountWithCurrency(archivedTotal, currencyCode),
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFF1C1C1E),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        if (showBalanceWarning)
          Padding(
            padding: EdgeInsets.fromLTRB(padding, 4, padding, 0),
            child: Text(
              'Warning: total payables exceed your current balance.',
              style: TextStyle(
                fontSize: 12,
                color: Colors.red[600],
              ),
            ),
          ),
        Expanded(
          child: Padding(
            padding: EdgeInsets.all(padding),
            child: ListView(children: listChildren),
          ),
        ),
      ],
    );
  }
}

enum _CardAction { edit, delete, toggleStatus }
