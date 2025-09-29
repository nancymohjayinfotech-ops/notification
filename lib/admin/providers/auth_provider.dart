import 'package:flutter/material.dart';

class User {
  final String id;
  final String name;
  final String email;
  final String role;

  User({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
  });
}

class AuthProvider extends ChangeNotifier {
  User? _currentUser;
  bool _isLoading = false;

  User? get currentUser => _currentUser;
  bool get isLoading => _isLoading;
  bool get isAuthenticated => _currentUser != null;

  AuthProvider() {
    // Initialize with a default admin user
    _currentUser = User(
      id: '1',
      name: 'Admin User',
      email: 'admin@example.com',
      role: 'admin',
    );
  }

  Future<bool> login(String email, String password) async {
    _isLoading = true;
    notifyListeners();

    try {
      // Simulate API call
      await Future.delayed(const Duration(seconds: 1));

      // Mock authentication - in real app, validate with backend
      if (email.isNotEmpty && password.isNotEmpty) {
        _currentUser = User(
          id: '1',
          name: 'Admin User',
          email: email,
          role: 'admin',
        );
        _isLoading = false;
        notifyListeners();
        return true;
      }
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      return false;
    }

    _isLoading = false;
    notifyListeners();
    return false;
  }

  Future<void> logout() async {
    _isLoading = true;
    notifyListeners();

    try {
      // Simulate API call
      await Future.delayed(const Duration(milliseconds: 500));
      _currentUser = null;
    } catch (e) {
      // Handle error
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<void> updateProfile(String name, String email) async {
    if (_currentUser != null) {
      _currentUser = User(
        id: _currentUser!.id,
        name: name,
        email: email,
        role: _currentUser!.role,
      );
      notifyListeners();
    }
  }
}
