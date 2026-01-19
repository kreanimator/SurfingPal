import 'dart:math' as math;
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/api_service.dart';
import '../services/location_service.dart';
import '../services/geocoding_service.dart';
import '../models/forecast_data.dart';
import '../theme/app_theme.dart';
import 'results_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with SingleTickerProviderStateMixin {
  final ApiService _apiService = ApiService();
  final LocationService _locationService = LocationService();
  final GeocodingService _geocodingService = GeocodingService();
  bool _isLoading = false;
  late AnimationController _animationController;
  late Animation<double> _logoAnimation;

  @override
  void initState() {
    super.initState();
    // Subtle logo breathing animation
    _animationController = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    )..repeat(reverse: true);
    
    _logoAnimation = Tween<double>(begin: 0.95, end: 1.05).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _fetchForecast() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Get user's current location
      final position = await _locationService.getCurrentPosition();
      
      double? latitude;
      double? longitude;

      if (position != null) {
        latitude = position.latitude;
        longitude = position.longitude;
      } else {
        final lastPosition = await _locationService.getLastKnownPosition();
        if (lastPosition != null) {
          latitude = lastPosition.latitude;
          longitude = lastPosition.longitude;
        } else {
          final result = await _showLocationDialog();
          if (result != null) {
            latitude = result['latitude'] as double?;
            longitude = result['longitude'] as double?;
          }
        }
      }

      // Fetch forecast with coordinates
      final data = await _apiService.getForecast(
        latitude: latitude,
        longitude: longitude,
      );
      final forecastData = ForecastData.fromJson(data);

      // Get location name from coordinates
      String? locationName;
      if (latitude != null && longitude != null) {
        try {
          locationName = await _geocodingService.getLocationName(
            latitude!,
            longitude!,
          );
        } catch (e) {
          locationName = forecastData.meta['coordinates']?['pretty'] as String?;
        }
      } else {
        locationName = forecastData.meta['coordinates']?['pretty'] as String?;
      }

      if (!mounted) return;

      // Fade → slide transition
      Navigator.push(
        context,
        PageRouteBuilder(
          pageBuilder: (context, animation, secondaryAnimation) => ResultsScreen(
            forecastData: forecastData,
            locationName: locationName,
            latitude: latitude,
            longitude: longitude,
          ),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return FadeTransition(
              opacity: animation,
              child: SlideTransition(
                position: Tween<Offset>(
                  begin: const Offset(0.0, 0.1),
                  end: Offset.zero,
                ).animate(CurvedAnimation(
                  parent: animation,
                  curve: Curves.easeOut,
                )),
                child: child,
              ),
            );
          },
          transitionDuration: const Duration(milliseconds: 300),
        ),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: AppTheme.coral,
          duration: const Duration(seconds: 5),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<Map<String, double?>?> _showLocationDialog() async {
    return showDialog<Map<String, double?>>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Location Required'),
        content: const Text(
          'Unable to get your current location. You can:\n\n'
          '1. Enable location services in settings\n'
          '2. Enter coordinates manually\n'
          '3. Use default test location',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, null),
            child: const Text('Use Default'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(dialogContext);
              final result = await _showManualLocationDialog();
              if (result != null) {
                Navigator.pop(context, result);
              }
            },
            child: const Text('Enter Manually'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }

  Future<Map<String, double?>?> _showManualLocationDialog() async {
    final latController = TextEditingController();
    final lonController = TextEditingController();

    return showDialog<Map<String, double?>>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Enter Coordinates'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: latController,
              decoration: const InputDecoration(
                labelText: 'Latitude',
                hintText: 'e.g., 32.3443',
              ),
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: lonController,
              decoration: const InputDecoration(
                labelText: 'Longitude',
                hintText: 'e.g., 34.8637',
              ),
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              final lat = double.tryParse(latController.text);
              final lon = double.tryParse(lonController.text);
              if (lat != null && lon != null) {
                Navigator.pop(dialogContext, {'latitude': lat, 'longitude': lon});
              } else {
                ScaffoldMessenger.of(dialogContext).showSnackBar(
                  const SnackBar(
                    content: Text('Please enter valid coordinates'),
                    backgroundColor: AppTheme.coral,
                  ),
                );
              }
            },
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Fullscreen looping GIF background
          Image.asset(
            'assets/ocean_waves_bg.gif',
            fit: BoxFit.cover,
            repeat: ImageRepeat.noRepeat,
          ),
          
          // Soft blur + overlay (Option B)
          Positioned.fill(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
              child: Container(
                color: AppTheme.sand.withOpacity(0.30), // Soft surf vibe overlay
              ),
            ),
          ),
          
          // Content
          SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final isDesktop = constraints.maxWidth > 768;
                return Center(
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      maxWidth: isDesktop ? 600.0 : constraints.maxWidth,
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(32.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          // Logo icon with subtle breathing animation
                          AnimatedBuilder(
                            animation: _logoAnimation,
                            builder: (context, child) {
                              return Transform.scale(
                                scale: _logoAnimation.value,
                                child: Container(
                                  width: 100,
                                  height: 100,
                                  decoration: BoxDecoration(
                                    color: AppTheme.oceanDeep,
                                    shape: BoxShape.circle,
                                    boxShadow: [
                                      BoxShadow(
                                        color: AppTheme.oceanDeep.withOpacity(0.3),
                                        blurRadius: 20,
                                        spreadRadius: 5,
                                      ),
                                    ],
                                  ),
                                  child: const Icon(
                                    Icons.waves,
                                    size: 50,
                                    color: Colors.white,
                                  ),
                                ),
                              );
                            },
                          ),
                          const SizedBox(height: 40),
                          
                          // Title with curvy surf font (Pacifico)
                          Text(
                            'SurfingPal',
                            style: GoogleFonts.pacifico(
                              fontSize: 48,
                              color: AppTheme.oceanDeep,
                              shadows: [
                                Shadow(
                                  color: Colors.white.withOpacity(0.8),
                                  blurRadius: 10,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),
                          
                          // Subtitle with calm font (Inter)
                          Text(
                            'What\'s the surf like?',
                            style: GoogleFonts.inter(
                              fontSize: 20,
                              color: AppTheme.oceanDeep.withOpacity(0.9),
                              fontWeight: FontWeight.w300,
                              shadows: [
                                Shadow(
                                  color: Colors.white.withOpacity(0.8),
                                  blurRadius: 8,
                                  offset: const Offset(0, 1),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 60),
                          
                          // Single strong CTA with wave-like hover effect
                          _isLoading
                              ? Center(
                                  child: CircularProgressIndicator(
                                    valueColor: AlwaysStoppedAnimation<Color>(AppTheme.oceanDeep),
                                  ),
                                )
                              : SizedBox(
                                  width: double.infinity,
                                  child: _WaveButton(
                                    onPressed: _fetchForecast,
                                    child: Text(
                                      'Check Conditions',
                                      style: GoogleFonts.inter(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                        letterSpacing: 0.5,
                                      ),
                                    ),
                                  ),
                                ),
                          const SizedBox(height: 40),
                          
                          // Small helper text
                          Text(
                            'Real-time surf, SUP, wind & kite recommendations',
                            textAlign: TextAlign.center,
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              color: AppTheme.oceanDeep.withOpacity(0.7),
                              fontWeight: FontWeight.w300,
                              shadows: [
                                Shadow(
                                  color: Colors.white.withOpacity(0.8),
                                  blurRadius: 6,
                                  offset: const Offset(0, 1),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

// Wave-like button with subtle pulse animation
class _WaveButton extends StatefulWidget {
  final VoidCallback onPressed;
  final Widget child;

  const _WaveButton({
    required this.onPressed,
    required this.child,
  });

  @override
  State<_WaveButton> createState() => _WaveButtonState();
}

class _WaveButtonState extends State<_WaveButton> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  bool _isHovered = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          final waveOffset = _isHovered ? 0.02 : 0.0;
          return Transform.scale(
            scale: 1.0 + (waveOffset * (0.5 + 0.5 * (1 + math.sin(_controller.value * 2 * math.pi)) / 2)),
            child: ElevatedButton(
              onPressed: widget.onPressed,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.coralAccent,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 18),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
                elevation: _isHovered ? 8 : 4,
              ),
              child: widget.child,
            ),
          );
        },
      ),
    );
  }
}
