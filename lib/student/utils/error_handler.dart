import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

enum ErrorType {
  network,
  authentication,
  validation,
  permission,
  storage,
  unknown,
}

class AppError {
  final ErrorType type;
  final String message;
  final String? details;
  final String? code;
  final DateTime timestamp;
  final StackTrace? stackTrace;

  AppError({
    required this.type,
    required this.message,
    this.details,
    this.code,
    StackTrace? stackTrace,
  }) : timestamp = DateTime.now(),
       stackTrace = stackTrace ?? StackTrace.current;

  @override
  String toString() {
    return 'AppError(type: $type, message: $message, code: $code, timestamp: $timestamp)';
  }

  Map<String, dynamic> toMap() {
    return {
      'type': type.toString(),
      'message': message,
      'details': details,
      'code': code,
      'timestamp': timestamp.toIso8601String(),
    };
  }
}

class ErrorHandler {
  static final List<AppError> _errorHistory = [];
  static const int _maxHistorySize = 50;

  // Handle different types of errors
  static AppError handleError(dynamic error, {StackTrace? stackTrace}) {
    AppError appError;

    if (error is AppError) {
      appError = error;
    } else if (error is PlatformException) {
      appError = _handlePlatformException(error, stackTrace);
    } else if (error is FormatException) {
      appError = _handleFormatException(error, stackTrace);
    } else if (error is TimeoutException) {
      appError = _handleTimeoutException(error, stackTrace);
    } else {
      appError = AppError(
        type: ErrorType.unknown,
        message: error.toString(),
        stackTrace: stackTrace,
      );
    }

    _addToHistory(appError);
    return appError;
  }

  static AppError _handlePlatformException(PlatformException error, StackTrace? stackTrace) {
    ErrorType type;
    String message;

    switch (error.code) {
      case 'network_error':
        type = ErrorType.network;
        message = 'Network connection failed. Please check your internet connection.';
        break;
      case 'permission_denied':
        type = ErrorType.permission;
        message = 'Permission denied. Please grant the required permissions.';
        break;
      case 'storage_error':
        type = ErrorType.storage;
        message = 'Storage error occurred. Please try again.';
        break;
      default:
        type = ErrorType.unknown;
        message = error.message ?? 'An unexpected error occurred.';
    }

    return AppError(
      type: type,
      message: message,
      details: error.details?.toString(),
      code: error.code,
      stackTrace: stackTrace,
    );
  }

  static AppError _handleFormatException(FormatException error, StackTrace? stackTrace) {
    return AppError(
      type: ErrorType.validation,
      message: 'Invalid data format. Please check your input.',
      details: error.message,
      stackTrace: stackTrace,
    );
  }

  static AppError _handleTimeoutException(TimeoutException error, StackTrace? stackTrace) {
    return AppError(
      type: ErrorType.network,
      message: 'Request timed out. Please try again.',
      details: error.message,
      stackTrace: stackTrace,
    );
  }

  static void _addToHistory(AppError error) {
    _errorHistory.add(error);
    if (_errorHistory.length > _maxHistorySize) {
      _errorHistory.removeAt(0);
    }
  }

  // Get error history
  static List<AppError> getErrorHistory() {
    return List.unmodifiable(_errorHistory);
  }

  // Clear error history
  static void clearErrorHistory() {
    _errorHistory.clear();
  }

  // Show error dialog
  static void showErrorDialog(BuildContext context, AppError error) {
    showDialog(
      context: context,
      builder: (context) => ErrorDialog(error: error),
    );
  }

  // Show error snackbar
  static void showErrorSnackBar(BuildContext context, AppError error) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(error.message),
        backgroundColor: _getErrorColor(error.type),
        action: SnackBarAction(
          label: 'Details',
          textColor: Colors.white,
          onPressed: () => showErrorDialog(context, error),
        ),
        duration: const Duration(seconds: 4),
      ),
    );
  }

  static Color _getErrorColor(ErrorType type) {
    switch (type) {
      case ErrorType.network:
        return Colors.orange;
      case ErrorType.authentication:
        return Colors.red;
      case ErrorType.validation:
        return Colors.amber;
      case ErrorType.permission:
        return Colors.purple;
      case ErrorType.storage:
        return Colors.blue;
      case ErrorType.unknown:
        return Colors.grey;
    }
  }

  // Create specific error types
  static AppError networkError(String message, {String? details}) {
    return AppError(
      type: ErrorType.network,
      message: message,
      details: details,
    );
  }

  static AppError authenticationError(String message, {String? details}) {
    return AppError(
      type: ErrorType.authentication,
      message: message,
      details: details,
    );
  }

  static AppError validationError(String message, {String? details}) {
    return AppError(
      type: ErrorType.validation,
      message: message,
      details: details,
    );
  }

  static AppError permissionError(String message, {String? details}) {
    return AppError(
      type: ErrorType.permission,
      message: message,
      details: details,
    );
  }

  static AppError storageError(String message, {String? details}) {
    return AppError(
      type: ErrorType.storage,
      message: message,
      details: details,
    );
  }
}

class ErrorDialog extends StatelessWidget {
  final AppError error;

  const ErrorDialog({super.key, required this.error});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Row(
        children: [
          Icon(
            _getErrorIcon(error.type),
            color: ErrorHandler._getErrorColor(error.type),
          ),
          const SizedBox(width: 8),
          Text(_getErrorTitle(error.type)),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            error.message,
            style: const TextStyle(fontSize: 16),
          ),
          if (error.details != null) ...[
            const SizedBox(height: 12),
            const Text(
              'Details:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Text(
              error.details!,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
            ),
          ],
          if (error.code != null) ...[
            const SizedBox(height: 8),
            Text(
              'Error Code: ${error.code}',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[500],
                fontFamily: 'monospace',
              ),
            ),
          ],
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('OK'),
        ),
        if (error.type == ErrorType.network)
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              // Add retry logic here
            },
            child: const Text('Retry'),
          ),
      ],
    );
  }

  IconData _getErrorIcon(ErrorType type) {
    switch (type) {
      case ErrorType.network:
        return Icons.wifi_off;
      case ErrorType.authentication:
        return Icons.lock;
      case ErrorType.validation:
        return Icons.warning;
      case ErrorType.permission:
        return Icons.security;
      case ErrorType.storage:
        return Icons.storage;
      case ErrorType.unknown:
        return Icons.error;
    }
  }

  String _getErrorTitle(ErrorType type) {
    switch (type) {
      case ErrorType.network:
        return 'Network Error';
      case ErrorType.authentication:
        return 'Authentication Error';
      case ErrorType.validation:
        return 'Validation Error';
      case ErrorType.permission:
        return 'Permission Error';
      case ErrorType.storage:
        return 'Storage Error';
      case ErrorType.unknown:
        return 'Unknown Error';
    }
  }
}

// Timeout exception class
class TimeoutException implements Exception {
  final String message;
  
  const TimeoutException(this.message);
  
  @override
  String toString() => 'TimeoutException: $message';
}
