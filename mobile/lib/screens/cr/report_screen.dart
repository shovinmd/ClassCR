import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/theme.dart';
import '../../providers/classcr_state.dart';

class ReportScreen extends StatelessWidget {
  final ClassCRState state;

  const ReportScreen({super.key, required this.state});

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
    final reportText = state.generateSmartReportText();
    final absentees = state.absentRolls.toList()..sort();

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
            icon: const Icon(Icons.copy),
            tooltip: 'Copy Report',
            onPressed: () {
              Clipboard.setData(ClipboardData(text: reportText));
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('📋 Report copied to clipboard! Ready to paste.'),
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
                          'Formatted according to advisor requirements for I MCA',
                          style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 18),

            // REPORT PREVIEW CARD (Matches exact prompt format)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(22),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: const Color(0xFFCBD5E1), width: 1.5),
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
                  // Title
                  const Text(
                    'Attendance Report',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.deepBlue),
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
                          'Marked by: ${state.currentAttendanceRecord?.markedByName ?? state.currentUser.name} (${state.currentAttendanceRecord?.markedByRole ?? state.currentUser.roleDisplayName})',
                          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.primary),
                        ),
                      ),
                      if (state.currentAttendanceRecord?.lastModifiedBy != null && state.currentAttendanceRecord!.lastModifiedBy!.isNotEmpty)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: const Color(0xFFECFDF5),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: const Color(0xFFA7F3D0)),
                          ),
                          child: Text(
                            'Advisor Approved: ${state.currentAttendanceRecord!.lastModifiedBy}',
                            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.presentGreen),
                          ),
                        ),
                    ],
                  ),

                  const Divider(height: 24, thickness: 1),

                  // Counts
                  _buildReportLine('Total Students:', '${state.totalCount}'),
                  _buildReportLine('Present:', '${state.presentCount}', color: AppColors.presentGreen),
                  _buildReportLine('Absent:', '${state.absentCount}', color: AppColors.absentRed),

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
              ),
            ),

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
                    label: const Text(
                      'Share via WhatsApp',
                      style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
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
                            const SnackBar(
                              content: Text('📋 Report copied to clipboard!'),
                              backgroundColor: AppColors.primary,
                            ),
                          );
                        },
                        icon: const Icon(Icons.copy, size: 18),
                        label: const Text('Copy Report'),
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
                              content: Text('📤 Report prepared for sharing! (Copied to clipboard)'),
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
