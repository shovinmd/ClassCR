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
    final roll = json['rollNo'] is int ? json['rollNo'] : int.tryParse(json['rollNo']?.toString() ?? '0') ?? 0;
    final inferredGender = json['gender']?.toString() ?? (femaleRollNumbers.contains(roll) ? 'F' : 'M');
    final code = json['ccrCode']?.toString() ?? json['ccr_code']?.toString() ?? 'CCR-${roll.toString().padLeft(4, '0')}';

    return Student(
      rollNo: roll,
      enrollmentNo: json['enrollmentNo'].toString(),
      name: json['name'].toString(),
      dob: json['dob']?.toString(),
      gender: inferredGender,
      ccrCode: code,
      classId: json['classId']?.toString() ?? 'I-MCA-A',
      department: json['department']?.toString() ?? 'MCA',
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
      facultyAcknowledgmentStatus: facultyAcknowledgmentStatus ?? this.facultyAcknowledgmentStatus,
      facultyRejectionReason: facultyRejectionReason ?? this.facultyRejectionReason,
      facultyAcknowledgedBy: facultyAcknowledgedBy ?? this.facultyAcknowledgedBy,
      facultyAcknowledgedAt: facultyAcknowledgedAt ?? this.facultyAcknowledgedAt,
    );
  }

  factory AttendanceRecord.fromJson(Map<String, dynamic> json) {
    return AttendanceRecord(
      id: json['id'] ?? 'att_${json['date']}',
      classId: json['classId'] ?? 'I-MCA-A',
      date: json['date'] ?? '',
      totalStudents: json['totalStudents'] ?? 52,
      presentCount: json['presentCount'] ?? 52,
      absentCount: json['absentCount'] ?? 0,
      absentRolls: (json['absentRolls'] as List<dynamic>?)?.map((e) => e as int).toList() ?? [],
      status: json['status'] ?? 'submitted',
      submittedAt: json['submittedAt'],
      notes: json['notes'],
      isSynced: json['isSynced'] ?? true,
      markedByName: json['markedByName'],
      markedByRole: json['markedByRole'],
      isLocked: json['isLocked'] == true || json['status'] == 'submitted',
      lastModifiedBy: json['lastModifiedBy'],
      asstCrVerified: json['asstCrVerified'] == true,
      asstCrVerifiedBy: json['asstCrVerifiedBy']?.toString(),
      asstCrVerifiedAt: json['asstCrVerifiedAt']?.toString(),
      periodNo: json['periodNo'] is int ? json['periodNo'] : int.tryParse(json['periodNo']?.toString() ?? ''),
      periodSubject: json['periodSubject']?.toString(),
      facultyAcknowledgmentStatus: json['facultyAcknowledgmentStatus']?.toString() ?? 'pending',
      facultyRejectionReason: json['facultyRejectionReason']?.toString(),
      facultyAcknowledgedBy: json['facultyAcknowledgedBy']?.toString(),
      facultyAcknowledgedAt: json['facultyAcknowledgedAt']?.toString(),
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
      classId: json['classId']?.toString() ?? 'I-MCA-A',
      advisorName: json['advisorName']?.toString() ?? 'Mrs. V. Nandhini, AP/CA',
      advisorCode: json['advisorCode']?.toString() ?? 'NAVI2026',
      crRoll: json['crRoll'] is int ? json['crRoll'] : int.tryParse(json['crRoll']?.toString() ?? ''),
      crName: json['crName']?.toString(),
      crCode: json['crCode']?.toString(),
      maleAsstRoll: json['maleAsstRoll'] is int ? json['maleAsstRoll'] : int.tryParse(json['maleAsstRoll']?.toString() ?? ''),
      maleAsstName: json['maleAsstName']?.toString(),
      maleAsstCode: json['maleAsstCode']?.toString(),
      femaleAsstRoll: json['femaleAsstRoll'] is int ? json['femaleAsstRoll'] : int.tryParse(json['femaleAsstRoll']?.toString() ?? ''),
      femaleAsstName: json['femaleAsstName']?.toString(),
      femaleAsstCode: json['femaleAsstCode']?.toString(),
      studentCode: json['studentCode']?.toString() ?? 'STU2026',
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
