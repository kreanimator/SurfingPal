import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/forecast_data.dart';
import '../theme/app_theme.dart';
import '../utils/sport_formatters.dart';
import '../utils/forecast_helpers.dart';

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
              // Show label first, number only in expanded view
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      decoration: BoxDecoration(
                        color: statusColor,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      sport.label.toUpperCase(),
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: statusColor,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
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
          // Condition labels (good for Great, bad for Bad, both for OK)
          ..._buildConditionLabels(sport),
          
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
                        style: GoogleFonts.inter(
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
          // Tips: max 2-3, categorize silently (no label)
          if (sport.tips.isNotEmpty) ...[
            const SizedBox(height: 12),
            ...sport.tips.take(3).map((tip) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _getTipIcon(tip.icon),
                      style: const TextStyle(fontSize: 14),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        tip.text,
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          color: AppTheme.slateGray.withOpacity(0.7),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }),
            if (sport.tips.length > 3) ...[
              const SizedBox(height: 4),
              Text(
                'Show more tips',
                style: GoogleFonts.inter(
                  fontSize: 10,
                  color: AppTheme.oceanDeep.withOpacity(0.6),
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
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

  List<Widget> _buildConditionLabels(SportForecast sport) {
    final status = sport.label.toLowerCase();
    final context = sport.context;
    final labels = <Widget>[];
    
    // Get good and bad conditions
    final goodConditions = <_ConditionLabel>[];
    final badConditions = <_ConditionLabel>[];
    
    // Wave conditions (for wave sports)
    if (sport.sport == 'surfing' || sport.sport == 'sup_surf') {
      final waveHeight = context['wave_height_m'] as double?;
      final wavePeriod = context['wave_period_s'] as double?;
      
      if (waveHeight != null && wavePeriod != null) {
        if (waveHeight >= 0.5 && wavePeriod >= 6) {
          goodConditions.add(_ConditionLabel('Great Waves', AppTheme.seafoamGreen));
        } else if (waveHeight >= 0.3 && wavePeriod >= 4) {
          goodConditions.add(_ConditionLabel('Good Waves', AppTheme.seafoamGreen.withOpacity(0.8)));
        } else if (status == 'ok' || status == 'marginal') {
          // For OK status, show why waves aren't great
          if (waveHeight < 0.3 || wavePeriod < 4) {
            badConditions.add(_ConditionLabel('Small Waves', AppTheme.okYellow));
          }
        }
      }
      
      // Chop (wind waves) - bad condition
      final windWaveHeight = context['wind_wave_height_m'] as double?;
      if (windWaveHeight != null) {
        if (windWaveHeight >= 0.5) {
          badConditions.add(_ConditionLabel('Chop', AppTheme.coralAccent));
        } else if (windWaveHeight >= 0.3) {
          badConditions.add(_ConditionLabel('Chop', AppTheme.okYellow));
        } else if (windWaveHeight >= 0.15 && (status == 'ok' || status == 'marginal')) {
          // Show moderate chop for OK status (explains why not Great)
          badConditions.add(_ConditionLabel('Chop', AppTheme.okYellow.withOpacity(0.7)));
        }
      }
    }
    
    // Current conditions (important for SUP, SUP Surf)
    if (sport.sport == 'sup' || sport.sport == 'sup_surf') {
      final current = context['current_kmh'] as double?;
      if (current != null) {
        if (current >= 5) {
          badConditions.add(_ConditionLabel('Strong Current', AppTheme.coralAccent));
        } else if (current >= 3) {
          badConditions.add(_ConditionLabel('Current', AppTheme.okYellow));
        } else if (current <= 3 && status == 'great') {
          // Mild current is good for SUP
          goodConditions.add(_ConditionLabel('Mild Current', AppTheme.seafoamGreen.withOpacity(0.8)));
        }
      }
    }
    
    // Wind conditions (for wind sports)
    // Use wind_wave_height as proxy for wind (as backend does - ideal 0.4-1.2m)
    if (sport.sport == 'windsurfing' || sport.sport == 'kitesurfing') {
      final windSpeed = context['wind_speed_kmh'] as double?;
      final windWaveHeight = context['wind_wave_height_m'] as double?;
      
      // Prefer wind_speed if available, otherwise use wind_wave_height as proxy
      if (windSpeed != null) {
        if (windSpeed >= 25) {
          goodConditions.add(_ConditionLabel('Strong Wind', AppTheme.seafoamGreen));
        } else if (windSpeed >= 15) {
          goodConditions.add(_ConditionLabel('Good Wind', AppTheme.seafoamGreen.withOpacity(0.8)));
        } else if (windSpeed >= 10 && windSpeed < 15) {
          // Moderate wind - OK but not great
          if (status == 'ok' || status == 'marginal') {
            badConditions.add(_ConditionLabel('Light Wind', AppTheme.okYellow));
          }
        } else if (windSpeed < 10) {
          badConditions.add(_ConditionLabel('No Wind', AppTheme.coralAccent));
        }
      } else if (windWaveHeight != null) {
        // Use wind_wave_height as proxy (backend logic: ideal 0.4-1.2m, min 0.25m)
        if (windWaveHeight >= 0.4 && windWaveHeight <= 1.2) {
          goodConditions.add(_ConditionLabel('Good Wind', AppTheme.seafoamGreen));
        } else if (windWaveHeight >= 0.25 && windWaveHeight < 0.4) {
          // Moderate wind - OK but not great (show why it's not Great)
          if (status == 'ok' || status == 'marginal') {
            badConditions.add(_ConditionLabel('Light Wind', AppTheme.okYellow));
          }
        } else if (windWaveHeight < 0.25) {
          badConditions.add(_ConditionLabel('No Wind', AppTheme.coralAccent));
        }
      }
    }
    
    // Current for all sports (show as positive when mild)
    final current = context['current_kmh'] as double?;
    if (current != null && current <= 3.0) {
      // Only add if not already handled by SUP-specific logic above
      if (sport.sport != 'sup' && sport.sport != 'sup_surf') {
        if (status == 'great' || status == 'ok' || status == 'marginal') {
          goodConditions.add(_ConditionLabel('Mild Current', AppTheme.seafoamGreen.withOpacity(0.8)));
        }
      }
    }
    
    // Display based on status
    if (status == 'ok' || status == 'marginal') {
      // Show both good and bad for OK/Marginal
      if (goodConditions.isNotEmpty) {
        labels.add(const SizedBox(height: 8));
        labels.add(
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: goodConditions.map<Widget>((label) => _buildLabelChip(label)).toList(),
          ),
        );
      }
      if (badConditions.isNotEmpty) {
        labels.add(const SizedBox(height: 6));
        labels.add(
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: badConditions.map<Widget>((label) => _buildLabelChip(label)).toList(),
          ),
        );
      }
    } else if (status == 'great') {
      // Show only good conditions
      if (goodConditions.isNotEmpty) {
        labels.add(const SizedBox(height: 8));
        labels.add(
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: goodConditions.map<Widget>((label) => _buildLabelChip(label)).toList(),
          ),
        );
      }
    } else if (status == 'bad') {
      // Show only bad conditions
      if (badConditions.isNotEmpty) {
        labels.add(const SizedBox(height: 8));
        labels.add(
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: badConditions.map<Widget>((label) => _buildLabelChip(label)).toList(),
          ),
        );
      }
    }
    
    return labels;
  }

  Widget _buildLabelChip(_ConditionLabel label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: label.color,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        label.text,
        style: GoogleFonts.inter(
          fontSize: 10,
          fontWeight: FontWeight.w600,
          color: AppTheme.white,
          letterSpacing: 0.3,
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
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                          decoration: BoxDecoration(
                            color: statusColor.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 4,
                                height: 4,
                                decoration: BoxDecoration(
                                  color: statusColor,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 4),
                              Text(
                                sport.label.toUpperCase(),
                                style: GoogleFonts.inter(
                                  fontSize: 9,
                                  fontWeight: FontWeight.w700,
                                  color: statusColor,
                                  letterSpacing: 0.3,
                                ),
                              ),
                            ],
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
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: AppTheme.slateGray.withOpacity(0.7),
                    ),
                  ),
                  // Condition labels (good for Great, bad for Bad, both for OK)
                  ..._buildConditionLabels(sport),
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
                                style: GoogleFonts.inter(
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
                  // Tips: max 2-3, categorize silently
                  if (sport.tips.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    ...sport.tips.take(3).map((tip) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 6),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _getTipIcon(tip.icon),
                              style: const TextStyle(fontSize: 14),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                tip.text,
                                style: GoogleFonts.inter(
                                  fontSize: 11,
                                  color: AppTheme.slateGray.withOpacity(0.7),
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    }),
                    if (sport.tips.length > 3) ...[
                      const SizedBox(height: 4),
                      Text(
                        'Show more tips',
                        style: GoogleFonts.inter(
                          fontSize: 10,
                          color: AppTheme.oceanDeep.withOpacity(0.6),
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ],
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

  List<Widget> _buildConditionLabels(SportForecast sport) {
    final status = sport.label.toLowerCase();
    final context = sport.context;
    final labels = <Widget>[];
    
    // Get good and bad conditions
    final goodConditions = <_ConditionLabel>[];
    final badConditions = <_ConditionLabel>[];
    
    // Wave conditions (for wave sports)
    if (sport.sport == 'surfing' || sport.sport == 'sup_surf') {
      final waveHeight = context['wave_height_m'] as double?;
      final wavePeriod = context['wave_period_s'] as double?;
      
      if (waveHeight != null && wavePeriod != null) {
        if (waveHeight >= 0.5 && wavePeriod >= 6) {
          goodConditions.add(_ConditionLabel('Great Waves', AppTheme.seafoamGreen));
        } else if (waveHeight >= 0.3 && wavePeriod >= 4) {
          goodConditions.add(_ConditionLabel('Good Waves', AppTheme.seafoamGreen.withOpacity(0.8)));
        }
      }
      
      // Chop (wind waves) - bad condition
      final windWaveHeight = context['wind_wave_height_m'] as double?;
      if (windWaveHeight != null) {
        if (windWaveHeight >= 0.5) {
          badConditions.add(_ConditionLabel('Chop', AppTheme.coralAccent));
        } else if (windWaveHeight >= 0.3) {
          badConditions.add(_ConditionLabel('Chop', AppTheme.okYellow));
        } else if (windWaveHeight >= 0.15 && (status == 'ok' || status == 'marginal')) {
          // Show moderate chop for OK status (explains why not Great)
          badConditions.add(_ConditionLabel('Chop', AppTheme.okYellow.withOpacity(0.7)));
        }
      }
      
      // For OK status, show why waves aren't great
      if ((status == 'ok' || status == 'marginal') && waveHeight != null && wavePeriod != null) {
        if (waveHeight < 0.3 || wavePeriod < 4) {
          badConditions.add(_ConditionLabel('Small Waves', AppTheme.okYellow));
        }
      }
    }
    
    // Current conditions (important for SUP, SUP Surf)
    if (sport.sport == 'sup' || sport.sport == 'sup_surf') {
      final current = context['current_kmh'] as double?;
      if (current != null) {
        if (current >= 5) {
          badConditions.add(_ConditionLabel('Strong Current', AppTheme.coralAccent));
        } else if (current >= 3) {
          badConditions.add(_ConditionLabel('Current', AppTheme.okYellow));
        } else if (current <= 3 && status == 'great') {
          // Mild current is good for SUP
          goodConditions.add(_ConditionLabel('Mild Current', AppTheme.seafoamGreen.withOpacity(0.8)));
        }
      }
    }
    
    // Wind conditions (for wind sports)
    // Use wind_wave_height as proxy for wind (as backend does - ideal 0.4-1.2m)
    if (sport.sport == 'windsurfing' || sport.sport == 'kitesurfing') {
      final windSpeed = context['wind_speed_kmh'] as double?;
      final windWaveHeight = context['wind_wave_height_m'] as double?;
      
      // Prefer wind_speed if available, otherwise use wind_wave_height as proxy
      if (windSpeed != null) {
        if (windSpeed >= 25) {
          goodConditions.add(_ConditionLabel('Strong Wind', AppTheme.seafoamGreen));
        } else if (windSpeed >= 15) {
          goodConditions.add(_ConditionLabel('Good Wind', AppTheme.seafoamGreen.withOpacity(0.8)));
        } else if (windSpeed >= 10 && windSpeed < 15) {
          // Moderate wind - OK but not great
          if (status == 'ok' || status == 'marginal') {
            badConditions.add(_ConditionLabel('Light Wind', AppTheme.okYellow));
          }
        } else if (windSpeed < 10) {
          badConditions.add(_ConditionLabel('No Wind', AppTheme.coralAccent));
        }
      } else if (windWaveHeight != null) {
        // Use wind_wave_height as proxy (backend logic: ideal 0.4-1.2m, min 0.25m)
        if (windWaveHeight >= 0.4 && windWaveHeight <= 1.2) {
          goodConditions.add(_ConditionLabel('Good Wind', AppTheme.seafoamGreen));
        } else if (windWaveHeight >= 0.25 && windWaveHeight < 0.4) {
          // Moderate wind - OK but not great (show why it's not Great)
          if (status == 'ok' || status == 'marginal') {
            badConditions.add(_ConditionLabel('Light Wind', AppTheme.okYellow));
          }
        } else if (windWaveHeight < 0.25) {
          badConditions.add(_ConditionLabel('No Wind', AppTheme.coralAccent));
        }
      }
    }
    
    // Current for all sports (show as positive when mild)
    final current = context['current_kmh'] as double?;
    if (current != null && current <= 3.0) {
      // Only add if not already handled by SUP-specific logic above
      if (sport.sport != 'sup' && sport.sport != 'sup_surf') {
        if (status == 'great' || status == 'ok' || status == 'marginal') {
          goodConditions.add(_ConditionLabel('Mild Current', AppTheme.seafoamGreen.withOpacity(0.8)));
        }
      }
    }
    
    // Display based on status
    if (status == 'ok' || status == 'marginal') {
      // Show both good and bad for OK/Marginal
      if (goodConditions.isNotEmpty) {
        labels.add(const SizedBox(height: 8));
        labels.add(
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: goodConditions.map<Widget>((label) => _buildLabelChip(label)).toList(),
          ),
        );
      }
      if (badConditions.isNotEmpty) {
        labels.add(const SizedBox(height: 6));
        labels.add(
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: badConditions.map<Widget>((label) => _buildLabelChip(label)).toList(),
          ),
        );
      }
    } else if (status == 'great') {
      // Show only good conditions
      if (goodConditions.isNotEmpty) {
        labels.add(const SizedBox(height: 8));
        labels.add(
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: goodConditions.map<Widget>((label) => _buildLabelChip(label)).toList(),
          ),
        );
      }
    } else if (status == 'bad') {
      // Show only bad conditions
      if (badConditions.isNotEmpty) {
        labels.add(const SizedBox(height: 8));
        labels.add(
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: badConditions.map<Widget>((label) => _buildLabelChip(label)).toList(),
          ),
        );
      }
    }
    
    return labels;
  }

  Widget _buildLabelChip(_ConditionLabel label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: label.color,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        label.text,
        style: GoogleFonts.inter(
          fontSize: 10,
          fontWeight: FontWeight.w600,
          color: AppTheme.white,
          letterSpacing: 0.3,
        ),
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
      child: Column(
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
          
          // "Why is this bad?" section - use humanized reasons/flags, no duplicates
          if (sport.reasons.isNotEmpty || sport.flags.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              'Why:',
              style: GoogleFonts.inter(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: AppTheme.slateGray.withOpacity(0.5),
              ),
            ),
            const SizedBox(height: 4),
            ...SportFormatters.getHumanizedReasons(sport.reasons, sport.flags)
                .take(2)
                .map((item) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 3),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '•',
                      style: GoogleFonts.inter(
                        fontSize: 10,
                        color: AppTheme.coralAccent.withOpacity(0.6),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        item,
                        style: GoogleFonts.inter(
                          fontSize: 10,
                          color: AppTheme.slateGray.withOpacity(0.6),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }),
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
      ),
    );
  }
}
