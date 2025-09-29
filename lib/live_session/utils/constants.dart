import 'app_config.dart';

/// Global application constants
class AppConstants {
  // Platform identifier for the app - used for API and socket connections
  static const String platformId = 'miskills';

    // API endpoints (delegated to AppConfig)
    // For local development on actual device, use your machine's IP address via --dart-define
    static final String apiBaseUrl = AppConfig.serverBaseUrl;
    static final String apiBaseUrliOS = AppConfig.serverBaseUrl;

  // Use this when testing with a real device, replace with your computer's IP
  // static const String apiBaseUrl = 'http://192.168.0.xxx:3000';

    // LiveKit URLs - Must match docker container setup
    static final String liveKitServerUrl = AppConfig.livekitBaseUrl;
    static final String socketUrl = AppConfig.serverBaseUrl;
    static final String socketUrliOS = AppConfig.serverBaseUrl;

  // LiveKit Keys - Must match docker container setup in .env
  static const String liveKitApiKey =
      'devkey'; // Same as LIVEKIT_API_KEY in .env
  static const String liveKitApiSecret =
      'secret'; // Same as LIVEKIT_API_SECRET in .env

  // API token from backend
  static const String apiToken =
      'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJ0eXBlIjoiZGV2ZWxvcGVyIiwiZ2VuZXJhdGVkIjoiMjAyNS0wOC0yMVQxMTo0NjozMy41NDBaIiwidGltZXN0YW1wIjoxNzU1Nzc2NzkzNTQwLCJpYXQiOjE3NTU3NzY3OTMsImV4cCI6MTc4NzMxMjc5M30.ryYJdQysqHDBnDrFjBABz6vNYhHuipcD8zDkDng-U9I';
}
