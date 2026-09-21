import 'package:flutter/material.dart';
import '../../core/theme.dart';
import '../../data/mca_faculty.dart';
import '../../providers/classcr_state.dart';
import '../cr/report_screen.dart';

class AdminDashboardScreen extends StatefulWidget {
  final ClassCRState state;

  const AdminDashboardScreen({super.key, required this.state});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  String _selectedDept = 'MCA';
  String _selectedYear = 'I MCA';
  String _selectedSection = 'I MCA A';

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'CLASSCR HOD PORTAL',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0.5,
                      color: AppColors.deepBlue,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Department & Academic Attendance Oversight',
                    style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: const Color(0xFF8B5CF6).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Text(
                  'HOD',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF8B5CF6),
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),

          // OVERVIEW STATS GRID (Spec metrics)
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF1E293B), Color(0xFF0F172A)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.15),
                  blurRadius: 12,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildAdminStat('Students', '1,284', Icons.school),
                    _buildAdminStat('Departments', '8', Icons.domain),
                    _buildAdminStat('Classes', '32', Icons.class_outlined),
                  ],
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 14),
                  child: Divider(color: Colors.white24, height: 1),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildAdminStat('CRs', '32', Icons.badge_outlined),
                    _buildAdminStat('Advisors', '32', Icons.psychology),
                    _buildAdminStat('Active Acad Year', '2026–27', Icons.calendar_month),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // TODAY'S REPORTS MONITOR
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
                const Text(
                  "Today's Reports Status",
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: const Color(0xFFDCFCE7),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: const Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Submitted',
                              style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF166534)),
                            ),
                            SizedBox(height: 4),
                            Text(
                              '29',
                              style: TextStyle(fontSize: 26, fontWeight: FontWeight.w900, color: Color(0xFF15803D)),
                            ),
                            Text('Classes marked on time', style: TextStyle(fontSize: 10, color: Color(0xFF166534))),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFEF3C7),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: const Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Pending',
                              style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF92400E)),
                            ),
                            SizedBox(height: 4),
                            Text(
                              '3',
                              style: TextStyle(fontSize: 26, fontWeight: FontWeight.w900, color: Color(0xFFB45309)),
                            ),
                            Text('Awaiting CR submission', style: TextStyle(fontSize: 10, color: Color(0xFF92400E))),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // DRILL-DOWN SELECTOR (Spec flow: MCA -> I MCA -> I MCA A)
          const Text(
            'Department & Class Explorer',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
          ),
          const SizedBox(height: 4),
          const Text(
            'Drill down into any department, year, or section',
            style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
          ),
          const SizedBox(height: 12),

          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.cardBorder),
            ),
            child: Column(
              children: [
                // Step 1: Department
                _buildDropdownRow(
                  step: '1',
                  label: 'Department',
                  value: _selectedDept,
                  items: const ['MCA', 'BCA', 'B.Sc CS', 'Other Departments'],
                  onChanged: (val) => setState(() => _selectedDept = val!),
                ),
                const SizedBox(height: 12),

                // Step 2: Year
                _buildDropdownRow(
                  step: '2',
                  label: 'Course / Year',
                  value: _selectedYear,
                  items: const ['I MCA', 'II MCA'],
                  onChanged: (val) => setState(() => _selectedYear = val!),
                ),
                const SizedBox(height: 12),

                // Step 3: Section
                _buildDropdownRow(
                  step: '3',
                  label: 'Section / Class',
                  value: _selectedSection,
                  items: const ['I MCA A', 'I MCA B'],
                  onChanged: (val) => setState(() => _selectedSection = val!),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // SELECTED CLASS PREVIEW TILE
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: const Color(0xFFEFF6FF),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFBFDBFE)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '$_selectedSection (52 Students)',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.deepBlue),
                    ),
                    ElevatedButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => ReportScreen(state: widget.state)),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      ),
                      child: const Text('View Live Report'),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text('• Class Advisor: ${widget.state.delegation.advisorName}'),
                Text('• Class Representative (CR): ${widget.state.delegation.crName}'),
                const Text('• Today Status: 43 Present / 9 Absent (Submitted at 09:18 AM) ✓'),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // SECTION FACULTY & SUBJECT DETAILS (HOD Academic Oversight)
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: const Color(0xFFC7D2FE), width: 1.5),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF6366F1).withOpacity(0.08),
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
                        color: const Color(0xFFEEF2FF),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.school, color: Color(0xFF4F46E5), size: 20),
                    ),
                    const SizedBox(width: 10),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Section Faculty & Subject Overview',
                            style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.deepBlue),
                          ),
                          Text(
                            'I MCA A • Official MVIT Faculty & Subject Lecture Details',
                            style: TextStyle(fontSize: 11, color: AppColors.textSecondary),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),

                // Assigned Class Advisor Banner
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEFF6FF),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFBFDBFE)),
                  ),
                  child: Row(
                    children: [
                      const CircleAvatar(
                        radius: 18,
                        backgroundColor: Color(0xFF2563EB),
                        child: Icon(Icons.psychology, color: Colors.white, size: 20),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Class Advisor: Mrs. V. Nandhini, AP/CA',
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF1E40AF)),
                            ),
                            Text(
                              'Hall 408 • OOPS & Lab (11 Hrs) • Access Code: NAVI2026 / ADV2026',
                              style: const TextStyle(fontSize: 11, color: Color(0xFF1E3A8A)),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: AppColors.presentGreen.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Text(
                          'Active ✓',
                          style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.presentGreen),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),

                const Text(
                  'Section Subject Teachers & Lecture Attendance:',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.textSecondary),
                ),
                const SizedBox(height: 8),

                // List of official faculty members
                Column(
                  children: kOfficialMcaFaculty.map((f) {
                    return Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.cardBorder),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              color: const Color(0xFFEEF2FF),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Center(
                              child: Text(
                                f.subjectAbb ?? 'FAC',
                                style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 11, color: Color(0xFF4F46E5)),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  f.name,
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  '${f.subject ?? f.role} (${f.subjectCode ?? ""}) • ${f.hours ?? 7} Hrs/Wk',
                                  style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                                ),
                              ],
                            ),
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                '${widget.state.presentCount}/52',
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: AppColors.presentGreen),
                              ),
                              const Text(
                                'Recorded',
                                style: TextStyle(fontSize: 10, color: AppColors.textSecondary),
                              ),
                            ],
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),

                const SizedBox(height: 10),
                const Row(
                  children: [
                    Icon(Icons.verified, size: 14, color: AppColors.presentGreen),
                    SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        'All faculty and advisors have pre-configured secure login. No manual code creation needed.',
                        style: TextStyle(fontSize: 11, color: AppColors.textSecondary),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAdminStat(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: const Color(0xFF67E8F9), size: 20),
        const SizedBox(height: 6),
        Text(
          value,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
        ),
        Text(
          label,
          style: const TextStyle(fontSize: 11, color: Colors.white70),
        ),
      ],
    );
  }

  Widget _buildDropdownRow({
    required String step,
    required String label,
    required String value,
    required List<String> items,
    required ValueChanged<String?> onChanged,
  }) {
    return Row(
      children: [
        CircleAvatar(
          radius: 12,
          backgroundColor: AppColors.primary.withOpacity(0.12),
          child: Text(
            step,
            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.primary),
          ),
        ),
        const SizedBox(width: 10),
        SizedBox(
          width: 100,
          child: Text(
            label,
            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
          ),
        ),
        Expanded(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppColors.cardBorder),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: items.contains(value) ? value : items.first,
                isExpanded: true,
                items: items
                    .map((item) => DropdownMenuItem(value: item, child: Text(item, style: const TextStyle(fontSize: 13))))
                    .toList(),
                onChanged: onChanged,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
