class FacultyMember {
  final String name;
  final String designation;
  final String department;
  final String role;
  final String? subject;
  final String? subjectCode;
  final String? hallNo;
  final int? hours;

  const FacultyMember({
    required this.name,
    required this.designation,
    this.department = 'MCA',
    required this.role,
    this.subject,
    this.subjectCode,
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
      hallNo: json['hallNo']?.toString(),
      hours: json['hours'] is int ? json['hours'] : int.tryParse(json['hours']?.toString() ?? '15'),
    );
  }
}

// Official MCA Teachers from Manakula Vinayagar Institute of Technology
const List<FacultyMember> kOfficialMcaFaculty = [
  FacultyMember(
    name: 'Mrs. V. Nandhini, AP/CA',
    designation: 'Assistant Professor',
    department: 'MCA',
    role: 'Class Advisor',
    subject: 'Class Advisor & Mentor',
    hallNo: '408',
  ),
  FacultyMember(
    name: 'Ms. M. Tamilmani, AP/CA',
    designation: 'Assistant Professor',
    department: 'MCA',
    role: 'Subject Teacher',
    subject: 'Fundamentals of Computer Programming (FCP)',
    subjectCode: '25PMCY01',
    hours: 15,
  ),
  FacultyMember(
    name: 'Ms. V. Deepa, AP/CA',
    designation: 'Assistant Professor',
    department: 'MCA',
    role: 'Subject Teacher',
    subject: 'Introduction to Problem Solving (IPS)',
    subjectCode: '25PMCY02',
    hours: 15,
  ),
  FacultyMember(
    name: 'Ms. M. Shakira Banu, AP/CA',
    designation: 'Assistant Professor',
    department: 'MCA',
    role: 'Subject Teacher',
    subject: 'Introduction to Computer Organization (ICO)',
    subjectCode: '25PMCY03',
    hours: 15,
  ),
  FacultyMember(
    name: 'Ms. S. Sharleen Banou, AP/CA',
    designation: 'Assistant Professor',
    department: 'MCA',
    role: 'Subject Teacher',
    subject: 'Fundamentals of Web Applications (FWA)',
    subjectCode: '25PMCY04',
    hours: 15,
  ),
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
    periods: ['IPS', 'FCP', 'IPS', 'FWA', 'FCP', 'FCP', 'ICO', 'IPS'],
  ),
  TimeTableSlot(
    day: 'Tuesday',
    periods: ['FWA', 'FCP', 'ICO', 'ICO', 'FWA', 'FWA', 'IPS', 'ICO'],
  ),
  TimeTableSlot(
    day: 'Wednesday',
    periods: ['ICO', 'IPS', 'FWA', 'FWA', 'FCP', 'ICO', 'FWA', 'IPS'],
  ),
  TimeTableSlot(
    day: 'Thursday',
    periods: ['IPS', 'ICO', 'FCP', 'IPS', 'IPS', 'FWA', 'FCP', 'ICO'],
  ),
  TimeTableSlot(
    day: 'Friday',
    periods: ['FCP', 'FCP', 'ICO', 'FWA', 'FWA', 'IPS', 'ICO', 'FCP'],
  ),
  TimeTableSlot(
    day: 'Saturday',
    periods: ['ICO', 'IPS', 'FWA', 'FWA', 'ICO', 'IPS', 'FCP', 'FCP'],
  ),
];
