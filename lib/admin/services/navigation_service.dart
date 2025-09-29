import 'package:flutter/widgets.dart';

class NavigationService {
  static final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();
  
  // Callback for internal navigation within admin layout
  static Function(int)? _onInternalNavigation;
  
  static void setInternalNavigationCallback(Function(int) callback) {
    _onInternalNavigation = callback;
  }
  
  static void navigateToIndex(int index) {
    print('NavigationService: Attempting to navigate to index $index');
    if (_onInternalNavigation != null) {
      print('NavigationService: Callback is available, calling navigation');
      _onInternalNavigation?.call(index);
    } else {
      print('NavigationService: No navigation callback registered!');
    }
  }

  static void redirectToLogin() {
    final navigator = navigatorKey.currentState;
    if (navigator == null) return;
    navigator.pushNamedAndRemoveUntil('/loginpage', (route) => false);
  }
  
  // Navigation indices for admin screens
  static const int dashboardIndex = 0;
  static const int userManagementIndex = 1;
  static const int instructorManagementIndex = 2;
  static const int eventManagementIndex = 3;
  static const int eventApprovalIndex = 4;
  static const int courseManagementIndex = 5;
  static const int groupIndex = 6;
  static const int settingsIndex = 7;
}
