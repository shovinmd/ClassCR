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

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: const EdgeInsets.all(24),
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
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Switch Demo Role',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  Text(
                    'Experience ClassCR from all 4 user perspectives',
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
          _buildRoleTile(
            context,
            role: UserRole.cr,
            title: '1. Class Representative (CR)',
            subtitle: 'MUTHUVEL R • I MCA A (Mark attendance, smart reports, offline sync)',
            icon: Icons.badge_outlined,
            color: AppColors.primary,
          ),
          _buildRoleTile(
            context,
            role: UserRole.assistantCr,
            title: '2. Assistant CR (Asst. CR)',
            subtitle: 'SHOVIN MICHEL DAVID • I MCA A (Equal CR privileges: mark, verify, share reports)',
            icon: Icons.assignment_ind_outlined,
            color: const Color(0xFF0D9488),
          ),
          _buildRoleTile(
            context,
            role: UserRole.advisor,
            title: '3. Class Advisor',
            subtitle: 'Dr. K. Senthil Nathan • I MCA A (Review submissions, correct records, announcements)',
            icon: Icons.psychology_alt_outlined,
            color: const Color(0xFF0284C7),
          ),
          _buildRoleTile(
            context,
            role: UserRole.student,
            title: '4. Student',
            subtitle: 'DHIVYALAKSHMI H • Roll #13 (View 86.67% attendance %, history, alerts)',
            icon: Icons.school_outlined,
            color: AppColors.presentGreen,
          ),
          _buildRoleTile(
            context,
            role: UserRole.admin,
            title: '5. College Admin',
            subtitle: 'College Administrator (1,284 students, 32 classes, 8 departments)',
            icon: Icons.admin_panel_settings_outlined,
            color: const Color(0xFF8B5CF6),
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
    );
  }

  Widget _buildRoleTile(
    BuildContext context, {
    required UserRole role,
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
  }) {
    final isSelected = state.currentRole == role;

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
        onTap: () {
          state.switchRole(role);
          Navigator.pop(context);
        },
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
