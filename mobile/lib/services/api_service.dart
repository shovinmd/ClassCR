import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/models.dart';

class ApiService {
  // Set your Vercel deployment URL here once deployed (e.g. 'https://classcr-server.vercel.app/api')
  static String vercelProductionUrl = '';

  static String _activeBaseUrl = 'http://localhost:5000/api';

  static String get baseUrl => _activeBaseUrl;

  static Future<void> setBaseUrl(String url) async {
    final cleanUrl = url.endsWith('/') ? url.substring(0, url.length - 1) : url;
    _activeBaseUrl = cleanUrl.endsWith('/api') ? cleanUrl : '$cleanUrl/api';
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('classcr_backend_url', _activeBaseUrl);
  }

  static Future<bool> isBackendAvailable() async {
    final prefs = await SharedPreferences.getInstance();
    final savedUrl = prefs.getString('classcr_backend_url');

    final candidateUrls = [
      if (savedUrl != null && savedUrl.isNotEmpty) savedUrl,
      if (vercelProductionUrl.isNotEmpty) vercelProductionUrl,
      'http://localhost:5000/api',
      'http://10.0.2.2:5000/api',
    ];

    for (final url in candidateUrls) {
      try {
        final response = await http
            .get(Uri.parse('$url/health'))
            .timeout(const Duration(seconds: 2));
        if (response.statusCode == 200) {
          _activeBaseUrl = url;
          return true;
        }
      } catch (_) {}
    }
    return false;
  }

  static Future<List<Student>?> fetchStudents({String classId = 'I-MCA-A'}) async {
    try {
      final response = await http
          .get(Uri.parse('$_activeBaseUrl/students?classId=$classId'))
          .timeout(const Duration(seconds: 3));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final list = (data['students'] as List)
            .map((s) => Student.fromJson(s))
            .toList();
        return list;
      }
    } catch (_) {}
    return null;
  }

  static Future<List<AttendanceRecord>?> fetchAttendanceHistory({String classId = 'I-MCA-A'}) async {
    try {
      final response = await http
          .get(Uri.parse('$_activeBaseUrl/attendance/history?classId=$classId'))
          .timeout(const Duration(seconds: 3));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final list = (data['history'] as List)
            .map((r) => AttendanceRecord.fromJson(r))
            .toList();
        return list;
      }
    } catch (_) {}
    return null;
  }

  static Future<AttendanceRecord?> fetchTodayAttendance({String classId = 'I-MCA-A'}) async {
    try {
      final response = await http
          .get(Uri.parse('$_activeBaseUrl/attendance/today?classId=$classId'))
          .timeout(const Duration(seconds: 3));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['attendance'] != null) {
          return AttendanceRecord.fromJson(data['attendance']);
        }
      }
    } catch (_) {}
    return null;
  }

  static Future<bool> submitAttendance({
    required String classId,
    required String date,
    required List<int> absentRolls,
    String? notes,
  }) async {
    try {
      final response = await http
          .post(
            Uri.parse('$_activeBaseUrl/attendance'),
            headers: {
              'Content-Type': 'application/json',
              'x-mock-role': 'cr',
            },
            body: json.encode({
              'classId': classId,
              'date': date,
              'absentRolls': absentRolls,
              'notes': notes,
            }),
          )
          .timeout(const Duration(seconds: 3));
      return response.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  static Future<void> saveOfflineQueue(List<AttendanceRecord> queue) async {
    final prefs = await SharedPreferences.getInstance();
    final strList = queue.map((r) => json.encode(r.toJson())).toList();
    await prefs.setStringList('offline_attendance_queue', strList);
  }

  static Future<List<AttendanceRecord>> loadOfflineQueue() async {
    final prefs = await SharedPreferences.getInstance();
    final strList = prefs.getStringList('offline_attendance_queue');
    if (strList == null) return [];
    return strList
        .map((s) => AttendanceRecord.fromJson(json.decode(s)))
        .toList();
  }
}
