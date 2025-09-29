import 'package:flutter/material.dart';

class NavigationHelper {
  /// Safely navigate back or to a specific route if needed
  static void goBack(BuildContext context, {bool isInDashboard = false}) {
    if (isInDashboard) {
      // If in dashboard tabs, navigate to the instructor dashboard route
      Navigator.of(context).pushReplacementNamed('/instructordashboard');
    } else {
      // Otherwise use normal back navigation
      Navigator.of(context).pop();
    }
  }

  /// Navigate to instructor dashboard
  static void goToInstructorDashboard(BuildContext context, {required String instructorName}) {
    // Navigate to instructor dashboard, clearing all previous routes
    Navigator.of(context).pushNamedAndRemoveUntil(
      '/instructordashboard',
      (route) => false, 
      arguments: instructorName,
    );
  }
}
