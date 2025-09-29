import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:pretty_dio_logger/pretty_dio_logger.dart';
import '../config/api_config.dart';
import '../utils/error_handler.dart';
import 'token_service.dart';
import 'auth_service.dart';

class ApiClient {
  static final ApiClient _instance = ApiClient._internal();
  factory ApiClient() => _instance;
  ApiClient._internal() {
    _initializeDio();
  }

  late Dio _dio;
  final TokenService _tokenService = TokenService();

  Dio get dio => _dio;

  void _initializeDio() {
    _dio = Dio(
      BaseOptions(
        baseUrl: ApiConfig.baseUrl,
        connectTimeout: ApiConfig.connectTimeout,
        receiveTimeout: ApiConfig.receiveTimeout,
        sendTimeout: ApiConfig.sendTimeout,
        headers: ApiConfig.defaultHeaders,
      ),
    );

    _addInterceptors();
  }

  void _addInterceptors() {
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          try {
            final authHeaders = await _tokenService.getAuthHeaders();
            options.headers.addAll(authHeaders);
          } catch (e) {
            debugPrint('Error adding auth headers: $e');
          }

          debugPrint('🚀 REQUEST: ${options.method} ${options.path}');
          handler.next(options);
        },
        onResponse: (response, handler) {
          debugPrint(
            '✅ RESPONSE: ${response.statusCode} ${response.requestOptions.path}',
          );
          handler.next(response);
        },
        onError: (error, handler) async {
          debugPrint(
            '❌ ERROR: ${error.response?.statusCode} ${error.requestOptions.path}',
          );

          if (error.response?.statusCode == ApiConfig.unauthorizedCode) {
            debugPrint('🔓 Unauthorized - attempting token refresh');

            final refreshSuccess = await _tokenService.refreshAccessToken();

            if (refreshSuccess) {
              debugPrint('🔄 Retrying request with refreshed token');
              final options = error.requestOptions;

              try {
                final newHeaders = await _tokenService.getAuthHeaders();
                options.headers.addAll(newHeaders);
                final response = await _dio.fetch(options);
                handler.resolve(response);
                return;
              } catch (retryError) {
                debugPrint('❌ Retry failed after token refresh: $retryError');
              }
            }

            debugPrint('🔓 Token refresh failed - handling via AuthService');
            await AuthService().handleUnauthorized();
          }

          handler.next(error);
        },
      ),
    );

    if (ApiConfig.enableLogging) {
      _dio.interceptors.add(
        PrettyDioLogger(
          requestHeader: true,
          requestBody: true,
          responseBody: true,
          responseHeader: false,
          error: true,
          compact: true,
          maxWidth: 90,
        ),
      );
    }
  }

  // ✅ Student ke liye generic authenticated request helper
  Future<ApiResponse<T>> authenticatedRequest<T>(
    Future<Response<T>> Function(Dio dio) requestFn,
  ) async {
    try {
      final response = await requestFn(_dio);
      return ApiResponse.success(response.data as T);
    } on DioException catch (e) {
      return _handleDioError<T>(e);
    } catch (e) {
      return ApiResponse.error(ErrorHandler.handleError(e));
    }
  }

  // Generic GET request
  Future<ApiResponse<T>> get<T>(
    String endpoint, {
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    try {
      final response = await _dio.get<T>(
        endpoint,
        queryParameters: queryParameters,
        options: options,
      );
      return ApiResponse.success(response.data as T);
    } on DioException catch (e) {
      return _handleDioError<T>(e);
    } catch (e) {
      return ApiResponse.error(ErrorHandler.handleError(e));
    }
  }

  // Generic POST request
  Future<ApiResponse<T>> post<T>(
    String endpoint, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    try {
      final response = await _dio.post<T>(
        endpoint,
        data: data,
        queryParameters: queryParameters,
        options: options,
      );
      return ApiResponse.success(response.data as T);
    } on DioException catch (e) {
      return _handleDioError<T>(e);
    } catch (e) {
      return ApiResponse.error(ErrorHandler.handleError(e));
    }
  }

  // Generic PUT request
  Future<ApiResponse<T>> put<T>(
    String endpoint, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    try {
      final response = await _dio.put<T>(
        endpoint,
        data: data,
        queryParameters: queryParameters,
        options: options,
      );
      return ApiResponse.success(response.data as T);
    } on DioException catch (e) {
      return _handleDioError<T>(e);
    } catch (e) {
      return ApiResponse.error(ErrorHandler.handleError(e));
    }
  }

  // Generic PATCH request
  Future<ApiResponse<T>> patch<T>(
    String endpoint, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    try {
      final response = await _dio.patch<T>(
        endpoint,
        data: data,
        queryParameters: queryParameters,
        options: options,
      );
      return ApiResponse.success(response.data as T);
    } on DioException catch (e) {
      return _handleDioError<T>(e);
    } catch (e) {
      return ApiResponse.error(ErrorHandler.handleError(e));
    }
  }

  // Generic DELETE request
  Future<ApiResponse<T>> delete<T>(
    String endpoint, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    try {
      final response = await _dio.delete<T>(
        endpoint,
        data: data,
        queryParameters: queryParameters,
        options: options,
      );
      return ApiResponse.success(response.data as T);
    } on DioException catch (e) {
      return _handleDioError<T>(e);
    } catch (e) {
      return ApiResponse.error(ErrorHandler.handleError(e));
    }
  }

  // File upload with progress
  Future<ApiResponse<T>> upload<T>(
    String endpoint, {
    required String filePath,
    required String fieldName,
    Map<String, dynamic>? data,
    ProgressCallback? onSendProgress,
    Options? options,
  }) async {
    try {
      final formData = FormData.fromMap({
        ...?data,
        fieldName: await MultipartFile.fromFile(filePath),
      });

      final response = await _dio.post<T>(
        endpoint,
        data: formData,
        options: options,
        onSendProgress: onSendProgress,
      );
      return ApiResponse.success(response.data as T);
    } on DioException catch (e) {
      return _handleDioError<T>(e);
    } catch (e) {
      return ApiResponse.error(ErrorHandler.handleError(e));
    }
  }

  // Handle Dio errors
  ApiResponse<T> _handleDioError<T>(DioException error) {
    switch (error.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return ApiResponse.error(
          ErrorHandler.networkError(
            'Connection timeout. Please check your internet connection.',
          ),
        );
      case DioExceptionType.badResponse:
        return _handleHttpError<T>(error);
      case DioExceptionType.cancel:
        return ApiResponse.error(
          ErrorHandler.networkError('Request was cancelled.'),
        );
      case DioExceptionType.connectionError:
        return ApiResponse.error(
          ErrorHandler.networkError(
            'Connection error. Please check your internet connection.',
          ),
        );
      default:
        return ApiResponse.error(
          ErrorHandler.networkError(error.message ?? 'Network error occurred.'),
        );
    }
  }

  // Handle HTTP errors
  ApiResponse<T> _handleHttpError<T>(DioException error) {
    final statusCode = error.response?.statusCode ?? 0;
    final responseData = error.response?.data;

    String message = ApiConfig.unknownErrorMessage;

    if (responseData is Map<String, dynamic>) {
      message =
          responseData['message'] ??
          responseData['error'] ??
          responseData['detail'] ??
          message;
    } else if (responseData is String) {
      try {
        final parsed = json.decode(responseData);
        if (parsed is Map<String, dynamic>) {
          message = parsed['message'] ?? parsed['error'] ?? message;
        }
      } catch (e) {
        message = responseData;
      }
    }

    switch (statusCode) {
      case ApiConfig.unauthorizedCode:
        return ApiResponse.error(
          ErrorHandler.authenticationError(
            message.isNotEmpty ? message : ApiConfig.unauthorizedMessage,
          ),
        );
      case ApiConfig.forbiddenCode:
        return ApiResponse.error(
          ErrorHandler.authenticationError(
            message.isNotEmpty
                ? message
                : 'Access forbidden. You don\'t have permission to access this resource.',
          ),
        );
      case ApiConfig.notFoundCode:
        return ApiResponse.error(
          ErrorHandler.networkError(
            message.isNotEmpty ? message : 'Resource not found.',
          ),
        );
      case ApiConfig.validationErrorCode:
        return ApiResponse.error(
          ErrorHandler.validationError(
            message.isNotEmpty ? message : ApiConfig.validationErrorMessage,
            details: responseData?.toString(),
          ),
        );
      case ApiConfig.serverErrorCode:
        return ApiResponse.error(
          ErrorHandler.networkError(
            message.isNotEmpty ? message : ApiConfig.serverErrorMessage,
          ),
        );
      default:
        return ApiResponse.error(
          ErrorHandler.networkError(
            message.isNotEmpty ? message : 'HTTP Error: $statusCode',
          ),
        );
    }
  }
}

// API Response wrapper
class ApiResponse<T> {
  final T? data;
  final AppError? error;
  final bool isSuccess;

  ApiResponse.success(this.data) : error = null, isSuccess = true;
  ApiResponse.error(this.error) : data = null, isSuccess = false;

  // Helper methods for easy access
  bool get hasError => error != null;
  bool get hasData => data != null;

  // Transform data if needed
  R? map<R>(R Function(T data) transformer) {
    return data != null ? transformer(data as T) : null;
  }
}
