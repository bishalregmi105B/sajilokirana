/// Central Dio HTTP client for SajiloKirana backend.
///
/// - Injects Bearer token automatically from [FlutterSecureStorage].
/// - Normalises errors into [ApiException].
/// - All callers import this file — nothing touches Dio directly.
import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import 'package:ecom/constants.dart';
import 'package:ecom/Services/Exceptions/api_exception.dart';

class ApiClient {
  ApiClient._();
  static final ApiClient instance = ApiClient._();

  final _storage = const FlutterSecureStorage();

  late final Dio _dio = Dio(
    BaseOptions(
      baseUrl: apiBaseUrl,
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 15),
      contentType: Headers.jsonContentType,
      responseType: ResponseType.json,
    ),
  )..interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          final token = await _storage.read(key: 'authToken');
          if (token != null) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          handler.next(options);
        },
        onError: (err, handler) {
          final status = err.response?.statusCode ?? 500;
          final message = err.response?.data is Map
              ? (err.response!.data['message'] as String? ?? err.message ?? 'Unknown error')
              : (err.message ?? 'Unknown error');
          handler.reject(
            DioException(
              requestOptions: err.requestOptions,
              error: ApiException(status, message),
              response: err.response,
            ),
          );
        },
      ),
    );

  /// Unwraps [DioException] into [ApiException] for callers.
  Future<T> _safeCall<T>(Future<T> Function() fn) async {
    try {
      return await fn();
    } on DioException catch (e) {
      final err = e.error;
      if (err is ApiException) rethrow;
      throw ApiException(
        e.response?.statusCode ?? 500,
        e.message ?? 'Network error',
      );
    }
  }

  Future<dynamic> get(String path, {Map<String, dynamic>? query}) =>
      _safeCall(() async {
        final r = await _dio.get(path, queryParameters: query);
        return r.data;
      });

  Future<dynamic> post(String path, {dynamic body}) =>
      _safeCall(() async {
        final r = await _dio.post(path, data: body);
        return r.data;
      });

  Future<dynamic> patch(String path, {dynamic body}) =>
      _safeCall(() async {
        final r = await _dio.patch(path, data: body);
        return r.data;
      });

  Future<void> delete(String path) =>
      _safeCall(() async {
        await _dio.delete(path);
      });
}
