import 'dart:convert';
import '../core/api/api_client.dart';
import 'report_model.dart';

class ReportingAnalyticsService {
  final ApiClient _apiClient;

  ReportingAnalyticsService(this._apiClient);

  Future<List<EventReport>> listReports({int page = 1, int limit = 50}) async {
    try {
      final response = await _apiClient.get('/reports?page=$page&limit=$limit');
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final list =
            (data['data'] ?? data['reports'] ?? data['items']) as List<dynamic>;
        return list
            .map((j) => EventReport.fromJson(j as Map<String, dynamic>))
            .toList();
      } else {
        throw Exception('Failed to load reports: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Failed to load reports: ${e.toString()}');
    }
  }

  Future<EventReport> getReport(String id) async {
    try {
      final response = await _apiClient.get('/reports/$id');
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final json = (data['data'] ?? data) as Map<String, dynamic>;
        return EventReport.fromJson(json);
      } else {
        throw Exception('Failed to load report: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Failed to load report: ${e.toString()}');
    }
  }
}
