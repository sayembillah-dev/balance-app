import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/models.dart';
import '../providers/app_providers.dart';

const Color _kBgGrey = Color(0xFFF2F2F7);
const Color _kCardWhite = Color(0xFFFAFAFA);
const Color _kBorderGrey = Color(0xFFE5E5EA);

/// Add or edit a tag. [tag] is null for create.
class AddEditTagScreen extends ConsumerStatefulWidget {
  const AddEditTagScreen({super.key, this.tag});

  final TagItem? tag;

  @override
  ConsumerState<AddEditTagScreen> createState() => _AddEditTagScreenState();
}

class _AddEditTagScreenState extends ConsumerState<AddEditTagScreen> {
  final _nameController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  bool get _isEdit => widget.tag != null;

  @override
  void initState() {
    super.initState();
    if (widget.tag != null) {
      _nameController.text = widget.tag!.name;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final name = _nameController.text.trim();
    if (name.isEmpty) return;
    final notifier = ref.read(tagsProvider.notifier);
    if (_isEdit) {
      await notifier.replaceById(
        widget.tag!.id,
        widget.tag!.copyWith(name: name),
      );
    } else {
      final id = notifier.nextId();
      await notifier.add(TagItem(id: id, name: name));
    }
    if (mounted) Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kBgGrey,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          _isEdit ? 'Edit tag' : 'New tag',
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: _kCardWhite,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: _kBorderGrey),
              ),
              child: TextFormField(
                controller: _nameController,
                autofocus: true,
                decoration: const InputDecoration(
                  labelText: 'Tag name',
                  hintText: 'e.g. Work, Vacation',
                  border: OutlineInputBorder(),
                  contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                ),
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return 'Enter a name';
                  return null;
                },
                onFieldSubmitted: (_) => _save(),
              ),
            ),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: _save,
              style: FilledButton.styleFrom(
                backgroundColor: Colors.black,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(_isEdit ? 'Save' : 'Add tag'),
            ),
          ],
        ),
      ),
    );
  }
}
