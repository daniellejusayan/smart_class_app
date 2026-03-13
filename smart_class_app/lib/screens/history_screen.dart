import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../models/checkin_record.dart';
import '../services/database_service.dart';
import '../services/firestore_service.dart';
import '../theme.dart';

class HistoryScreen extends StatefulWidget {
  final String studentId;

  const HistoryScreen({super.key, required this.studentId});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  List<CheckinRecord> _records = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    List<CheckinRecord> records;
    try {
      records = await FirestoreService.getAllRecords(widget.studentId);
    } catch (_) {
      records = [];
    }
    if (records.isEmpty) {
      records = await DatabaseService.getAllRecords(widget.studentId);
    }
    setState(() {
      _records = records;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.surface,
      appBar: AppBar(
        title: const Text('Attendance History'),
        backgroundColor: AppTheme.primary,
      ),
      body: _loading
          ? const Center(
              child: CircularProgressIndicator(color: AppTheme.accent))
          : _records.isEmpty
              ? _buildEmpty()
              : ListView.builder(
                  padding: const EdgeInsets.all(20),
                  itemCount: _records.length,
                  itemBuilder: (_, i) => _buildRecord(_records[i]),
                ),
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.history_toggle_off_rounded,
              size: 64, color: AppTheme.border),
          const SizedBox(height: 16),
          Text('No records yet',
              style: GoogleFonts.spaceGrotesk(
                  fontSize: 20, fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          Text('Check in to your first class to get started.',
              style: GoogleFonts.dmSans(color: AppTheme.textSecondary)),
        ],
      ),
    );
  }

  Widget _buildRecord(CheckinRecord record) {
    final time = record.checkinTime != null
        ? DateFormat('MMM d, yyyy · h:mm a')
            .format(DateTime.parse(record.checkinTime!))
        : 'Unknown time';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: record.isCompleted
              ? AppTheme.accentGreen.withOpacity(0.3)
              : AppTheme.accentAmber.withOpacity(0.4),
        ),
      ),
      child: ExpansionTile(
        shape: const Border(),
        tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: record.isCompleted
                ? AppTheme.accentGreen.withOpacity(0.1)
                : AppTheme.accentAmber.withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(
            record.isCompleted
                ? Icons.check_circle_rounded
                : Icons.access_time_rounded,
            color: record.isCompleted
                ? AppTheme.accentGreen
                : AppTheme.accentAmber,
            size: 22,
          ),
        ),
        title: Text(
          record.isCompleted ? 'Completed' : 'In Progress',
          style: GoogleFonts.spaceGrotesk(
              fontSize: 15, fontWeight: FontWeight.w700),
        ),
        subtitle: Text(time,
            style: GoogleFonts.dmSans(
                fontSize: 12, color: AppTheme.textSecondary)),
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Divider(),
                const SizedBox(height: 8),
                if (record.mood != null)
                  _detail('Mood', _moodLabel(record.mood!)),
                if (record.previousTopic?.isNotEmpty == true)
                  _detail('Previous Topic', record.previousTopic!),
                if (record.expectedTopic?.isNotEmpty == true)
                  _detail('Expected Topic', record.expectedTopic!),
                if (record.checkinLatitude != null)
                  _detail('Check-in GPS',
                      '${record.checkinLatitude!.toStringAsFixed(4)}, ${record.checkinLongitude!.toStringAsFixed(4)}'),
                if (record.isCompleted) ...[
                  const Divider(),
                  if (record.learnedToday?.isNotEmpty == true)
                    _detail('Learned Today', record.learnedToday!),
                  if (record.feedback?.isNotEmpty == true)
                    _detail('Feedback', record.feedback!),
                  if (record.checkoutTime != null)
                    _detail(
                        'Checked Out',
                        DateFormat('h:mm a')
                            .format(DateTime.parse(record.checkoutTime!))),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _detail(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(label,
                style: GoogleFonts.dmSans(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textSecondary)),
          ),
          Expanded(
            child: Text(value,
                style: GoogleFonts.dmSans(
                    fontSize: 13, color: AppTheme.textPrimary)),
          ),
        ],
      ),
    );
  }

  String _moodLabel(int mood) {
    const labels = [
      '',
      '😞 Terrible',
      '😕 Bad',
      '😐 Okay',
      '🙂 Good',
      '😄 Great'
    ];
    return mood >= 1 && mood <= 5 ? labels[mood] : 'Unknown';
  }
}
