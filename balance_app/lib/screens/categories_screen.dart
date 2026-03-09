import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/dummy_data.dart';
import '../providers/app_providers.dart';
import '../widgets/app_drawer.dart';
import 'category_detail_screen.dart';
import 'add_edit_category_screen.dart';

/// Categories list: cards with emoji. Tap to open category detail; long-press drag to reorder; FAB to add.
class CategoriesScreen extends ConsumerStatefulWidget {
  const CategoriesScreen({super.key});

  @override
  ConsumerState<CategoriesScreen> createState() => _CategoriesScreenState();
}

class _CategoriesScreenState extends ConsumerState<CategoriesScreen>
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

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    final width = media.size.width;
    final isNarrow = width < 360;
    final padding = isNarrow ? 16.0 : 20.0;
    final size = MediaQuery.sizeOf(context);
    final drawerWidth = (size.width * 0.68).clamp(260.0, 320.0);
    const cardRadius = 20.0;
    final categories = ref.watch(categoriesProvider).value ?? [];

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
                              'Categories',
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
                        body: ReorderableListView.builder(
                          padding: EdgeInsets.fromLTRB(
                            padding,
                            16,
                            padding,
                            24 + media.padding.bottom,
                          ),
                          buildDefaultDragHandles: false,
                          onReorder: (oldIndex, newIndex) {
                            if (newIndex > oldIndex) newIndex--;
                            ref.read(categoriesProvider.notifier).reorder(oldIndex, newIndex);
                            setState(() {});
                          },
                          itemCount: categories.length,
                          itemBuilder: (context, index) {
                            final category = categories[index];
                            return Padding(
                              key: ValueKey(category.id),
                              padding: const EdgeInsets.only(bottom: 12),
                              child: _CategoryListCard(
                                category: category,
                                index: index,
                                isNarrow: isNarrow,
                                onTap: () => Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (context) => CategoryDetailScreen(
                                      category: category,
                                      onCategoryUpdated: () => setState(() {}),
                                    ),
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                        floatingActionButton: FloatingActionButton(
                          onPressed: () async {
                            final added = await Navigator.of(context).push<bool>(
                              MaterialPageRoute(
                                builder: (context) => const AddEditCategoryScreen(),
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

class _CategoryListCard extends StatelessWidget {
  const _CategoryListCard({
    required this.category,
    required this.index,
    required this.isNarrow,
    required this.onTap,
  });

  final TransactionCategory category;
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
                width: isNarrow ? 48 : 56,
                height: isNarrow ? 48 : 56,
                decoration: BoxDecoration(
                  color: const Color(0xFFF2F2F7),
                  borderRadius: BorderRadius.circular(14),
                ),
                alignment: Alignment.center,
                child: Text(
                  category.emoji,
                  style: TextStyle(fontSize: isNarrow ? 26 : 30),
                ),
              ),
              SizedBox(width: isNarrow ? 14 : 18),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      category.name,
                      style: TextStyle(
                        fontSize: isNarrow ? 17 : 18,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF1C1C1E),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${category.subcategories.length} subcategories',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey[600],
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
                    size: 24,
                  ),
                ),
              ),
              const SizedBox(width: 4),
              Icon(
                Icons.chevron_right_rounded,
                color: Colors.grey[400],
                size: 28,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
