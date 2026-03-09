import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/dummy_data.dart';
import '../providers/app_providers.dart';
import 'add_edit_subcategory_screen.dart';
import 'add_edit_category_screen.dart';

/// Subcategories for one category. Tap to show/hide in lists; long-press drag to reorder; add subcategory; edit/delete only user-created.
class CategoryDetailScreen extends ConsumerStatefulWidget {
  const CategoryDetailScreen({
    super.key,
    required this.category,
    required this.onCategoryUpdated,
  });

  final TransactionCategory category;
  final VoidCallback onCategoryUpdated;

  @override
  ConsumerState<CategoryDetailScreen> createState() => _CategoryDetailScreenState();
}

class _CategoryDetailScreenState extends ConsumerState<CategoryDetailScreen> {
  TransactionCategory _category(List<TransactionCategory> list) {
    final i = list.indexWhere((c) => c.id == widget.category.id);
    return i >= 0 ? list[i] : widget.category;
  }

  void _replaceCategory(TransactionCategory updated) {
    ref.read(categoriesProvider.notifier).replaceById(updated.id, updated);
    widget.onCategoryUpdated();
    setState(() {});
  }

  void _showSubcategoryOptions(SubcategoryItem sub) {
    final theme = Theme.of(context);
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 8),
              Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                child: Row(
                  children: [
                    Text(sub.emoji, style: const TextStyle(fontSize: 28)),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        sub.name,
                        style: theme.textTheme.titleMedium,
                      ),
                    ),
                  ],
                ),
              ),
              ListTile(
                leading: Icon(
                  sub.isHidden ? Icons.visibility_off_rounded : Icons.visibility_rounded,
                  color: Colors.black87,
                ),
                title: Text(sub.isHidden ? 'Show in lists' : 'Hide from lists'),
                subtitle: Text(
                  sub.isHidden
                      ? 'Include in Add Transaction and other pickers'
                      : 'Exclude from category pickers',
                  style: theme.textTheme.bodySmall,
                ),
                onTap: () {
                  Navigator.pop(context);
                  _toggleSubcategoryVisibility(sub);
                },
              ),
              if (sub.isUserCreated) ...[
                ListTile(
                  leading: const Icon(Icons.edit_rounded, color: Colors.black87),
                  title: const Text('Edit subcategory'),
                  onTap: () {
                    Navigator.pop(context);
                    _editSubcategory(sub);
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.delete_outline_rounded, color: Colors.red),
                  title: const Text('Delete subcategory', style: TextStyle(color: Colors.red)),
                  onTap: () {
                    Navigator.pop(context);
                    _deleteSubcategory(sub);
                  },
                ),
              ],
              SizedBox(height: MediaQuery.of(context).padding.bottom + 8),
            ],
          ),
        ),
      ),
    );
  }

  void _toggleSubcategoryVisibility(SubcategoryItem sub) {
    final list = ref.read(categoriesProvider).value ?? [];
    final cat = _category(list);
    final newSubs = cat.subcategories.map((s) {
      if (s.name == sub.name && s.emoji == sub.emoji && s.id == sub.id) {
        return s.copyWith(isHidden: !s.isHidden);
      }
      return s;
    }).toList();
    _replaceCategory(cat.copyWith(subcategories: newSubs));
  }

  Future<void> _editSubcategory(SubcategoryItem sub) async {
    final list = ref.read(categoriesProvider).value ?? [];
    final cat = _category(list);
    await Navigator.of(context).push<SubcategoryItem?>(
      MaterialPageRoute(
        builder: (context) => AddEditSubcategoryScreen(
          category: cat,
          existing: sub,
        ),
      ),
    );
    if (mounted) {
      setState(() {});
      widget.onCategoryUpdated();
    }
  }

  void _deleteSubcategory(SubcategoryItem sub) {
    final list = ref.read(categoriesProvider).value ?? [];
    final cat = _category(list);
    final newSubs = cat.subcategories.where((s) => s.id != sub.id && !(s.name == sub.name && s.isUserCreated)).toList();
    _replaceCategory(cat.copyWith(subcategories: newSubs));
  }

  Future<void> _editCategory() async {
    final list = ref.read(categoriesProvider).value ?? [];
    final cat = _category(list);
    if (!cat.isUserCreated) return;
    final updated = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (context) => AddEditCategoryScreen(category: cat),
      ),
    );
    if (updated == true && mounted) {
      final listAfter = ref.read(categoriesProvider).value ?? [];
      final stillExists = listAfter.any((c) => c.id == widget.category.id);
      if (!stillExists) {
        Navigator.of(context).pop();
        widget.onCategoryUpdated();
        return;
      }
      setState(() {});
      widget.onCategoryUpdated();
    }
  }

  Future<void> _addSubcategory() async {
    final list = ref.read(categoriesProvider).value ?? [];
    await Navigator.of(context).push<SubcategoryItem?>(
      MaterialPageRoute(
        builder: (context) => AddEditSubcategoryScreen(category: _category(list)),
      ),
    );
    if (mounted) {
      setState(() {});
      widget.onCategoryUpdated();
    }
  }

  void _onReorderSubcategories(int oldIndex, int newIndex) {
    final list = ref.read(categoriesProvider).value ?? [];
    final cat = _category(list);
    final subs = List<SubcategoryItem>.from(cat.subcategories);
    if (newIndex > oldIndex) newIndex--;
    final item = subs.removeAt(oldIndex);
    subs.insert(newIndex, item);
    _replaceCategory(cat.copyWith(subcategories: subs));
  }

  @override
  Widget build(BuildContext context) {
    final categoriesList = ref.watch(categoriesProvider).value ?? [];
    final category = _category(categoriesList);
    final media = MediaQuery.of(context);
    final width = media.size.width;
    final isNarrow = width < 360;
    final padding = isNarrow ? 16.0 : 20.0;

    return Scaffold(
      backgroundColor: const Color(0xFFF2F2F7),
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Row(
          children: [
            Text(category.emoji, style: const TextStyle(fontSize: 24)),
            const SizedBox(width: 8),
            Text(
              category.name,
              style: const TextStyle(
                color: Color(0xFF1C1C1E),
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF1C1C1E),
        elevation: 0,
        scrolledUnderElevation: 0,
        actions: [
          if (category.isUserCreated)
            IconButton(
              icon: const Icon(Icons.edit_rounded),
              onPressed: _editCategory,
            ),
        ],
      ),
      body: ReorderableListView.builder(
        padding: EdgeInsets.fromLTRB(padding, 16, padding, 24 + media.padding.bottom),
        buildDefaultDragHandles: false,
        onReorder: _onReorderSubcategories,
        itemCount: category.subcategories.length,
        itemBuilder: (context, index) {
          final sub = category.subcategories[index];
          return Padding(
            key: ValueKey('${sub.id ?? sub.name}_$index'),
            padding: const EdgeInsets.only(bottom: 12),
            child: _SubcategoryListCard(
              subcategory: sub,
              index: index,
              isNarrow: isNarrow,
              onTap: () => _showSubcategoryOptions(sub),
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addSubcategory,
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        child: const Icon(Icons.add, size: 28),
      ),
    );
  }
}

class _SubcategoryListCard extends StatelessWidget {
  const _SubcategoryListCard({
    required this.subcategory,
    required this.index,
    required this.isNarrow,
    required this.onTap,
  });

  final SubcategoryItem subcategory;
  final int index;
  final bool isNarrow;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
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
                width: isNarrow ? 44 : 50,
                height: isNarrow ? 44 : 50,
                decoration: BoxDecoration(
                  color: const Color(0xFFF2F2F7),
                  borderRadius: BorderRadius.circular(12),
                ),
                alignment: Alignment.center,
                child: Text(
                  subcategory.emoji,
                  style: TextStyle(fontSize: isNarrow ? 22 : 26),
                ),
              ),
              SizedBox(width: isNarrow ? 12 : 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      subcategory.name,
                      style: TextStyle(
                        fontSize: isNarrow ? 16 : 17,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF1C1C1E),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subcategory.isHidden ? 'Hidden from lists' : 'Shown in lists',
                      style: TextStyle(
                        fontSize: 12,
                        color: subcategory.isHidden ? Colors.orange[700] : Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
              ReorderableDragStartListener(
                index: index,
                child: Padding(
                  padding: const EdgeInsets.all(8),
                  child: Icon(
                    Icons.drag_handle_rounded,
                    color: Colors.grey[400],
                    size: 22,
                  ),
                ),
              ),
              const SizedBox(width: 4),
              Icon(
                Icons.chevron_right_rounded,
                color: Colors.grey[400],
                size: 24,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
