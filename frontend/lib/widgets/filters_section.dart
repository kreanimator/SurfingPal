import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';
import '../utils/sport_formatters.dart';

class FiltersSection extends StatefulWidget {
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
  State<FiltersSection> createState() => _FiltersSectionState();
}

class _FiltersSectionState extends State<FiltersSection> {
  final ScrollController _scrollController = ScrollController();
  bool _showRightArrow = false;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_checkScrollPosition);
    // Check initial scroll position after first frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkScrollPosition();
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _checkScrollPosition() {
    if (!_scrollController.hasClients) return;
    
    final maxScroll = _scrollController.position.maxScrollExtent;
    final currentScroll = _scrollController.position.pixels;
    
    // Show arrow if there's scrollable content and not at the end
    final shouldShow = maxScroll > 0 && currentScroll < maxScroll - 10;
    
    if (shouldShow != _showRightArrow) {
      setState(() {
        _showRightArrow = shouldShow;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Sport toggles in one horizontal scrollable line with scroll indicator
          Row(
            children: [
              Text(
                'Show:',
                style: GoogleFonts.inter(
                  fontSize: 12,
                  color: AppTheme.slateGray.withOpacity(0.7),
                  fontWeight: FontWeight.w400,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Stack(
                  children: [
                    SingleChildScrollView(
                      controller: _scrollController,
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: widget.availableSports.map((sport) {
                          final isSelected = widget.selectedSports[sport] ?? false;
                          return Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: FilterChip(
                              label: Text(SportFormatters.getSportName(sport)),
                              selected: isSelected,
                              onSelected: (selected) => widget.onSportToggled(sport),
                              selectedColor: AppTheme.sand,
                              checkmarkColor: AppTheme.oceanBlue,
                              labelStyle: GoogleFonts.inter(
                                fontSize: 11,
                                fontWeight: FontWeight.w400,
                                color: isSelected 
                                    ? AppTheme.oceanBlue 
                                    : AppTheme.slateGray.withOpacity(0.7),
                              ),
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                    // Right arrow indicator (fade gradient)
                    if (_showRightArrow)
                      Positioned(
                        right: 0,
                        top: 0,
                        bottom: 0,
                        child: Container(
                          width: 40,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.centerLeft,
                              end: Alignment.centerRight,
                              colors: [
                                AppTheme.white.withOpacity(0.0),
                                AppTheme.white.withOpacity(0.8),
                                AppTheme.white,
                              ],
                            ),
                          ),
                          child: Center(
                            child: Icon(
                              Icons.arrow_forward_ios,
                              size: 12,
                              color: AppTheme.oceanDeep.withOpacity(0.6),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
          
          // "Only recommended" toggle below
          const SizedBox(height: 12),
          Row(
            children: [
              Text(
                'Only recommended',
                style: GoogleFonts.inter(
                  fontSize: 11,
                  color: AppTheme.slateGray.withOpacity(0.7),
                ),
              ),
              const SizedBox(width: 8),
              Switch(
                value: widget.onlyRecommended,
                onChanged: widget.onOnlyRecommendedChanged,
                activeColor: AppTheme.oceanBlue,
              ),
            ],
          ),
        ],
      ),
    );
  }
}
