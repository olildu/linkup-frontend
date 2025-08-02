import 'dart:convert';
import 'dart:developer';
import 'package:get_it/get_it.dart';
import 'package:http/http.dart' as http;
import 'package:linkup/data/clients/custom_http_client.dart';
import 'package:linkup/presentation/constants/global_constants.dart';

class CityLookupHttpServices {
  static const String _logTag = 'CityLookupHttpServices';
  static final CustomHttpClient _client = GetIt.instance<CustomHttpClient>();

  /// Searches for cities in India based on the query string.
  /// Returns a list of matching city names from FastAPI.
  static Future<List<String>> searchCities(String query) async {
    try {
      final response = await _client.get(
        Uri.parse("$BASE_URL/locations/india/search/$query"),
        headers: {'Content-Type': 'application/json'},
      );

      log('City search response status: ${response.statusCode}', name: _logTag);
      log('City search response body: ${response.body}', name: _logTag);

      if (response.statusCode == 200) {
        final List<dynamic> jsonResponse = jsonDecode(response.body);
        return jsonResponse.cast<String>();
      } else {
        throw Exception("City search failed with status: ${response.statusCode}");
      }
    } on http.ClientException catch (e) {
      log('HTTP ClientException during city search: $e', name: _logTag);
      throw Exception('Network error during city search');
    } catch (e, stackTrace) {
      log('Unexpected error during city search: $e', name: _logTag, stackTrace: stackTrace);
      throw Exception('Unexpected error during city search');
    }
  }
}
