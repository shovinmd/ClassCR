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

// In-memory cache / fallback store (100% clean and ready for real production data)
const memoryStore = {
  attendanceRecords: [],
  reports: []
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
      { id: 'I-MCA-A', name: 'I MCA A', batch: '2026–2028', department: 'MCA', totalStudents: 52, advisorName: 'Mrs. V. Nandhini, AP/CA', crName: 'MUTHUVEL R' }
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
  async getAttendanceByDate(classId = 'I-MCA-A', date, periodNo) {
    const memRecord = memoryStore.attendanceRecords.find(r => 
      r.classId === classId && r.date === date && (!periodNo || r.periodNo == periodNo)
    ) || null;
    try {
      let query = supabase
        .from('attendance_records')
        .select('*')
        .eq('class_id', classId)
        .eq('date', date);
      if (periodNo) {
        query = query.eq('period_no', periodNo);
      }
      const { data, error } = await query.order('submitted_at', { ascending: false }).limit(1).maybeSingle();

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
    const existingIdx = memoryStore.attendanceRecords.findIndex(r => 
      r.date === record.date && r.classId === record.classId && (r.periodNo == record.periodNo || r.id === record.id)
    );
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
      let { error } = await supabase.from('attendance_records').upsert(dbRow, { onConflict: 'id' });
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
        const res = await supabase.from('attendance_records').upsert(coreRow, { onConflict: 'id' });
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

  // Clear all attendance records & reports to ensure 100% clean state for real production data
  async clearAllAttendanceRecords(classId) {
    if (classId) {
      memoryStore.attendanceRecords = memoryStore.attendanceRecords.filter(r => r.classId !== classId);
      memoryStore.reports = memoryStore.reports.filter(r => r.classId !== classId);
    } else {
      memoryStore.attendanceRecords = [];
      memoryStore.reports = [];
    }

    try {
      let query = supabase.from('attendance_records').delete();
      if (classId) query = query.eq('class_id', classId);
      else query = query.neq('id', 'NONE');
      await query;

      let repQuery = supabase.from('reports').delete();
      if (classId) repQuery = repQuery.eq('class_id', classId);
      else repQuery = repQuery.neq('id', 'NONE');
      await repQuery;
      console.log(`🧹 Cleared attendance & reports in Supabase for ${classId || 'all classes'}`);
    } catch (e) {
      console.warn('Could not clear Supabase tables:', e.message);
    }
    return true;
  },

  // Delete attendance records for a specific month (Month-End rollover after downloading Excel)
  async deleteAttendanceForMonth(classId, yearMonth) {
    const ym = yearMonth || new Date().toISOString().slice(0, 7);
    const startDate = `${ym}-01`;
    const endDate = `${ym}-31`;

    if (classId) {
      memoryStore.attendanceRecords = memoryStore.attendanceRecords.filter(r => 
        r.classId !== classId || !(r.date >= startDate && r.date <= endDate)
      );
      memoryStore.reports = memoryStore.reports.filter(r => 
        r.classId !== classId || !(r.date >= startDate && r.date <= endDate)
      );
    } else {
      memoryStore.attendanceRecords = memoryStore.attendanceRecords.filter(r => 
        !(r.date >= startDate && r.date <= endDate)
      );
      memoryStore.reports = memoryStore.reports.filter(r => 
        !(r.date >= startDate && r.date <= endDate)
      );
    }

    try {
      let query = supabase.from('attendance_records').delete().gte('date', startDate).lte('date', endDate);
      if (classId) query = query.eq('class_id', classId);
      const res = await query;
      if (res.error) {
        console.warn('Supabase deleteAttendanceForMonth warning:', res.error.message);
      } else {
        console.log(`🧹 Deleted attendance records in Supabase for ${classId || 'all'} in ${ym}`);
      }
    } catch (e) {
      console.warn('Could not delete attendance records for month in Supabase:', e.message);
    }
    return true;
  },

  // Get attendance records for a specific month (for Excel report)
  async getMonthAttendance(classId, yearMonth) {
    const ym = yearMonth || new Date().toISOString().slice(0, 7);
    const startDate = `${ym}-01`;
    const endDate = `${ym}-31`;
    try {
      let query = supabase
        .from('attendance_records')
        .select('*')
        .gte('date', startDate)
        .lte('date', endDate)
        .order('date', { ascending: true })
        .order('period_no', { ascending: true });
      if (classId) query = query.eq('class_id', classId);
      const { data, error } = await query;
      if (!error && data && data.length > 0) {
        return data.map(mapAttendance);
      }
    } catch (_) {}
    return memoryStore.attendanceRecords.filter(r => 
      (!classId || r.classId === classId) && (r.date >= startDate && r.date <= endDate)
    );
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
      crRoll: null,
      crName: null,
      crCode: null,
      maleAsstRoll: null,
      maleAsstName: null,
      maleAsstCode: null,
      femaleAsstRoll: null,
      femaleAsstName: null,
      femaleAsstCode: null,
      studentCode: 'STU2026'
    }
  },

  async getDelegation(classId = 'I-MCA-A') {
    if (!this.delegations[classId]) {
      this.delegations[classId] = {
        classId,
        advisorName: 'Mrs. V. Nandhini, AP/CA',
        advisorCode: 'NAVI2026',
        crRoll: null,
        crName: null,
        crCode: null,
        maleAsstRoll: null,
        maleAsstName: null,
        maleAsstCode: null,
        femaleAsstRoll: null,
        femaleAsstName: null,
        femaleAsstCode: null,
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

  async verifyPasscode({ classId = 'I-MCA-A', role, code, gender, rollNo, staffName }) {
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
      const teacherCodes = {
        'Mrs. V. Nandhini, AP/CA': ['OOPS2026', 'NAVI2026', 'ADV2026', '25PMCT12', '25PMCP11', 'STAFF2026'],
        'Dr. S. Sivaramakrishnan, Prof/Maths': ['MAT2026', 'SIVA2026', '25PMCT11', 'STAFF2026'],
        'Mrs. K. Shivashankari, AP/CA': ['DT2026', 'SHIVA2026', '25PMCT13', '25PMCP12', 'STAFF2026'],
        'Ms. M. Tamilmani, AP/CA': ['OS2026', 'TAMIL2026', '25PMCT14', '25PMCP13', 'STAFF2026'],
        'Ms. V. Deepa, AP/CA': ['SE2026', 'DEEPA2026', '25PMCT15', 'STAFF2026']
      };

      let matchedFaculty = null;
      if (staffName) {
        matchedFaculty = this.facultyList.find(f => f.name.toLowerCase().includes(staffName.toLowerCase()));
      }

      if (!matchedFaculty) {
        for (const [fName, codes] of Object.entries(teacherCodes)) {
          if (codes.includes(entered)) {
            matchedFaculty = this.facultyList.find(f => f.name === fName);
            break;
          }
        }
      }

      if (matchedFaculty) {
        const allowed = teacherCodes[matchedFaculty.name] || ['STAFF2026'];
        if (allowed.includes(entered) || entered === 'STAFF2026' || entered === 'ADV2026') {
          return {
            valid: true,
            role: 'staff',
            name: matchedFaculty.name,
            subject: matchedFaculty.subject,
            code: matchedFaculty.code,
            classId
          };
        } else {
          return {
            valid: false,
            error: `Invalid passcode for ${matchedFaculty.name}. Assigned code: ${allowed[0]} or STAFF2026.`
          };
        }
      }

      const generalMatch = entered === 'STAFF2026' || entered === 'ADV2026' || entered === 'NAVI2026' || entered === 'TEACH2026';
      if (generalMatch) {
        return {
          valid: true,
          role: 'staff',
          name: 'Ms. M. Tamilmani, AP/CA',
          subject: 'Operating Systems & Lab',
          code: '25PMCT14 / 25PMCP13',
          classId
        };
      }
      return {
        valid: false,
        error: 'Invalid staff passcode. Please enter your teacher code (e.g. OS2026, MAT2026, DT2026, SE2026) or STAFF2026.'
      };
    } else if (role === 'cr') {
      if (!del.crRoll || !del.crCode) {
        return { valid: false, error: 'No Class Representative has been appointed by the Class Advisor yet.' };
      }
      if (rollNo && Number(rollNo) !== Number(del.crRoll)) {
        return {
          valid: false,
          error: `Access Denied: You are not the appointed Class Representative. Only ${del.crName || 'Roll #' + del.crRoll} can access the CR dashboard.`
        };
      }
      const match = entered === (del.crCode || '').trim().toUpperCase() || entered === 'CR2026';
      if (match) {
        return {
          valid: true,
          name: del.crName ? `${del.crName} (CR)` : 'Class Representative (CR)',
          role: 'cr',
          classId,
          rollNo: del.crRoll,
          gender: gender || 'M'
        };
      } else {
        return { valid: false, error: 'Invalid CR passcode. Please check with your Class Advisor.' };
      }
    } else if (role === 'assistantCr') {
      const hasFemaleAsst = del.femaleAsstRoll && del.femaleAsstCode;
      const hasMaleAsst = del.maleAsstRoll && del.maleAsstCode;

      if (!hasFemaleAsst && !hasMaleAsst) {
        return { valid: false, error: 'No Assistant Class Representative has been appointed by the Class Advisor yet.' };
      }

      if (rollNo) {
        const isFemaleAsst = hasFemaleAsst && Number(rollNo) === Number(del.femaleAsstRoll);
        const isMaleAsst = hasMaleAsst && Number(rollNo) === Number(del.maleAsstRoll);

        if (!isFemaleAsst && !isMaleAsst) {
          const asstsList = [];
          if (hasFemaleAsst) asstsList.push(`${del.femaleAsstName || 'Female Asst. CR'} (Roll #${del.femaleAsstRoll})`);
          if (hasMaleAsst) asstsList.push(`${del.maleAsstName || 'Male Asst. CR'} (Roll #${del.maleAsstRoll})`);
          const assts = asstsList.join(' or ');
          return {
            valid: false,
            error: `Access Denied: You are not appointed as Assistant CR. Only appointed Assistant CRs (${assts}) can access this dashboard.`
          };
        }

        if (isFemaleAsst && (entered === (del.femaleAsstCode || '').trim().toUpperCase() || entered === 'FACR2026' || entered === 'ACR2026')) {
          return {
            valid: true,
            name: del.femaleAsstName ? `${del.femaleAsstName} (Asst. CR)` : 'Assistant CR',
            role: 'assistantCr',
            classId,
            rollNo: del.femaleAsstRoll,
            gender: 'F'
          };
        }
        if (isMaleAsst && (entered === (del.maleAsstCode || '').trim().toUpperCase() || entered === 'MACR2026' || entered === 'ACR2026')) {
          return {
            valid: true,
            name: del.maleAsstName ? `${del.maleAsstName} (Asst. CR)` : 'Assistant CR',
            role: 'assistantCr',
            classId,
            rollNo: del.maleAsstRoll,
            gender: 'M'
          };
        }
        return { valid: false, error: 'Invalid Assistant CR passcode. Please check with your Class Advisor.' };
      } else {
        // Switcher sheet without rollNo - match by entered code directly!
        if (hasFemaleAsst && (entered === (del.femaleAsstCode || '').trim().toUpperCase() || entered === 'FACR2026')) {
          return {
            valid: true,
            name: del.femaleAsstName ? `${del.femaleAsstName} (Asst. CR)` : 'Assistant CR',
            role: 'assistantCr',
            classId,
            rollNo: del.femaleAsstRoll,
            gender: 'F'
          };
        }
        if (hasMaleAsst && (entered === (del.maleAsstCode || '').trim().toUpperCase() || entered === 'MACR2026')) {
          return {
            valid: true,
            name: del.maleAsstName ? `${del.maleAsstName} (Asst. CR)` : 'Assistant CR',
            role: 'assistantCr',
            classId,
            rollNo: del.maleAsstRoll,
            gender: 'M'
          };
        }
        if (entered === 'ACR2026') {
          const isFemale = !!hasFemaleAsst;
          const chosenName = isFemale ? del.femaleAsstName : del.maleAsstName;
          const chosenRoll = isFemale ? del.femaleAsstRoll : del.maleAsstRoll;
          return {
            valid: true,
            name: chosenName ? `${chosenName} (Asst. CR)` : 'Assistant CR',
            role: 'assistantCr',
            classId,
            rollNo: chosenRoll,
            gender: isFemale ? 'F' : 'M'
          };
        }
        return { valid: false, error: 'Invalid Assistant CR passcode. Please check with your Class Advisor.' };
      }
    } else if (role === 'student') {
      if (rollNo) {
        const matched = fallbackStudents.find(s => s.rollNo === Number(rollNo));
        if (!matched) {
          return { valid: false, error: 'Selected student not found in roster.' };
        }

        const isCcrMatch = (
          entered === (matched.ccrCode || '').toUpperCase() ||
          entered === `CCR-${String(matched.rollNo).padStart(4, '0')}` ||
          entered === String(matched.enrollmentNo).toUpperCase() ||
          entered === (del.studentCode || '').trim().toUpperCase() ||
          entered === 'STU2026'
        );

        if (isCcrMatch) {
          return {
            valid: true,
            role: 'student',
            name: matched.name,
            rollNo: matched.rollNo,
            enrollmentNo: matched.enrollmentNo,
            studentId: matched.enrollmentNo,
            gender: matched.gender || (gender || 'M'),
            ccrCode: matched.ccrCode || `CCR-${String(matched.rollNo).padStart(4, '0')}`,
            classId
          };
        } else {
          return {
            valid: false,
            error: `Code mismatch: The entered code does not match ${matched.name}. Please enter your assigned ClassCR code (${matched.ccrCode || 'CCR-' + String(matched.rollNo).padStart(4, '0')}).`
          };
        }
      } else {
        // Without rollNo (from switcher sheet)
        const matched = fallbackStudents.find(s => 
          entered === (s.ccrCode || '').toUpperCase() ||
          entered === `CCR-${String(s.rollNo).padStart(4, '0')}` ||
          entered === String(s.enrollmentNo).toUpperCase()
        );
        if (matched) {
          return {
            valid: true,
            role: 'student',
            name: matched.name,
            rollNo: matched.rollNo,
            enrollmentNo: matched.enrollmentNo,
            studentId: matched.enrollmentNo,
            gender: matched.gender || 'M',
            ccrCode: matched.ccrCode || `CCR-${String(matched.rollNo).padStart(4, '0')}`,
            classId
          };
        }
        if (entered === (del.studentCode || '').trim().toUpperCase() || entered === 'STU2026') {
          const firstStu = fallbackStudents[0] || { name: 'Student', rollNo: 1, enrollmentNo: '24MCA001', gender: 'M' };
          return {
            valid: true,
            role: 'student',
            name: firstStu.name,
            rollNo: firstStu.rollNo,
            enrollmentNo: firstStu.enrollmentNo,
            studentId: firstStu.enrollmentNo,
            gender: firstStu.gender || 'M',
            ccrCode: firstStu.ccrCode || `CCR-${String(firstStu.rollNo).padStart(4, '0')}`,
            classId
          };
        }
        return { valid: false, error: 'Invalid student CCR passcode or enrollment number.' };
      }
    }


    return { valid: false, error: 'Invalid verification passcode for this role' };
  },

  getTimetable: async (classId = 'I-MCA-A') => {
    try {
      const { data, error } = await supabase
        .from('timetable')
        .select('*')
        .eq('class_id', classId)
        .order('day_order', { ascending: true })
        .order('period_no', { ascending: true });
      if (!error && data && data.length > 0) {
        return data;
      }
    } catch (_) {}
    return [
      { day: 'Monday', dayOrder: 1, periods: ['OS', 'MAT', 'OOPS', 'MAT', 'OOPS', 'SE', 'DT LAB', 'DT LAB'] },
      { day: 'Tuesday', dayOrder: 2, periods: ['OOPS', 'OS', 'MAT', 'OS', 'DT', 'OS LAB', 'OS LAB', 'OOPS'] },
      { day: 'Wednesday', dayOrder: 3, periods: ['DT', 'MAT', 'OOPS LAB', 'OOPS LAB', 'DT', 'OS', 'DT', 'SE'] },
      { day: 'Thursday', dayOrder: 4, periods: ['SE', 'OS LAB', 'OS LAB', 'MAT', 'OOPS', 'DT', 'SE', 'OS'] },
      { day: 'Friday', dayOrder: 5, periods: ['MAT', 'OOPS', 'SE', 'MAT', 'DT LAB', 'DT LAB', 'OS', 'DT'] },
      { day: 'Saturday', dayOrder: 6, periods: ['OOPS', 'LIB', 'OOPS LAB', 'OOPS LAB', 'MAT', 'OS', 'SE', 'DT'] }
    ];
  },

  getTimetableForDay: async (classId = 'I-MCA-A', day = 'Saturday') => {
    try {
      const { data, error } = await supabase
        .from('timetable')
        .select('*')
        .eq('class_id', classId)
        .ilike('day', day)
        .order('period_no', { ascending: true });
      if (!error && data && data.length > 0) {
        return data;
      }
    } catch (_) {}
    const defaultTable = [
      { day: 'Monday', dayOrder: 1, periods: ['OS', 'MAT', 'OOPS', 'MAT', 'OOPS', 'SE', 'DT LAB', 'DT LAB'] },
      { day: 'Tuesday', dayOrder: 2, periods: ['OOPS', 'OS', 'MAT', 'OS', 'DT', 'OS LAB', 'OS LAB', 'OOPS'] },
      { day: 'Wednesday', dayOrder: 3, periods: ['DT', 'MAT', 'OOPS LAB', 'OOPS LAB', 'DT', 'OS', 'DT', 'SE'] },
      { day: 'Thursday', dayOrder: 4, periods: ['SE', 'OS LAB', 'OS LAB', 'MAT', 'OOPS', 'DT', 'SE', 'OS'] },
      { day: 'Friday', dayOrder: 5, periods: ['MAT', 'OOPS', 'SE', 'MAT', 'DT LAB', 'DT LAB', 'OS', 'DT'] },
      { day: 'Saturday', dayOrder: 6, periods: ['OOPS', 'LIB', 'OOPS LAB', 'OOPS LAB', 'MAT', 'OS', 'SE', 'DT'] }
    ];
    return defaultTable.find(t => t.day.toLowerCase() === day.toLowerCase()) || null;
  }
};

module.exports = {
  supabase,
  db,
  mapStudent,
  mapAttendance,
  mapReport
};
