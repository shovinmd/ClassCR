import 'package:flutter/material.dart';
import '../../core/theme.dart';
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
                        'Dr. K. Senthil Nathan • I MCA A',
                        style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
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
                                  const Text(
                                    'Submitted by MUTHUVEL R',
                                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
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
