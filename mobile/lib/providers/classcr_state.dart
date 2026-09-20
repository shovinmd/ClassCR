import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/models.dart';
import '../data/mca_students.dart';
import '../services/api_service.dart';

class ClassCRState extends ChangeNotifier {
  // Default Passcode Constants (Fallback)
  static const String codeCR = 'CR2026';
  static const String codeAssistantCR = 'ACR2026';
  static const String codeAdvisor = 'ADV2026';

  // Active Class Delegation & Passcodes
  ClassDelegation _delegation = const ClassDelegation(classId: 'I-MCA-A');
  ClassDelegation get delegation => _delegation;

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

  // Today's attendance state (Real-Time Dynamic Date)
  static String get _initialDate {
    final now = DateTime.now();
    return "${now.year.toString().padLeft(4, '0')}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}";
  }

  String _todayDate = _initialDate;
  String get todayDate => _todayDate;
  String get formattedTodayDate => _formatDateForReport(_todayDate);

  // Active attendance record for current date
  AttendanceRecord? _currentAttendanceRecord;
  AttendanceRecord? get currentAttendanceRecord => _currentAttendanceRecord;

  // Locked attendance check: once submitted, locked for CR & Asst CR
  bool get isAttendanceLocked =>
      _currentAttendanceRecord != null && (_currentAttendanceRecord!.isLocked || _currentAttendanceRecord!.status == 'submitted');

  // Only advisor or admin can edit attendance after submission
  bool get canModifyAttendance =>
      !isAttendanceLocked || _currentUser.role == UserRole.advisor || _currentUser.role == UserRole.admin;

  // Set of absent roll numbers
  final Set<int> _absentRolls = {};
  Set<int> get absentRolls => _absentRolls;

  int get totalCount => _students.length; // 52
  int get absentCount => _absentRolls.length;
  int get presentCount => totalCount - absentCount;

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

  String? _crNotes = 'Daily attendance session verified and submitted to advisor.';
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

      final gender = prefs.getString('classcr_user_gender');

      _currentUser = AppUser(
        id: 'user_${role.name}',
        name: name,
        email: '${role.name}@classcr.edu',
        role: role,
        classId: classId,
        studentId: studentId,
        department: 'MCA',
        gender: gender,
      );
    }

    _checkBackendAndLoad();
  }

  Future<void> _checkBackendAndLoad() async {
    final available = await ApiService.isBackendAvailable();
    _isOnline = available;
    if (available) {
      final remoteDelegation = await ApiService.fetchDelegation(classId: 'I-MCA-A');
      if (remoteDelegation != null) {
        _delegation = remoteDelegation;
      }
      final remoteStudents = await ApiService.fetchStudents(classId: 'I-MCA-A');
      if (remoteStudents != null && remoteStudents.isNotEmpty) {
        _students = remoteStudents;
      }
      final remoteHistory = await ApiService.fetchAttendanceHistory(classId: 'I-MCA-A');
      if (remoteHistory != null && remoteHistory.isNotEmpty) {
        _history = remoteHistory;
      }
      final remoteToday = await ApiService.fetchTodayAttendance(classId: 'I-MCA-A', date: _todayDate);
      if (remoteToday != null) {
        _currentAttendanceRecord = remoteToday;
        _absentRolls.clear();
        _absentRolls.addAll(remoteToday.absentRolls);
        _crNotes = remoteToday.notes;
      } else {
        await _loadAttendanceForDate(_todayDate);
      }
    } else {
      await _loadAttendanceForDate(_todayDate);
    }
    final queue = await ApiService.loadOfflineQueue();
    _pendingSyncCount = queue.length;
    notifyListeners();
  }

  // Switch / pick date dynamically
  Future<void> setDate(String newDate) async {
    if (_todayDate == newDate) return;
    _todayDate = newDate;
    await _loadAttendanceForDate(newDate);
    notifyListeners();
  }

  Future<void> _loadAttendanceForDate(String date) async {
    // 1. Check in local history
    final existing = _history.where((r) => r.date == date).toList();
    if (existing.isNotEmpty) {
      _currentAttendanceRecord = existing.first;
      _absentRolls.clear();
      _absentRolls.addAll(_currentAttendanceRecord!.absentRolls);
      _crNotes = _currentAttendanceRecord!.notes;
      return;
    }

    // 2. Check remote backend if online
    if (_isOnline) {
      final remote = await ApiService.fetchTodayAttendance(classId: _currentUser.classId ?? 'I-MCA-A', date: date);
      if (remote != null) {
        _currentAttendanceRecord = remote;
        _absentRolls.clear();
        _absentRolls.addAll(remote.absentRolls);
        _crNotes = remote.notes;
        return;
      }
    }

    // 3. Fresh unsubmitted date
    _currentAttendanceRecord = null;
    _absentRolls.clear();
    _crNotes = 'Daily attendance session verified and submitted to advisor.';
  }

  // Admin assigns Class Advisor and sets passcode
  Future<bool> adminAssignAdvisor({
    String classId = 'I-MCA-A',
    required String advisorName,
    required String advisorCode,
  }) async {
    _delegation = ClassDelegation(
      classId: classId,
      advisorName: advisorName,
      advisorCode: advisorCode.toUpperCase(),
      crRoll: _delegation.crRoll,
      crName: _delegation.crName,
      crCode: _delegation.crCode,
      maleAsstRoll: _delegation.maleAsstRoll,
      maleAsstName: _delegation.maleAsstName,
      maleAsstCode: _delegation.maleAsstCode,
      femaleAsstRoll: _delegation.femaleAsstRoll,
      femaleAsstName: _delegation.femaleAsstName,
      femaleAsstCode: _delegation.femaleAsstCode,
      studentCode: _delegation.studentCode,
    );
    notifyListeners();
    return await ApiService.adminAssignAdvisor(
      classId: classId,
      advisorName: advisorName,
      advisorCode: advisorCode,
    );
  }

  // Advisor sets CR & Asst CRs and their passcodes
  Future<bool> advisorDelegate({
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
    _delegation = ClassDelegation(
      classId: classId,
      advisorName: _delegation.advisorName,
      advisorCode: _delegation.advisorCode,
      crRoll: crRoll ?? _delegation.crRoll,
      crName: crName ?? _delegation.crName,
      crCode: (crCode ?? _delegation.crCode).toUpperCase(),
      maleAsstRoll: maleAsstRoll ?? _delegation.maleAsstRoll,
      maleAsstName: maleAsstName ?? _delegation.maleAsstName,
      maleAsstCode: (maleAsstCode ?? _delegation.maleAsstCode).toUpperCase(),
      femaleAsstRoll: femaleAsstRoll ?? _delegation.femaleAsstRoll,
      femaleAsstName: femaleAsstName ?? _delegation.femaleAsstName,
      femaleAsstCode: (femaleAsstCode ?? _delegation.femaleAsstCode).toUpperCase(),
      studentCode: (studentCode ?? _delegation.studentCode).toUpperCase(),
    );
    notifyListeners();
    return await ApiService.advisorDelegate(
      classId: classId,
      crRoll: crRoll,
      crName: crName,
      crCode: crCode,
      maleAsstRoll: maleAsstRoll,
      maleAsstName: maleAsstName,
      maleAsstCode: maleAsstCode,
      femaleAsstRoll: femaleAsstRoll,
      femaleAsstName: femaleAsstName,
      femaleAsstCode: femaleAsstCode,
      studentCode: studentCode,
    );
  }

  // Dynamic role passcode verification
  Future<Map<String, dynamic>> verifyRolePasscode({
    String classId = 'I-MCA-A',
    required UserRole role,
    required String code,
    String? gender,
  }) async {
    final entered = code.trim().toUpperCase();

    // 1. Try remote verification
    final remoteRes = await ApiService.verifyRolePasscode(
      classId: classId,
      role: role.name,
      code: entered,
      gender: gender,
    );
    if (remoteRes != null) {
      return remoteRes;
    }

    // 2. Offline fallback verification
    if (role == UserRole.admin) {
      if (entered == 'ADMIN2026' || entered == 'ADM2026') {
        return {'valid': true, 'role': 'admin', 'name': 'College Dean / Administrator', 'classId': classId};
      }
    } else if (role == UserRole.advisor) {
      if (entered == _delegation.advisorCode || entered == 'ADV2026' || entered == 'NAVI2026') {
        return {'valid': true, 'role': 'advisor', 'name': _delegation.advisorName, 'classId': classId};
      }
    } else if (role == UserRole.cr) {
      if (entered == _delegation.crCode || entered == 'CR2026') {
        return {'valid': true, 'role': 'cr', 'name': _delegation.crName, 'rollNo': _delegation.crRoll, 'classId': classId, 'gender': 'M'};
      }
    } else if (role == UserRole.assistantCr) {
      final matchMale = entered == _delegation.maleAsstCode || entered == 'ACR2026' || entered == 'MACR2026';
      final matchFemale = entered == _delegation.femaleAsstCode || entered == 'ACR2026' || entered == 'FACR2026';
      if (gender == 'F' || (matchFemale && !matchMale)) {
        if (matchFemale || entered == 'ACR2026') {
          return {'valid': true, 'role': 'assistantCr', 'name': _delegation.femaleAsstName, 'rollNo': _delegation.femaleAsstRoll, 'classId': classId, 'gender': 'F'};
        }
      } else if (matchMale || matchFemale) {
        return {
          'valid': true,
          'role': 'assistantCr',
          'name': gender == 'F' ? _delegation.femaleAsstName : _delegation.maleAsstName,
          'rollNo': gender == 'F' ? _delegation.femaleAsstRoll : _delegation.maleAsstRoll,
          'classId': classId,
          'gender': gender ?? 'M',
        };
      }
    } else if (role == UserRole.student) {
      if (entered == _delegation.studentCode || entered == 'STU2026' || entered == '123456') {
        return {'valid': true, 'role': 'student', 'classId': classId};
      }
    }

    return {'valid': false, 'error': 'Invalid verification passcode'};
  }

  // Complete First Time Onboarding Setup
  Future<void> completeSetup({
    required UserRole role,
    required String name,
    required String classId,
    String? studentId,
    String? gender,
  }) async {
    _currentUser = AppUser(
      id: 'user_${role.name}',
      name: name,
      email: '${role.name}@classcr.edu',
      role: role,
      classId: classId,
      studentId: studentId,
      department: 'MCA',
      gender: gender,
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
    if (gender != null) {
      await prefs.setString('classcr_user_gender', gender);
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
    await prefs.remove('classcr_user_gender');
    notifyListeners();
  }

  // Quick Section Mark Actions (for Male/Female Cross-Checking)
  void markSectionPresent({required bool isFemale}) {
    if (!canModifyAttendance) return;
    final rolls = _students.where((s) => s.isFemale == isFemale).map((s) => s.rollNo).toSet();
    _absentRolls.removeAll(rolls);
    notifyListeners();
  }

  void markSectionAbsent({required bool isFemale}) {
    if (!canModifyAttendance) return;
    final rolls = _students.where((s) => s.isFemale == isFemale).map((s) => s.rollNo).toSet();
    _absentRolls.addAll(rolls);
    notifyListeners();
  }

  // Quick Mark Actions
  bool isAbsent(int rollNo) => _absentRolls.contains(rollNo);
  bool isPresent(int rollNo) => !_absentRolls.contains(rollNo);

  bool toggleStatus(int rollNo) {
    if (!canModifyAttendance) return false;
    if (_absentRolls.contains(rollNo)) {
      _absentRolls.remove(rollNo);
    } else {
      _absentRolls.add(rollNo);
    }
    notifyListeners();
    return true;
  }

  bool markAllPresent() {
    if (!canModifyAttendance) return false;
    _absentRolls.clear();
    notifyListeners();
    return true;
  }

  bool markAllAbsent() {
    if (!canModifyAttendance) return false;
    _absentRolls.addAll(_students.map((s) => s.rollNo));
    notifyListeners();
    return true;
  }

  void updateNotes(String notes) {
    _crNotes = notes;
    notifyListeners();
  }

  // Submit Attendance (Sets isLocked: true and records author attribution)
  Future<bool> submitAttendance({String? notes}) async {
    _crNotes = notes ?? _crNotes;
    final authorName = _currentUser.name;
    final authorRole = _currentUser.roleDisplayName;

    final record = AttendanceRecord(
      id: 'att_${_todayDate.replaceAll('-', '')}',
      classId: _currentUser.classId ?? 'I-MCA-A',
      date: _todayDate,
      totalStudents: totalCount,
      presentCount: presentCount,
      absentCount: absentCount,
      absentRolls: _absentRolls.toList()..sort(),
      markedByName: authorName,
      markedByRole: authorRole,
      isLocked: true,
      lastModifiedBy: _currentAttendanceRecord?.lastModifiedBy,
      status: 'submitted',
      submittedAt: _currentAttendanceRecord?.submittedAt ?? '09:18 AM',
      notes: _crNotes,
      isSynced: _isOnline,
    );

    _currentAttendanceRecord = record;

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
        userRole: _currentUser.role.name,
        userName: _currentUser.name,
        markedByName: authorName,
        markedByRole: authorRole,
        isLocked: true,
        lastModifiedBy: record.lastModifiedBy,
      );
      if (!success) {
        await _queueRecord(record);
      }
    } else {
      await _queueRecord(record);
    }

    notifyListeners();
    return true;
  }

  // Advisor modifies and approves attendance after submission
  Future<bool> saveAdvisorAttendanceOverride({String? notes}) async {
    _crNotes = notes ?? _crNotes;
    final advisorName = _delegation.advisorName;

    final record = AttendanceRecord(
      id: 'att_${_todayDate.replaceAll('-', '')}',
      classId: _currentUser.classId ?? 'I-MCA-A',
      date: _todayDate,
      totalStudents: totalCount,
      presentCount: presentCount,
      absentCount: absentCount,
      absentRolls: _absentRolls.toList()..sort(),
      markedByName: _currentAttendanceRecord?.markedByName ?? _delegation.crName,
      markedByRole: _currentAttendanceRecord?.markedByRole ?? 'CR',
      isLocked: true,
      lastModifiedBy: advisorName,
      status: 'submitted',
      submittedAt: _currentAttendanceRecord?.submittedAt ?? '09:18 AM',
      notes: _crNotes,
      isSynced: _isOnline,
    );

    _currentAttendanceRecord = record;

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
        userRole: 'advisor',
        userName: advisorName,
        markedByName: record.markedByName,
        markedByRole: record.markedByRole,
        isLocked: true,
        lastModifiedBy: advisorName,
      );
      if (!success) {
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
          gender: 'M',
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

  // Switch specifically to Male or Female Assistant CR
  void switchAssistantCrRole({required bool isFemale}) {
    if (isFemale) {
      _currentUser = const AppUser(
        id: 'user_acr_f',
        name: 'DHIVYALAKSHMI H (Asst. CR)',
        email: 'asstcr.female@classcr.edu',
        role: UserRole.assistantCr,
        classId: 'I-MCA-A',
        studentId: '260311',
        department: 'MCA',
        gender: 'F',
      );
    } else {
      _currentUser = const AppUser(
        id: 'user_acr_m',
        name: 'SHOVIN MICHEL DAVID (Asst. CR)',
        email: 'asstcr.male@classcr.edu',
        role: UserRole.assistantCr,
        classId: 'I-MCA-A',
        studentId: '260274',
        department: 'MCA',
        gender: 'M',
      );
    }
    notifyListeners();
  }

  // Generate Smart Report formatted text
  String generateSmartReportText() {
    final sortedAbsentees = _absentRolls.toList()..sort();
    final author = _currentAttendanceRecord?.markedByName ?? _currentUser.name;
    final authorRole = _currentAttendanceRecord?.markedByRole ?? _currentUser.roleDisplayName;
    final advisor = _delegation.advisorName;

    final buffer = StringBuffer();
    buffer.writeln("Attendance Report");
    buffer.writeln("I MCA A — MVIT");
    buffer.writeln("Date: ${_formatDateForReport(_todayDate)}");
    buffer.writeln("Marked By: $author ($authorRole)");
    if (_currentAttendanceRecord?.lastModifiedBy != null && _currentAttendanceRecord!.lastModifiedBy!.isNotEmpty) {
      buffer.writeln("Advisor Approval: ${_currentAttendanceRecord!.lastModifiedBy}");
    } else {
      buffer.writeln("Verified by Class Advisor: $advisor");
    }
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
