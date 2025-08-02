import 'dart:convert';
import 'dart:developer';
import 'dart:io';
import 'package:get_it/get_it.dart';
import 'package:http/http.dart' as http;
import 'package:linkup/data/clients/custom_http_client.dart';
import 'package:linkup/data/enums/message_type_enum.dart';
import 'package:linkup/presentation/constants/global_constants.dart';

class CommonHttpServices {
  static final CustomHttpClient _client = GetIt.instance<CustomHttpClient>();

  Future<Map<String, dynamic>> uploadMediaChat({required File file, required MessageType mediaType}) async {
    final response = await _client.postMultipart(
      Uri.parse("$BASE_URL/upload/media"),
      fields: {'media_type': mediaType.name},
      buildFiles: () async => [await http.MultipartFile.fromPath('file', file.path)],
    );

    if (response.statusCode == 200) {
      final jsonData = json.decode(response.body);
      log('[uploadMediaChat] Success: $jsonData');
      return jsonData;
    } else {
      log('[uploadMediaChat] Error ${response.statusCode}: ${response.body}');
      throw Exception('Media upload failed: ${response.statusCode}');
    }
  }

  Future<Map<String, dynamic>> uploadMediaUser({required File file, required MessageType mediaType}) async {
    final response = await _client.postMultipart(
      Uri.parse("$BASE_URL/upload/media-user"),
      fields: {'media_type': mediaType.name},
      buildFiles: () async => [await http.MultipartFile.fromPath('file', file.path)],
    );

    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      log('[uploadMediaUser] Error ${response.statusCode}: ${response.body}');
      throw Exception('Media upload failed: ${response.statusCode}');
    }
  }

  Future<Map<String, dynamic>> uploadProfilePictureFromUrl({required String imageUrl}) async {
    final response = await _client.postMultipart(
      Uri.parse("$BASE_URL/upload/media-user-pfp-from-url"),
      fields: {'image_url': imageUrl},
      buildFiles: () async => [],
    );

    if (response.statusCode == 200) {
      final jsonData = json.decode(response.body);
      log('[uploadProfilePictureFromUrl] Success: $jsonData');
      return jsonData;
    } else {
      log('[uploadProfilePictureFromUrl] Error ${response.statusCode}: ${response.body}');
      throw Exception('PFP upload from URL failed: ${response.statusCode}');
    }
  }

  Future<Map<String, dynamic>> uploadPfp({required File file, required MessageType mediaType}) async {
    final response = await _client.postMultipart(
      Uri.parse("$BASE_URL/upload/media-user-pfp"),
      fields: {'media_type': mediaType.name},
      buildFiles: () async => [await http.MultipartFile.fromPath('file', file.path)],
    );

    if (response.statusCode == 200) {
      final jsonData = json.decode(response.body);
      log('[uploadPfp] Success: $jsonData');
      return jsonData;
    } else {
      log('[uploadPfp] Error ${response.statusCode}: ${response.body}');
      throw Exception('PFP upload failed: ${response.statusCode}');
    }
  }
}
