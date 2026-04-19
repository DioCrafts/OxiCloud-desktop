import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  static const Color primary = Color(0xFF2563EB); // Blue-600
  static const Color secondary = Color(0xFF7C3AED); // Violet-600
  static const Color success = Color(0xFF16A34A); // Green-600
  static const Color warning = Color(0xFFD97706); // Amber-600
  static const Color error = Color(0xFFDC2626); // Red-600
  static const Color info = Color(0xFF0891B2); // Cyan-600

  // Sync status
  static const Color syncIdle = Color(0xFF6B7280); // Gray-500
  static const Color syncing = Color(0xFF2563EB); // Blue-600
  static const Color syncError = Color(0xFFDC2626); // Red-600
  static const Color syncConflict = Color(0xFFD97706); // Amber-600

  // File type accents
  static const Color fileDocument = Color(0xFF2563EB);
  static const Color fileImage = Color(0xFF16A34A);
  static const Color fileVideo = Color(0xFF7C3AED);
  static const Color fileAudio = Color(0xFFD97706);
  static const Color fileArchive = Color(0xFF6B7280);
  static const Color fileCode = Color(0xFF0891B2);
  static const Color fileOther = Color(0xFF9CA3AF);
}
