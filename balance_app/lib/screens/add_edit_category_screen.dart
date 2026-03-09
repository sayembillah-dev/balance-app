import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/dummy_data.dart';
import '../providers/app_providers.dart';
import '../widgets/emoji_picker_strip.dart';

/// Add new category or edit user-created one. Name + emoji (horizontal scroll picker).
class AddEditCategoryScreen extends ConsumerStatefulWidget {
  const AddEditCategoryScreen({this.category, super.key});

  final TransactionCategory? category;

  @override
  ConsumerState<AddEditCategoryScreen> createState() => _AddEditCategoryScreenState();
}

class _AddEditCategoryScreenState extends ConsumerState<AddEditCategoryScreen> {
  late TextEditingController _nameController;
  String? _selectedEmoji;
  bool get _isEdit => widget.category != null && widget.category!.isUserCreated;

  @override
  void initState() {
    super.initState();
    final c = widget.category;
    _nameController = TextEditingController(text: c?.name ?? '');
    _selectedEmoji = c?.emoji;
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  void _save() {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter a category name')),
      );
      return;
    }
    final notifier = ref.read(categoriesProvider.notifier);
    final emoji = _selectedEmoji ?? '📁';
    if (_isEdit) {
      final cat = widget.category!;
      final updated = cat.copyWith(name: name, emoji: emoji);
      notifier.replaceById(cat.id, updated);
      if (mounted) Navigator.of(context).pop(true);
    } else {
      final id = notifier.nextUserCategoryId();
      final newCategory = TransactionCategory(
        id: id,
        name: name,
        emoji: emoji,
        subcategories: [],
        isUserCreated: true,
      );
      notifier.add(newCategory);
      if (mounted) Navigator.of(context).pop(true);
    }
  }

  void _delete() {
    if (!_isEdit) return;
    showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete category?'),
        content: Text(
          '${widget.category!.name} will be removed. Subcategories will be lost.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    ).then((ok) async {
      if (ok == true && mounted) {
        await ref.read(categoriesProvider.notifier).removeUserCategory(widget.category!.id);
        if (mounted) Navigator.of(context).pop(true);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    final padding = media.size.width < 360 ? 16.0 : 20.0;

    return Scaffold(
      backgroundColor: const Color(0xFFF2F2F7),
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.close_rounded),
          onPressed: () => Navigator.of(context).pop(false),
        ),
        title: Text(
          _isEdit ? 'Edit category' : 'New category',
          style: const TextStyle(
            color: Color(0xFF1C1C1E),
            fontWeight: FontWeight.w600,
          ),
        ),
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF1C1C1E),
        elevation: 0,
        actions: [
          if (_isEdit)
            IconButton(
              icon: const Icon(Icons.delete_outline_rounded, color: Colors.red),
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
            Text(
              'Name',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.grey[700],
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _nameController,
              decoration: InputDecoration(
                hintText: 'e.g. Food & Dining',
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide(color: Colors.grey[300]!),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide(color: Colors.grey[300]!),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: const BorderSide(color: Color(0xFF1C1C1E), width: 1.5),
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              ),
              textCapitalization: TextCapitalization.words,
            ),
            const SizedBox(height: 24),
            EmojiPickerStrip(
              selectedEmoji: _selectedEmoji,
              onEmojiSelected: (emoji) => setState(() => _selectedEmoji = emoji),
              cellSize: 48,
              emojiSize: 28,
            ),
          ],
        ),
      ),
    );
  }
}
