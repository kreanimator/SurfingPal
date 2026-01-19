import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';
import '../utils/sport_formatters.dart';

class FiltersSection extends StatelessWidget {
  final List<String> availableSports;
  final Map<String, bool> selectedSports;
  final bool onlyRecommended;
  final ValueChanged<String> onSportToggled;
  final ValueChanged<bool> onOnlyRecommendedChanged;

  const FiltersSection({
    super.key,
    required this.availableSports,
    required this.selectedSports,
    required this.onlyRecommended,
    required this.onSportToggled,
    required this.onOnlyRecommendedChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      child: Row(
        children: [
          Text(
            'Show:',
            style: GoogleFonts.poppins(
              fontSize: 12,
              color: AppTheme.slateGray.withOpacity(0.7),
              fontWeight: FontWeight.w400,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: availableSports.map((sport) {
                final isSelected = selectedSports[sport] ?? false;
                return FilterChip(
                  label: Text(SportFormatters.getSportName(sport)),
                  selected: isSelected,
                  onSelected: (selected) => onSportToggled(sport),
                  selectedColor: AppTheme.sand,
                  checkmarkColor: AppTheme.oceanBlue,
                  labelStyle: GoogleFonts.poppins(
                    fontSize: 11,
                    fontWeight: FontWeight.w400,
                    color: isSelected ? AppTheme.oceanBlue : AppTheme.slateGray.withOpacity(0.7),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                );
              }).toList(),
            ),
          ),
          const SizedBox(width: 12),
          Row(
            children: [
              Text(
                'Only recommended',
                style: GoogleFonts.poppins(
                  fontSize: 11,
                  color: AppTheme.slateGray.withOpacity(0.7),
                ),
              ),
              const SizedBox(width: 6),
              Switch(
                value: onlyRecommended,
                onChanged: onOnlyRecommendedChanged,
                activeColor: AppTheme.oceanBlue,
              ),
            ],
          ),
        ],
      ),
    );
  }
}
