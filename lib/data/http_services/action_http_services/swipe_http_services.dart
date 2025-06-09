import 'dart:convert';
import 'dart:developer';

import 'package:flutter_card_swiper/flutter_card_swiper.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'package:linkup/presentation/constants/global_constants.dart';

class SwipeHttpServices {
  static Future<Map> swipe({
    required int likedId,
    required CardSwiperDirection action, 
  }) async {
    log("Liked ID : $likedId");

    final secureStorage = FlutterSecureStorage();
    final accessToken = await secureStorage.read(key: 'access_token');

    final endpoint = action == CardSwiperDirection.left ? '/swipe/left' : '/swipe/right';

    var res = await http.post(
      Uri.parse("$BASE_URL$endpoint"),
      headers: {
        'Authorization': 'Bearer $accessToken',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        "liked_id": likedId.toString(),
      }),
    );

    Map returnedBody = jsonDecode(res.body);

    if (action == CardSwiperDirection.right) {
      return returnedBody;
    } else {
      return {
        "match" : false
      };
    }
  }
}
