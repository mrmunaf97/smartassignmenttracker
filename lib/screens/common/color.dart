import 'package:flutter/material.dart';

class AppColors {
  // Primary Colors
  static const Color primary = Color(0xFF1E3A8A);
  static const Color primaryVariant = Color(0xFF3B82F6);

  // Secondary Colors
  static const Color secondary = Color(0xFF4B5563);
  static const Color secondaryVariant = Color(0xFF6B7280);

  // Accent / State Colors
  static const Color success = Color(0xFF22C55E);
  static const Color warning = Color(0xFFFACC15);
  static const Color error = Color(0xFFEF4444);

  // Background / Surface
  static const Color background = Color(0xFFF9FAFB);
  static const Color surface = Color(0xFFFFFFFF);

  // Text Colors
  static const Color textPrimary = Color(0xFF111827);
  static const Color textSecondary = Color(0xFF374151);
  static const Color textDisabled = Color(0xFF9CA3AF);

  // Miscellaneous
  static const Color border = Color(0xFF4B5563);
}

// Utility function to format date as dd/mm/yyyy
String formatDate(DateTime date) {
  return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
}

// Utility function to get filename from path
String getFileNameFromPath(String? filePath) {
  if (filePath == null || filePath.isEmpty) return '';
  return filePath.split('/').last;
}

// Utility function to truncate text to 80 characters with ellipsis
String truncateToWords(String text, {int maxCharacters = 80}) {
  if (text.isEmpty) return text;

  if (text.length <= maxCharacters) return text;

  return '${text.substring(0, maxCharacters)}...';
}
