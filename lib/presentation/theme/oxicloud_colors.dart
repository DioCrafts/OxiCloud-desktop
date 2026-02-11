import 'package:flutter/material.dart';

/// OxiCloud design tokens — extracted from the server frontend CSS.
///
/// Provides a unified color palette that keeps the desktop client
/// visually consistent with the web interface.
class OxiColors {
  const OxiColors._();

  // ── Primary / Brand ─────────────────────────────────────────────────────
  static const Color primary = Color(0xFFFF5E3A);
  static const Color primaryEnd = Color(0xFFFF2D55);
  static const Color primaryLight = Color(0xFFFF8A5C);
  static const Color primaryHover = Color(0xFFE64A29);

  /// Primary gradient used for buttons, avatars, logo.
  static const LinearGradient primaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [primary, primaryEnd],
  );

  /// Storage bar gradient.
  static const LinearGradient storageGradient = LinearGradient(
    colors: [primary, primaryLight],
  );

  /// Danger gradient for destructive actions.
  static const LinearGradient dangerGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFEF4444), Color(0xFFDC2626)],
  );

  // ── Primary tints ───────────────────────────────────────────────────────
  static const Color primaryBgTint = Color(0xFFFFF5F3);
  static const Color primaryBgTintLight = Color(0xFFFFF8F6);
  static Color primaryFocusRing = primary.withOpacity(0.1);
  static Color primaryShadow = primary.withOpacity(0.3);
  static Color primaryShadowHover = primary.withOpacity(0.4);

  // ── Sidebar / Dark chrome ───────────────────────────────────────────────
  static const Color sidebarTop = Color(0xFF2A3042);
  static const Color sidebarBottom = Color(0xFF232838);
  static Color sidebarBorder = Colors.white.withOpacity(0.07);
  static Color sidebarTextInactive = Colors.white.withOpacity(0.65);
  static const Color sidebarTextActive = Colors.white;
  static Color sidebarActiveBg = primary.withOpacity(0.12);
  static Color sidebarHoverBg = Colors.white.withOpacity(0.06);

  static const LinearGradient sidebarGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [sidebarTop, sidebarBottom],
  );

  // ── Nav section icon colors ─────────────────────────────────────────────
  static const Color navFilesInactive = Color(0xFFFFA94D);
  static const Color navFilesActive = Color(0xFFFF5E3A);
  static const Color navSharedInactive = Color(0xFF74B9FF);
  static const Color navSharedActive = Color(0xFF0984E3);
  static const Color navRecentInactive = Color(0xFF81ECEC);
  static const Color navRecentActive = Color(0xFF00CEC9);
  static const Color navFavoritesInactive = Color(0xFFFFD43B);
  static const Color navFavoritesActive = Color(0xFFF0C800);
  static const Color navTrashInactive = Color(0xFFFF7675);
  static const Color navTrashActive = Color(0xFFE74C3C);

  // ── Background / Surface ────────────────────────────────────────────────
  static const Color pageBg = Color(0xFFF5F7FA);
  static const Color surface = Colors.white;
  static const Color inputBg = Color(0xFFF8FAFC);
  static const Color secondaryBg = Color(0xFFF0F3F7);
  static const Color footerBg = Color(0xFFF8FAFC);
  static const Color toolbarBg = Color(0xFFF8F9FA);

  // ── Text ────────────────────────────────────────────────────────────────
  static const Color textHeading = Color(0xFF1A202C);
  static const Color textBody = Color(0xFF4A5568);
  static const Color textSecondary = Color(0xFF718096);
  static const Color textPlaceholder = Color(0xFFA0AEC0);
  static const Color textSubtle = Color(0xFF94A3B8);

  // ── Borders ─────────────────────────────────────────────────────────────
  static const Color border = Color(0xFFE2E8F0);
  static const Color borderLight = Color(0xFFF1F5F9);
  static const Color borderHover = Color(0xFFCBD5E0);

  // ── Semantic / Status ───────────────────────────────────────────────────
  static const Color error = Color(0xFFEF4444);
  static const Color errorBg = Color(0xFFFEE2E2);
  static const Color errorBgLight = Color(0xFFFEF2F2);

  static const Color success = Color(0xFF48BB78);
  static const Color successDark = Color(0xFF16A34A);
  static const Color successBg = Color(0xFFDCFCE7);
  static const Color successBgLight = Color(0xFFF0FDF4);

  static const Color warning = Color(0xFFFFC107);
  static const Color warningDark = Color(0xFFF59E0B);
  static const Color warningBg = Color(0xFFFEF3C7);

  static const Color info = Color(0xFF1890FF);
  static const Color infoDark = Color(0xFF1565C0);

  // ── Dark mode overrides ─────────────────────────────────────────────────
  static const Color darkSurface = Color(0xFF1E1E2E);
  static const Color darkPageBg = Color(0xFF181825);
  static const Color darkBorder = Color(0xFF313244);
  static const Color darkInputBg = Color(0xFF2A2A3C);
  static const Color darkTextHeading = Color(0xFFCDD6F4);
  static const Color darkTextBody = Color(0xFFBAC2DE);
  static const Color darkTextSecondary = Color(0xFFA6ADC8);

  // ── Shadows (as BoxShadow lists) ────────────────────────────────────────
  static List<BoxShadow> get cardShadow => [
        BoxShadow(
          color: Colors.black.withOpacity(0.05),
          blurRadius: 3,
          offset: const Offset(0, 1),
        ),
      ];

  static List<BoxShadow> get cardHoverShadow => [
        BoxShadow(
          color: Colors.black.withOpacity(0.08),
          blurRadius: 15,
          offset: const Offset(0, 5),
        ),
      ];

  static List<BoxShadow> get primaryButtonShadow => [
        BoxShadow(
          color: primary.withOpacity(0.3),
          blurRadius: 15,
          offset: const Offset(0, 4),
        ),
      ];

  static List<BoxShadow> get primaryButtonHoverShadow => [
        BoxShadow(
          color: primary.withOpacity(0.4),
          blurRadius: 20,
          offset: const Offset(0, 6),
        ),
      ];

  static List<BoxShadow> get modalShadow => [
        BoxShadow(
          color: Colors.black.withOpacity(0.25),
          blurRadius: 60,
          offset: const Offset(0, 20),
        ),
      ];

  static List<BoxShadow> get sidebarShadow => [
        BoxShadow(
          color: Colors.black.withOpacity(0.15),
          blurRadius: 12,
          offset: const Offset(2, 0),
        ),
      ];

  // ── Radii ───────────────────────────────────────────────────────────────
  static const double radiusSmall = 8.0;
  static const double radiusMedium = 12.0;
  static const double radiusLarge = 16.0;
  static const double radiusXLarge = 20.0;
  static const double radiusPill = 50.0;
}
