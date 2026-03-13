import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/checkin_record.dart';

class DatabaseService {
  static Database? _db;
  static const _webStorageKey = 'checkin_records_cache';

  static Future<Database> get database async {
    if (kIsWeb) {
      throw UnsupportedError('Database getter is not used on web.');
    }
    if (_db != null) return _db!;
    _db = await _initDatabase();
    return _db!;
  }

  static Future<Database> _initDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'smart_class.db');

    return await openDatabase(
      path,
      version: 1,
      onCreate: _onCreate,
    );
  }

  static Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE checkin_records (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        student_id TEXT NOT NULL,
        checkin_time TEXT,
        checkin_latitude REAL,
        checkin_longitude REAL,
        checkin_qr_value TEXT,
        previous_topic TEXT,
        expected_topic TEXT,
        mood INTEGER,
        checkout_time TEXT,
        checkout_latitude REAL,
        checkout_longitude REAL,
        checkout_qr_value TEXT,
        learned_today TEXT,
        feedback TEXT,
        is_completed INTEGER DEFAULT 0
      )
    ''');
  }

  static Future<int> insertCheckin(CheckinRecord record) async {
    if (kIsWeb) {
      final records = await _readWebRecords();
      final nextId = records.isEmpty
          ? 1
          : records
                  .map((item) => (item['id'] as num?)?.toInt() ?? 0)
                  .fold<int>(0, (max, id) => id > max ? id : max) +
              1;
      records.add({...record.toMap(), 'id': nextId});
      await _writeWebRecords(records);
      return nextId;
    }

    final db = await database;
    return await db.insert('checkin_records', record.toMap());
  }

  static Future<void> updateCheckout(int id, CheckoutData data) async {
    if (kIsWeb) {
      final records = await _readWebRecords();
      final index = records.indexWhere(
        (item) => ((item['id'] as num?)?.toInt() ?? -1) == id,
      );
      if (index == -1) return;
      records[index] = {
        ...records[index],
        ...data.toMap(),
      };
      await _writeWebRecords(records);
      return;
    }

    final db = await database;
    await db.update(
      'checkin_records',
      data.toMap(),
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  static Future<List<CheckinRecord>> getAllRecords(String studentId) async {
    if (kIsWeb) {
      final records = await _readWebRecords();
      final filtered = records
          .where((item) => item['student_id'] == studentId)
          .map(CheckinRecord.fromMap)
          .toList();
      filtered.sort((a, b) => (b.checkinTime ?? '').compareTo(a.checkinTime ?? ''));
      return filtered;
    }

    final db = await database;
    final maps = await db.query(
      'checkin_records',
      where: 'student_id = ?',
      whereArgs: [studentId],
      orderBy: 'checkin_time DESC',
    );
    return maps.map((m) => CheckinRecord.fromMap(m)).toList();
  }

  static Future<CheckinRecord?> getLatestOpenCheckin(String studentId) async {
    if (kIsWeb) {
      final records = await getAllRecords(studentId);
      final open = records.where((record) => !record.isCompleted).toList();
      if (open.isEmpty) return null;
      open.sort((a, b) => (b.checkinTime ?? '').compareTo(a.checkinTime ?? ''));
      return open.first;
    }

    final db = await database;
    final maps = await db.query(
      'checkin_records',
      where: 'student_id = ? AND is_completed = 0',
      whereArgs: [studentId],
      orderBy: 'checkin_time DESC',
      limit: 1,
    );
    if (maps.isEmpty) return null;
    return CheckinRecord.fromMap(maps.first);
  }

  static Future<void> clearAllOpenCheckins(String studentId) async {
    if (kIsWeb) {
      final records = await _readWebRecords();
      var changed = false;
      final now = DateTime.now().toIso8601String();

      for (var i = 0; i < records.length; i++) {
        final item = records[i];
        if (item['student_id'] != studentId) continue;
        final isCompleted = (item['is_completed'] ?? 0) == 1;
        if (isCompleted) continue;

        records[i] = {
          ...item,
          'is_completed': 1,
          'checkout_time': item['checkout_time'] ?? now,
        };
        changed = true;
      }

      if (changed) {
        await _writeWebRecords(records);
      }
      return;
    }

    final db = await database;
    await db.update(
      'checkin_records',
      {
        'is_completed': 1,
        'checkout_time': DateTime.now().toIso8601String(),
      },
      where: 'student_id = ? AND is_completed = 0',
      whereArgs: [studentId],
    );
  }

  static Future<List<Map<String, dynamic>>> _readWebRecords() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_webStorageKey);
    if (raw == null || raw.isEmpty) return [];

    final decoded = jsonDecode(raw);
    if (decoded is! List) return [];

    return decoded
        .whereType<Map>()
        .map((item) => item.map(
              (key, value) => MapEntry(key.toString(), value),
            ))
        .toList();
  }

  static Future<void> _writeWebRecords(List<Map<String, dynamic>> records) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_webStorageKey, jsonEncode(records));
  }
}
