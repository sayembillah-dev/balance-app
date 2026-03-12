import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/models.dart';
import '../providers/app_providers.dart';
import '../widgets/app_drawer.dart';

/// Notes screen with list + add/edit/delete.
class NotesScreen extends ConsumerStatefulWidget {
  const NotesScreen({super.key});

  @override
  ConsumerState<NotesScreen> createState() => _NotesScreenState();
}

class _NotesScreenState extends ConsumerState<NotesScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _drawerController;
  late Animation<double> _drawerAnimation;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

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
    _searchController.dispose();
    _drawerController.dispose();
    super.dispose();
  }

  void _openDrawer() => _drawerController.forward();
  void _closeDrawer() => _drawerController.reverse();

  Future<void> _showEditNoteSheet({NoteItem? existing}) async {
    final titleController = TextEditingController(text: existing?.title ?? '');
    final contentController = TextEditingController(
      text: existing?.content ?? '',
    );
    final formKey = GlobalKey<FormState>();

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
          child: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      existing == null ? 'New note' : 'Edit note',
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
                  controller: titleController,
                  decoration: const InputDecoration(
                    labelText: 'Title',
                    border: OutlineInputBorder(),
                  ),
                  textInputAction: TextInputAction.next,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter a title';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: contentController,
                  decoration: const InputDecoration(
                    labelText: 'Notes',
                    alignLabelWithHint: true,
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 6,
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: () async {
                      if (!formKey.currentState!.validate()) return;
                      final notesNotifier = ref.read(notesProvider.notifier);
                      final now = DateTime.now();
                      if (existing == null) {
                        final id = notesNotifier.nextId();
                        final note = NoteItem(
                          id: id,
                          title: titleController.text.trim(),
                          content: contentController.text.trim(),
                          createdAt: now,
                          updatedAt: now,
                        );
                        await notesNotifier.add(note);
                      } else {
                        final updated = existing.copyWith(
                          title: titleController.text.trim(),
                          content: contentController.text.trim(),
                          updatedAt: now,
                        );
                        await notesNotifier.replaceById(existing.id, updated);
                      }
                      if (mounted) {
                        Navigator.of(context).pop();
                      }
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
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
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
                    behavior: progress > 0
                        ? HitTestBehavior.opaque
                        : HitTestBehavior.translucent,
                    onTap: progress > 0 ? _closeDrawer : null,
                    child: Scaffold(
                      backgroundColor: const Color(0xFFF2F2F7),
                      appBar: AppBar(
                        leading: const SizedBox.shrink(),
                        leadingWidth: 0,
                        title: const Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            'Notes',
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
                        backgroundColor: Colors.black,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        scrolledUnderElevation: 0,
                      ),
                      floatingActionButton: FloatingActionButton(
                        onPressed: () => _showEditNoteSheet(),
                        backgroundColor: Colors.black,
                        foregroundColor: Colors.white,
                        elevation: 2,
                        focusElevation: 4,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: const Icon(Icons.add, size: 28),
                      ),
                      floatingActionButtonLocation:
                          FloatingActionButtonLocation.endFloat,
                      body: Consumer(
                        builder: (context, ref, _) {
                          final asyncNotes = ref.watch(notesProvider);
                          return asyncNotes.when(
                            data: (notes) {
                              final media = MediaQuery.of(context);
                              final isNarrow = media.size.width < 360;
                              final horizontalPadding = isNarrow ? 16.0 : 20.0;
                              final query = _searchQuery.trim().toLowerCase();
                              final filtered = query.isEmpty
                                  ? notes
                                  : notes.where((note) {
                                      final title = note.title
                                          .toLowerCase()
                                          .trim();
                                      final content = note.content
                                          .toLowerCase()
                                          .trim();
                                      return title.contains(query) ||
                                          content.contains(query);
                                    }).toList();

                              return Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  Padding(
                                    padding: EdgeInsets.fromLTRB(
                                      horizontalPadding,
                                      12,
                                      horizontalPadding,
                                      4,
                                    ),
                                    child: TextField(
                                      controller: _searchController,
                                      autofocus: false,
                                      onChanged: (value) {
                                        setState(() {
                                          _searchQuery = value;
                                        });
                                      },
                                      decoration: InputDecoration(
                                        hintText: 'Search notes',
                                        isDense: true,
                                        prefixIcon: const Icon(
                                          Icons.search_rounded,
                                          size: 20,
                                        ),
                                        contentPadding:
                                            const EdgeInsets.symmetric(
                                              horizontal: 12,
                                              vertical: 10,
                                            ),
                                        filled: true,
                                        fillColor: Colors.white,
                                        border: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(
                                            999,
                                          ),
                                          borderSide: const BorderSide(
                                            color: Color(0xFFE5E5EA),
                                          ),
                                        ),
                                        enabledBorder: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(
                                            999,
                                          ),
                                          borderSide: const BorderSide(
                                            color: Color(0xFFE5E5EA),
                                          ),
                                        ),
                                        focusedBorder: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(
                                            999,
                                          ),
                                          borderSide: const BorderSide(
                                            color: Colors.black,
                                            width: 1.2,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                  Expanded(
                                    child: Builder(
                                      builder: (context) {
                                        if (notes.isEmpty) {
                                          return const _EmptyNotesView();
                                        }
                                        if (filtered.isEmpty) {
                                          return const _EmptySearchResultView();
                                        }
                                        return _NotesListView(
                                          notes: filtered,
                                          onEdit: (note) => _showEditNoteSheet(
                                            existing: note,
                                          ),
                                          onDelete: (note) async {
                                            final notifier = ref.read(
                                              notesProvider.notifier,
                                            );
                                            await notifier.removeById(note.id);
                                            if (!mounted) return;
                                            final messenger =
                                                ScaffoldMessenger.of(context);
                                            late final ScaffoldFeatureController<
                                              SnackBar,
                                              SnackBarClosedReason
                                            >
                                            controller;
                                            controller = messenger.showSnackBar(
                                              SnackBar(
                                                content: Text(
                                                  'Deleted note "${note.title}"',
                                                  maxLines: 2,
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                ),
                                                behavior:
                                                    SnackBarBehavior.floating,
                                                duration: const Duration(
                                                  seconds: 2,
                                                ),
                                                action: SnackBarAction(
                                                  label: 'UNDO',
                                                  onPressed: () async {
                                                    await notifier.add(note);
                                                    controller.close();
                                                  },
                                                ),
                                              ),
                                            );
                                            Future<void>.delayed(
                                              const Duration(seconds: 2),
                                            ).then((_) {
                                              if (mounted) {
                                                controller.close();
                                              }
                                            });
                                          },
                                          onTogglePinned: (note) async {
                                            await ref
                                                .read(notesProvider.notifier)
                                                .togglePinned(note.id);
                                          },
                                        );
                                      },
                                    ),
                                  ),
                                ],
                              );
                            },
                            loading: () => const Center(
                              child: CircularProgressIndicator(),
                            ),
                            error: (_, __) => const Center(
                              child: Text('Failed to load notes'),
                            ),
                          );
                        },
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

class _EmptyNotesView extends StatelessWidget {
  const _EmptyNotesView();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.note_alt_outlined, size: 64, color: Colors.grey[500]),
            const SizedBox(height: 16),
            Text(
              'No notes yet',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.grey[800],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Capture ideas, reminders, and anything related to your finances.',
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
}

class _EmptySearchResultView extends StatelessWidget {
  const _EmptySearchResultView();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.search_off_rounded, size: 56, color: Colors.grey[500]),
            const SizedBox(height: 12),
            Text(
              'No notes match your search',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.grey[800],
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Try a different keyword or clear the search.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: Colors.grey[600]),
            ),
          ],
        ),
      ),
    );
  }
}

class _NotesListView extends StatelessWidget {
  const _NotesListView({
    required this.notes,
    required this.onEdit,
    required this.onDelete,
    required this.onTogglePinned,
  });

  final List<NoteItem> notes;
  final void Function(NoteItem note) onEdit;
  final void Function(NoteItem note) onDelete;
  final void Function(NoteItem note) onTogglePinned;

  String _formatDateTime(DateTime dt) {
    final now = DateTime.now();
    final isToday =
        dt.year == now.year && dt.month == now.month && dt.day == now.day;
    if (isToday) {
      final h = dt.hour.toString().padLeft(2, '0');
      final m = dt.minute.toString().padLeft(2, '0');
      return 'Today $h:$m';
    }
    return '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    final isNarrow = media.size.width < 360;
    final padding = isNarrow ? 16.0 : 20.0;

    return ListView.builder(
      padding: EdgeInsets.fromLTRB(padding, 16, padding, 80),
      itemCount: notes.length,
      itemBuilder: (context, index) {
        final note = notes[index];
        final subtitle = note.content.trim();
        return Padding(
          padding: EdgeInsets.only(bottom: index == notes.length - 1 ? 0 : 10),
          child: Material(
            color: note.isPinned
                ? const Color(0xFFFFFBEB) // very subtle warm yellow for pinned
                : Colors.white,
            borderRadius: BorderRadius.circular(14),
            child: InkWell(
              borderRadius: BorderRadius.circular(14),
              onTap: () => onEdit(note),
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  note.title.isEmpty
                                      ? '(Untitled)'
                                      : note.title,
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    color: Color(0xFF1C1C1E),
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          if (subtitle.isNotEmpty)
                            Text(
                              subtitle,
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey[700],
                              ),
                              maxLines: 3,
                              overflow: TextOverflow.ellipsis,
                            ),
                          const SizedBox(height: 8),
                          Text(
                            _formatDateTime(note.updatedAt),
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[500],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: Icon(
                            note.isPinned
                                ? Icons.push_pin
                                : Icons.push_pin_outlined,
                            size: 20,
                          ),
                          tooltip: note.isPinned ? 'Unpin' : 'Pin',
                          onPressed: () => onTogglePinned(note),
                        ),
                        IconButton(
                          icon: const Icon(Icons.more_vert_rounded, size: 20),
                          onPressed: () async {
                            final action =
                                await showModalBottomSheet<_NoteAction>(
                                  context: context,
                                  backgroundColor: Colors.white,
                                  shape: const RoundedRectangleBorder(
                                    borderRadius: BorderRadius.vertical(
                                      top: Radius.circular(16),
                                    ),
                                  ),
                                  builder: (context) {
                                    return SafeArea(
                                      top: false,
                                      child: Column(
                                        mainAxisSize: MainAxisSize.min,
                                        crossAxisAlignment:
                                            CrossAxisAlignment.stretch,
                                        children: [
                                          ListTile(
                                            leading: const Icon(
                                              Icons.edit_rounded,
                                            ),
                                            title: const Text('Edit'),
                                            onTap: () => Navigator.of(
                                              context,
                                            ).pop(_NoteAction.edit),
                                          ),
                                          ListTile(
                                            leading: const Icon(
                                              Icons.delete_rounded,
                                              color: Colors.red,
                                            ),
                                            title: const Text(
                                              'Delete',
                                              style: TextStyle(
                                                color: Colors.red,
                                              ),
                                            ),
                                            onTap: () => Navigator.of(
                                              context,
                                            ).pop(_NoteAction.delete),
                                          ),
                                        ],
                                      ),
                                    );
                                  },
                                );
                            if (action == null) return;
                            switch (action) {
                              case _NoteAction.edit:
                                onEdit(note);
                                break;
                              case _NoteAction.delete:
                                onDelete(note);
                                break;
                            }
                          },
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

enum _NoteAction { edit, delete }
