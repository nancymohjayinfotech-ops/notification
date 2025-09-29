import '../models/notification_model.dart';
import '../services/api_client.dart';

class NotificationRepository {
  final ApiClient _apiClient = ApiClient();

  Future<List<NotificationModel>> fetchNotifications() async {
    final response = await _apiClient.get('/instructor/api/notifications/');

    // Access the actual payload correctly
    final data = response.data is List ? response.data : [];

    return data
        .map<NotificationModel>((json) => NotificationModel.fromJson(json))
        .toList();
  }
}
