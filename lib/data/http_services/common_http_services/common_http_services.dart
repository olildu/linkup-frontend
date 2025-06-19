import 'dart:convert';
import 'dart:developer';
import 'dart:io';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'package:linkup/data/models/chat_models/message_model.dart';
import 'package:linkup/presentation/constants/global_constants.dart';

class CommonHttpServices {
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();

  Future<Map<String, dynamic>> uploadMedia({required File file, required MessageType mediaType}) async {
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
      log('[UploadMedia] Success: $jsonData');
       return jsonData;
    } else {
      log('[UploadMedia] Error ${response.statusCode}: ${response.body}');
      throw Exception('Media upload failed: ${response.statusCode}');
    }
  }
}
