import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user.dart';
import '../models/user_role.dart';

abstract class UserRepository {
  Future<User?> getCurrentUser();
  Future<bool> login(String email, String password);
  Future<bool> register(String email, String password, String name);
  Future<bool> logout();
  Future<bool> updateProfile(User user);
  Future<bool> changePassword(String oldPassword, String newPassword);
  Future<bool> resetPassword(String email);
  Future<List<String>> getUserInterests();
  Future<bool> updateUserInterests(List<String> interests);
}

class UserRepositoryImpl implements UserRepository {
  static const String _userKey = 'current_user';
  static const String _isLoggedInKey = 'is_logged_in';
  static const String _userInterestsKey = 'user_interests';
  static const String _loginTokenKey = 'login_token';

  // Simulate network delay
  Future<void> _simulateNetworkDelay() async {
    await Future.delayed(const Duration(milliseconds: 800));
  }

  @override
  Future<User?> getCurrentUser() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final isLoggedIn = prefs.getBool(_isLoggedInKey) ?? false;

      if (!isLoggedIn) return null;

      final userJson = prefs.getString(_userKey);
      if (userJson != null) {
        final userMap = json.decode(userJson) as Map<String, dynamic>;
        return User.fromMap(userMap);
      }
    } catch (e) {
      debugPrint('Error getting current user: $e');
    }
    return null;
  }

  // Helper to convert string to UserRole
  UserRole _parseUserRole(String role) {
    return UserRole.values.firstWhere(
      (e) => e.toString().split('.').last.toLowerCase() == role.toLowerCase(),
      orElse: () => UserRole.everyone,
    );
  }

  @override
  Future<bool> login(String email, String password) async {
    try {
      await _simulateNetworkDelay();

      // Simple validation for demo
      if (email.isEmpty || password.isEmpty) {
        throw Exception('Email and password are required');
      }

      if (!email.contains('@')) {
        throw Exception('Invalid email format');
      }

      if (password.length < 6) {
        throw Exception('Password must be at least 6 characters');
      }

      // Create user from email
      final user = User(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        name: _extractNameFromEmail(email),
        email: email,
        avatar: 'assets/images/homescreen.png',
        role: UserRole.everyone, // <-- FIXED: use enum, not string
        joinDate: DateTime.now(),
        isVerified: true,
      );

      // Save user data
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_isLoggedInKey, true);
      await prefs.setString(_userKey, json.encode(user.toMap()));
      await prefs.setString(_loginTokenKey, _generateToken());

      return true;
    } catch (e) {
      debugPrint('Login error: $e');
      return false;
    }
  }

  @override
  Future<bool> register(String email, String password, String name) async {
    try {
      await _simulateNetworkDelay();

      // Validation
      if (email.isEmpty || password.isEmpty || name.isEmpty) {
        throw Exception('All fields are required');
      }

      if (!email.contains('@')) {
        throw Exception('Invalid email format');
      }

      if (password.length < 6) {
        throw Exception('Password must be at least 6 characters');
      }

      if (name.length < 2) {
        throw Exception('Name must be at least 2 characters');
      }

      // Check if user already exists (simulate)
      final existingUser = await getCurrentUser();
      if (existingUser?.email == email) {
        throw Exception('User with this email already exists');
      }

      // Create new user
      final user = User(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        name: name,
        email: email,
        avatar: 'assets/images/homescreen.png',
        role: UserRole.everyone, // <-- FIXED: use enum, not string
        joinDate: DateTime.now(),
        isVerified: false,
      );

      // Save user data
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_isLoggedInKey, true);
      await prefs.setString(_userKey, json.encode(user.toMap()));
      await prefs.setString(_loginTokenKey, _generateToken());

      return true;
    } catch (e) {
      debugPrint('Registration error: $e');
      return false;
    }
  }

  @override
  Future<bool> logout() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_isLoggedInKey, false);
      await prefs.remove(_userKey);
      await prefs.remove(_loginTokenKey);

      return true;
    } catch (e) {
      debugPrint('Logout error: $e');
      return false;
    }
  }

  @override
  Future<bool> updateProfile(User user) async {
    try {
      await _simulateNetworkDelay();

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_userKey, json.encode(user.toMap()));

      return true;
    } catch (e) {
      debugPrint('Update profile error: $e');
      return false;
    }
  }

  @override
  Future<bool> changePassword(String oldPassword, String newPassword) async {
    try {
      await _simulateNetworkDelay();

      // Validation
      if (oldPassword.isEmpty || newPassword.isEmpty) {
        throw Exception('Both passwords are required');
      }

      if (newPassword.length < 6) {
        throw Exception('New password must be at least 6 characters');
      }

      if (oldPassword == newPassword) {
        throw Exception('New password must be different from old password');
      }

      // In a real app, you would verify the old password
      // For demo, we'll just simulate success
      return true;
    } catch (e) {
      debugPrint('Change password error: $e');
      return false;
    }
  }

  @override
  Future<bool> resetPassword(String email) async {
    try {
      await _simulateNetworkDelay();

      if (email.isEmpty || !email.contains('@')) {
        throw Exception('Valid email is required');
      }

      // Simulate sending reset email
      return true;
    } catch (e) {
      debugPrint('Reset password error: $e');
      return false;
    }
  }

  @override
  Future<List<String>> getUserInterests() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getStringList(_userInterestsKey) ?? [];
    } catch (e) {
      debugPrint('Error getting user interests: $e');
      return [];
    }
  }

  @override
  Future<bool> updateUserInterests(List<String> interests) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList(_userInterestsKey, interests);

      // Also update the user's role based on primary interest
      if (interests.isNotEmpty) {
        final currentUser = await getCurrentUser();
        if (currentUser != null) {
          final updatedUser = currentUser.copyWith(
            role: _parseUserRole(interests.first),
          ); // <-- FIXED
          await updateProfile(updatedUser);
        }
      }

      return true;
    } catch (e) {
      debugPrint('Error updating user interests: $e');
      return false;
    }
  }

  // Helper methods
  String _extractNameFromEmail(String email) {
    final username = email.split('@')[0];
    return username
        .replaceAll('.', ' ')
        .replaceAll('_', ' ')
        .replaceAll('-', ' ')
        .split(' ')
        .map(
          (word) => word.isNotEmpty
              ? word[0].toUpperCase() + word.substring(1).toLowerCase()
              : '',
        )
        .join(' ');
  }

  String _generateToken() {
    return DateTime.now().millisecondsSinceEpoch.toString() +
        DateTime.now().microsecond.toString();
  }

  // Additional utility methods
  Future<bool> isLoggedIn() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_isLoggedInKey) ?? false;
  }

  Future<String?> getLoginToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_loginTokenKey);
  }

  Future<bool> verifyToken(String token) async {
    final savedToken = await getLoginToken();
    return savedToken == token;
  }

  Future<void> clearUserData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_userKey);
    await prefs.remove(_isLoggedInKey);
    await prefs.remove(_userInterestsKey);
    await prefs.remove(_loginTokenKey);
  }

  // Demo methods for testing
  Future<bool> createDemoUser() async {
    final demoUser = User(
      id: 'demo_user_123',
      name: 'Demo User',
      email: 'demo@example.com',
      avatar: 'assets/images/homescreen.png',
      role: UserRole.instructor, // <-- FIXED: use enum, not string
      joinDate: DateTime.now().subtract(const Duration(days: 30)),
      isVerified: true,
    );

    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_isLoggedInKey, true);
    await prefs.setString(_userKey, json.encode(demoUser.toMap()));
    await prefs.setString(_loginTokenKey, _generateToken());

    return true;
  }
}
