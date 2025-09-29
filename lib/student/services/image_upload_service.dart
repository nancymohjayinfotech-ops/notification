import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import '../config/api_config.dart';
import 'token_service.dart';

class ImageUploadService {
  final ImagePicker _picker = ImagePicker();

  /// Pick image from camera
  Future<File?> pickImageFromCamera() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.camera,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );
      
      if (image != null) {
        return File(image.path);
      }
      return null;
    } catch (e) {
      debugPrint('Error picking image from camera: $e');
      return null;
    }
  }

  /// Pick image from gallery - returns XFile for web compatibility
  Future<XFile?> pickImageFromGallery() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );
      
      if (image != null) {
        try {
          await image.readAsBytes();
          return image;
        } catch (e) {
          return image; // Return anyway, might still work
        }
      } else {
        return null;
      }
    } catch (e) {
      return null;
    }
  }



  /// Upload profile image to server (works on web and mobile)
  Future<String?> uploadProfileImageFromXFile(XFile imageFile) async {
    try {
      final request = http.MultipartRequest(
        'POST',
        Uri.parse('${ApiConfig.baseUrl}${ApiConfig.uploadProfileImage}'),
      );
      
      // Add authentication header using TokenService
      try {
        final tokenService = TokenService();
        final accessToken = await tokenService.getAccessToken();
        
        if (accessToken != null && accessToken.isNotEmpty) {
          request.headers['Authorization'] = 'Bearer $accessToken';
        }
      } catch (e) {
        // Handle auth error silently
      }
      
      // Read file bytes (works on web)
      final bytes = await imageFile.readAsBytes();
      
      // Determine MIME type from file extension
      String mimeType = 'image/jpeg'; // Default
      final fileName = imageFile.name.toLowerCase();
      
      if (fileName.endsWith('.png')) {
        mimeType = 'image/png';
      } else if (fileName.endsWith('.jpg') || fileName.endsWith('.jpeg')) {
        mimeType = 'image/jpeg';
      } else if (fileName.endsWith('.gif')) {
        mimeType = 'image/gif';
      } else if (fileName.endsWith('.webp')) {
        mimeType = 'image/webp';
      }
      
      request.files.add(
        http.MultipartFile.fromBytes(
          'avatar',
          bytes,
          filename: imageFile.name.isNotEmpty ? imageFile.name : 'avatar.jpg',
          contentType: MediaType.parse(mimeType),
        ),
      );

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        if (responseData['success'] == true) {
          // Handle your API response structure
          String? imageUrl;
          
          // Try to get from data.file.url first (as shown in your API response)
          if (responseData['data'] != null && responseData['data']['file'] != null) {
            imageUrl = responseData['data']['file']['url'];
          }
          
          // Fallback to data.user.avatar (also in your response)
          if (imageUrl == null && responseData['data'] != null && responseData['data']['user'] != null) {
            imageUrl = responseData['data']['user']['avatar'];
          }
          
          // Other fallbacks
          imageUrl ??= responseData['data']?['url'] ?? responseData['url'];
          
          if (imageUrl != null) {
            return imageUrl;
          } else {
            return null;
          }
        } else {
          return null;
        }
      } else {
        return null;
      }
    } catch (e) {
      return null;
    }
  }

  /// Convert image to base64 string (alternative method)
  Future<String?> convertImageToBase64(File imageFile) async {
    try {
      final bytes = await imageFile.readAsBytes();
      final base64String = base64Encode(bytes);
      return 'data:image/jpeg;base64,$base64String';
    } catch (e) {
      debugPrint('Error converting image to base64: $e');
      return null;
    }
  }

  /// Show image picker dialog
  Future<File?> showImagePickerDialog(BuildContext context) async {
    return await showModalBottomSheet<File?>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (BuildContext context) {
        return Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(20),
              topRight: Radius.circular(20),
            ),
          ),
          child: SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 40,
                  height: 4,
                  margin: EdgeInsets.only(top: 12),
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                Padding(
                  padding: EdgeInsets.all(20),
                  child: Column(
                    children: [
                      Text(
                        'Select Profile Picture',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF5F299E),
                        ),
                      ),
                      SizedBox(height: 20),
                      Row(
                        children: [
                          Expanded(
                            child: _buildImageOption(
                              context,
                              icon: Icons.camera_alt,
                              title: 'Camera',
                              onTap: () async {
                                final nav = Navigator.of(context);
                                nav.pop();
                                final image = await pickImageFromCamera();
                                nav.pop(image);
                              },
                            ),
                          ),
                          SizedBox(width: 16),
                          Expanded(
                            child: _buildImageOption(
                              context,
                              icon: Icons.photo_library,
                              title: 'Gallery',
                              onTap: () async {
                                debugPrint('🖼️ Gallery button tapped');
                                try {
                                  debugPrint('🖼️ Opening gallery picker...');
                                  final image = await pickImageFromGallery();
                                  debugPrint('🖼️ Gallery picker returned: ${image?.path}');
                                  
                                  // Close dialog and return image
                                  Navigator.of(context).pop(image);
                                } catch (e) {
                                  debugPrint('🖼️ Error in gallery selection: $e');
                                  Navigator.of(context).pop(null);
                                }
                              },
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 16),
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: Text(
                          'Cancel',
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 16,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildImageOption(
    BuildContext context, {
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 20),
        decoration: BoxDecoration(
          color: Color(0xFF5F299E).withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: Color(0xFF5F299E).withValues(alpha: 0.2),
          ),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              size: 32,
              color: Color(0xFF5F299E),
            ),
            SizedBox(height: 8),
            Text(
              title,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Color(0xFF5F299E),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
