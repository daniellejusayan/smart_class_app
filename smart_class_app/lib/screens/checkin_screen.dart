import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:geolocator/geolocator.dart';
import '../models/checkin_record.dart';
import '../services/database_service.dart';
import '../services/firestore_service.dart';
import '../services/location_service.dart';
import '../services/student_service.dart';
import '../theme.dart';
import '../widgets/qr_scanner_widget.dart';
import '../widgets/mood_selector.dart';

enum _Step { location, qr, form, saving }

class CheckinScreen extends StatefulWidget {
  final String studentId;

  const CheckinScreen({super.key, required this.studentId});

  @override
  State<CheckinScreen> createState() => _CheckinScreenState();
}

class _CheckinScreenState extends State<CheckinScreen> {
  _Step _step = _Step.location;
  Position? _position;
  String? _qrValue;
  int? _mood;
  final _prevTopicCtrl = TextEditingController();
  final _expectedTopicCtrl = TextEditingController();
  bool _locationLoading = false;
  String? _locationError;
  bool _validatingQr = false;
  String? _qrError;
  int _qrKey = 0;

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
          _position = pos;
          _step = _Step.qr;
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

  Future<void> _saveCheckin() async {
    if (_position == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Location unavailable — please go back and try again.')),
      );
      return;
    }
    setState(() => _step = _Step.saving);
    try {
      final now = DateTime.now().toIso8601String();
      final record = CheckinRecord(
        studentId: widget.studentId,
        checkinTime: now,
        checkinLatitude: _position!.latitude,
        checkinLongitude: _position!.longitude,
        checkinQrValue: _qrValue,
        previousTopic: _prevTopicCtrl.text.trim(),
        expectedTopic: _expectedTopicCtrl.text.trim(),
        mood: _mood,
      );

      // Firestore is the primary shared store — save here first.
      // SQLite is a local cache; its failure must never block the Firestore save.
      final docId = await FirestoreService.saveCheckin(record);
      await StudentService.saveActiveCheckinDocId(docId);

      // Best-effort local save (may fail on web if SharedArrayBuffer unavailable).
      try {
        await DatabaseService.insertCheckin(record);
      } catch (_) {}

      if (mounted) {
        _showSuccessDialog();
      }
    } on FirebaseException catch (e) {
      if (mounted) {
        setState(() => _step = _Step.form);
        final message = kIsWeb
            ? 'Firestore could not be reached from this browser session. Hard-refresh the page and try again. If it still fails, verify Firestore Database is enabled for this project.'
            : 'Check-in failed: ${e.message ?? e.code}';
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
            content: Text('Check-in failed: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _handleQrScan(String value) async {
    setState(() {
      _validatingQr = true;
      _qrError = null;
    });

    try {
      final resolvedQrValue = await FirestoreService.resolveActiveSessionQr(value);
      if (!mounted) return;

      if (resolvedQrValue == null) {
        setState(() {
          _validatingQr = false;
          _qrError = 'This class code or QR value is not an active instructor session. Ask your instructor to generate a fresh class QR.';
          _qrKey++;
        });
        return;
      }

      setState(() {
        _qrValue = resolvedQrValue;
        _validatingQr = false;
        _step = _Step.form;
      });
    } on FirebaseException catch (_) {
      if (!mounted) return;
      setState(() {
        _validatingQr = false;
        _qrError = 'Could not verify the class code or QR value with Firestore. Refresh and try again.';
        _qrKey++;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _validatingQr = false;
        _qrError = 'QR validation failed. Please scan again.';
        _qrKey++;
      });
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
                color: AppTheme.accentGreen.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.check_circle_rounded,
                  color: AppTheme.accentGreen, size: 40),
            ),
            const SizedBox(height: 16),
            Text('Checked In!',
                style: GoogleFonts.spaceGrotesk(
                    fontSize: 22, fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            Text(
              'Your attendance has been recorded successfully.',
              textAlign: TextAlign.center,
              style: GoogleFonts.dmSans(
                  color: AppTheme.textSecondary, fontSize: 14, height: 1.5),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pop(context); // close dialog
                  Navigator.pop(context); // back to home
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
        title: const Text('Check In'),
        backgroundColor: AppTheme.primary,
        leading: BackButton(
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
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

  Widget _buildProgressBar() {
    final steps = ['GPS', 'QR Code', 'Reflection'];
    final currentIndex = _step.index.clamp(0, 2);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: List.generate(steps.length, (i) {
            final done = i < currentIndex;
            final active = i == currentIndex;
            return Expanded(
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      children: [
                        Container(
                          height: 4,
                          decoration: BoxDecoration(
                            color: done || active
                                ? AppTheme.accent
                                : AppTheme.border,
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          steps[i],
                          style: GoogleFonts.dmSans(
                            fontSize: 11,
                            fontWeight: active
                                ? FontWeight.w700
                                : FontWeight.w400,
                            color: active || done
                                ? AppTheme.accent
                                : AppTheme.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (i < steps.length - 1) const SizedBox(width: 4),
                ],
              ),
            );
          }),
        ),
      ],
    );
  }

  Widget _buildCurrentStep() {
    switch (_step) {
      case _Step.location:
        return _buildLocationStep();
      case _Step.qr:
        return _buildQrStep();
      case _Step.form:
        return _buildFormStep();
      case _Step.saving:
        return const Center(
          child: Padding(
            padding: EdgeInsets.all(48),
            child: CircularProgressIndicator(color: AppTheme.accent),
          ),
        );
    }
  }

  Widget _buildLocationStep() {
    return Column(
      key: const ValueKey('location'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Step 1: Verify Location',
            style: GoogleFonts.spaceGrotesk(
                fontSize: 22, fontWeight: FontWeight.w700)),
        const SizedBox(height: 8),
        Text(
          'We need your GPS location to confirm you\'re on campus.',
          style: GoogleFonts.dmSans(
              fontSize: 14, color: AppTheme.textSecondary, height: 1.5),
        ),
        const SizedBox(height: 32),
        Center(
          child: Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              color: AppTheme.accent.withOpacity(0.08),
              shape: BoxShape.circle,
              border: Border.all(
                  color: AppTheme.accent.withOpacity(0.3), width: 2),
            ),
            child: const Icon(Icons.location_on_rounded,
                color: AppTheme.accent, size: 56),
          ),
        ).animate().scale(duration: 600.ms, curve: Curves.elasticOut),
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
            label: Text(_locationLoading
                ? 'Getting Location...'
                : 'Get My Location'),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildQrStep() {
    return Column(
      key: const ValueKey('qr'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Step 2: Scan QR Code',
            style: GoogleFonts.spaceGrotesk(
                fontSize: 22, fontWeight: FontWeight.w700)),
        const SizedBox(height: 8),
        Text(
          'Scan the QR code displayed by your instructor.',
          style: GoogleFonts.dmSans(
              fontSize: 14, color: AppTheme.textSecondary, height: 1.5),
        ),
        const SizedBox(height: 24),
        if (_qrError != null) ...[
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
                  child: Text(_qrError!,
                      style: GoogleFonts.dmSans(
                          color: Colors.red.shade700, fontSize: 13)),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
        ],
        if (_validatingQr) ...[
          const Center(
            child: Padding(
              padding: EdgeInsets.symmetric(vertical: 24),
              child: CircularProgressIndicator(color: AppTheme.accent),
            ),
          ),
          Center(
            child: Text('Validating instructor session...',
                style: GoogleFonts.dmSans(
                    fontSize: 13, color: AppTheme.textSecondary)),
          ),
          const SizedBox(height: 16),
        ],
        QrScannerWidget(
          key: ValueKey('checkin-qr-$_qrKey'),
          onScanned: _handleQrScan,
          instruction: 'Scan your instructor\'s QR code',
        ),
      ],
    );
  }

  Widget _buildFormStep() {
    return Column(
      key: const ValueKey('form'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Step 3: Pre-class Reflection',
            style: GoogleFonts.spaceGrotesk(
                fontSize: 22, fontWeight: FontWeight.w700)),
        const SizedBox(height: 8),
        Text(
          'Take a moment to reflect before class begins.',
          style: GoogleFonts.dmSans(
              fontSize: 14, color: AppTheme.textSecondary),
        ),
        const SizedBox(height: 8),
        _buildQrConfirmBadge(),
        const SizedBox(height: 20),
        _buildFormCard('Previous Class Topic',
            'What was covered in your last class?', _prevTopicCtrl,
            maxLines: 2),
        const SizedBox(height: 16),
        _buildFormCard('Today\'s Expected Topic',
            'What do you expect to learn today?', _expectedTopicCtrl,
            maxLines: 2),
        const SizedBox(height: 20),
        MoodSelector(
          value: _mood,
          onChanged: (v) => setState(() => _mood = v),
        ),
        const SizedBox(height: 32),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: _mood == null ? null : _saveCheckin,
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              backgroundColor:
                  _mood == null ? AppTheme.border : AppTheme.accent,
            ),
            child: const Text('Complete Check-in →'),
          ),
        ),
        if (_mood == null) ...[
          const SizedBox(height: 8),
          Center(
            child: Text('Please select your mood to continue.',
                style: GoogleFonts.dmSans(
                    fontSize: 12, color: AppTheme.textSecondary)),
          ),
        ],
      ],
    );
  }

  Widget _buildQrConfirmBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppTheme.accentGreen.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppTheme.accentGreen.withOpacity(0.4)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.check_circle_outline,
              color: AppTheme.accentGreen, size: 14),
          const SizedBox(width: 6),
          Text('QR Code: $_qrValue',
              style: GoogleFonts.dmSans(
                  fontSize: 12,
                  color: AppTheme.accentGreen,
                  fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  Widget _buildFormCard(
      String label, String hint, TextEditingController ctrl,
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
          decoration: InputDecoration(hintText: hint),
        ),
      ],
    );
  }

  @override
  void dispose() {
    _prevTopicCtrl.dispose();
    _expectedTopicCtrl.dispose();
    super.dispose();
  }
}
