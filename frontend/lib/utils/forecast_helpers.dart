import 'package:intl/intl.dart';
import '../models/forecast_data.dart';

class ForecastHelpers {
  /// Group hourly forecasts by day
  static List<List<HourlyForecast>> groupByDay(List<HourlyForecast> forecasts) {
    if (forecasts.isEmpty) return [];

    final Map<String, List<HourlyForecast>> dayGroups = {};
    
    for (var forecast in forecasts) {
      final date = DateTime.parse(forecast.date);
      final dayKey = DateFormat('yyyy-MM-dd').format(date);
      
      if (!dayGroups.containsKey(dayKey)) {
        dayGroups[dayKey] = [];
      }
      dayGroups[dayKey]!.add(forecast);
    }

    final sortedDays = dayGroups.keys.toList()..sort();
    return sortedDays.map((day) => dayGroups[day]!).toList();
  }

  /// Get day label (Today, Tomorrow, or date)
  static String getDayLabel(int index, List<List<HourlyForecast>> forecastsByDay) {
    if (index >= forecastsByDay.length) return 'Day ${index + 1}';
    
    final firstForecast = forecastsByDay[index].first;
    final date = DateTime.parse(firstForecast.date);
    final today = DateTime.now();
    final dayDate = DateTime(date.year, date.month, date.day);
    final todayDate = DateTime(today.year, today.month, today.day);
    
    final diff = dayDate.difference(todayDate).inDays;
    
    if (diff == 0) return 'Today';
    if (diff == 1) return 'Tomorrow';
    if (diff == 2) return 'Day After';
    
    return DateFormat('MMM d').format(date);
  }

  /// Get best hours for each sport
  static Map<String, List<MapEntry<String, SportForecast>>> getBestHoursBySport(
    List<HourlyForecast> forecasts,
    Map<String, bool> selectedSports,
    bool onlyRecommended,
  ) {
    final Map<String, List<MapEntry<String, SportForecast>>> bestHours = {};
    
    for (var hourly in forecasts) {
      for (var entry in hourly.sports.entries) {
        if (selectedSports[entry.key] != true) continue;
        if (onlyRecommended && !isRecommended(entry.value.label)) continue;
        
        if (!bestHours.containsKey(entry.key)) {
          bestHours[entry.key] = [];
        }
        bestHours[entry.key]!.add(MapEntry(hourly.date, entry.value));
      }
    }
    
    for (var sport in bestHours.keys) {
      bestHours[sport]!.sort((a, b) => b.value.score.compareTo(a.value.score));
      bestHours[sport] = bestHours[sport]!.take(3).toList();
    }
    
    return bestHours;
  }

  /// Check if a label is recommended (great or ok)
  static bool isRecommended(String label) {
    return label.toLowerCase() == 'great' || label.toLowerCase() == 'ok';
  }

  /// Get best window string for a sport
  static String getBestWindow(
    List<MapEntry<String, SportForecast>> bestHours,
  ) {
    if (bestHours.isEmpty) return '—';
    
    final times = bestHours.map((e) {
      return DateFormat('HH:mm').format(DateTime.parse(e.key));
    }).toList();
    
    return times.join('–');
  }

  /// Find better alternatives for a bad sport at the same hour
  static List<String> findBetterAlternatives(
    HourlyForecast hourly,
    String currentSport,
  ) {
    final alternatives = <String>[];
    
    // Get all sports for this hour, sorted by score
    final allSports = hourly.sports.entries.toList()
      ..sort((a, b) => b.value.score.compareTo(a.value.score));
    
    for (var entry in allSports) {
      if (entry.key == currentSport) continue;
      if (isRecommended(entry.value.label)) {
        alternatives.add(entry.key);
      }
    }
    
    return alternatives.take(2).toList();
  }
}
