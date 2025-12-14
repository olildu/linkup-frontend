import 'dart:convert';
import 'dart:developer';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:get_it/get_it.dart';
import 'package:http/http.dart' as http;
import 'package:linkup/data/clients/custom_http_client.dart';
import 'package:linkup/data/enums/otp_subject_enum.dart';
import 'package:linkup/data/get_it/get_it_registerer.dart';
import 'package:linkup/data/models/update_metadata_model.dart';
import 'package:linkup/presentation/constants/global_constants.dart';

class AuthHttpServices {
  static final FlutterSecureStorage _secureStorage = GetIt.instance<FlutterSecureStorage>();
  static final CustomHttpClient _client = GetIt.instance<CustomHttpClient>();

  static const String _logTag = 'AuthHttpServices';

  /// Attempts login with given email and password.
  /// Saves access, refresh tokens and userID to secure storage on success.
  /// Returns HTTP status code on success.
  /// Throws an exception on network or unexpected errors.
  static Future<int> login(String email, String password) async {
    final formData = {'username': email, 'password': password};

    try {
      final response = await http.post(Uri.parse("$BASE_URL/token"), body: formData, headers: {'Content-Type': 'application/x-www-form-urlencoded'});

      log('Login response status: ${response.statusCode}', name: _logTag);
      log('Login response body: ${response.body}', name: _logTag);

      if (response.statusCode == 200) {
        final responseBody = jsonDecode(response.body);
        final String accessToken = responseBody['access_token'];
        final String refreshToken = responseBody['refresh_token'];
        final int userID = responseBody['user_id'];

        GetItRegisterer.registerValue<int>(value: userID, name: "user_id");

        await _secureStorage.write(key: 'access_token', value: accessToken);
        await _secureStorage.write(key: 'refresh_token', value: refreshToken);
        await _secureStorage.write(key: 'user_id', value: "$userID");
      }

      return response.statusCode;
    } on http.ClientException catch (e) {
      log('HTTP ClientException during login: $e', name: _logTag);
      throw Exception((e));
    } catch (e, stackTrace) {
      log('Unexpected error during login: $e', name: _logTag, stackTrace: stackTrace);
      throw Exception((e));
    }
  }

  /// Performs the primary functionality as defined in the selection.
  ///
  /// This function is responsible for executing the main logic or operation
  /// as intended by the code. It processes the input, applies the necessary
  /// computations, and returns the result accordingly.
  ///
  /// Detailed behavior and parameters should be specified based on the
  /// actual implementation within the selection.
  static Future<int> sendEmailOTP({required String email}) async {
    try {
      final response = await http.get(Uri.parse("$BASE_URL/verify-email?email=$email"), headers: {'Content-Type': 'application/json'});

      log('OTP response status: ${response.statusCode}', name: _logTag);
      log('OTP response body: ${response.body}', name: _logTag);

      return response.statusCode;
    } on http.ClientException catch (e) {
      log('HTTP ClientException during sendEmailOTP: $e', name: _logTag);
      return 500;
    } catch (e, stackTrace) {
      log('Unexpected error during sendEmailOTP: $e', name: _logTag, stackTrace: stackTrace);
      return 500;
    }
  }

  /// Verifies the OTP sent to the user's email.
  ///
  /// Sends a POST request to the server with the email and OTP for verification.
  /// Returns a `Map<String, dynamic>` containing the response body on success,
  /// or throws an exception if the request fails.
  static Future<Map<String, dynamic>> verifyEmailOTP({required String email, required int otp, required EmailOTPSubject subject}) async {
    try {
      final response = await http.post(Uri.parse("$BASE_URL/verify-otp"), headers: {'Content-Type': 'application/json'}, body: jsonEncode({"email": email, "otp": otp, "subject": subject.value}));

      log('OTP response status: ${response.statusCode}', name: _logTag);
      log('OTP response body: ${response.body}', name: _logTag);

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        final error = jsonDecode(response.body);
        throw Exception("OTP verification failed: ${error['detail'] ?? 'Unknown error'}");
      }
    } on http.ClientException catch (e) {
      log('HTTP ClientException during verifyEmailOTP: $e', name: _logTag);
      throw Exception('Network error during OTP verification');
    } catch (e, stackTrace) {
      log('Unexpected error during verifyEmailOTP: $e', name: _logTag, stackTrace: stackTrace);
      throw Exception('Unexpected error during OTP verification');
    }
  }

  /// Completes the signup process using a verified email token and password.
  ///
  /// Sends a POST request to the server with the `email_hash` (token) and `password`.
  /// Returns a `Map<String, dynamic>` containing the response body on success,
  /// or throws an exception if the request fails.
  static Future<bool> completeSignupCreds({required String emailHash, required String password}) async {
    try {
      final response = await http.post(Uri.parse("$BASE_URL/signup"), headers: {'Content-Type': 'application/json'}, body: jsonEncode({"email_hash": emailHash, "password": password}));

      log('Signup response status: ${response.statusCode}', name: _logTag);
      log('Signup response body: ${response.body}', name: _logTag);

      if (response.statusCode == 200 || response.statusCode == 201) {
        final responseBody = jsonDecode(response.body);
        if (responseBody['status'] == 'success') {
          final String accessToken = responseBody['access_token'];
          final String refreshToken = responseBody['refresh_token'];
          final int userID = responseBody['user_id'];

          GetItRegisterer.registerValue<int>(value: userID, name: "user_id");

          await _secureStorage.write(key: 'access_token', value: accessToken);
          await _secureStorage.write(key: 'refresh_token', value: refreshToken);
          await _secureStorage.write(key: 'user_id', value: "$userID");
          return true;
        } else {
          return false;
        }
      } else {
        final error = jsonDecode(response.body);
        throw Exception("Signup failed: ${error['detail'] ?? 'Unknown error'}");
      }
    } on http.ClientException catch (e) {
      log('HTTP ClientException during completeSignup: $e', name: _logTag);
      throw Exception('Network error during signup');
    } catch (e, stackTrace) {
      log('Unexpected error during completeSignup: $e', name: _logTag, stackTrace: stackTrace);
      throw Exception('Unexpected error during signup');
    }
  }

  /// Resets the user's password using a verified email token.
  ///
  /// Sends a POST request to the `/reset-password` endpoint with the
  /// `email_hash` (verified email token) and the new `password`.
  ///
  /// Parameters:
  /// - [emailHash]: The email verification token obtained after successful OTP verification.
  /// - [password]: The new password to set for the user.
  ///
  /// Returns:
  /// - `true` if the password reset was successful (i.e., server returns `status: success`),
  /// - otherwise throws an `Exception` with error details.
  ///
  /// Throws:
  /// - `Exception` on network errors, non-success responses, or unexpected failures.
  static Future<bool> resetPassword({required String emailHash, required String password}) async {
    try {
      final response = await http.post(Uri.parse("$BASE_URL/reset-password"), headers: {'Content-Type': 'application/json'}, body: jsonEncode({"email_hash": emailHash, "password": password}));

      log('Reset Password response status: ${response.statusCode}', name: _logTag);

      if (response.statusCode == 200 || response.statusCode == 201) {
        final responseBody = jsonDecode(response.body);
        return responseBody['status'] == 'success';
      } else {
        final error = jsonDecode(response.body);
        throw Exception("Password reset failed: ${error['detail'] ?? 'Unknown error'}");
      }
    } on http.ClientException catch (e) {
      log('HTTP ClientException during resetPassword: $e', name: _logTag);
      throw Exception('Network error during password reset');
    } catch (e, stackTrace) {
      log('Unexpected error during resetPassword: $e', name: _logTag, stackTrace: stackTrace);
      throw Exception('Unexpected error during password reset');
    }
  }

  /// Completes the profile registration for a signed-in user.
  ///
  /// Sends a POST request to the `/register` endpoint with user profile data,
  /// using the provided bearer `accessToken` for authorization.
  ///
  /// Parameters:
  /// - [data]: A `UpdateMetadataModel` containing the complete profile information to send.
  ///
  /// Returns:
  /// - `true` if the profile was successfully completed (i.e., server returns a `msg` field),
  /// - otherwise throws an `Exception` with error details.
  ///
  /// Throws:
  /// - `Exception` on non-200 response or unexpected errors.
  static Future<bool> completeProfile({required UpdateMetadataModel data}) async {
    try {
      final response = await _client.post(Uri.parse('$BASE_URL/register'), body: jsonEncode(data.toJson()));

      log('Register body sent: ${jsonEncode(data.toJson())}', name: _logTag);
      log('Register response status: ${response.statusCode}', name: _logTag);
      log('Register response body: ${response.body}', name: _logTag);

      if (response.statusCode == 200 || response.statusCode == 201) {
        final responseBody = jsonDecode(response.body);
        return responseBody['msg'] != null;
      } else {
        final error = jsonDecode(response.body);
        throw Exception("Profile completion failed: ${error['detail'] ?? 'Unknown error'}");
      }
    } on http.ClientException catch (e) {
      log('HTTP ClientException during completeProfile: $e', name: _logTag);
      throw Exception('Network error during profile completion');
    } catch (e, stackTrace) {
      log('Unexpected error during completeProfile: $e', name: _logTag, stackTrace: stackTrace);
      throw Exception('Unexpected error during profile completion');
    }
  }
}
