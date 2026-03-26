import '../models/user_model.dart';
import 'api_service.dart';

class AuthService {
  static Future<UserModel> login(String email, String password) async {
    final response = await ApiService.client.post(
      '/auth/login',
      data: {'email': email, 'password': password},
    );
    final user = UserModel.fromJson(response.data as Map<String, dynamic>);
    ApiService.setAuthToken(user.token);
    return user;
  }

  static Future<UserModel> register(
      String name, String email, String password) async {
    final response = await ApiService.client.post(
      '/auth/register',
      data: {'name': name, 'email': email, 'password': password},
    );
    final user = UserModel.fromJson(response.data as Map<String, dynamic>);
    ApiService.setAuthToken(user.token);
    return user;
  }

  static Future<void> forgotPassword(String email) async {
    await ApiService.client.post(
      '/auth/forgot-password',
      data: {'email': email},
    );
  }

  static Future<void> resetPassword(
      String email, String resetCode, String newPassword) async {
    await ApiService.client.post(
      '/auth/reset-password',
      data: {
        'email': email,
        'reset_code': resetCode,
        'new_password': newPassword,
      },
    );
  }

  static void logout() => ApiService.clearAuthToken();
}
