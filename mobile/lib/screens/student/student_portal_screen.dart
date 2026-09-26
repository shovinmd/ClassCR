import 'package:flutter/material.dart';
import '../../core/theme.dart';
import '../../data/mca_faculty.dart';
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
    final Student student = matched ?? (state.students.isNotEmpty ? state.students.first : const Student(
      rollNo: 1,
      name: 'STUDENT',
      enrollmentNo: '260001',
      dob: '01/01/2004',
      ccrCode: 'STU001',
      classId: 'I-MCA-A',
      department: 'MCA',
    ));

    // Aggregate all unique real attendance records from Supabase (history + today's periods)
    final Map<String, AttendanceRecord> allUniqueRecords = {};
    for (final rec in state.history) {
      allUniqueRecords[rec.id] = rec;
    }
    for (final rec in state.periodRecords.values) {
      allUniqueRecords[rec.id] = rec;
    }
    final allRecords = allUniqueRecords.values.toList();

    final int totalConducted = allRecords.length;
    final int absentLectures = allRecords.where((r) => r.absentRolls.contains(student.rollNo)).length;
    final int presentLectures = totalConducted - absentLectures;
    final double percentage = totalConducted > 0
        ? double.parse(((presentLectures / totalConducted) * 100).toStringAsFixed(1))
        : 100.0;
    final isEligible = percentage >= 75.0;

    // Today's live period checks
    final markedTodayEntries = state.periodRecords.entries.toList()
      ..sort((a, b) => a.key.compareTo(b.key));
    final absentTodayEntries = markedTodayEntries
        .where((e) => e.value.absentRolls.contains(student.rollNo))
        .toList();

    return RefreshIndicator(
      onRefresh: () async {
        await state.fetchRealtimeAttendance();
      },
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
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
                        const SizedBox(height: 4),
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
                  IconButton(
                    icon: const Icon(Icons.person_search_outlined, color: Colors.white),
                    tooltip: 'Change / Select Student',
                    onPressed: () => _showStudentPickerDialog(context),
                  ),
                  IconButton(
                    icon: const Icon(Icons.refresh, color: Colors.white),
                    tooltip: 'Refresh from Supabase',
                    onPressed: () async {
                      await state.fetchRealtimeAttendance();
                    },
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // TODAY'S LIVE STATUS BANNER
            _buildTodayLiveStatusBanner(markedTodayEntries, absentTodayEntries),

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
                      _buildSubMetric('Lectures Conducted', '$totalConducted', AppColors.textPrimary),
                      _buildSubMetric('Present', '$presentLectures', AppColors.presentGreen),
                      _buildSubMetric('Absent', '$absentLectures', AppColors.absentRed),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // TODAY'S LIVE PERIOD-BY-PERIOD SCHEDULE
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  "Today's Period Schedule",
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                ),
                Text(
                  '${markedTodayEntries.length} / 8 Marked',
                  style: const TextStyle(fontSize: 12, color: AppColors.primary, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 12),

            ...List.generate(8, (index) {
              final pNum = index + 1;
              final timing = index < kMcaPeriodTimings.length
                  ? '${kMcaPeriodTimings[index].startTime} - ${kMcaPeriodTimings[index].endTime}'
                  : 'Period $pNum';
              final subjectAbb = getPeriodSubject(pNum);
              final faculty = getFacultyForSubject(subjectAbb);
              final rec = state.periodRecords[pNum];

              return _buildPeriodScheduleTile(
                periodNo: pNum,
                timing: timing,
                subjectAbb: subjectAbb,
                facultyName: faculty?.name ?? 'Assigned Faculty',
                record: rec,
                studentRoll: student.rollNo,
              );
            }),

            const SizedBox(height: 24),

            // OFFICIAL SUBJECTS BREAKDOWN (FROM REAL SUPABASE RECORDS)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Subject-wise Attendance',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                ),
                const Text(
                  'Hall 408 • I MCA',
                  style: TextStyle(fontSize: 12, color: AppColors.textSecondary, fontWeight: FontWeight.w600),
                ),
              ],
            ),
            const SizedBox(height: 12),

            ..._buildSubjectBreakdownTiles(allRecords, student.rollNo),

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
                        const Text(
                          'Batch 2026–2028 • Hall 408',
                          style: TextStyle(fontSize: 11, color: AppColors.textMuted),
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
      ),
    );
  }

  Widget _buildTodayLiveStatusBanner(
    List<MapEntry<int, AttendanceRecord>> markedToday,
    List<MapEntry<int, AttendanceRecord>> absentToday,
  ) {
    if (markedToday.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFFF0F9FF),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFBAE6FD)),
        ),
        child: Row(
          children: [
            const Icon(Icons.schedule, color: Color(0xFF0284C7), size: 28),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "TODAY: ATTENDANCE IN PROGRESS",
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w900,
                      color: Color(0xFF0369A1),
                    ),
                  ),
                  const SizedBox(height: 2),
                  const Text(
                    "No periods have been submitted by the CR yet for today.",
                    style: TextStyle(fontSize: 11, color: Color(0xFF075985)),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    final hasAbsence = absentToday.isNotEmpty;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: hasAbsence ? const Color(0xFFFEF2F2) : const Color(0xFFF0FDF4),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: hasAbsence ? const Color(0xFFFCA5A5) : const Color(0xFF86EFAC),
        ),
      ),
      child: Row(
        children: [
          Icon(
            hasAbsence ? Icons.cancel : Icons.check_circle,
            color: hasAbsence ? AppColors.absentRed : AppColors.presentGreen,
            size: 28,
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  hasAbsence
                      ? 'TODAY: MARKED ABSENT (${absentToday.length} Period${absentToday.length > 1 ? 's' : ''})'
                      : 'TODAY: ALL ${markedToday.length} MARKED PERIODS PRESENT ✓',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w900,
                    color: hasAbsence ? AppColors.absentRed : AppColors.presentGreen,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  hasAbsence
                      ? 'Recorded absent in: ${absentToday.map((e) => 'Period ${e.key} (${e.value.periodSubject ?? getPeriodSubject(e.key)})').join(', ')}. Inform Class Advisor for on-duty/medical exemption.'
                      : 'Verified by CR ${state.delegation.crName}. You are present in all ${markedToday.length} marked period(s) today.',
                  style: TextStyle(
                    fontSize: 11,
                    color: hasAbsence ? const Color(0xFF991B1B) : const Color(0xFF166534),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPeriodScheduleTile({
    required int periodNo,
    required String timing,
    required String subjectAbb,
    required String facultyName,
    required AttendanceRecord? record,
    required int studentRoll,
  }) {
    final isMarked = record != null;
    final isAbsent = isMarked && record.absentRolls.contains(studentRoll);

    Color badgeBg;
    Color badgeFg;
    String badgeText;

    if (!isMarked) {
      badgeBg = const Color(0xFFF1F5F9);
      badgeFg = const Color(0xFF64748B);
      badgeText = 'Awaiting CR';
    } else if (isAbsent) {
      badgeBg = const Color(0xFFFEE2E2);
      badgeFg = AppColors.absentRed;
      badgeText = '❌ Absent';
    } else {
      badgeBg = const Color(0xFFDCFCE7);
      badgeFg = AppColors.presentGreen;
      badgeText = '✅ Present';
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isMarked
              ? (isAbsent ? const Color(0xFFFCA5A5) : const Color(0xFFBBF7D0))
              : AppColors.cardBorder,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: isMarked
                  ? (isAbsent ? const Color(0xFFFEE2E2) : const Color(0xFFDCFCE7))
                  : const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Center(
              child: Text(
                'P$periodNo',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                  color: isMarked
                      ? (isAbsent ? AppColors.absentRed : AppColors.presentGreen)
                      : AppColors.textSecondary,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      subjectAbb,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      '• $timing',
                      style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  facultyName,
                  style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: badgeBg,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              badgeText,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: badgeFg,
              ),
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildSubjectBreakdownTiles(List<AttendanceRecord> allRecords, int studentRoll) {
    final List<Map<String, String>> subjects = [
      {
        'abb': 'MAT',
        'title': 'Mathematical Foundation of Computer Applications (MAT)',
        'teacher': 'Dr. S. Sivaramakrishnan, Prof/Maths',
      },
      {
        'abb': 'OOPS',
        'title': 'Object oriented Programming in C++ (OOPS) & Lab',
        'teacher': 'Mrs. V. Nandhini, AP/CA (Class Advisor)',
      },
      {
        'abb': 'DT',
        'title': 'Database Technology (DT) & Lab',
        'teacher': 'Mrs. K. Shivashankari, AP/CA',
      },
      {
        'abb': 'OS',
        'title': 'Operating Systems (OS) & Lab',
        'teacher': 'Ms. M. Tamilmani, AP/CA',
      },
      {
        'abb': 'SE',
        'title': 'Software Engineering (SE)',
        'teacher': 'Ms. V. Deepa, AP/CA',
      },
    ];

    return subjects.map((sub) {
      final abb = sub['abb']!;
      final title = sub['title']!;
      final teacher = sub['teacher']!;

      // Filter matching records from real database
      final matching = allRecords.where((r) {
        final ps = (r.periodSubject ?? '').toUpperCase();
        return ps.contains(abb);
      }).toList();

      final int conducted = matching.length;
      final int attended = matching.where((r) => !r.absentRolls.contains(studentRoll)).length;
      final double percent = conducted > 0
          ? double.parse(((attended / conducted) * 100).toStringAsFixed(1))
          : 100.0;
      final String ratio = conducted > 0 ? '$attended / $conducted' : '0 / 0 (No classes held yet)';

      return _buildSubjectTile(title, teacher, ratio, percent);
    }).toList();
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

  void _showStudentPickerDialog(BuildContext context) {
    Student? selected = state.students.isNotEmpty ? state.students.first : null;
    final codeController = TextEditingController();
    String error = '';

    showDialog(
      context: context,
      builder: (dialogCtx) => StatefulBuilder(
        builder: (ctx, setDialogState) {
          void updateFromInput(String val) {
            final trimmed = val.trim().toUpperCase();
            if (trimmed.isEmpty) return;
            final match = state.students.cast<Student?>().firstWhere(
              (s) => s != null && (
                s.rollNo.toString() == trimmed ||
                s.code.toUpperCase() == trimmed ||
                'CCR-${s.rollNo}' == trimmed ||
                'CCR-${s.rollNo.toString().padLeft(4, '0')}' == trimmed ||
                s.enrollmentNo.toUpperCase() == trimmed
              ),
              orElse: () => null,
            );
            if (match != null) {
              setDialogState(() {
                selected = match;
                error = '';
              });
            }
          }

          return AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
            title: const Row(
              children: [
                Icon(Icons.school_outlined, color: AppColors.presentGreen),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Select Student Portal',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Enter your Roll Number (1–52) or CCR Code:',
                    style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: codeController,
                    textCapitalization: TextCapitalization.characters,
                    decoration: const InputDecoration(
                      labelText: 'Roll No or CCR Code',
                      hintText: 'e.g. 13 or CCR-0013',
                      prefixIcon: Icon(Icons.pin, size: 20),
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    ),
                    onChanged: updateFromInput,
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Or select from class roster:',
                    style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                  ),
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      border: Border.all(color: AppColors.cardBorder),
                      borderRadius: BorderRadius.circular(10),
                      color: const Color(0xFFF8FAFC),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<Student>(
                        isExpanded: true,
                        value: selected,
                        hint: const Text('Select student name'),
                        items: state.students.map((st) {
                          return DropdownMenuItem<Student>(
                            value: st,
                            child: Text(
                              '${st.rollNo}. ${st.name} (${st.enrollmentNo})',
                              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                              overflow: TextOverflow.ellipsis,
                            ),
                          );
                        }).toList(),
                        onChanged: (val) {
                          setDialogState(() {
                            selected = val;
                            if (val != null) {
                              codeController.text = val.rollNo.toString();
                              error = '';
                            }
                          });
                        },
                      ),
                    ),
                  ),
                  if (selected != null) ...[
                    const SizedBox(height: 14),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFECFDF5),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: const Color(0xFFA7F3D0)),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            selected!.isFemale ? Icons.female : Icons.male,
                            color: AppColors.presentGreen,
                            size: 20,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  selected!.name,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13,
                                    color: Color(0xFF065F46),
                                  ),
                                ),
                                Text(
                                  'Roll #${selected!.rollNo} • Code: ${selected!.code}',
                                  style: const TextStyle(fontSize: 11, color: Color(0xFF047857)),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                  if (error.isNotEmpty) ...[
                    const SizedBox(height: 10),
                    Text(
                      error,
                      style: const TextStyle(fontSize: 12, color: AppColors.absentRed, fontWeight: FontWeight.bold),
                    ),
                  ],
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogCtx),
                child: const Text('Cancel'),
              ),
              ElevatedButton.icon(
                icon: const Icon(Icons.check_circle_outline, size: 18),
                label: const Text('View Attendance'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.presentGreen,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                onPressed: () async {
                  final entered = codeController.text.trim().toUpperCase();
                  if (entered.isNotEmpty) {
                    final res = await state.verifyRolePasscode(
                      classId: 'I-MCA-A',
                      role: UserRole.student,
                      code: entered,
                      rollNo: selected?.rollNo,
                    );
                    if (res['valid'] != true) {
                      setDialogState(() {
                        error = res['error']?.toString() ?? 'Invalid Roll No or CCR Code.';
                      });
                      return;
                    }
                  }
                  if (selected == null) return;
                  Navigator.pop(dialogCtx);
                  state.switchRole(
                    UserRole.student,
                    customName: selected!.name,
                    customStudentId: selected!.enrollmentNo,
                    customGender: selected!.isFemale ? 'F' : 'M',
                  );
                },
              ),
            ],
          );
        },
      ),
    );
  }
}
