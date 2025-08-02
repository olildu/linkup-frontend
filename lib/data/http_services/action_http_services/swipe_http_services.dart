import 'dart:convert';
import 'package:flutter_card_swiper/flutter_card_swiper.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:get_it/get_it.dart';
import 'package:linkup/data/clients/custom_http_client.dart';
import 'package:linkup/presentation/constants/global_constants.dart';

class SwipeHttpServices {
  static final CustomHttpClient _client = GetIt.instance<CustomHttpClient>();
  static final FlutterSecureStorage _secureStorage = GetIt.instance<FlutterSecureStorage>();

  static Future<Map> swipe({required int likedId, required CardSwiperDirection action}) async {
    final accessToken = await _secureStorage.read(key: 'access_token');
    final endpoint = action == CardSwiperDirection.left ? '/swipe/left' : '/swipe/right';

    var res = await _client.post(
      Uri.parse("$BASE_URL$endpoint"),
      headers: {'Authorization': 'Bearer $accessToken', 'Content-Type': 'application/json'},
      body: jsonEncode({"liked_id": likedId.toString()}),
    );

    Map returnedBody = jsonDecode(res.body);

    if (action == CardSwiperDirection.right) {
      return returnedBody;
    } else {
      return {"match": false};
    }
  }
}
