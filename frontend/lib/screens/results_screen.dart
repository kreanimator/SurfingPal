import 'package:flutter/material.dart';
import '../models/forecast_data.dart';
import '../theme/app_theme.dart';
import '../widgets/location_header.dart';
import '../widgets/filters_section.dart';
import '../widgets/day_selector.dart';
import '../widgets/best_window_strip.dart';
import '../widgets/hourly_item.dart';
import '../utils/forecast_helpers.dart';

class ResultsScreen extends StatefulWidget {
  final ForecastData forecastData;
  final String? locationName;
  final double? latitude;
  final double? longitude;

  const ResultsScreen({
    super.key,
    required this.forecastData,
    this.locationName,
    this.latitude,
    this.longitude,
  });

  @override
  State<ResultsScreen> createState() => _ResultsScreenState();
}

class _ResultsScreenState extends State<ResultsScreen> {
  final Map<String, bool> _selectedSports = {
    'surfing': true,
    'sup': true,
    'sup_surf': true,
    'windsurfing': true,
    'kitesurfing': true,
  };

  bool _onlyRecommended = false;
  int _selectedDayIndex = 0;
  // Track expanded state: key is "date|sport" (e.g., "2026-01-19T08:00:00Z|sup")
  final Set<String> _expandedSports = {};

  List<String> get _availableSports {
    if (widget.forecastData.scores.isEmpty) return [];
    return widget.forecastData.scores.first.sports.keys.toList();
  }

  List<List<HourlyForecast>> get _forecastsByDay {
    return ForecastHelpers.groupByDay(widget.forecastData.scores);
  }

  List<HourlyForecast> get _selectedDayForecasts {
    if (_selectedDayIndex >= _forecastsByDay.length) return [];
    return _forecastsByDay[_selectedDayIndex];
  }

  Map<String, List<MapEntry<String, SportForecast>>> get _bestHoursBySport {
    return ForecastHelpers.getBestHoursBySport(
      _selectedDayForecasts,
      _selectedSports,
      _onlyRecommended,
    );
  }

  void _toggleExpanded(String expansionKey) {
    setState(() {
      if (_expandedSports.contains(expansionKey)) {
        _expandedSports.remove(expansionKey);
      } else {
        // Extract hourDate from expansionKey (format: "date|sport")
        final hourDate = expansionKey.split('|').first;
        // Remove other expanded sports for this hour
        _expandedSports.removeWhere((k) => k.startsWith('$hourDate|'));
        _expandedSports.add(expansionKey);
      }
    });
  }

  @override
  void initState() {
    super.initState();
    for (var sport in _availableSports) {
      _selectedSports[sport] = _selectedSports[sport] ?? true;
    }
  }

  @override
  Widget build(BuildContext context) {
    final coordinates = widget.forecastData.meta['coordinates'];
    final lat = coordinates?['latitude'] as double? ?? widget.latitude;
    final lon = coordinates?['longitude'] as double? ?? widget.longitude;
    final coordsStr = lat != null && lon != null 
        ? '${lat.toStringAsFixed(3)}, ${lon.toStringAsFixed(3)}'
        : null;
    
    return Scaffold(
      backgroundColor: AppTheme.white,
      appBar: AppBar(
        backgroundColor: AppTheme.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppTheme.slateGray),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Column(
        children: [
          // 1️⃣ Context layer (very light, orientation only)
          LocationHeader(
            locationName: widget.locationName,
            coordinates: coordsStr,
          ),
          
          // 2️⃣ Filters (quiet, optional)
          FiltersSection(
            availableSports: _availableSports,
            selectedSports: _selectedSports,
            onlyRecommended: _onlyRecommended,
            onSportToggled: (sport) {
              setState(() {
                _selectedSports[sport] = !(_selectedSports[sport] ?? false);
              });
            },
            onOnlyRecommendedChanged: (value) {
              setState(() => _onlyRecommended = value);
            },
          ),
          
          // 3️⃣ Day selector (subtle navigation)
          if (_forecastsByDay.length > 1)
            DaySelector(
              forecastsByDay: _forecastsByDay,
              selectedIndex: _selectedDayIndex,
              onDaySelected: (index) => setState(() => _selectedDayIndex = index),
            ),
          
          // 4️⃣ Best window strip (decision-first, scannable)
          BestWindowStrip(
            availableSports: _availableSports,
            selectedSports: _selectedSports,
            bestHoursBySport: _bestHoursBySport,
          ),
          
          // 5️⃣ Hourly section (timeline feel)
          Expanded(child: _buildHourlySection()),
        ],
      ),
    );
  }

  Widget _buildHourlySection() {
    final filteredForecasts = _selectedDayForecasts.where((hourly) {
      return hourly.sports.entries.any((entry) {
        if (_selectedSports[entry.key] != true) return false;
        if (_onlyRecommended && !ForecastHelpers.isRecommended(entry.value.label)) return false;
        return true;
      });
    }).toList();

    if (filteredForecasts.isEmpty) {
      return Center(
        child: Text(
          'No forecasts available',
          style: TextStyle(
            color: AppTheme.slateGray.withOpacity(0.5),
          ),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      itemCount: filteredForecasts.length,
      itemBuilder: (context, index) {
        return HourlyItem(
          hourly: filteredForecasts[index],
          selectedSports: _selectedSports,
          onlyRecommended: _onlyRecommended,
          expandedSports: _expandedSports,
          onToggleExpanded: _toggleExpanded,
        );
      },
    );
  }
}
