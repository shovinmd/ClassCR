import 'package:flutter/material.dart';
import '../core/theme.dart';
import '../models/models.dart';
import '../providers/classcr_state.dart';
import '../screens/auth/setup_screen.dart';
import '../services/update_service.dart';

class RoleSwitcherSheet extends StatelessWidget {
  final ClassCRState state;

  const RoleSwitcherSheet({super.key, required this.state});

  static void show(BuildContext context, ClassCRState state) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => RoleSwitcherSheet(state: state),
    );
  }

  void _promptPasscodeAndSwitch(BuildContext context, UserRole role) {
    if (role == UserRole.student) {
      _showStudentSwitchDialog(context);
      return;
    }

    String roleLabel = '';
    if (role == UserRole.cr) {
      roleLabel = 'Class Representative (CR)';
    } else if (role == UserRole.assistantCr) {
      roleLabel = 'Assistant CR (Asst. CR)';
    } else if (role == UserRole.advisor) {
      roleLabel = 'Class Advisor (Mrs. V. Nandhini, AP/CA)';
    } else if (role == UserRole.staff) {
      roleLabel = 'Subject Teacher / Faculty';
    } else if (role == UserRole.admin) {
      roleLabel = 'Head of Department (HOD) / Admin';
    }

    final controller = TextEditingController();
    String error = '';

    showDialog(
      context: context,
      builder: (dialogCtx) => StatefulBuilder(
        builder: (ctx, setDialogState) {
          return AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
            title: Row(
              children: [
                const Icon(Icons.lock_outline, color: AppColors.primary),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Passcode Required',
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Enter authorized passcode to switch into $roleLabel:',
                  style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: controller,
                  textCapitalization: TextCapitalization.characters,
                  obscureText: true,
                  autofocus: true,
                  decoration: const InputDecoration(
                    labelText: 'Passcode',
                    hintText: 'Enter college passcode',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.key, size: 18),
                  ),
                ),
                if (error.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(
                    error,
                    style: const TextStyle(fontSize: 12, color: AppColors.absentRed, fontWeight: FontWeight.bold),
                  ),
                ],
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogCtx),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                onPressed: () async {
                  final entered = controller.text.trim().toUpperCase();
                  final res = await state.verifyRolePasscode(
                    classId: 'I-MCA-A',
                    role: role,
                    code: entered,
                  );

                  if (res['valid'] == true) {
                    Navigator.pop(dialogCtx); // Close dialog
                    Navigator.pop(context);   // Close bottom sheet
                    if (role == UserRole.assistantCr) {
                      final isFemale = res['gender'] == 'F' || entered == 'FACR2026' || (state.currentUser.gender == 'F' && entered != 'MACR2026');
                      state.switchAssistantCrRole(
                        isFemale: isFemale,
                        customName: res['name']?.toString(),
                        customRoll: res['rollNo'] is int ? res['rollNo'] as int : int.tryParse(res['rollNo']?.toString() ?? ''),
                      );
                    } else {
                      state.switchRole(
                        role,
                        customName: res['name']?.toString(),
                        customSubject: res['subject']?.toString(),
                      );
                    }
                  } else {
                    setDialogState(() {
                      error = res['error']?.toString() ?? 'Invalid passcode for $roleLabel!';
                    });
                  }
                },
                child: const Text('Verify & Switch'),
              ),
            ],
          );
        },
      ),
    );
  }

  void _showStudentSwitchDialog(BuildContext context) {
    Student? selectedStudent = state.students.isNotEmpty ? state.students.first : null;
    final codeController = TextEditingController();
    String error = '';

    showDialog(
      context: context,
      builder: (dialogCtx) => StatefulBuilder(
        builder: (ctx, setDialogState) {
          void updateFromInput(String val) {
            final trimmed = val.trim().toUpperCase();
            if (trimmed.isEmpty) return;
            final match = state.students.cast<Student?>().firstWhere(
              (s) => s != null && (
                s.rollNo.toString() == trimmed ||
                s.code.toUpperCase() == trimmed ||
                'CCR-${s.rollNo}' == trimmed ||
                'CCR-${s.rollNo.toString().padLeft(4, '0')}' == trimmed ||
                s.enrollmentNo.toUpperCase() == trimmed
              ),
              orElse: () => null,
            );
            if (match != null) {
              setDialogState(() {
                selectedStudent = match;
                error = '';
              });
            }
          }

          return AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
            title: const Row(
              children: [
                Icon(Icons.school_outlined, color: AppColors.presentGreen),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Student Verification',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Enter your Roll Number (1–52) or CCR Code:',
                    style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: codeController,
                    textCapitalization: TextCapitalization.characters,
                    decoration: const InputDecoration(
                      labelText: 'Roll No or CCR Code',
                      hintText: 'e.g. 13 or CCR-0013',
                      prefixIcon: Icon(Icons.pin, size: 20),
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    ),
                    onChanged: updateFromInput,
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Or select your name from class roster:',
                    style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                  ),
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      border: Border.all(color: AppColors.cardBorder),
                      borderRadius: BorderRadius.circular(10),
                      color: const Color(0xFFF8FAFC),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<Student>(
                        isExpanded: true,
                        value: selectedStudent,
                        hint: const Text('Select your name'),
                        items: state.students.map((st) {
                          return DropdownMenuItem<Student>(
                            value: st,
                            child: Text(
                              '${st.rollNo}. ${st.name} (${st.enrollmentNo})',
                              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                              overflow: TextOverflow.ellipsis,
                            ),
                          );
                        }).toList(),
                        onChanged: (val) {
                          setDialogState(() {
                            selectedStudent = val;
                            if (val != null) {
                              codeController.text = val.rollNo.toString();
                              error = '';
                            }
                          });
                        },
                      ),
                    ),
                  ),
                  if (selectedStudent != null) ...[
                    const SizedBox(height: 14),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFECFDF5),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: const Color(0xFFA7F3D0)),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            selectedStudent!.isFemale ? Icons.female : Icons.male,
                            color: AppColors.presentGreen,
                            size: 20,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  selectedStudent!.name,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13,
                                    color: Color(0xFF065F46),
                                  ),
                                ),
                                Text(
                                  'Roll #${selectedStudent!.rollNo} • Code: ${selectedStudent!.code}',
                                  style: const TextStyle(fontSize: 11, color: Color(0xFF047857)),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                  if (error.isNotEmpty) ...[
                    const SizedBox(height: 10),
                    Text(
                      error,
                      style: const TextStyle(fontSize: 12, color: AppColors.absentRed, fontWeight: FontWeight.bold),
                    ),
                  ],
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogCtx),
                child: const Text('Cancel'),
              ),
              ElevatedButton.icon(
                icon: const Icon(Icons.check_circle_outline, size: 18),
                label: const Text('Verify & Switch'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.presentGreen,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                onPressed: () async {
                  final entered = codeController.text.trim().toUpperCase();
                  if (entered.isNotEmpty) {
                    final res = await state.verifyRolePasscode(
                      classId: 'I-MCA-A',
                      role: UserRole.student,
                      code: entered,
                      rollNo: selectedStudent?.rollNo,
                    );
                    if (res['valid'] != true) {
                      setDialogState(() {
                        error = res['error']?.toString() ?? 'Invalid Roll No or CCR Code.';
                      });
                      return;
                    }
                  }
                  if (selectedStudent == null) return;
                  Navigator.pop(dialogCtx);
                  Navigator.pop(context);
                  state.switchRole(
                    UserRole.student,
                    customName: selectedStudent!.name,
                    customStudentId: selectedStudent!.enrollmentNo,
                    customGender: selectedStudent!.isFemale ? 'F' : 'M',
                  );
                },
              ),
            ],
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final currentRole = state.currentRole;

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: const EdgeInsets.all(24),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.swap_horiz, color: AppColors.primary),
                ),
                const SizedBox(width: 14),
                const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Switch Verified Role',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    Text(
                      'Enter passcode to switch authorized perspective',
                      style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                    ),
                  ],
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // 1. CR
            _buildCustomTile(
              context,
              isSelected: currentRole == UserRole.cr,
              title: '1. Class Representative (CR)',
              subtitle: '${state.delegation.crName} • I MCA A (Full attendance & reports management)',
              icon: Icons.badge_outlined,
              color: AppColors.primary,
              onTap: () => _promptPasscodeAndSwitch(context, UserRole.cr),
            ),

            // 2. Assistant CR
            _buildCustomTile(
              context,
              isSelected: currentRole == UserRole.assistantCr,
              title: '2. Assistant CR (Asst. CR)',
              subtitle: '${state.delegation.femaleAsstName} & ${state.delegation.maleAsstName} • Verifies section with CR',
              icon: Icons.how_to_reg_outlined,
              color: const Color(0xFF0284C7),
              onTap: () => _promptPasscodeAndSwitch(context, UserRole.assistantCr),
            ),

            // 3. Advisor
            _buildCustomTile(
              context,
              isSelected: currentRole == UserRole.advisor,
              title: '3. Class Advisor',
              subtitle: 'Mrs. V. Nandhini, AP/CA • Class Advisor & Academic Mentor',
              icon: Icons.psychology_alt_outlined,
              color: const Color(0xFF0284C7),
              onTap: () => _promptPasscodeAndSwitch(context, UserRole.advisor),
            ),

            // 4. Subject Teacher / Faculty
            _buildCustomTile(
              context,
              isSelected: currentRole == UserRole.staff,
              title: '4. Subject Teacher / Faculty',
              subtitle: 'OS (Tamilmani), MAT (Sivaramakrishnan), DT (Shivashankari), SE (Deepa)',
              icon: Icons.menu_book_outlined,
              color: const Color(0xFF0D9488),
              onTap: () => _promptPasscodeAndSwitch(context, UserRole.staff),
            ),

            // 5. Student
            _buildCustomTile(
              context,
              isSelected: currentRole == UserRole.student,
              title: '5. Student Portal',
              subtitle: 'View attendance percentage, personal logs, and shortage alerts',
              icon: Icons.school_outlined,
              color: AppColors.presentGreen,
              onTap: () => _promptPasscodeAndSwitch(context, UserRole.student),
            ),

            // 6. HOD
            _buildCustomTile(
              context,
              isSelected: currentRole == UserRole.admin,
              title: '6. Head of Department (HOD)',
              subtitle: 'Department & Academic Oversight (Classes, Faculty, Attendance)',
              icon: Icons.admin_panel_settings_outlined,
              color: const Color(0xFF8B5CF6),
              onTap: () => _promptPasscodeAndSwitch(context, UserRole.admin),
            ),

            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () async {
                  await state.resetSetup();
                  if (context.mounted) {
                    Navigator.pop(context);
                    Navigator.of(context).pushReplacement(
                      MaterialPageRoute(
                        builder: (_) => SetupScreen(state: state),
                      ),
                    );
                  }
                },
                icon: const Icon(Icons.restart_alt, size: 18),
                label: const Text('Re-run First-Time Class & Role Setup'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.primary,
                  side: const BorderSide(color: AppColors.primary),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
            const SizedBox(height: 6),
            SizedBox(
              width: double.infinity,
              child: TextButton.icon(
                onPressed: () {
                  Navigator.pop(context);
                  UpdateService.checkForUpdatesManual(context);
                },
                icon: const Icon(Icons.system_update_alt, size: 16, color: AppColors.textSecondary),
                label: const Text(
                  'Check for App Updates (OTA)',
                  style: TextStyle(fontSize: 12, color: AppColors.textSecondary, fontWeight: FontWeight.w600),
                ),
              ),
            ),
            const SizedBox(height: 4),
          ],
        ),
      ),
    );
  }

  Widget _buildCustomTile(
    BuildContext context, {
    required bool isSelected,
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: isSelected ? color.withOpacity(0.08) : const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isSelected ? color : const Color(0xFFE2E8F0),
          width: isSelected ? 2 : 1,
        ),
      ),
      child: ListTile(
        onTap: onTap,
        leading: CircleAvatar(
          backgroundColor: color.withOpacity(0.15),
          child: Icon(icon, color: color, size: 22),
        ),
        title: Text(
          title,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 14,
            color: isSelected ? color : AppColors.textPrimary,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
        ),
        trailing: isSelected
            ? Icon(Icons.check_circle, color: color)
            : const Icon(Icons.chevron_right, color: Color(0xFFCBD5E1)),
      ),
    );
  }
}
