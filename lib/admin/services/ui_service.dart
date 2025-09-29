import 'package:flutter/material.dart';
import 'navigation_service.dart';

class UiService {
  static void showSuccess(String message) {
    _showSnack(message, Colors.green);
  }

  static void showError(String message) {
    _showSnack(message, Colors.red);
  }

  static void showInfo(String message) {
    _showSnack(message, Colors.black87);
  }

  static void _showSnack(String message, Color background) {
    final context = NavigationService.navigatorKey.currentContext;
    if (context == null) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: background,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}


