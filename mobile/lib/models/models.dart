enum UserRole {
  cr,
  assistantCr,
  advisor,
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

  const AppUser({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    this.classId,
    this.studentId,
    this.department,
  });

  String get roleDisplayName {
    switch (role) {
      case UserRole.cr:
        return 'Class Representative (CR)';
      case UserRole.assistantCr:
        return 'Assistant CR (Asst. CR)';
      case UserRole.advisor:
        return 'Class Advisor';
      case UserRole.student:
        return 'Student';
      case UserRole.admin:
        return 'College Admin';
    }
  }

  bool get canMarkAttendance => role == UserRole.cr || role == UserRole.assistantCr;
}

class Student {
  final int rollNo;
  final String enrollmentNo;
  final String name;
  final String? dob;
  final String classId;
  final String department;

  const Student({
    required this.rollNo,
    required this.enrollmentNo,
    required this.name,
    this.dob,
    this.classId = 'I-MCA-A',
    this.department = 'MCA',
  });

  factory Student.fromJson(Map<String, dynamic> json) {
    return Student(
      rollNo: json['rollNo'] is int ? json['rollNo'] : int.parse(json['rollNo'].toString()),
      enrollmentNo: json['enrollmentNo'].toString(),
      name: json['name'].toString(),
      dob: json['dob']?.toString(),
      classId: json['classId']?.toString() ?? 'I-MCA-A',
      department: json['department']?.toString() ?? 'MCA',
    );
  }

  Map<String, dynamic> toJson() => {
    'rollNo': rollNo,
    'enrollmentNo': enrollmentNo,
    'name': name,
    'dob': dob,
    'classId': classId,
    'department': department,
  };
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
  };
}
