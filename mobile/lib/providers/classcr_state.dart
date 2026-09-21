import 'dart:async';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/models.dart';
import '../data/mca_students.dart';
import '../data/mca_faculty.dart';
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

  // Real-time synchronization timer
  Timer? _realtimeTimer;
  bool _isRealtimeSyncActive = false;
  bool get isRealtimeSyncActive => _isRealtimeSyncActive;

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

  // Locked attendance check: once finalized and locked by CR
  bool get isAttendanceLocked =>
      _currentAttendanceRecord != null && _currentAttendanceRecord!.isLocked;

  // Assistant CR Verification Status
  bool get isSectionVerifiedByAsstCr => _currentAttendanceRecord?.asstCrVerified == true;
  String? get asstCrVerifiedBy => _currentAttendanceRecord?.asstCrVerifiedBy;
  String? get asstCrVerifiedAt => _currentAttendanceRecord?.asstCrVerifiedAt;
  int? get activePeriodNo => _currentAttendanceRecord?.periodNo;
  String? get activePeriodSubject => _currentAttendanceRecord?.periodSubject;

  // Only CR & Asst. CR can mark attendance while unlocked; only Class Advisor can modify/override after submission. HOD and Students CANNOT mark or modify attendance.
  bool get canModifyAttendance =>
      (!isAttendanceLocked && (_currentUser.role == UserRole.cr || _currentUser.role == UserRole.assistantCr)) ||
      _currentUser.role == UserRole.advisor;

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
      if (roleStr == 'staff') role = UserRole.staff;
      if (roleStr == 'student') role = UserRole.student;
      if (roleStr == 'admin') role = UserRole.admin;

      final gender = prefs.getString('classcr_user_gender');
      final subject = prefs.getString('classcr_user_subject');

      _currentUser = AppUser(
        id: 'user_${role.name}',
        name: name,
        email: '${role.name}@classcr.edu',
        role: role,
        classId: classId,
        studentId: studentId,
        department: 'MCA',
        gender: gender,
        subject: subject,
      );
    }

    final savedCrName = prefs.getString('classcr_delegation_cr_name');
    final savedCrRoll = prefs.getInt('classcr_delegation_cr_roll');
    final savedCrCode = prefs.getString('classcr_delegation_cr_code');
    final savedMaleAsstName = prefs.getString('classcr_delegation_male_asst_name');
    final savedMaleAsstRoll = prefs.getInt('classcr_delegation_male_asst_roll');
    final savedMaleAsstCode = prefs.getString('classcr_delegation_male_asst_code');
    final savedFemaleAsstName = prefs.getString('classcr_delegation_female_asst_name');
    final savedFemaleAsstRoll = prefs.getInt('classcr_delegation_female_asst_roll');
    final savedFemaleAsstCode = prefs.getString('classcr_delegation_female_asst_code');
    final savedStudentCode = prefs.getString('classcr_delegation_student_code');

    if (savedCrName != null || savedFemaleAsstName != null || savedMaleAsstName != null) {
      _delegation = ClassDelegation(
        classId: 'I-MCA-A',
        advisorName: _delegation.advisorName,
        advisorCode: _delegation.advisorCode,
        crRoll: savedCrRoll ?? _delegation.crRoll,
        crName: savedCrName ?? _delegation.crName,
        crCode: savedCrCode ?? _delegation.crCode,
        maleAsstRoll: savedMaleAsstRoll ?? _delegation.maleAsstRoll,
        maleAsstName: savedMaleAsstName ?? _delegation.maleAsstName,
        maleAsstCode: savedMaleAsstCode ?? _delegation.maleAsstCode,
        femaleAsstRoll: savedFemaleAsstRoll ?? _delegation.femaleAsstRoll,
        femaleAsstName: savedFemaleAsstName ?? _delegation.femaleAsstName,
        femaleAsstCode: savedFemaleAsstCode ?? _delegation.femaleAsstCode,
        studentCode: savedStudentCode ?? _delegation.studentCode,
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

    final prefs = await SharedPreferences.getInstance();
    if (crName != null) await prefs.setString('classcr_delegation_cr_name', crName);
    if (crRoll != null) await prefs.setInt('classcr_delegation_cr_roll', crRoll);
    if (crCode != null) await prefs.setString('classcr_delegation_cr_code', crCode.toUpperCase());
    if (maleAsstName != null) await prefs.setString('classcr_delegation_male_asst_name', maleAsstName);
    if (maleAsstRoll != null) await prefs.setInt('classcr_delegation_male_asst_roll', maleAsstRoll);
    if (maleAsstCode != null) await prefs.setString('classcr_delegation_male_asst_code', maleAsstCode.toUpperCase());
    if (femaleAsstName != null) await prefs.setString('classcr_delegation_female_asst_name', femaleAsstName);
    if (femaleAsstRoll != null) await prefs.setInt('classcr_delegation_female_asst_roll', femaleAsstRoll);
    if (femaleAsstCode != null) await prefs.setString('classcr_delegation_female_asst_code', femaleAsstCode.toUpperCase());
    if (studentCode != null) await prefs.setString('classcr_delegation_student_code', studentCode.toUpperCase());

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
    int? rollNo,
  }) async {
    final entered = code.trim().toUpperCase();

    // 1. Try remote verification
    final remoteRes = await ApiService.verifyRolePasscode(
      classId: classId,
      role: role.name,
      code: entered,
      gender: gender,
      rollNo: rollNo,
    );
    if (remoteRes != null) {
      return remoteRes;
    }

    // 2. Offline fallback verification
    if (role == UserRole.admin) {
      if (entered == 'ADMIN2026' || entered == 'ADM2026' || entered == 'HOD2026') {
        return {'valid': true, 'role': 'admin', 'name': 'Head of Department (HOD)', 'classId': classId};
      }
    } else if (role == UserRole.advisor) {
      if (entered == _delegation.advisorCode || entered == 'ADV2026' || entered == 'NAVI2026') {
        return {'valid': true, 'role': 'advisor', 'name': _delegation.advisorName, 'classId': classId};
      }
    } else if (role == UserRole.staff) {
      if (entered == 'STAFF2026' || entered == 'ADV2026' || entered == 'TEACH2026' || entered == 'NAVI2026') {
        return {'valid': true, 'role': 'staff', 'name': 'Subject Teacher / Faculty', 'classId': classId};
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
      // Check individual student ClassCR code
      if (rollNo != null) {
        final expectedCode = 'CCR-${rollNo.toString().padLeft(4, '0')}';
        if (entered == expectedCode) {
          final studentList = _students;
          final student = studentList.cast<Student?>().firstWhere(
                (s) => s?.rollNo == rollNo,
                orElse: () => null,
              );
          return {
            'valid': true,
            'role': 'student',
            'classId': classId,
            'name': student?.name ?? '',
            'rollNo': rollNo,
            'code': entered,
          };
        }
      } else {
        final match = _students.cast<Student?>().firstWhere(
              (s) => s != null && s.code.toUpperCase() == entered,
              orElse: () => null,
            );
        if (match != null) {
          return {
            'valid': true,
            'role': 'student',
            'classId': classId,
            'name': match.name,
            'rollNo': match.rollNo,
            'code': entered,
          };
        }
      }
    }

    return {'valid': false, 'error': 'Invalid verification passcode'};
  }

  // Universal Code Verification: instantly deduces role & identity from passcode
  Map<String, dynamic> verifyAnyCode(String rawCode) {
    final code = rawCode.trim().toUpperCase();
    if (code.isEmpty) {
      return {'valid': false, 'error': 'Please enter your passcode or ClassCR code'};
    }

    // 1. HOD / Admin Passcodes
    if (code == 'HOD2026' || code == 'ADMIN2026' || code == 'ADM2026') {
      return {
        'valid': true,
        'role': UserRole.admin,
        'name': 'Head of Department (HOD)',
        'classId': 'I-MCA-A',
        'gender': 'M',
        'title': 'Head of Department (HOD)',
      };
    }

    // 2. Advisor Passcodes
    if (code == 'ADV2026' || code == 'NAVI2026' || code == _delegation.advisorCode.toUpperCase()) {
      return {
        'valid': true,
        'role': UserRole.advisor,
        'name': _delegation.advisorName.isNotEmpty ? _delegation.advisorName : 'Mrs. V. Nandhini, AP/CA',
        'classId': 'I-MCA-A',
        'gender': 'F',
        'title': 'Class Advisor (Mrs. V. Nandhini, AP/CA)',
      };
    }

    // 3. Staff / Faculty Passcodes
    if (code == 'STAFF2026' || code == 'TEACH2026') {
      return {
        'valid': true,
        'role': UserRole.staff,
        'name': 'Faculty / Subject Teacher',
        'classId': 'I-MCA-A',
        'gender': 'M',
        'title': 'Subject Teacher / Faculty',
      };
    }
    for (final f in kOfficialMcaFaculty) {
      if (code == (f.subjectAbb?.toUpperCase()) || code == (f.subjectCode?.toUpperCase())) {
        return {
          'valid': true,
          'role': UserRole.staff,
          'name': f.name,
          'classId': 'I-MCA-A',
          'gender': 'M',
          'title': '${f.name} (${f.subject ?? f.role})',
        };
      }
    }

    // 4. CR Passcodes
    if (code == 'CR2026' || code == _delegation.crCode.toUpperCase()) {
      return {
        'valid': true,
        'role': UserRole.cr,
        'name': _delegation.crName.isNotEmpty ? '${_delegation.crName} (CR)' : 'AASIM S (CR)',
        'studentId': '260192',
        'rollNo': _delegation.crRoll,
        'classId': 'I-MCA-A',
        'gender': 'M',
        'title': 'Class Representative (CR) • ${_delegation.crName}',
      };
    }

    // 5. Assistant CR Passcodes
    if (code == 'ACR2026' || code == 'FACR2026' || code == _delegation.femaleAsstCode.toUpperCase()) {
      return {
        'valid': true,
        'role': UserRole.assistantCr,
        'name': _delegation.femaleAsstName.isNotEmpty ? '${_delegation.femaleAsstName} (Asst. CR)' : 'DHIVYALAKSHMI H (Asst. CR)',
        'studentId': '260311',
        'rollNo': _delegation.femaleAsstRoll,
        'classId': 'I-MCA-A',
        'gender': 'F',
        'title': 'Assistant CR (Female) • ${_delegation.femaleAsstName}',
      };
    }
    if (code == 'MACR2026' || code == _delegation.maleAsstCode.toUpperCase()) {
      return {
        'valid': true,
        'role': UserRole.assistantCr,
        'name': _delegation.maleAsstName.isNotEmpty ? '${_delegation.maleAsstName} (Asst. CR)' : 'ABDUL MALIK A (Asst. CR)',
        'studentId': '260008',
        'rollNo': _delegation.maleAsstRoll,
        'classId': 'I-MCA-A',
        'gender': 'M',
        'title': 'Assistant CR (Male) • ${_delegation.maleAsstName}',
      };
    }

    // 6. Generic Student Passcodes
    if (code == 'STU2026' || code == '123456' || code == _delegation.studentCode.toUpperCase()) {
      final firstSt = _students.isNotEmpty ? _students.first : null;
      return {
        'valid': true,
        'role': UserRole.student,
        'name': firstSt?.name ?? 'Student',
        'studentId': firstSt?.enrollmentNo ?? '260192',
        'student': firstSt,
        'classId': 'I-MCA-A',
        'gender': firstSt?.isFemale == true ? 'F' : 'M',
        'title': 'Student • ${firstSt?.name ?? "I MCA"}',
      };
    }

    // 7. Individual Student Code Check (e.g. CCR-0001 to CCR-0052, or enrollment number, or roll number)
    final matchedStudent = _students.cast<Student?>().firstWhere(
      (s) => s != null && (
        s.code.toUpperCase() == code ||
        s.enrollmentNo.toUpperCase() == code ||
        'CCR-${s.rollNo.toString().padLeft(4, '0')}' == code ||
        s.rollNo.toString() == code
      ),
      orElse: () => null,
    );

    if (matchedStudent != null) {
      return {
        'valid': true,
        'role': UserRole.student,
        'student': matchedStudent,
        'name': matchedStudent.name,
        'studentId': matchedStudent.enrollmentNo,
        'rollNo': matchedStudent.rollNo,
        'classId': 'I-MCA-A',
        'gender': matchedStudent.isFemale ? 'F' : 'M',
        'title': '#${matchedStudent.rollNo} ${matchedStudent.name} (${matchedStudent.enrollmentNo})',
      };
    }

    return {
      'valid': false,
      'error': 'Unrecognized code. Enter your ClassCR code (e.g. CCR-0001), CR2026, ACR2026, ADV2026, STAFF2026, or HOD2026.',
    };
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
    autoSaveRealtimeDraft();
  }

  void markSectionAbsent({required bool isFemale}) {
    if (!canModifyAttendance) return;
    final rolls = _students.where((s) => s.isFemale == isFemale).map((s) => s.rollNo).toSet();
    _absentRolls.addAll(rolls);
    notifyListeners();
    autoSaveRealtimeDraft();
  }

  // Real-time synchronization methods (Zero Delay between CR and Asst. CR)
  void startRealtimeSync() {
    _stopRealtimeTimer();
    _isRealtimeSyncActive = true;
    fetchRealtimeAttendance();
    // Poll every 3 seconds for instant real-time sync across devices
    _realtimeTimer = Timer.periodic(const Duration(seconds: 3), (_) {
      fetchRealtimeAttendance();
    });
  }

  void stopRealtimeSync() {
    _isRealtimeSyncActive = false;
    _stopRealtimeTimer();
  }

  void _stopRealtimeTimer() {
    _realtimeTimer?.cancel();
    _realtimeTimer = null;
  }

  Future<void> fetchRealtimeAttendance() async {
    if (!_isOnline) return;
    try {
      final remote = await ApiService.fetchTodayAttendance(
        classId: _currentUser.classId ?? 'I-MCA-A',
        date: _todayDate,
      );
      if (remote != null) {
        final remoteSet = remote.absentRolls.toSet();
        final hasChanged = _currentAttendanceRecord?.isLocked != remote.isLocked ||
            _currentAttendanceRecord?.asstCrVerified != remote.asstCrVerified ||
            _currentAttendanceRecord?.absentRolls.length != remote.absentRolls.length ||
            !_absentRolls.containsAll(remoteSet) ||
            !remoteSet.containsAll(_absentRolls);

        if (hasChanged) {
          _currentAttendanceRecord = remote;
          _absentRolls.clear();
          _absentRolls.addAll(remote.absentRolls);
          if (remote.notes != null) _crNotes = remote.notes;
          notifyListeners();
        }
      }
    } catch (_) {}
  }

  // Instant real-time background save of marks
  Future<void> autoSaveRealtimeDraft() async {
    if (!_isOnline || isAttendanceLocked) return;
    try {
      await ApiService.submitAttendance(
        classId: _currentUser.classId ?? 'I-MCA-A',
        date: _todayDate,
        absentRolls: _absentRolls.toList()..sort(),
        notes: _crNotes,
        userRole: _currentUser.role.name,
        userName: _currentUser.name,
        markedByName: _currentAttendanceRecord?.markedByName ?? _currentUser.name,
        markedByRole: _currentAttendanceRecord?.markedByRole ?? _currentUser.roleDisplayName,
        isLocked: false,
        asstCrVerified: isSectionVerifiedByAsstCr,
        asstCrVerifiedBy: _currentAttendanceRecord?.asstCrVerifiedBy,
        asstCrVerifiedAt: _currentAttendanceRecord?.asstCrVerifiedAt,
      );
    } catch (_) {}
  }

  // Assistant CR completes verification of assigned section and transmits to CR
  Future<bool> verifyAndSendSectionToCr({String? notes}) async {
    final now = DateTime.now();
    final timeStr = "${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}";
    final updatedRecord = (_currentAttendanceRecord ?? AttendanceRecord(
      id: 'att_${_todayDate.replaceAll('-', '')}',
      classId: _currentUser.classId ?? 'I-MCA-A',
      date: _todayDate,
      totalStudents: totalCount,
      presentCount: presentCount,
      absentCount: absentCount,
      absentRolls: _absentRolls.toList()..sort(),
      isLocked: false,
    )).copyWith(
      asstCrVerified: true,
      asstCrVerifiedBy: _currentUser.name,
      asstCrVerifiedAt: timeStr,
      isLocked: false,
      status: 'draft',
      notes: notes ?? _crNotes,
      markedByName: _currentUser.name,
      markedByRole: _currentUser.roleDisplayName,
    );

    _currentAttendanceRecord = updatedRecord;
    notifyListeners();

    if (_isOnline) {
      return await ApiService.submitAttendance(
        classId: updatedRecord.classId,
        date: updatedRecord.date,
        absentRolls: updatedRecord.absentRolls,
        notes: updatedRecord.notes,
        userRole: _currentUser.role.name,
        userName: _currentUser.name,
        markedByName: updatedRecord.markedByName,
        markedByRole: updatedRecord.markedByRole,
        isLocked: false,
        asstCrVerified: true,
        asstCrVerifiedBy: _currentUser.name,
        asstCrVerifiedAt: timeStr,
      );
    }
    return true;
  }

  // Merge Boys & Girls Assistant CR records into consolidated class attendance
  Future<bool> mergeAndSubmitSectionAttendance({
    Set<int>? additionalAbsentees,
    String? mergeNotes,
  }) async {
    if (additionalAbsentees != null) {
      _absentRolls.addAll(additionalAbsentees);
    }
    _crNotes = mergeNotes ?? 'Merged Assistant CR section attendance verified.';
    notifyListeners();
    return await submitAttendance(isLocked: true);
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
    autoSaveRealtimeDraft();
    return true;
  }

  bool markAllPresent() {
    if (!canModifyAttendance) return false;
    _absentRolls.clear();
    notifyListeners();
    autoSaveRealtimeDraft();
    return true;
  }

  bool markAllAbsent() {
    if (!canModifyAttendance) return false;
    _absentRolls.addAll(_students.map((s) => s.rollNo));
    notifyListeners();
    autoSaveRealtimeDraft();
    return true;
  }

  void updateNotes(String notes) {
    _crNotes = notes;
    notifyListeners();
  }

  // Final Lock Attendance Submission (Only CR and Advisor can execute final lock)
  Future<bool> submitAttendance({
    String? notes,
    bool isLocked = true,
    int? periodNo,
    String? periodSubject,
  }) async {
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
      isLocked: isLocked,
      lastModifiedBy: _currentAttendanceRecord?.lastModifiedBy,
      status: isLocked ? 'submitted' : 'draft',
      submittedAt: _currentAttendanceRecord?.submittedAt ?? '09:18 AM',
      notes: _crNotes,
      isSynced: _isOnline,
      asstCrVerified: _currentAttendanceRecord?.asstCrVerified ?? false,
      asstCrVerifiedBy: _currentAttendanceRecord?.asstCrVerifiedBy,
      asstCrVerifiedAt: _currentAttendanceRecord?.asstCrVerifiedAt,
      periodNo: periodNo ?? _currentAttendanceRecord?.periodNo ?? 1,
      periodSubject: periodSubject ?? _currentAttendanceRecord?.periodSubject,
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
        isLocked: isLocked,
        lastModifiedBy: record.lastModifiedBy,
        asstCrVerified: record.asstCrVerified,
        asstCrVerifiedBy: record.asstCrVerifiedBy,
        asstCrVerifiedAt: record.asstCrVerifiedAt,
        periodNo: record.periodNo,
        periodSubject: record.periodSubject,
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
  void switchRole(UserRole newRole, {String? customName, String? customSubject}) async {
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
        _currentUser = AppUser(
          id: 'user_adv_1',
          name: customName ?? 'Mrs. V. Nandhini, AP/CA',
          email: 'advisor@classcr.edu',
          role: UserRole.advisor,
          classId: 'I-MCA-A',
          department: 'MCA',
          subject: 'Object oriented Programming in C++ (OOPS) & Lab',
        );
        break;
      case UserRole.staff:
        _currentUser = AppUser(
          id: 'user_staff_1',
          name: customName ?? 'Ms. M. Tamilmani, AP/CA',
          email: 'staff@classcr.edu',
          role: UserRole.staff,
          classId: 'I-MCA-A',
          department: 'MCA',
          subject: customSubject ?? 'Operating Systems (OS) & Lab',
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
          name: 'Head of Department (HOD)',
          email: 'hod@classcr.edu',
          role: UserRole.admin,
          department: 'MCA',
        );
        break;
    }

    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('classcr_setup_done', true);
    await prefs.setString('classcr_user_role', newRole.name);
    await prefs.setString('classcr_user_name', _currentUser.name);
    await prefs.setString('classcr_class_id', _currentUser.classId ?? 'I-MCA-A');
    if (_currentUser.studentId != null) {
      await prefs.setString('classcr_student_id', _currentUser.studentId!);
    }
    if (_currentUser.gender != null) {
      await prefs.setString('classcr_user_gender', _currentUser.gender!);
    }
    if (_currentUser.subject != null) {
      await prefs.setString('classcr_user_subject', _currentUser.subject!);
    }
    notifyListeners();
  }

  // Switch specifically to Male or Female Assistant CR
  void switchAssistantCrRole({required bool isFemale}) async {
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

    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('classcr_setup_done', true);
    await prefs.setString('classcr_user_role', UserRole.assistantCr.name);
    await prefs.setString('classcr_user_name', _currentUser.name);
    await prefs.setString('classcr_class_id', 'I-MCA-A');
    if (_currentUser.studentId != null) {
      await prefs.setString('classcr_student_id', _currentUser.studentId!);
    }
    await prefs.setString('classcr_user_gender', isFemale ? 'F' : 'M');
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

  @override
  void dispose() {
    _stopRealtimeTimer();
    super.dispose();
  }
}
