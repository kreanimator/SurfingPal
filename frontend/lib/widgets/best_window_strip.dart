import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../theme/app_theme.dart';
import '../models/forecast_data.dart';
import '../utils/sport_formatters.dart';
import '../utils/forecast_helpers.dart';

class BestWindowStrip extends StatelessWidget {
  final List<String> availableSports;
  final Map<String, bool> selectedSports;
  final Map<String, List<MapEntry<String, SportForecast>>> bestHoursBySport;
  final ValueChanged<String>? onSportWindowTap; // (sport|hourDate) to jump to timeline

  const BestWindowStrip({
    super.key,
    required this.availableSports,
    required this.selectedSports,
    required this.bestHoursBySport,
    this.onSportWindowTap,
  });

  int get _selectedSportCount {
    return selectedSports.values.where((v) => v == true).length;
  }

  bool get _isMultiSportMode => _selectedSportCount > 1;

  @override
  Widget build(BuildContext context) {
    final bestWindows = <String, MapEntry<String, String>>{};
    
    for (var sport in availableSports) {
      if (selectedSports[sport] != true) continue;
      final bestHours = bestHoursBySport[sport];
      if (bestHours == null || bestHours.isEmpty) {
        bestWindows[sport] = const MapEntry('none today', 'Bad');
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
            _isMultiSportMode ? 'Best times by sport' : 'Best window today',
            style: GoogleFonts.inter(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: AppTheme.slateGray.withOpacity(0.5),
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 12),
          ...bestWindows.entries.map((entry) {
            final statusColor = _getStatusDotColor(entry.value.value);
            final hasWindow = entry.value.key != 'none today';
            
            return InkWell(
              onTap: hasWindow && onSportWindowTap != null
                  ? () {
                      // Jump to first best hour for this sport
                      final bestHours = bestHoursBySport[entry.key];
                      if (bestHours != null && bestHours.isNotEmpty) {
                        onSportWindowTap!('${entry.key}|${bestHours.first.key}');
                      }
                    }
                  : null,
              borderRadius: BorderRadius.circular(8),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
                child: Row(
                  children: [
                    SizedBox(
                      width: 70,
                      child: Text(
                        SportFormatters.getSportName(entry.key),
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: hasWindow && onSportWindowTap != null
                              ? AppTheme.oceanDeep
                              : AppTheme.slateGray,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        entry.value.key,
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          color: hasWindow
                              ? AppTheme.slateGray.withOpacity(0.7)
                              : AppTheme.slateGray.withOpacity(0.4),
                          fontStyle: hasWindow ? FontStyle.normal : FontStyle.italic,
                        ),
                      ),
                    ),
                    if (hasWindow) ...[
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
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                          color: statusColor,
                        ),
                      ),
                    ],
                    if (hasWindow && onSportWindowTap != null) ...[
                      const SizedBox(width: 8),
                      Icon(
                        Icons.arrow_forward_ios,
                        size: 12,
                        color: AppTheme.oceanDeep.withOpacity(0.5),
                      ),
                    ],
                  ],
                ),
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
        return AppTheme.coralAccent;
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
