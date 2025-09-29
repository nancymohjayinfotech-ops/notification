import 'package:flutter/material.dart';
import '../../event_management/models/dashboard_response.dart';

class DashboardProvider with ChangeNotifier {
  EventSummary? _summary;
  List<Map<String, dynamic>> _todayEvents = [];
  List<Map<String, dynamic>> _upcomingEvents = [];
  List<Map<String, dynamic>> _pastEvents = [];
  bool _isLoading = false;
  String? _errorMessage;

  // Getters
  EventSummary? get summary => _summary;
  List<Map<String, dynamic>> get todayEvents => _todayEvents;
  List<Map<String, dynamic>> get upcomingEvents => _upcomingEvents;
  List<Map<String, dynamic>> get pastEvents => _pastEvents;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  // Update dashboard data (called from home page)
  void updateDashboardData({
    required EventSummary? summary,
    required List<Map<String, dynamic>> todayEvents,
    required List<Map<String, dynamic>> upcomingEvents,
    required List<Map<String, dynamic>> pastEvents,
  }) {
    _summary = summary;
    _todayEvents = todayEvents;
    _upcomingEvents = upcomingEvents;
    _pastEvents = pastEvents;
    _isLoading = false;
    _errorMessage = null;
    notifyListeners();
  }

  // Set loading state
  void setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  // Set error state
  void setError(String error) {
    _errorMessage = error;
    _isLoading = false;
    notifyListeners();
  }

  // Clear error
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  // Get stats for profile page
  Map<String, dynamic> getStatsData() {
    if (_summary == null) return {};
    
    return {
      'totalActiveEvents': _summary!.totalActiveEvents,
      'upcomingCount': _summary!.upcomingCount,
      'pastCount': _summary!.pastCount,
      'todayCount': _summary!.todayCount,
    };
  }
}
