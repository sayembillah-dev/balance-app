import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../theme/app_theme.dart';
import '../widgets/app_drawer.dart';
import '../providers/currency_provider.dart';
import 'currency_picker_screen.dart';

/// Settings: default currency only. Same layout as other secondary screens.
class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen>
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
    final currencyAsync = ref.watch(selectedCurrencyProvider);
    final currencyCode = currencyAsync.valueOrNull ?? 'USD';
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
                      child: Scaffold(
                        backgroundColor: const Color(0xFFF2F2F7),
                        appBar: AppBar(
                          leading: const SizedBox.shrink(),
                          leadingWidth: 0,
                          title: const Align(
                            alignment: Alignment.centerLeft,
                            child: Text(
                              'Settings',
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
                        body: ListView(
                          padding: EdgeInsets.fromLTRB(
                            padding,
                            16,
                            padding,
                            24 + media.padding.bottom,
                          ),
                          children: [
                            _SettingsSection(
                              title: 'Preferences',
                              children: [
                                _SettingsTile(
                                  icon: Icons.attach_money_rounded,
                                  label: 'Default currency',
                                  value: currencyCode,
                                  onTap: () async {
                                    await Navigator.of(context).push(
                                      MaterialPageRoute(
                                        builder: (context) =>
                                            const CurrencyPickerScreen(),
                                      ),
                                    );
                                    if (mounted) setState(() {});
                                  },
                                ),
                              ],
                            ),
                          ],
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

class _SettingsSection extends StatelessWidget {
  const _SettingsSection({required this.title, required this.children});

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 4, bottom: 8),
            child: Text(
              title.toUpperCase(),
              style: TextStyle(
                fontFamily: AppFonts.family,
                fontSize: 12,
                fontWeight: AppFonts.medium,
                color: Colors.black.withValues(alpha: 0.45),
                letterSpacing: 0.8,
              ),
            ),
          ),
          Material(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            clipBehavior: Clip.antiAlias,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                for (var i = 0; i < children.length; i++) ...[
                  children[i],
                  if (i < children.length - 1)
                    Divider(
                      height: 1,
                      indent: 56,
                      endIndent: 16,
                      color: const Color(0xFFE5E5EA),
                    ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SettingsTile extends StatelessWidget {
  const _SettingsTile({
    required this.icon,
    required this.label,
    this.value,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final String? value;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              Icon(icon, size: 22, color: const Color(0xFF1C1C1E)),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  label,
                  style: const TextStyle(
                    fontFamily: AppFonts.family,
                    fontSize: 16,
                    fontWeight: AppFonts.medium,
                    color: Color(0xFF1C1C1E),
                  ),
                ),
              ),
              if (value != null)
                Text(
                  value!,
                  style: TextStyle(
                    fontFamily: AppFonts.family,
                    fontSize: 15,
                    color: Colors.grey[600],
                  ),
                ),
              if (value != null) const SizedBox(width: 4),
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
