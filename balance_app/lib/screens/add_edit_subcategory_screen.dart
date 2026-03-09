import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/dummy_data.dart';
import '../providers/app_providers.dart';
import '../widgets/emoji_picker_strip.dart';

/// Add new subcategory or edit user-created one. Name + emoji.
class AddEditSubcategoryScreen extends ConsumerStatefulWidget {
  const AddEditSubcategoryScreen({
    required this.category,
    this.existing,
    super.key,
  });

  final TransactionCategory category;
  final SubcategoryItem? existing;

  @override
  ConsumerState<AddEditSubcategoryScreen> createState() => _AddEditSubcategoryScreenState();
}

class _AddEditSubcategoryScreenState extends ConsumerState<AddEditSubcategoryScreen> {
  late TextEditingController _nameController;
  String? _selectedEmoji;
  bool get _isEdit => widget.existing != null && widget.existing!.isUserCreated;

  @override
  void initState() {
    super.initState();
    final s = widget.existing;
    _nameController = TextEditingController(text: s?.name ?? '');
    _selectedEmoji = s?.emoji;
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
        const SnackBar(content: Text('Enter a subcategory name')),
      );
      return;
    }
    final emoji = _selectedEmoji ?? '📌';
    final categoriesList = ref.read(categoriesProvider).value ?? [];
    TransactionCategory cat = widget.category;
    for (final c in categoriesList) {
      if (c.id == widget.category.id) {
        cat = c;
        break;
      }
    }
    final notifier = ref.read(categoriesProvider.notifier);
    if (_isEdit) {
      final sub = widget.existing!;
      final newSubs = cat.subcategories.map((s) {
        if (s.id == sub.id || (s.name == sub.name && s.isUserCreated)) {
          return sub.copyWith(name: name, emoji: emoji);
        }
        return s;
      }).toList();
      notifier.replaceById(cat.id, cat.copyWith(subcategories: newSubs));
      if (mounted) Navigator.of(context).pop(sub.copyWith(name: name, emoji: emoji));
    } else {
      final newSub = SubcategoryItem(
        name: name,
        emoji: emoji,
        id: notifier.nextUserSubcategoryId(),
        isHidden: false,
        isUserCreated: true,
      );
      final newSubs = [...cat.subcategories, newSub];
      notifier.replaceById(cat.id, cat.copyWith(subcategories: newSubs));
      if (mounted) Navigator.of(context).pop(newSub);
    }
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
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          _isEdit ? 'Edit subcategory' : 'New subcategory',
          style: const TextStyle(
            color: Color(0xFF1C1C1E),
            fontWeight: FontWeight.w600,
          ),
        ),
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF1C1C1E),
        elevation: 0,
        actions: [
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
              'Under ${widget.category.emoji} ${widget.category.name}',
              style: TextStyle(
                fontSize: 13,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 16),
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
                hintText: 'e.g. Restaurant',
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
              cellSize: 44,
              emojiSize: 26,
            ),
          ],
        ),
      ),
    );
  }
}
