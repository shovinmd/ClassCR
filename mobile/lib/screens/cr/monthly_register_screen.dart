import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/theme.dart';
import '../../models/models.dart';
import '../../providers/classcr_state.dart';

class MonthlyRegisterScreen extends StatefulWidget {
  final ClassCRState state;

  const MonthlyRegisterScreen({super.key, required this.state});

  @override
  State<MonthlyRegisterScreen> createState() => _MonthlyRegisterScreenState();
}

class _MonthlyRegisterScreenState extends State<MonthlyRegisterScreen> {
  late String _selectedYearMonth;
  String _selectedSubject = 'ALL';
  String _searchQuery = '';
  bool _isLoading = true;
  List<AttendanceRecord> _monthRecords = [];

  final List<Map<String, String>> _availableMonths = [
    {'label': 'September 2026', 'value': '2026-09'},
    {'label': 'October 2026', 'value': '2026-10'},
    {'label': 'November 2026', 'value': '2026-11'},
    {'label': 'August 2026', 'value': '2026-08'},
    {'label': 'July 2026', 'value': '2026-07'},
  ];

  final List<String> _subjects = [
    'ALL',
    'OOPS',
    'MAT',
    'DT',
    'OS',
    'SE',
    'DT LAB',
    'OS LAB',
    'OOPS LAB',
    'LIB',
  ];

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _selectedYearMonth = "${now.year.toString().padLeft(4, '0')}-${now.month.toString().padLeft(2, '0')}";
    _loadRecords();
  }

  Future<void> _loadRecords() async {
    setState(() => _isLoading = true);
    final recs = await widget.state.fetchMonthRecords(_selectedYearMonth);
    if (mounted) {
      setState(() {
        _monthRecords = recs;
        _isLoading = false;
      });
    }
  }

  List<AttendanceRecord> get _filteredRecords {
    if (_selectedSubject == 'ALL') return _monthRecords;
    return _monthRecords.where((r) =>
      (r.periodSubject ?? '').toUpperCase().contains(_selectedSubject.toUpperCase())
    ).toList();
  }

  void _downloadExcelCsv() async {
    final csvContent = widget.state.generateMonthlyExcelCsv(
      records: _monthRecords,
      subjectFilter: _selectedSubject,
      yearMonth: _selectedYearMonth,
    );

    // Always copy to clipboard for convenience
    await Clipboard.setData(ClipboardData(text: csvContent));

    final filename = 'Attendance_${_selectedSubject}_$_selectedYearMonth.csv';
    final encoded = Uri.encodeComponent(csvContent);
    final uri = Uri.parse('data:text/csv;charset=utf-8,$encoded');

    try {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (_) {}

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: AppColors.presentGreen,
          duration: const Duration(seconds: 4),
          content: Text('📥 Excel CSV ready! "$filename" copied to clipboard for direct paste into Excel/Sheets.'),
        ),
      );
    }
  }

  void _copyExcelCsv() async {
    final csvContent = widget.state.generateMonthlyExcelCsv(
      records: _monthRecords,
      subjectFilter: _selectedSubject,
      yearMonth: _selectedYearMonth,
    );
    await Clipboard.setData(ClipboardData(text: csvContent));
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: Color(0xFF0F766E),
          content: Text('📋 Excel Sheet (CSV) copied! Open Excel or Google Sheets and Paste.'),
        ),
      );
    }
  }

  void _showHardCopyDialog() {
    final hardCopyText = widget.state.generateMonthlyHardCopyText(
      records: _monthRecords,
      subjectFilter: _selectedSubject,
      yearMonth: _selectedYearMonth,
    );

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.print, color: Color(0xFF0D9488)),
            const SizedBox(width: 8),
            Text(
              'Subject Hard Copy Preview',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        content: SizedBox(
          width: double.maxFinite,
          height: 450,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Department official format with signature blocks ready for print / submission to subject teacher:',
                style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
              ),
              const SizedBox(height: 10),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: SingleChildScrollView(
                    child: SelectableText(
                      hardCopyText,
                      style: const TextStyle(fontFamily: 'monospace', fontSize: 11),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton.icon(
            onPressed: () {
              Clipboard.setData(ClipboardData(text: hardCopyText));
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('📋 Hard copy text copied to clipboard!')),
              );
            },
            icon: const Icon(Icons.copy, size: 16),
            label: const Text('Copy Hard Copy'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx),
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF0D9488)),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _confirmDeleteMonthRecords() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: AppColors.absentRed, size: 28),
            SizedBox(width: 10),
            Expanded(
              child: Text(
                'Delete Month Records?',
                style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: AppColors.absentRed),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Are you sure you want to delete all attendance records for $_selectedYearMonth from the database?',
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFFEF2F2),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFFFECACA)),
              ),
              child: const Row(
                children: [
                  Icon(Icons.info_outline, color: AppColors.absentRed, size: 18),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'IMPORTANT: Please ensure you have downloaded the Excel sheet and saved the official Hard Copy before purging records for this month.',
                      style: TextStyle(fontSize: 12, color: Color(0xFF991B1B)),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel', style: TextStyle(color: AppColors.textSecondary)),
          ),
          ElevatedButton.icon(
            onPressed: () async {
              Navigator.pop(ctx);
              setState(() => _isLoading = true);
              final ok = await widget.state.deleteMonthAttendance(_selectedYearMonth);
              await _loadRecords();
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    backgroundColor: ok ? AppColors.presentGreen : AppColors.absentRed,
                    content: Text(ok
                        ? '🧹 Attendance records for $_selectedYearMonth deleted successfully. Database reset for new month.'
                        : '⚠️ Could not clear remote records, but local month cache was reset.'),
                  ),
                );
              }
            },
            icon: const Icon(Icons.delete_forever, size: 18),
            label: const Text('Confirm & Delete Month'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.absentRed,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final relevantRecords = _filteredRecords;
    final totalSessions = relevantRecords.length;

    // Calculate students attendance stats
    int shortageCount = 0;
    double totalPctSum = 0;

    for (final s in widget.state.students) {
      int attended = 0;
      for (final r in relevantRecords) {
        if (!r.absentRolls.contains(s.rollNo)) attended++;
      }
      final pct = totalSessions > 0 ? (attended / totalSessions) * 100 : 100.0;
      totalPctSum += pct;
      if (pct < 75.0) {
        shortageCount++;
      }
    }
    final avgAttendance = widget.state.students.isNotEmpty ? totalPctSum / widget.state.students.length : 100.0;

    // Filter students by search
    final displayedStudents = widget.state.students.where((st) {
      if (_searchQuery.isEmpty) return true;
      final q = _searchQuery.toLowerCase();
      return st.name.toLowerCase().contains(q) ||
          st.rollNo.toString() == q.trim() ||
          st.enrollmentNo.toLowerCase().contains(q);
    }).toList();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 1,
        title: const Text(
          'Monthly Subject Register',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: AppColors.primary),
            tooltip: 'Reload Month Records',
            onPressed: _loadRecords,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Month Picker & Subject Selector Bar
                  Container(
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
                          children: [
                            const Icon(Icons.calendar_month, color: AppColors.primary, size: 20),
                            const SizedBox(width: 8),
                            const Text(
                              'Select Month:',
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                            ),
                            const Spacer(),
                            DropdownButton<String>(
                              value: _selectedYearMonth,
                              underline: const SizedBox(),
                              borderRadius: BorderRadius.circular(10),
                              style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary, fontSize: 13),
                              items: _availableMonths.map((m) {
                                return DropdownMenuItem<String>(
                                  value: m['value'],
                                  child: Text(m['label']!),
                                );
                              }).toList(),
                              onChanged: (val) {
                                if (val != null) {
                                  setState(() => _selectedYearMonth = val);
                                  _loadRecords();
                                }
                              },
                            ),
                          ],
                        ),
                        const Divider(height: 16),
                        const Text(
                          'Subject Filter:',
                          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textSecondary),
                        ),
                        const SizedBox(height: 8),
                        SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            children: _subjects.map((sub) {
                              final isSelected = _selectedSubject == sub;
                              return Padding(
                                padding: const EdgeInsets.only(right: 8),
                                child: FilterChip(
                                  selected: isSelected,
                                  label: Text(sub),
                                  labelStyle: TextStyle(
                                    fontSize: 11,
                                    fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                                    color: isSelected ? Colors.white : AppColors.textPrimary,
                                  ),
                                  selectedColor: const Color(0xFF0D9488),
                                  checkmarkColor: Colors.white,
                                  backgroundColor: const Color(0xFFF1F5F9),
                                  onSelected: (_) => setState(() => _selectedSubject = sub),
                                ),
                              );
                            }).toList(),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 14),

                  // Monthly Metrics Summary
                  Row(
                    children: [
                      Expanded(
                        child: _buildMetricTile(
                          'Sessions Held',
                          '$totalSessions',
                          _selectedSubject == 'ALL' ? 'All Subjects' : _selectedSubject,
                          Icons.event_available,
                          const Color(0xFF0D9488),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _buildMetricTile(
                          'Class Avg',
                          '${avgAttendance.toStringAsFixed(1)}%',
                          '52 Students',
                          Icons.insights,
                          AppColors.presentGreen,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _buildMetricTile(
                          'Shortage (<75%)',
                          '$shortageCount',
                          'Need Attention',
                          Icons.warning_amber,
                          shortageCount > 0 ? AppColors.absentRed : AppColors.presentGreen,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 14),

                  // Quick Action Buttons (Excel, Hard Copy, Delete)
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF0F766E), Color(0xFF115E59)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF0F766E).withOpacity(0.25),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Row(
                          children: [
                            Icon(Icons.table_chart, color: Colors.white, size: 20),
                            SizedBox(width: 8),
                            Text(
                              'Month-End Subject Register Exports',
                              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          'Generate Excel spreadsheets and hard copies to submit to faculty before clearing month records.',
                          style: TextStyle(color: Colors.white70, fontSize: 11),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: ElevatedButton.icon(
                                onPressed: _downloadExcelCsv,
                                icon: const Icon(Icons.download, size: 16),
                                label: const Text('Excel (.csv)', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.white,
                                  foregroundColor: const Color(0xFF0F766E),
                                  padding: const EdgeInsets.symmetric(vertical: 12),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: _showHardCopyDialog,
                                icon: const Icon(Icons.print, size: 16, color: Colors.white),
                                label: const Text('Hard Copy', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white)),
                                style: OutlinedButton.styleFrom(
                                  side: const BorderSide(color: Colors.white),
                                  padding: const EdgeInsets.symmetric(vertical: 12),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            IconButton(
                              onPressed: _copyExcelCsv,
                              tooltip: 'Copy Excel Sheet',
                              icon: const Icon(Icons.copy, color: Colors.white),
                              style: IconButton.styleFrom(
                                backgroundColor: Colors.white.withOpacity(0.15),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 14),

                  // Search Student Roster
                  TextField(
                    decoration: InputDecoration(
                      hintText: 'Search Roll No or Student Name...',
                      prefixIcon: const Icon(Icons.search, size: 20),
                      isDense: true,
                      contentPadding: const EdgeInsets.symmetric(vertical: 12),
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: AppColors.cardBorder),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: AppColors.cardBorder),
                      ),
                    ),
                    onChanged: (val) => setState(() => _searchQuery = val),
                  ),

                  const SizedBox(height: 12),

                  // Students Register List
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: AppColors.cardBorder),
                    ),
                    child: ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: displayedStudents.length,
                      separatorBuilder: (_, _) => const Divider(height: 1),
                      itemBuilder: (context, index) {
                        final student = displayedStudents[index];
                        int attended = 0;
                        for (final r in relevantRecords) {
                          if (!r.absentRolls.contains(student.rollNo)) attended++;
                        }
                        final pct = totalSessions > 0 ? (attended / totalSessions) * 100 : 100.0;
                        final isEligible = pct >= 75.0;

                        return Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                          child: Row(
                            children: [
                              CircleAvatar(
                                radius: 16,
                                backgroundColor: isEligible
                                    ? AppColors.presentGreen.withOpacity(0.15)
                                    : AppColors.absentRed.withOpacity(0.15),
                                child: Text(
                                  '${student.rollNo}',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12,
                                    color: isEligible ? AppColors.presentGreen : AppColors.absentRed,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      student.name,
                                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                                    ),
                                    Text(
                                      '${student.enrollmentNo} • ${student.code}',
                                      style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                                    ),
                                  ],
                                ),
                              ),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text(
                                    '$attended / $totalSessions',
                                    style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12),
                                  ),
                                  const SizedBox(height: 2),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: isEligible ? const Color(0xFFF0FDF4) : const Color(0xFFFEF2F2),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Text(
                                      '${pct.toStringAsFixed(1)}% ${isEligible ? "ELIGIBLE" : "SHORTAGE"}',
                                      style: TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                        color: isEligible ? AppColors.presentGreen : AppColors.absentRed,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Month-End Purge Records Danger Zone
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFEF2F2),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: const Color(0xFFFECACA)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Row(
                          children: [
                            Icon(Icons.delete_sweep, color: AppColors.absentRed, size: 20),
                            SizedBox(width: 8),
                            Text(
                              'Month-End Database Reset',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF991B1B),
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Once you have downloaded the Excel sheet and saved the official Hard Copy for $_selectedYearMonth, clear the month records from Supabase to prepare for the upcoming month.',
                          style: const TextStyle(fontSize: 12, color: Color(0xFF7F1D1D)),
                        ),
                        const SizedBox(height: 12),
                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton.icon(
                            onPressed: _confirmDeleteMonthRecords,
                            icon: const Icon(Icons.delete_forever, size: 18, color: AppColors.absentRed),
                            label: Text(
                              'Purge & Delete $_selectedYearMonth Records',
                              style: const TextStyle(color: AppColors.absentRed, fontWeight: FontWeight.bold),
                            ),
                            style: OutlinedButton.styleFrom(
                              side: const BorderSide(color: AppColors.absentRed),
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 30),
                ],
              ),
            ),
    );
  }

  Widget _buildMetricTile(String title, String value, String subtitle, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: color),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: AppColors.textSecondary),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: color),
          ),
          Text(
            subtitle,
            style: const TextStyle(fontSize: 9, color: AppColors.textSecondary),
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}
