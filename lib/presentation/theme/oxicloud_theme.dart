import 'package:flutter/material.dart';

import 'oxicloud_colors.dart';

/// OxiCloud theme factory — builds Material 3 themes aligned with the
/// OxiCloud server web frontend aesthetic.
///
/// Key differences from stock Material:
/// - Coral/orange primary (`#FF5E3A`) instead of default blue
/// - 12 px border-radius on cards & buttons (server uses 12 px)
/// - System font stack (no custom fonts needed)
/// - Subtle shadows matching the server's light elevation style
/// - Card borders instead of elevation
class OxiCloudTheme {
  const OxiCloudTheme._();

  // ── Public API ──────────────────────────────────────────────────────────

  static ThemeData light() => _buildTheme(Brightness.light);
  static ThemeData dark() => _buildTheme(Brightness.dark);

  // ── Private builder ─────────────────────────────────────────────────────

  static ThemeData _buildTheme(Brightness brightness) {
    final bool isLight = brightness == Brightness.light;

    final colorScheme = ColorScheme.fromSeed(
      seedColor: OxiColors.primary,
      brightness: brightness,
      primary: OxiColors.primary,
      onPrimary: Colors.white,
      secondary: OxiColors.primaryLight,
      error: OxiColors.error,
      surface: isLight ? OxiColors.surface : OxiColors.darkSurface,
      onSurface: isLight ? OxiColors.textHeading : OxiColors.darkTextHeading,
    );

    final textTheme = _buildTextTheme(isLight);

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: colorScheme,
      scaffoldBackgroundColor:
          isLight ? OxiColors.pageBg : OxiColors.darkPageBg,

      // ── Typography ────────────────────────────────────────────────────
      fontFamily: null, // system font stack
      textTheme: textTheme,

      // ── AppBar ────────────────────────────────────────────────────────
      appBarTheme: AppBarTheme(
        centerTitle: false,
        elevation: 0,
        scrolledUnderElevation: 0.5,
        backgroundColor: isLight ? OxiColors.surface : OxiColors.darkSurface,
        foregroundColor:
            isLight ? OxiColors.textHeading : OxiColors.darkTextHeading,
        surfaceTintColor: Colors.transparent,
        titleTextStyle: textTheme.titleLarge?.copyWith(
          fontWeight: FontWeight.w700,
          fontSize: 19,
          color: isLight ? OxiColors.textHeading : OxiColors.darkTextHeading,
        ),
      ),

      // ── Cards ─────────────────────────────────────────────────────────
      cardTheme: CardThemeData(
        elevation: 0,
        color: isLight ? OxiColors.surface : OxiColors.darkSurface,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(OxiColors.radiusMedium),
          side: BorderSide(
            color: isLight ? OxiColors.border : OxiColors.darkBorder,
          ),
        ),
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      ),

      // ── Elevated Button (primary) ─────────────────────────────────────
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          elevation: 0,
          backgroundColor: OxiColors.primary,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          textStyle: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(OxiColors.radiusMedium),
          ),
        ).copyWith(
          shadowColor: WidgetStatePropertyAll(
            OxiColors.primary.withOpacity(0.3),
          ),
          elevation: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.hovered)) return 6;
            if (states.contains(WidgetState.pressed)) return 2;
            return 4;
          }),
        ),
      ),

      // ── Outlined Button (secondary) ───────────────────────────────────
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor:
              isLight ? OxiColors.textBody : OxiColors.darkTextBody,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          textStyle: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
          side: BorderSide(
            color: isLight ? OxiColors.border : OxiColors.darkBorder,
            width: 2,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(OxiColors.radiusMedium),
          ),
        ),
      ),

      // ── Text Button ───────────────────────────────────────────────────
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: OxiColors.primary,
          textStyle: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(OxiColors.radiusSmall),
          ),
        ),
      ),

      // ── Floating Action Button ────────────────────────────────────────
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: OxiColors.primary,
        foregroundColor: Colors.white,
        elevation: 4,
        hoverElevation: 6,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(OxiColors.radiusMedium),
        ),
      ),

      // ── Input fields ──────────────────────────────────────────────────
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: isLight ? OxiColors.inputBg : OxiColors.darkInputBg,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(OxiColors.radiusSmall),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(OxiColors.radiusSmall),
          borderSide: BorderSide(
            color: isLight ? OxiColors.border : OxiColors.darkBorder,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(OxiColors.radiusSmall),
          borderSide: const BorderSide(
            color: OxiColors.primary,
            width: 2,
          ),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(OxiColors.radiusSmall),
          borderSide: const BorderSide(color: OxiColors.error),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(OxiColors.radiusSmall),
          borderSide: const BorderSide(color: OxiColors.error, width: 2),
        ),
        hintStyle: TextStyle(
          color: isLight ? OxiColors.textPlaceholder : OxiColors.darkTextSecondary,
        ),
        labelStyle: TextStyle(
          color: isLight ? OxiColors.textSecondary : OxiColors.darkTextSecondary,
          fontWeight: FontWeight.w500,
        ),
        floatingLabelStyle: const TextStyle(
          color: OxiColors.primary,
          fontWeight: FontWeight.w500,
        ),
        prefixIconColor: isLight ? OxiColors.textSecondary : OxiColors.darkTextSecondary,
        suffixIconColor: isLight ? OxiColors.textSecondary : OxiColors.darkTextSecondary,
      ),

      // ── Divider ───────────────────────────────────────────────────────
      dividerTheme: DividerThemeData(
        color: isLight ? OxiColors.border : OxiColors.darkBorder,
        thickness: 1,
        space: 1,
      ),

      // ── ProgressIndicator ─────────────────────────────────────────────
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: OxiColors.primary,
        linearTrackColor:
            isLight ? OxiColors.border : OxiColors.darkBorder,
        circularTrackColor:
            isLight ? OxiColors.border : OxiColors.darkBorder,
      ),

      // ── Checkbox ──────────────────────────────────────────────────────
      checkboxTheme: CheckboxThemeData(
        fillColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return OxiColors.primary;
          return isLight ? OxiColors.surface : OxiColors.darkSurface;
        }),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(4),
        ),
      ),

      // ── Switch ────────────────────────────────────────────────────────
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return Colors.white;
          return isLight ? OxiColors.textPlaceholder : OxiColors.darkTextSecondary;
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return OxiColors.primary;
          return isLight ? OxiColors.border : OxiColors.darkBorder;
        }),
        trackOutlineColor: const WidgetStatePropertyAll(Colors.transparent),
      ),

      // ── ListTile ──────────────────────────────────────────────────────
      listTileTheme: ListTileThemeData(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(OxiColors.radiusSmall),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      ),

      // ── Dialog ────────────────────────────────────────────────────────
      dialogTheme: DialogThemeData(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(OxiColors.radiusLarge),
        ),
        backgroundColor: isLight ? OxiColors.surface : OxiColors.darkSurface,
        surfaceTintColor: Colors.transparent,
        elevation: 20,
      ),

      // ── SnackBar ──────────────────────────────────────────────────────
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(OxiColors.radiusSmall),
        ),
      ),

      // ── PopupMenu ─────────────────────────────────────────────────────
      popupMenuTheme: PopupMenuThemeData(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(OxiColors.radiusMedium),
        ),
        elevation: 8,
        surfaceTintColor: Colors.transparent,
        color: isLight ? OxiColors.surface : OxiColors.darkSurface,
      ),

      // ── Tooltip ───────────────────────────────────────────────────────
      tooltipTheme: TooltipThemeData(
        decoration: BoxDecoration(
          color: isLight ? OxiColors.sidebarTop : OxiColors.surface,
          borderRadius: BorderRadius.circular(OxiColors.radiusSmall),
        ),
        textStyle: TextStyle(
          color: isLight ? Colors.white : OxiColors.textHeading,
          fontSize: 12,
        ),
      ),

      // ── Scrollbar ─────────────────────────────────────────────────────
      scrollbarTheme: ScrollbarThemeData(
        thumbColor: WidgetStatePropertyAll(
          Colors.black.withOpacity(0.2),
        ),
        radius: const Radius.circular(4),
        thickness: const WidgetStatePropertyAll(8),
      ),

      // ── CircleAvatar ──────────────────────────────────────────────────
      // CircleAvatar doesn't have a theme; handled in the widget tree.
      // Use OxiColors.primaryGradient for avatar backgrounds.

      // ── NavigationRail (for desktop sidebar) ──────────────────────────
      navigationRailTheme: NavigationRailThemeData(
        backgroundColor:
            isLight ? OxiColors.sidebarTop : OxiColors.darkSurface,
        selectedIconTheme: const IconThemeData(color: OxiColors.primary),
        unselectedIconTheme: IconThemeData(color: OxiColors.sidebarTextInactive),
        indicatorColor: OxiColors.sidebarActiveBg,
      ),
    );
  }

  // ── Text theme ──────────────────────────────────────────────────────────

  static TextTheme _buildTextTheme(bool isLight) {
    final Color heading = isLight ? OxiColors.textHeading : OxiColors.darkTextHeading;
    final Color body = isLight ? OxiColors.textBody : OxiColors.darkTextBody;
    final Color secondary = isLight ? OxiColors.textSecondary : OxiColors.darkTextSecondary;

    return TextTheme(
      // Display / Headline
      headlineLarge: TextStyle(
        fontSize: 28,
        fontWeight: FontWeight.w700,
        color: heading,
        letterSpacing: -0.5,
      ),
      headlineMedium: TextStyle(
        fontSize: 24,
        fontWeight: FontWeight.w700,
        color: heading,
      ),
      headlineSmall: TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.w600,
        color: heading,
      ),

      // Title
      titleLarge: TextStyle(
        fontSize: 19,
        fontWeight: FontWeight.w700,
        color: heading,
        letterSpacing: 0.3,
      ),
      titleMedium: TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: heading,
      ),
      titleSmall: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: heading,
      ),

      // Body
      bodyLarge: TextStyle(
        fontSize: 15,
        fontWeight: FontWeight.w400,
        color: body,
      ),
      bodyMedium: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w400,
        color: body,
      ),
      bodySmall: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w400,
        color: secondary,
      ),

      // Label
      labelLarge: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w500,
        color: heading,
      ),
      labelMedium: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w500,
        color: body,
      ),
      labelSmall: TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w500,
        color: secondary,
        letterSpacing: 0.5,
      ),
    );
  }
}
