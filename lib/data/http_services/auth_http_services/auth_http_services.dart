import 'dart:convert';
import 'dart:developer';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:get_it/get_it.dart';
import 'package:http/http.dart' as http;
import 'package:isar/isar.dart';
import 'package:linkup/data/get_it/get_it_registerer.dart';
import 'package:linkup/presentation/constants/global_constants.dart';

class AuthHttpServices {
  /// Attempts login with given email and password.
  /// Saves access and refresh tokens to secure storage on success.
  /// Returns HTTP status code on success.
  /// Throws an exception on network or unexpected errors.
  static Future<int> login(String email, String password) async {
    final FlutterSecureStorage secureStorage = GetIt.instance<FlutterSecureStorage>();

    final formData = {'username': email, 'password': password};

    try {
      final response = await http.post(Uri.parse("$BASE_URL/token"), body: formData, headers: {'Content-Type': 'application/x-www-form-urlencoded'});

      log('Login response status: ${response.statusCode}');
      log('Login response body: ${response.body}');

      if (response.statusCode == 200) {
        final responseBody = jsonDecode(response.body);
        final String accessToken = responseBody['access_token'];
        final String refreshToken = responseBody['refresh_token'];
        final int userID = responseBody['user_id'];

        GetItRegisterer.registerValue<int>(value: userID, name: "user_id");

        await secureStorage.write(key: 'access_token', value: accessToken);
        await secureStorage.write(key: 'refresh_token', value: refreshToken);
        await secureStorage.write(key: 'user_id', value: "$userID");
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
