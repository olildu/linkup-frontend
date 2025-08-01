import 'dart:convert';
import 'dart:developer';
import 'dart:io';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:get_it/get_it.dart';
import 'package:http/http.dart' as http;
import 'package:linkup/data/enums/message_type_enum.dart';
import 'package:linkup/presentation/constants/global_constants.dart';
// add this if not already

class CommonHttpServices {
  final FlutterSecureStorage _secureStorage = GetIt.instance<FlutterSecureStorage>();

  Future<Map<String, dynamic>> uploadMediaChat({required File file, required MessageType mediaType}) async {
    final accessToken = await _secureStorage.read(key: 'access_token');

    if (accessToken == null) {
      throw Exception('Access token not found');
    }

    final uri = Uri.parse("$BASE_URL/upload/media");
    final request =
        http.MultipartRequest("POST", uri)
          ..headers['Authorization'] = 'Bearer $accessToken'
          ..fields['media_type'] = mediaType.name
          ..files.add(await http.MultipartFile.fromPath('file', file.path));

    final streamedResponse = await request.send();
    final response = await http.Response.fromStream(streamedResponse);

    if (response.statusCode == 200) {
      final Map<String, dynamic> jsonData = json.decode(response.body);

      // Log all response fields if needed
      log('[uploadMediaChat] Success: $jsonData');
      return jsonData;
    } else {
      log('[uploadMediaChat] Error ${response.statusCode}: ${response.body}');
      throw Exception('Media upload failed: ${response.statusCode}');
    }
  }

  Future<Map<String, dynamic>> uploadMediaUser({required File file, required MessageType mediaType}) async {
    final accessToken = await _secureStorage.read(key: 'access_token');

    if (accessToken == null) {
      throw Exception('Access token not found');
    }

    final uri = Uri.parse("$BASE_URL/upload/media-user");

    final request =
        http.MultipartRequest("POST", uri)
          ..headers['Authorization'] = 'Bearer $accessToken'
          ..fields['media_type'] = mediaType.name
          ..files.add(await http.MultipartFile.fromPath('file', file.path));

    final streamedResponse = await request.send();
    final response = await http.Response.fromStream(streamedResponse);

    if (response.statusCode == 200) {
      final Map<String, dynamic> jsonData = json.decode(response.body);
      return jsonData;
    } else {
      log('[uploadMediaUser] Error ${response.statusCode}: ${response.body}');
      throw Exception('Media upload failed: ${response.statusCode}');
    }
  }

  Future<Map<String, dynamic>> uploadPfp({required File file, required MessageType mediaType}) async {
    final accessToken = await _secureStorage.read(key: 'access_token');

    if (accessToken == null) {
      throw Exception('Access token not found');
    }

    final uri = Uri.parse("$BASE_URL/upload/media-user-pfp");

    final request =
        http.MultipartRequest("POST", uri)
          ..headers['Authorization'] = 'Bearer $accessToken'
          ..fields['media_type'] = mediaType.name
          ..files.add(await http.MultipartFile.fromPath('file', file.path));

    final streamedResponse = await request.send();
    final response = await http.Response.fromStream(streamedResponse);

    if (response.statusCode == 200) {
      final Map<String, dynamic> jsonData = json.decode(response.body);
      log('[uploadPfp] Success: $jsonData');
      return jsonData;
    } else {
      log('[uploadPfp] Error ${response.statusCode}: ${response.body}');
      return {'status': 'failed'};
    }
  }
}
