import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../theme/app_theme.dart';

class LocationHeader extends StatelessWidget {
  final String? locationName;
  final String? coordinates;

  const LocationHeader({
    super.key,
    this.locationName,
    this.coordinates,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 16),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  locationName ?? 'Nearest spot',
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: AppTheme.slateGray,
                  ),
                ),
                if (coordinates != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    '$coordinates • Updated ${DateFormat('HH:mm').format(DateTime.now())}',
                    style: GoogleFonts.poppins(
                      fontSize: 11,
                      color: AppTheme.slateGray.withOpacity(0.5),
                      fontWeight: FontWeight.w300,
                    ),
                  ),
                ],
              ],
            ),
          ),
          TextButton.icon(
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Change spot coming soon')),
              );
            },
            icon: const Icon(Icons.map, size: 16),
            label: const Text('Change'),
            style: TextButton.styleFrom(
              foregroundColor: AppTheme.oceanBlue,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            ),
          ),
        ],
      ),
    );
  }
}
