import 'package:flutter/material.dart';
import '../core/theme.dart';
import '../models/models.dart';
import '../providers/classcr_state.dart';
import '../widgets/app_header.dart';
import '../widgets/role_switcher_sheet.dart';
import 'cr/cr_home_screen.dart';
import 'cr/mark_attendance_screen.dart';
import 'cr/report_screen.dart';
import 'advisor/advisor_dashboard_screen.dart';
import 'staff/staff_dashboard_screen.dart';
import 'student/student_portal_screen.dart';
import 'admin/admin_dashboard_screen.dart';

class MainShell extends StatefulWidget {
  final ClassCRState state;

  const MainShell({super.key, required this.state});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _currentIndex = 0;
  UserRole? _lastRole;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.state,
      builder: (context, _) {
        final role = widget.state.currentUser.role;
        if (_lastRole != role) {
          _lastRole = role;
          _currentIndex = 0;
        }

        List<NavigationDestination> destinations;
        Widget contentWidget;

        if (role == UserRole.student) {
          destinations = const [
            NavigationDestination(
              icon: Icon(Icons.school_outlined),
              selectedIcon: Icon(Icons.school, color: AppColors.primary),
              label: 'My Attendance',
            ),
            NavigationDestination(
              icon: Icon(Icons.description_outlined),
              selectedIcon: Icon(Icons.description, color: AppColors.primary),
              label: 'Class Report',
            ),
            NavigationDestination(
              icon: Icon(Icons.settings_outlined),
              selectedIcon: Icon(Icons.settings, color: AppColors.primary),
              label: 'Settings',
            ),
          ];

          final safeIndex = _currentIndex.clamp(0, destinations.length - 1);
          if (safeIndex == 0) {
            contentWidget = StudentPortalScreen(state: widget.state);
          } else if (safeIndex == 1) {
            contentWidget = ReportScreen(state: widget.state);
          } else {
            contentWidget = _buildSettingsView();
          }
        } else if (role == UserRole.admin) {
          destinations = const [
            NavigationDestination(
              icon: Icon(Icons.admin_panel_settings_outlined),
              selectedIcon: Icon(Icons.admin_panel_settings, color: Color(0xFF8B5CF6)),
              label: 'Dashboard',
            ),
            NavigationDestination(
              icon: Icon(Icons.description_outlined),
              selectedIcon: Icon(Icons.description, color: Color(0xFF8B5CF6)),
              label: 'Class Report',
            ),
            NavigationDestination(
              icon: Icon(Icons.settings_outlined),
              selectedIcon: Icon(Icons.settings, color: Color(0xFF8B5CF6)),
              label: 'Settings',
            ),
          ];

          final safeIndex = _currentIndex.clamp(0, destinations.length - 1);
          if (safeIndex == 0) {
            contentWidget = AdminDashboardScreen(state: widget.state);
          } else if (safeIndex == 1) {
            contentWidget = ReportScreen(state: widget.state);
          } else {
            contentWidget = _buildSettingsView();
          }
        } else if (role == UserRole.staff) {
          destinations = const [
            NavigationDestination(
              icon: Icon(Icons.menu_book_outlined),
              selectedIcon: Icon(Icons.menu_book, color: Color(0xFF0D9488)),
              label: 'Lectures',
            ),
            NavigationDestination(
              icon: Icon(Icons.description_outlined),
              selectedIcon: Icon(Icons.description, color: Color(0xFF0D9488)),
              label: 'Reports',
            ),
            NavigationDestination(
              icon: Icon(Icons.settings_outlined),
              selectedIcon: Icon(Icons.settings, color: Color(0xFF0D9488)),
              label: 'Settings',
            ),
          ];

          final safeIndex = _currentIndex.clamp(0, destinations.length - 1);
          if (safeIndex == 0) {
            contentWidget = StaffDashboardScreen(state: widget.state);
          } else if (safeIndex == 1) {
            contentWidget = ReportScreen(state: widget.state);
          } else {
            contentWidget = _buildSettingsView();
          }
        } else if (role == UserRole.advisor) {
          destinations = const [
            NavigationDestination(
              icon: Icon(Icons.psychology_alt_outlined),
              selectedIcon: Icon(Icons.psychology_alt, color: Color(0xFF0284C7)),
              label: 'Advisor Portal',
            ),
            NavigationDestination(
              icon: Icon(Icons.checklist_rtl_outlined),
              selectedIcon: Icon(Icons.checklist_rtl, color: Color(0xFF0284C7)),
              label: 'Attendance Review',
            ),
            NavigationDestination(
              icon: Icon(Icons.description_outlined),
              selectedIcon: Icon(Icons.description, color: Color(0xFF0284C7)),
              label: 'Reports',
            ),
            NavigationDestination(
              icon: Icon(Icons.settings_outlined),
              selectedIcon: Icon(Icons.settings, color: Color(0xFF0284C7)),
              label: 'Settings',
            ),
          ];

          final safeIndex = _currentIndex.clamp(0, destinations.length - 1);
          if (safeIndex == 0) {
            contentWidget = AdvisorDashboardScreen(state: widget.state);
          } else if (safeIndex == 1) {
            contentWidget = MarkAttendanceScreen(state: widget.state);
          } else if (safeIndex == 2) {
            contentWidget = ReportScreen(state: widget.state);
          } else {
            contentWidget = _buildSettingsView();
          }
        } else {
          // CR & Assistant CR
          destinations = const [
            NavigationDestination(
              icon: Icon(Icons.home_outlined),
              selectedIcon: Icon(Icons.home, color: AppColors.primary),
              label: 'Home',
            ),
            NavigationDestination(
              icon: Icon(Icons.groups_outlined),
              selectedIcon: Icon(Icons.groups, color: AppColors.primary),
              label: 'Attendance',
            ),
            NavigationDestination(
              icon: Icon(Icons.description_outlined),
              selectedIcon: Icon(Icons.description, color: AppColors.primary),
              label: 'Reports',
            ),
            NavigationDestination(
              icon: Icon(Icons.settings_outlined),
              selectedIcon: Icon(Icons.settings, color: AppColors.primary),
              label: 'Settings',
            ),
          ];

          final safeIndex = _currentIndex.clamp(0, destinations.length - 1);
          if (safeIndex == 0) {
            contentWidget = CrHomeScreen(state: widget.state);
          } else if (safeIndex == 1) {
            contentWidget = MarkAttendanceScreen(state: widget.state);
          } else if (safeIndex == 2) {
            contentWidget = ReportScreen(state: widget.state);
          } else {
            contentWidget = _buildSettingsView();
          }
        }

        final activeIndex = _currentIndex.clamp(0, destinations.length - 1);

        return Scaffold(
          backgroundColor: AppColors.background,
          body: Column(
            children: [
              AppHeader(state: widget.state),
              Expanded(child: contentWidget),
            ],
          ),
          bottomNavigationBar: NavigationBar(
            selectedIndex: activeIndex,
            onDestinationSelected: (index) {
              setState(() {
                _currentIndex = index;
              });
            },
            backgroundColor: Colors.white,
            elevation: 3,
            indicatorColor: AppColors.primary.withOpacity(0.12),
            destinations: destinations,
          ),
          floatingActionButton: role == UserRole.student
              ? null
              : FloatingActionButton.extended(
                  onPressed: () => RoleSwitcherSheet.show(context, widget.state),
                  icon: const Icon(Icons.swap_horiz, color: Colors.white),
                  label: Text(
                    'Switch Role (${widget.state.currentUser.role.name.toUpperCase()})',
                    style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                  backgroundColor: AppColors.primary,
                ),
        );
      },
    );
  }

  Widget _buildSettingsView() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Settings & Configuration', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          Card(
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.person_outline, color: AppColors.primary),
                  title: Text(widget.state.currentUser.name),
                  subtitle: Text('${widget.state.currentUser.email} • ${widget.state.currentUser.roleDisplayName}'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => RoleSwitcherSheet.show(context, widget.state),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.wifi, color: AppColors.presentGreen),
                  title: const Text('Backend API Status'),
                  subtitle: Text(
                    widget.state.isOnline
                        ? 'Connected to Express Server (http://localhost:5000)'
                        : 'Offline Mode (Local Storage)',
                  ),
                  trailing: TextButton(
                    onPressed: () => widget.state.syncPendingRecords(),
                    child: const Text('Check Sync'),
                  ),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.cloud_upload_outlined, color: AppColors.warningYellow),
                  title: const Text('Offline Queue'),
                  subtitle: Text('${widget.state.pendingSyncCount} attendance records stored locally'),
                  trailing: widget.state.pendingSyncCount > 0
                      ? ElevatedButton(
                          onPressed: () => widget.state.syncPendingRecords(),
                          child: const Text('Sync Now'),
                        )
                      : const Text('All Synced ✓', style: TextStyle(color: AppColors.presentGreen, fontWeight: FontWeight.bold)),
                ),
                const Divider(height: 1),
                const ListTile(
                  leading: Icon(Icons.info_outline, color: AppColors.textSecondary),
                  title: Text('ClassCR Version'),
                  subtitle: Text('v1.0.0 (MCA 2026–2028 Edition)'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
