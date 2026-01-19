import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../models/forecast_data.dart';
import '../theme/app_theme.dart';
import '../utils/sport_formatters.dart';
import '../utils/forecast_helpers.dart';

/// Layer 1: Sticky decision summary header
/// Shows "Right now in [Location] → [Sport] → [Label]"
class DecisionSummary extends StatelessWidget {
  final String? locationName;
  final List<HourlyForecast> forecasts;
  final Map<String, bool> selectedSports;
  final bool onlyRecommended;

  const DecisionSummary({
    super.key,
    required this.locationName,
    required this.forecasts,
    required this.selectedSports,
    required this.onlyRecommended,
  });

  @override
  Widget build(BuildContext context) {
    // Find current hour or next hour
    final now = DateTime.now();
    HourlyForecast? currentHour;
    
    for (var forecast in forecasts) {
      final forecastTime = DateTime.parse(forecast.date);
      if (forecastTime.isAfter(now.subtract(const Duration(hours: 1)))) {
        currentHour = forecast;
        break;
      }
    }
    
    if (currentHour == null && forecasts.isNotEmpty) {
      currentHour = forecasts.first;
    }

    if (currentHour == null) {
      return const SizedBox.shrink();
    }

    // Find best sport for this hour
    final availableSports = currentHour.sports.entries
        .where((e) => selectedSports[e.key] == true)
        .where((e) => !onlyRecommended || ForecastHelpers.isRecommended(e.value.label))
        .toList();
    
    if (availableSports.isEmpty) {
      return const SizedBox.shrink();
    }

    // Sort by score, pick best
    availableSports.sort((a, b) => b.value.score.compareTo(a.value.score));
    final bestSport = availableSports.first.value;
    
    // Find best window for this sport
    final bestHours = ForecastHelpers.getBestHoursBySport(
      forecasts,
      {bestSport.sport: true},
      onlyRecommended,
    )[bestSport.sport] ?? [];
    
    final bestWindow = bestHours.isNotEmpty
        ? ForecastHelpers.getBestWindow(bestHours)
        : null;

    // Get micro-stats
    final sportContext = bestSport.context;
    final waveHeight = sportContext['wave_height_m'] as double?;
    final wavePeriod = sportContext['wave_period_s'] as double?;
    final windWaveHeight = sportContext['wind_wave_height_m'] as double?;
    final waterTemp = sportContext['water_temp_c'] as double?;
    
    String chopLabel = 'Calm';
    if (windWaveHeight != null) {
      if (windWaveHeight < 0.15) {
        chopLabel = 'Calm';
      } else if (windWaveHeight < 0.3) {
        chopLabel = 'Light chop';
      } else if (windWaveHeight < 0.5) {
        chopLabel = 'Moderate chop';
      } else {
        chopLabel = 'Choppy';
      }
    }

    final statusColor = AppTheme.getStatusColor(bestSport.label);
    final sportName = SportFormatters.getSportName(bestSport.sport);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color: AppTheme.sand.withOpacity(0.5), // Light sand background
        border: Border(
          bottom: BorderSide(
            color: AppTheme.slateGray.withOpacity(0.1),
            width: 1,
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Main decision line (wraps on mobile)
          Row(
            children: [
              Flexible(
                child: Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Text(
                      'Right now in ',
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        color: AppTheme.slateGray.withOpacity(0.7),
                      ),
                    ),
                    Text(
                      locationName ?? 'Unknown',
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.oceanDeep,
                      ),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    ),
                    Text(
                      '→',
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        color: AppTheme.slateGray.withOpacity(0.4),
                      ),
                    ),
                    Text(
                      sportName,
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.oceanDeep,
                      ),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  bestSport.label.toUpperCase(),
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: statusColor,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ],
          ),
          
          // Best window
          if (bestWindow != null) ...[
            const SizedBox(height: 10),
            Row(
              children: [
                Icon(
                  Icons.access_time,
                  size: 13,
                  color: AppTheme.slateGray.withOpacity(0.6),
                ),
                const SizedBox(width: 6),
                Flexible(
                  child: Text(
                    'Best window: $bestWindow',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: AppTheme.slateGray.withOpacity(0.7),
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ],
          
          // Micro-stats
          const SizedBox(height: 10),
          Wrap(
            spacing: 12,
            runSpacing: 4,
            children: [
              if (waveHeight != null && wavePeriod != null)
                _MicroStat(
                  '${waveHeight.toStringAsFixed(1)}m @ ${wavePeriod.toStringAsFixed(1)}s',
                ),
              if (chopLabel != 'Calm')
                _MicroStat(chopLabel),
              if (waterTemp != null)
                _MicroStat('${waterTemp.toStringAsFixed(0)}°C'),
            ],
          ),
        ],
      ),
    );
  }
}

class _MicroStat extends StatelessWidget {
  final String text;

  const _MicroStat(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: GoogleFonts.inter(
        fontSize: 11,
        color: AppTheme.slateGray.withOpacity(0.7),
        fontWeight: FontWeight.w400,
      ),
    );
  }
}
