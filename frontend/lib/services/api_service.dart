import 'dart:convert';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:http/http.dart' as http;

class ApiService {
  static String get baseUrl {
    if (kIsWeb) return Uri.base.origin;
    return 'https://surfingpal.app';
  }

  Future<Map<String, dynamic>> getForecast({
    double? latitude,
    double? longitude,
  }) async {
    try {
      final uri = Uri.parse('$baseUrl/api/forecast');
      final response = await http.post(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          if (latitude != null) 'latitude': latitude,
          if (longitude != null) 'longitude': longitude,
        }),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      } else {
        throw Exception('Failed to load forecast: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error fetching forecast: $e');
    }
  }
}
