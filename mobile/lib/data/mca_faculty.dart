class FacultyMember {
  final String name;
  final String designation;
  final String department;
  final String role;
  final String? subject;
  final String? subjectCode;
  final String? subjectAbb;
  final String? hallNo;
  final int? hours;

  const FacultyMember({
    required this.name,
    required this.designation,
    this.department = 'MCA',
    required this.role,
    this.subject,
    this.subjectCode,
    this.subjectAbb,
    this.hallNo,
    this.hours,
  });

  factory FacultyMember.fromJson(Map<String, dynamic> json) {
    return FacultyMember(
      name: json['name']?.toString() ?? '',
      designation: json['designation']?.toString() ?? 'AP/CA',
      department: json['department']?.toString() ?? 'MCA',
      role: json['role']?.toString() ?? 'Faculty',
      subject: json['subject']?.toString(),
      subjectCode: json['subjectCode']?.toString() ?? json['code']?.toString(),
      subjectAbb: json['subjectAbb']?.toString(),
      hallNo: json['hallNo']?.toString(),
      hours: json['hours'] is int ? json['hours'] : int.tryParse(json['hours']?.toString() ?? '7'),
    );
  }
}

// Official MCA Teachers from Manakula Vinayagar Institute of Technology (MVIT)
// Department of Computer Applications - MCA I Semester (Batch 2026-2028, Hall 408)
const List<FacultyMember> kOfficialMcaFaculty = [
  FacultyMember(
    name: 'Mrs. V. Nandhini, AP/CA',
    designation: 'Assistant Professor / CA',
    department: 'MCA',
    role: 'Class Advisor',
    subject: 'Object oriented Programming in C++ & Lab',
    subjectCode: '25PMCT12 / 25PMCP11',
    subjectAbb: 'OOPS',
    hallNo: '408',
    hours: 11, // 7 theory + 4 lab
  ),
  FacultyMember(
    name: 'Dr. S. Sivaramakrishnan, Prof/Maths',
    designation: 'Professor / Maths',
    department: 'Mathematics',
    role: 'Subject Teacher',
    subject: 'Mathematical Foundation of Computer Applications',
    subjectCode: '25PMCT11',
    subjectAbb: 'MAT',
    hallNo: '408',
    hours: 8,
  ),
  FacultyMember(
    name: 'Mrs. K. Shivashankari, AP/CA',
    designation: 'Assistant Professor / CA',
    department: 'MCA',
    role: 'Subject Teacher',
    subject: 'Database Technology & Lab',
    subjectCode: '25PMCT13 / 25PMCP12',
    subjectAbb: 'DT',
    hallNo: '408',
    hours: 11, // 7 theory + 4 lab
  ),
  FacultyMember(
    name: 'Ms. M. Tamilmani, AP/CA',
    designation: 'Assistant Professor / CA',
    department: 'MCA',
    role: 'Subject Teacher',
    subject: 'Operating Systems & Lab',
    subjectCode: '25PMCT14 / 25PMCP13',
    subjectAbb: 'OS',
    hallNo: '408',
    hours: 11, // 7 theory + 4 lab
  ),
  FacultyMember(
    name: 'Ms. V. Deepa, AP/CA',
    designation: 'Assistant Professor / CA',
    department: 'MCA',
    role: 'Subject Teacher',
    subject: 'Software Engineering',
    subjectCode: '25PMCT15',
    subjectAbb: 'SE',
    hallNo: '408',
    hours: 6,
  ),
];

class PeriodTiming {
  final int periodNo;
  final String startTime;
  final String endTime;
  final String label;

  const PeriodTiming({
    required this.periodNo,
    required this.startTime,
    required this.endTime,
    required this.label,
  });
}

const List<PeriodTiming> kMcaPeriodTimings = [
  PeriodTiming(periodNo: 1, startTime: '8:50 AM', endTime: '9:40 AM', label: 'Period 1 (Morning 1st Hour)'),
  PeriodTiming(periodNo: 2, startTime: '9:40 AM', endTime: '10:30 AM', label: 'Period 2'),
  PeriodTiming(periodNo: 3, startTime: '10:45 AM', endTime: '11:35 AM', label: 'Period 3'),
  PeriodTiming(periodNo: 4, startTime: '11:35 AM', endTime: '12:25 PM', label: 'Period 4'),
  PeriodTiming(periodNo: 5, startTime: '1:10 PM', endTime: '2:00 PM', label: 'Period 5'),
  PeriodTiming(periodNo: 6, startTime: '2:00 PM', endTime: '2:50 PM', label: 'Period 6'),
  PeriodTiming(periodNo: 7, startTime: '3:00 PM', endTime: '3:50 PM', label: 'Period 7'),
  PeriodTiming(periodNo: 8, startTime: '3:50 PM', endTime: '4:40 PM', label: 'Period 8'),
];

// Official Time Table Schedule for I MCA A (Batch 2026-2028, Hall 408)
class TimeTableSlot {
  final String day;
  final List<String> periods; // Periods 1 to 8

  const TimeTableSlot({required this.day, required this.periods});
}

const List<TimeTableSlot> kMcaTimeTable = [
  TimeTableSlot(
    day: 'Monday',
    periods: ['OS', 'MAT', 'OOPS', 'MAT', 'OOPS', 'SE', 'DT LAB', 'DT LAB'],
  ),
  TimeTableSlot(
    day: 'Tuesday',
    periods: ['OOPS', 'OS', 'MAT', 'OS', 'DT', 'OS LAB', 'OS LAB', 'OOPS'],
  ),
  TimeTableSlot(
    day: 'Wednesday',
    periods: ['DT', 'MAT', 'OOPS LAB', 'OOPS LAB', 'DT', 'OS', 'DT', 'SE'],
  ),
  TimeTableSlot(
    day: 'Thursday',
    periods: ['SE', 'OS LAB', 'OS LAB', 'MAT', 'OOPS', 'DT', 'SE', 'OS'],
  ),
  TimeTableSlot(
    day: 'Friday',
    periods: ['MAT', 'OOPS', 'SE', 'MAT', 'DT LAB', 'DT LAB', 'OS', 'DT'],
  ),
  TimeTableSlot(
    day: 'Saturday',
    periods: ['OOPS', 'LIB', 'OOPS LAB', 'OOPS LAB', 'MAT', 'OS', 'SE', 'DT'],
  ),
];

// Helper to look up staff by subject abbreviation
FacultyMember? getFacultyForSubject(String subjectAbb) {
  final abb = subjectAbb.trim().toUpperCase();
  if (abb.contains('OOPS')) {
    return kOfficialMcaFaculty[0]; // Mrs. V. Nandhini
  } else if (abb == 'MAT') {
    return kOfficialMcaFaculty[1]; // Dr. S. Sivaramakrishnan
  } else if (abb.contains('DT')) {
    return kOfficialMcaFaculty[2]; // Mrs. K. Shivashankari
  } else if (abb.contains('OS')) {
    return kOfficialMcaFaculty[3]; // Ms. M. Tamilmani
  } else if (abb == 'SE') {
    return kOfficialMcaFaculty[4]; // Ms. V. Deepa
  }
  return null;
}

// Return the 1st period subject and faculty for any date
Map<String, dynamic> getFirstPeriodDetailsForDate([DateTime? date]) {
  final d = date ?? DateTime.now();
  final dayNames = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
  final dayName = dayNames[d.weekday - 1];

  final slot = kMcaTimeTable.firstWhere(
    (s) => s.day.toLowerCase() == dayName.toLowerCase(),
    orElse: () => kMcaTimeTable.first,
  );

  final subjectAbb = slot.periods.first;
  final faculty = getFacultyForSubject(subjectAbb);

  return {
    'day': slot.day,
    'period': 1,
    'time': '8:50 AM - 9:40 AM',
    'subjectAbb': subjectAbb,
    'faculty': faculty,
    'facultyName': faculty?.name ?? 'Assigned Faculty',
    'advisorName': 'Mrs. V. Nandhini, AP/CA',
  };
}

/// Parses a time string like "9:40 AM" or "2:00 PM" into a [DateTime] for today.
DateTime _parseTimeToday(String timeStr) {
  final now = DateTime.now();
  final clean = timeStr.trim().toUpperCase();
  final isPm = clean.endsWith('PM');
  final parts = clean.replaceAll(RegExp(r'[AMP ]'), '').split(':');
  int hour = int.parse(parts[0]);
  final int minute = parts.length > 1 ? int.parse(parts[1]) : 0;
  if (isPm && hour != 12) hour += 12;
  if (!isPm && hour == 12) hour = 0;
  return DateTime(now.year, now.month, now.day, hour, minute);
}

/// Returns true if [periodNo]'s end time has already passed (auto time-lock).
bool isPeriodTimeLocked(int periodNo) {
  final idx = periodNo - 1;
  if (idx < 0 || idx >= kMcaPeriodTimings.length) return false;
  final endTime = _parseTimeToday(kMcaPeriodTimings[idx].endTime);
  return DateTime.now().isAfter(endTime);
}

/// Returns the currently active period number based on wall-clock time.
/// Returns null if before the first period or after the last period of the day.
int? getActivePeriodNo() {
  final now = DateTime.now();
  for (final p in kMcaPeriodTimings) {
    final start = _parseTimeToday(p.startTime);
    final end = _parseTimeToday(p.endTime);
    if (now.isAfter(start.subtract(const Duration(minutes: 5))) && now.isBefore(end)) {
      return p.periodNo;
    }
  }
  // Default to Period 1 (official daily class lecture) outside scheduled class hours
  return 1;
}

/// Gets the subject abbreviation for [periodNo] on [date] (defaults to today).
String getPeriodSubject(int periodNo, [DateTime? date]) {
  final d = date ?? DateTime.now();
  final dayNames = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
  final dayName = dayNames[d.weekday - 1];
  final slot = kMcaTimeTable.firstWhere(
    (s) => s.day.toLowerCase() == dayName.toLowerCase(),
    orElse: () => kMcaTimeTable.first,
  );
  final idx = periodNo - 1;
  if (idx >= 0 && idx < slot.periods.length) return slot.periods[idx];
  return '';
}
