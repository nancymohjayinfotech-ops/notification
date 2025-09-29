import 'package:flutter/material.dart';
import 'enrollment_api_service.dart';

class EnrollmentProvider with ChangeNotifier {
  final EnrollmentApiService _enrollmentService;

  EnrollmentProvider(this._enrollmentService);

  // State variables
  EnrollmentResponse? _enrollmentResponse;
  bool _isLoading = false;
  String? _errorMessage;
  String? _selectedEventId;

  // Getters
  EnrollmentResponse? get enrollmentResponse => _enrollmentResponse;
  List<Enrollment> get enrollments => _enrollmentResponse?.enrollments ?? [];
  EnrollmentStats? get stats => _enrollmentResponse?.stats;
  EventInfo? get eventInfo => _enrollmentResponse?.event;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  String? get selectedEventId => _selectedEventId;

  // Load enrollments for a specific event
  Future<void> loadEventEnrollments(String eventId) async {
    _setLoading(true);
    _clearError();
    _selectedEventId = eventId;

    try {
      final response = await _enrollmentService.getEventEnrollments(eventId);
      _enrollmentResponse = response;
    } catch (e) {
      _setError(e.toString());
    } finally {
      _setLoading(false);
    }
  }

  // Clear enrollment data
  void clearEnrollments() {
    _enrollmentResponse = null;
    _selectedEventId = null;
    _clearError();
    notifyListeners();
  }

  // Get enrollments by status
  List<Enrollment> getEnrollmentsByStatus(String status) {
    return enrollments.where((enrollment) => enrollment.status == status).toList();
  }

  // Update enrollment status
  Future<void> updateEnrollmentStatus(String eventId, String enrollmentId, String status) async {
    _setLoading(true);
    _clearError();

    try {
      final success = await _enrollmentService.updateEnrollmentStatus(eventId, enrollmentId, status);
      if (success) {
        // Reload enrollments to get updated data
        await loadEventEnrollments(eventId);
      } else {
        throw Exception('Failed to update enrollment status');
      }
    } catch (e) {
      _setError(e.toString());
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  // Private helper methods
  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void _setError(String error) {
    _errorMessage = error;
    notifyListeners();
  }

  void _clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}
