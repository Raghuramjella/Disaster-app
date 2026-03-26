import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/user_model.dart';
import '../services/auth_service.dart';

class AuthState {
  final UserModel? user;
  final bool isLoading;
  final String? error;

  const AuthState({
    this.user,
    this.isLoading = false,
    this.error,
  });

  bool get isAuthenticated => user != null;

  AuthState copyWith({
    UserModel? user,
    bool? isLoading,
    String? error,
    bool clearUser = false,
    bool clearError = false,
  }) {
    return AuthState(
      user: clearUser ? null : (user ?? this.user),
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
    );
  }
}

class AuthNotifier extends Notifier<AuthState> {
  @override
  AuthState build() => const AuthState();

  Future<void> login(String email, String password) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final user = await AuthService.login(email, password);
      state = state.copyWith(user: user, isLoading: false);
    } on DioException catch (e) {
      final msg = _errorMessage(e);
      state = state.copyWith(isLoading: false, error: msg);
      throw Exception(msg);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      rethrow;
    }
  }

  Future<void> register(String name, String email, String password) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final user = await AuthService.register(name, email, password);
      state = state.copyWith(user: user, isLoading: false);
    } on DioException catch (e) {
      final msg = _errorMessage(e);
      state = state.copyWith(isLoading: false, error: msg);
      throw Exception(msg);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      rethrow;
    }
  }

  Future<void> forgotPassword(String email) async {
    try {
      await AuthService.forgotPassword(email);
    } on DioException catch (e) {
      throw Exception(_errorMessage(e));
    }
  }

  Future<void> resetPassword(
      String email, String resetCode, String newPassword) async {
    try {
      await AuthService.resetPassword(email, resetCode, newPassword);
    } on DioException catch (e) {
      throw Exception(_errorMessage(e));
    }
  }

  void logout() {
    AuthService.logout();
    state = const AuthState();
  }

  String _errorMessage(DioException e) {
    if (e.response?.data?['detail'] != null) {
      return e.response!.data['detail'].toString();
    }
    if (e.type == DioExceptionType.connectionError ||
        e.type == DioExceptionType.connectionTimeout) {
      return 'Cannot connect to server. Make sure the backend is running.';
    }
    return e.message ?? 'Something went wrong';
  }
}

final authProvider = NotifierProvider<AuthNotifier, AuthState>(AuthNotifier.new);
