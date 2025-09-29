import 'package:flutter/foundation.dart';
import 'package:fluttertest/instructor/services/api_service.dart';

class AvatarManagement {
  static final AvatarManagement _instance = AvatarManagement._internal();
  factory AvatarManagement() => _instance;
  AvatarManagement._internal();

  // Make these static to match instructorNameNotifier
  static final ValueNotifier<String> instructorNameNotifier =
      ValueNotifier<String>('');
  static final ValueNotifier<Uint8List?> avatarBytesNotifier =
      ValueNotifier<Uint8List?>(null);
  static final ValueNotifier<String?> avatarUrlNotifier =
      ValueNotifier<String?>(null);

  void initialize({required String instructorName}) {
    instructorNameNotifier.value = instructorName;
  }

  void updateInstructorData({
    String? name,
    String? avatarUrl,
    Uint8List? avatarBytes,
  }) {
    if (name != null) instructorNameNotifier.value = name;
    if (avatarUrl != null) avatarUrlNotifier.value = avatarUrl;
    if (avatarBytes != null) avatarBytesNotifier.value = avatarBytes;
  }

  Future<void> uploadAvatar(Uint8List? fileBytes, String fileName) async {
    if (fileBytes == null) return;

    try {
      final Map<String, dynamic> response = await ApiService.uploadProfileImage(
        fileBytes,
        fileName,
      );
      if (response.containsKey('avatar') || response.containsKey('avatarUrl')) {
        final String newAvatarUrl =
            response['avatarUrl'] ?? response['avatar'] ?? '';
        updateInstructorData(avatarUrl: newAvatarUrl, avatarBytes: null);
        debugPrint('Avatar uploaded successfully: $newAvatarUrl');
      } else {
        throw Exception('Invalid response structure');
      }
    } catch (e) {
      debugPrint('Error uploading avatar: $e');
      rethrow;
    }
  }
}
