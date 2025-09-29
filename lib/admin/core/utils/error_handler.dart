import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import '../constants/app_strings.dart';

class ErrorHandler {
  // Show error snackbar
  static void showErrorSnackBar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 3),
      ),
    );
  }
  
  // Show success snackbar
  static void showSuccessSnackBar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
      ),
    );
  }
  
  // Show warning snackbar
  static void showWarningSnackBar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.orange,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 3),
      ),
    );
  }
  
  // Show info snackbar
  static void showInfoSnackBar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.blue,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
      ),
    );
  }
  
  // Show error toast
  static void showErrorToast(String message) {
    Fluttertoast.showToast(
      msg: message,
      toastLength: Toast.LENGTH_LONG,
      gravity: ToastGravity.BOTTOM,
      backgroundColor: Colors.red,
      textColor: Colors.white,
    );
  }
  
  // Show success toast
  static void showSuccessToast(String message) {
    Fluttertoast.showToast(
      msg: message,
      toastLength: Toast.LENGTH_SHORT,
      gravity: ToastGravity.BOTTOM,
      backgroundColor: Colors.green,
      textColor: Colors.white,
    );
  }
  
  // Handle API errors
  static String handleApiError(dynamic error) {
    if (error is String) {
      return error;
    }
    
    if (error is Map<String, dynamic>) {
      return error['message'] ?? error['error'] ?? AppStrings.unknownError;
    }
    
    return AppStrings.unknownError;
  }
  
  // Handle network errors
  static String handleNetworkError(dynamic error) {
    if (error.toString().contains('SocketException')) {
      return 'No internet connection';
    }
    
    if (error.toString().contains('TimeoutException')) {
      return 'Request timeout. Please try again';
    }
    
    if (error.toString().contains('FormatException')) {
      return 'Invalid response format';
    }
    
    return AppStrings.networkError;
  }
  
  // Show error dialog
  static void showErrorDialog(
    BuildContext context, {
    required String title,
    required String message,
    String? buttonText,
    VoidCallback? onPressed,
  }) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: onPressed ?? () => Navigator.pop(context),
            child: Text(buttonText ?? AppStrings.cancel),
          ),
        ],
      ),
    );
  }
  
  // Show confirmation dialog
  static void showConfirmationDialog(
    BuildContext context, {
    required String title,
    required String message,
    required VoidCallback onConfirm,
    String? confirmText,
    String? cancelText,
  }) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(cancelText ?? AppStrings.cancel),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              onConfirm();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: Text(confirmText ?? AppStrings.delete),
          ),
        ],
      ),
    );
  }
  
  // Show loading dialog
  static void showLoadingDialog(BuildContext context, {String? message}) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        content: Row(
          children: [
            const CircularProgressIndicator(),
            const SizedBox(width: 16),
            Text(message ?? AppStrings.loading),
          ],
        ),
      ),
    );
  }
  
  // Hide loading dialog
  static void hideLoadingDialog(BuildContext context) {
    Navigator.pop(context);
  }
  
  // Handle form validation errors
  static void showValidationError(BuildContext context, String fieldName) {
    showErrorSnackBar(context, 'Please enter a valid $fieldName');
  }
  
  // Handle success operations
  static void showSuccessMessage(BuildContext context, String operation, String itemName) {
    showSuccessSnackBar(context, '$itemName $operation successfully');
  }
  
  // Handle error operations
  static void showErrorMessage(BuildContext context, String operation, String itemName) {
    showErrorSnackBar(context, 'Failed to $operation $itemName');
  }
}
