import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/models.dart';
import '../data/mca_students.dart';
import '../services/api_service.dart';

class ClassCRState extends ChangeNotifier {
  // Offline Passcodes for First-Time Verification
  static const String codeCR = 'CR2026';
  static const String codeAssistantCR = 'ACR2026';
  static const String codeAdvisor = 'ADV2026';

  // Setup completion state
  bool _isSetupDone = false;
  bool get isSetupDone => _isSetupDone;

  // Active User State
  AppUser _currentUser = const AppUser(
    id: 'user_cr_1',
    name: 'MUTHUVEL R (CR)',
    email: 'cr@classcr.edu',
    role: UserRole.cr,
    classId: 'I-MCA-A',
    studentId: '260320',
    department: 'MCA',
  );

  AppUser get currentUser => _currentUser;
  UserRole get currentRole => _currentUser.role;

  // Students list (52 items)
  List<Student> _students = List.from(kInitialMcaStudents);
  List<Student> get students => _students;

  // Today's attendance state
  String _todayDate = '2026-09-18';
  String get todayDate => _todayDate;

  // Set of absent roll numbers (default 9 absentees from prompt example: 43 present, 9 absent)
  final Set<int> _absentRolls = {13, 25, 27, 28, 31, 34, 37, 44, 52};
  Set<int> get absentRolls => _absentRolls;

  int get totalCount => _students.length; // 52
  int get absentCount => _absentRolls.length; // 9
  int get presentCount => totalCount - absentCount; // 43

  // Attendance History
  List<AttendanceRecord> _history = List.from(kInitialHistoryRecords);
  List<AttendanceRecord> get history => _history;

  // Offline / Sync status
  bool _isOnline = true;
  bool get isOnline => _isOnline;
  int _pendingSyncCount = 0;
  int get pendingSyncCount => _pendingSyncCount;
  bool _isSyncing = false;
  bool get isSyncing => _isSyncing;

  String? _crNotes = 'Morning session attendance verified and submitted to advisor.';
  String? get crNotes => _crNotes;

  ClassCRState() {
    _loadSetupAndInit();
  }

  Future<void> _loadSetupAndInit() async {
    final prefs = await SharedPreferences.getInstance();
    _isSetupDone = prefs.getBool('classcr_setup_done') ?? false;

    if (_isSetupDone) {
      final roleStr = prefs.getString('classcr_user_role') ?? 'cr';
      final name = prefs.getString('classcr_user_name') ?? 'CR User';
      final classId = prefs.getString('classcr_class_id') ?? 'I-MCA-A';
      final studentId = prefs.getString('classcr_student_id');

      UserRole role = UserRole.cr;
      if (roleStr == 'assistantCr') role = UserRole.assistantCr;
      if (roleStr == 'advisor') role = UserRole.advisor;
      if (roleStr == 'student') role = UserRole.student;
      if (roleStr == 'admin') role = UserRole.admin;

      _currentUser = AppUser(
        id: 'user_${role.name}',
        name: name,
        email: '${role.name}@classcr.edu',
        role: role,
        classId: classId,
        studentId: studentId,
        department: 'MCA',
      );
    }

    _checkBackendAndLoad();
  }

  Future<void> _checkBackendAndLoad() async {
    final available = await ApiService.isBackendAvailable();
    _isOnline = available;
    if (available) {
      final remoteStudents = await ApiService.fetchStudents(classId: 'I-MCA-A');
      if (remoteStudents != null && remoteStudents.isNotEmpty) {
        _students = remoteStudents;
      }
      final remoteHistory = await ApiService.fetchAttendanceHistory(classId: 'I-MCA-A');
      if (remoteHistory != null && remoteHistory.isNotEmpty) {
        _history = remoteHistory;
      }
    }
    final queue = await ApiService.loadOfflineQueue();
    _pendingSyncCount = queue.length;
    notifyListeners();
  }

  // Complete First Time Onboarding Setup
  Future<void> completeSetup({
    required UserRole role,
    required String name,
    required String classId,
    String? studentId,
  }) async {
    _currentUser = AppUser(
      id: 'user_${role.name}',
      name: name,
      email: '${role.name}@classcr.edu',
      role: role,
      classId: classId,
      studentId: studentId,
      department: 'MCA',
    );
    _isSetupDone = true;

    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('classcr_setup_done', true);
    await prefs.setString('classcr_user_role', role.name);
    await prefs.setString('classcr_user_name', name);
    await prefs.setString('classcr_class_id', classId);
    if (studentId != null) {
      await prefs.setString('classcr_student_id', studentId);
    }

    notifyListeners();
  }

  // Reset Onboarding Setup (to test setup flow again anytime)
  Future<void> resetSetup() async {
    _isSetupDone = false;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('classcr_setup_done');
    await prefs.remove('classcr_user_role');
    await prefs.remove('classcr_user_name');
    await prefs.remove('classcr_class_id');
    await prefs.remove('classcr_student_id');
    notifyListeners();
  }

  // Quick Mark Actions
  bool isAbsent(int rollNo) => _absentRolls.contains(rollNo);
  bool isPresent(int rollNo) => !_absentRolls.contains(rollNo);

  void toggleStatus(int rollNo) {
    if (_absentRolls.contains(rollNo)) {
      _absentRolls.remove(rollNo);
    } else {
      _absentRolls.add(rollNo);
    }
    notifyListeners();
  }

  void markAllPresent() {
    _absentRolls.clear();
    notifyListeners();
  }

  void markAllAbsent() {
    _absentRolls.addAll(_students.map((s) => s.rollNo));
    notifyListeners();
  }

  void updateNotes(String notes) {
    _crNotes = notes;
    notifyListeners();
  }

  // Submit Attendance
  Future<bool> submitAttendance({String? notes}) async {
    _crNotes = notes ?? _crNotes;
    final record = AttendanceRecord(
      id: 'att_${_todayDate.replaceAll('-', '')}',
      classId: _currentUser.classId ?? 'I-MCA-A',
      date: _todayDate,
      totalStudents: totalCount,
      presentCount: presentCount,
      absentCount: absentCount,
      absentRolls: _absentRolls.toList()..sort(),
      status: 'submitted',
      submittedAt: '09:18 AM',
      notes: _crNotes,
      isSynced: _isOnline,
    );

    // Update in local history
    final existingIndex = _history.indexWhere((r) => r.date == _todayDate);
    if (existingIndex >= 0) {
      _history[existingIndex] = record;
    } else {
      _history.insert(0, record);
    }

    if (_isOnline) {
      final success = await ApiService.submitAttendance(
        classId: record.classId,
        date: record.date,
        absentRolls: record.absentRolls,
        notes: record.notes,
      );
      if (!success) {
        // Queue offline
        await _queueRecord(record);
      }
    } else {
      await _queueRecord(record);
    }

    notifyListeners();
    return true;
  }

  Future<void> _queueRecord(AttendanceRecord record) async {
    final queue = await ApiService.loadOfflineQueue();
    queue.removeWhere((r) => r.date == record.date);
    queue.add(record.copyWith(isSynced: false));
    await ApiService.saveOfflineQueue(queue);
    _pendingSyncCount = queue.length;
    notifyListeners();
  }

  Future<void> syncPendingRecords() async {
    if (_isSyncing) return;
    _isSyncing = true;
    notifyListeners();

    final queue = await ApiService.loadOfflineQueue();
    if (queue.isEmpty) {
      _isSyncing = false;
      notifyListeners();
      return;
    }

    bool allSuccess = true;
    for (final rec in queue) {
      final success = await ApiService.submitAttendance(
        classId: rec.classId,
        date: rec.date,
        absentRolls: rec.absentRolls,
        notes: rec.notes,
      );
      if (!success) {
        allSuccess = false;
        break;
      }
    }

    if (allSuccess) {
      await ApiService.saveOfflineQueue([]);
      _pendingSyncCount = 0;
      _isOnline = true;
    }

    _isSyncing = false;
    notifyListeners();
  }

  // Switch role for full interactive demo
  void switchRole(UserRole newRole) {
    switch (newRole) {
      case UserRole.cr:
        _currentUser = const AppUser(
          id: 'user_cr_1',
          name: 'MUTHUVEL R (CR)',
          email: 'cr@classcr.edu',
          role: UserRole.cr,
          classId: 'I-MCA-A',
          studentId: '260320',
          department: 'MCA',
        );
        break;
      case UserRole.assistantCr:
        _currentUser = const AppUser(
          id: 'user_acr_1',
          name: 'SHOVIN MICHEL DAVID (Asst. CR)',
          email: 'asstcr@classcr.edu',
          role: UserRole.assistantCr,
          classId: 'I-MCA-A',
          studentId: '260274',
          department: 'MCA',
        );
        break;
      case UserRole.advisor:
        _currentUser = const AppUser(
          id: 'user_adv_1',
          name: 'Dr. K. Senthil Nathan',
          email: 'advisor@classcr.edu',
          role: UserRole.advisor,
          classId: 'I-MCA-A',
          department: 'MCA',
        );
        break;
      case UserRole.student:
        _currentUser = const AppUser(
          id: 'user_stu_1',
          name: 'DHIVYALAKSHMI H',
          email: 'student@classcr.edu',
          role: UserRole.student,
          classId: 'I-MCA-A',
          studentId: '260311',
          department: 'MCA',
        );
        break;
      case UserRole.admin:
        _currentUser = const AppUser(
          id: 'user_adm_1',
          name: 'College Dean / Administrator',
          email: 'admin@classcr.edu',
          role: UserRole.admin,
          department: 'All Departments',
        );
        break;
    }
    notifyListeners();
  }

  // Generate Smart Report formatted text
  String generateSmartReportText() {
    final sortedAbsentees = _absentRolls.toList()..sort();
    final buffer = StringBuffer();
    buffer.writeln("Attendance Report");
    buffer.writeln("I MCA");
    buffer.writeln("Date: ${_formatDateForReport(_todayDate)}");
    buffer.writeln();
    buffer.writeln("Total Students: $totalCount");
    buffer.writeln("Present: $presentCount");
    buffer.writeln("Absent: $absentCount");
    buffer.writeln();
    buffer.writeln("Absent Students:");
    buffer.writeln();

    if (sortedAbsentees.isEmpty) {
      buffer.writeln("None! 100% Attendance 🎉");
    } else {
      for (final rNo in sortedAbsentees) {
        final st = _students.firstWhere(
          (s) => s.rollNo == rNo,
          orElse: () => Student(rollNo: rNo, enrollmentNo: 'N/A', name: 'Student $rNo'),
        );
        buffer.writeln("${st.rollNo}. ${st.name}");
        buffer.writeln("    ${st.enrollmentNo}");
        buffer.writeln();
      }
    }

    buffer.writeln("Generated via ClassCR 📱");
    return buffer.toString().trim();
  }

  String _formatDateForReport(String yyyyMmDd) {
    try {
      final parts = yyyyMmDd.split('-');
      if (parts.length == 3) {
        return "${parts[2]}/${parts[1]}/${parts[0]}";
      }
    } catch (_) {}
    return yyyyMmDd;
  }
}
