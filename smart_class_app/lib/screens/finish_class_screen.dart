import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/checkin_record.dart';
import '../services/database_service.dart';
import '../services/firestore_service.dart';
import '../services/location_service.dart';
import '../services/student_service.dart';
import '../theme.dart';

enum _Step { location, form, saving }

class FinishClassScreen extends StatefulWidget {
  final String studentId;

  const FinishClassScreen({super.key, required this.studentId});

  @override
  State<FinishClassScreen> createState() => _FinishClassScreenState();
}

class _FinishClassScreenState extends State<FinishClassScreen> {
  _Step _step = _Step.location;
  String? _qrValue;
  String? _activeCheckinDocId;
  CheckinRecord? _openRecord;
  bool _recordLoading = true;
  bool _locationLoading = false;
  String? _locationError;
  double? _lat;
  double? _lng;

  final _learnedCtrl = TextEditingController();
  final _feedbackCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadOpenRecord();
  }

  Future<void> _loadOpenRecord() async {
    CheckinRecord? record;
    var firestoreReachable = true;
    _activeCheckinDocId = await StudentService.getActiveCheckinDocId();
    try {
      if (_activeCheckinDocId != null && _activeCheckinDocId!.isNotEmpty) {
        record = await FirestoreService.getOpenCheckinByDocId(
          widget.studentId,
          _activeCheckinDocId!,
        ).timeout(const Duration(seconds: 10));
      }

      record ??= await FirestoreService.getLatestOpenCheckin(widget.studentId)
          .timeout(const Duration(seconds: 10));
    } catch (_) {
      firestoreReachable = false;
      record = null;
    }

    // Only trust local fallback when Firestore could not be reached.
    if (!firestoreReachable) {
      record = await DatabaseService.getLatestOpenCheckin(widget.studentId);
    }

    if (!mounted) return;
    setState(() {
      _openRecord = record;
      _recordLoading = false;
      // Reuse the class code from check-in — no second QR scan needed.
      _qrValue = record?.checkinQrValue;
    });
  }

  Future<void> _getLocation() async {
    setState(() {
      _locationLoading = true;
      _locationError = null;
    });
    try {
      final pos = await LocationService.getCurrentLocation().timeout(
        const Duration(seconds: 25),
        onTimeout: () => null,
      );
      if (!mounted) return;
      if (pos == null) {
        setState(() => _locationError = 'Could not retrieve location. Enable Location, allow browser permission, then try again.');
      } else {
        setState(() {
          _lat = pos.latitude;
          _lng = pos.longitude;
          _step = _Step.form;
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _locationError = 'Location error: $e');
    } finally {
      if (mounted) {
        setState(() => _locationLoading = false);
      }
    }
  }

  Future<void> _saveCheckout() async {
    if (_lat == null || _lng == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Location unavailable — please go back and capture your location.')),
      );
      return;
    }
    setState(() => _step = _Step.saving);
    try {
      final data = CheckoutData(
        checkoutTime: DateTime.now().toIso8601String(),
        checkoutLatitude: _lat!,
        checkoutLongitude: _lng!,
        checkoutQrValue: _qrValue,
        learnedToday: _learnedCtrl.text.trim(),
        feedback: _feedbackCtrl.text.trim(),
      );
      // Firestore is the primary shared store — save here first.
      final updated =
          await FirestoreService.updateCheckout(
        widget.studentId,
        data,
        checkinDocId: _activeCheckinDocId,
      );
      if (!updated) {
        throw Exception('No active check-in found to complete.');
      }

      await StudentService.clearActiveCheckinDocId();

      // Best-effort local update (may fail on web if SharedArrayBuffer unavailable).
      try {
        final localOpen = await DatabaseService.getLatestOpenCheckin(widget.studentId);
        if (localOpen?.id != null) {
          await DatabaseService.updateCheckout(localOpen!.id!, data);
        }
      } catch (_) {}

      if (mounted) {
        _showSuccessDialog();
      }
    } on FirebaseException catch (e) {
      if (mounted) {
        setState(() => _step = _Step.form);
        final message = kIsWeb
            ? 'Firestore could not be reached from this browser session. Hard-refresh the page and try again. If it still fails, verify Firestore Database is enabled for this project.'
            : 'Save failed: ${e.message ?? e.code}';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(message),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _step = _Step.form);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Save failed: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: AppTheme.accent.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.star_rounded,
                  color: AppTheme.accent, size: 40),
            ),
            const SizedBox(height: 16),
            Text('Class Complete!',
                style: GoogleFonts.spaceGrotesk(
                    fontSize: 22, fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            Text(
              'Great job today! Your learning reflection has been saved.',
              textAlign: TextAlign.center,
              style: GoogleFonts.dmSans(
                  color: AppTheme.textSecondary, fontSize: 14, height: 1.5),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  Navigator.pop(context);
                },
                child: const Text('Back to Home'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.surface,
      appBar: AppBar(
        title: const Text('Finish Class'),
        backgroundColor: AppTheme.accentGreen,
      ),
      body: _recordLoading
          ? const Center(child: CircularProgressIndicator(color: AppTheme.accentGreen))
        : _openRecord == null
            ? _buildNoRecordState()
            : SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildProgressBar(),
                    const SizedBox(height: 28),
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 350),
                      child: _buildCurrentStep(),
                    ),
                  ],
                ),
              ),
    );
  }

  Widget _buildNoRecordState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.info_outline_rounded,
                color: AppTheme.textSecondary, size: 56),
            const SizedBox(height: 20),
            Text(
              'No active check-in found',
              style: GoogleFonts.spaceGrotesk(
                  fontSize: 20, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 10),
            Text(
              'You need to check in to a class before you can check out.',
              textAlign: TextAlign.center,
              style: GoogleFonts.dmSans(
                  fontSize: 14,
                  color: AppTheme.textSecondary,
                  height: 1.5),
            ),
            const SizedBox(height: 28),
            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Back to Home'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProgressBar() {
    final steps = ['GPS', 'Reflection'];
    final currentIndex = _step.index.clamp(0, 1);

    return Row(
      children: List.generate(steps.length, (i) {
        final done = i < currentIndex;
        final active = i == currentIndex;
        return Expanded(
          child: Padding(
            padding: EdgeInsets.only(right: i < steps.length - 1 ? 4 : 0),
            child: Column(
              children: [
                Container(
                  height: 4,
                  decoration: BoxDecoration(
                    color:
                        done || active ? AppTheme.accentGreen : AppTheme.border,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  steps[i],
                  style: GoogleFonts.dmSans(
                    fontSize: 11,
                    fontWeight: active ? FontWeight.w700 : FontWeight.w400,
                    color: active || done
                        ? AppTheme.accentGreen
                        : AppTheme.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        );
      }),
    );
  }

  Widget _buildCurrentStep() {
    switch (_step) {
      case _Step.location:
        return _buildLocationStep();
      case _Step.form:
        return _buildFormStep();
      case _Step.saving:
        return const Center(
          child: Padding(
            padding: EdgeInsets.all(48),
            child: CircularProgressIndicator(color: AppTheme.accentGreen),
          ),
        );
    }
  }

  Widget _buildLocationStep() {
    return Column(
      key: const ValueKey('location'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Step 1: Verify Exit Location',
            style: GoogleFonts.spaceGrotesk(
                fontSize: 22, fontWeight: FontWeight.w700)),
        const SizedBox(height: 8),
        if (_qrValue != null) ...[
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            margin: const EdgeInsets.only(bottom: 12),
            decoration: BoxDecoration(
              color: AppTheme.accentGreen.withOpacity(0.08),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppTheme.accentGreen.withOpacity(0.3)),
            ),
            child: Row(
              children: [
                const Icon(Icons.school_rounded,
                    color: AppTheme.accentGreen, size: 16),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Checking out of: ${FirestoreService.extractClassCode(_qrValue) ?? _qrValue}',
                    style: GoogleFonts.dmSans(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.accentGreen),
                  ),
                ),
              ],
            ),
          ),
        ],
        Text(
          'Recording your exit location to confirm you were in class.',
          style: GoogleFonts.dmSans(
              fontSize: 14, color: AppTheme.textSecondary, height: 1.5),
        ),
        const SizedBox(height: 32),
        Center(
          child: Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              color: AppTheme.accentGreen.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.location_on_rounded,
                color: AppTheme.accentGreen, size: 48),
          ),
        ),
        const SizedBox(height: 32),
        if (_locationError != null) ...[   
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.red.shade50,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.red.shade200),
            ),
            child: Row(
              children: [
                const Icon(Icons.error_outline, color: Colors.red, size: 18),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(_locationError!,
                      style: GoogleFonts.dmSans(
                          color: Colors.red.shade700, fontSize: 13)),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
        ],
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: _locationLoading ? null : _getLocation,
            icon: _locationLoading
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                        color: Colors.white, strokeWidth: 2),
                  )
                : const Icon(Icons.my_location_rounded),
            label: Text(
                _locationLoading ? 'Getting Location...' : 'Get My Location'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.accentGreen,
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFormStep() {
    return Column(
      key: const ValueKey('form'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Step 2: Learning Reflection',
            style: GoogleFonts.spaceGrotesk(
                fontSize: 22, fontWeight: FontWeight.w700)),
        const SizedBox(height: 8),
        Text(
          'Reflect on what you learned today.',
          style:
              GoogleFonts.dmSans(fontSize: 14, color: AppTheme.textSecondary),
        ),
        const SizedBox(height: 20),
        _buildFormCard('What did you learn today?',
            'Share your key takeaways from this class...', _learnedCtrl,
            maxLines: 4),
        const SizedBox(height: 16),
        _buildFormCard('Feedback (Optional)',
            'Any comments about the class or teaching style?', _feedbackCtrl,
            maxLines: 3),
        const SizedBox(height: 32),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: _learnedCtrl.text.isEmpty ? null : _saveCheckout,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.accentGreen,
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
            child: const Text('Submit & Complete →'),
          ),
        ),
        const SizedBox(height: 8),
        Center(
          child: TextButton(
            onPressed: _saveCheckout,
            child: Text('Skip reflection & complete',
                style: GoogleFonts.dmSans(
                    fontSize: 13, color: AppTheme.textSecondary)),
          ),
        ),
      ],
    );
  }

  Widget _buildFormCard(String label, String hint, TextEditingController ctrl,
      {int maxLines = 1}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: GoogleFonts.dmSans(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppTheme.textPrimary)),
        const SizedBox(height: 8),
        TextField(
          controller: ctrl,
          maxLines: maxLines,
          onChanged: (_) => setState(() {}),
          decoration: InputDecoration(hintText: hint),
        ),
      ],
    );
  }

  @override
  void dispose() {
    _learnedCtrl.dispose();
    _feedbackCtrl.dispose();
    super.dispose();
  }
}
