import 'package:shared_preferences/shared_preferences.dart';

class StudentService {
  static const _keyStudentId = 'student_id';
  static const _keyActiveCheckinDocId = 'active_checkin_doc_id';

  static Future<String?> getStudentId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyStudentId);
  }

  static Future<void> saveStudentId(String id) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyStudentId, id);
  }

  static Future<bool> hasStudentId() async {
    final id = await getStudentId();
    return id != null && id.isNotEmpty;
  }

  static Future<void> clearStudentId() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyStudentId);
    await prefs.remove(_keyActiveCheckinDocId);
  }

  static Future<String?> getActiveCheckinDocId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyActiveCheckinDocId);
  }

  static Future<void> saveActiveCheckinDocId(String docId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyActiveCheckinDocId, docId);
  }

  static Future<void> clearActiveCheckinDocId() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyActiveCheckinDocId);
  }
}
