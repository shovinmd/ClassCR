import 'package:flutter/material.dart';
import '../../core/theme.dart';
import '../../data/mca_faculty.dart';
import '../../providers/classcr_state.dart';
import '../cr/report_screen.dart';

class AdvisorDashboardScreen extends StatefulWidget {
  final ClassCRState state;

  const AdvisorDashboardScreen({super.key, required this.state});

  @override
  State<AdvisorDashboardScreen> createState() => _AdvisorDashboardScreenState();
}

class _AdvisorDashboardScreenState extends State<AdvisorDashboardScreen> {
  bool _showStudentList = false;

  int? _selectedCrRoll;
  int? _selectedMaleAsstRoll;
  int? _selectedFemaleAsstRoll;
  late final TextEditingController _crCodeCtrl;
  late final TextEditingController _maleAsstCodeCtrl;
  late final TextEditingController _femaleAsstCodeCtrl;
  late final TextEditingController _studentCodeCtrl;
  bool _isSavingDelegation = false;

  @override
  void initState() {
    super.initState();
    final del = widget.state.delegation;
    _selectedCrRoll = del.crRoll;
    _selectedMaleAsstRoll = del.maleAsstRoll;
    _selectedFemaleAsstRoll = del.femaleAsstRoll;
    _crCodeCtrl = TextEditingController(text: del.crCode);
    _maleAsstCodeCtrl = TextEditingController(text: del.maleAsstCode);
    _femaleAsstCodeCtrl = TextEditingController(text: del.femaleAsstCode);
    _studentCodeCtrl = TextEditingController(text: del.studentCode);
  }

  @override
  void dispose() {
    _crCodeCtrl.dispose();
    _maleAsstCodeCtrl.dispose();
    _femaleAsstCodeCtrl.dispose();
    _studentCodeCtrl.dispose();
    super.dispose();
  }

  Future<void> _saveDelegations() async {
    setState(() => _isSavingDelegation = true);

    final crStudent = widget.state.students.firstWhere(
      (s) => s.rollNo == _selectedCrRoll,
      orElse: () => widget.state.students.first,
    );
    final maleAsst = widget.state.students.firstWhere(
      (s) => s.rollNo == _selectedMaleAsstRoll,
      orElse: () => widget.state.students.first,
    );
    final femaleAsst = widget.state.students.firstWhere(
      (s) => s.rollNo == _selectedFemaleAsstRoll,
      orElse: () => widget.state.students.first,
    );

    await widget.state.advisorDelegate(
      classId: 'I-MCA-A',
      crRoll: _selectedCrRoll,
      crName: crStudent.name,
      crCode: _crCodeCtrl.text.trim(),
      maleAsstRoll: _selectedMaleAsstRoll,
      maleAsstName: maleAsst.name,
      maleAsstCode: _maleAsstCodeCtrl.text.trim(),
      femaleAsstRoll: _selectedFemaleAsstRoll,
      femaleAsstName: femaleAsst.name,
      femaleAsstCode: _femaleAsstCodeCtrl.text.trim(),
      studentCode: _studentCodeCtrl.text.trim(),
    );

    setState(() => _isSavingDelegation = false);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('✅ Appointed CR (${crStudent.name}) & Asst. CRs (${maleAsst.name}, ${femaleAsst.name})! Passcodes updated in backend.'),
          backgroundColor: AppColors.presentGreen,
        ),
      );
    }
  }

  void _showAnnouncementDialog() {
    final titleController = TextEditingController();
    final messageController = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.campaign, color: AppColors.primary),
            SizedBox(width: 8),
            Text('Broadcast Announcement', style: TextStyle(fontSize: 16)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: titleController,
              decoration: const InputDecoration(labelText: 'Subject / Title'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: messageController,
              maxLines: 3,
              decoration: const InputDecoration(labelText: 'Message to I MCA students'),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('📢 Announcement sent to all 52 students of I MCA!'),
                  backgroundColor: AppColors.presentGreen,
                ),
              );
            },
            child: const Text('Broadcast'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.state,
      builder: (context, _) {
        final absentees = widget.state.absentRolls.toList()..sort();

        return SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Advisor Profile Banner
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Class Advisor Portal',
                        style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${widget.state.delegation.advisorName} • I MCA A',
                        style: const TextStyle(fontSize: 13, color: AppColors.textSecondary, fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                  ElevatedButton.icon(
                    onPressed: _showAnnouncementDialog,
                    icon: const Icon(Icons.campaign, size: 16),
                    label: const Text('Broadcast'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 20),

              // TODAY'S REPORT CARD (Spec layout)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(22),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppColors.cardBorder),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.03),
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
                        const Text(
                          "I MCA — Today's Report",
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            color: AppColors.deepBlue,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppColors.presentGreen.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Row(
                            children: [
                              Icon(Icons.check_circle, size: 14, color: AppColors.presentGreen),
                              SizedBox(width: 4),
                              Text(
                                'Submitted (09:18 AM)',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.presentGreen,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),

                    const Divider(height: 24),

                    // Metrics table: Total, Present, Absent
                    Row(
                      children: [
                        _buildStatBox('Total', '${widget.state.totalCount}', AppColors.textPrimary),
                        _buildStatBox('Present', '${widget.state.presentCount}', AppColors.presentGreen),
                        _buildStatBox('Absent', '${widget.state.absentCount}', AppColors.absentRed),
                      ],
                    ),

                    const SizedBox(height: 18),

                    // CR Status & Last Updated
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'CR Status',
                                style: TextStyle(fontSize: 11, color: AppColors.textSecondary),
                              ),
                              const SizedBox(height: 2),
                              Row(
                                children: [
                                  const Icon(Icons.check, size: 14, color: AppColors.presentGreen),
                                  const SizedBox(width: 4),
                                  Text(
                                    'Submitted by ${widget.state.delegation.crName}',
                                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              const Text(
                                'Last Updated',
                                style: TextStyle(fontSize: 11, color: AppColors.textSecondary),
                              ),
                              const SizedBox(height: 2),
                              const Text(
                                '09:18 AM',
                                style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Toggle View Student List & View Smart Report
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () {
                              setState(() {
                                _showStudentList = !_showStudentList;
                              });
                            },
                            icon: Icon(_showStudentList ? Icons.expand_less : Icons.people_outline, size: 18),
                            label: Text(_showStudentList ? 'Hide Students' : 'Open Student List'),
                          ),
                        ),
                        const SizedBox(width: 10),
                        ElevatedButton.icon(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => ReportScreen(state: widget.state)),
                            );
                          },
                          icon: const Icon(Icons.description, size: 16),
                          label: const Text('Full Report'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // EXPANDABLE STUDENT LIST FOR ADVISOR VERIFICATION & CORRECTION
              if (_showStudentList) ...[
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Interactive Class Roster (52 Students)',
                      style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Text(
                        'Advisor Correction Mode',
                        style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.primary),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),

                Card(
                  child: ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: widget.state.students.length,
                    separatorBuilder: (_, _) => const Divider(height: 1),
                    itemBuilder: (context, index) {
                      final st = widget.state.students[index];
                      final isAbsent = widget.state.isAbsent(st.rollNo);

                      return ListTile(
                        dense: true,
                        leading: CircleAvatar(
                          radius: 14,
                          backgroundColor: isAbsent
                              ? AppColors.absentRed.withOpacity(0.15)
                              : AppColors.presentGreen.withOpacity(0.15),
                          child: Text(
                            '${st.rollNo}',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: isAbsent ? AppColors.absentRed : AppColors.presentGreen,
                            ),
                          ),
                        ),
                        title: Text(st.name, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                        subtitle: Text(st.enrollmentNo, style: const TextStyle(fontSize: 11)),
                        trailing: ElevatedButton(
                          onPressed: () {
                            widget.state.toggleStatus(st.rollNo);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                duration: const Duration(seconds: 1),
                                content: Text('Updated ${st.name} to ${isAbsent ? "PRESENT" : "ABSENT"}'),
                              ),
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: isAbsent ? AppColors.absentRed : AppColors.presentGreen,
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            minimumSize: const Size(60, 28),
                          ),
                          child: Text(
                            isAbsent ? 'ABSENT' : 'PRESENT',
                            style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],

              // APPOINT CR, ASST. CRS & CONFIGURE PASSCODES (Advisor authority)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: const Color(0xFFBAE6FD), width: 1.5),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF0284C7).withValues(alpha: 0.08),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: const Color(0xFFE0F2FE),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(Icons.manage_accounts, color: Color(0xFF0284C7), size: 22),
                        ),
                        const SizedBox(width: 10),
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Appoint CR & Asst. CRs (Delegation)',
                                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.deepBlue),
                              ),
                              Text(
                                'Select from class roster and configure dynamic passcodes',
                                style: TextStyle(fontSize: 11, color: AppColors.textSecondary),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // 1. CLASS REPRESENTATIVE (CR)
                    const Text('Class Representative (CR):', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: AppColors.cardBorder),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<int>(
                          value: _selectedCrRoll,
                          isExpanded: true,
                          items: widget.state.students.map((s) {
                            return DropdownMenuItem<int>(
                              value: s.rollNo,
                              child: Text('#${s.rollNo.toString().padLeft(2, '0')} ${s.name} (${s.enrollmentNo})', style: const TextStyle(fontSize: 13)),
                            );
                          }).toList(),
                          onChanged: (val) => setState(() => _selectedCrRoll = val),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _crCodeCtrl,
                      textCapitalization: TextCapitalization.characters,
                      decoration: const InputDecoration(
                        labelText: 'CR Join Passcode',
                        hintText: 'e.g. CR2026',
                        prefixIcon: Icon(Icons.key, size: 18),
                        border: OutlineInputBorder(),
                        isDense: true,
                      ),
                    ),

                    const Divider(height: 28),

                    // 2. MALE ASSISTANT CR
                    const Text('Male Assistant CR (Boys Coordinator):', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF0369A1))),
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF0F9FF),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: const Color(0xFFBAE6FD)),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<int>(
                          value: _selectedMaleAsstRoll,
                          isExpanded: true,
                          items: widget.state.students.where((s) => s.isMale).map((s) {
                            return DropdownMenuItem<int>(
                              value: s.rollNo,
                              child: Text('#${s.rollNo.toString().padLeft(2, '0')} ${s.name} (${s.enrollmentNo})', style: const TextStyle(fontSize: 13)),
                            );
                          }).toList(),
                          onChanged: (val) => setState(() => _selectedMaleAsstRoll = val),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _maleAsstCodeCtrl,
                      textCapitalization: TextCapitalization.characters,
                      decoration: const InputDecoration(
                        labelText: 'Male Asst. CR Passcode',
                        hintText: 'e.g. ACR2026',
                        prefixIcon: Icon(Icons.male, color: Color(0xFF0284C7), size: 18),
                        border: OutlineInputBorder(),
                        isDense: true,
                      ),
                    ),

                    const Divider(height: 28),

                    // 3. FEMALE ASSISTANT CR
                    const Text('Female Assistant CR (Girls Coordinator):', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFFBE185D))),
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFDF2F8),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: const Color(0xFFFBCFE8)),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<int>(
                          value: _selectedFemaleAsstRoll,
                          isExpanded: true,
                          items: widget.state.students.where((s) => s.isFemale).map((s) {
                            return DropdownMenuItem<int>(
                              value: s.rollNo,
                              child: Text('#${s.rollNo.toString().padLeft(2, '0')} ${s.name} (${s.enrollmentNo})', style: const TextStyle(fontSize: 13)),
                            );
                          }).toList(),
                          onChanged: (val) => setState(() => _selectedFemaleAsstRoll = val),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _femaleAsstCodeCtrl,
                      textCapitalization: TextCapitalization.characters,
                      decoration: const InputDecoration(
                        labelText: 'Female Asst. CR Passcode',
                        hintText: 'e.g. ACR2026',
                        prefixIcon: Icon(Icons.female, color: Color(0xFFDB2777), size: 18),
                        border: OutlineInputBorder(),
                        isDense: true,
                      ),
                    ),

                    const Divider(height: 28),

                    // 4. STUDENT PORTAL PASSCODE
                    const Text('Student Portal Access Passcode:', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 6),
                    TextField(
                      controller: _studentCodeCtrl,
                      textCapitalization: TextCapitalization.characters,
                      decoration: const InputDecoration(
                        labelText: 'Student Passcode',
                        hintText: 'e.g. STU2026',
                        prefixIcon: Icon(Icons.school, size: 18),
                        border: OutlineInputBorder(),
                        isDense: true,
                      ),
                    ),

                    const SizedBox(height: 18),

                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: _isSavingDelegation ? null : _saveDelegations,
                        icon: _isSavingDelegation
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                              )
                            : const Icon(Icons.save_outlined),
                        label: Text(_isSavingDelegation ? 'Saving...' : 'Save Delegations & Passcodes'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF0284C7),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 28),

              // CLASS ATTENDANCE ANALYTICS (Spec section)
              const Text(
                'Class Attendance Analytics',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
              ),
              const SizedBox(height: 4),
              const Text(
                'Attendance distribution across all 52 students',
                style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
              ),
              const SizedBox(height: 14),

              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppColors.cardBorder),
                ),
                child: Column(
                  children: [
                    _buildTierRow('Excellent (>90%)', 31, 52, AppColors.presentGreen),
                    const SizedBox(height: 14),
                    _buildTierRow('75–90%', 14, 52, AppColors.primary),
                    const SizedBox(height: 14),
                    _buildTierRow('Below 75% (Shortage Risk)', 7, 52, AppColors.absentRed),
                  ],
                ),
              ),

              const SizedBox(height: 28),

              // Absent students list
              const Text(
                "Today's Absent Students (9)",
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
              ),
              const SizedBox(height: 12),

              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.cardBorder),
                ),
                child: Column(
                  children: absentees.map((rNo) {
                    final st = widget.state.students.firstWhere((s) => s.rollNo == rNo);
                    return ListTile(
                      dense: true,
                      leading: const Icon(Icons.cancel, color: AppColors.absentRed, size: 20),
                      title: Text(
                        '${st.rollNo}. ${st.name}',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                      ),
                      subtitle: Text(st.enrollmentNo, style: const TextStyle(fontSize: 11)),
                      trailing: TextButton(
                        onPressed: () {
                          widget.state.toggleStatus(st.rollNo);
                        },
                        child: const Text('Mark Present', style: TextStyle(fontSize: 12)),
                      ),
                    );
                  }).toList(),
                ),
              ),

              const SizedBox(height: 28),

              // BRIDGE COURSE TIME TABLE SCHEDULE (MVIT Official)
              Container(
                padding: const EdgeInsets.all(18),
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
                        const Row(
                          children: [
                            Icon(Icons.calendar_month, color: AppColors.primary, size: 20),
                            SizedBox(width: 8),
                            Text(
                              'Bridge Course Time Table',
                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: const Color(0xFFEFF6FF),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Text(
                            'Hall NO: 408',
                            style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.primary),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'I MCA A • Batch 2026–2028 • Advisor: Mrs. V. Nandhini, AP/CA',
                      style: TextStyle(fontSize: 11, color: AppColors.textSecondary),
                    ),
                    const SizedBox(height: 14),
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: DataTable(
                        headingRowColor: WidgetStateProperty.all(const Color(0xFFF8FAFC)),
                        columnSpacing: 16,
                        columns: const [
                          DataColumn(label: Text('Day', style: TextStyle(fontWeight: FontWeight.bold))),
                          DataColumn(label: Text('P1 (8:50)', style: TextStyle(fontWeight: FontWeight.bold))),
                          DataColumn(label: Text('P2 (9:40)', style: TextStyle(fontWeight: FontWeight.bold))),
                          DataColumn(label: Text('P3 (10:45)', style: TextStyle(fontWeight: FontWeight.bold))),
                          DataColumn(label: Text('P4 (11:35)', style: TextStyle(fontWeight: FontWeight.bold))),
                          DataColumn(label: Text('P5 (1:10)', style: TextStyle(fontWeight: FontWeight.bold))),
                          DataColumn(label: Text('P6 (2:00)', style: TextStyle(fontWeight: FontWeight.bold))),
                          DataColumn(label: Text('P7 (3:00)', style: TextStyle(fontWeight: FontWeight.bold))),
                          DataColumn(label: Text('P8 (3:50)', style: TextStyle(fontWeight: FontWeight.bold))),
                        ],
                        rows: kMcaTimeTable.map((slot) {
                          return DataRow(
                            cells: [
                              DataCell(Text(slot.day, style: const TextStyle(fontWeight: FontWeight.bold))),
                              ...slot.periods.map((p) => DataCell(
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: p == 'FCP'
                                        ? const Color(0xFFDCFCE7)
                                        : (p == 'IPS'
                                            ? const Color(0xFFFEF3C7)
                                            : (p == 'ICO'
                                                ? const Color(0xFFE0E7FF)
                                                : const Color(0xFFFCE7F3))),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    p,
                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11),
                                  ),
                                ),
                              )),
                            ],
                          );
                        }).toList(),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildStatBox(String label, String count, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        margin: const EdgeInsets.symmetric(horizontal: 4),
        decoration: BoxDecoration(
          color: color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Text(
              count,
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: color),
            ),
            Text(
              label,
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: color),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTierRow(String title, int count, int total, Color color) {
    final double fraction = total > 0 ? count / total : 0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              title,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
            ),
            Text(
              '$count Students (${(fraction * 100).toStringAsFixed(0)}%)',
              style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: color),
            ),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: fraction,
            backgroundColor: const Color(0xFFF1F5F9),
            valueColor: AlwaysStoppedAnimation<Color>(color),
            minHeight: 8,
          ),
        ),
      ],
    );
  }
}
