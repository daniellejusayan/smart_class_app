import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../services/student_service.dart';
import '../services/database_service.dart';
import '../services/firestore_service.dart';
import '../theme.dart';
import 'checkin_screen.dart';
import 'finish_class_screen.dart';
import 'history_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String _studentId = '';
  bool _hasOpenCheckin = false;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final id = await StudentService.getStudentId() ?? '';
    final activeDocId = await StudentService.getActiveCheckinDocId();
    dynamic openCheckin;
    var firestoreReachable = true;
    try {
      if (activeDocId != null && activeDocId.isNotEmpty) {
        openCheckin = await FirestoreService.getOpenCheckinByDocId(
          id,
          activeDocId,
        ).timeout(const Duration(seconds: 10));
      }

      openCheckin ??= await FirestoreService.getLatestOpenCheckin(id)
          .timeout(const Duration(seconds: 10));
    } catch (_) {
      firestoreReachable = false;
      openCheckin = null;
    }

    // Only use local fallback when Firestore is unreachable.
    // If Firestore is reachable and returns null, there is no active session.
    if (!firestoreReachable) {
      openCheckin = await DatabaseService.getLatestOpenCheckin(id);
    }

    if (mounted) {
      setState(() {
        _studentId = id;
        _hasOpenCheckin = openCheckin != null;
      });
    }
  }

  String get _greeting {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good morning';
    if (hour < 17) return 'Good afternoon';
    return 'Good evening';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.surface,
      appBar: AppBar(
        backgroundColor: AppTheme.primary,
        elevation: 0,
        title: Row(
          children: [
            const Icon(Icons.school_rounded, color: AppTheme.accent, size: 22),
            const SizedBox(width: 8),
            Text(
              'SmartClass',
              style: GoogleFonts.spaceGrotesk(
                color: Colors.white,
                fontWeight: FontWeight.w700,
                fontSize: 20,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.history_rounded, color: Colors.white70),
            onPressed: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => HistoryScreen(studentId: _studentId),
                ),
              );
              _loadData();
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadData,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              _buildHeader(),
              const SizedBox(height: 28),

              // Status banner
              if (_hasOpenCheckin) _buildActiveBanner(),
              if (_hasOpenCheckin) const SizedBox(height: 20),

              // Action cards
              Text(
                'What would you like to do?',
                style: GoogleFonts.spaceGrotesk(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.textPrimary,
                ),
              ),
              const SizedBox(height: 16),
              _buildActionCard(
                title: 'Check In',
                subtitle:
                    'Start a new class session\nwith GPS & QR verification',
                icon: Icons.login_rounded,
                color: AppTheme.accent,
                enabled: !_hasOpenCheckin,
                disabledReason: 'You already have an active check-in',
                onTap: () async {
                  await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => CheckinScreen(studentId: _studentId),
                    ),
                  );
                  _loadData();
                },
              ).animate().fadeIn(delay: 100.ms).slideX(begin: -0.1),
              const SizedBox(height: 16),
              _buildActionCard(
                title: 'Finish Class',
                subtitle: 'Complete your session\nand submit your reflection',
                icon: Icons.logout_rounded,
                color: AppTheme.accentGreen,
                enabled: _hasOpenCheckin,
                disabledReason: 'Check in to a class first',
                onTap: () async {
                  await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => FinishClassScreen(studentId: _studentId),
                    ),
                  );
                  _loadData();
                },
              ).animate().fadeIn(delay: 200.ms).slideX(begin: 0.1),

              const SizedBox(height: 32),
              _buildInfoCard(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '$_greeting,',
          style: GoogleFonts.dmSans(
            fontSize: 16,
            color: AppTheme.textSecondary,
          ),
        ),
        Text(
          _studentId,
          style: GoogleFonts.spaceGrotesk(
            fontSize: 28,
            fontWeight: FontWeight.w800,
            color: AppTheme.textPrimary,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          DateFormat('EEEE, MMMM d, yyyy').format(DateTime.now()),
          style: GoogleFonts.dmSans(
            fontSize: 14,
            color: AppTheme.textSecondary,
          ),
        ),
      ],
    ).animate().fadeIn(duration: 500.ms).slideY(begin: -0.1);
  }

  Widget _buildActiveBanner() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.accentGreen.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.accentGreen.withOpacity(0.4)),
      ),
      child: Row(
        children: [
          const Icon(Icons.radio_button_checked,
              color: AppTheme.accentGreen, size: 16),
          const SizedBox(width: 10),
          Text(
            'Active class session in progress',
            style: GoogleFonts.dmSans(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppTheme.accentGreen,
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 400.ms);
  }

  Widget _buildActionCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required bool enabled,
    required String disabledReason,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: enabled
          ? onTap
          : () {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(disabledReason),
                  backgroundColor: AppTheme.textSecondary,
                ),
              );
            },
      child: AnimatedOpacity(
        opacity: enabled ? 1.0 : 0.5,
        duration: const Duration(milliseconds: 200),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: enabled ? color.withOpacity(0.3) : AppTheme.border,
            ),
            boxShadow: enabled
                ? [
                    BoxShadow(
                      color: color.withOpacity(0.08),
                      blurRadius: 20,
                      offset: const Offset(0, 4),
                    )
                  ]
                : null,
          ),
          child: Row(
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(icon, color: color, size: 28),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: GoogleFonts.spaceGrotesk(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: GoogleFonts.dmSans(
                        fontSize: 13,
                        color: AppTheme.textSecondary,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.arrow_forward_ios_rounded,
                color: enabled ? color : AppTheme.border,
                size: 16,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.primary.withOpacity(0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.primary.withOpacity(0.1)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              const Icon(Icons.info_outline_rounded,
                  color: AppTheme.textSecondary, size: 18),
              const SizedBox(width: 8),
              Text(
                'How it works',
                style: GoogleFonts.dmSans(
                  fontWeight: FontWeight.w700,
                  color: AppTheme.textPrimary,
                  fontSize: 14,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _infoRow('1.', 'Tap Check In when class begins'),
          _infoRow('2.', 'Allow GPS & scan your instructor\'s QR code'),
          _infoRow('3.', 'Fill in your pre-class reflection'),
          _infoRow('4.', 'Tap Finish Class after the session ends'),
        ],
      ),
    ).animate().fadeIn(delay: 400.ms);
  }

  Widget _infoRow(String num, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          Text(
            num,
            style: GoogleFonts.spaceGrotesk(
              fontWeight: FontWeight.w700,
              color: AppTheme.accent,
              fontSize: 13,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: GoogleFonts.dmSans(
                fontSize: 13,
                color: AppTheme.textSecondary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
