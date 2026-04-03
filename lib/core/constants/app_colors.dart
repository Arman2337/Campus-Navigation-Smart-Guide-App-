import 'package:flutter/material.dart';

class AppColors {
  // Primary palette
  static const Color primary = Color(0xFF1A73E8);
  static const Color secondary = Color(0xFF34A853);
  static const Color accent = Color(0xFFFBBC04);
  static const Color error = Color(0xFFEA4335);

  // Background & Surface (Light)
  static const Color background = Color(0xFFF8F9FA);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceVariant = Color(0xFFE8F0FE);

  // Background & Surface (Dark)
  static const Color darkBackground = Color(0xFF121212);
  static const Color darkSurface = Color(0xFF1E1E2E);
  static const Color darkSurfaceVariant = Color(0xFF2D2D3F);

  // Text
  static const Color textPrimary = Color(0xFF202124);
  static const Color textSecondary = Color(0xFF5F6368);
  static const Color textHint = Color(0xFF9AA0A6);
  static const Color textLight = Color(0xFFFFFFFF);

  // Category Colors
  static const Color classroom = Color(0xFF1A73E8);
  static const Color office = Color(0xFF6B7BD3);
  static const Color lab = Color(0xFF9C27B0);
  static const Color cafeteria = Color(0xFFFF6D00);
  static const Color library = Color(0xFF00897B);
  static const Color restroom = Color(0xFF42A5F5);
  static const Color parking = Color(0xFF78909C);
  static const Color entrance = Color(0xFF34A853);

  // Gradient Colors
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [Color(0xFF1A73E8), Color(0xFF0D47A1)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient secondaryGradient = LinearGradient(
    colors: [Color(0xFF34A853), Color(0xFF1B5E20)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient splashGradient = LinearGradient(
    colors: [Color(0xFF1A73E8), Color(0xFF34A853)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // Borders & Dividers
  static const Color borderLight = Color(0xFFE0E0E0);
  static const Color divider = Color(0xFFF1F3F4);

  // Shadow
  static const Color shadow = Color(0x1A000000);

  // Status
  static const Color success = Color(0xFF34A853);
  static const Color warning = Color(0xFFFBBC04);
  static const Color info = Color(0xFF1A73E8);

  static Color getCategoryColor(String category) {
    switch (category.toLowerCase()) {
      case 'classroom':
        return classroom;
      case 'office':
        return office;
      case 'lab':
        return lab;
      case 'cafeteria':
        return cafeteria;
      case 'library':
        return library;
      case 'restroom':
        return restroom;
      case 'parking':
        return parking;
      case 'entrance':
        return entrance;
      default:
        return primary;
    }
  }
}
