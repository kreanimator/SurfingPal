import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiService {
  // For web: use localhost
  // For mobile: use your computer's IP address (e.g., 'http://192.168.1.100:8000')
  // For production: use your deployed backend URL
  static const String baseUrl = 'http://localhost:8000';
  
  // Uncomment and set for mobile development:
  // static const String baseUrl = 'http://YOUR_COMPUTER_IP:8000';
  
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
