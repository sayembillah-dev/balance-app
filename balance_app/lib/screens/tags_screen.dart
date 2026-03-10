import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/models.dart';
import '../providers/app_providers.dart';
import 'add_edit_tag_screen.dart';

const Color _kCardWhite = Color(0xFFFAFAFA);
const Color _kTextDark = Color(0xFF1C1C1E);
const Color _kBorderGrey = Color(0xFFE5E5EA);

/// Tags list: manage (add/edit/remove) and optionally choose tags for a transaction.
/// When [onDone] is non-null, [initialSelectedIds] are pre-selected and a Done
/// button returns the selected tag IDs.
class TagsScreen extends ConsumerStatefulWidget {
  const TagsScreen({
    super.key,
    this.initialSelectedIds = const [],
    this.onDone,
  });

  /// Pre-selected tag IDs when in choose mode.
  final List<String> initialSelectedIds;

  /// If set, screen is in "choose" mode: show checkboxes and Done returns selected IDs.
  final void Function(List<String> selectedIds)? onDone;

  bool get _chooseMode => onDone != null;

  @override
  ConsumerState<TagsScreen> createState() => _TagsScreenState();
}

class _TagsScreenState extends ConsumerState<TagsScreen> {
  late Set<String> _selectedIds;

  @override
  void initState() {
    super.initState();
    _selectedIds = Set.from(widget.initialSelectedIds);
  }

  void _toggle(String id) {
    setState(() {
      if (_selectedIds.contains(id)) {
        _selectedIds.remove(id);
      } else {
        _selectedIds.add(id);
      }
    });
  }

  Future<void> _openAddTag() async {
    final result = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (context) => const AddEditTagScreen(),
      ),
    );
    if (result == true && mounted) setState(() {});
  }

  Future<void> _openEditTag(TagItem tag) async {
    final result = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (context) => AddEditTagScreen(tag: tag),
      ),
    );
    if (result == true && mounted) setState(() {});
  }

  Future<void> _confirmRemove(TagItem tag) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Remove tag?'),
        content: Text(
          'Tag "${tag.name}" will be removed from all transactions.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Remove', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    if (confirm == true && mounted) {
      await ref.read(tagsProvider.notifier).remove(tag.id);
      setState(() => _selectedIds.remove(tag.id));
    }
  }

  void _done() {
    final list = List<String>.from(_selectedIds);
    widget.onDone?.call(list);
    Navigator.of(context).pop(list);
  }

  @override
  Widget build(BuildContext context) {
    final tagsAsync = ref.watch(tagsProvider);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          widget._chooseMode ? 'Choose tags' : 'Tags',
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          if (widget._chooseMode)
            TextButton(
              onPressed: _done,
              child: const Text('Done', style: TextStyle(color: Colors.white)),
            ),
        ],
      ),
      body: tagsAsync.when(
        data: (tags) {
          if (tags.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.label_outline_rounded,
                        size: 64, color: Colors.grey[400]),
                    const SizedBox(height: 16),
                    Text(
                      'No tags yet',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey[700],
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      widget._chooseMode
                          ? 'Add a tag below, then select it.'
                          : 'Tap + to create your first tag.',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                    ),
                  ],
                ),
              ),
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            itemCount: tags.length,
            itemBuilder: (context, index) {
              final tag = tags[index];
              final selected = _selectedIds.contains(tag.id);
              return Container(
                margin: const EdgeInsets.only(bottom: 8),
                decoration: BoxDecoration(
                  color: _kCardWhite,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: _kBorderGrey),
                ),
                child: Material(
                  color: Colors.transparent,
                  borderRadius: BorderRadius.circular(16),
                  child: InkWell(
                    onTap: widget._chooseMode
                        ? () => _toggle(tag.id)
                        : () => _openEditTag(tag),
                    borderRadius: BorderRadius.circular(16),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 14,
                      ),
                      child: Row(
                        children: [
                          if (widget._chooseMode) ...[
                            Icon(
                              selected
                                  ? Icons.check_box_rounded
                                  : Icons.check_box_outline_blank_rounded,
                              size: 24,
                              color: selected
                                  ? Colors.black87
                                  : Colors.grey[600],
                            ),
                            const SizedBox(width: 12),
                          ],
                          Expanded(
                            child: Text(
                              tag.name,
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                                color: _kTextDark,
                              ),
                            ),
                          ),
                          if (!widget._chooseMode) ...[
                            IconButton(
                              icon: Icon(
                                Icons.edit_outlined,
                                size: 22,
                                color: Colors.grey[600],
                              ),
                              onPressed: () => _openEditTag(tag),
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(
                                minWidth: 40,
                                minHeight: 40,
                              ),
                            ),
                            IconButton(
                              icon: Icon(
                                Icons.delete_outline_rounded,
                                size: 22,
                                color: Colors.grey[600],
                              ),
                              onPressed: () => _confirmRemove(tag),
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(
                                minWidth: 40,
                                minHeight: 40,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Text('Error: $e', style: TextStyle(color: Colors.grey[700])),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _openAddTag,
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        child: const Icon(Icons.add_rounded),
      ),
    );
  }
}
