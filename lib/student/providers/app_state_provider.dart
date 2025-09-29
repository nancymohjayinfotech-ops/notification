import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AppStateProvider extends ChangeNotifier {
  static const String _selectedRoleKey = 'selected_role';
  static const String _selectedLanguageKey = 'selected_language';
  static const String _currentTabIndexKey = 'current_tab_index';
  
  // App State
  String _selectedRole = '';
  String _selectedLanguage = 'English';
  int _currentTabIndex = 0;
  bool _isLoading = false;
  String? _errorMessage;
  
  // User State
  bool _isLoggedIn = false;
  String _userName = 'John Doe';
  String _userEmail = 'john.doe@example.com';
  String _userAvatar = 'assets/images/homescreen.png';
  
  // Navigation State
  final List<String> _navigationHistory = [];
  
  // Getters
  String get selectedRole => _selectedRole;
  String get selectedLanguage => _selectedLanguage;
  int get currentTabIndex => _currentTabIndex;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get isLoggedIn => _isLoggedIn;
  String get userName => _userName;
  String get userEmail => _userEmail;
  String get userAvatar => _userAvatar;
  List<String> get navigationHistory => List.unmodifiable(_navigationHistory);
  
  AppStateProvider() {
    _loadAppState();
  }
  
  // App State Methods
  Future<void> setSelectedRole(String role) async {
    if (_selectedRole != role) {
      _selectedRole = role;
      await _saveAppState();
      notifyListeners();
    }
  }
  
  Future<void> setSelectedLanguage(String language) async {
    if (_selectedLanguage != language) {
      _selectedLanguage = language;
      await _saveAppState();
      notifyListeners();
    }
  }
  
  Future<void> setCurrentTabIndex(int index) async {
    if (_currentTabIndex != index) {
      _currentTabIndex = index;
      await _saveAppState();
      notifyListeners();
    }
  }
  
  void setLoading(bool loading) {
    if (_isLoading != loading) {
      _isLoading = loading;
      notifyListeners();
    }
  }
  
  void setError(String? error) {
    if (_errorMessage != error) {
      _errorMessage = error;
      notifyListeners();
    }
  }
  
  void clearError() {
    setError(null);
  }
  
  // User State Methods
  Future<void> login(String email, String password) async {
    setLoading(true);
    clearError();
    
    try {
      // Simulate API call
      await Future.delayed(const Duration(seconds: 2));
      
      // For demo purposes, accept any email/password
      _isLoggedIn = true;
      _userEmail = email;
      _userName = email.split('@')[0].replaceAll('.', ' ').toUpperCase();
      
      await _saveAppState();
      notifyListeners();
    } catch (e) {
      setError('Login failed: ${e.toString()}');
    } finally {
      setLoading(false);
    }
  }
  
  Future<void> logout() async {
    _isLoggedIn = false;
    _userName = '';
    _userEmail = '';
    _selectedRole = '';
    _currentTabIndex = 0;
    _navigationHistory.clear();
    
    await _clearAppState();
    notifyListeners();
  }
  
  Future<void> updateUserProfile({
    String? name,
    String? email,
    String? avatar,
  }) async {
    bool hasChanges = false;
    
    if (name != null && _userName != name) {
      _userName = name;
      hasChanges = true;
    }
    
    if (email != null && _userEmail != email) {
      _userEmail = email;
      hasChanges = true;
    }
    
    if (avatar != null && _userAvatar != avatar) {
      _userAvatar = avatar;
      hasChanges = true;
    }
    
    if (hasChanges) {
      await _saveAppState();
      notifyListeners();
    }
  }
  
  // Navigation Methods
  void addToNavigationHistory(String route) {
    _navigationHistory.add(route);
    if (_navigationHistory.length > 10) {
      _navigationHistory.removeAt(0);
    }
  }
  
  void clearNavigationHistory() {
    _navigationHistory.clear();
  }
  
  // Persistence Methods
  Future<void> _loadAppState() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      _selectedRole = prefs.getString(_selectedRoleKey) ?? '';
      _selectedLanguage = prefs.getString(_selectedLanguageKey) ?? 'English';
      _currentTabIndex = prefs.getInt(_currentTabIndexKey) ?? 0;
      _isLoggedIn = prefs.getBool('is_logged_in') ?? false;
      _userName = prefs.getString('user_name') ?? 'John Doe';
      _userEmail = prefs.getString('user_email') ?? 'john.doe@example.com';
      _userAvatar = prefs.getString('user_avatar') ?? 'assets/images/homescreen.png';
      
      notifyListeners();
    } catch (e) {
      debugPrint('Error loading app state: $e');
    }
  }
  
  Future<void> _saveAppState() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      await prefs.setString(_selectedRoleKey, _selectedRole);
      await prefs.setString(_selectedLanguageKey, _selectedLanguage);
      await prefs.setInt(_currentTabIndexKey, _currentTabIndex);
      await prefs.setBool('is_logged_in', _isLoggedIn);
      await prefs.setString('user_name', _userName);
      await prefs.setString('user_email', _userEmail);
      await prefs.setString('user_avatar', _userAvatar);
    } catch (e) {
      debugPrint('Error saving app state: $e');
    }
  }
  
  Future<void> _clearAppState() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.clear();
    } catch (e) {
      debugPrint('Error clearing app state: $e');
    }
  }
  
  // Utility Methods
  bool hasRole() => _selectedRole.isNotEmpty;
  
  bool isRole(String role) => _selectedRole.toLowerCase() == role.toLowerCase();
  
  String getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) {
      return 'Good Morning';
    } else if (hour < 17) {
      return 'Good Afternoon';
    } else {
      return 'Good Evening';
    }
  }
  
  Map<String, dynamic> toJson() {
    return {
      'selectedRole': _selectedRole,
      'selectedLanguage': _selectedLanguage,
      'currentTabIndex': _currentTabIndex,
      'isLoggedIn': _isLoggedIn,
      'userName': _userName,
      'userEmail': _userEmail,
      'userAvatar': _userAvatar,
    };
  }
}
