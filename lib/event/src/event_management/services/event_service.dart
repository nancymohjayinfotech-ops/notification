import 'dart:convert';
import '../models/dashboard_response.dart';
import '../../core/api/api_client.dart';

class EventService {
  final ApiClient _apiClient;

  EventService(this._apiClient);

  Future<DashboardResponse?> getDashboardData() async {
    try {
      final response = await _apiClient.get('/events/dashboard');
      
      if (response.statusCode == 200) {
        final jsonData = jsonDecode(response.body);
        return DashboardResponse.fromJson(jsonData);
      } else {
        print('❌ Failed to fetch dashboard data: ${response.statusCode}');
        print('Response body: ${response.body}');
        return null;
      }
    } catch (e) {
      print('❌ Error fetching dashboard data: $e');
      return null;
    }
  }

  // Helper method to get events formatted for UI
  Future<Map<String, List<Map<String, dynamic>>>> getFormattedEvents() async {
    final dashboardData = await getDashboardData();
    
    if (dashboardData == null) {
      return {
        'today': [],
        'upcoming': [],
        'past': [],
      };
    }

    return {
      'today': dashboardData.data.today
          .map((event) => event.toHomePageFormat())
          .toList(),
      'upcoming': dashboardData.data.upcoming
          .map((event) => event.toHomePageFormat())
          .toList(),
      'past': dashboardData.data.past
          .map((event) => event.toHomePageFormat())
          .toList(),
    };
  }

  // Get events by category
  Future<Map<String, List<Map<String, dynamic>>>> getEventsByCategory(String category) async {
    final allEvents = await getFormattedEvents();
    
    if (category == 'All') {
      return allEvents;
    }

    return {
      'today': allEvents['today']!
          .where((event) => event['category'] == category)
          .toList(),
      'upcoming': allEvents['upcoming']!
          .where((event) => event['category'] == category)
          .toList(),
      'past': allEvents['past']!
          .where((event) => event['category'] == category)
          .toList(),
    };
  }

  // Get summary statistics
  Future<EventSummary?> getSummary() async {
    final dashboardData = await getDashboardData();
    return dashboardData?.data.summary;
  }
}
