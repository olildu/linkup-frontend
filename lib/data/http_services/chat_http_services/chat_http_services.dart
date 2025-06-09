import 'dart:convert';
import 'dart:developer';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'package:linkup/data/models/chat_models/message_model.dart';
import 'package:linkup/presentation/constants/global_constants.dart';

class ChatHttpServices {
  Future<int> startChat({
    required int chatUserId
  }) async {
    final secureStorage = FlutterSecureStorage();
    final accessToken = await secureStorage.read(key: 'access_token');

    final response = await http.post(
      Uri.parse("$BASE_URL/chats/start-chat"),
      headers: {
        'Authorization': 'Bearer $accessToken',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        "id" : chatUserId
      })
    );

    if (response.statusCode == 200) {
      return 0;
    } 
    else {
      log('[ChatHttpServices] Error: ${response.statusCode}');
      throw Exception('Failed to start chat. Status: ${response.statusCode} Server-Response: ${response.body}');
    }
  }

  Future<List<Message>> fetchChatMessages({
    required int chatRoomId
  }) async {
    final secureStorage = FlutterSecureStorage();
    final accessToken = await secureStorage.read(key: 'access_token');

    final response = await http.post(
      Uri.parse("$BASE_URL/chats/get/chat"),
      headers: {
        'Authorization': 'Bearer $accessToken',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        "chat_room_id" : chatRoomId
      })
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final messages = (data['messages'] as List).map((message) => Message.fromJson(message)).toList();
      return messages;
    } 
    else {
      log('[ChatHttpServices] Error: ${response.statusCode}');
      throw Exception('Failed to start chat. Status: ${response.statusCode} Server-Response: ${response.body}');
    }
  }
}