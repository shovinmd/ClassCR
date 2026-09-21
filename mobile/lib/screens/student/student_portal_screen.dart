import 'package:flutter/material.dart';
import '../../core/theme.dart';
import '../../models/models.dart';
import '../../providers/classcr_state.dart';

class StudentPortalScreen extends StatelessWidget {
  final ClassCRState state;

  const StudentPortalScreen({super.key, required this.state});

  @override
  Widget build(BuildContext context) {
    final currentUser = state.currentUser;

    // Detect logged in student from state.students
    Student? matched;
    if (currentUser.studentId != null && currentUser.studentId!.isNotEmpty) {
      matched = state.students.cast<Student?>().firstWhere(
        (s) => s?.enrollmentNo == currentUser.studentId || s?.rollNo.toString() == currentUser.studentId,
        orElse: () => null,
      );
    }
    if (matched == null) {
      final cleanName = currentUser.name.replaceAll(RegExp(r'\s*\([^)]*\)'), '').trim().toUpperCase();
      matched = state.students.cast<Student?>().firstWhere(
        (s) => s?.name.toUpperCase() == cleanName,
        orElse: () => null,
      );
    }
    final Student student = matched ?? state.students.first;

    final isAbsentToday = state.isAbsent(student.rollNo);

    // Dynamic attendance calculations based on real history
    final history = state.history;
    final int pastDays = history.isEmpty ? 5 : history.length;
    // Each college day has ~7 hours/lectures
    final int conducted = (pastDays + 1) * 7;
    int absentLectures = 0;
    for (final record in history) {
      if (record.absentRolls.contains(student.rollNo)) {
        absentLectures += 7;
      }
    }
    if (isAbsentToday) {
      absentLectures += 7;
    }
    final int presentLectures = (conducted - absentLectures).clamp(0, conducted);
    final double percentage = conducted > 0
        ? double.parse(((presentLectures / conducted) * 100).toStringAsFixed(1))
        : 100.0;

    final isEligible = percentage >= 75.0;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Student Profile Card
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: AppColors.primaryGradient,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withOpacity(0.2),
                  blurRadius: 12,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 30,
                  backgroundColor: Colors.white,
                  child: Text(
                    student.name.isNotEmpty ? student.name[0] : 'S',
                    style: const TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        student.name,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Roll No: ${student.rollNo} • Enrollment: ${student.enrollmentNo}',
                        style: const TextStyle(fontSize: 12, color: Colors.white70),
                      ),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              student.code,
                              style: const TextStyle(
                                fontSize: 11,
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          const Text(
                            'I MCA A • Batch 2026–2028',
                            style: TextStyle(fontSize: 11, color: Color(0xFF67E8F9), fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // TODAY'S LIVE STATUS BANNER
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isAbsentToday ? const Color(0xFFFEF2F2) : const Color(0xFFF0FDF4),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isAbsentToday ? const Color(0xFFFCA5A5) : const Color(0xFF86EFAC),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  isAbsentToday ? Icons.cancel : Icons.check_circle,
                  color: isAbsentToday ? AppColors.absentRed : AppColors.presentGreen,
                  size: 28,
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isAbsentToday ? 'TODAY: MARKED ABSENT' : 'TODAY: MARKED PRESENT ✓',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w900,
                          color: isAbsentToday ? AppColors.absentRed : AppColors.presentGreen,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        isAbsentToday
                            ? 'Morning attendance recorded absent. Inform Class Advisor if you have on-duty / medical leave.'
                            : 'Attendance marked by CR ${state.delegation.crName}. You are present for all lectures today.',
                        style: TextStyle(
                          fontSize: 11,
                          color: isAbsentToday ? const Color(0xFF991B1B) : const Color(0xFF166534),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // Attendance Percentage Big Stat Card
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppColors.cardBorder),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'ATTENDANCE OVERVIEW',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textSecondary,
                        letterSpacing: 1,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: (isEligible ? AppColors.presentGreen : AppColors.absentRed).withOpacity(0.12),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            isEligible ? Icons.verified : Icons.warning_amber,
                            size: 14,
                            color: isEligible ? AppColors.presentGreen : AppColors.absentRed,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            isEligible ? 'ELIGIBLE (>75%)' : 'SHORTAGE ALERT (<75%)',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: isEligible ? AppColors.presentGreen : AppColors.absentRed,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // Big percentage number and circular indicator
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '$percentage%',
                            style: TextStyle(
                              fontSize: 40,
                              fontWeight: FontWeight.w900,
                              color: isEligible ? AppColors.primary : AppColors.absentRed,
                              height: 1,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            isEligible
                                ? 'Safe above University 75% eligibility threshold. Keep it up!'
                                : 'Attendance is below 75%. Meet Class Advisor Mrs. V. Nandhini immediately.',
                            style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(
                      width: 70,
                      height: 70,
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          CircularProgressIndicator(
                            value: (percentage / 100).clamp(0.0, 1.0),
                            strokeWidth: 8,
                            backgroundColor: const Color(0xFFE2E8F0),
                            valueColor: AlwaysStoppedAnimation<Color>(
                              isEligible ? AppColors.presentGreen : AppColors.absentRed,
                            ),
                          ),
                          Center(
                            child: Icon(
                              isEligible ? Icons.school : Icons.warning,
                              color: isEligible ? AppColors.primary : AppColors.absentRed,
                              size: 24,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 20),
                const Divider(height: 1),
                const SizedBox(height: 16),

                // Conducted / Present / Absent metrics row
                Row(
                  children: [
                    _buildSubMetric('Lectures Conducted', '$conducted', AppColors.textPrimary),
                    _buildSubMetric('Present', '$presentLectures', AppColors.presentGreen),
                    _buildSubMetric('Absent', '$absentLectures', AppColors.absentRed),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Official Subjects Breakdown from Time Table
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Subject-wise Attendance',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
              ),
              Text(
                'Hall 408 • I MCA',
                style: const TextStyle(fontSize: 12, color: AppColors.textSecondary, fontWeight: FontWeight.w600),
              ),
            ],
          ),
          const SizedBox(height: 12),

          _buildSubjectTile(
            'Mathematical Foundation of Computer Applications (MAT)',
            'Dr. S. Sivaramakrishnan, Prof/Maths',
            '${(conducted * 0.19).round() - (isAbsentToday ? 1 : 0)} / ${(conducted * 0.19).round()}',
            isAbsentToday ? (percentage - 2).clamp(50, 100).toDouble() : (percentage + 1).clamp(50, 100).toDouble(),
          ),
          _buildSubjectTile(
            'Object oriented Programming in C++ (OOPS) & Lab',
            'Mrs. V. Nandhini, AP/CA (Class Advisor)',
            '${(conducted * 0.26).round() - (isAbsentToday ? 1 : 0)} / ${(conducted * 0.26).round()}',
            isAbsentToday ? (percentage - 1).clamp(50, 100).toDouble() : percentage,
          ),
          _buildSubjectTile(
            'Database Technology (DT) & Lab',
            'Mrs. K. Shivashankari, AP/CA',
            '${(conducted * 0.26).round() - (isAbsentToday ? 1 : 0)} / ${(conducted * 0.26).round()}',
            isAbsentToday ? (percentage - 3).clamp(50, 100).toDouble() : (percentage + 2).clamp(50, 100).toDouble(),
          ),
          _buildSubjectTile(
            'Operating Systems (OS) & Lab',
            'Ms. M. Tamilmani, AP/CA',
            '${(conducted * 0.26).round() - (isAbsentToday ? 1 : 0)} / ${(conducted * 0.26).round()}',
            percentage,
          ),
          _buildSubjectTile(
            'Software Engineering (SE)',
            'Ms. V. Deepa, AP/CA',
            '${(conducted * 0.14).round() - (isAbsentToday ? 1 : 0)} / ${(conducted * 0.14).round()}',
            isAbsentToday ? (percentage - 1).clamp(50, 100).toDouble() : (percentage + 3).clamp(50, 100).toDouble(),
          ),

          const SizedBox(height: 24),

          // Class Announcements from Advisor
          const Text(
            'Class Advisor Notice Board',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
          ),
          const SizedBox(height: 12),

          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.cardBorder),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFEF3C7),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.campaign, color: Color(0xFFD97706), size: 24),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Class Advisor: Mrs. V. Nandhini, AP/CA',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'Ensure all OOPS, OS, and Database Technology lab observation records are maintained up-to-date for internal assessment.',
                        style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Batch 2026–2028 • Hall 408',
                        style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildSubMetric(String label, String value, Color color) {
    return Expanded(
      child: Column(
        children: [
          Text(
            value,
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: color),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }

  Widget _buildSubjectTile(String title, String teacher, String ratio, double percent) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      teacher,
                      style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '$percent%',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                  color: percent >= 75 ? AppColors.presentGreen : AppColors.absentRed,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: (percent / 100).clamp(0.0, 1.0),
              backgroundColor: const Color(0xFFF1F5F9),
              valueColor: AlwaysStoppedAnimation<Color>(
                percent >= 75 ? AppColors.presentGreen : AppColors.absentRed,
              ),
              minHeight: 6,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Attended: $ratio hours',
            style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }
}
