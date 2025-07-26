import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:get_it/get_it.dart';
import 'package:linkup/data/get_it/get_it_registerer.dart';

class TokenServices {
  final FlutterSecureStorage _secureStorage = GetIt.instance<FlutterSecureStorage>();

  Future<bool> tokenExists() async {
    final accessToken = await _secureStorage.read(key: 'access_token');
    final refreshToken = await _secureStorage.read(key: 'refresh_token');
    return accessToken != null && refreshToken != null;
  }

  Future<void> registerUserIdIfExists() async {
    final userIdStr = await _secureStorage.read(key: 'user_id');
    final int? userId = userIdStr != null ? int.tryParse(userIdStr) : null;

    if (userId != null) {
      GetItRegisterer.registerValue<int>(value: userId, name: "user_id");
    }
  }

  Future<void> clearTokens() async {
    final refreshToken = await _secureStorage.read(key: 'refresh_token');

    if (refreshToken != null) {
      await _secureStorage.delete(key: 'access_token');
      await _secureStorage.delete(key: 'refresh_token');
      await _secureStorage.delete(key: 'user_id');
    }
  }
}
