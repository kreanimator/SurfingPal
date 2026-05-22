import 'dart:convert';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';
import '../theme/app_theme.dart';

class AppDrawer extends StatelessWidget {
  const AppDrawer({super.key});

  static const String _kofiUrl = 'https://ko-fi.com/vallsp';

  Future<void> _openKofi() async {
    final uri = Uri.parse(_kofiUrl);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  void _showDisclaimer(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => const _InfoDialog(
        icon: Icons.info_outline,
        title: 'Disclaimer',
        paragraphs: [
          'SurfingPal provides surf and water sports condition data '
              'for informational purposes only.',
          'We do not guarantee the accuracy, completeness, or reliability '
              'of any forecasts or recommendations displayed in this app.',
          'Always use your own judgment and check official local sources '
              'before entering the water. Conditions can change rapidly '
              'and may differ from forecasts.',
          'SurfingPal and its developers assume no responsibility or '
              'liability for any injury, loss, or damage arising from the '
              'use of information provided by this app.',
        ],
      ),
    );
  }

  void _showFeedback(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => const _FeedbackDialog(),
    );
  }

  void _showPrivacyPolicy(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => const _InfoDialog(
        icon: Icons.shield_outlined,
        title: 'Privacy Policy',
        paragraphs: [
          'SurfingPal respects your privacy. We do not collect, store, '
              'or share any personal data.',
          'Your location is used solely to display surf and weather '
              'conditions near you. Location data is sent to our forecast '
              'API to retrieve relevant results and is not stored on our '
              'servers or shared with third parties.',
          'We do not use analytics, tracking cookies, or any form of '
              'user profiling. No account or sign-up is required.',
          'If you have any questions about this policy, feel free to '
              'reach out via the support link in this menu.',
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Drawer(
      backgroundColor: AppTheme.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20),
          bottomLeft: Radius.circular(20),
        ),
      ),
      child: SafeArea(
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 24, 16, 8),
              child: Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: const BoxDecoration(
                      color: AppTheme.oceanDeep,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.waves,
                      size: 24,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Text(
                    'SurfingPal',
                    style: GoogleFonts.pacifico(
                      fontSize: 22,
                      color: AppTheme.oceanDeep,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.close, color: AppTheme.slateGray),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
            const Divider(height: 1, indent: 24, endIndent: 24),

            const SizedBox(height: 12),

            // Menu items
            _DrawerTile(
              icon: Icons.info_outline,
              label: 'Disclaimer',
              subtitle: 'Informational use only',
              onTap: () => _showDisclaimer(context),
            ),
            _DrawerTile(
              icon: Icons.shield_outlined,
              label: 'Privacy Policy',
              subtitle: 'Your data stays yours',
              onTap: () => _showPrivacyPolicy(context),
            ),
            _DrawerTile(
              icon: Icons.feedback_outlined,
              label: 'Feedback',
              subtitle: 'Help us improve',
              onTap: () => _showFeedback(context),
            ),

            const Divider(height: 24, indent: 24, endIndent: 24),

            // Ko-fi support section
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppTheme.sand,
                      AppTheme.sand.withOpacity(0.5),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: AppTheme.oceanDeep.withOpacity(0.08),
                  ),
                ),
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(
                          Icons.favorite,
                          color: AppTheme.coralAccent,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Support the App',
                          style: GoogleFonts.inter(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.oceanDeep,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'SurfingPal is completely free with no ads. '
                      'If you find it useful and want to support its '
                      'development, you can buy me a coffee!',
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        color: AppTheme.slateGray,
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: 14),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: _openKofi,
                        icon: const Icon(Icons.coffee, size: 18),
                        label: Text(
                          'Buy me a coffee',
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.coralAccent,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 0,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const Spacer(),

            // Footer
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
              child: Text(
                'Born from salt, wind & stoke\nv0.11 beta',
                style: GoogleFonts.inter(
                  fontSize: 12,
                  color: AppTheme.slateGray.withOpacity(0.5),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DrawerTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String subtitle;
  final VoidCallback onTap;

  const _DrawerTile({
    required this.icon,
    required this.label,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 2),
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: AppTheme.sand,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: AppTheme.oceanDeep, size: 20),
      ),
      title: Text(
        label,
        style: GoogleFonts.inter(
          fontSize: 15,
          fontWeight: FontWeight.w600,
          color: AppTheme.oceanDeep,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: GoogleFonts.inter(
          fontSize: 12,
          color: AppTheme.slateGray.withOpacity(0.7),
        ),
      ),
      trailing: Icon(
        Icons.chevron_right,
        color: AppTheme.slateGray.withOpacity(0.4),
        size: 20,
      ),
      onTap: onTap,
    );
  }
}

class _FeedbackDialog extends StatefulWidget {
  const _FeedbackDialog();

  @override
  State<_FeedbackDialog> createState() => _FeedbackDialogState();
}

class _FeedbackDialogState extends State<_FeedbackDialog> {
  int _rating = 0;
  final _messageController = TextEditingController();
  bool _sending = false;
  bool _sent = false;

  static String get _baseUrl {
    if (kIsWeb) return Uri.base.origin;
    return 'https://surfingpal.app';
  }

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_rating == 0) return;
    setState(() => _sending = true);

    try {
      final uri = Uri.parse('$_baseUrl/api/feedback');
      await http.post(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'rating': _rating,
          'message': _messageController.text.trim(),
        }),
      );
      if (mounted) setState(() => _sent = true);
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Failed to send feedback. Try again later.'),
            backgroundColor: AppTheme.coralAccent,
          ),
        );
        setState(() => _sending = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: AppTheme.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 48),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 480),
        child: _sent ? _buildThankYou() : _buildForm(),
      ),
    );
  }

  Widget _buildThankYou() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.check_circle, color: AppTheme.seafoamGreen, size: 56),
          const SizedBox(height: 16),
          Text(
            'Thank you!',
            style: GoogleFonts.pacifico(
              fontSize: 24,
              color: AppTheme.oceanDeep,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Your feedback helps make SurfingPal better.',
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              fontSize: 14,
              color: AppTheme.slateGray,
            ),
          ),
          const SizedBox(height: 24),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Close',
              style: GoogleFonts.inter(
                color: AppTheme.oceanDeep,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildForm() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Title
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 20, 12, 0),
          child: Row(
            children: [
              const Icon(Icons.feedback_outlined, color: AppTheme.oceanDeep, size: 24),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Send Feedback',
                  style: GoogleFonts.inter(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.oceanDeep,
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close, color: AppTheme.slateGray),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
        ),
        const Divider(indent: 24, endIndent: 24),

        Padding(
          padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Rating
              Text(
                'How would you rate SurfingPal?',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.oceanDeep,
                ),
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(5, (i) {
                  final star = i + 1;
                  return GestureDetector(
                    onTap: () => setState(() => _rating = star),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: Icon(
                        star <= _rating ? Icons.star_rounded : Icons.star_outline_rounded,
                        color: star <= _rating
                            ? AppTheme.okYellow
                            : AppTheme.slateGray.withOpacity(0.3),
                        size: 40,
                      ),
                    ),
                  );
                }),
              ),
              if (_rating > 0) ...[
                const SizedBox(height: 4),
                Center(
                  child: Text(
                    ['', 'Terrible', 'Poor', 'Okay', 'Good', 'Awesome'][_rating],
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: AppTheme.slateGray,
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 20),

              // Message
              Text(
                'What can we improve?',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.oceanDeep,
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _messageController,
                maxLines: 4,
                maxLength: 500,
                decoration: InputDecoration(
                  hintText: 'Missing features, wrong data, UI ideas...',
                  hintStyle: GoogleFonts.inter(
                    fontSize: 13,
                    color: AppTheme.slateGray.withOpacity(0.4),
                  ),
                  filled: true,
                  fillColor: AppTheme.sand.withOpacity(0.5),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: AppTheme.oceanDeep, width: 1.5),
                  ),
                  contentPadding: const EdgeInsets.all(14),
                  counterStyle: GoogleFonts.inter(
                    fontSize: 11,
                    color: AppTheme.slateGray.withOpacity(0.5),
                  ),
                ),
                style: GoogleFonts.inter(fontSize: 14, color: AppTheme.slateGray),
              ),
              const SizedBox(height: 16),

              // Submit
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _rating == 0 || _sending ? null : _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.oceanDeep,
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: AppTheme.oceanDeep.withOpacity(0.3),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                  ),
                  child: _sending
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : Text(
                          'Send Feedback',
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _InfoDialog extends StatelessWidget {
  final IconData icon;
  final String title;
  final List<String> paragraphs;

  const _InfoDialog({
    required this.icon,
    required this.title,
    required this.paragraphs,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: AppTheme.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 48),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 480),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Title row with close button
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 20, 12, 0),
              child: Row(
                children: [
                  Icon(icon, color: AppTheme.oceanDeep, size: 24),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      title,
                      style: GoogleFonts.inter(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.oceanDeep,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: AppTheme.slateGray),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
            const Divider(indent: 24, endIndent: 24),

            // Content
            Flexible(
              child: ListView.builder(
                shrinkWrap: true,
                padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
                itemCount: paragraphs.length,
                itemBuilder: (context, index) => Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: Text(
                    paragraphs[index],
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      color: AppTheme.slateGray,
                      height: 1.6,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
