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
    final color = Theme.of(context).textTheme.bodyLarge?.color;
    if (color != null) {
      return color.withAlpha((opacity * 255).round());
    }
    return Theme.of(context).brightness == Brightness.dark
        ? Colors.white.withAlpha((opacity * 255).round())
        : Colors.black.withAlpha((opacity * 255).round());
  }

  // Get theme-aware secondary text color
  static Color getSecondaryTextColor(BuildContext context) {
    final color = Theme.of(context).textTheme.bodyMedium?.color;
    if (color != null) {
      return color.withAlpha(178); // 0.7 * 255 = 178
    }
    return Theme.of(context).brightness == Brightness.dark
        ? Colors.white.withAlpha(178)
        : Colors.grey[600]!;
  }

  // Get theme-aware shadow color
  static Color getShadowColor(BuildContext context, {double opacity = 0.1}) {
    return Theme.of(context).shadowColor.withAlpha((opacity * 255).round());
  }

  // Get theme-aware border color
  static Color getBorderColor(BuildContext context, {double opacity = 0.2}) {
    return Theme.of(context).brightness == Brightness.dark
        ? Colors.white.withAlpha((opacity * 255).round())
        : Colors.grey.withAlpha((opacity * 255).round());
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
