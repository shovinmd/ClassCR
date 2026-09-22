import 'package:flutter/material.dart';
import '../../core/theme.dart';
import '../../data/mca_faculty.dart';
import '../../models/models.dart';
import '../../providers/classcr_state.dart';

class SubjectAttendanceScreen extends StatefulWidget {
  final ClassCRState state;

  const SubjectAttendanceScreen({super.key, required this.state});

  @override
  State<SubjectAttendanceScreen> createState() => _SubjectAttendanceScreenState();
}

class _SubjectAttendanceScreenState extends State<SubjectAttendanceScreen> {
  int _selectedPeriod = 1;
  String _sectionTab = 'all'; // 'all', 'boys', 'girls'
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _selectedPeriod = widget.state.viewingPeriodNo;
    widget.state.switchToPeriod(_selectedPeriod);
    final isAsstCr = widget.state.currentRole == UserRole.assistantCr;
    final asstGender = widget.state.currentUser.gender;
    if (isAsstCr) {
      if (asstGender == 'M') {
        _sectionTab = 'boys'; // Male priority
      } else if (asstGender == 'F') {
        _sectionTab = 'girls'; // Female priority
      }
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  int get totalBoys => widget.state.students.where((s) => s.isMale).length;
  int get presentBoys => widget.state.students.where((s) => s.isMale && widget.state.isPresent(s.rollNo)).length;
  int get absentBoys => totalBoys - presentBoys;

  int get totalGirls => widget.state.students.where((s) => s.isFemale).length;
  int get presentGirls => widget.state.students.where((s) => s.isFemale && widget.state.isPresent(s.rollNo)).length;
  int get absentGirls => totalGirls - presentGirls;

  List<Student> get filteredStudents {
    final isAsstCr = widget.state.currentRole == UserRole.assistantCr;
    final asstGender = widget.state.currentUser.gender;

    final list = widget.state.students.where((st) {
      final matchesSearch = _searchQuery.isEmpty ||
          st.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          st.enrollmentNo.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          st.rollNo.toString() == _searchQuery.trim();

      if (!matchesSearch) return false;

      if (_sectionTab == 'boys' && !st.isMale) return false;
      if (_sectionTab == 'girls' && !st.isFemale) return false;

      return true;
    }).toList();

    if (_sectionTab == 'all') {
      if (isAsstCr && asstGender == 'M') {
        list.sort((a, b) {
          if (a.isMale && !b.isMale) return -1;
          if (!a.isMale && b.isMale) return 1;
          return a.rollNo.compareTo(b.rollNo);
        });
      } else if (isAsstCr && asstGender == 'F') {
        list.sort((a, b) {
          if (a.isFemale && !b.isFemale) return -1;
          if (!a.isFemale && b.isFemale) return 1;
          return a.rollNo.compareTo(b.rollNo);
        });
      } else {
        list.sort((a, b) => a.rollNo.compareTo(b.rollNo));
      }
    }

    return list;
  }

  void _showConfirmAndDispatchDialog(FacultyMember faculty, String subjectName) {
    final absentees = widget.state.absentRolls.toList()..sort();
    final presentCount = widget.state.presentCount;
    final absentCount = widget.state.absentCount;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: EdgeInsets.only(
          top: 20,
          left: 20,
          right: 20,
          bottom: MediaQuery.of(context).viewInsets.bottom + 20,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Confirm All 52 Students',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0D9488).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    'Period $_selectedPeriod • $subjectName',
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF0D9488)),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Routing banner to respective staff
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFF0FDFA),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFF99F6E4)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.person_pin_outlined, color: Color(0xFF0F766E), size: 22),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Routes directly to Respective Staff:',
                          style: TextStyle(fontSize: 11, color: Color(0xFF115E59), fontWeight: FontWeight.bold),
                        ),
                        Text(
                          '${faculty.name} (${faculty.designation})',
                          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xFF134E4A)),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // Combined Stats
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  Column(
                    children: [
                      Text('${widget.state.totalCount}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      const Text('Total (52)', style: TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                    ],
                  ),
                  Column(
                    children: [
                      Text('$presentCount', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.presentGreen)),
                      Text('Boys: $presentBoys, Girls: $presentGirls', style: const TextStyle(fontSize: 10, color: AppColors.presentGreen)),
                    ],
                  ),
                  Column(
                    children: [
                      Text('$absentCount', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.absentRed)),
                      Text('Boys: $absentBoys, Girls: $absentGirls', style: const TextStyle(fontSize: 10, color: AppColors.absentRed)),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),

            Text(
              'Absentees (${absentees.length}):',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
            ),
            const SizedBox(height: 6),

            if (absentees.isEmpty)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFF0FDF4),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Text('🎉 Full Attendance! All 52 students present for this lecture.', style: TextStyle(color: AppColors.presentGreen, fontWeight: FontWeight.bold)),
              )
            else
              Container(
                constraints: const BoxConstraints(maxHeight: 140),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppColors.cardBorder),
                ),
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: absentees.length,
                  itemBuilder: (_, idx) {
                    final roll = absentees[idx];
                    final s = widget.state.students.firstWhere((st) => st.rollNo == roll);
                    return ListTile(
                      dense: true,
                      visualDensity: VisualDensity.compact,
                      leading: CircleAvatar(
                        radius: 12,
                        backgroundColor: AppColors.absentRed.withOpacity(0.15),
                        child: Text('${s.rollNo}', style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.absentRed)),
                      ),
                      title: Text(s.name, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                      subtitle: Text('${s.enrollmentNo} • ${s.isFemale ? "Girl" : "Boy"}', style: const TextStyle(fontSize: 11)),
                    );
                  },
                ),
              ),

            const SizedBox(height: 18),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () async {
                  Navigator.pop(ctx);
                  await widget.state.submitAttendance(
                    isLocked: true,
                    periodNo: _selectedPeriod,
                    periodSubject: subjectName,
                    notes: 'Subject attendance for Period $_selectedPeriod ($subjectName) routed to ${faculty.name}',
                  );

                  if (mounted) {
                    setState(() {});
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        backgroundColor: AppColors.presentGreen,
                        content: Text('✅ Period $_selectedPeriod ($subjectName) attendance dispatched directly to ${faculty.name}!'),
                      ),
                    );
                  }
                },
                icon: const Icon(Icons.send_rounded),
                label: Text('Confirm Combined 52 Students & Dispatch to ${faculty.name.split(',')[0]}'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0D9488),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final dayNames = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
    final dayName = dayNames[now.weekday - 1];

    final slot = kMcaTimeTable.firstWhere(
      (s) => s.day.toLowerCase() == dayName.toLowerCase(),
      orElse: () => kMcaTimeTable.first,
    );

    final currentSubj = (_selectedPeriod >= 1 && _selectedPeriod <= slot.periods.length)
        ? slot.periods[_selectedPeriod - 1]
        : 'OOPS';
    final faculty = getFacultyForSubject(currentSubj) ?? kOfficialMcaFaculty.first;
    final timing = kMcaPeriodTimings[(_selectedPeriod - 1).clamp(0, kMcaPeriodTimings.length - 1)];

    final isAsstCr = widget.state.currentRole == UserRole.assistantCr;
    final asstGender = widget.state.currentUser.gender;

    final record = widget.state.currentAttendanceRecord;
    final isDispatchedThisPeriod = record != null && record.periodNo == _selectedPeriod;
    final ackStatus = isDispatchedThisPeriod ? (record.facultyAcknowledgmentStatus ?? 'pending') : 'none';

    final studentsList = filteredStudents;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 1,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Subject Attendance', style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
            Text('$dayName • Period $_selectedPeriod: $currentSubj', style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
          ],
        ),
        actions: [
          Container(
            margin: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0xFF0D9488).withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.calendar_today, size: 12, color: Color(0xFF0D9488)),
                const SizedBox(width: 4),
                Text(widget.state.formattedTodayDate, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF0D9488))),
              ],
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // Period Selector Bar
          Container(
            color: Colors.white,
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Select Lecture Period Today:',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.textSecondary),
                ),
                const SizedBox(height: 8),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: List.generate(slot.periods.length, (idx) {
                      final pNum = idx + 1;
                      final pSubj = slot.periods[idx];
                      final isSelected = _selectedPeriod == pNum;
                      final isLocked = widget.state.isPeriodLocked(pNum);
                      return GestureDetector(
                        onTap: () {
                          widget.state.switchToPeriod(pNum);
                          setState(() => _selectedPeriod = pNum);
                        },
                        child: Container(
                          margin: const EdgeInsets.only(right: 8),
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? const Color(0xFF0D9488)
                                : (isLocked ? const Color(0xFFE2E8F0) : const Color(0xFFF1F5F9)),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: isSelected ? const Color(0xFF0D9488) : AppColors.cardBorder,
                            ),
                          ),
                          child: Row(
                            children: [
                              if (isLocked) ...[
                                Icon(Icons.lock, size: 12, color: isSelected ? Colors.white : AppColors.absentRed),
                                const SizedBox(width: 4),
                              ],
                              Text(
                                'P$pNum: $pSubj',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: isSelected ? Colors.white : AppColors.textPrimary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }),
                  ),
                ),
                const SizedBox(height: 12),

                // Respective Faculty Card with live status
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF0FDFA),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFF99F6E4)),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: const Color(0xFF0D9488).withOpacity(0.15),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.school, color: Color(0xFF0D9488), size: 20),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${faculty.name} (${faculty.subjectAbb ?? currentSubj})',
                              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF134E4A)),
                            ),
                            Text(
                              '${timing.startTime} - ${timing.endTime} • Hall ${faculty.hallNo ?? "408"}',
                              style: const TextStyle(fontSize: 11, color: Color(0xFF115E59)),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: const Color(0xFF99F6E4)),
                        ),
                        child: const Text('Routes to Staff', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF0D9488))),
                      ),
                    ],
                  ),
                ),

                // Staff Acknowledgment / Rejection Status Strip
                if (isDispatchedThisPeriod) ...[
                  const SizedBox(height: 8),
                  if (ackStatus == 'acknowledged') ...[
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF0FDF4),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: const Color(0xFF86EFAC)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.check_circle, size: 16, color: AppColors.presentGreen),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              '✓ Acknowledged & Approved by ${record.facultyAcknowledgedBy ?? faculty.name} (${record.facultyAcknowledgedAt ?? "Today"})',
                              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF166534)),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ] else if (ackStatus == 'rejected') ...[
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFEF2F2),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: const Color(0xFFFCA5A5)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.error_outline, size: 18, color: AppColors.absentRed),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '✕ Discrepancy Reported by ${record.facultyAcknowledgedBy ?? faculty.name}:',
                                  style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF991B1B)),
                                ),
                                Text(
                                  record.facultyRejectionReason ?? 'Please verify absent student list.',
                                  style: const TextStyle(fontSize: 11, color: Color(0xFF7F1D1D)),
                                ),
                              ],
                            ),
                          ),
                          TextButton(
                            onPressed: () => _showConfirmAndDispatchDialog(faculty, currentSubj),
                            style: TextButton.styleFrom(visualDensity: VisualDensity.compact),
                            child: const Text('Re-dispatch', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.absentRed, fontSize: 11)),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],

                const SizedBox(height: 10),

                // Section Tabs (Prioritizing Male if Asst CR is Male)
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      if (isAsstCr && asstGender == 'M') ...[
                        _buildSectionTab('Boys ($totalBoys) • Priority', 'boys', Icons.male, const Color(0xFF0284C7)),
                        _buildSectionTab('Girls ($totalGirls)', 'girls', Icons.female, const Color(0xFFDB2777)),
                        _buildSectionTab('All (52)', 'all', Icons.groups_outlined, const Color(0xFF0D9488)),
                      ] else if (isAsstCr && asstGender == 'F') ...[
                        _buildSectionTab('Girls ($totalGirls) • Priority', 'girls', Icons.female, const Color(0xFFDB2777)),
                        _buildSectionTab('Boys ($totalBoys)', 'boys', Icons.male, const Color(0xFF0284C7)),
                        _buildSectionTab('All (52)', 'all', Icons.groups_outlined, const Color(0xFF0D9488)),
                      ] else ...[
                        _buildSectionTab('All (52)', 'all', Icons.groups_outlined, const Color(0xFF0D9488)),
                        _buildSectionTab('Boys ($totalBoys)', 'boys', Icons.male, const Color(0xFF0284C7)),
                        _buildSectionTab('Girls ($totalGirls)', 'girls', Icons.female, const Color(0xFFDB2777)),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Search Field
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            child: TextField(
              controller: _searchController,
              onChanged: (val) => setState(() => _searchQuery = val),
              decoration: InputDecoration(
                hintText: 'Search by roll number or name...',
                prefixIcon: const Icon(Icons.search, size: 18),
                filled: true,
                fillColor: Colors.white,
                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppColors.cardBorder)),
              ),
            ),
          ),

          if (widget.state.isPeriodLocked(_selectedPeriod))
            Container(
              margin: const EdgeInsets.fromLTRB(16, 0, 16, 8),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: const Color(0xFFFEF2F2),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFFFCA5A5)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.lock, color: AppColors.absentRed, size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Period $_selectedPeriod attendance is locked & saved. Cannot be modified.',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF991B1B),
                      ),
                    ),
                  ),
                ],
              ),
            ),

          // Student Roster
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              itemCount: studentsList.length,
              itemBuilder: (context, idx) {
                final student = studentsList[idx];
                final isAbsent = widget.state.isAbsent(student.rollNo);

                return Card(
                  margin: const EdgeInsets.only(bottom: 6),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: BorderSide(
                      color: isAbsent ? AppColors.absentRed.withOpacity(0.3) : AppColors.cardBorder,
                    ),
                  ),
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
                    leading: CircleAvatar(
                      radius: 16,
                      backgroundColor: isAbsent ? const Color(0xFFFEE2E2) : const Color(0xFFDCFCE7),
                      child: Text(
                        '${student.rollNo}',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                          color: isAbsent ? AppColors.absentRed : AppColors.presentGreen,
                        ),
                      ),
                    ),
                    title: Row(
                      children: [
                        Expanded(
                          child: Text(
                            student.name,
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: student.isFemale ? const Color(0xFFFCE7F3) : const Color(0xFFE0F2FE),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            student.isFemale ? 'Girl' : 'Boy',
                            style: TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.bold,
                              color: student.isFemale ? const Color(0xFFDB2777) : const Color(0xFF0284C7),
                            ),
                          ),
                        ),
                      ],
                    ),
                    subtitle: Text('${student.enrollmentNo} • ${student.code}', style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                    trailing: Switch(
                      value: !isAbsent,
                      activeColor: AppColors.presentGreen,
                      inactiveTrackColor: const Color(0xFFFCA5A5),
                      onChanged: (widget.state.isPeriodLocked(_selectedPeriod) || !widget.state.canModifyAttendance)
                          ? null
                          : (_) {
                              widget.state.toggleStatus(student.rollNo);
                              setState(() {});
                            },
                    ),
                  ),
                );
              },
            ),
          ),

          // Bottom Bar to Dispatch
          Container(
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(
              color: Colors.white,
              boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, -2))],
            ),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: (widget.state.isPeriodLocked(_selectedPeriod) && ackStatus != 'rejected')
                    ? null
                    : () => _showConfirmAndDispatchDialog(faculty, currentSubj),
                icon: Icon(
                  widget.state.isPeriodLocked(_selectedPeriod) && ackStatus != 'rejected'
                      ? Icons.lock
                      : Icons.verified_user,
                ),
                label: Text(
                  widget.state.isPeriodLocked(_selectedPeriod) && ackStatus != 'rejected'
                      ? 'Period $_selectedPeriod Attendance Dispatched & Locked'
                      : 'Review All 52 Students & Dispatch to ${faculty.name.split(',')[0]}',
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: widget.state.isPeriodLocked(_selectedPeriod) && ackStatus != 'rejected'
                      ? Colors.grey.shade400
                      : const Color(0xFF0D9488),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTab(String label, String tabKey, IconData icon, Color activeColor) {
    final isSelected = _sectionTab == tabKey;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _sectionTab = tabKey),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: isSelected ? Colors.white : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
            boxShadow: isSelected ? [const BoxShadow(color: Colors.black12, blurRadius: 2, offset: Offset(0, 1))] : null,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 14, color: isSelected ? activeColor : AppColors.textSecondary),
              const SizedBox(width: 4),
              Flexible(
                child: Text(
                  label,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: isSelected ? activeColor : AppColors.textSecondary,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
