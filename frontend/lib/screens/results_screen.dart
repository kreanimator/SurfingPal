import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../models/forecast_data.dart';
import '../theme/app_theme.dart';
import '../widgets/decision_summary.dart';
import '../widgets/filters_section.dart';
import '../widgets/day_selector.dart';
import '../widgets/best_window_strip.dart';
import '../widgets/timeline_strip.dart';
import '../widgets/sport_card.dart';
import '../utils/forecast_helpers.dart';
import '../utils/sport_formatters.dart';

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
  String? _selectedHour; // Selected hour from timeline
  String? _selectedSport; // Selected sport for expansion (multi-sport mode)
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
    return Scaffold(
      backgroundColor: AppTheme.sand.withOpacity(0.3), // Warm sand background
      appBar: AppBar(
        backgroundColor: AppTheme.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppTheme.slateGray),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Layer 1: Decision Summary (always visible anchor)
            DecisionSummary(
              locationName: widget.locationName,
              forecasts: _selectedDayForecasts,
              selectedSports: _selectedSports,
              onlyRecommended: _onlyRecommended,
            ),
            
            // Filters (quiet, optional)
            FiltersSection(
              availableSports: _availableSports,
              selectedSports: _selectedSports,
              onlyRecommended: _onlyRecommended,
              onSportToggled: (sport) {
                setState(() {
                  _selectedSports[sport] = !(_selectedSports[sport] ?? false);
                  // Reset selection when toggling sports
                  _selectedHour = null;
                  _selectedSport = null;
                });
              },
              onOnlyRecommendedChanged: (value) {
                setState(() {
                  _onlyRecommended = value;
                  _selectedHour = null;
                  _selectedSport = null;
                });
              },
            ),
            
            // Best times by sport (clickable, adapts to multi-sport mode)
            if (_selectedSports.values.where((v) => v == true).length > 1)
              BestWindowStrip(
                availableSports: _availableSports,
                selectedSports: _selectedSports,
                bestHoursBySport: _bestHoursBySport,
                onSportWindowTap: (sportHourKey) {
                  // Format: "sport|hourDate"
                  final parts = sportHourKey.split('|');
                  if (parts.length == 2) {
                    setState(() {
                      _selectedSport = parts[0];
                      _selectedHour = parts[1];
                    });
                  }
                },
              ),
            
            // Day selector (subtle navigation)
            if (_forecastsByDay.length > 1)
              DaySelector(
                forecastsByDay: _forecastsByDay,
                selectedIndex: _selectedDayIndex,
                onDaySelected: (index) {
                  setState(() {
                    _selectedDayIndex = index;
                    _selectedHour = null; // Reset selected hour when changing days
                    _selectedSport = null;
                  });
                },
              ),
            
            // Layer 2: Timeline strip (horizontal scrollable)
            TimelineStrip(
              forecasts: _selectedDayForecasts,
              selectedSports: _selectedSports,
              onlyRecommended: _onlyRecommended,
              selectedHour: _selectedHour,
              selectedSport: _selectedSport,
              onHourSelected: (hourDate) {
                setState(() {
                  _selectedHour = _selectedHour == hourDate ? null : hourDate;
                  _selectedSport = null; // Clear sport selection in single-sport mode
                });
              },
              onSportHourSelected: (sportHourKey) {
                // Format: "sport|hourDate"
                final parts = sportHourKey.split('|');
                if (parts.length == 2) {
                  setState(() {
                    _selectedSport = parts[0];
                    _selectedHour = parts[1];
                  });
                }
              },
              onSportNameTapped: (sport) {
                // Filter to this sport (enter single-sport mode)
                setState(() {
                  // Deselect all other sports
                  for (var key in _selectedSports.keys) {
                    _selectedSports[key] = key == sport;
                  }
                  _selectedHour = null;
                  _selectedSport = null;
                });
              },
            ),
            
            // Layer 3: Expandable sport details
            _buildExpandedDetails(),
            
            // Bottom padding to prevent overflow
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildExpandedDetails() {
    if (_selectedHour == null) {
      return Container(
        padding: const EdgeInsets.symmetric(vertical: 48, horizontal: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.touch_app,
              size: 48,
              color: AppTheme.slateGray.withOpacity(0.3),
            ),
            const SizedBox(height: 16),
            Text(
              _selectedSports.values.where((v) => v == true).length > 1
                  ? 'Tap a cell on the timeline to see details'
                  : 'Tap an hour on the timeline to see details',
              style: GoogleFonts.inter(
                fontSize: 14,
                color: AppTheme.slateGray.withOpacity(0.6),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    // Find the selected hour forecast
    final selectedForecast = _selectedDayForecasts.firstWhere(
      (h) => h.date == _selectedHour,
      orElse: () => _selectedDayForecasts.first,
    );

    // In multi-sport mode, show only the selected sport
    // In single-sport mode, show all selected sports
    final filteredSports = selectedForecast.sports.entries
        .where((entry) {
          if (_selectedSports[entry.key] != true) return false;
          if (_selectedSport != null && entry.key != _selectedSport) return false;
          if (_onlyRecommended && !ForecastHelpers.isRecommended(entry.value.label)) return false;
          return true;
        })
        .toList();

    if (filteredSports.isEmpty) {
      return _buildEmptyState(selectedForecast);
    }

    // Sort by score, hero is first
    filteredSports.sort((a, b) => b.value.score.compareTo(a.value.score));
    final heroSport = filteredSports.first;
    final otherSports = filteredSports.skip(1).toList();

    return Container(
      decoration: BoxDecoration(
        color: AppTheme.white, // White background for expanded cards
      ),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header showing selected sport and hour
          if (_selectedSport != null) ...[
            Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Row(
                children: [
                  Text(
                    '${SportFormatters.getSportName(_selectedSport!)} · ${DateFormat('HH:mm').format(DateTime.parse(selectedForecast.date))}',
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.oceanDeep,
                    ),
                  ),
                ],
              ),
            ),
          ],
          
          // Hero sport (always expanded)
          SportCard(
            sport: heroSport.value,
            hourDate: selectedForecast.date,
            hourlyForecast: selectedForecast,
            isHero: true,
          ),
          
          // Other sports (accordion) - only in single-sport mode
          if (_selectedSport == null) ...[
            ...otherSports.map((entry) {
              final expansionKey = '${selectedForecast.date}|${entry.value.sport}';
              return Padding(
                padding: const EdgeInsets.only(top: 12),
                child: SportCard(
                  sport: entry.value,
                  hourDate: selectedForecast.date,
                  hourlyForecast: selectedForecast,
                  isHero: false,
                  isExpanded: _expandedSports.contains(expansionKey),
                  onToggleExpanded: () => _toggleExpanded(expansionKey),
                ),
              );
            }),
          ],
        ],
      ),
    );
  }

  Widget _buildEmptyState(HourlyForecast forecast) {
    // Check if all selected sports are BAD
    final selectedSportEntries = forecast.sports.entries
        .where((e) => _selectedSports[e.key] == true)
        .toList();
    
    final allBad = selectedSportEntries.isNotEmpty &&
        selectedSportEntries.every((e) => e.value.label.toLowerCase() == 'bad');

    if (allBad) {
      // Find better alternatives
      final betterSports = <String>[];
      for (var entry in forecast.sports.entries) {
        if (_selectedSports[entry.key] == true) continue;
        if (ForecastHelpers.isRecommended(entry.value.label)) {
          betterSports.add(entry.key);
        }
      }

      final badSportNames = selectedSportEntries
          .map((e) => SportFormatters.getSportName(e.key))
          .join(', ');

      return Container(
        padding: const EdgeInsets.symmetric(vertical: 48, horizontal: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.waves,
              size: 48,
              color: AppTheme.slateGray.withOpacity(0.3),
            ),
            const SizedBox(height: 16),
            Text(
              'Not a great day for $badSportNames.',
              style: GoogleFonts.inter(
                fontSize: 14,
                color: AppTheme.slateGray.withOpacity(0.7),
              ),
              textAlign: TextAlign.center,
            ),
            if (betterSports.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                'But perfect for ${betterSports.map((s) => SportFormatters.getSportName(s)).join(', ')} 🌊',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.seafoamGreen,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 48, horizontal: 24),
      child: Text(
        'No forecasts available',
        style: GoogleFonts.inter(
          fontSize: 14,
          color: AppTheme.slateGray.withOpacity(0.5),
        ),
        textAlign: TextAlign.center,
      ),
    );
  }
}
