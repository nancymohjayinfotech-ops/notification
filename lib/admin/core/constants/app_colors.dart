import 'package:flutter/material.dart';

class AppColors {
  // Primary Colors - Purple Theme
  static const Color primary = Color(0xFF9C27B0);
  static const Color primaryDark = Color(0xFF7B1FA2);
  static const Color primaryLight = Color(0xFFBA68C8);
  
  // Secondary Colors
  static const Color secondary = Color(0xFF673AB7);
  static const Color secondaryDark = Color(0xFF512DA8);
  
  // Background Colors
  static const Color background = Color(0xFFF8F8F8);
  static const Color surface = Colors.white;
  static const Color card = Colors.white;
  
  // Text Colors
  static const Color textPrimary = Colors.black;
  static const Color textSecondary = Color(0xFF666666);
  static const Color textHint = Color(0xFF9E9E9E);
  static const Color textOnPrimary = Colors.white;
  
  // Status Colors
  static const Color success = Color(0xFF4CAF50);
  static const Color warning = Color(0xFFFF9800);
  static const Color error = Color(0xFFF44336);
  static const Color info = Color(0xFF9C27B0);
  
  // Utility Colors
  static const Color divider = Color(0xFFE0E0E0);
  static const Color shadow = Color(0x1F000000);
  static const Color overlay = Color(0x80000000);
  
  // Gradient Colors
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [primary, primaryDark],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  
  static const LinearGradient purpleGradient = LinearGradient(
    colors: [Color(0xFF9C27B0), Color(0xFF673AB7)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}
