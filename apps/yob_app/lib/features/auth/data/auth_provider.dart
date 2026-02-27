import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../../core/utils/providers.dart';

/// Auth state
class AuthState {
  final bool isAuthenticated;
  final bool isLoading;
  final Map<String, dynamic>? user;
  final String? error;

  const AuthState({
    this.isAuthenticated = false,
    this.isLoading = false,
    this.user,
    this.error,
  });

  AuthState copyWith({
    bool? isAuthenticated,
    bool? isLoading,
    Map<String, dynamic>? user,
    String? error,
  }) {
    return AuthState(
      isAuthenticated: isAuthenticated ?? this.isAuthenticated,
      isLoading: isLoading ?? this.isLoading,
      user: user ?? this.user,
      error: error,
    );
  }
}

/// Auth notifier
class AuthNotifier extends StateNotifier<AuthState> {
  final Dio _dio;
  final FlutterSecureStorage _storage;

  AuthNotifier(this._dio, this._storage) : super(const AuthState());

  Future<void> checkAuth() async {
    state = state.copyWith(isLoading: true);

    try {
      final token = await _storage.read(key: 'access_token');
      if (token == null) {
        state = const AuthState();
        return;
      }

      final response = await _dio.get('/auth/me');
      final data = response.data as Map<String, dynamic>;

      if (data['success'] == true) {
        state = AuthState(
          isAuthenticated: true,
          user: data['data'] as Map<String, dynamic>,
        );
      } else {
        await _storage.deleteAll();
        state = const AuthState();
      }
    } catch (_) {
      await _storage.deleteAll();
      state = const AuthState();
    }
  }

  Future<bool> login(String email, String password) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final response = await _dio.post(
        '/auth/login',
        data: {'email': email, 'password': password},
      );

      final data = response.data as Map<String, dynamic>;

      if (data['success'] == true) {
        final authData = data['data'] as Map<String, dynamic>;
        await _storage.write(
          key: 'access_token',
          value: authData['token'] as String,
        );
        await _storage.write(
          key: 'refresh_token',
          value: authData['refresh_token'] as String,
        );

        state = AuthState(
          isAuthenticated: true,
          user: authData['user'] as Map<String, dynamic>,
        );
        return true;
      } else {
        state = state.copyWith(
          isLoading: false,
          error: data['message'] as String? ?? 'Erreur de connexion',
        );
        return false;
      }
    } on DioException catch (e) {
      final message = e.response?.data?['message'] as String? ??
          'Erreur de connexion au serveur';
      state = state.copyWith(isLoading: false, error: message);
      return false;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: 'Erreur inattendue');
      return false;
    }
  }

  Future<void> logout() async {
    await _storage.deleteAll();
    state = const AuthState();
  }
}

/// Provider
final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  final dio = ref.watch(dioProvider);
  final storage = ref.watch(secureStorageProvider);
  return AuthNotifier(dio, storage);
});
