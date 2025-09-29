import 'dart:convert';
import 'package:http/http.dart' as http;
import '../utils/network_config.dart';
import '../utils/constants.dart';


class ParticipantService {
  // We use the static API token for participant endpoints to avoid per-user Bearer tokens.
  // Backend accepts 'x-auth-token' without the 'Bearer' prefix (see globalAuth middleware).
  static String get _apiToken => AppConstants.apiToken;

  static String get _apiBase => '${NetworkConfig.socketBaseUrl}/participant';

  static Future<bool> deleteParticipant({
    required String scheduleId,
    required String participantId,
  }) async {
    final token = _apiToken;
    final url = '$_apiBase/delete/${AppConstants.platformId}/$scheduleId/$participantId';
    final response = await http.delete(
      Uri.parse(url),
      headers: {
        'x-auth-token': token, // no Bearer prefix
        'Content-Type': 'application/json',
      },
    );
    print('[ParticipantService] DELETE participant response: ' + response.body);
    return response.statusCode == 200;
  }

  static Future<List<Map<String, dynamic>>> getParticipantsForSchedule({
    required String scheduleId,
    required String hostId,
    required String platformId,
  }) async {
    final token = _apiToken;
    final uri = Uri.parse('$_apiBase/').replace(queryParameters: {
      'scheduleId': scheduleId,
      'hostId': hostId,
      'platformId': platformId,
    });
    try {
      final response = await http.get(
        uri,
        headers: {
          'x-auth-token': token, // no Bearer prefix
          'Content-Type': 'application/json',
        },
      );
      print('[ParticipantService] GET participants response: ' + response.body);
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data is Map && data['data'] is List) {
          return List<Map<String, dynamic>>.from(data['data']);
        }
      } else {
        print('[ParticipantService] GET participants HTTP ${response.statusCode}');
      }
    } catch (e) {
      print('[ParticipantService] GET participants error: $e');
    }
    return [];
  }

  static Future<Map<String, dynamic>?> addParticipant({
    required String scheduleId,
    required String participantId,
    required String participantName,
  }) async {
    final token = _apiToken;
    final body = jsonEncode({
      'scheduleId': scheduleId,
      'participantId': participantId,
      'platformId': AppConstants.platformId,
      'participantName': participantName,
    });
    try {
      final response = await http.post(
        Uri.parse('$_apiBase/'),
        headers: {
          'x-auth-token': token, // no Bearer prefix
          'Content-Type': 'application/json',
        },
        body: body,
      );
      print('[ParticipantService] API response: ' + response.body);
      if (response.statusCode == 200 || response.statusCode == 201) {
        return jsonDecode(response.body);
      }
      print('[ParticipantService] ADD participant HTTP ${response.statusCode}');
    } catch (e) {
      print('[ParticipantService] ADD participant error: $e');
    }
    return null;
  }
}
