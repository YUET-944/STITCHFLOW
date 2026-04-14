import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'api_client.dart';

class AuthUser {
  final String id;
  final String readableId;
  final String role;
  final String fullName;
  final String username;
  final String? city;

  const AuthUser({
    required this.id,
    required this.readableId,
    required this.role,
    required this.fullName,
    required this.username,
    this.city,
  });

  factory AuthUser.fromJson(Map<String, dynamic> json) => AuthUser(
        id: json['id'] ?? '',
        readableId: json['readable_id'] ?? '',
        role: json['role'] ?? '',
        fullName: json['full_name'] ?? '',
        username: json['username'] ?? '',
        city: json['city'] ?? json['location_city'],
      );

  bool get isTailor => role == 'TAILOR';
  bool get isClient => role == 'CLIENT';
}

@immutable
class AuthState {
  final AuthUser? user;
  final bool isLoading;
  final String? error;

  const AuthState({this.user, this.isLoading = false, this.error});

  bool get isAuthenticated => user != null;

  AuthState copyWith({AuthUser? user, bool? isLoading, String? error}) =>
      AuthState(
        user: user ?? this.user,
        isLoading: isLoading ?? this.isLoading,
        error: error,
      );
}

// Riverpod 3.x uses Notifier<State> instead of StateNotifier<State>
class AuthNotifier extends Notifier<AuthState> {
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  ApiClient get _api => ref.read(apiClientProvider);

  @override
  AuthState build() {
    _restoreSession();
    return const AuthState();
  }

  Future<void> _restoreSession() async {
    final token = await _storage.read(key: 'access_token');
    final userJson = await _storage.read(key: 'user_json');
    if (token != null && userJson != null) {
      try {
        final map = jsonDecode(userJson) as Map<String, dynamic>;
        state = AuthState(user: AuthUser.fromJson(map));
      } catch (_) {}
    }
  }

  Future<bool> sendOtp(String phone) async {
    try {
      await _api.post('/auth/send-otp', data: {'phone': phone});
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<bool> verifyOtp(String phone, String otp) async {
    try {
      final res = await _api.post('/auth/verify-otp', data: {'phone': phone, 'otp': otp});
      return res.data['verified'] == true;
    } catch (_) {
      return false;
    }
  }

  Future<String?> register(Map<String, dynamic> body) async {
    state = const AuthState(isLoading: true);
    try {
      final res = await _api.post('/auth/register', data: body);
      await _api.saveTokens(res.data['accessToken'] as String, res.data['refreshToken'] as String);
      final user = AuthUser.fromJson(Map<String, dynamic>.from(res.data['user'] as Map));
      await _storage.write(
        key: 'user_json',
        value: jsonEncode({
          'id': user.id,
          'readable_id': user.readableId,
          'role': user.role,
          'full_name': user.fullName,
          'username': user.username,
        }),
      );
      state = AuthState(user: user);
      return null;
    } catch (e) {
      state = AuthState(error: e.toString());
      return e.toString();
    }
  }

  Future<String?> login(String username, String password) async {
    state = const AuthState(isLoading: true);
    try {
      final res = await _api.post('/auth/login', data: {
        'username': username,
        'password': password
      });
      await _api.saveTokens(res.data['accessToken'] as String, res.data['refreshToken'] as String);
      final user = AuthUser.fromJson(Map<String, dynamic>.from(res.data['user'] as Map));
      await _storage.write(
        key: 'user_json',
        value: jsonEncode({
          'id': user.id,
          'readable_id': user.readableId,
          'role': user.role,
          'full_name': user.fullName,
          'username': user.username,
          'city': user.city,
        }),
      );
      state = AuthState(user: user);
      return null;
    } catch (e) {
      state = AuthState(error: e.toString());
      return e.toString();
    }
  }

  /// ── Demo Login (no server needed) ─────────────────────────────────────────
  /// Call with role = 'TAILOR' or 'CLIENT' to get KHAN demo account
  /// ── Demo Login (hits server with KHAN/KHAN) ──────────────────────────────────
  Future<String?> demoLogin(String role) async {
    // We now use real login with the bypass credentials to get a REAL valid JWT
    final username = role == 'TAILOR' ? 'KHAN' : 'KHAN_CLIENT';
    return login(username, 'KHAN');
  }

  bool get isDemoMode =>
      state.user?.id.startsWith('demo-') == true;

  Future<void> logout() async {
    try {
      await _api.delete('/auth/logout');
    } catch (_) {}
    await _api.clearTokens();
    await _storage.delete(key: 'user_json');
    state = const AuthState();
  }
}

// Riverpod 3.x NotifierProvider
final authProvider = NotifierProvider<AuthNotifier, AuthState>(AuthNotifier.new);
