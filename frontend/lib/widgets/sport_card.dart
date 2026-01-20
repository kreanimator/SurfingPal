import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/forecast_data.dart';
import '../theme/app_theme.dart';
import '../utils/sport_formatters.dart';
import '../utils/forecast_helpers.dart';
import 'sport_card_helpers.dart';

class SportCard extends StatelessWidget {
  final SportForecast sport;
  final String hourDate;
  final HourlyForecast? hourlyForecast; // For finding better alternatives
  final bool isHero;
  final bool isExpanded;
  final VoidCallback? onToggleExpanded;

  const SportCard({
    super.key,
    required this.sport,
    required this.hourDate,
    this.hourlyForecast,
    this.isHero = false,
    this.isExpanded = false,
    this.onToggleExpanded,
  });

  @override
  Widget build(BuildContext context) {
    final statusColor = AppTheme.getStatusColor(sport.label);
    final isBad = sport.label.toLowerCase() == 'bad';
    
    if (isBad) {
      return _BadSportCard(
        sport: sport,
        statusColor: statusColor,
        hourlyForecast: hourlyForecast,
      );
    } else if (isHero) {
      return _HeroSportCard(sport: sport, statusColor: statusColor);
    } else {
      return _AccordionSportCard(
        sport: sport,
        hourDate: hourDate,
        statusColor: statusColor,
        isExpanded: isExpanded,
        onToggleExpanded: onToggleExpanded,
      );
    }
  }
}

class _HeroSportCard extends StatelessWidget {
  final SportForecast sport;
  final Color statusColor;

  const _HeroSportCard({
    required this.sport,
    required this.statusColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.white,
        borderRadius: BorderRadius.circular(12),
        border: Border(left: BorderSide(color: statusColor, width: 4)),
        boxShadow: [
          BoxShadow(
            color: statusColor.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                sport.sportDisplayName,
                    style: GoogleFonts.inter(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.slateGray,
                    ),
              ),
              StatusBadge(
                label: sport.label,
                statusColor: statusColor,
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            SportFormatters.buildHeroLine(sport),
            style: GoogleFonts.inter(
              fontSize: 12,
              color: AppTheme.slateGray.withOpacity(0.7),
            ),
          ),
          // Condition labels only - displayed in order: green → yellow → red
          ...ConditionLabelsBuilder.build(sport),
          
          // Tips: max 2-3, categorize silently (no label)
          ...TipsBuilder.build(sport.tips),
        ],
      ),
    );
  }
}

class _AccordionSportCard extends StatelessWidget {
  final SportForecast sport;
  final String hourDate;
  final Color statusColor;
  final bool isExpanded;
  final VoidCallback? onToggleExpanded;

  const _AccordionSportCard({
    required this.sport,
    required this.hourDate,
    required this.statusColor,
    required this.isExpanded,
    this.onToggleExpanded,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.white,
        borderRadius: BorderRadius.circular(8),
        border: Border(
          left: BorderSide(color: statusColor.withOpacity(0.5), width: 2),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          InkWell(
            onTap: () {
              onToggleExpanded?.call();
              if (!isExpanded) {
                Future.delayed(const Duration(milliseconds: 100), () {
                  Scrollable.ensureVisible(
                    context,
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeInOut,
                  );
                });
              }
            },
            borderRadius: BorderRadius.circular(8),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Row(
                      children: [
                        // Score ring (small badge)
                        Container(
                          width: 20,
                          height: 20,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(color: statusColor.withOpacity(0.5), width: 1.5),
                          ),
                          child: Center(
                            child: Text(
                              (sport.score * 100).toStringAsFixed(0),
                              style: GoogleFonts.inter(
                                fontSize: 8,
                                fontWeight: FontWeight.bold,
                                color: statusColor,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Flexible(
                          child: Text(
                            sport.sportDisplayName,
                            style: GoogleFonts.inter(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: AppTheme.slateGray,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 8),
                        // Label pill (show label first)
                        StatusBadge(
                          label: sport.label,
                          statusColor: statusColor,
                          dotSize: 4,
                          fontSize: 9,
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    isExpanded ? Icons.expand_less : Icons.expand_more,
                    size: 20,
                    color: AppTheme.slateGray.withOpacity(0.5),
                  ),
                ],
              ),
            ),
          ),
          if (isExpanded) ...[
            Divider(height: 1, color: AppTheme.slateGray.withOpacity(0.1)),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    SportFormatters.buildHeroLine(sport),
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: AppTheme.slateGray.withOpacity(0.7),
                    ),
                  ),
                  // Condition labels only - displayed in order: green → yellow → red
                  ...ConditionLabelsBuilder.build(sport),
                  // Tips: max 2-3, categorize silently
                  ...TipsBuilder.build(sport.tips),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

}

class _BadSportCard extends StatelessWidget {
  final SportForecast sport;
  final Color statusColor;
  final HourlyForecast? hourlyForecast;

  const _BadSportCard({
    required this.sport,
    required this.statusColor,
    this.hourlyForecast,
  });

  @override
  Widget build(BuildContext context) {
    // Find better alternatives
    final betterAlternatives = hourlyForecast != null
        ? ForecastHelpers.findBetterAlternatives(hourlyForecast!, sport.sport)
        : <String>[];

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.sand.withOpacity(0.3), // Muted background for bad sports
        borderRadius: BorderRadius.circular(8),
        border: Border(
          left: BorderSide(color: AppTheme.coralAccent.withOpacity(0.2), width: 2),
        ),
      ),
      child: Builder(
        builder: (context) {
          // "Caution" section - display red condition labels
          final redLabels = sport.conditionLabels['red'] ?? [];
          
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Row(
                      children: [
                        Text(
                          sport.sportDisplayName,
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color: AppTheme.slateGray.withOpacity(0.6), // Muted text
                          ),
                        ),
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppTheme.coralAccent.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            'BAD',
                            style: GoogleFonts.inter(
                              fontSize: 8,
                              fontWeight: FontWeight.w700,
                              color: AppTheme.coralAccent.withOpacity(0.7),
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              
              // "Caution" section - display red condition labels
              if (redLabels.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  'Caution',
                  style: GoogleFonts.inter(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.coralAccent,
                  ),
                ),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: redLabels.map<Widget>((label) => ConditionLabelChip(
                    label: label,
                    color: AppTheme.coralAccent,
                    isGood: false,
                  )).toList(),
                ),
              ],
          
          // Better alternatives
          if (betterAlternatives.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              'Better for:',
              style: GoogleFonts.inter(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: AppTheme.seafoamGreen.withOpacity(0.7),
              ),
            ),
            const SizedBox(height: 4),
            Wrap(
              spacing: 6,
              children: betterAlternatives.map((alt) {
                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppTheme.seafoamGreen.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    '→ ${SportFormatters.getSportName(alt)}',
                    style: GoogleFonts.inter(
                      fontSize: 10,
                      color: AppTheme.seafoamGreen,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
            ],
          );
        },
      ),
    );
  }
}
