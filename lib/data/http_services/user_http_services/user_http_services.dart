import 'dart:convert';
import 'dart:developer';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'package:linkup/data/models/match_candidate_model.dart';
import 'package:linkup/data/models/update_metadata_model.dart';
import 'package:linkup/data/models/user_model.dart';
import 'package:linkup/data/models/user_preference_model.dart';
import 'package:linkup/presentation/constants/global_constants.dart';

class UserHttpServices {
  Future<UserModel> getProfileSettings() async {
    final secureStorage = FlutterSecureStorage();
    final accessToken = await secureStorage.read(key: 'access_token');

    final response = await http.get(
      Uri.parse("$BASE_URL/me"),
      headers: {
        'Authorization': 'Bearer $accessToken',
      },
    );

    if (response.statusCode == 200) {
      final Map<String, dynamic> jsonData = json.decode(response.body);
      return UserModel.fromJson(jsonData);
    } 
    else {
      print('Error: ${response.statusCode}');
      throw Exception('Failed to fetch matches. Status: ${response.statusCode} Server-Response: ${response.body}');
    }
  }

  Future<MatchCandidateModel> getOtherProfile({required int userId}) async {
    final secureStorage = FlutterSecureStorage();
    final accessToken = await secureStorage.read(key: 'access_token');

    final response = await http.get(
      Uri.parse("$BASE_URL/user/get/detail/$userId"), 
      headers: {
        'Authorization': 'Bearer $accessToken',
      },
    );

    if (response.statusCode == 200) {
      log(json.decode(response.body).toString());
      final Map<String, dynamic> jsonData = json.decode(response.body);
      return MatchCandidateModel.fromJson(jsonData);
    } 
    else {
      print('Error: ${response.statusCode}');
      throw Exception('Failed to fetch matches. Status: ${response.statusCode} Server-Response: ${response.body}');
    }
  }

  Future<UserPreferenceModel> getUserPreference() async {
    final secureStorage = FlutterSecureStorage();
    final accessToken = await secureStorage.read(key: 'access_token');

    final response = await http.get(
      Uri.parse("$BASE_URL/user/get/preferences"),
      headers: {
        'Authorization': 'Bearer $accessToken',
      },
    );

    if (response.statusCode == 200) {
      final Map<String, dynamic> jsonData = json.decode(response.body);
      return UserPreferenceModel.fromJson(jsonData);
    } 
    else {
      print('Error: ${response.statusCode}');
      throw Exception('Failed to fetch matches. Status: ${response.statusCode} Server-Response: ${response.body}');
    }
  }

  Future<void> updateUserPreference({
    required UserPreferenceModel userPreference,
  }) async {
    final secureStorage = FlutterSecureStorage();
    final accessToken = await secureStorage.read(key: 'access_token');

    var body = userPreference.toJson();

    final response = await http.post(
      Uri.parse("$BASE_URL/user/update/preferences"),
      headers: {
        'Authorization': 'Bearer $accessToken',
        'Content-Type': 'application/json',
      },
      body: json.encode(body),
    );

    if (response.statusCode == 200) {
      final Map<String, dynamic> jsonData = json.decode(response.body);
      log('User preferences updated successfully: $jsonData');
    } 
    else {
      print('Error: ${response.statusCode}');
      throw Exception('Failed to fetch matches. Status: ${response.statusCode} Server-Response: ${response.body}');
    }
  }

  Future<void> updateUserProfile({
    required UpdateMetadataModel userUpdatedModel,
  }) async {
    final secureStorage = FlutterSecureStorage();
    final accessToken = await secureStorage.read(key: 'access_token');

    var body = userUpdatedModel.toJson();

    final response = await http.post(
      Uri.parse("$BASE_URL/user/update/metadata"),
      headers: {
        'Authorization': 'Bearer $accessToken',
        'Content-Type': 'application/json',
      },
      body: json.encode(body),
    );

    if (response.statusCode == 200) {
      final Map<String, dynamic> jsonData = json.decode(response.body);
      log('User preferences updated successfully: $jsonData');
    } 
    else {
    log('Error: ${response.statusCode}');
      throw Exception('Failed to fetch matches. Status: ${response.statusCode} Server-Response: ${response.body}');
    }
  }


}