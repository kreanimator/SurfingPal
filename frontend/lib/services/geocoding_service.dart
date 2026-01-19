import 'package:geocoding/geocoding.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

class GeocodingService {
  /// Get location name from coordinates using reverse geocoding
  /// Falls back to OpenStreetMap Nominatim API if geocoding package fails
  Future<String> getLocationName(double latitude, double longitude) async {
    try {
      // Try using geocoding package first (works on mobile)
      try {
        final placemarks = await placemarkFromCoordinates(latitude, longitude);
        if (placemarks.isNotEmpty) {
          final place = placemarks.first;
          
          // Build location name from available components
          final parts = <String>[];
          
          if (place.locality != null && place.locality!.isNotEmpty) {
            parts.add(place.locality!);
          }
          if (place.administrativeArea != null && place.administrativeArea!.isNotEmpty) {
            if (!parts.contains(place.administrativeArea)) {
              parts.add(place.administrativeArea!);
            }
          }
          if (place.country != null && place.country!.isNotEmpty) {
            parts.add(place.country!);
          }
          
          if (parts.isNotEmpty) {
            return parts.join(', ');
          }
          
          // Fallback: use subLocality or name if available
          if (place.subLocality != null && place.subLocality!.isNotEmpty) {
            return place.subLocality!;
          }
          if (place.name != null && place.name!.isNotEmpty) {
            return place.name!;
          }
        }
      } catch (e) {
        // If geocoding package fails, fall through to API
      }
      
      // Fallback to OpenStreetMap Nominatim API (works everywhere)
      return await _getLocationNameFromNominatim(latitude, longitude);
    } catch (e) {
      // If all fails, return formatted coordinates
      return '${latitude.toStringAsFixed(4)}°N, ${longitude.toStringAsFixed(4)}°E';
    }
  }

  /// Get location name using OpenStreetMap Nominatim API
  Future<String> _getLocationNameFromNominatim(
      double latitude, double longitude) async {
    try {
      final url = Uri.parse(
        'https://nominatim.openstreetmap.org/reverse?'
        'format=json&'
        'lat=$latitude&'
        'lon=$longitude&'
        'zoom=10&'
        'addressdetails=1',
      );

      final response = await http.get(
        url,
        headers: {
          'User-Agent': 'SurfingPal/1.0',
        },
      ).timeout(const Duration(seconds: 5));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final address = data['address'] as Map<String, dynamic>?;

        if (address != null) {
          // Try to get city/town/village name
          final city = address['city'] ??
              address['town'] ??
              address['village'] ??
              address['municipality'] ??
              address['county'];

          // Get state/region
          final state = address['state'] ?? address['region'];

          // Get country
          final country = address['country'];

          final parts = <String>[];
          if (city != null && city.toString().isNotEmpty) {
            parts.add(city.toString());
          }
          if (state != null && state.toString().isNotEmpty) {
            parts.add(state.toString());
          }
          if (country != null && country.toString().isNotEmpty) {
            parts.add(country.toString());
          }

          if (parts.isNotEmpty) {
            return parts.join(', ');
          }

          // Fallback to display name
          final displayName = data['display_name'] as String?;
          if (displayName != null && displayName.isNotEmpty) {
            // Extract first part of display name (usually the most relevant)
            final parts = displayName.split(',');
            if (parts.length >= 2) {
              return '${parts[0]}, ${parts[parts.length - 1]}';
            }
            return displayName;
          }
        }
      }
    } catch (e) {
      // Silently fail and return coordinates
    }

    // Final fallback: formatted coordinates
    return '${latitude.toStringAsFixed(4)}°N, ${longitude.toStringAsFixed(4)}°E';
  }
}
