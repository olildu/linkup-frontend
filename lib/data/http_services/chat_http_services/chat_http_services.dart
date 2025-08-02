import 'dart:convert';
import 'dart:developer';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:get_it/get_it.dart';
import 'package:linkup/data/clients/custom_http_client.dart';
import 'package:linkup/data/models/chat_models/message_model.dart';
import 'package:linkup/presentation/constants/global_constants.dart';

class ChatHttpServices {
  final FlutterSecureStorage _secureStorage = GetIt.instance<FlutterSecureStorage>();
  static final CustomHttpClient _client = GetIt.instance<CustomHttpClient>();

  Future<Map<String, dynamic>> startChat({required int chatUserId}) async {
    final accessToken = await _secureStorage.read(key: 'access_token');

    final response = await _client.post(
      Uri.parse("$BASE_URL/chats/start-chat"),
      headers: {'Authorization': 'Bearer $accessToken', 'Content-Type': 'application/json'},
      body: jsonEncode({"id": chatUserId}),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      log('[ChatHttpServices] Error: ${response.statusCode}');
      throw Exception('Failed to start chat. Status: ${response.statusCode} Server-Response: ${response.body}');
    }
  }

  Future<List<Message>> fetchChatMessages({required int chatRoomId}) async {
    final accessToken = await _secureStorage.read(key: 'access_token');

    final response = await _client.post(
      Uri.parse("$BASE_URL/chats/get/chat"),
      headers: {'Authorization': 'Bearer $accessToken', 'Content-Type': 'application/json'},
      body: jsonEncode({"chat_room_id": chatRoomId}),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final messages = (data['messages'] as List).map((message) => Message.fromJson(message)).toList();
      return messages;
    } else {
      log('[ChatHttpServices] Error: ${response.statusCode}');
      throw Exception('Failed to start chat. Status: ${response.statusCode} Server-Response: ${response.body}');
    }
  }

  Future<List<Message>> fetchPaginatedChatMessages({
    required int chatRoomId,
    required String lastMessageId,
    required DateTime lastMessageTimeStamp,
  }) async {
    final accessToken = await _secureStorage.read(key: 'access_token');

    final response = await _client.post(
      Uri.parse("$BASE_URL/chats/get/chat-paginated"),
      headers: {'Authorization': 'Bearer $accessToken', 'Content-Type': 'application/json'},
      body: jsonEncode({
        "chat_room_id": chatRoomId,
        "last_message_id": lastMessageId,
        "last_message_timestamp": lastMessageTimeStamp.toIso8601String(),
      }),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final messages = (data['messages'] as List).map((message) => Message.fromJson(message)).toList();
      return messages;
    } else {
      log('[ChatHttpServices] Error: ${response.statusCode}');
      throw Exception('Failed to start chat. Status: ${response.statusCode} Server-Response: ${response.body}');
    }
  }
}
