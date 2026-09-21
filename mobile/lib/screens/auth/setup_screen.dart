import 'package:flutter/material.dart';
import '../../core/theme.dart';
import '../../models/models.dart';
import '../../providers/classcr_state.dart';
import '../main_shell.dart';

class SetupScreen extends StatefulWidget {
  final ClassCRState state;

  const SetupScreen({super.key, required this.state});

  @override
  State<SetupScreen> createState() => _SetupScreenState();
}

class _SetupScreenState extends State<SetupScreen> {
  // Step 1: Class Selection
  String _selectedDept = 'MCA';
  String _selectedClass = 'I MCA';
  String _selectedSection = 'Section A';

  // Step 2: Role Selection
  UserRole _selectedRole = UserRole.cr;

  // Step 3: Student / Advisor Selection
  Student? _selectedStudent;
  late final TextEditingController _advisorNameController;
  final TextEditingController _searchStudentController = TextEditingController();
  final TextEditingController _codeController = TextEditingController();

  String _errorMessage = '';
  bool _isVerifying = false;
  bool _obscurePasscode = true;

  @override
  void initState() {
    super.initState();
    _advisorNameController = TextEditingController(text: widget.state.delegation.advisorName);
    // No default selection: student must explicitly choose their name
    _selectedStudent = null;
  }

  @override
  void dispose() {
    _advisorNameController.dispose();
    _searchStudentController.dispose();
    _codeController.dispose();
    super.dispose();
  }

  void _verifyAndProceed() async {
    setState(() {
      _errorMessage = '';
      _isVerifying = true;
    });

    final enteredCode = _codeController.text.trim().toUpperCase();

    if (enteredCode.isEmpty) {
      setState(() {
        _errorMessage = 'Please enter your ClassCR code or authorized passcode';
        _isVerifying = false;
      });
      return;
    }

    // 1. Universal code verification (auto-detect role, student identity, staff, advisor, HOD)
    final universal = widget.state.verifyAnyCode(enteredCode);
    if (universal['valid'] == true) {
      final role = universal['role'] as UserRole;
      final name = universal['name'] as String;
      final studentId = universal['studentId'] as String?;
      final gender = universal['gender'] as String?;
      final classId = universal['classId'] as String? ?? 'I-MCA-A';

      await widget.state.completeSetup(
        role: role,
        name: name,
        classId: classId,
        studentId: studentId,
        gender: gender,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: AppColors.presentGreen,
            content: Text('Verified as ${_getRoleTitle(role)}! Welcome $name.'),
          ),
        );

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => MainShell(state: widget.state)),
        );
      }
      return;
    }

    // 2. Fallback to manual role verification
    final studentGender = _selectedStudent != null ? (_selectedStudent!.isFemale ? 'F' : 'M') : null;

    final verification = await widget.state.verifyRolePasscode(
      classId: 'I-MCA-A',
      role: _selectedRole,
      code: enteredCode,
      gender: studentGender,
      rollNo: _selectedStudent?.rollNo,
    );

    if (verification['valid'] != true) {
      setState(() {
        _errorMessage = verification['error']?.toString() ??
            'Invalid passcode for ${_getRoleTitle(_selectedRole)}. Please verify with your Class Advisor or HOD.';
        _isVerifying = false;
      });
      return;
    }

    // If individual student matched via ClassCR code, auto-select if not yet selected
    if (_selectedRole == UserRole.student && _selectedStudent == null && verification['rollNo'] != null) {
      final matchedRoll = verification['rollNo'] as int;
      _selectedStudent = widget.state.students.cast<Student?>().firstWhere(
            (s) => s?.rollNo == matchedRoll,
            orElse: () => null,
          );
    }

    String userName = '';
    String? studentId;

    if (_selectedRole == UserRole.advisor) {
      userName = verification['name']?.toString() ?? _advisorNameController.text.trim();
      if (userName.isEmpty) userName = 'Mrs. V. Nandhini, AP/CA';
    } else if (_selectedRole == UserRole.staff) {
      userName = verification['name']?.toString() ?? 'Ms. M. Tamilmani, AP/CA';
    } else if (_selectedRole == UserRole.admin) {
      userName = verification['name']?.toString() ?? 'Head of Department (HOD)';
    } else {
      if (_selectedStudent == null) {
        setState(() {
          _errorMessage = 'Please select a student from the class roster';
          _isVerifying = false;
        });
        return;
      }
      final roleSuffix = _selectedRole == UserRole.cr
          ? ' (CR)'
          : (_selectedRole == UserRole.assistantCr ? ' (Asst. CR)' : '');
      userName = '${_selectedStudent!.name}$roleSuffix';
      studentId = _selectedStudent!.enrollmentNo;
    }

    final classId = '$_selectedClass-$_selectedSection';
    final userGender = studentGender ?? 'M';

    await widget.state.completeSetup(
      role: _selectedRole,
      name: userName,
      classId: classId,
      studentId: studentId,
      gender: userGender,
    );

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: AppColors.presentGreen,
          content: Text('Verified as ${_getRoleTitle(_selectedRole)}! Welcome $userName.'),
        ),
      );

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => MainShell(state: widget.state)),
      );
    }
  }

  String _getRoleTitle(UserRole role) {
    switch (role) {
      case UserRole.cr:
        return 'Class Representative (CR)';
      case UserRole.assistantCr:
        return 'Assistant CR (Asst. CR)';
      case UserRole.advisor:
        return 'Class Advisor';
      case UserRole.staff:
        return 'Subject Teacher / Faculty';
      case UserRole.student:
        return 'Student';
      case UserRole.admin:
        return 'HOD';
    }
  }

  @override
  Widget build(BuildContext context) {
    final students = widget.state.students;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFD),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header with logo
              Center(
                child: Column(
                  children: [
                    Container(
                      width: 64,
                      height: 64,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primary.withValues(alpha: 0.2),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: Image.asset('assets/images/logo.png', fit: BoxFit.cover),
                      ),
                    ),
                    const SizedBox(height: 10),
                    const Text(
                      'Welcome to ClassCR',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                        color: AppColors.deepBlue,
                      ),
                    ),
                    const SizedBox(height: 2),
                    const Text(
                      'Set up your class & role to get started',
                      style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // STEP 1: CLASS & SECTION SELECTION
              _buildSectionHeader('1', 'Select Class & Section'),
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.cardBorder),
                ),
                child: Column(
                  children: [
                    _buildDropdown(
                      label: 'Department',
                      value: _selectedDept,
                      items: ['MCA', 'BCA', 'B.Sc CS', 'Other Departments'],
                      onChanged: (val) => setState(() => _selectedDept = val!),
                    ),
                    const SizedBox(height: 12),
                    _buildDropdown(
                      label: 'Class / Year',
                      value: _selectedClass,
                      items: ['I MCA', 'II MCA'],
                      onChanged: (val) => setState(() => _selectedClass = val!),
                    ),
                    const SizedBox(height: 12),
                    _buildDropdown(
                      label: 'Section',
                      value: _selectedSection,
                      items: ['Section A', 'Section B'],
                      onChanged: (val) => setState(() => _selectedSection = val!),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // STEP 2: ROLE SELECTION (CR, Asst. CR, Advisor, Student, Admin)
              _buildSectionHeader('2', 'Select Your Role'),
              const SizedBox(height: 10),
              Row(
                children: [
                  _buildRoleCard(
                    role: UserRole.cr,
                    title: 'CR',
                    subtitle: 'Class Rep',
                    icon: Icons.badge_outlined,
                  ),
                  const SizedBox(width: 8),
                  _buildRoleCard(
                    role: UserRole.assistantCr,
                    title: 'Asst. CR',
                    subtitle: 'Equal Access',
                    icon: Icons.assignment_ind_outlined,
                  ),
                  const SizedBox(width: 8),
                  _buildRoleCard(
                    role: UserRole.advisor,
                    title: 'Advisor',
                    subtitle: 'Staff Portal',
                    icon: Icons.psychology_alt_outlined,
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  _buildRoleCard(
                    role: UserRole.student,
                    title: 'Student',
                    subtitle: 'Attendance View',
                    icon: Icons.school_outlined,
                  ),
                  const SizedBox(width: 8),
                  _buildRoleCard(
                    role: UserRole.admin,
                    title: 'HOD',
                    subtitle: 'Dept Head',
                    icon: Icons.admin_panel_settings_outlined,
                  ),
                ],
              ),

              const SizedBox(height: 20),

              // STEP 3: IDENTIFY PERSON IN CLASS
              _buildSectionHeader(
                '3',
                _selectedRole == UserRole.advisor
                    ? 'Advisor Details'
                    : (_selectedRole == UserRole.admin
                        ? 'HOD Verification'
                        : 'Verify Student from Roster'),
              ),
              const SizedBox(height: 10),

              if (_selectedRole == UserRole.admin) ...[
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.cardBorder),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.shield, color: AppColors.primary, size: 28),
                      SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Head of Department (HOD).\nAcademic and department oversight over curriculum, classes, and faculty advisors.',
                          style: TextStyle(fontSize: 12, color: AppColors.textPrimary, fontWeight: FontWeight.w500),
                        ),
                      ),
                    ],
                  ),
                ),
              ] else if (_selectedRole == UserRole.advisor) ...[
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.cardBorder),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      TextField(
                        controller: _advisorNameController,
                        decoration: const InputDecoration(
                          labelText: 'Advisor Full Name',
                          prefixIcon: Icon(Icons.person, color: AppColors.primary),
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Assigned Class: I MCA A • Batch 2026–2028',
                        style: TextStyle(fontSize: 12, color: AppColors.textSecondary, fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                ),
              ] else ...[
                // Student Picker from 52 students list
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.cardBorder),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Select student from I MCA (52 students):',
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.textSecondary),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF1F5F9),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<Student>(
                            isExpanded: true,
                            value: (_selectedStudent != null &&
                                    students.any((s) => s.rollNo == _selectedStudent!.rollNo))
                                ? students.firstWhere((s) => s.rollNo == _selectedStudent!.rollNo)
                                : null,
                            hint: const Text(
                              '-- Tap to choose your name from roster --',
                              style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
                            ),
                            items: students.map((st) {
                              return DropdownMenuItem<Student>(
                                value: st,
                                child: Text(
                                  '#${st.rollNo.toString().padLeft(2, '0')} ${st.name} (${st.enrollmentNo})',
                                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                                ),
                              );
                            }).toList(),
                            onChanged: (st) => setState(() => _selectedStudent = st),
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      if (_selectedStudent != null) ...[
                        Row(
                          children: [
                            const Icon(Icons.check_circle, color: AppColors.presentGreen, size: 16),
                            const SizedBox(width: 6),
                            Text(
                              'Verified in I MCA Batch 2026–28 roster (${_selectedStudent!.isFemale ? "Girl" : "Boy"})',
                              style: const TextStyle(fontSize: 12, color: AppColors.presentGreen, fontWeight: FontWeight.w600),
                            ),
                          ],
                        ),
                        if (_selectedRole == UserRole.assistantCr) ...[
                          const SizedBox(height: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                            decoration: BoxDecoration(
                              color: _selectedStudent!.isFemale ? const Color(0xFFFDF2F8) : const Color(0xFFF0F9FF),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: _selectedStudent!.isFemale ? const Color(0xFFF472B6) : const Color(0xFF38BDF8),
                              ),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  _selectedStudent!.isFemale ? Icons.female : Icons.male,
                                  color: _selectedStudent!.isFemale ? const Color(0xFFDB2777) : const Color(0xFF0284C7),
                                  size: 18,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    'Assigned: Assistant CR (Section Coordinator)',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                      color: _selectedStudent!.isFemale ? const Color(0xFFBE185D) : const Color(0xFF0369A1),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ],
                  ),
                ),
              ],

              const SizedBox(height: 20),

              // STEP 4: OFFLINE VERIFICATION CODE
              _buildSectionHeader('4', 'Enter Official Passcode'),
              const SizedBox(height: 10),

              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.cardBorder),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextField(
                      controller: _codeController,
                      textCapitalization: TextCapitalization.characters,
                      obscureText: _selectedRole == UserRole.student ? false : _obscurePasscode,
                      decoration: InputDecoration(
                        labelText: _selectedRole == UserRole.student
                            ? 'ClassCR Code (e.g. CCR-0001 or STU2026)'
                            : 'Passcode for ${_getRoleTitle(_selectedRole)}',
                        hintText: _selectedRole == UserRole.student
                            ? 'Enter individual CCR code (e.g. CCR-0001)'
                            : 'Enter authorized passcode',
                        prefixIcon: const Icon(Icons.lock_outline, color: AppColors.primary),
                        suffixIcon: _selectedRole == UserRole.student
                            ? null
                            : IconButton(
                                icon: Icon(
                                  _obscurePasscode ? Icons.visibility_off : Icons.visibility,
                                  color: AppColors.textSecondary,
                                  size: 20,
                                ),
                                onPressed: () {
                                  setState(() {
                                    _obscurePasscode = !_obscurePasscode;
                                  });
                                },
                              ),
                        border: const OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        const Icon(Icons.security, size: 14, color: AppColors.textSecondary),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            _selectedRole == UserRole.student
                                ? 'Use your assigned ClassCR code (e.g. CCR-0001 to CCR-0052) or class code'
                                : 'Authorized code required to activate ${_getRoleTitle(_selectedRole)}',
                            style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                          ),
                        ),
                      ],
                    ),

                    if (_errorMessage.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFEF2F2),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: const Color(0xFFFCA5A5)),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.error_outline, color: AppColors.absentRed, size: 18),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                _errorMessage,
                                style: const TextStyle(fontSize: 12, color: AppColors.absentRed, fontWeight: FontWeight.bold),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // SUBMIT & ENTER APP BUTTON (Thumb-friendly mobile button)
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _isVerifying ? null : _verifyAndProceed,
                  icon: _isVerifying
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : const Icon(Icons.arrow_forward),
                  label: Text(
                    _isVerifying ? 'Verifying...' : 'Verify & Launch ClassCR',
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                ),
              ),

              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String step, String title) {
    return Row(
      children: [
        CircleAvatar(
          radius: 12,
          backgroundColor: AppColors.primary,
          child: Text(
            step,
            style: const TextStyle(fontSize: 12, color: Colors.white, fontWeight: FontWeight.bold),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
        ),
      ],
    );
  }

  Widget _buildRoleCard({
    required UserRole role,
    required String title,
    required String subtitle,
    required IconData icon,
  }) {
    final isSelected = _selectedRole == role;

    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            _selectedRole = role;
            _codeController.clear(); // HIDE CODE: Never prefill with secret passcode!
            _errorMessage = '';
            _selectedStudent = null; // No default student: must be explicitly chosen from roster
          });
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.primary : Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: isSelected ? AppColors.primary : AppColors.cardBorder,
              width: isSelected ? 2 : 1,
            ),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.25),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ]
                : null,
          ),
          child: Column(
            children: [
              Icon(icon, color: isSelected ? Colors.white : AppColors.primary, size: 24),
              const SizedBox(height: 6),
              Text(
                title,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: isSelected ? Colors.white : AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 10,
                  color: isSelected ? Colors.white70 : AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDropdown({
    required String label,
    required String value,
    required List<String> items,
    required ValueChanged<String?> onChanged,
  }) {
    return Row(
      children: [
        SizedBox(
          width: 90,
          child: Text(
            label,
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textSecondary),
          ),
        ),
        Expanded(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
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
