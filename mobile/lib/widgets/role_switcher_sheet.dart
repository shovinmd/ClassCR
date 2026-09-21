import 'package:flutter/material.dart';
import '../core/theme.dart';
import '../models/models.dart';
import '../providers/classcr_state.dart';
import '../screens/auth/setup_screen.dart';

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

  void _promptPasscodeAndSwitch(BuildContext context, UserRole role, {bool? isFemale}) {
    // Student & Admin do not require secret CR passcodes
    if (role == UserRole.student || role == UserRole.admin) {
      state.switchRole(role);
      Navigator.pop(context);
      return;
    }

    String roleLabel = '';
    if (role == UserRole.cr) {
      roleLabel = 'Class Representative (CR)';
    } else if (role == UserRole.assistantCr) {
      roleLabel = isFemale == true ? 'Female Assistant CR (Girls Section)' : 'Male Assistant CR (Boys Section)';
    } else if (role == UserRole.advisor) {
      roleLabel = 'Class Advisor';
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
                  final gender = isFemale != null ? (isFemale ? 'F' : 'M') : null;
                  final res = await state.verifyRolePasscode(
                    classId: 'I-MCA-A',
                    role: role,
                    code: entered,
                    gender: gender,
                  );

                  if (res['valid'] == true) {
                    Navigator.pop(dialogCtx); // Close dialog
                    Navigator.pop(context);   // Close bottom sheet
                    if (role == UserRole.assistantCr && isFemale != null) {
                      state.switchAssistantCrRole(isFemale: isFemale);
                    } else {
                      state.switchRole(role);
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

  @override
  Widget build(BuildContext context) {
    final currentRole = state.currentRole;
    final isFemaleAsst = currentRole == UserRole.assistantCr && state.currentUser.gender == 'F';
    final isMaleAsst = currentRole == UserRole.assistantCr && state.currentUser.gender != 'F';

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
              subtitle: 'MUTHUVEL R • I MCA A (Full attendance & reports management)',
              icon: Icons.badge_outlined,
              color: AppColors.primary,
              onTap: () => _promptPasscodeAndSwitch(context, UserRole.cr),
            ),

            // 2a. Male Assistant CR
            _buildCustomTile(
              context,
              isSelected: isMaleAsst,
              title: '2a. Male Assistant CR (Boys Section)',
              subtitle: 'SHOVIN MICHEL DAVID • Cross-checks 28 Boys, marks & updates',
              icon: Icons.male,
              color: const Color(0xFF0284C7),
              onTap: () => _promptPasscodeAndSwitch(context, UserRole.assistantCr, isFemale: false),
            ),

            // 2b. Female Assistant CR
            _buildCustomTile(
              context,
              isSelected: isFemaleAsst,
              title: '2b. Female Assistant CR (Girls Section)',
              subtitle: 'DHIVYALAKSHMI H • Cross-checks 24 Girls, marks & updates',
              icon: Icons.female,
              color: const Color(0xFFDB2777),
              onTap: () => _promptPasscodeAndSwitch(context, UserRole.assistantCr, isFemale: true),
            ),

            // 3. Advisor
            _buildCustomTile(
              context,
              isSelected: currentRole == UserRole.advisor,
              title: '3. Class Advisor',
              subtitle: 'Dr. K. Senthil Nathan • Review submissions, confirm, & announce',
              icon: Icons.psychology_alt_outlined,
              color: const Color(0xFF0284C7),
              onTap: () => _promptPasscodeAndSwitch(context, UserRole.advisor),
            ),

            // 4. Student
            _buildCustomTile(
              context,
              isSelected: currentRole == UserRole.student,
              title: '4. Student Portal',
              subtitle: 'View attendance percentage, personal logs, and shortage alerts',
              icon: Icons.school_outlined,
              color: AppColors.presentGreen,
              onTap: () => _promptPasscodeAndSwitch(context, UserRole.student),
            ),

            // 5. HOD
            _buildCustomTile(
              context,
              isSelected: currentRole == UserRole.admin,
              title: '5. Head of Department (HOD)',
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
            const SizedBox(height: 8),
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
