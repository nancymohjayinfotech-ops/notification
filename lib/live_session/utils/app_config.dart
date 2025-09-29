/// Centralized application configuration.
///
/// Use --dart-define to pass values at build/run time, e.g.:
///   flutter run \
///     --dart-define=SERVER_BASE_URL=http://44.223.46.43:3000 \
///     --dart-define=LIVEKIT_BASE_URL=http://44.223.46.43:7880
///
/// These defaults are safe for current production but can be overridden
/// without touching source files.
class AppConfig {
  /// Base URL for REST API and Socket.IO (HTTP origin)
  static const String serverBaseUrl = String.fromEnvironment(
    'SERVER_BASE_URL',
    defaultValue: 'http://34.235.136.116:3000',
  );

  /// Base URL for LiveKit signaling server (HTTP origin; will be normalized to ws://)
  static const String livekitBaseUrl = String.fromEnvironment(
    'LIVEKIT_BASE_URL',
    defaultValue: 'http://34.235.136.116:7880',
  );
}
