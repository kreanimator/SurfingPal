import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';
import '../models/forecast_data.dart';
import '../utils/forecast_helpers.dart';

class DaySelector extends StatelessWidget {
  final List<List<HourlyForecast>> forecastsByDay;
  final int selectedIndex;
  final ValueChanged<int> onDaySelected;

  const DaySelector({
    super.key,
    required this.forecastsByDay,
    required this.selectedIndex,
    required this.onDaySelected,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 44,
      margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: forecastsByDay.length,
        itemBuilder: (context, index) {
          final isSelected = index == selectedIndex;
          return GestureDetector(
            onTap: () => onDaySelected(index),
            child: Container(
              margin: const EdgeInsets.only(right: 8),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: isSelected ? AppTheme.sand : Colors.transparent,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Center(
                child: Text(
                  ForecastHelpers.getDayLabel(index, forecastsByDay),
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    fontWeight: isSelected ? FontWeight.w500 : FontWeight.w400,
                    color: isSelected ? AppTheme.oceanBlue : AppTheme.slateGray.withOpacity(0.6),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
