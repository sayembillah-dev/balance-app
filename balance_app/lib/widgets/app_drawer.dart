import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/app_providers.dart';

/// Drawer page entry for app drawer.
class AppDrawerPage {
  const AppDrawerPage({
    required this.routeName,
    required this.label,
    required this.icon,
  });
  final String routeName;
  final String label;
  final IconData icon;
}

/// All main app pages shown in the side drawer.
const List<AppDrawerPage> appDrawerPages = [
  AppDrawerPage(
    routeName: '/dashboard',
    label: 'Dashboard',
    icon: Icons.dashboard_rounded,
  ),
  AppDrawerPage(
    routeName: '/transactions',
    label: 'Transactions',
    icon: Icons.list_alt_rounded,
  ),
  AppDrawerPage(
    routeName: '/accounts',
    label: 'Accounts',
    icon: Icons.account_balance_wallet_rounded,
  ),
  AppDrawerPage(
    routeName: '/categories',
    label: 'Categories',
    icon: Icons.category_rounded,
  ),
  AppDrawerPage(
    routeName: '/presets',
    label: 'Presets',
    icon: Icons.bookmark_rounded,
  ),
  AppDrawerPage(
    routeName: '/budgets',
    label: 'Budgets',
    icon: Icons.savings_rounded,
  ),
  AppDrawerPage(
    routeName: '/receivables-payables',
    label: 'Receivables &\nPayables',
    icon: Icons.swap_horiz_rounded,
  ),
  AppDrawerPage(
    routeName: '/notes',
    label: 'Notes',
    icon: Icons.note_rounded,
  ),
  AppDrawerPage(
    routeName: '/tags',
    label: 'Tags',
    icon: Icons.label_rounded,
  ),
  AppDrawerPage(
    routeName: '/settings',
    label: 'Settings',
    icon: Icons.settings_rounded,
  ),
];

/// Black side drawer panel. Use with a Stack; position/size via [width].
/// [currentRouteName] highlights the active page. Tapping a page closes drawer and navigates.
class AppDrawerPanel extends ConsumerWidget {
  const AppDrawerPanel({
    super.key,
    required this.width,
    required this.currentRouteName,
    required this.onClose,
  });

  final double width;
  final String? currentRouteName;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final media = MediaQuery.of(context);
    final top = media.padding.top;
    final bottom = media.padding.bottom;
    final screenHeight = media.size.height;
    final isNarrow = media.size.width < 360;
    final horizontalPadding = (width * 0.08).clamp(20.0, 28.0);
    final verticalPadding = (screenHeight * 0.03).clamp(20.0, 32.0);
    final itemHeight = isNarrow ? 48.0 : 52.0;
    final iconSize = isNarrow ? 22.0 : 24.0;
    final fontSize = isNarrow ? 15.0 : 16.0;
    final versionFontSize = isNarrow ? 11.0 : 12.0;
    final notesCount = ref.watch(notesProvider).value?.length ?? 0;

    return Positioned(
      left: 0,
      top: 0,
      bottom: 0,
      width: width,
      child: Container(
        decoration: const BoxDecoration(
          color: Colors.black,
          borderRadius: BorderRadius.only(
            topRight: Radius.circular(0),
            bottomRight: Radius.circular(0),
          ),
        ),
        child: SafeArea(
          top: false,
          bottom: false,
          child: Padding(
            padding: EdgeInsets.fromLTRB(
              horizontalPadding,
              top + verticalPadding,
              horizontalPadding,
              bottom + verticalPadding,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    IconButton(
                      onPressed: onClose,
                      icon: const Icon(
                        Icons.close_rounded,
                        color: Colors.white,
                      ),
                      iconSize: isNarrow ? 24.0 : 28.0,
                      padding: const EdgeInsets.all(8),
                      style: IconButton.styleFrom(
                        minimumSize: const Size(44, 44),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: verticalPadding * 0.5),
                Expanded(
                  child: ListView(
                    shrinkWrap: true,
                    padding: EdgeInsets.zero,
                    children: appDrawerPages.map((page) {
                      final isActive = currentRouteName == page.routeName;
                      final bool isNotesPage = page.routeName == '/notes';
                      final String? badgeText =
                          isNotesPage && notesCount > 0 ? '$notesCount' : null;
                      return _DrawerItem(
                        icon: page.icon,
                        label: page.label,
                        iconSize: iconSize,
                        fontSize: fontSize,
                        height: itemHeight,
                        isActive: isActive,
                        badgeText: badgeText,
                        onTap: () {
                          onClose();
                          if (!isActive) {
                            final nav = Navigator.of(context);
                            if (page.routeName == '/dashboard') {
                              nav.popUntil((route) => route.settings.name == '/dashboard');
                            } else if (page.routeName == '/accounts' || page.routeName == '/transactions' || page.routeName == '/categories' || page.routeName == '/presets' || page.routeName == '/budgets' || page.routeName == '/receivables-payables' || page.routeName == '/tags' || page.routeName == '/settings' || page.routeName == '/notes') {
                              nav.pushNamed(page.routeName);
                            } else {
                              nav.pushNamed(page.routeName);
                            }
                          }
                        },
                      );
                    }).toList(),
                  ),
                ),
                Text(
                  'App version 1.0.0',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.6),
                    fontSize: versionFontSize,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _DrawerItem extends StatelessWidget {
  const _DrawerItem({
    required this.icon,
    required this.label,
    required this.iconSize,
    required this.fontSize,
    required this.height,
    required this.isActive,
    this.badgeText,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final double iconSize;
  final double fontSize;
  final double height;
  final bool isActive;
  final String? badgeText;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final bgColor = isActive
        ? Colors.white.withValues(alpha: 0.12)
        : Colors.transparent;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          height: height,
          padding: const EdgeInsets.symmetric(horizontal: 8),
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              Icon(
                icon,
                size: iconSize,
                color: isActive ? Colors.white : Colors.white.withValues(alpha: 0.9),
              ),
              SizedBox(width: iconSize * 0.9),
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: fontSize,
                    fontWeight: isActive ? FontWeight.w600 : FontWeight.w500,
                  ),
                ),
              ),
              if (badgeText != null)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.14),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    badgeText!,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: fontSize - 3,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
