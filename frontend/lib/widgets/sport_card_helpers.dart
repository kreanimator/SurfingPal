import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/forecast_data.dart';
import '../theme/app_theme.dart';
import '../utils/sport_formatters.dart';

/// Reusable condition label chip widget
class ConditionLabelChip extends StatelessWidget {
  final String label;
  final Color color;
  final bool isGood;

  const ConditionLabelChip({
    super.key,
    required this.label,
    required this.color,
    this.isGood = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isGood ? Icons.check : Icons.close,
            size: 12,
            color: AppTheme.white,
          ),
          const SizedBox(width: 4),
          Text(
            SportFormatters.normalizeConditionLabel(label),
            style: GoogleFonts.inter(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: AppTheme.white,
              letterSpacing: 0.3,
            ),
          ),
        ],
      ),
    );
  }
}

/// Reusable tip item widget
class TipItem extends StatelessWidget {
  final Tip tip;

  const TipItem({super.key, required this.tip});

  @override
  Widget build(BuildContext context) {
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
  }

  static String _getTipIcon(String icon) {
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

/// Reusable status badge widget
class StatusBadge extends StatelessWidget {
  final String label;
  final Color statusColor;
  final double dotSize;
  final double fontSize;
  final EdgeInsets padding;

  const StatusBadge({
    super.key,
    required this.label,
    required this.statusColor,
    this.dotSize = 6,
    this.fontSize = 11,
    this.padding = const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: statusColor.withOpacity(0.15),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: dotSize,
            height: dotSize,
            decoration: BoxDecoration(
              color: statusColor,
              shape: BoxShape.circle,
            ),
          ),
          SizedBox(width: dotSize),
          Text(
            label.toUpperCase(),
            style: GoogleFonts.inter(
              fontSize: fontSize,
              fontWeight: FontWeight.w700,
              color: statusColor,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }
}

/// Helper class for building condition labels
class ConditionLabelsBuilder {
  /// Builds condition labels in order: green → yellow → red
  static List<Widget> build(SportForecast sport) {
    final labels = <Widget>[];
    final conditionLabels = sport.conditionLabels;
    
    if (conditionLabels.isEmpty) {
      return labels;
    }
    
    final greenLabels = conditionLabels['green'] ?? [];
    final yellowLabels = conditionLabels['yellow'] ?? [];
    final redLabels = conditionLabels['red'] ?? [];
    
    if (greenLabels.isNotEmpty) {
      labels.add(const SizedBox(height: 8));
      labels.add(
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: greenLabels.map<Widget>((label) => ConditionLabelChip(
            label: label,
            color: AppTheme.seafoamGreen.withOpacity(0.8),
            isGood: true,
          )).toList(),
        ),
      );
    }
    
    if (yellowLabels.isNotEmpty) {
      labels.add(SizedBox(height: greenLabels.isNotEmpty ? 6 : 8));
      labels.add(
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: yellowLabels.map<Widget>((label) => ConditionLabelChip(
            label: label,
            color: AppTheme.okYellow,
            isGood: false,
          )).toList(),
        ),
      );
    }
    
    if (redLabels.isNotEmpty) {
      labels.add(SizedBox(height: (greenLabels.isNotEmpty || yellowLabels.isNotEmpty) ? 6 : 8));
      labels.add(
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: redLabels.map<Widget>((label) => ConditionLabelChip(
            label: label,
            color: AppTheme.coralAccent,
            isGood: false,
          )).toList(),
        ),
      );
    }
    
    return labels;
  }
}

/// Helper class for building tips section
class TipsBuilder {
  /// Builds tips list widget (max 3 tips with "show more" indicator)
  static List<Widget> build(List<Tip> tips) {
    if (tips.isEmpty) {
      return [];
    }
    
    return [
      const SizedBox(height: 12),
      ...tips.take(3).map((tip) => TipItem(tip: tip)),
      if (tips.length > 3) ...[
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
    ];
  }
}
