import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

final _baseUrl = dotenv.get('API_BASE_URL', fallback: 'http://10.0.2.2:3000/api/v1');

class ApiClient {
  final Dio _dio;
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  ApiClient()
      : _dio = Dio(BaseOptions(
          baseUrl: _baseUrl,
          connectTimeout: const Duration(seconds: 10),
          receiveTimeout: const Duration(seconds: 15),
          sendTimeout: const Duration(seconds: 10),
          headers: {'Content-Type': 'application/json'},
        )) {
    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        final token = await _storage.read(key: 'access_token');
        if (token != null) {
          options.headers['Authorization'] = 'Bearer $token';
        }
        return handler.next(options);
      },
      onError: (error, handler) async {
        // ── Connection errors → friendly message ───────────────────────────
        if (error.type == DioExceptionType.connectionTimeout ||
            error.type == DioExceptionType.receiveTimeout ||
            error.type == DioExceptionType.connectionError) {
          return handler.reject(
            DioException(
              requestOptions: error.requestOptions,
              type: error.type,
              error: 'SERVER_UNREACHABLE',
              message:
                  'Cannot reach server. Make sure the backend is running on port 3000.',
            ),
          );
        }

        // ── 401 → try token refresh ────────────────────────────────────────
        if (error.response?.statusCode == 401) {
          try {
            final refreshToken = await _storage.read(key: 'refresh_token');
            if (refreshToken != null) {
              final res = await Dio(BaseOptions(
                baseUrl: _baseUrl,
                connectTimeout: const Duration(seconds: 10),
                receiveTimeout: const Duration(seconds: 15),
              )).post('/auth/refresh', data: {'refreshToken': refreshToken});
              final newToken = res.data['accessToken'] as String;
              await _storage.write(key: 'access_token', value: newToken);
              error.requestOptions.headers['Authorization'] =
                  'Bearer $newToken';
              final retryRes = await _dio.fetch(error.requestOptions);
              return handler.resolve(retryRes);
            }
          } catch (_) {}
        }

        return handler.next(error);
      },
    ));
  }

  Future<Response> get(String path, {Map<String, dynamic>? params}) =>
      _dio.get(path, queryParameters: params);

  Future<Response> post(String path, {dynamic data}) =>
      _dio.post(path, data: data);

  Future<Response> patch(String path, {dynamic data}) =>
      _dio.patch(path, data: data);

  Future<Response> delete(String path) => _dio.delete(path);

  Future<void> saveTokens(String access, String refresh) async {
    await _storage.write(key: 'access_token', value: access);
    await _storage.write(key: 'refresh_token', value: refresh);
  }

  Future<void> clearTokens() async {
    await _storage.deleteAll();
  }

  /// Test backend connectivity — returns true if reachable
  Future<bool> isServerReachable() async {
    try {
      await Dio(BaseOptions(
        connectTimeout: const Duration(seconds: 5),
        receiveTimeout: const Duration(seconds: 5),
      )).get('${_baseUrl.replaceAll('/api/v1', '')}/health');
      return true;
    } catch (_) {
      return false;
    }
  }
}

final apiClientProvider = Provider<ApiClient>((ref) => ApiClient());
