import 'package:flutter/material.dart';
import '../../core/theme.dart';
import '../../models/models.dart';
import '../../providers/classcr_state.dart';
import '../../data/mca_faculty.dart';
import 'report_screen.dart';

class MarkAttendanceScreen extends StatefulWidget {
  final ClassCRState state;

  const MarkAttendanceScreen({super.key, required this.state});

  @override
  State<MarkAttendanceScreen> createState() => _MarkAttendanceScreenState();
}

class _MarkAttendanceScreenState extends State<MarkAttendanceScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String _filter = 'all'; // 'all', 'present', 'absent'
  String _sectionTab = 'all'; // 'all', 'boys', 'girls'
  int _selectedPeriod = 1;

  @override
  void initState() {
    super.initState();
    widget.state.startRealtimeSync();
    // For Assistant CR: Auto-select and prioritize their assigned section
    if (widget.state.currentRole == UserRole.assistantCr) {
      if (widget.state.currentUser.gender == 'F') {
        _sectionTab = 'girls';
      } else if (widget.state.currentUser.gender == 'M') {
        _sectionTab = 'boys';
      }
    }
  }

  @override
  void dispose() {
    widget.state.stopRealtimeSync();
    _searchController.dispose();
    super.dispose();
  }

  int get totalBoys => widget.state.students.where((s) => s.isMale).length;
  int get presentBoys => widget.state.students.where((s) => s.isMale && widget.state.isPresent(s.rollNo)).length;
  int get absentBoys => totalBoys - presentBoys;

  int get totalGirls => widget.state.students.where((s) => s.isFemale).length;
  int get presentGirls => widget.state.students.where((s) => s.isFemale && widget.state.isPresent(s.rollNo)).length;
  int get absentGirls => totalGirls - presentGirls;

  Future<void> _selectDate() async {
    DateTime initial;
    try {
      initial = DateTime.parse(widget.state.todayDate);
    } catch (_) {
      initial = DateTime.now();
    }

    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(2025, 1, 1),
      lastDate: DateTime(2030, 12, 31),
    );

    if (picked != null) {
      final yyyyMmDd =
          "${picked.year.toString().padLeft(4, '0')}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}";
      await widget.state.setDate(yyyyMmDd);
      if (mounted) setState(() {});
    }
  }

  List<Student> get filteredStudents {
    final isAsstCr = widget.state.currentRole == UserRole.assistantCr;
    final asstGender = widget.state.currentUser.gender;

    final list = widget.state.students.where((st) {
      final matchesSearch = _searchQuery.isEmpty ||
          st.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          st.enrollmentNo.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          st.rollNo.toString() == _searchQuery.trim();

      if (!matchesSearch) return false;

      // Status filter
      if (_filter == 'present') {
        if (!widget.state.isPresent(st.rollNo)) return false;
      } else if (_filter == 'absent') {
        if (!widget.state.isAbsent(st.rollNo)) return false;
      }

      // Section / Gender filter
      if (_sectionTab == 'boys' && !st.isMale) return false;
      if (_sectionTab == 'girls' && !st.isFemale) return false;

      return true;
    }).toList();

    // Prioritize display order based on Assistant CR's gender when viewing All
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

  void _showVerificationDialog() {
    final absentees = widget.state.absentRolls.toList()..sort();
    final notesController = TextEditingController(text: widget.state.crNotes ?? '');

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) {
          return Container(
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
                      'Verify Attendance',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        widget.state.formattedTodayDate,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),

                // Stats summary pills
                Row(
                  children: [
                    _buildStatusPill(
                      label: 'Total',
                      count: widget.state.totalCount,
                      color: AppColors.textPrimary,
                      bgColor: const Color(0xFFF1F5F9),
                    ),
                    const SizedBox(width: 8),
                    _buildStatusPill(
                      label: 'Present',
                      count: widget.state.presentCount,
                      color: AppColors.presentGreen,
                      bgColor: const Color(0xFFDCFCE7),
                    ),
                    const SizedBox(width: 8),
                    _buildStatusPill(
                      label: 'Absent',
                      count: widget.state.absentCount,
                      color: AppColors.absentRed,
                      bgColor: const Color(0xFFFEE2E2),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                const SizedBox(height: 12),

                // Assistant CR Dual-Verification Status Badge
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: widget.state.isSectionVerifiedByAsstCr ? const Color(0xFFF0FDF4) : const Color(0xFFFFFBEB),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: widget.state.isSectionVerifiedByAsstCr ? const Color(0xFF86EFAC) : const Color(0xFFFDE68A),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        widget.state.isSectionVerifiedByAsstCr ? Icons.verified : Icons.pending_actions,
                        size: 18,
                        color: widget.state.isSectionVerifiedByAsstCr ? AppColors.presentGreen : const Color(0xFFD97706),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          widget.state.isSectionVerifiedByAsstCr
                              ? '✓ Section verified by Assistant CR (${widget.state.asstCrVerifiedBy ?? 'Asst. CR'} • ${widget.state.asstCrVerifiedAt ?? ''})'
                              : '⏳ Assistant CR section check pending (CR final lock will consolidate all)',
                          style: TextStyle(
                            fontSize: 11,
                            color: widget.state.isSectionVerifiedByAsstCr ? const Color(0xFF166534) : const Color(0xFF92400E),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 10),

                // Lecture Period Dispatch Selector & Target
                Builder(
                  builder: (_) {
                    final d = DateTime.tryParse(widget.state.todayDate) ?? DateTime.now();
                    final dayNames = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
                    final dayName = dayNames[d.weekday - 1];
                    final slot = kMcaTimeTable.firstWhere(
                      (s) => s.day.toLowerCase() == dayName.toLowerCase(),
                      orElse: () => kMcaTimeTable.first,
                    );
                    final subj = (_selectedPeriod >= 1 && _selectedPeriod <= slot.periods.length)
                        ? slot.periods[_selectedPeriod - 1]
                        : 'OOPS';
                    final fac = getFacultyForSubject(subj);
                    final isMorning = _selectedPeriod == 1;

                    return Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEFF6FF),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFFBFDBFE)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(isMorning ? Icons.wb_sunny_outlined : Icons.menu_book, size: 18, color: const Color(0xFF2563EB)),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  isMorning
                                      ? 'Morning 1st Lecture • Dispatches to Advisor & $subj Faculty'
                                      : 'Period $_selectedPeriod Lecture Log • Dispatches to $subj Faculty',
                                  style: const TextStyle(fontSize: 12, color: Color(0xFF1E40AF), fontWeight: FontWeight.bold),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Faculty: ${fac?.name ?? "Subject Faculty"} (${fac?.subject ?? subj})\nAdvisor: Mrs. V. Nandhini, AP/CA',
                            style: const TextStyle(fontSize: 11, color: Color(0xFF1E3A8A)),
                          ),
                          const SizedBox(height: 8),
                          // Period Selector Chips
                          SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: Row(
                              children: List.generate(slot.periods.length, (pIdx) {
                                final pNum = pIdx + 1;
                                final pSubj = slot.periods[pIdx];
                                final isSelected = _selectedPeriod == pNum;
                                return GestureDetector(
                                  onTap: () {
                                    setModalState(() => _selectedPeriod = pNum);
                                    setState(() => _selectedPeriod = pNum);
                                  },
                                  child: Container(
                                    margin: const EdgeInsets.only(right: 6),
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: isSelected ? const Color(0xFF2563EB) : Colors.white,
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(
                                        color: isSelected ? const Color(0xFF2563EB) : const Color(0xFFBFDBFE),
                                      ),
                                    ),
                                    child: Text(
                                      'P$pNum: $pSubj',
                                      style: TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                        color: isSelected ? Colors.white : const Color(0xFF1E40AF),
                                      ),
                                    ),
                                  ),
                                );
                              }),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
                const SizedBox(height: 14),

                // List of absentees
                Text(
                  'Absent Students (${absentees.length}):',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                ),
                const SizedBox(height: 8),

                if (absentees.isEmpty)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF0FDF4),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Text(
                      '🎉 Everyone is marked Present!',
                      style: TextStyle(color: AppColors.presentGreen, fontWeight: FontWeight.w600),
                    ),
                  )
                else
                  Container(
                    constraints: const BoxConstraints(maxHeight: 160),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.cardBorder),
                    ),
                    child: ListView.builder(
                      shrinkWrap: true,
                      itemCount: absentees.length,
                      itemBuilder: (context, i) {
                        final roll = absentees[i];
                        final st = widget.state.students.firstWhere((s) => s.rollNo == roll);
                        return ListTile(
                          dense: true,
                          visualDensity: VisualDensity.compact,
                          leading: CircleAvatar(
                            radius: 12,
                            backgroundColor: AppColors.absentRed.withOpacity(0.15),
                            child: Text(
                              '${st.rollNo}',
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: AppColors.absentRed,
                              ),
                            ),
                          ),
                          title: Text(
                            st.name,
                            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                          ),
                          subtitle: Text(
                            st.enrollmentNo,
                            style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                          ),
                          trailing: IconButton(
                            icon: const Icon(Icons.close, size: 16, color: AppColors.textSecondary),
                            onPressed: () {
                              widget.state.toggleStatus(st.rollNo);
                              setModalState(() {});
                            },
                          ),
                        );
                      },
                    ),
                  ),

                const SizedBox(height: 16),

                // CR Notes Input
                TextField(
                  controller: notesController,
                  maxLines: 2,
                  decoration: InputDecoration(
                    labelText: 'CR Daily Notes (Optional)',
                    hintText: 'e.g. Lab session, placement talk, prior leave notice...',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  ),
                ),

                const SizedBox(height: 18),

                // Confirm Final Lock & Submit Button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () async {
                      final messenger = ScaffoldMessenger.of(context);
                      final nav = Navigator.of(context);
                      Navigator.pop(ctx);
                      await widget.state.submitAttendance(
                        notes: notesController.text.trim(),
                        isLocked: true,
                        periodNo: _selectedPeriod,
                      );

                      if (mounted) {
                        messenger.showSnackBar(
                          SnackBar(
                            backgroundColor: AppColors.presentGreen,
                            content: Text(
                              '✅ Attendance Locked & Dispatched to Advisor and Period $_selectedPeriod Faculty!',
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ),
                        );

                        // Navigate to Report Screen
                        nav.pushReplacement(
                          MaterialPageRoute(builder: (_) => ReportScreen(state: widget.state)),
                        );
                      }
                    },
                    icon: const Icon(Icons.lock_outline),
                    label: const Text('Confirm Final Lock & Dispatch'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  // Modal for Assistant CR to review combined 52 students and transmit to CR
  void _showAsstCrSendDialog() {
    final allStudents = widget.state.students;
    final allAbsentees = widget.state.absentRolls.toList()..sort();
    final totalCount = widget.state.totalCount;
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
                    color: AppColors.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    widget.state.formattedTodayDate,
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.primary),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
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
                      Text('$totalCount', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      const Text('Total Students', style: TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                    ],
                  ),
                  Column(
                    children: [
                      Text('$presentCount', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.presentGreen)),
                      Text('Boys: $presentBoys • Girls: $presentGirls', style: const TextStyle(fontSize: 10, color: AppColors.presentGreen)),
                    ],
                  ),
                  Column(
                    children: [
                      Text('$absentCount', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.absentRed)),
                      Text('Boys: $absentBoys • Girls: $absentGirls', style: const TextStyle(fontSize: 10, color: AppColors.absentRed)),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFEFF6FF),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFFBFDBFE)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.info_outline, size: 18, color: Color(0xFF1D4ED8)),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'This confirms the combined 52-student list and transmits live to CR (${widget.state.delegation.crName}). CR will lock and dispatch to Class Advisor & Lecture Faculty.',
                      style: const TextStyle(fontSize: 11, color: Color(0xFF1E40AF), fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            Text(
              'Combined Absentees (${allAbsentees.length}):',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
            ),
            const SizedBox(height: 6),
            if (allAbsentees.isEmpty)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFF0FDF4),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Text('🎉 All 52 students are marked Present!', style: TextStyle(color: AppColors.presentGreen, fontWeight: FontWeight.bold)),
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
                  itemCount: allAbsentees.length,
                  itemBuilder: (_, idx) {
                    final roll = allAbsentees[idx];
                    final s = allStudents.firstWhere((st) => st.rollNo == roll);
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
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () async {
                  Navigator.pop(ctx);
                  await widget.state.verifyAndSendSectionToCr();
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        backgroundColor: AppColors.presentGreen,
                        content: Text('✅ Combined class attendance ($presentCount Present / $absentCount Absent) transmitted to CR live!'),
                      ),
                    );
                  }
                },
                icon: const Icon(Icons.send_rounded),
                label: const Text('Confirm Combined 52 Students & Transmit to CR'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
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

  Widget _buildStatusPill({
    required String label,
    required int count,
    required Color color,
    required Color bgColor,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          children: [
            Text(
              '$count',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: color),
            ),
            Text(
              label,
              style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: color),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.state,
      builder: (context, _) {
        final currentRole = widget.state.currentRole;
        if (currentRole == UserRole.student || currentRole == UserRole.admin) {
          return Scaffold(
            appBar: AppBar(
              title: const Text('Attendance Access Restricted'),
              leading: IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () => Navigator.pop(context),
              ),
            ),
            body: Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      currentRole == UserRole.admin ? Icons.admin_panel_settings : Icons.school,
                      size: 64,
                      color: AppColors.primary,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      currentRole == UserRole.admin
                          ? 'Attendance marking is handled strictly by Class Representatives (CR & Asst. CR) and approved by Class Advisor.\n\nHOD monitors academic records via the HOD Portal.'
                          : 'Attendance marking is only accessible to Class Representatives.\n\nStudents can check attendance and announcements in the Student Portal.',
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textSecondary),
                    ),
                  ],
                ),
              ),
            ),
          );
        }

        final list = filteredStudents;

        return Scaffold(
          backgroundColor: AppColors.background,
          appBar: AppBar(
            backgroundColor: Colors.white,
            elevation: 1,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: () => Navigator.pop(context),
            ),
            title: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Mark Attendance',
                  style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
                ),
                Text(
                  'I MCA • ${widget.state.presentCount} Present, ${widget.state.absentCount} Absent',
                  style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                ),
              ],
            ),
            actions: [
              // Dynamic Date Picker Button
              InkWell(
                onTap: _selectDate,
                borderRadius: BorderRadius.circular(20),
                child: Container(
                  margin: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: AppColors.primary.withOpacity(0.3)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.calendar_month, size: 14, color: AppColors.primary),
                      const SizedBox(width: 5),
                      Text(
                        widget.state.formattedTodayDate,
                        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.primary),
                      ),
                    ],
                  ),
                ),
              ),
              if (widget.state.canModifyAttendance)
                PopupMenuButton<String>(
                  icon: const Icon(Icons.more_vert),
                  onSelected: (val) {
                    if (val == 'all_present') widget.state.markAllPresent();
                    if (val == 'all_absent') widget.state.markAllAbsent();
                  },
                  itemBuilder: (_) => [
                    const PopupMenuItem(
                      value: 'all_present',
                      child: Row(
                        children: [
                          Icon(Icons.check_circle_outline, color: AppColors.presentGreen, size: 18),
                          SizedBox(width: 8),
                          Text('Mark All Present'),
                        ],
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'all_absent',
                      child: Row(
                        children: [
                          Icon(Icons.cancel_outlined, color: AppColors.absentRed, size: 18),
                          SizedBox(width: 8),
                          Text('Mark All Absent'),
                        ],
                      ),
                    ),
                  ],
                ),
            ],
          ),
          body: Column(
            children: [
              // Search & Filter Header
              Container(
                color: Colors.white,
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                child: Column(
                  children: [
                    // Locked Banner or Advisor Override Banner
                    if (widget.state.isAttendanceLocked) ...[
                      Container(
                        margin: const EdgeInsets.only(bottom: 10),
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        decoration: BoxDecoration(
                          color: widget.state.canModifyAttendance ? const Color(0xFFEFF6FF) : const Color(0xFFFEF2F2),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: widget.state.canModifyAttendance ? const Color(0xFF93C5FD) : const Color(0xFFFCA5A5),
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              widget.state.canModifyAttendance ? Icons.edit_note : Icons.lock_clock,
                              color: widget.state.canModifyAttendance ? AppColors.primary : AppColors.absentRed,
                              size: 20,
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    widget.state.canModifyAttendance
                                        ? '✏️ Advisor Override Mode'
                                        : '🔒 Attendance Submitted & Locked',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12,
                                      color: widget.state.canModifyAttendance ? AppColors.primary : AppColors.absentRed,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    widget.state.canModifyAttendance
                                        ? 'You can modify and approve student attendance as Class Advisor.'
                                        : 'Marked by: ${widget.state.currentAttendanceRecord?.markedByName ?? "CR"} (${widget.state.currentAttendanceRecord?.markedByRole ?? "CR"}). Only Class Advisor (${widget.state.delegation.advisorName}) can make changes.',
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: widget.state.canModifyAttendance ? const Color(0xFF1E40AF) : const Color(0xFF991B1B),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                    // Assistant CR / CR Header Status Cards
                    if (widget.state.currentRole == UserRole.assistantCr) ...[
                      Builder(
                        builder: (_) {
                          final isVerified = widget.state.isSectionVerifiedByAsstCr;

                          return Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            margin: const EdgeInsets.only(bottom: 10),
                            decoration: BoxDecoration(
                              color: isVerified ? const Color(0xFFF0FDF4) : const Color(0xFFEFF6FF),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: isVerified ? const Color(0xFF86EFAC) : const Color(0xFFBFDBFE)),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  isVerified ? Icons.check_circle : Icons.sync,
                                  size: 16,
                                  color: isVerified ? AppColors.presentGreen : const Color(0xFF2563EB),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    isVerified
                                        ? '✓ Section verified & transmitted to CR (${widget.state.asstCrVerifiedAt ?? "Today"}) • Awaiting CR lock'
                                        : '⚡ Real-time active: Cross-check assigned section and transmit to CR',
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                      color: isVerified ? const Color(0xFF166534) : const Color(0xFF1E40AF),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ] else if (widget.state.currentRole == UserRole.cr) ...[
                      // CR: Real-Time Assistant CR Check Status Pill
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                        margin: const EdgeInsets.only(bottom: 10),
                        decoration: BoxDecoration(
                          color: widget.state.isSectionVerifiedByAsstCr ? const Color(0xFFF0FDF4) : const Color(0xFFFFFBEB),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: widget.state.isSectionVerifiedByAsstCr ? const Color(0xFF86EFAC) : const Color(0xFFFDE68A),
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              widget.state.isSectionVerifiedByAsstCr ? Icons.verified : Icons.hourglass_top,
                              size: 16,
                              color: widget.state.isSectionVerifiedByAsstCr ? AppColors.presentGreen : const Color(0xFFD97706),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                widget.state.isSectionVerifiedByAsstCr
                                    ? '✓ Section verified by Asst. CR (${widget.state.asstCrVerifiedBy ?? 'Asst. CR'} • ${widget.state.asstCrVerifiedAt ?? ''})'
                                    : '⏳ Asst. CR section check in progress (real-time sync active)...',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: widget.state.isSectionVerifiedByAsstCr ? const Color(0xFF166534) : const Color(0xFF92400E),
                                ),
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: AppColors.primary.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.circle, size: 6, color: AppColors.presentGreen),
                                  SizedBox(width: 4),
                                  Text('LIVE', style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: AppColors.primary)),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],

                    // Adaptive Section Selector Tabs (Male priority for Male Assistant CR)
                    Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          if (widget.state.currentRole == UserRole.assistantCr && widget.state.currentUser.gender == 'M') ...[
                            _buildSectionTab('Boys ($totalBoys) • Priority', 'boys', Icons.male, activeColor: const Color(0xFF0284C7)),
                            _buildSectionTab('Girls ($totalGirls)', 'girls', Icons.female, activeColor: const Color(0xFFDB2777)),
                            _buildSectionTab('All (${widget.state.totalCount})', 'all', Icons.groups_outlined),
                          ] else if (widget.state.currentRole == UserRole.assistantCr && widget.state.currentUser.gender == 'F') ...[
                            _buildSectionTab('Girls ($totalGirls) • Priority', 'girls', Icons.female, activeColor: const Color(0xFFDB2777)),
                            _buildSectionTab('Boys ($totalBoys)', 'boys', Icons.male, activeColor: const Color(0xFF0284C7)),
                            _buildSectionTab('All (${widget.state.totalCount})', 'all', Icons.groups_outlined),
                          ] else ...[
                            _buildSectionTab('All (${widget.state.totalCount})', 'all', Icons.groups_outlined),
                            _buildSectionTab('Boys ($totalBoys)', 'boys', Icons.male, activeColor: const Color(0xFF0284C7)),
                            _buildSectionTab('Girls ($totalGirls)', 'girls', Icons.female, activeColor: const Color(0xFFDB2777)),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: 10),

                    // Section Quick Batch & Status Strip (when on Boys or Girls section)
                    if (_sectionTab == 'boys') ...[
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                        margin: const EdgeInsets.only(bottom: 10),
                        decoration: BoxDecoration(
                          color: const Color(0xFFE0F2FE),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: const Color(0xFFBAE6FD)),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.male, size: 16, color: Color(0xFF0284C7)),
                            const SizedBox(width: 6),
                            Text(
                              'Boys: $presentBoys Present • $absentBoys Absent',
                              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF0369A1)),
                            ),
                            if (widget.state.canModifyAttendance) ...[
                              const Spacer(),
                              GestureDetector(
                                onTap: () => widget.state.markSectionPresent(isFemale: false),
                                child: const Text('Mark All Present', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.presentGreen)),
                              ),
                              const SizedBox(width: 10),
                              GestureDetector(
                                onTap: () => widget.state.markSectionAbsent(isFemale: false),
                                child: const Text('Mark All Absent', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.absentRed)),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ] else if (_sectionTab == 'girls') ...[
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                        margin: const EdgeInsets.only(bottom: 10),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFCE7F3),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: const Color(0xFFFBCFE8)),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.female, size: 16, color: Color(0xFFDB2777)),
                            const SizedBox(width: 6),
                            Text(
                              'Girls: $presentGirls Present • $absentGirls Absent',
                              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF9D174D)),
                            ),
                            if (widget.state.canModifyAttendance) ...[
                              const Spacer(),
                              GestureDetector(
                                onTap: () => widget.state.markSectionPresent(isFemale: true),
                                child: const Text('Mark All Present', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.presentGreen)),
                              ),
                              const SizedBox(width: 10),
                              GestureDetector(
                                onTap: () => widget.state.markSectionAbsent(isFemale: true),
                                child: const Text('Mark All Absent', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.absentRed)),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],

                    // Search box
                    TextField(
                      controller: _searchController,
                      onChanged: (val) => setState(() => _searchQuery = val),
                      decoration: InputDecoration(
                        hintText: 'Search by Name, S.No, or Enrollment...',
                        prefixIcon: const Icon(Icons.search, size: 20, color: AppColors.textSecondary),
                        suffixIcon: _searchQuery.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.clear, size: 18),
                                onPressed: () {
                                  _searchController.clear();
                                  setState(() => _searchQuery = '');
                                },
                              )
                            : null,
                        filled: true,
                        fillColor: const Color(0xFFF1F5F9),
                        contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 16),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),

                    const SizedBox(height: 10),

                    // Filter chips
                    Row(
                      children: [
                        _buildFilterChip('All', 'all'),
                        const SizedBox(width: 8),
                        _buildFilterChip('Present', 'present', AppColors.presentGreen),
                        const SizedBox(width: 8),
                        _buildFilterChip('Absent', 'absent', AppColors.absentRed),
                      ],
                    ),
                  ],
                ),
              ),

              // Helper guide text
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                color: const Color(0xFFEFF6FF),
                child: const Row(
                  children: [
                    Icon(Icons.touch_app_outlined, size: 16, color: AppColors.primary),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        '⚡ Quick Mark: Tap any student tile to toggle Present / Absent',
                        style: TextStyle(fontSize: 12, color: AppColors.primary, fontWeight: FontWeight.w600),
                      ),
                    ),
                  ],
                ),
              ),

              // Student List
              Expanded(
                child: list.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.search_off, size: 48, color: AppColors.textMuted),
                            const SizedBox(height: 12),
                            Text('No student found matching "$_searchQuery"'),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        itemCount: list.length,
                        itemBuilder: (context, index) {
                          final student = list[index];
                          final isAbsent = widget.state.isAbsent(student.rollNo);

                          return Container(
                            margin: const EdgeInsets.only(bottom: 8),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                color: isAbsent ? AppColors.absentRed.withOpacity(0.5) : AppColors.cardBorder,
                                width: isAbsent ? 1.5 : 1,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.02),
                                  blurRadius: 4,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: InkWell(
                              borderRadius: BorderRadius.circular(14),
                              onTap: () {
                                final success = widget.state.toggleStatus(student.rollNo);
                                if (!success) {
                                  ScaffoldMessenger.of(context).hideCurrentSnackBar();
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      backgroundColor: AppColors.absentRed,
                                      content: Text(
                                        '🔒 Attendance is locked. Only Class Advisor (${widget.state.delegation.advisorName}) can make changes.',
                                      ),
                                      duration: const Duration(seconds: 2),
                                    ),
                                  );
                                }
                              },
                              child: Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                                child: Row(
                                  children: [
                                    // Present / Absent Icon Circle
                                    Container(
                                      width: 36,
                                      height: 36,
                                      decoration: BoxDecoration(
                                        color: isAbsent
                                            ? AppColors.absentRed.withOpacity(0.12)
                                            : AppColors.presentGreen.withOpacity(0.12),
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      child: Center(
                                        child: Icon(
                                          isAbsent ? Icons.close : Icons.check,
                                          color: isAbsent ? AppColors.absentRed : AppColors.presentGreen,
                                          size: 20,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 14),

                                    // Roll number badge
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFF1F5F9),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Text(
                                        student.rollNo.toString().padLeft(2, '0'),
                                        style: const TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w800,
                                          color: AppColors.textPrimary,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 12),

                                    // Name & Enrollment
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            student.name,
                                            style: TextStyle(
                                              fontSize: 14,
                                              fontWeight: FontWeight.w700,
                                              color: isAbsent ? AppColors.absentRed : AppColors.textPrimary,
                                            ),
                                          ),
                                          const SizedBox(height: 2),
                                          Row(
                                            children: [
                                              Text(
                                                student.enrollmentNo,
                                                style: const TextStyle(
                                                  fontSize: 12,
                                                  color: AppColors.textSecondary,
                                                  fontWeight: FontWeight.w500,
                                                ),
                                              ),
                                              const SizedBox(width: 8),
                                              Container(
                                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                                                decoration: BoxDecoration(
                                                  color: const Color(0xFFF1F5F9),
                                                  borderRadius: BorderRadius.circular(4),
                                                ),
                                                child: Text(
                                                  student.code,
                                                  style: const TextStyle(
                                                    fontSize: 10,
                                                    fontWeight: FontWeight.bold,
                                                    color: AppColors.textSecondary,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),

                                    // Status Badge
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: isAbsent
                                            ? AppColors.absentRed.withOpacity(0.1)
                                            : AppColors.presentGreen.withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(20),
                                      ),
                                      child: Text(
                                        isAbsent ? 'ABSENT' : 'PRESENT',
                                        style: TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w800,
                                          color: isAbsent ? AppColors.absentRed : AppColors.presentGreen,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      ),
              ),

              // Bottom Sticky Verification Bar
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.08),
                      blurRadius: 10,
                      offset: const Offset(0, -4),
                    ),
                  ],
                ),
                child: SafeArea(
                  child: Row(
                    children: [
                      // Counter label
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            RichText(
                              text: TextSpan(
                                children: [
                                  TextSpan(
                                    text: '${widget.state.presentCount} Present',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.presentGreen,
                                      fontSize: 15,
                                    ),
                                  ),
                                  const TextSpan(
                                    text: '  •  ',
                                    style: TextStyle(color: AppColors.textSecondary),
                                  ),
                                  TextSpan(
                                    text: '${widget.state.absentCount} Absent',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.absentRed,
                                      fontSize: 15,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Text(
                              'Total: ${widget.state.totalCount} Students',
                              style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                            ),
                          ],
                        ),
                      ),

                      // Verify / Submit / Locked / Advisor override button
                      if (!widget.state.canModifyAttendance)
                        ElevatedButton.icon(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => ReportScreen(state: widget.state)),
                            );
                          },
                          icon: const Icon(Icons.lock, size: 18),
                          label: const Text('Submitted (Locked)'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF64748B),
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                        )
                      else if (widget.state.currentUser.role == UserRole.advisor)
                        ElevatedButton.icon(
                          onPressed: () async {
                            await widget.state.saveAdvisorAttendanceOverride();
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  backgroundColor: AppColors.presentGreen,
                                  content: Text('✅ Advisor Attendance Changes Saved & Synced!'),
                                ),
                              );
                            }
                          },
                          icon: const Icon(Icons.check_circle, size: 18),
                          label: const Text('Save & Approve'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.presentGreen,
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                        )
                      else if (widget.state.currentUser.role == UserRole.assistantCr)
                        ElevatedButton.icon(
                          onPressed: _showAsstCrSendDialog,
                          icon: Icon(
                            widget.state.isSectionVerifiedByAsstCr ? Icons.check_circle_outline : Icons.send_rounded,
                            size: 18,
                          ),
                          label: Text(
                            widget.state.isSectionVerifiedByAsstCr ? 'Update & Resend to CR' : 'Verify & Send to CR',
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: widget.state.isSectionVerifiedByAsstCr ? const Color(0xFF0D9488) : AppColors.primary,
                            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                        )
                      else
                        ElevatedButton.icon(
                          onPressed: _showVerificationDialog,
                          icon: const Icon(Icons.lock_outline, size: 18),
                          label: const Text('Final Lock & Dispatch'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildFilterChip(String label, String value, [Color? activeColor]) {
    final isSelected = _filter == value;
    final color = activeColor ?? AppColors.primary;

    return GestureDetector(
      onTap: () => setState(() => _filter = value),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? color : const Color(0xFFF1F5F9),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: isSelected ? Colors.white : AppColors.textSecondary,
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTab(String label, String value, IconData icon, {Color? activeColor}) {
    final isSelected = _sectionTab == value;
    final color = activeColor ?? AppColors.primary;

    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _sectionTab = value),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: isSelected ? Colors.white : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.06),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    )
                  ]
                : null,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 16, color: isSelected ? color : AppColors.textSecondary),
              const SizedBox(width: 4),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                  color: isSelected ? color : AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
