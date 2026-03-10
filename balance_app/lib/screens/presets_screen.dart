import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/dummy_data.dart';
import '../providers/app_providers.dart';
import '../widgets/app_drawer.dart';
import 'add_edit_preset_screen.dart';

/// Presets list. Tap to edit; FAB to add; delete from edit screen.
class PresetsScreen extends ConsumerStatefulWidget {
  const PresetsScreen({super.key});

  @override
  ConsumerState<PresetsScreen> createState() => _PresetsScreenState();
}

class _PresetsScreenState extends ConsumerState<PresetsScreen>
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

  void _showPresetInfo() {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.info_outline_rounded, color: Theme.of(context).colorScheme.primary),
            const SizedBox(width: 10),
            const Text('About Presets'),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'What are Presets?',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 15,
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                'Presets are saved transaction templates. Instead of entering the same details every time (e.g. account, category, description), you create a preset once and apply it when adding a transaction to fill in the fields automatically.',
                style: TextStyle(fontSize: 14, height: 1.4),
              ),
              const SizedBox(height: 16),
              const Text(
                'How it works',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 15,
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                '• Create a preset from this page (tap +) or save one when adding or editing a transaction.\n\n'
                '• Each preset can store: transaction type (spend/income/transfer), account(s), category, subcategory, description, and optionally a default amount.\n\n'
                '• When adding a transaction, you can pick a preset to pre-fill the form. You can still change any field before saving.',
                style: TextStyle(fontSize: 14, height: 1.4),
              ),
              const SizedBox(height: 16),
              const Text(
                'Instructions',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 15,
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                '1. Tap + to create a new preset. Set a name and the fields you want to reuse (category, account, etc.).\n\n'
                '2. Tap a preset card here to use it: you\'ll go to Add Transaction with the preset applied.\n\n'
                '3. When adding or editing a transaction, use "Save as preset" to create a preset from the current transaction.\n\n'
                '4. Edit or delete a preset by tapping it, then use the edit or delete option on the edit screen.',
                style: TextStyle(fontSize: 14, height: 1.4),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Got it'),
          ),
        ],
      ),
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
    final presets = ref.watch(presetsProvider).value ?? [];

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
                      child: Scaffold(
                        backgroundColor: const Color(0xFFF2F2F7),
                        appBar: AppBar(
                          leading: const SizedBox.shrink(),
                          leadingWidth: 0,
                          title: const Align(
                            alignment: Alignment.centerLeft,
                            child: Text(
                              'Presets',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          actions: [
                            IconButton(
                              icon: const Icon(Icons.info_outline_rounded),
                              onPressed: _showPresetInfo,
                              tooltip: 'About presets',
                            ),
                            IconButton(
                              icon: const Icon(Icons.menu_rounded),
                              onPressed: _openDrawer,
                            ),
                          ],
                          backgroundColor: Colors.black,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          scrolledUnderElevation: 0,
                        ),
                        body: presets.isEmpty
                            ? Center(
                                child: Padding(
                                  padding: const EdgeInsets.all(24),
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        Icons.bookmark_border_rounded,
                                        size: 64,
                                        color: Colors.grey[400],
                                      ),
                                      const SizedBox(height: 16),
                                      Text(
                                        'No presets yet',
                                        style: TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.w600,
                                          color: Colors.grey[700],
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        'Create presets to quickly fill Add Transaction',
                                        textAlign: TextAlign.center,
                                        style: TextStyle(
                                          fontSize: 14,
                                          color: Colors.grey[600],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              )
                            : ListView.builder(
                                padding: EdgeInsets.fromLTRB(
                                  padding,
                                  16,
                                  padding,
                                  24 + media.padding.bottom,
                                ),
                                itemCount: presets.length,
                                itemBuilder: (context, index) {
                                  final preset = presets[index];
                                  return Padding(
                                    padding: const EdgeInsets.only(bottom: 12),
                                    child: _PresetListCard(
                                      preset: preset,
                                      categories: ref.watch(categoriesProvider).value ?? [],
                                      isNarrow: isNarrow,
                                      onTap: () async {
                                        await Navigator.of(context).push(
                                          MaterialPageRoute(
                                            builder: (context) =>
                                                AddEditPresetScreen(
                                              preset: preset,
                                            ),
                                          ),
                                        );
                                        if (mounted) setState(() {});
                                      },
                                    ),
                                  );
                                },
                              ),
                        floatingActionButton: FloatingActionButton(
                          onPressed: () async {
                            final added = await Navigator.of(context).push<bool>(
                              MaterialPageRoute(
                                builder: (context) =>
                                    const AddEditPresetScreen(),
                              ),
                            );
                            if (added == true && mounted) setState(() {});
                          },
                          backgroundColor: Colors.black,
                          foregroundColor: Colors.white,
                          child: const Icon(Icons.add, size: 28),
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
}

class _PresetListCard extends StatelessWidget {
  const _PresetListCard({
    required this.preset,
    required this.categories,
    required this.isNarrow,
    required this.onTap,
  });

  final PresetItem preset;
  final List<TransactionCategory> categories;
  final bool isNarrow;
  final VoidCallback onTap;

  static String _typeLabel(TransactionType t) {
    switch (t) {
      case TransactionType.deducted:
        return 'Spend';
      case TransactionType.added:
        return 'Income';
      case TransactionType.transferred:
        return 'Transfer';
    }
  }

  @override
  Widget build(BuildContext context) {
    TransactionCategory? cat;
    if (preset.categoryId != null) {
      try {
        cat = categories.firstWhere((c) => c.id == preset.categoryId);
      } catch (_) {}
    }
    final subLabel = preset.subcategoryName ?? (cat?.name ?? '—');
    final emoji = cat?.emoji ?? '📌';

    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: EdgeInsets.all(isNarrow ? 14 : 18),
          child: Row(
            children: [
              Container(
                width: isNarrow ? 48 : 56,
                height: isNarrow ? 48 : 56,
                decoration: BoxDecoration(
                  color: const Color(0xFFF2F2F7),
                  borderRadius: BorderRadius.circular(14),
                ),
                alignment: Alignment.center,
                child: Text(emoji, style: TextStyle(fontSize: isNarrow ? 26 : 30)),
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
                        color: const Color(0xFF1C1C1E),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${_typeLabel(preset.transactionType)} · $subLabel',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right_rounded, color: Colors.grey[400], size: 28),
            ],
          ),
        ),
      ),
    );
  }
}
