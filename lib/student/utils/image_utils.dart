import 'package:flutter/material.dart';

class ImageUtils {
  static const String baseUrl = 'http://54.82.53.11:5001';

  /// Get complete avatar URL with base URL if needed
  static String getCompleteAvatarUrl(String? avatarPath) {
    if (avatarPath == null || avatarPath.isEmpty) {
      return '';
    }

    // If it's already a complete URL, return as is
    if (avatarPath.startsWith('http')) {
      return avatarPath;
    }

    // Add base URL to relative path
    return '$baseUrl$avatarPath';
  }

  /// Get avatar ImageProvider with proper URL handling
  static ImageProvider? getAvatarImageProvider(String? avatarPath) {
    if (avatarPath == null || avatarPath.isEmpty) {
      return null;
    }

    final completeUrl = getCompleteAvatarUrl(avatarPath);
    return completeUrl.isNotEmpty ? NetworkImage(completeUrl) : null;
  }

  /// Get user initials from name
  static String getUserInitials(String? name) {
    if (name == null || name.isEmpty) {
      return 'U';
    }

    final words = name.trim().split(' ');
    if (words.length >= 2) {
      return '${words[0][0]}${words[1][0]}'.toUpperCase();
    } else if (words.isNotEmpty) {
      return words[0][0].toUpperCase();
    }

    return 'U';
  }
}
