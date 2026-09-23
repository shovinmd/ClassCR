enum UserRole {
  cr,
  assistantCr,
  advisor,
  staff,
  student,
  admin,
}

class AppUser {
  final String id;
  final String name;
  final String email;
  final UserRole role;
  final String? classId;
  final String? studentId;
  final String? department;
  final String? gender; // 'M' or 'F'
  final String? subject;

  const AppUser({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    this.classId,
    this.studentId,
    this.department,
    this.gender,
    this.subject,
  });

  String get roleDisplayName {
    switch (role) {
      case UserRole.cr:
        return 'Class Representative (CR)';
      case UserRole.assistantCr:
        return 'Assistant CR (Asst. CR)';
      case UserRole.advisor:
        return 'Class Advisor';
      case UserRole.staff:
        return 'Subject Teacher / Faculty';
      case UserRole.student:
        return 'Student';
      case UserRole.admin:
        return 'HOD';
    }
  }

  bool get canMarkAttendance => role == UserRole.cr || role == UserRole.assistantCr;
  bool get isFemale => gender == 'F';
  bool get isMale => gender == 'M';
}

class Student {
  final int rollNo;
  final String enrollmentNo;
  final String name;
  final String? dob;
  final String gender; // 'M' or 'F'
  final String ccrCode;
  final String classId;
  final String department;

  const Student({
    required this.rollNo,
    required this.enrollmentNo,
    required this.name,
    this.dob,
    this.gender = 'M',
    this.ccrCode = '',
    this.classId = 'I-MCA-A',
    this.department = 'MCA',
  });

  String get code => ccrCode.isNotEmpty ? ccrCode : 'CCR-${rollNo.toString().padLeft(4, '0')}';

  bool get isFemale => gender == 'F';
  bool get isMale => gender != 'F';

  static const Set<int> femaleRollNumbers = {
    // Current official roster rolls for all 22 female students:
    5, 6, 10, 11, 12, 13, 15, 20, 21, 22, 24, 29, 32, 33, 35, 38, 41, 47, 48, 50, 51, 52,
    // Prior compatibility:
    9, 19, 23, 28, 31, 34, 37, 42
  };

  factory Student.fromJson(Map<String, dynamic> json) {
    final roll = json['rollNo'] is int
        ? json['rollNo']
        : json['roll_no'] is int
            ? json['roll_no']
            : int.tryParse((json['rollNo'] ?? json['roll_no'])?.toString() ?? '0') ?? 0;
    final enrollment = (json['enrollmentNo'] ?? json['enrollment_no'])?.toString() ?? '';
    final name = json['name']?.toString() ?? '';
    final dob = json['dob']?.toString();
    final inferredGender = json['gender']?.toString() ?? (femaleRollNumbers.contains(roll) ? 'F' : 'M');
    final code = json['ccrCode']?.toString() ?? json['ccr_code']?.toString() ?? 'CCR-${roll.toString().padLeft(4, '0')}';
    final classId = (json['classId'] ?? json['class_id'])?.toString() ?? 'I-MCA-A';
    final department = json['department']?.toString() ?? 'MCA';

    return Student(
      rollNo: roll,
      enrollmentNo: enrollment,
      name: name,
      dob: dob,
      gender: inferredGender,
      ccrCode: code,
      classId: classId,
      department: department,
    );
  }

  Map<String, dynamic> toJson() => {
    'rollNo': rollNo,
    'enrollmentNo': enrollmentNo,
    'name': name,
    'dob': dob,
    'gender': gender,
    'ccrCode': code,
    'classId': classId,
    'department': department,
  };

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Student &&
          runtimeType == other.runtimeType &&
          rollNo == other.rollNo &&
          enrollmentNo == other.enrollmentNo;

  @override
  int get hashCode => rollNo.hashCode ^ enrollmentNo.hashCode;
}

class AttendanceRecord {
  final String id;
  final String classId;
  final String date; // YYYY-MM-DD
  final int totalStudents;
  final int presentCount;
  final int absentCount;
  final List<int> absentRolls;
  final String status; // 'draft', 'submitted', 'verified'
  final String? submittedAt;
  final String? notes;
  final bool isSynced;
  final String? markedByName;
  final String? markedByRole;
  final bool isLocked;
  final String? lastModifiedBy;
  final bool asstCrVerified;
  final String? asstCrVerifiedBy;
  final String? asstCrVerifiedAt;
  final int? periodNo;
  final String? periodSubject;
  final bool isDailyClassRecord;
  final String? facultyAcknowledgmentStatus; // 'pending', 'acknowledged', 'rejected'
  final String? facultyRejectionReason;
  final String? facultyAcknowledgedBy;
  final String? facultyAcknowledgedAt;

  const AttendanceRecord({
    required this.id,
    required this.classId,
    required this.date,
    required this.totalStudents,
    required this.presentCount,
    required this.absentCount,
    required this.absentRolls,
    this.status = 'submitted',
    this.submittedAt,
    this.notes,
    this.isSynced = true,
    this.markedByName,
    this.markedByRole,
    this.isLocked = true,
    this.lastModifiedBy,
    this.asstCrVerified = false,
    this.asstCrVerifiedBy,
    this.asstCrVerifiedAt,
    this.periodNo,
    this.periodSubject,
    this.isDailyClassRecord = false,
    this.facultyAcknowledgmentStatus = 'pending',
    this.facultyRejectionReason,
    this.facultyAcknowledgedBy,
    this.facultyAcknowledgedAt,
  });

  AttendanceRecord copyWith({
    String? id,
    String? classId,
    String? date,
    int? totalStudents,
    int? presentCount,
    int? absentCount,
    List<int>? absentRolls,
    String? status,
    String? submittedAt,
    String? notes,
    bool? isSynced,
    String? markedByName,
    String? markedByRole,
    bool? isLocked,
    String? lastModifiedBy,
    bool? asstCrVerified,
    String? asstCrVerifiedBy,
    String? asstCrVerifiedAt,
    int? periodNo,
    String? periodSubject,
    bool? isDailyClassRecord,
    String? facultyAcknowledgmentStatus,
    String? facultyRejectionReason,
    String? facultyAcknowledgedBy,
    String? facultyAcknowledgedAt,
  }) {
    return AttendanceRecord(
      id: id ?? this.id,
      classId: classId ?? this.classId,
      date: date ?? this.date,
      totalStudents: totalStudents ?? this.totalStudents,
      presentCount: presentCount ?? this.presentCount,
      absentCount: absentCount ?? this.absentCount,
      absentRolls: absentRolls ?? this.absentRolls,
      status: status ?? this.status,
      submittedAt: submittedAt ?? this.submittedAt,
      notes: notes ?? this.notes,
      isSynced: isSynced ?? this.isSynced,
      markedByName: markedByName ?? this.markedByName,
      markedByRole: markedByRole ?? this.markedByRole,
      isLocked: isLocked ?? this.isLocked,
      lastModifiedBy: lastModifiedBy ?? this.lastModifiedBy,
      asstCrVerified: asstCrVerified ?? this.asstCrVerified,
      asstCrVerifiedBy: asstCrVerifiedBy ?? this.asstCrVerifiedBy,
      asstCrVerifiedAt: asstCrVerifiedAt ?? this.asstCrVerifiedAt,
      periodNo: periodNo ?? this.periodNo,
      periodSubject: periodSubject ?? this.periodSubject,
      isDailyClassRecord: isDailyClassRecord ?? this.isDailyClassRecord,
      facultyAcknowledgmentStatus: facultyAcknowledgmentStatus ?? this.facultyAcknowledgmentStatus,
      facultyRejectionReason: facultyRejectionReason ?? this.facultyRejectionReason,
      facultyAcknowledgedBy: facultyAcknowledgedBy ?? this.facultyAcknowledgedBy,
      facultyAcknowledgedAt: facultyAcknowledgedAt ?? this.facultyAcknowledgedAt,
    );
  }

  factory AttendanceRecord.fromJson(Map<String, dynamic> json) {
    final rawRolls = json['absentRolls'] ?? json['absent_rolls'];
    List<int> parsedRolls = [];
    if (rawRolls is List) {
      parsedRolls = rawRolls.map((e) => int.tryParse(e.toString()) ?? 0).where((r) => r > 0).toList();
    }

    final rawLocked = json['isLocked'] ?? json['is_locked'];
    final bool isLocked = rawLocked == true || rawLocked == 1 || rawLocked == 'true';

    final parsedPeriodNo = json['periodNo'] is int
        ? json['periodNo'] as int
        : json['period_no'] is int
            ? json['period_no'] as int
            : int.tryParse((json['periodNo'] ?? json['period_no'])?.toString() ?? '');

    final bool isDaily = json['isDailyClassRecord'] == true ||
        json['is_daily_class_record'] == true ||
        parsedPeriodNo == 1;

    return AttendanceRecord(
      id: json['id']?.toString() ?? 'att_${json['date']}',
      classId: (json['classId'] ?? json['class_id'])?.toString() ?? 'I-MCA-A',
      date: json['date']?.toString() ?? '',
      totalStudents: json['totalStudents'] ?? json['total_students'] ?? 52,
      presentCount: json['presentCount'] ?? json['present_count'] ?? 52,
      absentCount: json['absentCount'] ?? json['absent_count'] ?? 0,
      absentRolls: parsedRolls,
      status: json['status']?.toString() ?? 'submitted',
      submittedAt: (json['submittedAt'] ?? json['submitted_at'])?.toString(),
      notes: json['notes']?.toString(),
      isSynced: true,
      markedByName: (json['markedByName'] ?? json['marked_by_name'])?.toString(),
      markedByRole: (json['markedByRole'] ?? json['marked_by_role'])?.toString(),
      isLocked: isLocked,
      lastModifiedBy: (json['lastModifiedBy'] ?? json['last_modified_by'])?.toString(),
      asstCrVerified: json['asstCrVerified'] == true || json['asst_cr_verified'] == true,
      asstCrVerifiedBy: (json['asstCrVerifiedBy'] ?? json['asst_cr_verified_by'])?.toString(),
      asstCrVerifiedAt: (json['asstCrVerifiedAt'] ?? json['asst_cr_verified_at'])?.toString(),
      periodNo: parsedPeriodNo,
      periodSubject: (json['periodSubject'] ?? json['period_subject'])?.toString(),
      isDailyClassRecord: isDaily,
      facultyAcknowledgmentStatus: (json['facultyAcknowledgmentStatus'] ?? json['faculty_acknowledgment_status'])?.toString() ?? 'pending',
      facultyRejectionReason: (json['facultyRejectionReason'] ?? json['faculty_rejection_reason'])?.toString(),
      facultyAcknowledgedBy: (json['facultyAcknowledgedBy'] ?? json['faculty_acknowledged_by'])?.toString(),
      facultyAcknowledgedAt: (json['facultyAcknowledgedAt'] ?? json['faculty_acknowledged_at'])?.toString(),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'classId': classId,
    'date': date,
    'totalStudents': totalStudents,
    'presentCount': presentCount,
    'absentCount': absentCount,
    'absentRolls': absentRolls,
    'status': status,
    'submittedAt': submittedAt,
    'notes': notes,
    'isSynced': isSynced,
    'markedByName': markedByName,
    'markedByRole': markedByRole,
    'isLocked': isLocked,
    'lastModifiedBy': lastModifiedBy,
    'asstCrVerified': asstCrVerified,
    'asstCrVerifiedBy': asstCrVerifiedBy,
    'asstCrVerifiedAt': asstCrVerifiedAt,
    'periodNo': periodNo,
    'periodSubject': periodSubject,
    'isDailyClassRecord': isDailyClassRecord,
    'is_daily_class_record': isDailyClassRecord,
    'facultyAcknowledgmentStatus': facultyAcknowledgmentStatus,
    'facultyRejectionReason': facultyRejectionReason,
    'facultyAcknowledgedBy': facultyAcknowledgedBy,
    'facultyAcknowledgedAt': facultyAcknowledgedAt,
  };
}

class ClassDelegation {
  final String classId;
  final String advisorName;
  final String advisorCode;
  final int? crRoll;
  final String? crName;
  final String? crCode;
  final int? maleAsstRoll;
  final String? maleAsstName;
  final String? maleAsstCode;
  final int? femaleAsstRoll;
  final String? femaleAsstName;
  final String? femaleAsstCode;
  final String studentCode;

  const ClassDelegation({
    required this.classId,
    this.advisorName = 'Mrs. V. Nandhini, AP/CA',
    this.advisorCode = 'NAVI2026',
    this.crRoll,
    this.crName,
    this.crCode,
    this.maleAsstRoll,
    this.maleAsstName,
    this.maleAsstCode,
    this.femaleAsstRoll,
    this.femaleAsstName,
    this.femaleAsstCode,
    this.studentCode = 'STU2026',
  });

  bool get isCrAppointed =>
      crRoll != null && crCode != null && crCode!.trim().isNotEmpty;

  bool get isMaleAsstAppointed =>
      maleAsstRoll != null && maleAsstCode != null && maleAsstCode!.trim().isNotEmpty;

  bool get isFemaleAsstAppointed =>
      femaleAsstRoll != null && femaleAsstCode != null && femaleAsstCode!.trim().isNotEmpty;

  bool get isAsstCrAppointed => isMaleAsstAppointed || isFemaleAsstAppointed;

  int? get asstRoll => femaleAsstRoll ?? maleAsstRoll;
  String? get asstName => femaleAsstName ?? maleAsstName;
  String? get asstCode => femaleAsstCode ?? maleAsstCode;
  String? get asstGender => femaleAsstRoll != null ? 'F' : (maleAsstRoll != null ? 'M' : null);

  factory ClassDelegation.fromJson(Map<String, dynamic> json) {
    return ClassDelegation(
      classId: (json['classId'] ?? json['class_id'] ?? json['id'])?.toString() ?? 'I-MCA-A',
      advisorName: (json['advisorName'] ?? json['advisor_name'])?.toString() ?? 'Mrs. V. Nandhini, AP/CA',
      advisorCode: (json['advisorCode'] ?? json['advisor_code'])?.toString() ?? 'NAVI2026',
      crRoll: json['crRoll'] is int ? json['crRoll'] : (json['cr_roll'] is int ? json['cr_roll'] : int.tryParse((json['crRoll'] ?? json['cr_roll'])?.toString() ?? '')),
      crName: (json['crName'] ?? json['cr_name'])?.toString(),
      crCode: (json['crCode'] ?? json['cr_code'])?.toString(),
      maleAsstRoll: json['maleAsstRoll'] is int ? json['maleAsstRoll'] : (json['male_asst_roll'] is int ? json['male_asst_roll'] : int.tryParse((json['maleAsstRoll'] ?? json['male_asst_roll'])?.toString() ?? '')),
      maleAsstName: (json['maleAsstName'] ?? json['male_asst_name'])?.toString(),
      maleAsstCode: (json['maleAsstCode'] ?? json['male_asst_code'])?.toString(),
      femaleAsstRoll: json['femaleAsstRoll'] is int ? json['femaleAsstRoll'] : (json['female_asst_roll'] is int ? json['female_asst_roll'] : int.tryParse((json['femaleAsstRoll'] ?? json['female_asst_roll'])?.toString() ?? '')),
      femaleAsstName: (json['femaleAsstName'] ?? json['female_asst_name'])?.toString(),
      femaleAsstCode: (json['femaleAsstCode'] ?? json['female_asst_code'])?.toString(),
      studentCode: (json['studentCode'] ?? json['student_code'])?.toString() ?? 'STU2026',
    );
  }

  Map<String, dynamic> toJson() => {
    'classId': classId,
    'advisorName': advisorName,
    'advisorCode': advisorCode,
    'crRoll': crRoll,
    'crName': crName,
    'crCode': crCode,
    'maleAsstRoll': maleAsstRoll,
    'maleAsstName': maleAsstName,
    'maleAsstCode': maleAsstCode,
    'femaleAsstRoll': femaleAsstRoll,
    'femaleAsstName': femaleAsstName,
    'femaleAsstCode': femaleAsstCode,
    'studentCode': studentCode,
  };
}
