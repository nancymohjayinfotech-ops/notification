import 'package:dio/dio.dart';
import 'package:http_parser/http_parser.dart';
import 'package:mime/mime.dart';

class FileUploadService {
  final Dio _dio;
  final String baseUrl;

  FileUploadService({required this.baseUrl}) : _dio = Dio() {
    _dio.options.baseUrl = baseUrl;
    _dio.options.connectTimeout = const Duration(seconds: 30);
    _dio.options.receiveTimeout = const Duration(seconds: 30);
  }

  Future<String?> uploadProfileImage(String filePath, String token) async {
    try {
      final mimeType = lookupMimeType(filePath);
      final fileName = filePath.split('/').last;

      final formData = FormData.fromMap({
        'file': await MultipartFile.fromFile(
          filePath,
          filename: fileName,
          contentType: MediaType.parse(mimeType ?? 'image/jpeg'),
        ),
      });

      final response = await _dio.post(
        '/uploads/profile',
        data: formData,
        options: Options(
          headers: {
            'Authorization': 'Bearer $token',
            'Content-Type': 'multipart/form-data',
          },
        ),
      );

      if (response.statusCode == 200) {
        return response.data['url'];
      }
      return null;
    } catch (e) {
      print('Error uploading file: $e');
      return null;
    }
  }
}
