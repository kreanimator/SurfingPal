import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../models/forecast_data.dart';
import '../theme/app_theme.dart';
import 'sport_card.dart';
import '../utils/forecast_helpers.dart';

class HourlyItem extends StatelessWidget {
  final HourlyForecast hourly;
  final Map<String, bool> selectedSports;
  final bool onlyRecommended;
  final Set<String> expandedSports;
  final ValueChanged<String> onToggleExpanded;

  const HourlyItem({
    super.key,
    required this.hourly,
    required this.selectedSports,
    required this.onlyRecommended,
    required this.expandedSports,
    required this.onToggleExpanded,
  });

  String _getExpansionKey(String hourDate, String sport) {
    return '$hourDate|$sport';
  }

  bool _isExpanded(String hourDate, String sport) {
    return expandedSports.contains(_getExpansionKey(hourDate, sport));
  }

  @override
  Widget build(BuildContext context) {
    final filteredSports = hourly.sports.entries
        .where((entry) {
          if (selectedSports[entry.key] != true) return false;
          if (onlyRecommended && !ForecastHelpers.isRecommended(entry.value.label)) return false;
          return true;
        })
        .toList();

    if (filteredSports.isEmpty) return const SizedBox.shrink();

    // Find hero sport (best score)
    filteredSports.sort((a, b) => b.value.score.compareTo(a.value.score));
    final heroSport = filteredSports.first;
    final otherSports = filteredSports.skip(1).toList();

    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Timeline marker (thin vertical line with dot)
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 1,
                height: 8,
                color: AppTheme.slateGray.withOpacity(0.2),
              ),
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: AppTheme.oceanBlue,
                  shape: BoxShape.circle,
                ),
              ),
              Container(
                width: 1,
                height: 300,
                color: AppTheme.slateGray.withOpacity(0.1),
              ),
            ],
          ),
          const SizedBox(width: 16),
          // Time label
          SizedBox(
            width: 50,
            child: Text(
              DateFormat('HH:mm').format(DateTime.parse(hourly.date)),
              style: GoogleFonts.poppins(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: AppTheme.slateGray.withOpacity(0.6),
              ),
            ),
          ),
          const SizedBox(width: 16),
          // Sports cards
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Hero sport (emphasized, always expanded)
                SportCard(
                  sport: heroSport.value,
                  hourDate: hourly.date,
                  hourlyForecast: hourly,
                  isHero: true,
                ),
                // Other sports (secondary, accordion)
                ...otherSports.map((entry) => Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: SportCard(
                    sport: entry.value,
                    hourDate: hourly.date,
                    hourlyForecast: hourly,
                    isHero: false,
                    isExpanded: _isExpanded(hourly.date, entry.value.sport),
                    onToggleExpanded: () => onToggleExpanded(_getExpansionKey(hourly.date, entry.value.sport)),
                  ),
                )),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
