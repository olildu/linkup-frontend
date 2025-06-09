import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class TokenServices {
  final FlutterSecureStorage _secureStorage;
  TokenServices(this._secureStorage);
  
  Future<bool> tokenExists() async {
    final String? accessToken = await _secureStorage.read(key: 'access_token');
    final String? refreshToken = await _secureStorage.read(key: 'refresh_token');
    return accessToken != null && refreshToken != null;
  }
}