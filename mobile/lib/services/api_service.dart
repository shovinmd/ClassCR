import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/models.dart';

class ApiService {
  // Live Vercel production endpoint
  static String vercelProductionUrl = 'https://server-eta-dun-48.vercel.app/api';

  static String _activeBaseUrl = 'https://server-eta-dun-48.vercel.app/api';

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

  static Future<AttendanceRecord?> fetchTodayAttendance({String classId = 'I-MCA-A', String? date}) async {
    try {
      final url = date != null
          ? '$_activeBaseUrl/attendance/today?classId=$classId&date=$date'
          : '$_activeBaseUrl/attendance/today?classId=$classId';
      final response = await http
          .get(Uri.parse(url))
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
    String? userRole,
    String? userName,
    String? markedByName,
    String? markedByRole,
    bool isLocked = true,
    String? lastModifiedBy,
    bool asstCrVerified = false,
    String? asstCrVerifiedBy,
    String? asstCrVerifiedAt,
    int? periodNo,
    String? periodSubject,
  }) async {
    try {
      final response = await http
          .post(
            Uri.parse('$_activeBaseUrl/attendance'),
            headers: {
              'Content-Type': 'application/json',
              'x-mock-role': userRole ?? 'cr',
              if (userName != null) 'x-user-name': userName,
              'x-class-id': classId,
            },
            body: json.encode({
              'classId': classId,
              'date': date,
              'absentRolls': absentRolls,
              'notes': notes,
              'markedByName': markedByName,
              'markedByRole': markedByRole,
              'isLocked': isLocked,
              'lastModifiedBy': lastModifiedBy,
              'asstCrVerified': asstCrVerified,
              'asstCrVerifiedBy': asstCrVerifiedBy,
              'asstCrVerifiedAt': asstCrVerifiedAt,
              'periodNo': periodNo,
              'periodSubject': periodSubject,
            }),
          )
          .timeout(const Duration(seconds: 4));
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

  // Fetch current class delegation (Advisor, CR, Asst CR, Passcodes)
  static Future<ClassDelegation?> fetchDelegation({String classId = 'I-MCA-A'}) async {
    try {
      final response = await http
          .get(Uri.parse('$_activeBaseUrl/class-delegation/$classId'))
          .timeout(const Duration(seconds: 3));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['delegation'] != null) {
          return ClassDelegation.fromJson(data['delegation']);
        }
      }
    } catch (_) {}
    return null;
  }

  // Admin assigns Class Advisor and sets their passcode
  static Future<bool> adminAssignAdvisor({
    String classId = 'I-MCA-A',
    required String advisorName,
    required String advisorCode,
  }) async {
    try {
      final response = await http
          .post(
            Uri.parse('$_activeBaseUrl/admin/assign-advisor'),
            headers: {'Content-Type': 'application/json'},
            body: json.encode({
              'classId': classId,
              'advisorName': advisorName,
              'advisorCode': advisorCode,
            }),
          )
          .timeout(const Duration(seconds: 3));
      return response.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  // Advisor appoints CR & Assistant CRs and configures passcodes
  static Future<bool> advisorDelegate({
    String classId = 'I-MCA-A',
    int? crRoll,
    String? crName,
    String? crCode,
    int? maleAsstRoll,
    String? maleAsstName,
    String? maleAsstCode,
    int? femaleAsstRoll,
    String? femaleAsstName,
    String? femaleAsstCode,
    String? studentCode,
  }) async {
    try {
      final response = await http
          .post(
            Uri.parse('$_activeBaseUrl/advisor/delegate'),
            headers: {'Content-Type': 'application/json'},
            body: json.encode({
              'classId': classId,
              if (crRoll != null) 'crRoll': crRoll,
              if (crName != null) 'crName': crName,
              if (crCode != null) 'crCode': crCode,
              if (maleAsstRoll != null) 'maleAsstRoll': maleAsstRoll,
              if (maleAsstName != null) 'maleAsstName': maleAsstName,
              if (maleAsstCode != null) 'maleAsstCode': maleAsstCode,
              if (femaleAsstRoll != null) 'femaleAsstRoll': femaleAsstRoll,
              if (femaleAsstName != null) 'femaleAsstName': femaleAsstName,
              if (femaleAsstCode != null) 'femaleAsstCode': femaleAsstCode,
              if (studentCode != null) 'studentCode': studentCode,
            }),
          )
          .timeout(const Duration(seconds: 3));
      return response.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  // Verify Passcode against backend dynamic delegation store
  static Future<Map<String, dynamic>?> verifyRolePasscode({
    String classId = 'I-MCA-A',
    required String role,
    required String code,
    String? gender,
    int? rollNo,
    String? staffName,
  }) async {
    try {
      final response = await http
          .post(
            Uri.parse('$_activeBaseUrl/auth/verify-code'),
            headers: {'Content-Type': 'application/json'},
            body: json.encode({
              'classId': classId,
              'role': role,
              'code': code,
              'gender': gender,
              'rollNo': rollNo,
              'staffName': staffName,
            }),
          )
          .timeout(const Duration(seconds: 3));
      if (response.statusCode == 200) {
        return json.decode(response.body) as Map<String, dynamic>;
      }
    } catch (_) {}
    return null;
  }
}
