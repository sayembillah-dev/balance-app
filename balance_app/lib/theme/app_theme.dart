import 'package:flutter/material.dart';

/// Gilroy font family and weights used app-wide.
/// Only three weights are used for consistent, systematic UI/UX:
/// - [kGilroyRegular] (400): body text, captions, descriptions, amounts
/// - [kGilroyMedium] (500): labels, secondary line in lists, unselected state
/// - [kGilroySemiBold] (600): headings, titles, buttons, primary emphasis
class AppFonts {
  AppFonts._();

  static const String family = 'Gilroy';

  /// Body, captions, descriptions. Use for readable paragraphs and numbers.
  static const FontWeight regular = FontWeight.w400;

  /// Labels, list subtitles, subtle emphasis. Use for form labels and secondary info.
  static const FontWeight medium = FontWeight.w500;

  /// Headings, screen titles, buttons, card titles. Use for hierarchy and emphasis.
  static const FontWeight semiBold = FontWeight.w600;
}

/// Builds a [TextTheme] with Gilroy and consistent weight mapping:
/// - display/headline/title → SemiBold (600)
/// - body → Regular (400)
/// - label → Medium (500)
TextTheme _buildGilroyTextTheme(TextTheme base) {
  TextStyle withGilroy(TextStyle? s, FontWeight w) {
    return (s ?? const TextStyle()).copyWith(
      fontFamily: AppFonts.family,
      fontWeight: w,
    );
  }

  return TextTheme(
    displayLarge: withGilroy(base.displayLarge, AppFonts.semiBold),
    displayMedium: withGilroy(base.displayMedium, AppFonts.semiBold),
    displaySmall: withGilroy(base.displaySmall, AppFonts.semiBold),
    headlineLarge: withGilroy(base.headlineLarge, AppFonts.semiBold),
    headlineMedium: withGilroy(base.headlineMedium, AppFonts.semiBold),
    headlineSmall: withGilroy(base.headlineSmall, AppFonts.semiBold),
    titleLarge: withGilroy(base.titleLarge, AppFonts.semiBold),
    titleMedium: withGilroy(base.titleMedium, AppFonts.semiBold),
    titleSmall: withGilroy(base.titleSmall, AppFonts.semiBold),
    bodyLarge: withGilroy(base.bodyLarge, AppFonts.regular),
    bodyMedium: withGilroy(base.bodyMedium, AppFonts.regular),
    bodySmall: withGilroy(base.bodySmall, AppFonts.regular),
    labelLarge: withGilroy(base.labelLarge, AppFonts.medium),
    labelMedium: withGilroy(base.labelMedium, AppFonts.medium),
    labelSmall: withGilroy(base.labelSmall, AppFonts.medium),
  );
}

/// App theme using Gilroy everywhere with the above typography system.
/// All [TextTheme] styles use [AppFonts.family]. Use [Theme.of(context).textTheme]
/// or [AppFonts] when building custom [TextStyle]s so Gilroy is applied everywhere.
ThemeData get appTheme {
  final base = ThemeData(useMaterial3: true);
  return base.copyWith(
    textTheme: _buildGilroyTextTheme(base.textTheme),
    colorScheme: ColorScheme.fromSeed(
      seedColor: Colors.black,
    ).copyWith(surface: Colors.white, surfaceTint: Colors.transparent),
    cardTheme: const CardThemeData(
      elevation: 0,
      surfaceTintColor: Colors.transparent,
    ),
    pageTransitionsTheme: PageTransitionsTheme(
      builders: {
        TargetPlatform.android: _SmoothTransitionBuilder(),
        TargetPlatform.iOS: _SmoothTransitionBuilder(),
        TargetPlatform.macOS: _SmoothTransitionBuilder(),
      },
    ),
  );
}

/// Page transition with longer duration and easeInOutCubic for smoother feel.
class _SmoothTransitionBuilder extends PageTransitionsBuilder {
  @override
  Widget buildTransitions<T>(
    PageRoute<T> route,
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    final curved = CurvedAnimation(
      parent: animation,
      curve: Curves.easeInOutCubic,
      reverseCurve: Curves.easeInOutCubic,
    );
    return SlideTransition(
      position: Tween<Offset>(
        begin: const Offset(0.03, 0),
        end: Offset.zero,
      ).animate(curved),
      child: FadeTransition(opacity: curved, child: child),
    );
  }
}
