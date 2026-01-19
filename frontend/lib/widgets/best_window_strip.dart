import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../theme/app_theme.dart';
import '../models/forecast_data.dart';
import '../utils/sport_formatters.dart';

class BestWindowStrip extends StatelessWidget {
  final List<String> availableSports;
  final Map<String, bool> selectedSports;
  final Map<String, List<MapEntry<String, SportForecast>>> bestHoursBySport;

  const BestWindowStrip({
    super.key,
    required this.availableSports,
    required this.selectedSports,
    required this.bestHoursBySport,
  });

  @override
  Widget build(BuildContext context) {
    final bestWindows = <String, MapEntry<String, String>>{};
    
    for (var sport in availableSports) {
      if (selectedSports[sport] != true) continue;
      final bestHours = bestHoursBySport[sport];
      if (bestHours == null || bestHours.isEmpty) {
        bestWindows[sport] = const MapEntry('—', 'Bad');
      } else {
        final times = bestHours.map((e) {
          return DateFormat('HH:mm').format(DateTime.parse(e.key));
        }).toList();
        final label = bestHours.first.value.label;
        bestWindows[sport] = MapEntry(times.join('–'), label.capitalize());
      }
    }

    if (bestWindows.isEmpty) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      padding: const EdgeInsets.symmetric(vertical: 16),
      decoration: BoxDecoration(
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
          Text(
            'Best windows today',
            style: GoogleFonts.poppins(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: AppTheme.slateGray.withOpacity(0.5),
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 12),
          ...bestWindows.entries.map((entry) {
            final statusColor = _getStatusDotColor(entry.value.value);
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: [
                  SizedBox(
                    width: 60,
                    child: Text(
                      SportFormatters.getSportName(entry.key),
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: AppTheme.slateGray,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      entry.value.key,
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: AppTheme.slateGray.withOpacity(0.7),
                      ),
                    ),
                  ),
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: statusColor,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    entry.value.value,
                    style: GoogleFonts.poppins(
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      color: statusColor,
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Color _getStatusDotColor(String label) {
    switch (label.toLowerCase()) {
      case 'great':
        return AppTheme.seafoamGreen;
      case 'ok':
      case 'good':
        return AppTheme.okYellow;
      case 'marginal':
        return AppTheme.marginalOrange;
      case 'bad':
        return AppTheme.coral;
      default:
        return AppTheme.slateGray;
    }
  }
}

extension StringExtension on String {
  String capitalize() {
    if (isEmpty) return this;
    return '${this[0].toUpperCase()}${substring(1)}';
  }
}
