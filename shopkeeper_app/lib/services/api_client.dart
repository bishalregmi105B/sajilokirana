import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../constants.dart';

class ApiClient {
  ApiClient._();
  static final ApiClient instance = ApiClient._();
  final _storage = const FlutterSecureStorage();

  late final Dio _dio = Dio(BaseOptions(
    baseUrl: apiBaseUrl, connectTimeout: const Duration(seconds: 10),
    receiveTimeout: const Duration(seconds: 15), contentType: Headers.jsonContentType,
  ))..interceptors.add(InterceptorsWrapper(
    onRequest: (options, handler) async {
      final token = await _storage.read(key: 'authToken');
      if (token != null) options.headers['Authorization'] = 'Bearer \$token';
      handler.next(options);
    },
  ));

  Future<dynamic> get(String path, {Map<String, dynamic>? query}) async {
    final r = await _dio.get(path, queryParameters: query); return r.data;
  }
  Future<dynamic> post(String path, {dynamic body}) async {
    final r = await _dio.post(path, data: body); return r.data;
  }
  Future<dynamic> patch(String path, {dynamic body}) async {
    final r = await _dio.patch(path, data: body); return r.data;
  }
}
