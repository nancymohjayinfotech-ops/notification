import 'package:flutter/foundation.dart';
import '../models/user_model.dart';
import '../services/event_auth_service.dart';

class UserProfileProvider with ChangeNotifier {
  final EventAuthService _authService;

  UserProfileProvider(this._authService);

  User? _user;
  bool _isLoading = false;
  String? _errorMessage;
  Map<String, dynamic>? _dashboardStats;
  bool _isLoadingStats = false;

  User? get user => _user;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get hasProfile => _user != null;
  Map<String, dynamic>? get dashboardStats => _dashboardStats;
  bool get isLoadingStats => _isLoadingStats;

  // Load user profile from API
  Future<void> loadUserProfile() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _user = await _authService.getUserProfile();
      _errorMessage = null;
    } catch (e) {
      _errorMessage = e.toString();
      _user = null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Load cached user profile
  Future<void> loadCachedProfile() async {
    try {
      _user = await _authService.getCachedUser();
      notifyListeners();
    } catch (e) {
      _user = null;
      notifyListeners();
    }
  }

  // Update user profile
  Future<bool> updateProfile({
    String? name,
    String? avatar,
    String? bio,
    String? phone,
    String? address,
    String? college,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _user = await _authService.updateUserProfile(
        name: name,
        avatar: avatar,
        bio: bio,
        phone: phone,
        address: address,
        college: college,
      );
      _errorMessage = null;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Upload profile image with bytes (web-compatible)
  Future<String?> uploadProfileImageBytes(Uint8List imageBytes, String fileName) async {
    try {
      return await _authService.uploadProfileImageBytes(imageBytes, fileName);
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return null;
    }
  }

  // Legacy method for backward compatibility
  Future<String?> uploadProfileImage(String imagePath) async {
    try {
      return await _authService.uploadProfileImage(imagePath);
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return null;
    }
  }

  // Clear profile data
  void clearProfile() {
    _user = null;
    _errorMessage = null;
    _isLoading = false;
    notifyListeners();
  }

  // Load dashboard statistics
  Future<void> loadDashboardStats() async {
    _isLoadingStats = true;
    notifyListeners();

    try {
      _dashboardStats = await _authService.getDashboardStats();
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isLoadingStats = false;
      notifyListeners();
    }
  }

  // Refresh profile
  Future<void> refreshProfile() async {
    await loadUserProfile();
  }
}
