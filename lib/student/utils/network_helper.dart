import 'dart:io';
import 'package:flutter/material.dart';

class NetworkHelper {
  static bool _isConnected = true;
  static final List<VoidCallback> _listeners = [];

  // Check internet connectivity
  static Future<bool> checkConnectivity() async {
    try {
      final result = await InternetAddress.lookup('google.com');
      _isConnected = result.isNotEmpty && result[0].rawAddress.isNotEmpty;
    } catch (_) {
      _isConnected = false;
    }
    
    // Notify listeners
    for (final listener in _listeners) {
      listener();
    }
    
    return _isConnected;
  }

  // Get current connectivity status
  static bool get isConnected => _isConnected;

  // Add connectivity listener
  static void addListener(VoidCallback listener) {
    _listeners.add(listener);
  }

  // Remove connectivity listener
  static void removeListener(VoidCallback listener) {
    _listeners.remove(listener);
  }

  // Show no internet dialog
  static void showNoInternetDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.wifi_off, color: Colors.red),
            SizedBox(width: 8),
            Text('No Internet Connection'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.cloud_off,
              size: 64,
              color: Colors.grey[400],
            ),
            SizedBox(height: 16),
            Text(
              'Please check your internet connection and try again.',
              textAlign: TextAlign.center,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () async {
              Navigator.of(context).pop();
              final isConnected = await checkConnectivity();
              if (!isConnected) {
                showNoInternetDialog(context);
              }
            },
            child: Text('Retry'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('Cancel'),
          ),
        ],
      ),
    );
  }

  // Show offline banner
  static Widget buildOfflineBanner() {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(8),
      color: Colors.red[600],
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.wifi_off, color: Colors.white, size: 16),
          SizedBox(width: 8),
          Text(
            'No Internet Connection',
            style: TextStyle(color: Colors.white, fontSize: 14),
          ),
        ],
      ),
    );
  }

  // Network-aware widget wrapper
  static Widget networkAwareWidget({
    required Widget child,
    Widget? offlineWidget,
  }) {
    return StreamBuilder<bool>(
      stream: Stream.periodic(Duration(seconds: 5))
          .asyncMap((_) => checkConnectivity()),
      initialData: _isConnected,
      builder: (context, snapshot) {
        final isOnline = snapshot.data ?? false;
        
        if (!isOnline) {
          return offlineWidget ?? _buildDefaultOfflineWidget();
        }
        
        return child;
      },
    );
  }

  static Widget _buildDefaultOfflineWidget() {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.cloud_off,
              size: 100,
              color: Colors.grey[400],
            ),
            SizedBox(height: 24),
            Text(
              'No Internet Connection',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.grey[700],
              ),
            ),
            SizedBox(height: 16),
            Text(
              'Please check your connection and try again',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: () => checkConnectivity(),
              icon: Icon(Icons.refresh),
              label: Text('Retry'),
              style: ElevatedButton.styleFrom(
                padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Check if API endpoint is reachable
  static Future<bool> checkApiEndpoint(String url) async {
    try {
      final uri = Uri.parse(url);
      final result = await InternetAddress.lookup(uri.host);
      return result.isNotEmpty && result[0].rawAddress.isNotEmpty;
    } catch (_) {
      return false;
    }
  }

  // Retry mechanism for network requests
  static Future<T> retryRequest<T>(
    Future<T> Function() request, {
    int maxRetries = 3,
    Duration delay = const Duration(seconds: 2),
  }) async {
    int attempts = 0;
    
    while (attempts < maxRetries) {
      try {
        return await request();
      } catch (e) {
        attempts++;
        if (attempts >= maxRetries) {
          rethrow;
        }
        await Future.delayed(delay);
      }
    }
    
    throw Exception('Max retries exceeded');
  }
}

// Network status provider
class NetworkProvider extends ChangeNotifier {
  bool _isConnected = true;
  
  bool get isConnected => _isConnected;
  
  NetworkProvider() {
    _checkConnectivity();
    NetworkHelper.addListener(_onConnectivityChanged);
  }
  
  void _onConnectivityChanged() {
    final newStatus = NetworkHelper.isConnected;
    if (_isConnected != newStatus) {
      _isConnected = newStatus;
      notifyListeners();
    }
  }
  
  Future<void> _checkConnectivity() async {
    _isConnected = await NetworkHelper.checkConnectivity();
    notifyListeners();
  }
  
  @override
  void dispose() {
    NetworkHelper.removeListener(_onConnectivityChanged);
    super.dispose();
  }
}
