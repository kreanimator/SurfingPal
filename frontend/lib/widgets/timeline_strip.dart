import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../models/forecast_data.dart';
import '../theme/app_theme.dart';
import '../utils/forecast_helpers.dart';
import '../utils/sport_formatters.dart';

/// Layer 2: Horizontal scrollable timeline strip
/// Mode A: Single sport → single timeline
/// Mode B: Multiple sports → stacked sport rows
class TimelineStrip extends StatefulWidget {
  final List<HourlyForecast> forecasts;
  final Map<String, bool> selectedSports;
  final bool onlyRecommended;
  final String? selectedHour;
  final String? selectedSport; // Selected sport for expansion
  final ValueChanged<String> onHourSelected; // (hourDate)
  final ValueChanged<String> onSportHourSelected; // (sport|hourDate) for multi-sport mode
  final ValueChanged<String>? onSportNameTapped; // (sport) to filter to that sport

  const TimelineStrip({
    super.key,
    required this.forecasts,
    required this.selectedSports,
    required this.onlyRecommended,
    this.selectedHour,
    this.selectedSport,
    required this.onHourSelected,
    required this.onSportHourSelected,
    this.onSportNameTapped,
  });

  @override
  State<TimelineStrip> createState() => _TimelineStripState();
}

class _TimelineStripState extends State<TimelineStrip> {
  final ScrollController _scrollController = ScrollController();

  int get _selectedSportCount {
    return widget.selectedSports.values.where((v) => v == true).length;
  }

  bool get _isMultiSportMode => _selectedSportCount > 1;

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.forecasts.isEmpty) return const SizedBox.shrink();

    if (_isMultiSportMode) {
      return _buildMultiSportTimeline();
    } else {
      return _buildSingleSportTimeline();
    }
  }

  /// Mode A: Single sport timeline
  Widget _buildSingleSportTimeline() {
    final sport = widget.selectedSports.entries.firstWhere((e) => e.value == true).key;

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        color: AppTheme.white.withOpacity(0.7),
      ),
      child: SingleChildScrollView(
        controller: _scrollController,
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Row(
          children: widget.forecasts.map((hourly) {
            final isSelected = widget.selectedHour == hourly.date;
            final sportForecast = hourly.sports[sport];
            
            if (sportForecast == null) {
              return _TimelineHour(
                time: DateFormat('HH').format(DateTime.parse(hourly.date)),
                status: null,
                isSelected: isSelected,
                onTap: () => widget.onHourSelected(hourly.date),
              );
            }

            if (widget.onlyRecommended && !ForecastHelpers.isRecommended(sportForecast.label)) {
              return _TimelineHour(
                time: DateFormat('HH').format(DateTime.parse(hourly.date)),
                status: null,
                isSelected: isSelected,
                onTap: () => widget.onHourSelected(hourly.date),
              );
            }

            final statusColor = AppTheme.getStatusColor(sportForecast.label);

            return _TimelineHour(
              time: DateFormat('HH').format(DateTime.parse(hourly.date)),
              status: sportForecast.label.toLowerCase(),
              statusColor: statusColor,
              isSelected: isSelected,
              onTap: () => widget.onHourSelected(hourly.date),
            );
          }).toList(),
        ),
      ),
    );
  }

  /// Mode B: Multi-sport timeline (stacked rows)
  Widget _buildMultiSportTimeline() {
    final sports = widget.selectedSports.entries
        .where((e) => e.value == true)
        .map((e) => e.key)
        .toList();

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        color: AppTheme.white.withOpacity(0.7),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Legend (tiny, once)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            child: Row(
              children: [
                _LegendItem('Great', AppTheme.seafoamGreen),
                const SizedBox(width: 12),
                _LegendItem('OK', AppTheme.okYellow),
                const SizedBox(width: 12),
                _LegendItem('Bad', AppTheme.coralAccent),
              ],
            ),
          ),
          const Divider(height: 1),
          // Sport rows (fixed sport name + scrollable cells)
          ...sports.map((sport) {
            return _SportTimelineRow(
              sport: sport,
              forecasts: widget.forecasts,
              onlyRecommended: widget.onlyRecommended,
              selectedHour: widget.selectedHour,
              selectedSport: widget.selectedSport,
              scrollController: _scrollController,
              onCellTap: (hourDate) => widget.onSportHourSelected('$sport|$hourDate'),
              onSportNameTap: () => widget.onSportNameTapped?.call(sport),
            );
          }),
        ],
      ),
    );
  }
}

class _SportTimelineRow extends StatelessWidget {
  final String sport;
  final List<HourlyForecast> forecasts;
  final bool onlyRecommended;
  final String? selectedHour;
  final String? selectedSport;
  final ScrollController scrollController;
  final ValueChanged<String> onCellTap;
  final VoidCallback? onSportNameTap;

  const _SportTimelineRow({
    required this.sport,
    required this.forecasts,
    required this.onlyRecommended,
    this.selectedHour,
    this.selectedSport,
    required this.scrollController,
    required this.onCellTap,
    this.onSportNameTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 6),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: AppTheme.slateGray.withOpacity(0.05),
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          // Sport name (fixed, not scrollable, clickable to filter)
          GestureDetector(
            onTap: onSportNameTap,
            child: Container(
              width: 80,
              padding: const EdgeInsets.only(left: 16, right: 12),
              child: Text(
                SportFormatters.getSportName(sport),
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.oceanDeep,
                ),
              ),
            ),
          ),
          // Timeline cells (scrollable, synchronized with hour labels)
          Expanded(
            child: SingleChildScrollView(
              controller: scrollController,
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.only(right: 16),
              child: Row(
                children: forecasts.map((hourly) {
                  final sportForecast = hourly.sports[sport];
                  final isSelected = selectedHour == hourly.date && selectedSport == sport;
                  
                  if (sportForecast == null) {
                    return _TimelineCell(
                      status: null,
                      isSelected: isSelected,
                      onTap: () => onCellTap(hourly.date),
                    );
                  }

                  if (onlyRecommended && !ForecastHelpers.isRecommended(sportForecast.label)) {
                    return _TimelineCell(
                      status: null,
                      isSelected: isSelected,
                      onTap: () => onCellTap(hourly.date),
                    );
                  }

                  final statusColor = AppTheme.getStatusColor(sportForecast.label);
                  final status = sportForecast.label.toLowerCase();

                  return _TimelineCell(
                    status: status,
                    statusColor: statusColor,
                    isSelected: isSelected,
                    onTap: () => onCellTap(hourly.date),
                    tooltip: _buildTooltip(sportForecast, hourly.date),
                  );
                }).toList(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _buildTooltip(SportForecast sport, String hourDate) {
    final time = DateFormat('HH:mm').format(DateTime.parse(hourDate));
    final parts = <String>[];
    
    final waveHeight = sport.context['wave_height_m'] as double?;
    final wavePeriod = sport.context['wave_period_s'] as double?;
    if (waveHeight != null && wavePeriod != null) {
      parts.add('${waveHeight.toStringAsFixed(1)}m @ ${wavePeriod.toStringAsFixed(1)}s');
    }
    
    final current = sport.context['current_kmh'] as double?;
    if (current != null && current > 2) {
      parts.add('Current ${current.toStringAsFixed(1)} km/h');
    }
    
    final temp = sport.context['water_temp_c'] as double?;
    if (temp != null) {
      parts.add('${temp.toStringAsFixed(0)}°C');
    }

    return '$time: ${parts.join(' • ')}';
  }
}

/// Timeline cell (color only, no labels)
class _TimelineCell extends StatelessWidget {
  final String? status; // 'great', 'ok', 'marginal', 'bad'
  final Color? statusColor;
  final bool isSelected;
  final VoidCallback onTap;
  final String? tooltip;

  const _TimelineCell({
    this.status,
    this.statusColor,
    required this.isSelected,
    required this.onTap,
    this.tooltip,
  });

  @override
  Widget build(BuildContext context) {
    final color = statusColor ?? AppTheme.slateGray.withOpacity(0.2);
    final height = status == 'great' ? 24.0 
        : status == 'ok' ? 20.0 
        : status == 'marginal' ? 16.0 
        : 12.0;

    Widget cell = GestureDetector(
      onTap: onTap,
      onLongPress: tooltip != null
          ? () {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(tooltip!),
                  duration: const Duration(seconds: 2),
                  backgroundColor: AppTheme.oceanDeep,
                ),
              );
            }
          : null,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 1),
        width: 26,
        height: height,
        decoration: BoxDecoration(
          color: isSelected ? color : color.withOpacity(0.7),
          borderRadius: BorderRadius.circular(3),
          border: isSelected
              ? Border.all(color: color, width: 2)
              : null,
        ),
      ),
    );

    if (tooltip != null) {
      return Tooltip(
        message: tooltip!,
        child: cell,
      );
    }

    return cell;
  }
}

/// Single sport timeline hour (color only, no labels)
class _TimelineHour extends StatelessWidget {
  final String time;
  final String? status; // 'great', 'ok', 'marginal', 'bad'
  final Color? statusColor;
  final bool isSelected;
  final VoidCallback onTap;

  const _TimelineHour({
    required this.time,
    this.status,
    this.statusColor,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = statusColor ?? AppTheme.slateGray.withOpacity(0.3);
    final height = status == 'great' ? 28.0 
        : status == 'ok' ? 22.0 
        : status == 'marginal' ? 18.0 
        : 14.0;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 2),
        width: 36,
        height: height,
        alignment: Alignment.center,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          width: 28,
          height: height,
          decoration: BoxDecoration(
            color: isSelected ? color : color.withOpacity(0.7),
            borderRadius: BorderRadius.circular(3),
            border: isSelected
                ? Border.all(color: color, width: 2)
                : null,
          ),
        ),
      ),
    );
  }
}

/// Helper class for condition labels
class _ConditionLabel {
  final String text;
  final Color color;

  _ConditionLabel(this.text, this.color);
}

class _LegendItem extends StatelessWidget {
  final String label;
  final Color color;

  const _LegendItem(this.label, this.color);

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 9,
            color: AppTheme.slateGray.withOpacity(0.6),
          ),
        ),
      ],
    );
  }
}
