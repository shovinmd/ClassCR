import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/theme.dart';
import '../../models/models.dart';
import '../../providers/classcr_state.dart';
import 'monthly_register_screen.dart';

class ReportScreen extends StatefulWidget {
  final ClassCRState state;

  const ReportScreen({super.key, required this.state});

  @override
  State<ReportScreen> createState() => _ReportScreenState();
}

class _ReportScreenState extends State<ReportScreen> {
  // Default to Names Only as requested by user for fast WhatsApp sharing
  bool _namesOnly = true;

  Future<void> _shareOnWhatsApp(BuildContext context, String reportText) async {
    // 1. Always copy report to clipboard first so the user has it ready
    await Clipboard.setData(ClipboardData(text: reportText));

    final encodedText = Uri.encodeComponent(reportText);
    final whatsappUrl = Uri.parse("https://api.whatsapp.com/send?text=$encodedText");
    final webWhatsappUrl = Uri.parse("https://web.whatsapp.com/send?text=$encodedText");

    bool launched = false;
    try {
      if (kIsWeb) {
        // On Flutter Web, launch with _blank to open in a new browser tab
        launched = await launchUrl(
          whatsappUrl,
          mode: LaunchMode.platformDefault,
          webOnlyWindowName: '_blank',
        );
        if (!launched) {
          launched = await launchUrl(
            webWhatsappUrl,
            mode: LaunchMode.platformDefault,
            webOnlyWindowName: '_blank',
          );
        }
      } else {
        if (await canLaunchUrl(whatsappUrl)) {
          launched = await launchUrl(whatsappUrl, mode: LaunchMode.externalApplication);
        } else {
          launched = await launchUrl(whatsappUrl, mode: LaunchMode.platformDefault);
        }
      }
    } catch (_) {}

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: AppColors.presentGreen,
          content: Text(
            launched
                ? '📱 Opening WhatsApp! Report also copied to clipboard.'
                : '📋 Report copied to clipboard! Paste it into your WhatsApp group.',
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = widget.state;
    final reportText = state.generateSmartReportText(namesOnly: _namesOnly);
    final dailyRec = state.dailyClassAttendanceRecord ?? state.periodRecords[1] ?? state.currentAttendanceRecord;
    final absentees = (dailyRec != null ? dailyRec.absentRolls : state.absentRolls.toList())..sort();
    final displayTotal = dailyRec?.totalStudents ?? state.totalCount;
    final displayAbsent = absentees.length;
    final displayPresent = displayTotal - displayAbsent;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 1,
        title: const Text(
          'Smart Attendance Report',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.table_chart_outlined, color: Color(0xFF0D9488)),
            tooltip: 'Monthly Register & Excel Export',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => MonthlyRegisterScreen(state: widget.state)),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.copy),
            tooltip: 'Copy Report',
            onPressed: () {
              Clipboard.setData(ClipboardData(text: reportText));
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(_namesOnly
                      ? '📋 Absentee names copied to clipboard!'
                      : '📋 Official report copied to clipboard!'),
                  backgroundColor: AppColors.primary,
                ),
              );
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header summary banner
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.cardBorder),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.presentGreen.withOpacity(0.12),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.check_circle, color: AppColors.presentGreen, size: 28),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Official Daily Report Generated',
                          style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Formatted for I MCA (Period 1 Class Record)',
                          style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // FORMAT TOGGLE: Names Only vs Detailed
            Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: const Color(0xFFE2E8F0),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () => setState(() => _namesOnly = true),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        decoration: BoxDecoration(
                          color: _namesOnly ? Colors.white : Colors.transparent,
                          borderRadius: BorderRadius.circular(10),
                          boxShadow: _namesOnly
                              ? [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.08),
                                    blurRadius: 4,
                                    offset: const Offset(0, 2),
                                  )
                                ]
                              : null,
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.person_pin_outlined,
                              size: 18,
                              color: _namesOnly ? const Color(0xFF0D9488) : AppColors.textSecondary,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              'Names Only (WhatsApp)',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: _namesOnly ? FontWeight.bold : FontWeight.w500,
                                color: _namesOnly ? const Color(0xFF0F172A) : AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    child: GestureDetector(
                      onTap: () => setState(() => _namesOnly = false),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        decoration: BoxDecoration(
                          color: !_namesOnly ? Colors.white : Colors.transparent,
                          borderRadius: BorderRadius.circular(10),
                          boxShadow: !_namesOnly
                              ? [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.08),
                                    blurRadius: 4,
                                    offset: const Offset(0, 2),
                                  )
                                ]
                              : null,
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.article_outlined,
                              size: 18,
                              color: !_namesOnly ? AppColors.primary : AppColors.textSecondary,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              'Detailed Report',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: !_namesOnly ? FontWeight.bold : FontWeight.w500,
                                color: !_namesOnly ? const Color(0xFF0F172A) : AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 18),

            // REPORT PREVIEW CARD
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(22),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                  color: _namesOnly ? const Color(0xFF99F6E4) : const Color(0xFFCBD5E1),
                  width: 1.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.04),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: _namesOnly
                  ? _buildNamesOnlyPreview(state, absentees, displayTotal, displayAbsent)
                  : _buildDetailedPreview(state, dailyRec, absentees, displayTotal, displayPresent, displayAbsent),
            ),

            if (state.periodRecords.isNotEmpty && !_namesOnly) ...[
              const SizedBox(height: 18),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: const Color(0xFFCBD5E1), width: 1.5),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.subject, color: Color(0xFF0D9488), size: 20),
                        SizedBox(width: 8),
                        Text(
                          "Today's Subject-Wise Reports",
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    ...state.periodRecords.entries.map((e) {
                      final pNo = e.key;
                      final r = e.value;
                      return Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF8FAFC),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppColors.cardBorder),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Period $pNo • ${r.periodSubject ?? "Subject"}',
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'Marked by: ${r.markedByName}',
                                  style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                                ),
                              ],
                            ),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  '${r.presentCount} P / ${r.absentCount} A',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13,
                                    color: r.absentCount > 0 ? AppColors.absentRed : AppColors.presentGreen,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: r.isLocked ? const Color(0xFFDCFCE7) : const Color(0xFFFEF3C7),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    r.isLocked ? 'Locked' : 'Draft',
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                      color: r.isLocked ? AppColors.presentGreen : const Color(0xFFB45309),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      );
                    }),
                  ],
                ),
              ),
            ],

            const SizedBox(height: 24),

            // ACTION BUTTONS: Copy Report | Share | WhatsApp
            Column(
              children: [
                // WhatsApp Button (Green highlight)
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () => _shareOnWhatsApp(context, reportText),
                    icon: const Icon(Icons.send_rounded, size: 20),
                    label: Text(
                      _namesOnly ? 'Share Names to WhatsApp' : 'Share Full Report to WhatsApp',
                      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF25D366),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                  ),
                ),

                const SizedBox(height: 10),

                Row(
                  children: [
                    // Copy Report Button
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () {
                          Clipboard.setData(ClipboardData(text: reportText));
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(_namesOnly
                                  ? '📋 Absentee names copied to clipboard!'
                                  : '📋 Official report copied to clipboard!'),
                              backgroundColor: AppColors.primary,
                            ),
                          );
                        },
                        icon: const Icon(Icons.copy, size: 18),
                        label: Text(_namesOnly ? 'Copy Names' : 'Copy Report'),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          side: const BorderSide(color: AppColors.primary),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                    ),

                    const SizedBox(width: 10),

                    // Share button
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () {
                          Clipboard.setData(ClipboardData(text: reportText));
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('📤 Report copied to clipboard for sharing!'),
                            ),
                          );
                        },
                        icon: const Icon(Icons.share_outlined, size: 18),
                        label: const Text('Share'),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          side: const BorderSide(color: AppColors.textSecondary),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // CLEAN NAMES-ONLY PREVIEW
  Widget _buildNamesOnlyPreview(
    ClassCRState state,
    List<int> absentees,
    int displayTotal,
    int displayAbsent,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'I MCA A — MVIT',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: Color(0xFF0F172A)),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: const Color(0xFFCCFBF1),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: const Color(0xFF5EEAD4)),
              ),
              child: const Text(
                '💬 WhatsApp Format',
                style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF0F766E)),
              ),
            ),
          ],
        ),
        Text(
          'Date: ${state.formattedTodayDate}/',
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF0D9488)),
        ),
        Text(
          state.todayDayName,
          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textSecondary),
        ),
        const SizedBox(height: 6),
        const Text(
          'Absentees Name list',
          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: AppColors.absentRed),
        ),
        const Divider(height: 20, thickness: 1),
        if (absentees.isEmpty)
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFF0FDF4),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Text(
              'None! 100% Attendance 🎉',
              style: TextStyle(color: AppColors.presentGreen, fontWeight: FontWeight.bold),
            ),
          )
        else
          ...absentees.asMap().entries.map((entry) {
            final idx = entry.key + 1;
            final rNo = entry.value;
            final st = state.students.firstWhere(
              (s) => s.rollNo == rNo,
              orElse: () => Student(rollNo: rNo, enrollmentNo: 'N/A', name: 'Student $rNo'),
            );
            return Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(
                children: [
                  Text(
                    '$idx.',
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF475569)),
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      st.name,
                      style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14, color: Color(0xFF1E293B)),
                    ),
                  ),
                ],
              ),
            );
          }),
      ],
    );
  }

  // DETAILED OFFICIAL PREVIEW
  Widget _buildDetailedPreview(
    ClassCRState state,
    dynamic dailyRec,
    List<int> absentees,
    int displayTotal,
    int displayPresent,
    int displayAbsent,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Title
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Attendance Report',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.deepBlue),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: const Color(0xFFFEF3C7),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: const Color(0xFFFCD34D)),
              ),
              child: const Text(
                '👑 Period 1: Official Class Record',
                style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF92400E)),
              ),
            ),
          ],
        ),
        const Text(
          'I MCA A — MVIT',
          style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: AppColors.primary),
        ),
        Text(
          'Date: ${state.formattedTodayDate}',
          style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
        ),
        const SizedBox(height: 6),
        Wrap(
          spacing: 6,
          runSpacing: 4,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: const Color(0xFFEFF6FF),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: const Color(0xFFBFDBFE)),
              ),
              child: Text(
                'Marked by: ${dailyRec?.markedByName ?? state.currentAttendanceRecord?.markedByName ?? state.currentUser.name} (${dailyRec?.markedByRole ?? state.currentAttendanceRecord?.markedByRole ?? state.currentUser.roleDisplayName})',
                style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.primary),
              ),
            ),
            if (dailyRec?.lastModifiedBy != null && dailyRec!.lastModifiedBy!.isNotEmpty)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFFECFDF5),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: const Color(0xFFA7F3D0)),
                ),
                child: Text(
                  'Advisor Approved: ${dailyRec.lastModifiedBy}',
                  style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.presentGreen),
                ),
              ),
          ],
        ),

        const Divider(height: 24, thickness: 1),

        // Counts
        _buildReportLine('Total Students:', '$displayTotal'),
        _buildReportLine('Present:', '$displayPresent', color: AppColors.presentGreen),
        _buildReportLine('Absent:', '$displayAbsent', color: AppColors.absentRed),

        const Divider(height: 24, thickness: 1),

        // Absent students section
        const Text(
          'Absent Students:',
          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: AppColors.textPrimary),
        ),
        const SizedBox(height: 12),

        if (absentees.isEmpty)
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFF0FDF4),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Text(
              'None! 100% Attendance.',
              style: TextStyle(color: AppColors.presentGreen, fontWeight: FontWeight.bold),
            ),
          )
        else
          ...absentees.map((rNo) {
            final st = state.students.firstWhere((s) => s.rollNo == rNo);
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${st.rollNo}. ${st.name}',
                    style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(left: 18, top: 1),
                    child: Text(
                      st.enrollmentNo,
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                        fontFamily: 'monospace',
                      ),
                    ),
                  ),
                ],
              ),
            );
          }),
      ],
    );
  }

  Widget _buildReportLine(String label, String value, {Color? color}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
          Text(
            value,
            style: TextStyle(
              fontWeight: FontWeight.w800,
              fontSize: 14,
              color: color ?? AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}
