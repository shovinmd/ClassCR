import 'package:flutter/material.dart';
import '../../core/theme.dart';
import '../../data/mca_faculty.dart';
import '../../providers/classcr_state.dart';

class StaffDashboardScreen extends StatefulWidget {
  final ClassCRState state;

  const StaffDashboardScreen({super.key, required this.state});

  @override
  State<StaffDashboardScreen> createState() => _StaffDashboardScreenState();
}

class _StaffDashboardScreenState extends State<StaffDashboardScreen> {
  late FacultyMember _selectedFaculty;
  bool _isAcknowledged = false;

  @override
  void initState() {
    super.initState();
    // Default to faculty from currentUser or first official MCA faculty
    final currentUserName = widget.state.currentUser.name;
    _selectedFaculty = kOfficialMcaFaculty.firstWhere(
      (f) => currentUserName.contains(f.name.split(',')[0]),
      orElse: () => kOfficialMcaFaculty[3], // Default: Ms. M. Tamilmani (OS)
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = widget.state;
    final now = DateTime.now();
    final dayNames = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
    final todayDayName = dayNames[now.weekday - 1];

    // Find today's timetable slot
    final todaySlot = kMcaTimeTable.firstWhere(
      (s) => s.day.toLowerCase() == todayDayName.toLowerCase(),
      orElse: () => kMcaTimeTable.first,
    );

    // Filter periods taught by this faculty member today
    final myPeriodsToday = <Map<String, dynamic>>[];
    for (int i = 0; i < todaySlot.periods.length; i++) {
      final periodAbb = todaySlot.periods[i];
      final facultyForPeriod = getFacultyForSubject(periodAbb);
      if (facultyForPeriod != null && facultyForPeriod.name == _selectedFaculty.name) {
        final timing = kMcaPeriodTimings[i];
        myPeriodsToday.add({
          'periodNo': i + 1,
          'timing': timing,
          'subjectAbb': periodAbb,
          'isFirstPeriod': i == 0,
        });
      }
    }

    final absentStudents = state.students.where((s) => state.isAbsent(s.rollNo)).toList();
    final firstPeriodInfo = getFirstPeriodDetailsForDate(now);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Faculty Profile Switcher Card
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF0284C7), Color(0xFF0369A1)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF0284C7).withOpacity(0.25),
                  blurRadius: 12,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      radius: 26,
                      backgroundColor: Colors.white,
                      child: Text(
                        _selectedFaculty.name.contains('.')
                            ? _selectedFaculty.name.split('.')[1].trim()[0]
                            : 'F',
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF0284C7),
                        ),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _selectedFaculty.name,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '${_selectedFaculty.designation} • ${_selectedFaculty.department}',
                            style: const TextStyle(fontSize: 12, color: Colors.white70),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '${_selectedFaculty.subject ?? _selectedFaculty.role} • Hall ${_selectedFaculty.hallNo ?? "408"}',
                            style: const TextStyle(
                              fontSize: 11,
                              color: Color(0xFFBAE6FD),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                const Divider(color: Colors.white24, height: 1),
                const SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Switch Faculty Profile:',
                      style: TextStyle(fontSize: 11, color: Colors.white70, fontWeight: FontWeight.w500),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<FacultyMember>(
                          dropdownColor: const Color(0xFF0369A1),
                          iconEnabledColor: Colors.white,
                          value: _selectedFaculty,
                          style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                          items: kOfficialMcaFaculty.map((f) {
                            return DropdownMenuItem<FacultyMember>(
                              value: f,
                              child: Text(
                                '${f.name.split(',')[0]} (${f.subjectAbb ?? f.role})',
                                style: const TextStyle(color: Colors.white),
                              ),
                            );
                          }).toList(),
                          onChanged: (val) {
                            if (val != null) {
                              setState(() {
                                _selectedFaculty = val;
                                _isAcknowledged = false;
                              });
                            }
                          },
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // TODAY'S LECTURE SESSION CARD
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: AppColors.cardBorder),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.04),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.calendar_today, size: 16, color: AppColors.primary),
                        const SizedBox(width: 8),
                        Text(
                          '$todayDayName • ${state.formattedTodayDate}',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.deepBlue),
                        ),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        'ClassCR Live Sync ✓',
                        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.primary),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),

                // Notice on Morning 1st Hour Attendance Dispatch
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEFF6FF),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFBFDBFE)),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.wb_sunny_outlined, color: Color(0xFF2563EB), size: 20),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Morning 1st Lecture Attendance Delivery',
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF1E40AF)),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Period 1: ${firstPeriodInfo['subjectAbb']} (${firstPeriodInfo['time']})\nFaculty: ${firstPeriodInfo['facultyName']}\nClass Advisor: Mrs. V. Nandhini, AP/CA',
                              style: const TextStyle(fontSize: 11, color: Color(0xFF1E3A8A)),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // Scheduled periods for this teacher today
                const Text(
                  'Your Timetable Lectures Today:',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                ),
                const SizedBox(height: 8),

                if (myPeriodsToday.isEmpty)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      'No direct lecture periods scheduled for ${_selectedFaculty.name.split(',')[0]} on $todayDayName. Available as Class Advisor & Mentor.',
                      style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                    ),
                  )
                else
                  Column(
                    children: myPeriodsToday.map((p) {
                      final timing = p['timing'] as PeriodTiming;
                      final isFirst = p['isFirstPeriod'] == true;
                      return Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: isFirst ? const Color(0xFFF0FDF4) : const Color(0xFFF8FAFC),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isFirst ? const Color(0xFF86EFAC) : AppColors.cardBorder,
                          ),
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: isFirst ? AppColors.presentGreen : AppColors.primary,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                'P${p['periodNo']}',
                                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    '${p['subjectAbb']} • Hall 408',
                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                                  ),
                                  Text(
                                    '${timing.startTime} - ${timing.endTime} • ${timing.label}',
                                    style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                                  ),
                                ],
                              ),
                            ),
                            if (isFirst)
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: AppColors.presentGreen.withOpacity(0.15),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: const Text(
                                  '1st Period',
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.presentGreen,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // LECTURE ATTENDANCE STATS CARD
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: AppColors.cardBorder),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Live Attendance for Lecture',
                      style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.deepBlue),
                    ),
                    Text(
                      'Marked by: ${state.delegation.crName} (CR)',
                      style: const TextStyle(fontSize: 11, color: AppColors.textSecondary, fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                Row(
                  children: [
                    _buildStatPill('Total', '${state.totalCount}', AppColors.textPrimary, const Color(0xFFF1F5F9)),
                    const SizedBox(width: 8),
                    _buildStatPill('Present', '${state.presentCount}', AppColors.presentGreen, const Color(0xFFDCFCE7)),
                    const SizedBox(width: 8),
                    _buildStatPill('Absent', '${state.absentCount}', AppColors.absentRed, const Color(0xFFFEE2E2)),
                    const SizedBox(width: 8),
                    _buildStatPill(
                      'Rate',
                      '${((state.presentCount / state.totalCount) * 100).toStringAsFixed(1)}%',
                      AppColors.primary,
                      const Color(0xFFE0F2FE),
                    ),
                  ],
                ),

                const SizedBox(height: 16),
                const Divider(height: 1),
                const SizedBox(height: 14),

                // Absent students list
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Absent Students (${absentStudents.length}):',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.absentRed),
                    ),
                    const Text(
                      'Sent to Advisor & Faculty',
                      style: TextStyle(fontSize: 11, color: AppColors.textSecondary),
                    ),
                  ],
                ),
                const SizedBox(height: 8),

                if (absentStudents.isEmpty)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF0FDF4),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Text(
                      '🎉 100% Full Attendance! All 52 students present in class today.',
                      style: TextStyle(fontSize: 12, color: AppColors.presentGreen, fontWeight: FontWeight.bold),
                    ),
                  )
                else
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: absentStudents.map((st) {
                      return Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFEF2F2),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: const Color(0xFFFECACA)),
                        ),
                        child: Text(
                          'Roll ${st.rollNo} • ${st.name} (${st.code})',
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF991B1B),
                          ),
                        ),
                      );
                    }).toList(),
                  ),

                const SizedBox(height: 20),

                // Faculty Acknowledgment Button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _isAcknowledged
                        ? null
                        : () {
                            setState(() => _isAcknowledged = true);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('✅ Lecture attendance acknowledged and recorded for ${_selectedFaculty.name}!'),
                                backgroundColor: AppColors.presentGreen,
                              ),
                            );
                          },
                    icon: Icon(_isAcknowledged ? Icons.check_circle : Icons.verified_user),
                    label: Text(_isAcknowledged ? '✓ Attendance Acknowledged by Faculty' : 'Acknowledge & Record Lecture Attendance'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _isAcknowledged ? const Color(0xFF64748B) : AppColors.presentGreen,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatPill(String label, String value, Color textColor, Color bgColor) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Text(
              value,
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: textColor),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.textSecondary),
            ),
          ],
        ),
      ),
    );
  }
}
