import 'dart:convert';
import 'dart:developer';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:get_it/get_it.dart';
import 'package:http/http.dart' as http;
import 'package:linkup/data/models/chats_connection_model.dart';
import 'package:linkup/data/models/matches_connection_model.dart';
import 'package:linkup/presentation/constants/global_constants.dart';
import 'package:linkup/data/models/match_candidate_model.dart';

class MatchHttpServices {
  final FlutterSecureStorage _secureStorage = GetIt.instance<FlutterSecureStorage>();

  Future<List<MatchCandidateModel>> getMatchUsers() async {
    final accessToken = await _secureStorage.read(key: 'access_token');

    final response = await http.get(Uri.parse("$BASE_URL/matches/get-matches"), headers: {'Authorization': 'Bearer $accessToken'});

    if (response.statusCode == 200) {
      final Map jsonData = json.decode(response.body)[0];
      final List matches = jsonData["matches"];

      return matches.map((json) => MatchCandidateModel.fromJson(json)).toList();
    } else {
      log('[GetMatchUsers] Error: ${response.statusCode}');
      throw Exception('Failed to fetch matches. Status: ${response.statusCode} Server-Response: ${response.body}');
    }
  }

  Future<Map<String, dynamic>> getConnections() async {
    final accessToken = await _secureStorage.read(key: 'access_token');

    final response = await http.get(Uri.parse("$BASE_URL/matches/get-connections"), headers: {'Authorization': 'Bearer $accessToken'});

    if (response.statusCode == 200) {
      final Map jsonData = json.decode(response.body);

      log('Response Data: $jsonData');

      final List<MatchesConnectionModel> matches =
          (jsonData["matches"] as List<dynamic>).map((json) => MatchesConnectionModel.fromJson(json)).toList();
      final List<ChatsConnectionModel> chats = (jsonData["chats"] as List<dynamic>).map((json) => ChatsConnectionModel.fromJson(json)).toList();

      log('Matches: $matches, Chats: $chats');

      return {'matches': matches, 'chats': chats};
    } else {
      log('[GetMatchUsers] Error: ${response.statusCode}');
      throw Exception('Failed to fetch matches. Status: ${response.statusCode} Server-Response: ${response.body}');
    }
  }
}
