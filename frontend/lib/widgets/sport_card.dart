import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/forecast_data.dart';
import '../theme/app_theme.dart';
import '../utils/sport_formatters.dart';

class SportCard extends StatelessWidget {
  final SportForecast sport;
  final String hourDate;
  final bool isHero;
  final bool isExpanded;
  final VoidCallback? onToggleExpanded;

  const SportCard({
    super.key,
    required this.sport,
    required this.hourDate,
    this.isHero = false,
    this.isExpanded = false,
    this.onToggleExpanded,
  });

  @override
  Widget build(BuildContext context) {
    final statusColor = AppTheme.getStatusColor(sport.label);
    final isBad = sport.label.toLowerCase() == 'bad';
    
    if (isBad) {
      return _BadSportCard(sport: sport, statusColor: statusColor);
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
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.slateGray,
                ),
              ),
              Row(
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: statusColor, width: 2),
                    ),
                    child: Center(
                      child: Text(
                        (sport.score * 100).toStringAsFixed(0),
                        style: GoogleFonts.poppins(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: statusColor,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      sport.label.toUpperCase(),
                      style: GoogleFonts.poppins(
                        fontSize: 9,
                        fontWeight: FontWeight.bold,
                        color: statusColor,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            SportFormatters.buildHeroLine(sport),
            style: GoogleFonts.poppins(
              fontSize: 12,
              color: AppTheme.slateGray.withOpacity(0.7),
            ),
          ),
          if (sport.reasons.isNotEmpty && sport.flags.isEmpty) ...[
            const SizedBox(height: 8),
            ...sport.reasons.take(2).map((reason) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Row(
                  children: [
                    Icon(Icons.check_circle, size: 14, color: AppTheme.seafoamGreen),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        reason,
                        style: GoogleFonts.poppins(
                          fontSize: 11,
                          color: AppTheme.slateGray.withOpacity(0.7),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }),
          ],
          if (sport.tips.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(
              'Tips',
              style: GoogleFonts.poppins(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: AppTheme.slateGray.withOpacity(0.6),
              ),
            ),
            const SizedBox(height: 6),
            ...sport.tips.map((tip) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _getTipIcon(tip.icon),
                      style: const TextStyle(fontSize: 16),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        tip.text,
                        style: GoogleFonts.poppins(
                          fontSize: 11,
                          color: AppTheme.slateGray.withOpacity(0.8),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }),
          ],
        ],
      ),
    );
  }

  String _getTipIcon(String icon) {
    switch (icon) {
      case 'wetsuit':
        return '🧥';
      case 'sun':
        return '☀️';
      case 'warning':
        return '⚠️';
      case 'waves':
        return '🌊';
      default:
        return 'ℹ️';
    }
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
                        Container(
                          width: 24,
                          height: 24,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(color: statusColor, width: 1.5),
                          ),
                          child: Center(
                            child: Text(
                              (sport.score * 100).toStringAsFixed(0),
                              style: GoogleFonts.poppins(
                                fontSize: 9,
                                fontWeight: FontWeight.bold,
                                color: statusColor,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Flexible(
                          child: Text(
                            sport.sportDisplayName,
                            style: GoogleFonts.poppins(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: AppTheme.slateGray,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                          decoration: BoxDecoration(
                            color: statusColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            sport.label.toUpperCase(),
                            style: GoogleFonts.poppins(
                              fontSize: 8,
                              fontWeight: FontWeight.bold,
                              color: statusColor,
                            ),
                          ),
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
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      color: AppTheme.slateGray.withOpacity(0.7),
                    ),
                  ),
                  if (sport.reasons.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    ...sport.reasons.map((reason) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 4),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(
                              Icons.check_circle,
                              size: 14,
                              color: AppTheme.seafoamGreen,
                            ),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                reason,
                                style: GoogleFonts.poppins(
                                  fontSize: 11,
                                  color: AppTheme.slateGray.withOpacity(0.7),
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    }),
                  ],
                  if (sport.tips.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    Text(
                      'Tips',
                      style: GoogleFonts.poppins(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.slateGray.withOpacity(0.6),
                      ),
                    ),
                    const SizedBox(height: 6),
                    ...sport.tips.map((tip) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 6),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _getTipIcon(tip.icon),
                              style: const TextStyle(fontSize: 16),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                tip.text,
                                style: GoogleFonts.poppins(
                                  fontSize: 11,
                                  color: AppTheme.slateGray.withOpacity(0.8),
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    }),
                  ] else ...[
                    const SizedBox(height: 12),
                    Text(
                      'No tips available',
                      style: GoogleFonts.poppins(
                        fontSize: 10,
                        color: AppTheme.slateGray.withOpacity(0.4),
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  String _getTipIcon(String icon) {
    switch (icon) {
      case 'wetsuit':
        return '🧥';
      case 'sun':
        return '☀️';
      case 'warning':
        return '⚠️';
      case 'waves':
        return '🌊';
      default:
        return 'ℹ️';
    }
  }
}

class _BadSportCard extends StatelessWidget {
  final SportForecast sport;
  final Color statusColor;

  const _BadSportCard({
    required this.sport,
    required this.statusColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.white,
        borderRadius: BorderRadius.circular(8),
        border: Border(
          left: BorderSide(color: AppTheme.coral.withOpacity(0.3), width: 2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(Icons.warning, size: 16, color: AppTheme.coral),
                  const SizedBox(width: 6),
                  Text(
                    sport.sportDisplayName,
                    style: GoogleFonts.poppins(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: AppTheme.slateGray,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                decoration: BoxDecoration(
                  color: AppTheme.coral.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'BAD',
                  style: GoogleFonts.poppins(
                    fontSize: 8,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.coral,
                  ),
                ),
              ),
            ],
          ),
          if (sport.reasons.isNotEmpty) ...[
            const SizedBox(height: 6),
            ...sport.reasons.take(1).map((reason) {
              return Text(
                '⚠ $reason',
                style: GoogleFonts.poppins(
                  fontSize: 11,
                  color: AppTheme.coral,
                  fontWeight: FontWeight.w500,
                ),
              );
            }),
          ],
        ],
      ),
    );
  }
}
