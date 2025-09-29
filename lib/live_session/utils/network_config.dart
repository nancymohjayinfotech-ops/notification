import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb, debugPrint;
import 'package:shared_preferences/shared_preferences.dart';
import 'app_config.dart';

/// Central place to resolve network endpoints per platform with optional overrides.
class NetworkConfig {
  static String? _socketOverride; // e.g. http://192.168.1.10:3000
  static String? _livekitOverride; // e.g. http://192.168.1.10:7880
  static bool _loaded = false;

  /// Load optional overrides from SharedPreferences.
  /// Keys:
  ///  - server_base_url (for REST and socket, e.g. http://192.168.1.10:3000)
  ///  - livekit_base_url (for LiveKit server, e.g. http://192.168.1.10:7880)
  static Future<void> loadOverrides() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _socketOverride = prefs.getString('server_base_url');
      _livekitOverride = prefs.getString('livekit_base_url');
      _loaded = true;
      if (_socketOverride != null && _socketOverride!.isNotEmpty) {
        debugPrint('NetworkConfig: Using socket override: $_socketOverride');
      }
      if (_livekitOverride != null && _livekitOverride!.isNotEmpty) {
        debugPrint('NetworkConfig: Using LiveKit override: $_livekitOverride');
      }
    } catch (_) {
      // Ignore errors; fall back to defaults
      _loaded = true;
    }
  }

  static String get socketBaseUrl {
    if (!_loaded) {
      // Not fatal; just proceed with defaults
    }
    if (_socketOverride != null && _socketOverride!.isNotEmpty) {
      return _socketOverride!;
    }

    // Primary source: AppConfig (overridable via --dart-define)
    final primary = AppConfig.serverBaseUrl;
    if (primary.isNotEmpty) return primary;

    // Fallbacks by platform (should rarely be used now)
    if (kIsWeb) {
      return 'http://44.223.46.43:3000';
    }
    if (Platform.isAndroid) {
      return 'http://44.223.46.43:3000';
    }
    if (Platform.isIOS) {
      return 'http://44.223.46.43:3000';
    }
    return 'http://44.223.46.43:3000';
  }

  static String get liveKitBaseUrl {
    if (!_loaded) {
      // Not fatal; just proceed with defaults
    }
    if (_livekitOverride != null && _livekitOverride!.isNotEmpty) {
      return _livekitOverride!;
    }

    // Primary source: AppConfig (overridable via --dart-define)
    final primary = AppConfig.livekitBaseUrl;
    if (primary.isNotEmpty) return primary;

    // Platform fallbacks (rarely used)
    if (kIsWeb) {
      return 'http://44.223.46.43:7880';
    }
    if (Platform.isAndroid) {
      return 'http://44.223.46.43:7880';
    }
    if (Platform.isIOS) {
      return 'http://44.223.46.43:7880';
    }
    return 'http://44.223.46.43:7880';
  }

  /// Candidate list for socket (HTTP base) endpoints, ordered by priority.
  static List<String> socketCandidates() {
    final list = <String>[];
    if (_socketOverride != null && _socketOverride!.isNotEmpty) {
      list.add(_socketOverride!);
    }
  // Platform-preferred first (from AppConfig)
  list.add(AppConfig.serverBaseUrl);
  // Also include resolved getter
  list.add(socketBaseUrl);
    // Common fallbacks
    list.addAll([
      'http://44.223.46.43:3000',
      'http://10.0.2.2:3000',
      'http://localhost:3000',
      'http://127.0.0.1:3000',
    ]);
    // Deduplicate preserving order
    final seen = <String>{};
    return list.where((e) => seen.add(e)).toList();
  }

  /// Candidate list for LiveKit server endpoints, ordered by priority.
  static List<String> liveKitCandidates() {
    final list = <String>[];
    if (_livekitOverride != null && _livekitOverride!.isNotEmpty) {
      list.add(_livekitOverride!);
    }
  // AppConfig first
  list.add(AppConfig.livekitBaseUrl);
  // Also include resolved getter
  list.add(liveKitBaseUrl);
    list.addAll([
      // HTTP fallbacks
      'http://44.223.46.43:7880',
      'http://10.0.2.2:7880',
      'http://localhost:7880',
      'http://127.0.0.1:7880',
      // WS equivalents
      'ws://44.223.46.43:7880',
      'ws://10.0.2.2:7880',
      'ws://localhost:7880',
      'ws://127.0.0.1:7880',
    ]);
    final seen = <String>{};
    return list.where((e) => seen.add(e)).toList();
  }
}
