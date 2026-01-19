import '../models/forecast_data.dart';

class SportFormatters {
  /// Get human-readable sport name
  static String getSportName(String sport) {
    switch (sport) {
      case 'surfing':
        return 'Surf';
      case 'sup':
        return 'SUP';
      case 'sup_surf':
        return 'SUP Surf';
      case 'windsurfing':
        return 'Wind';
      case 'kitesurfing':
        return 'Kite';
      default:
        return sport;
    }
  }

  /// Build sport-specific hero line with most relevant metrics
  static String buildHeroLine(SportForecast sport) {
    final parts = <String>[];
    
    // Sport-specific hero line with most relevant metrics first
    switch (sport.sport) {
      case 'surfing':
      case 'sup_surf':
        // Wave-focused sports: Wave height @ period, Chop, Current, Temp, UV
        final waveHeight = sport.context['wave_height_m'];
        final wavePeriod = sport.context['wave_period_s'];
        if (waveHeight != null && wavePeriod != null) {
          parts.add('${waveHeight.toStringAsFixed(1)}m @ ${wavePeriod.toStringAsFixed(1)}s');
        } else if (waveHeight != null) {
          parts.add('${waveHeight.toStringAsFixed(1)}m waves');
        }
        
        final windWaveHeight = sport.context['wind_wave_height_m'];
        if (windWaveHeight != null && windWaveHeight > 0.2) {
          parts.add('Chop ${windWaveHeight.toStringAsFixed(1)}m');
        }
        
        final current = sport.context['current_kmh'];
        if (current != null && current > 2.0) {
          parts.add('Current ${current.toStringAsFixed(1)} km/h');
        }
        
        final temp = sport.context['water_temp_c'];
        if (temp != null) {
          parts.add('${temp.toStringAsFixed(0)}°C');
        }
        
        final uvIndex = sport.context['uv_index'];
        if (uvIndex != null && uvIndex > 0) {
          parts.add('UV ${uvIndex.toStringAsFixed(0)}');
        }
        break;
        
      case 'sup':
        // SUP: Wave height, Chop, Current (most important), Temp, UV
        final waveHeight = sport.context['wave_height_m'];
        if (waveHeight != null) {
          parts.add('Waves ${waveHeight.toStringAsFixed(1)}m');
        }
        
        final windWaveHeight = sport.context['wind_wave_height_m'];
        if (windWaveHeight != null && windWaveHeight > 0.15) {
          parts.add('Chop ${windWaveHeight.toStringAsFixed(1)}m');
        }
        
        final current = sport.context['current_kmh'];
        if (current != null) {
          parts.add('Current ${current.toStringAsFixed(1)} km/h');
        }
        
        final temp = sport.context['water_temp_c'];
        if (temp != null) {
          parts.add('${temp.toStringAsFixed(0)}°C');
        }
        
        final uvIndex = sport.context['uv_index'];
        if (uvIndex != null && uvIndex > 0) {
          parts.add('UV ${uvIndex.toStringAsFixed(0)}');
        }
        break;
        
      case 'windsurfing':
      case 'kitesurfing':
        // Wind sports: Wind waves (proxy for wind), Wave height, Current, Temp, UV
        final windWaveHeight = sport.context['wind_wave_height_m'];
        if (windWaveHeight != null) {
          parts.add('Wind waves ${windWaveHeight.toStringAsFixed(1)}m');
        }
        
        final waveHeight = sport.context['wave_height_m'];
        if (waveHeight != null && waveHeight > 0.5) {
          parts.add('Waves ${waveHeight.toStringAsFixed(1)}m');
        }
        
        final current = sport.context['current_kmh'];
        if (current != null && current > 2.0) {
          parts.add('Current ${current.toStringAsFixed(1)} km/h');
        }
        
        final temp = sport.context['water_temp_c'];
        if (temp != null) {
          parts.add('${temp.toStringAsFixed(0)}°C');
        }
        
        final uvIndex = sport.context['uv_index'];
        if (uvIndex != null && uvIndex > 0) {
          parts.add('UV ${uvIndex.toStringAsFixed(0)}');
        }
        break;
        
      default:
        // Fallback: show all available metrics
        final waveHeight = sport.context['wave_height_m'];
        final wavePeriod = sport.context['wave_period_s'];
        if (waveHeight != null && wavePeriod != null) {
          parts.add('${waveHeight.toStringAsFixed(1)}m @ ${wavePeriod.toStringAsFixed(1)}s');
        } else if (waveHeight != null) {
          parts.add('${waveHeight.toStringAsFixed(1)}m');
        }
        
        final current = sport.context['current_kmh'];
        if (current != null) {
          parts.add('Current ${current.toStringAsFixed(1)} km/h');
        }
        
        final temp = sport.context['water_temp_c'];
        if (temp != null) {
          parts.add('${temp.toStringAsFixed(0)}°C');
        }
        
        final uvIndex = sport.context['uv_index'];
        if (uvIndex != null && uvIndex > 0) {
          parts.add('UV ${uvIndex.toStringAsFixed(0)}');
        }
    }

    return parts.isEmpty ? 'No data available' : parts.join(' • ');
  }
}
