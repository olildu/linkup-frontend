import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:get_it/get_it.dart';
import 'package:http/http.dart' as http;
import 'package:linkup/presentation/constants/global_constants.dart';

class CustomHttpClient {
  final _storage = GetIt.instance<FlutterSecureStorage>();

  Future<http.Response> post(Uri uri, {Map<String, String>? headers, Object? body}) async {
    return _sendWithAuth((token) {
      final allHeaders = _mergeHeaders(token, headers);
      return http.post(uri, headers: allHeaders, body: body);
    });
  }

  Future<http.Response> get(Uri uri, {Map<String, String>? headers}) async {
    return _sendWithAuth((token) {
      final allHeaders = _mergeHeaders(token, headers);
      return http.get(uri, headers: allHeaders);
    });
  }

  Future<http.Response> postMultipart(
    Uri uri, {
    Map<String, String>? headers,
    required Map<String, String> fields,
    required Future<List<http.MultipartFile>> Function() buildFiles,
  }) async {
    return _sendWithAuth((token) async {
      final request =
          http.MultipartRequest("POST", uri)
            ..headers.addAll({'Authorization': 'Bearer $token', ...?headers})
            ..fields.addAll(fields)
            ..files.addAll(await buildFiles());

      final streamedResponse = await request.send();
      return http.Response.fromStream(streamedResponse);
    });
  }

  Future<http.Response> _sendWithAuth(Future<http.Response> Function(String accessToken) request) async {
    String? accessToken = await _storage.read(key: 'access_token');

    http.Response response = await request(accessToken!);

    if (response.statusCode == 401) {
      final refreshed = await refreshToken();
      if (refreshed) {
        accessToken = await _storage.read(key: 'access_token');
        response = await request(accessToken!);
      } else {
        throw Exception("Session expired. Please login again.");
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

    final res = await http.post(
      Uri.parse('$BASE_URL/refresh'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'refresh_token': refreshToken}),
    );

    if (res.statusCode == 200) {
      final body = jsonDecode(res.body);
      await _storage.write(key: 'access_token', value: body['access_token']);
      return true;
    }

    return false;
  }
}
