// This file was empty and unused - removed for code cleanup// lib/core/routes/app_route.dart
import 'package:flutter/material.dart';

// === ADJUST THIS IMPORT PATH if your file lives somewhere else ===
// Option A (if notification_management_page.dart is in lib/notification/):
import '../../event/src/notifications/notification_management_page.dart';

// Option B (if it's in lib/notification/screens/):
// import '../../notification/screens/notification_management_page.dart';

// Option C (if you prefer package imports, replace `your_app` with your package name):
// import 'package:your_app/notification/notification_management_page.dart';

class AppRoutes {
  static const String notifications = '/notifications';

  // Simple routes map (works with MaterialApp.routes)
  static Map<String, WidgetBuilder> get routes => {
    notifications: (context) => const NotificationManagementPage(),
  };

  // Optional: onGenerateRoute for more control
  static Route<dynamic>? onGenerateRoute(RouteSettings settings) {
    switch (settings.name) {
      case notifications:
        return MaterialPageRoute(
          builder: (_) => const NotificationManagementPage(),
          settings: settings,
        );
      default:
        return null;
    }
  }
}
