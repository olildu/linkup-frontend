import 'dart:convert';
import 'dart:io'; // Required for SocketException
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:get_it/get_it.dart';
import 'package:http/http.dart' as http;
import 'package:linkup/presentation/constants/global_constants.dart';

class CustomHttpClient {
  final _storage = GetIt.instance<FlutterSecureStorage>();

  Future<http.Response> delete(Uri uri, {Map<String, String>? headers, Object? body}) async {
    return _executeRequest(
      () => _sendWithAuth((token) {
        final allHeaders = _mergeHeaders(token, headers);
        return http.delete(uri, headers: allHeaders, body: body);
      }),
    );
  }

  Future<http.Response> post(Uri uri, {Map<String, String>? headers, Object? body}) async {
    return _executeRequest(
      () => _sendWithAuth((token) {
        final allHeaders = _mergeHeaders(token, headers);
        return http.post(uri, headers: allHeaders, body: body);
      }),
    );
  }

  Future<http.Response> get(Uri uri, {Map<String, String>? headers}) async {
    return _executeRequest(
      () => _sendWithAuth((token) {
        final allHeaders = _mergeHeaders(token, headers);
        return http.get(uri, headers: allHeaders);
      }),
    );
  }

  Future<http.Response> postMultipart(Uri uri, {Map<String, String>? headers, required Map<String, String> fields, required Future<List<http.MultipartFile>> Function() buildFiles}) async {
    return _executeRequest(
      () => _sendWithAuth((token) async {
        final request = http.MultipartRequest("POST", uri)
          ..headers.addAll({'Authorization': 'Bearer $token', ...?headers})
          ..fields.addAll(fields)
          ..files.addAll(await buildFiles());

        final streamedResponse = await request.send();
        return http.Response.fromStream(streamedResponse);
      }),
    );
  }

  /// 1. Central execution wrapper for Network/Socket errors
  Future<http.Response> _executeRequest(Future<http.Response> Function() request) async {
    try {
      final response = await request();
      return handleResponse(response);
    } on SocketException {
      throw Exception("No internet connection. Please check your network.");
    } on HttpException {
      throw Exception("Couldn't find the requested service.");
    } on FormatException {
      throw Exception("Bad response format from server.");
    } catch (e) {
      throw Exception("An unexpected error occurred. Please try again.");
    }
  }

  /// 2. Central Response Parser for Backend/Logic errors
  http.Response handleResponse(http.Response response) {
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return response;
    }

    // Map known technical errors to user-friendly messages
    String message = "Something went wrong (Error ${response.statusCode})";

    try {
      final Map<String, dynamic> body = jsonDecode(response.body);
      final String detail = body['detail']?.toString() ?? "";

      if (detail.contains('duplicate key') && detail.contains('users_email_key')) {
        message = "This email is already registered. Please log in.";
      } else if (detail.contains('OTP verification failed')) {
        message = "The code you entered is incorrect. Please try again.";
      } else if (detail.contains('Password must contain at')) {
        message = "Password must contain at least one uppercase letter, one lowercase letter, and one symbol.";
      } else if (detail.contains('Face not detected')) {
        message = "We couldn't detect a clear face in your photo.";
      } else if (response.statusCode == 401) {
        message = "Session expired. Please log in again.";
      } else if (response.statusCode == 500) {
        message = "Server maintenance. Please try again in a few minutes.";
      } else if (detail.isNotEmpty) {
        message = detail; // Use backend detail if it's not a known constraint
      }
    } catch (_) {
      // If body isn't JSON, use the default message based on status code
    }

    throw Exception(message);
  }

  Future<http.Response> _sendWithAuth(Future<http.Response> Function(String accessToken) request) async {
    String? accessToken = await _storage.read(key: 'access_token');
    if (accessToken == null) throw Exception("Unauthorized. Please log in.");

    http.Response response = await request(accessToken);

    if (response.statusCode == 401) {
      final refreshed = await refreshToken();
      if (refreshed) {
        accessToken = await _storage.read(key: 'access_token');
        response = await request(accessToken!);
      }
    }

    return response;
  }

  Map<String, String> _mergeHeaders(String accessToken, Map<String, String>? extra) {
    return {'Content-Type': 'application/json', 'Authorization': 'Bearer $accessToken', ...?extra};
  }

  Future<bool> refreshToken() async {
    final refreshToken = await _storage.read(key: 'refresh_token');
    if (refreshToken == null) return false;

    try {
      final res = await http.post(Uri.parse('$BASE_URL/refresh'), headers: {'Content-Type': 'application/json'}, body: jsonEncode({'refresh_token': refreshToken}));

      if (res.statusCode == 200) {
        final body = jsonDecode(res.body);
        await _storage.write(key: 'access_token', value: body['access_token']);
        return true;
      }
    } catch (_) {}
    return false;
  }
}
