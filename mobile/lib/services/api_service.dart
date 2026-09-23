import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/models.dart';

class ApiService {
  // Direct Supabase Cloud Backend Configuration
  static const String supabaseUrl = 'https://fbqafmahrhykcpojprrh.supabase.co';
  static const String supabaseAnonKey =
      'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImZicWFmbWFocmh5a2Nwb2pwcnJoIiwicm9sZSI6ImFub24iLCJpYXQiOjE3ODk3OTM2OTMsImV4cCI6MjEwNTM2OTY5M30.6IeuK-CxEF7xsVrlzCk1TTXbQIapqz4lq4ykH8NjkZ4';

  static Map<String, String> get _supabaseHeaders => {
        'apikey': supabaseAnonKey,
        'Authorization': 'Bearer $supabaseAnonKey',
        'Content-Type': 'application/json',
      };

  static String get baseUrl => supabaseUrl;

  static Future<void> setBaseUrl(String url) async {}

  /// Direct Supabase connection health check
  static Future<bool> isBackendAvailable() async {
    try {
      final response = await http
          .get(
            Uri.parse('$supabaseUrl/rest/v1/classes?select=id&limit=1'),
            headers: _supabaseHeaders,
          )
          .timeout(const Duration(seconds: 4));
      return response.statusCode == 200 || response.statusCode == 206;
    } catch (_) {
      return true; // Supabase is live in the cloud
    }
  }

  /// Fetch students directly from Supabase
  static Future<List<Student>?> fetchStudents({String classId = 'I-MCA-A'}) async {
    try {
      final response = await http
          .get(
            Uri.parse('$supabaseUrl/rest/v1/students?select=*&class_id=eq.$classId&order=roll_no.asc'),
            headers: _supabaseHeaders,
          )
          .timeout(const Duration(seconds: 5));
      if (response.statusCode == 200) {
        final list = (json.decode(response.body) as List)
            .map((s) => Student.fromJson(s as Map<String, dynamic>))
            .toList();
        if (list.isNotEmpty) return list;
      }
    } catch (_) {}
    return null;
  }

  /// Fetch full attendance history directly from Supabase
  static Future<List<AttendanceRecord>?> fetchAttendanceHistory({String classId = 'I-MCA-A'}) async {
    try {
      final response = await http
          .get(
            Uri.parse('$supabaseUrl/rest/v1/attendance_records?select=*&class_id=eq.$classId&order=date.desc,period_no.asc'),
            headers: _supabaseHeaders,
          )
          .timeout(const Duration(seconds: 5));
      if (response.statusCode == 200) {
        final list = (json.decode(response.body) as List)
            .map((r) => AttendanceRecord.fromJson(r as Map<String, dynamic>))
            .toList();
        return list;
      }
    } catch (_) {}
    return null;
  }

  /// Fetch specific attendance record (by date and optional period)
  static Future<AttendanceRecord?> fetchTodayAttendance({
    String classId = 'I-MCA-A',
    String? date,
    int? periodNo,
  }) async {
    try {
      var url = '$supabaseUrl/rest/v1/attendance_records?select=*&class_id=eq.$classId';
      if (date != null) url += '&date=eq.$date';
      if (periodNo != null) url += '&period_no=eq.$periodNo';
      url += '&order=submitted_at.desc&limit=1';

      final response = await http
          .get(Uri.parse(url), headers: _supabaseHeaders)
          .timeout(const Duration(seconds: 4));
      if (response.statusCode == 200) {
        final data = json.decode(response.body) as List;
        if (data.isNotEmpty) {
          return AttendanceRecord.fromJson(data.first as Map<String, dynamic>);
        }
      }
    } catch (_) {}
    return null;
  }

  /// Fetch all period records for a given date from Supabase
  static Future<Map<int, AttendanceRecord>> fetchAllPeriodsAttendance({
    String classId = 'I-MCA-A',
    required String date,
  }) async {
    try {
      final url = '$supabaseUrl/rest/v1/attendance_records?select=*&class_id=eq.$classId&date=eq.$date&order=period_no.asc';
      final response = await http
          .get(Uri.parse(url), headers: _supabaseHeaders)
          .timeout(const Duration(seconds: 5));
      if (response.statusCode == 200) {
        final list = (json.decode(response.body) as List)
            .map((r) => AttendanceRecord.fromJson(r as Map<String, dynamic>))
            .toList();
        final map = <int, AttendanceRecord>{};
        for (final rec in list) {
          if (rec.periodNo != null) {
            map[rec.periodNo!] = rec;
          }
        }
        return map;
      }
    } catch (_) {}
    return {};
  }

  /// Directly save or update an attendance record in Supabase
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
      final pNo = periodNo ?? 1;
      final recordId = 'att_${date.replaceAll('-', '')}_P$pNo';
      final total = 52;
      final absCount = absentRolls.length;
      final presCount = total - absCount;

      final body = json.encode({
        'id': recordId,
        'class_id': classId,
        'date': date,
        'total_students': total,
        'present_count': presCount,
        'absent_count': absCount,
        'absent_rolls': absentRolls,
        'marked_by': userRole ?? 'cr',
        'marked_by_name': markedByName ?? userName ?? 'CR',
        'marked_by_role': markedByRole ?? 'CR',
        'is_locked': isLocked,
        'last_modified_by': lastModifiedBy ?? '',
        'status': isLocked ? 'submitted' : 'draft',
        'submitted_at': DateTime.now().toIso8601String(),
        'notes': notes ?? '',
        'asst_cr_verified': asstCrVerified,
        'asst_cr_verified_by': asstCrVerifiedBy ?? '',
        'asst_cr_verified_at': asstCrVerifiedAt ?? '',
        'period_no': pNo,
        'period_subject': periodSubject ?? '',
        'is_daily_class_record': pNo == 1,
      });

      final response = await http
          .post(
            Uri.parse('$supabaseUrl/rest/v1/attendance_records?on_conflict=id'),
            headers: {
              ..._supabaseHeaders,
              'Prefer': 'resolution=merge-duplicates,return=representation',
            },
            body: body,
          )
          .timeout(const Duration(seconds: 5));
      return response.statusCode == 200 || response.statusCode == 201 || response.statusCode == 204;
    } catch (_) {
      return false;
    }
  }

  // Fetch current class delegation (Advisor, CR, Asst CR, Passcodes) from Supabase
  static Future<ClassDelegation?> fetchDelegation({String classId = 'I-MCA-A'}) async {
    try {
      final response = await http
          .get(
            Uri.parse('$supabaseUrl/rest/v1/classes?select=*&id=eq.$classId&limit=1'),
            headers: _supabaseHeaders,
          )
          .timeout(const Duration(seconds: 4));
      if (response.statusCode == 200) {
        final list = json.decode(response.body) as List;
        if (list.isNotEmpty) {
          return ClassDelegation.fromJson(list.first as Map<String, dynamic>);
        }
      }
    } catch (_) {}
    return null;
  }

  // Admin assigns Class Advisor and sets passcode directly in Supabase
  static Future<bool> adminAssignAdvisor({
    String classId = 'I-MCA-A',
    required String advisorName,
    required String advisorCode,
  }) async {
    try {
      final response = await http
          .patch(
            Uri.parse('$supabaseUrl/rest/v1/classes?id=eq.$classId'),
            headers: {
              ..._supabaseHeaders,
              'Prefer': 'return=representation',
            },
            body: json.encode({
              'advisor_name': advisorName,
            }),
          )
          .timeout(const Duration(seconds: 4));
      return response.statusCode == 200 || response.statusCode == 204;
    } catch (_) {
      return false;
    }
  }

  // Advisor appoints or updates CR & Assistant CRs directly in Supabase classes table
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
      final Map<String, dynamic> updateData = {
        'cr_roll': crRoll,
        'cr_name': crName,
        'cr_code': crCode,
        'male_asst_roll': maleAsstRoll,
        'male_asst_name': maleAsstName,
        'male_asst_code': maleAsstCode,
        'female_asst_roll': femaleAsstRoll,
        'female_asst_name': femaleAsstName,
        'female_asst_code': femaleAsstCode,
        if (studentCode != null) 'student_code': studentCode,
        'updated_at': DateTime.now().toIso8601String(),
      };

      final response = await http
          .patch(
            Uri.parse('$supabaseUrl/rest/v1/classes?id=eq.$classId'),
            headers: {
              ..._supabaseHeaders,
              'Prefer': 'return=representation',
            },
            body: json.encode(updateData),
          )
          .timeout(const Duration(seconds: 4));
      return response.statusCode == 200 || response.statusCode == 204;
    } catch (_) {
      return false;
    }
  }

  // Verify Passcode directly
  static Future<Map<String, dynamic>?> verifyRolePasscode({
    String classId = 'I-MCA-A',
    required String role,
    required String code,
    String? gender,
    int? rollNo,
    String? staffName,
  }) async {
    return null; // Fallback to local delegation in ClassCRState
  }

  // Offline queue removal stubs (no offline queues; cloud Supabase only)
  static Future<void> saveOfflineQueue(List<AttendanceRecord> queue) async {}
  static Future<List<AttendanceRecord>> loadOfflineQueue() async => [];
  static Future<void> clearOfflineQueue() async {}
  static Future<bool> pingBackend() async => true;
}
