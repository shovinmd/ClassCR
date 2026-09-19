import 'package:flutter/material.dart';
import '../../core/theme.dart';
import '../../models/models.dart';
import '../../providers/classcr_state.dart';
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

  @override
  void initState() {
    super.initState();
    // For Assistant CR: Auto-select and prioritize their assigned section!
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
    return widget.state.students.where((st) {
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
                        '18/09/2026',
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
                const SizedBox(height: 16),

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
                    constraints: const BoxConstraints(maxHeight: 180),
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

                const SizedBox(height: 20),

                // Confirm & Submit Button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () async {
                      final messenger = ScaffoldMessenger.of(context);
                      final nav = Navigator.of(context);
                      Navigator.pop(ctx);
                      await widget.state.submitAttendance(notes: notesController.text.trim());

                      if (mounted) {
                        messenger.showSnackBar(
                          SnackBar(
                            backgroundColor: AppColors.presentGreen,
                            content: Text(
                              'Attendance verified! ${widget.state.presentCount} Present / ${widget.state.absentCount} Absent.',
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
                    icon: const Icon(Icons.check_circle_outline),
                    label: const Text('Confirm & Generate Report'),
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
                  'Today\'s Attendance',
                  style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
                ),
                Text(
                  'I MCA • ${widget.state.presentCount} Present, ${widget.state.absentCount} Absent',
                  style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                ),
              ],
            ),
            actions: [
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
                    // Assistant CR Role Notice (Cross-Checking Section Banner)
                    if (widget.state.currentRole == UserRole.assistantCr) ...[
                      Container(
                        margin: const EdgeInsets.only(bottom: 10),
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF0FDFA),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: const Color(0xFF5EEAD4)),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              widget.state.currentUser.gender == 'F' ? Icons.female : Icons.male,
                              size: 20,
                              color: widget.state.currentUser.gender == 'F' ? const Color(0xFFDB2777) : const Color(0xFF0D9488),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                '${widget.state.currentUser.roleDisplayName}: ${widget.state.currentUser.name}\n'
                                'Cross-Checking Section: ${_sectionTab == "girls" ? "👧 Girls Roster" : (_sectionTab == "boys" ? "👦 Boys Roster" : "👥 All Students")}',
                                style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF0F766E), height: 1.3),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],

                    // Section Selector Tabs (All / Boys / Girls)
                    Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          _buildSectionTab('All (${widget.state.totalCount})', 'all', Icons.groups_outlined),
                          _buildSectionTab('Boys ($totalBoys)', 'boys', Icons.male, activeColor: const Color(0xFF0284C7)),
                          _buildSectionTab('Girls ($totalGirls)', 'girls', Icons.female, activeColor: const Color(0xFFDB2777)),
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
                              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFFBE185D)),
                            ),
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
                              onTap: () => widget.state.toggleStatus(student.rollNo),
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
                                                  color: student.isFemale ? const Color(0xFFFCE7F3) : const Color(0xFFE0F2FE),
                                                  borderRadius: BorderRadius.circular(4),
                                                ),
                                                child: Text(
                                                  student.isFemale ? '👧 Girl' : '👦 Boy',
                                                  style: TextStyle(
                                                    fontSize: 10,
                                                    fontWeight: FontWeight.bold,
                                                    color: student.isFemale ? const Color(0xFFDB2777) : const Color(0xFF0284C7),
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

                      // Verify button
                      ElevatedButton.icon(
                        onPressed: _showVerificationDialog,
                        icon: const Icon(Icons.checklist_rtl, size: 18),
                        label: const Text('Verify & Submit'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
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
