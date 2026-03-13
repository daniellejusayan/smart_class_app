import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/checkin_record.dart';

/// Persists check-in and checkout data to Cloud Firestore so every device
/// (student app + instructor portal) shares the same data in real-time.
class FirestoreService {
  static final _db = FirebaseFirestore.instance;

  static String? extractClassCode(String? qrValue) {
    if (qrValue == null || qrValue.isEmpty) return null;
    final parts = qrValue.split('|');
    if (parts.length < 2 || parts.first != 'SMARTCLASS') return null;
    return parts[1];
  }

  static Future<bool> isActiveSessionQr(String qrValue) async {
    final classCode = extractClassCode(qrValue);
    if (classCode == null) return false;

    final snapshot = await _db.collection('active_sessions').doc(classCode).get();
    if (!snapshot.exists) return false;

    final data = snapshot.data();
    if (data == null) return false;
    if ((data['qrValue'] ?? '').toString() != qrValue) return false;

    final expiresAtRaw = data['expiresAt'];
    if (expiresAtRaw == null) return true;

    final expiresAt = DateTime.tryParse(expiresAtRaw.toString());
    if (expiresAt == null) return true;
    return expiresAt.isAfter(DateTime.now());
  }

  static Future<String?> resolveActiveSessionQr(String input) async {
    final value = input.trim();
    if (value.isEmpty) return null;

    final parsedClassCode = extractClassCode(value);
    if (parsedClassCode != null) {
      final isValid = await isActiveSessionQr(value);
      return isValid ? value : null;
    }

    final snapshot = await _db.collection('active_sessions').doc(value).get();
    if (!snapshot.exists) return null;

    final data = snapshot.data();
    if (data == null) return null;

    final qrValue = (data['qrValue'] ?? '').toString();
    if (qrValue.isEmpty) return null;

    final expiresAtRaw = data['expiresAt'];
    if (expiresAtRaw == null) return qrValue;

    final expiresAt = DateTime.tryParse(expiresAtRaw.toString());
    if (expiresAt == null || expiresAt.isAfter(DateTime.now())) {
      return qrValue;
    }

    return null;
  }

  static CheckinRecord _recordFromFirestore(Map<String, dynamic> data) {
    DateTime? _toDateTime(dynamic value) {
      if (value == null) return null;
      if (value is Timestamp) return value.toDate();
      if (value is DateTime) return value;
      if (value is String) return DateTime.tryParse(value);
      return null;
    }

    double? _toDouble(dynamic value) {
      if (value == null) return null;
      if (value is num) return value.toDouble();
      return double.tryParse(value.toString());
    }

    int? _toInt(dynamic value) {
      if (value == null) return null;
      if (value is num) return value.toInt();
      return int.tryParse(value.toString());
    }

    final checkoutTime = _toDateTime(data['checkout_time']);

    return CheckinRecord(
      studentId: (data['student_id'] ?? '').toString(),
      checkinTime: _toDateTime(data['checkin_time'])?.toIso8601String(),
      checkinLatitude: _toDouble(data['checkin_latitude']),
      checkinLongitude: _toDouble(data['checkin_longitude']),
      checkinQrValue: data['checkin_qr_value']?.toString(),
      previousTopic: data['previous_topic']?.toString(),
      expectedTopic: data['expected_topic']?.toString(),
      mood: _toInt(data['mood']),
      checkoutTime: checkoutTime?.toIso8601String(),
      checkoutLatitude: _toDouble(data['checkout_latitude']),
      checkoutLongitude: _toDouble(data['checkout_longitude']),
      checkoutQrValue: data['checkout_qr_value']?.toString(),
      learnedToday: data['learned_today']?.toString(),
      feedback: data['feedback']?.toString(),
      isCompleted: checkoutTime != null,
    );
  }

  /// Saves a new check-in record and returns its Firestore document ID.
  static Future<String> saveCheckin(CheckinRecord record) async {
    final ref = await _db.collection('checkins').add({
      'student_id': record.studentId,
      'checkin_time': record.checkinTime,
      'checkin_latitude': record.checkinLatitude,
      'checkin_longitude': record.checkinLongitude,
      'checkin_qr_value': record.checkinQrValue,
      'previous_topic': record.previousTopic,
      'expected_topic': record.expectedTopic,
      'mood': record.mood,
      'checkout_time': null,
      'checkout_latitude': null,
      'checkout_longitude': null,
      'checkout_qr_value': null,
      'learned_today': null,
      'feedback': null,
    });
    return ref.id;
  }

  /// Returns a specific open check-in by Firestore doc id, if it belongs to
  /// [studentId] and has not been checked out.
  static Future<CheckinRecord?> getOpenCheckinByDocId(
      String studentId, String docId) async {
    final snapshot = await _db.collection('checkins').doc(docId).get();
    if (!snapshot.exists) return null;

    final data = snapshot.data();
    if (data == null) return null;

    if ((data['student_id'] ?? '').toString() != studentId) return null;
    if (data['checkout_time'] != null) return null;

    return _recordFromFirestore(data);
  }

  /// Loads all records for a student from Firestore, newest first.
  static Future<List<CheckinRecord>> getAllRecords(String studentId) async {
    final snapshot = await _db
        .collection('checkins')
        .where('student_id', isEqualTo: studentId)
        .get();

    final records =
        snapshot.docs.map((d) => _recordFromFirestore(d.data())).toList();

    records.sort((a, b) {
      final aTime = a.checkinTime ?? '';
      final bTime = b.checkinTime ?? '';
      return bTime.compareTo(aTime);
    });

    return records;
  }

  /// Returns the most recent record with no checkout_time.
  static Future<CheckinRecord?> getLatestOpenCheckin(String studentId) async {
    final snapshot = await _db
        .collection('checkins')
        .where('student_id', isEqualTo: studentId)
        .get();

    final openRecords = snapshot.docs
        .where((d) => d.data()['checkout_time'] == null)
        .map((d) => _recordFromFirestore(d.data()))
        .toList();

    if (openRecords.isEmpty) return null;

    openRecords.sort((a, b) {
      final aTime = a.checkinTime ?? '';
      final bTime = b.checkinTime ?? '';
      return bTime.compareTo(aTime);
    });

    return openRecords.first;
  }

  /// Finds the most recent open (not yet checked out) check-in for [studentId]
  /// and writes the checkout fields to it.
  static Future<bool> updateCheckout(
      String studentId, CheckoutData data,
      {String? checkinDocId}) async {
    if (checkinDocId != null && checkinDocId.isNotEmpty) {
      final docRef = _db.collection('checkins').doc(checkinDocId);
      final doc = await docRef.get();
      if (doc.exists) {
        final existing = doc.data();
        final belongsToStudent =
            (existing?['student_id'] ?? '').toString() == studentId;
        final isOpen = existing?['checkout_time'] == null;

        if (belongsToStudent && isOpen) {
          await docRef.update({
            'checkout_time': data.checkoutTime,
            'checkout_latitude': data.checkoutLatitude,
            'checkout_longitude': data.checkoutLongitude,
            'checkout_qr_value': data.checkoutQrValue,
            'learned_today': data.learnedToday,
            'feedback': data.feedback,
          });
          return true;
        }
      }
    }

    // Single-field query — no composite index required.
    final snapshot = await _db
        .collection('checkins')
        .where('student_id', isEqualTo: studentId)
        .get();

    // Filter to docs without a checkout_time and pick the most recent.
    final openDocs =
        snapshot.docs.where((d) => d.data()['checkout_time'] == null).toList();
    if (openDocs.isEmpty) return false;

    openDocs.sort((a, b) {
      final aTime = (a.data()['checkin_time'] as String?) ?? '';
      final bTime = (b.data()['checkin_time'] as String?) ?? '';
      return bTime.compareTo(aTime);
    });

    await openDocs.first.reference.update({
      'checkout_time': data.checkoutTime,
      'checkout_latitude': data.checkoutLatitude,
      'checkout_longitude': data.checkoutLongitude,
      'checkout_qr_value': data.checkoutQrValue,
      'learned_today': data.learnedToday,
      'feedback': data.feedback,
    });

    return true;
  }
}
