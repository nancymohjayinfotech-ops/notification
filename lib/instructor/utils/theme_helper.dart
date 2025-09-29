import 'package:flutter/material.dart';

class ThemeHelper {
  // Get theme-aware background color
  static Color getBackgroundColor(BuildContext context) {
    return Theme.of(context).scaffoldBackgroundColor;
  }

  // Get theme-aware card color
  static Color getCardColor(BuildContext context) {
    return Theme.of(context).cardTheme.color ?? 
           (Theme.of(context).brightness == Brightness.dark 
            ? const Color(0xFF1E1E1E) 
            : Colors.white);
  }

  // Get theme-aware text color
  static Color getTextColor(BuildContext context, {double opacity = 1.0}) {
    return Theme.of(context).textTheme.bodyLarge?.color?.withValues(alpha: opacity) ?? 
           (Theme.of(context).brightness == Brightness.dark 
            ? Colors.white.withValues(alpha: opacity)
            : Colors.black.withValues(alpha: opacity));
  }

  // Get theme-aware secondary text color
  static Color getSecondaryTextColor(BuildContext context) {
    return Theme.of(context).textTheme.bodyMedium?.color?.withValues(alpha: 0.7) ?? 
           (Theme.of(context).brightness == Brightness.dark 
            ? Colors.white.withValues(alpha: 0.7)
            : Colors.grey[600]!);
  }

  // Get theme-aware shadow color
  static Color getShadowColor(BuildContext context, {double opacity = 0.1}) {
    return Theme.of(context).shadowColor.withValues(alpha: opacity);
  }

  // Get theme-aware border color
  static Color getBorderColor(BuildContext context, {double opacity = 0.2}) {
    return Theme.of(context).brightness == Brightness.dark 
        ? Colors.white.withValues(alpha: opacity)
        : Colors.grey.withValues(alpha: opacity);
  }

  // Get primary color
  static Color getPrimaryColor(BuildContext context) {
    return Theme.of(context).primaryColor;
  }

  // Check if dark mode is active
  static bool isDarkMode(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark;
  }
}
