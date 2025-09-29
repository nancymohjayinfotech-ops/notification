import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class NavigationProvider extends ChangeNotifier {
  int _currentIndex = 0;
  final List<String> _navigationStack = [];
  bool _canPop = false;
  
  // Tab Information
  final List<NavigationTab> _tabs = [
    NavigationTab(
      index: 0,
      label: 'Home',
      icon: Icons.home_outlined,
      activeIcon: Icons.home,
      route: '/home',
    ),
    NavigationTab(
      index: 1,
      label: 'All Courses',
      icon: Icons.school_outlined,
      activeIcon: Icons.school,
      route: '/all-courses',
    ),
    NavigationTab(
      index: 2,
      label: 'My Courses',
      icon: Icons.book_outlined,
      activeIcon: Icons.book,
      route: '/my-courses',
    ),
    NavigationTab(
      index: 3,
      label: 'Groups',
      icon: Icons.group_outlined,
      activeIcon: Icons.group,
      route: '/groups',
    ),
    NavigationTab(
      index: 4,
      label: 'Profile',
      icon: Icons.person_outline,
      activeIcon: Icons.person,
      route: '/profile',
    ),
  ];
  
  // Getters
  int get currentIndex => _currentIndex;
  List<NavigationTab> get tabs => List.unmodifiable(_tabs);
  NavigationTab get currentTab => _tabs[_currentIndex];
  bool get canPop => _canPop;
  List<String> get navigationStack => List.unmodifiable(_navigationStack);
  
  // Navigation Methods
  void setCurrentIndex(int index, {bool withHaptic = true}) {
    if (index >= 0 && index < _tabs.length && _currentIndex != index) {
      if (withHaptic) {
        HapticFeedback.lightImpact();
      }
      
      _currentIndex = index;
      _addToStack(_tabs[index].route);
      notifyListeners();
    }
  }
  
  void navigateToTab(String tabLabel, {bool withHaptic = true}) {
    final tabIndex = _tabs.indexWhere(
      (tab) => tab.label.toLowerCase() == tabLabel.toLowerCase(),
    );
    
    if (tabIndex != -1) {
      setCurrentIndex(tabIndex, withHaptic: withHaptic);
    }
  }
  
  void _addToStack(String route) {
    _navigationStack.add(route);
    
    // Keep stack size manageable
    if (_navigationStack.length > 20) {
      _navigationStack.removeAt(0);
    }
    
    _updateCanPop();
  }
  
  void _updateCanPop() {
    _canPop = _navigationStack.length > 1;
  }
  
  bool popNavigation() {
    if (_canPop && _navigationStack.isNotEmpty) {
      _navigationStack.removeLast();
      _updateCanPop();
      
      if (_navigationStack.isNotEmpty) {
        final lastRoute = _navigationStack.last;
        final tabIndex = _tabs.indexWhere((tab) => tab.route == lastRoute);
        
        if (tabIndex != -1) {
          _currentIndex = tabIndex;
          notifyListeners();
          return true;
        }
      }
    }
    return false;
  }
  
  void clearNavigationStack() {
    _navigationStack.clear();
    _updateCanPop();
    notifyListeners();
  }
  
  // Tab Badge Management
  final Map<int, int> _tabBadges = {};
  
  void setBadgeCount(int tabIndex, int count) {
    if (tabIndex >= 0 && tabIndex < _tabs.length) {
      if (count <= 0) {
        _tabBadges.remove(tabIndex);
      } else {
        _tabBadges[tabIndex] = count;
      }
      notifyListeners();
    }
  }
  
  int getBadgeCount(int tabIndex) {
    return _tabBadges[tabIndex] ?? 0;
  }
  
  void clearBadge(int tabIndex) {
    setBadgeCount(tabIndex, 0);
  }
  
  void clearAllBadges() {
    _tabBadges.clear();
    notifyListeners();
  }
  
  // Tab State Management
  final Map<int, Map<String, dynamic>> _tabStates = {};
  
  void saveTabState(int tabIndex, Map<String, dynamic> state) {
    if (tabIndex >= 0 && tabIndex < _tabs.length) {
      _tabStates[tabIndex] = Map.from(state);
    }
  }
  
  Map<String, dynamic>? getTabState(int tabIndex) {
    return _tabStates[tabIndex];
  }
  
  void clearTabState(int tabIndex) {
    _tabStates.remove(tabIndex);
  }
  
  void clearAllTabStates() {
    _tabStates.clear();
  }
  
  // Animation and Transition Support
  bool _isAnimating = false;
  
  bool get isAnimating => _isAnimating;
  
  void setAnimating(bool animating) {
    if (_isAnimating != animating) {
      _isAnimating = animating;
      notifyListeners();
    }
  }
  
  // Utility Methods
  bool isCurrentTab(int index) => _currentIndex == index;
  
  String getCurrentRoute() => currentTab.route;
  
  NavigationTab? getTabByRoute(String route) {
    try {
      return _tabs.firstWhere((tab) => tab.route == route);
    } catch (e) {
      return null;
    }
  }
  
  // Reset to initial state
  void reset() {
    _currentIndex = 0;
    _navigationStack.clear();
    _tabBadges.clear();
    _tabStates.clear();
    _canPop = false;
    _isAnimating = false;
    notifyListeners();
  }
}

class NavigationTab {
  final int index;
  final String label;
  final IconData icon;
  final IconData activeIcon;
  final String route;
  final Color? color;
  
  const NavigationTab({
    required this.index,
    required this.label,
    required this.icon,
    required this.activeIcon,
    required this.route,
    this.color,
  });
  
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is NavigationTab &&
        other.index == index &&
        other.route == route;
  }
  
  @override
  int get hashCode => index.hashCode ^ route.hashCode;
  
  @override
  String toString() {
    return 'NavigationTab(index: $index, label: $label, route: $route)';
  }
}
