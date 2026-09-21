const { createClient } = require('@supabase/supabase-js');
const fs = require('fs');
const path = require('path');

// Load fallback local students in case tables are not yet created in Supabase
const fallbackStudentsPath = path.join(__dirname, 'data', 'students.json');
let fallbackStudents = [];
try {
  fallbackStudents = JSON.parse(fs.readFileSync(fallbackStudentsPath, 'utf8'));
} catch (e) {
  console.error('Could not read fallback students.json:', e.message);
}

const supabaseUrl = process.env.SUPABASE_URL || 'https://fbqafmahrhykcpojprrh.supabase.co';
const rawSecretKey = process.env.SUPABASE_SECRET_KEY || '';
const isMaskedSecret = rawSecretKey.includes('•') || rawSecretKey.includes('...');
const publishableKey = process.env.SUPABASE_PUBLISHABLE_KEY || 'sb_publishable_liuYHEmFdCr3uepuAF30IQ_ZLSH60wR';

// Prefer secret key if unmasked, otherwise use publishable key
const activeKey = (!isMaskedSecret && rawSecretKey.length > 10) ? rawSecretKey : publishableKey;

if (isMaskedSecret) {
  console.warn('⚠️  Notice: SUPABASE_SECRET_KEY contains masked bullet characters (••••). Using SUPABASE_PUBLISHABLE_KEY for requests.');
  console.warn('👉 To enable full service-role permissions, copy the unmasked Secret Key from your Supabase Dashboard: Settings -> API Keys into server/.env');
}

const supabase = createClient(supabaseUrl, activeKey, {
  auth: {
    persistSession: false,
    autoRefreshToken: false,
  }
});

const femaleRolls = new Set([
  5, 6, 10, 11, 12, 13, 15, 20, 21, 22, 24, 29, 32, 33, 35, 38, 41, 47, 48, 50, 51, 52,
  9, 19, 23, 28, 31, 34, 37, 42 // prior compatibility
]);

// Helper to map DB student row (snake_case) to client student (camelCase)
function mapStudent(row) {
  if (!row) return null;
  const roll = row.roll_no !== undefined ? row.roll_no : row.rollNo;
  const ccrCode = row.ccr_code || row.ccrCode || `CCR-${String(roll).padStart(4, '0')}`;
  return {
    rollNo: roll,
    enrollmentNo: row.enrollment_no !== undefined ? row.enrollment_no : row.enrollmentNo,
    name: row.name,
    dob: row.dob,
    gender: row.gender || (femaleRolls.has(roll) ? 'F' : 'M'),
    ccrCode: ccrCode,
    classId: row.class_id !== undefined ? row.class_id : (row.classId || 'I-MCA-A'),
    department: row.department || 'MCA'
  };
}

// Helper to map DB attendance record
function mapAttendance(row) {
  if (!row) return null;
  return {
    id: row.id,
    classId: row.class_id !== undefined ? row.class_id : (row.classId || 'I-MCA-A'),
    date: row.date,
    totalStudents: row.total_students !== undefined ? row.total_students : (row.totalStudents || 52),
    presentCount: row.present_count !== undefined ? row.present_count : (row.presentCount || 0),
    absentCount: row.absent_count !== undefined ? row.absent_count : (row.absentCount || 0),
    absentRolls: row.absent_rolls !== undefined ? (typeof row.absent_rolls === 'string' ? JSON.parse(row.absent_rolls) : row.absent_rolls) : (row.absentRolls || []),
    markedBy: row.marked_by !== undefined ? row.marked_by : (row.markedBy || 'cr'),
    markedByName: row.marked_by_name !== undefined ? row.marked_by_name : (row.markedByName || ''),
    markedByRole: row.marked_by_role !== undefined ? row.marked_by_role : (row.markedByRole || ''),
    isLocked: row.is_locked !== undefined ? Boolean(row.is_locked) : (row.isLocked !== undefined ? Boolean(row.isLocked) : true),
    lastModifiedBy: row.last_modified_by !== undefined ? row.last_modified_by : (row.lastModifiedBy || ''),
    status: row.status || 'submitted',
    submittedAt: row.submitted_at !== undefined ? row.submitted_at : (row.submittedAt || new Date().toISOString()),
    notes: row.notes || '',
    asstCrVerified: row.asst_cr_verified !== undefined ? Boolean(row.asst_cr_verified) : Boolean(row.asstCrVerified),
    asstCrVerifiedBy: row.asst_cr_verified_by !== undefined ? row.asst_cr_verified_by : (row.asstCrVerifiedBy || ''),
    asstCrVerifiedAt: row.asst_cr_verified_at !== undefined ? row.asst_cr_verified_at : (row.asstCrVerifiedAt || ''),
    periodNo: row.period_no !== undefined ? row.period_no : (row.periodNo || 1),
    periodSubject: row.period_subject !== undefined ? row.period_subject : (row.periodSubject || '')
  };
}

// Helper to map DB report
function mapReport(row) {
  if (!row) return null;
  return {
    id: row.id,
    classId: row.class_id !== undefined ? row.class_id : (row.classId || 'I-MCA-A'),
    date: row.date,
    totalStudents: row.total_students !== undefined ? row.total_students : (row.totalStudents || 52),
    presentCount: row.present_count !== undefined ? row.present_count : (row.presentCount || 0),
    absentCount: row.absent_count !== undefined ? row.absent_count : (row.absentCount || 0),
    absentStudents: row.absent_students !== undefined ? (typeof row.absent_students === 'string' ? JSON.parse(row.absent_students) : row.absent_students) : (row.absentStudents || []),
    submittedAt: row.submitted_at !== undefined ? row.submitted_at : (row.submittedAt || ''),
    status: row.status || 'sent',
    formattedText: row.formatted_text !== undefined ? row.formatted_text : (row.formattedText || '')
  };
}

// In-memory cache / fallback store for when Supabase tables are being initialized
const memoryStore = {
  attendanceRecords: [
    {
      id: 'att_20260914',
      classId: 'I-MCA-A',
      date: '2026-09-14',
      totalStudents: 52,
      presentCount: 47,
      absentCount: 5,
      absentRolls: [8, 17, 24, 38, 49],
      markedBy: 'user_cr_1',
      status: 'submitted',
      submittedAt: '2026-09-14T09:12:00Z',
      notes: 'Regular lecture day. 5 absent with prior notice.'
    },
    {
      id: 'att_20260915',
      classId: 'I-MCA-A',
      date: '2026-09-15',
      totalStudents: 52,
      presentCount: 50,
      absentCount: 2,
      absentRolls: [13, 44],
      markedBy: 'user_cr_1',
      status: 'submitted',
      submittedAt: '2026-09-15T09:15:00Z',
      notes: 'Lab session conducted.'
    },
    {
      id: 'att_20260916',
      classId: 'I-MCA-A',
      date: '2026-09-16',
      totalStudents: 52,
      presentCount: 45,
      absentCount: 7,
      absentRolls: [2, 11, 21, 28, 33, 40, 51],
      markedBy: 'user_cr_1',
      status: 'submitted',
      submittedAt: '2026-09-16T09:20:00Z',
      notes: 'Campus placement orientation overlap.'
    },
    {
      id: 'att_20260917',
      classId: 'I-MCA-A',
      date: '2026-09-17',
      totalStudents: 52,
      presentCount: 48,
      absentCount: 4,
      absentRolls: [6, 18, 26, 35],
      markedBy: 'user_cr_1',
      status: 'submitted',
      submittedAt: '2026-09-17T09:10:00Z',
      notes: 'Full day classes.'
    },
    {
      id: `att_${new Date().toISOString().split('T')[0].replace(/-/g, '')}`,
      classId: 'I-MCA-A',
      date: new Date().toISOString().split('T')[0],
      totalStudents: 52,
      presentCount: 43,
      absentCount: 9,
      absentRolls: [13, 25, 27, 28, 31, 34, 37, 44, 52],
      markedBy: 'user_cr_1',
      markedByName: 'MUTHUVEL R',
      markedByRole: 'CR',
      isLocked: true,
      lastModifiedBy: '',
      status: 'submitted',
      submittedAt: '09:18 AM',
      notes: 'Morning session attendance verified and submitted to advisor.'
    }
  ],
  reports: [
    {
      id: `rep_${new Date().toISOString().split('T')[0].replace(/-/g, '')}`,
      classId: 'I-MCA-A',
      date: `${String(new Date().getDate()).padStart(2, '0')}/${String(new Date().getMonth() + 1).padStart(2, '0')}/${new Date().getFullYear()}`,
      totalStudents: 52,
      presentCount: 43,
      absentCount: 9,
      absentStudents: [
        { rollNo: 13, name: 'DHIVYALAKSHMI H', enrollmentNo: '260311' },
        { rollNo: 25, name: 'LOKESH V', enrollmentNo: '260364' },
        { rollNo: 27, name: 'MAHESH KUMAR R', enrollmentNo: '260367' },
        { rollNo: 28, name: 'MANIKANDAN D', enrollmentNo: '260345' },
        { rollNo: 31, name: 'MUTHUVEL R', enrollmentNo: '260320' },
        { rollNo: 34, name: 'NETHAJI V', enrollmentNo: '260333' },
        { rollNo: 37, name: 'PRITHEEVIRAJ S', enrollmentNo: '260405' },
        { rollNo: 44, name: 'SATHYA P', enrollmentNo: '260368' },
        { rollNo: 52, name: 'TASFIYA FARVIN S', enrollmentNo: '260738' }
      ],
      submittedAt: '09:18 AM',
      status: 'sent'
    }
  ]
};

// Database Operations
const db = {
  // Fetch students from Supabase
  async getStudents(classId) {
    try {
      let query = supabase.from('students').select('*').order('roll_no', { ascending: true });
      if (classId) {
        query = query.eq('class_id', classId);
      }
      const { data, error } = await query;
      if (error || !data || data.length === 0) {
        // Fallback to local 52 MCA students
        return fallbackStudents.filter(s => !classId || s.classId === classId);
      }
      return data.map(mapStudent);
    } catch (err) {
      console.warn('Supabase fetch students failed, using fallback:', err.message);
      return fallbackStudents.filter(s => !classId || s.classId === classId);
    }
  },

  // Fetch single student by rollNo
  async getStudentByRoll(rollNo) {
    try {
      const { data, error } = await supabase
        .from('students')
        .select('*')
        .eq('roll_no', rollNo)
        .maybeSingle();

      if (!error && data) {
        return mapStudent(data);
      }
    } catch (_) {}
    return fallbackStudents.find(s => s.rollNo === parseInt(rollNo, 10)) || null;
  },

  // Fetch student by enrollment number or roll
  async getStudentByIdentifier(id) {
    try {
      const { data, error } = await supabase
        .from('students')
        .select('*')
        .or(`enrollment_no.eq.${id},roll_no.eq.${isNaN(id) ? -1 : parseInt(id, 10)}`)
        .maybeSingle();

      if (!error && data) {
        return mapStudent(data);
      }
    } catch (_) {}
    return fallbackStudents.find(s => s.enrollmentNo === id || String(s.rollNo) === id) || null;
  },

  // Fetch classes from Supabase
  async getClasses() {
    try {
      const { data, error } = await supabase.from('classes').select('*');
      if (!error && data && data.length > 0) {
        return data.map(c => ({
          id: c.id,
          name: c.name,
          batch: c.batch,
          department: c.department,
          totalStudents: c.total_students,
          advisorName: c.advisor_name,
          crName: c.cr_name
        }));
      }
    } catch (_) {}
    return [
      { id: 'I-MCA-A', name: 'I MCA A', batch: '2026–2028', department: 'MCA', totalStudents: 52, advisorName: 'Dr. K. Senthil Nathan', crName: 'MUTHUVEL R' },
      { id: 'I-MCA-B', name: 'I MCA B', batch: '2026–2028', department: 'MCA', totalStudents: 48, advisorName: 'Prof. R. Priya', crName: 'K. Karthik' },
      { id: 'II-MCA', name: 'II MCA', batch: '2025–2027', department: 'MCA', totalStudents: 50, advisorName: 'Dr. M. Ramanathan', crName: 'V. Anand' },
      { id: 'I-BCA', name: 'I BCA', batch: '2026–2029', department: 'BCA', totalStudents: 55, advisorName: 'Prof. S. Meena', crName: 'R. Rajesh' }
    ];
  },

  // Fetch attendance history
  async getAttendanceHistory(classId = 'I-MCA-A') {
    try {
      const { data, error } = await supabase
        .from('attendance_records')
        .select('*')
        .eq('class_id', classId)
        .order('date', { ascending: false });

      if (!error && data && data.length > 0) {
        return data.map(mapAttendance);
      }
    } catch (_) {}
    return memoryStore.attendanceRecords.filter(r => r.classId === classId);
  },

  // Fetch attendance by specific date
  async getAttendanceByDate(classId = 'I-MCA-A', date) {
    const memRecord = memoryStore.attendanceRecords.find(r => r.classId === classId && r.date === date) || null;
    try {
      const { data, error } = await supabase
        .from('attendance_records')
        .select('*')
        .eq('class_id', classId)
        .eq('date', date)
        .maybeSingle();

      if (!error && data) {
        const mapped = mapAttendance(data);
        if (memRecord) {
          mapped.markedByName = mapped.markedByName || memRecord.markedByName;
          mapped.markedByRole = mapped.markedByRole || memRecord.markedByRole;
          mapped.lastModifiedBy = mapped.lastModifiedBy || memRecord.lastModifiedBy;
        }
        return mapped;
      }
    } catch (_) {}
    return memRecord;
  },

  // Save or update attendance record
  async saveAttendanceRecord(record) {
    // 1. Update memory store
    const existingIdx = memoryStore.attendanceRecords.findIndex(r => r.date === record.date && r.classId === record.classId);
    if (existingIdx >= 0) {
      memoryStore.attendanceRecords[existingIdx] = record;
    } else {
      memoryStore.attendanceRecords.unshift(record);
    }

    // 2. Persist to Supabase
    try {
      const dbRow = {
        id: record.id,
        class_id: record.classId,
        date: record.date,
        total_students: record.totalStudents,
        present_count: record.presentCount,
        absent_count: record.absentCount,
        absent_rolls: record.absentRolls,
        marked_by: record.markedBy,
        marked_by_name: record.markedByName || '',
        marked_by_role: record.markedByRole || '',
        is_locked: record.isLocked !== undefined ? Boolean(record.isLocked) : true,
        last_modified_by: record.lastModifiedBy || '',
        status: record.status || 'submitted',
        submitted_at: record.submittedAt || new Date().toISOString(),
        notes: record.notes || '',
        asst_cr_verified: record.asstCrVerified !== undefined ? Boolean(record.asstCrVerified) : false,
        asst_cr_verified_by: record.asstCrVerifiedBy || '',
        asst_cr_verified_at: record.asstCrVerifiedAt || '',
        period_no: record.periodNo || 1,
        period_subject: record.periodSubject || ''
      };
      let { error } = await supabase.from('attendance_records').upsert(dbRow, { onConflict: 'class_id,date' });
      if (error && error.message && error.message.includes('column')) {
        // Fallback for older database schema without added audit columns
        const coreRow = {
          id: record.id,
          class_id: record.classId,
          date: record.date,
          total_students: record.totalStudents,
          present_count: record.presentCount,
          absent_count: record.absentCount,
          absent_rolls: record.absentRolls,
          marked_by: record.markedBy,
          status: record.status || 'submitted',
          submitted_at: record.submittedAt || new Date().toISOString(),
          notes: record.notes || ''
        };
        const res = await supabase.from('attendance_records').upsert(coreRow, { onConflict: 'class_id,date' });
        error = res.error;
      }
      if (error) {
        console.warn('Supabase upsert attendance notice:', error.message);
      } else {
        console.log(`✅ Supabase saved attendance record for ${record.date} (${record.classId})`);
      }
    } catch (err) {
      console.warn('Supabase save attendance error:', err.message);
    }
    return record;
  },

  // Fetch reports
  async getReports(classId = 'I-MCA-A') {
    try {
      let query = supabase.from('reports').select('*').order('created_at', { ascending: false });
      if (classId) {
        query = query.eq('class_id', classId);
      }
      const { data, error } = await query;
      if (!error && data && data.length > 0) {
        return data.map(mapReport);
      }
    } catch (_) {}
    return memoryStore.reports.filter(r => !classId || r.classId === classId);
  },

  // Save report
  async saveReport(report) {
    // 1. Update memory store
    memoryStore.reports = memoryStore.reports.filter(r => r.date !== report.date);
    memoryStore.reports.unshift(report);

    // 2. Persist to Supabase
    try {
      const dbRow = {
        id: report.id,
        class_id: report.classId,
        date: report.date,
        total_students: report.totalStudents,
        present_count: report.presentCount,
        absent_count: report.absentCount,
        absent_students: report.absentStudents,
        submitted_at: report.submittedAt,
        status: report.status || 'sent',
        formatted_text: report.formattedText || ''
      };
      await supabase.from('reports').upsert(dbRow, { onConflict: 'id' });
    } catch (err) {
      console.warn('Supabase save report notice:', err.message);
    }
    return report;
  },

  // Find user by email
  async getUserByEmail(email) {
    try {
      const { data, error } = await supabase
        .from('app_users')
        .select('*')
        .eq('email', email)
        .maybeSingle();

      if (!error && data) {
        return {
          id: data.id,
          name: data.name,
          email: data.email,
          password: data.password,
          role: data.role,
          collegeId: data.college_id,
          departmentId: data.department_id,
          classId: data.class_id,
          studentId: data.student_id
        };
      }
    } catch (_) {}

    const seedUsers = [
      { id: 'user_cr_1', name: 'MUTHUVEL R (CR)', email: 'cr@classcr.edu', password: 'password123', role: 'cr', collegeId: 'COL-001', departmentId: 'MCA', classId: 'I-MCA-A', studentId: '260320' },
      { id: 'user_adv_1', name: 'Prof. Nandhini G (Navi Ma\'am)', email: 'advisor@classcr.edu', password: 'password123', role: 'advisor', collegeId: 'COL-001', departmentId: 'MCA', classId: 'I-MCA-A' },
      { id: 'user_stu_1', name: 'DHIVYALAKSHMI H', email: 'student@classcr.edu', password: 'password123', role: 'student', collegeId: 'COL-001', departmentId: 'MCA', classId: 'I-MCA-A', studentId: '260311' },
      { id: 'user_adm_1', name: 'College Dean / Administrator', email: 'admin@classcr.edu', password: 'password123', role: 'admin', collegeId: 'COL-001' }
    ];
    return seedUsers.find(u => u.email === email) || null;
  },

  // Official MCA Department Faculty List (Manakula Vinayagar Institute of Technology)
  facultyList: [
    { name: 'Mrs. V. Nandhini, AP/CA', designation: 'Assistant Professor / CA', department: 'MCA', role: 'Class Advisor', subject: 'Object oriented Programming in C++ (OOPS) & Lab', code: '25PMCT12 / 25PMCP11', hallNo: '408', hours: 11 },
    { name: 'Dr. S. Sivaramakrishnan, Prof/Maths', designation: 'Professor / Maths', department: 'Mathematics', role: 'Faculty', subject: 'Mathematical Foundation of Computer Applications (MAT)', code: '25PMCT11', hallNo: '408', hours: 8 },
    { name: 'Mrs. K. Shivashankari, AP/CA', designation: 'Assistant Professor / CA', department: 'MCA', role: 'Faculty', subject: 'Database Technology (DT) & Lab', code: '25PMCT13 / 25PMCP12', hallNo: '408', hours: 11 },
    { name: 'Ms. M. Tamilmani, AP/CA', designation: 'Assistant Professor / CA', department: 'MCA', role: 'Faculty', subject: 'Operating Systems (OS) & Lab', code: '25PMCT14 / 25PMCP13', hallNo: '408', hours: 11 },
    { name: 'Ms. V. Deepa, AP/CA', designation: 'Assistant Professor / CA', department: 'MCA', role: 'Faculty', subject: 'Software Engineering (SE)', code: '25PMCT15', hallNo: '408', hours: 6 }
  ],

  async getFaculty(department = 'MCA') {
    return this.facultyList.filter(f => !department || f.department === department);
  },

  // Delegation Store & Role Passcodes
  delegations: {
    'I-MCA-A': {
      classId: 'I-MCA-A',
      advisorName: 'Mrs. V. Nandhini, AP/CA',
      advisorCode: 'NAVI2026',
      crRoll: 31,
      crName: 'MUTHUVEL R',
      crCode: 'CR2026',
      maleAsstRoll: 45,
      maleAsstName: 'SHOVIN MICHEL DAVID',
      maleAsstCode: 'ACR2026',
      femaleAsstRoll: 13,
      femaleAsstName: 'DHIVYALAKSHMI H',
      femaleAsstCode: 'ACR2026',
      studentCode: 'STU2026'
    }
  },

  async getDelegation(classId = 'I-MCA-A') {
    if (!this.delegations[classId]) {
      this.delegations[classId] = {
        classId,
        advisorName: 'Mrs. V. Nandhini, AP/CA',
        advisorCode: 'NAVI2026',
        crRoll: 31,
        crName: 'MUTHUVEL R',
        crCode: 'CR2026',
        maleAsstRoll: 45,
        maleAsstName: 'SHOVIN MICHEL DAVID',
        maleAsstCode: 'ACR2026',
        femaleAsstRoll: 13,
        femaleAsstName: 'DHIVYALAKSHMI H',
        femaleAsstCode: 'ACR2026',
        studentCode: 'STU2026'
      };
    }
    return this.delegations[classId];
  },

  async adminAssignAdvisor({ classId = 'I-MCA-A', advisorName, advisorCode }) {
    const cur = await this.getDelegation(classId);
    if (advisorName) cur.advisorName = advisorName;
    if (advisorCode) cur.advisorCode = advisorCode.toUpperCase();
    this.delegations[classId] = cur;

    // Persist to Supabase classes table
    try {
      await supabase.from('classes').update({ advisor_name: cur.advisorName }).eq('id', classId);
    } catch (_) {}

    return cur;
  },

  async advisorDelegate({
    classId = 'I-MCA-A',
    crRoll,
    crName,
    crCode,
    maleAsstRoll,
    maleAsstName,
    maleAsstCode,
    femaleAsstRoll,
    femaleAsstName,
    femaleAsstCode,
    studentCode
  }) {
    const cur = await this.getDelegation(classId);
    if (crRoll) cur.crRoll = crRoll;
    if (crName) cur.crName = crName;
    if (crCode) cur.crCode = crCode.toUpperCase();
    if (maleAsstRoll) cur.maleAsstRoll = maleAsstRoll;
    if (maleAsstName) cur.maleAsstName = maleAsstName;
    if (maleAsstCode) cur.maleAsstCode = maleAsstCode.toUpperCase();
    if (femaleAsstRoll) cur.femaleAsstRoll = femaleAsstRoll;
    if (femaleAsstName) cur.femaleAsstName = femaleAsstName;
    if (femaleAsstCode) cur.femaleAsstCode = femaleAsstCode.toUpperCase();
    if (studentCode) cur.studentCode = studentCode.toUpperCase();

    this.delegations[classId] = cur;

    // Persist CR to classes table
    try {
      if (cur.crName) {
        await supabase.from('classes').update({ cr_name: cur.crName }).eq('id', classId);
      }
    } catch (_) {}

    return cur;
  },

  async verifyPasscode({ classId = 'I-MCA-A', role, code, gender, rollNo }) {
    const del = await this.getDelegation(classId);
    const entered = (code || '').trim().toUpperCase();

    if (role === 'admin') {
      const match = entered === 'ADMIN2026' || entered === 'ADM2026' || entered === 'HOD2026';
      if (match) {
        return {
          valid: true,
          name: 'Head of Department (HOD)',
          role: 'admin',
          classId
        };
      }
    } else if (role === 'advisor') {
      const match = entered === del.advisorCode || entered === 'ADV2026' || entered === 'NAVI2026';
      if (match) {
        return {
          valid: true,
          name: del.advisorName,
          role: 'advisor',
          classId
        };
      }
    } else if (role === 'staff') {
      const match = entered === 'STAFF2026' || entered === 'ADV2026' || entered === 'NAVI2026' || entered === 'TEACH2026';
      if (match) {
        return {
          valid: true,
          name: 'Subject Teacher / Faculty',
          role: 'staff',
          classId
        };
      }
    } else if (role === 'cr') {
      const match = entered === del.crCode || entered === 'CR2026';
      if (match) {
        return {
          valid: true,
          name: del.crName,
          role: 'cr',
          classId,
          rollNo: del.crRoll,
          gender: 'M'
        };
      }
    } else if (role === 'assistantCr') {
      const matchMale = entered === del.maleAsstCode || entered === 'ACR2026' || entered === 'MACR2026';
      const matchFemale = entered === del.femaleAsstCode || entered === 'ACR2026' || entered === 'FACR2026';

      if (gender === 'F' || (matchFemale && !matchMale)) {
        if (matchFemale || entered === 'ACR2026') {
          return {
            valid: true,
            name: del.femaleAsstName,
            role: 'assistantCr',
            classId,
            rollNo: del.femaleAsstRoll,
            gender: 'F'
          };
        }
      } else if (matchMale || matchFemale) {
        return {
          valid: true,
          name: (gender === 'F') ? del.femaleAsstName : del.maleAsstName,
          role: 'assistantCr',
          classId,
          rollNo: (gender === 'F') ? del.femaleAsstRoll : del.maleAsstRoll,
          gender: gender || 'M'
        };
      }
    } else if (role === 'student') {
      const isClassCode = entered === del.studentCode || entered === 'STU2026' || entered === '123456';

      let matched = null;
      if (rollNo) {
        matched = fallbackStudents.find(s => s.rollNo === Number(rollNo));
      }

      const isCcrMatch = matched && (
        entered === (matched.ccrCode || '').toUpperCase() ||
        entered === `CCR-${String(matched.rollNo).padStart(4, '0')}`
      );

      if (!matched && entered.startsWith('CCR-')) {
        matched = fallbackStudents.find(s =>
          (s.ccrCode || '').toUpperCase() === entered ||
          `CCR-${String(s.rollNo).padStart(4, '0')}` === entered
        );
      }

      if (isClassCode || isCcrMatch || (matched && entered.startsWith('CCR-'))) {
        return {
          valid: true,
          role: 'student',
          name: matched ? matched.name : 'Student',
          rollNo: matched ? matched.rollNo : rollNo,
          enrollmentNo: matched ? matched.enrollmentNo : null,
          gender: matched ? matched.gender : (gender || 'M'),
          ccrCode: matched ? matched.ccrCode : entered,
          classId
        };
      }
    }

    return { valid: false, error: 'Invalid verification passcode for this role' };
  }
};

module.exports = {
  supabase,
  db,
  mapStudent,
  mapAttendance,
  mapReport
};
