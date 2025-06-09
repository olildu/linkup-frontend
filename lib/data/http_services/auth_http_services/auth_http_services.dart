import 'dart:convert';
import 'dart:developer';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'package:linkup/presentation/constants/global_constants.dart';

class AuthHttpServices {
  /// Attempts login with given email and password.
  /// Saves access and refresh tokens to secure storage on success.
  /// Returns HTTP status code on success.
  /// Throws an exception on network or unexpected errors.
  static Future<int> login(String email, String password) async {
    final secureStorage = FlutterSecureStorage();
    
    final formData = {
      'username': email,
      'password': password,
    };

    try {
      final response = await http.post(
        Uri.parse("$BASE_URL/token"),
        body: formData,
        headers: {
          'Content-Type': 'application/x-www-form-urlencoded',
        },
      );

      log('Login response status: ${response.statusCode}');
      log('Login response body: ${response.body}');

      if (response.statusCode == 200) {
        final responseBody = jsonDecode(response.body);
        final String accessToken = responseBody['access_token'];
        final String refreshToken = responseBody['refresh_token'];

        await secureStorage.write(key: 'access_token', value: accessToken);
        await secureStorage.write(key: 'refresh_token', value: refreshToken);
      }

      return response.statusCode;
    } on http.ClientException catch (e) {
      log('HTTP ClientException during login: $e');
      rethrow;
    } catch (e, stackTrace) {
      log('Unexpected error during login: $e', stackTrace: stackTrace);
      rethrow;
    }
  }
}
