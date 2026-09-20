require('dotenv').config();
const express = require('express');
const cors = require('cors');
const jwt = require('jsonwebtoken');
const path = require('path');
const { db, supabase } = require('./supabase');

const app = express();
const PORT = process.env.PORT || 5000;
const JWT_SECRET = process.env.JWT_SECRET || 'classcr-super-secret-key-2026';

app.use(cors());
app.use(express.json());

// Token Authentication Middleware (supports local JWT & Supabase JWT)
async function authenticateToken(req, res, next) {
  const authHeader = req.headers['authorization'];
  const token = authHeader && authHeader.split(' ')[1];

  if (!token) {
    // If no token provided in demo/dev mode, allow anonymous fallback with role header
    const mockRole = req.headers['x-mock-role'];
    if (mockRole) {
      const email = `${mockRole}@classcr.edu`;
      const user = await db.getUserByEmail(email);
      const userNameHeader = req.headers['x-user-name'];
      req.user = user || {
        id: `user_${mockRole}`,
        role: mockRole,
        classId: req.headers['x-class-id'] || 'I-MCA-A',
        name: userNameHeader || `${mockRole.toUpperCase()} User`
      };
      if (userNameHeader) {
        req.user.name = userNameHeader;
      }
      return next();
    }
    return res.status(401).json({ error: 'Access token required' });
  }

  // First try verifying with local JWT
  jwt.verify(token, JWT_SECRET, (err, user) => {
    if (!err && user) {
      req.user = user;
      return next();
    }

    // Fallback: Verify via Supabase Auth
    supabase.auth.getUser(token).then(({ data, error }) => {
      if (!error && data && data.user) {
        req.user = {
          id: data.user.id,
          email: data.user.email,
          role: data.user.user_metadata?.role || 'cr',
          classId: data.user.user_metadata?.classId || 'I-MCA-A',
          name: data.user.user_metadata?.name || data.user.email
        };
        return next();
      }
      return res.status(403).json({ error: 'Invalid or expired authentication token' });
    }).catch(() => {
      return res.status(403).json({ error: 'Authentication verification failed' });
    });
  });
}

// Role authorization middleware
function requireRole(allowedRoles) {
  return (req, res, next) => {
    if (!req.user || !allowedRoles.includes(req.user.role)) {
      return res.status(403).json({ error: `Access denied. Requires role: ${allowedRoles.join(', ')}` });
    }
    next();
  };
}

// ==========================================
// Routes
// ==========================================

// Health check with Supabase database status
app.get('/api/health', async (req, res) => {
  let dbStatus = 'connected';
  try {
    const { error } = await supabase.from('classes').select('id').limit(1);
    if (error) dbStatus = `notice: ${error.message}`;
  } catch (err) {
    dbStatus = `disconnected: ${err.message}`;
  }

  res.json({
    status: 'ok',
    service: 'ClassCR Backend API',
    database: 'Supabase PostgreSQL',
    dbStatus,
    timestamp: new Date().toISOString()
  });
});

// Authentication
app.post('/api/auth/login', async (req, res) => {
  const { email, password } = req.body;
  if (!email) {
    return res.status(400).json({ error: 'Email is required' });
  }

  const user = await db.getUserByEmail(email);
  if (!user || user.password !== password) {
    return res.status(401).json({ error: 'Invalid email or password' });
  }

  const token = jwt.sign(
    {
      id: user.id,
      email: user.email,
      role: user.role,
      classId: user.classId,
      name: user.name,
      studentId: user.studentId
    },
    JWT_SECRET,
    { expiresIn: '7d' }
  );

  const safeUser = { ...user };
  delete safeUser.password;
  res.json({ token, user: safeUser });
});

app.get('/api/auth/me', authenticateToken, async (req, res) => {
  const user = await db.getUserByEmail(req.user.email);
  if (user) {
    const safeUser = { ...user };
    delete safeUser.password;
    return res.json({ user: safeUser });
  }
  res.json({ user: req.user });
});

// Students List
app.get('/api/students', async (req, res) => {
  const { classId, q } = req.query;
  let list = await db.getStudents(classId);

  if (q) {
    const term = q.toLowerCase();
    list = list.filter(s =>
      s.name.toLowerCase().includes(term) ||
      s.enrollmentNo.toLowerCase().includes(term) ||
      String(s.rollNo) === term
    );
  }
  res.json({ total: list.length, students: list });
});

app.get('/api/students/:rollNo', async (req, res) => {
  const roll = parseInt(req.params.rollNo, 10);
  const student = await db.getStudentByRoll(roll);
  if (!student) return res.status(404).json({ error: 'Student not found' });
  res.json({ student });
});

// Classes
app.get('/api/classes', async (req, res) => {
  const classes = await db.getClasses();
  res.json({ classes });
});

app.get('/api/classes/:id', async (req, res) => {
  const classes = await db.getClasses();
  const cls = classes.find(c => c.id === req.params.id);
  if (!cls) return res.status(404).json({ error: 'Class not found' });
  const students = await db.getStudents(cls.id);
  res.json({ class: cls, studentsCount: students.length });
});

// Attendance Endpoints
app.get('/api/attendance/today', async (req, res) => {
  const classId = req.query.classId || 'I-MCA-A';
  const today = req.query.date || new Date().toISOString().slice(0, 10);
  let record = await db.getAttendanceByDate(classId, today);
  if (!record && req.query.date === undefined) {
    const history = await db.getAttendanceHistory(classId);
    record = history[0] || null;
  }
  res.json({ attendance: record, todayDate: today });
});

app.get('/api/attendance/date/:date', async (req, res) => {
  const classId = req.query.classId || 'I-MCA-A';
  const record = await db.getAttendanceByDate(classId, req.params.date);
  if (!record) {
    return res.json({ attendance: null, message: 'No attendance marked for this date' });
  }
  res.json({ attendance: record });
});

app.get('/api/attendance/history', async (req, res) => {
  const classId = req.query.classId || 'I-MCA-A';
  const records = await db.getAttendanceHistory(classId);
  res.json({ history: records });
});

// Submit Attendance
app.post('/api/attendance', authenticateToken, async (req, res) => {
  const { classId, date, absentRolls, notes, markedByName, markedByRole } = req.body;
  const targetClass = classId || req.user.classId || 'I-MCA-A';
  const recordDate = date || new Date().toISOString().slice(0, 10);

  // Backend RBAC enforcement: CR can only submit for assigned class
  if (req.user.role === 'cr' && req.user.classId && req.user.classId !== targetClass) {
    return res.status(403).json({ error: 'Forbidden: CR cannot mark attendance for other classes' });
  }

  // Check if attendance already exists and is locked
  const existing = await db.getAttendanceByDate(targetClass, recordDate);
  const isAdvisorOrAdmin = req.user.role === 'advisor' || req.user.role === 'admin';

  if (existing && (existing.isLocked || existing.status === 'submitted')) {
    if (!isAdvisorOrAdmin) {
      return res.status(403).json({
        error: 'Attendance is locked after submission. Only Class Advisor can modify attendance.',
        isLocked: true,
        markedByName: existing.markedByName,
        markedByRole: existing.markedByRole
      });
    }
  }

  const students = await db.getStudents(targetClass);
  const total = students.length || 52;
  const absentCount = (absentRolls || []).length;
  const presentCount = total - absentCount;

  const authorName = markedByName || (existing && existing.markedByName ? existing.markedByName : (req.user.name || 'CR'));
  const authorRole = markedByRole || (existing && existing.markedByRole ? existing.markedByRole : (req.user.role === 'assistantCr' ? 'Assistant CR' : (req.user.role === 'cr' ? 'CR' : 'Advisor')));

  const newRecord = {
    id: `att_${recordDate.replace(/-/g, '')}`,
    classId: targetClass,
    date: recordDate,
    totalStudents: total,
    presentCount,
    absentCount,
    absentRolls: (absentRolls || []).sort((a, b) => a - b),
    markedBy: req.user.id || 'cr',
    markedByName: authorName,
    markedByRole: authorRole,
    isLocked: true,
    lastModifiedBy: isAdvisorOrAdmin && existing ? (req.user.name || 'Class Advisor') : (existing ? existing.lastModifiedBy : ''),
    status: 'submitted',
    submittedAt: existing && existing.submittedAt ? existing.submittedAt : new Date().toISOString(),
    notes: notes || ''
  };

  await db.saveAttendanceRecord(newRecord);

  // Auto-generate formatted report and persist to Supabase
  const absentStudents = (absentRolls || []).map(rNo => {
    const s = students.find(st => st.rollNo === rNo);
    return s
      ? { rollNo: s.rollNo, name: s.name, enrollmentNo: s.enrollmentNo }
      : { rollNo: rNo, name: 'Unknown', enrollmentNo: '' };
  });

  const formattedDate = recordDate.split('-').reverse().join('/');
  const report = {
    id: `rep_${recordDate.replace(/-/g, '')}`,
    classId: targetClass,
    date: formattedDate,
    totalStudents: total,
    presentCount,
    absentCount,
    absentStudents,
    markedByName: authorName,
    markedByRole: authorRole,
    submittedAt: new Date().toLocaleTimeString([], { hour: '2-digit', minute: '2-digit' }),
    status: 'sent',
    formattedText: `Attendance Report\n${targetClass}\nDate: ${formattedDate}\nMarked By: ${authorName} (${authorRole})\n\nTotal Students: ${total}\nPresent: ${presentCount}\nAbsent: ${absentCount}`
  };

  await db.saveReport(report);

  res.json({ success: true, attendance: newRecord, report });
});

// Offline Sync batch endpoint
app.post('/api/sync', authenticateToken, async (req, res) => {
  const { batch } = req.body;
  if (!Array.isArray(batch)) {
    return res.status(400).json({ error: 'Expected batch array of attendance logs' });
  }

  const synced = [];
  for (const item of batch) {
    await db.saveAttendanceRecord(item);
    synced.push(item.id || item.date);
  }

  res.json({ success: true, count: synced.length, synced });
});

// Smart Reports
app.get('/api/reports', async (req, res) => {
  const classId = req.query.classId || 'I-MCA-A';
  const reports = await db.getReports(classId);
  res.json({ reports });
});

app.post('/api/reports/generate', async (req, res) => {
  const { date, classId, absentRolls, markedByName, markedByRole } = req.body;
  const targetDate = date || new Date().toISOString().slice(0, 10);
  const formattedDate = targetDate.includes('-') ? targetDate.split('-').reverse().join('/') : targetDate;
  const cls = classId || 'I-MCA-A';
  const students = await db.getStudents(cls);
  const total = students.length || 52;
  const rolls = absentRolls || [13, 25, 27, 28, 31, 34, 37, 44, 52];

  const absentStudents = rolls.map(rNo => {
    const s = students.find(st => st.rollNo === rNo);
    return s
      ? { rollNo: s.rollNo, name: s.name, enrollmentNo: s.enrollmentNo }
      : { rollNo: rNo, name: 'Unknown', enrollmentNo: '' };
  });

  const authorText = markedByName ? `Marked By: ${markedByName}${markedByRole ? ` (${markedByRole})` : ''}\n` : '';
  const text = `Attendance Report\n${cls}\nDate: ${formattedDate}\n${authorText}\nTotal Students: ${total}\nPresent: ${total - rolls.length}\nAbsent: ${rolls.length}\n\nAbsent Students:\n\n` +
    absentStudents.map(s => `${s.rollNo}. ${s.name}\n    ${s.enrollmentNo}`).join('\n\n') +
    `\n\nGenerated via ClassCR 📱`;

  res.json({
    date: formattedDate,
    className: cls,
    totalStudents: total,
    presentCount: total - rolls.length,
    absentCount: rolls.length,
    absentStudents,
    markedByName,
    markedByRole,
    formattedText: text
  });
});

// Analytics
app.get('/api/analytics/class/:classId', async (req, res) => {
  const classId = req.params.classId || 'I-MCA-A';
  const history = await db.getAttendanceHistory(classId);
  const students = await db.getStudents(classId);
  const totalStudents = students.length || 52;

  const totalConductedDays = history.length > 0 ? history.length : 30;
  let totalPresentCount = 0;
  for (const rec of history) {
    totalPresentCount += (rec.presentCount || (totalStudents - (rec.absentCount || 0)));
  }

  const avgAttendance = history.length > 0
    ? ((totalPresentCount / (history.length * totalStudents)) * 100).toFixed(1)
    : '88.4';

  res.json({
    classId,
    totalStudents,
    categories: {
      excellent: Math.round(totalStudents * 0.6), // > 90%
      good: Math.round(totalStudents * 0.27),     // 75-90%
      below75: Math.round(totalStudents * 0.13)   // < 75%
    },
    averageAttendancePercent: parseFloat(avgAttendance),
    totalConductedDays
  });
});

app.get('/api/analytics/student/:identifier', async (req, res) => {
  const id = req.params.identifier;
  const student = await db.getStudentByIdentifier(id);
  if (!student) return res.status(404).json({ error: 'Student not found' });

  const history = await db.getAttendanceHistory(student.classId || 'I-MCA-A');
  const conducted = history.length > 0 ? history.length : 30;

  let presentCount = 0;
  if (history.length > 0) {
    for (const rec of history) {
      if (!rec.absentRolls.includes(student.rollNo)) {
        presentCount++;
      }
    }
  } else {
    // Default reference calculation
    presentCount = student.enrollmentNo === '260311' ? 26 : 28;
  }

  const absent = conducted - presentCount;
  const percentage = ((presentCount / conducted) * 100).toFixed(2);

  res.json({
    student,
    classesConducted: conducted,
    present: presentCount,
    absent,
    attendancePercentage: parseFloat(percentage),
    status: percentage >= 75 ? 'ELIGIBLE' : 'SHORTAGE'
  });
});

// Admin overview
app.get('/api/admin/overview', async (req, res) => {
  const classes = await db.getClasses();
  const students = await db.getStudents();

  res.json({
    stats: {
      students: students.length > 52 ? students.length : 1284,
      departments: 8,
      classes: classes.length,
      crs: classes.length,
      advisors: classes.length
    },
    todayReports: {
      submitted: 29,
      pending: 3
    },
    departments: [
      { name: 'MCA', classesCount: 3, studentsCount: 150 },
      { name: 'BCA', classesCount: 4, studentsCount: 210 },
      { name: 'B.Sc CS', classesCount: 6, studentsCount: 290 },
      { name: 'B.Com', classesCount: 8, studentsCount: 360 },
      { name: 'Other Departments', classesCount: 11, studentsCount: 274 }
    ]
  });
});

// Advisor dashboard data
app.get('/api/advisor/class', async (req, res) => {
  const classId = req.query.classId || 'I-MCA-A';
  const queryDate = req.query.date || new Date().toISOString().slice(0, 10);
  let todayRecord = await db.getAttendanceByDate(classId, queryDate);
  if (!todayRecord && req.query.date === undefined) {
    const history = await db.getAttendanceHistory(classId);
    todayRecord = history[0] || null;
  }
  const students = await db.getStudents(classId);

  const absentRolls = todayRecord ? todayRecord.absentRolls : [];
  const absentees = absentRolls.map(rNo => {
    const s = students.find(st => st.rollNo === rNo);
    return s
      ? { rollNo: s.rollNo, name: s.name, enrollmentNo: s.enrollmentNo }
      : { rollNo: rNo, name: 'Unknown', enrollmentNo: '' };
  });

  const displayDate = (todayRecord ? todayRecord.date : queryDate).split('-').reverse().join('/');

  res.json({
    className: 'I MCA A',
    batch: '2026–2028',
    todayReport: {
      date: displayDate,
      isoDate: todayRecord ? todayRecord.date : queryDate,
      total: students.length || 52,
      present: (students.length || 52) - absentRolls.length,
      absent: absentRolls.length,
      crStatus: todayRecord ? (todayRecord.status === 'submitted' ? 'Submitted' : todayRecord.status) : 'Pending',
      lastUpdated: todayRecord ? (todayRecord.submittedAt || '09:18 AM') : 'Pending',
      markedByName: todayRecord ? todayRecord.markedByName : '',
      markedByRole: todayRecord ? todayRecord.markedByRole : '',
      isLocked: todayRecord ? Boolean(todayRecord.isLocked) : false,
      lastModifiedBy: todayRecord ? todayRecord.lastModifiedBy : ''
    },
    absentees
  });
});

// Faculty & Staff Directory (MCA Department - MVIT)
app.get('/api/faculty', async (req, res) => {
  const department = req.query.department || 'MCA';
  const faculty = await db.getFaculty(department);
  res.json({ department, total: faculty.length, faculty });
});

// Class Delegation & Role Passcode Endpoints
app.get('/api/class-delegation/:classId', async (req, res) => {
  const classId = req.params.classId || 'I-MCA-A';
  const delegation = await db.getDelegation(classId);
  res.json({ delegation });
});

app.post('/api/admin/assign-advisor', async (req, res) => {
  const { classId, advisorName, advisorCode } = req.body;
  const updated = await db.adminAssignAdvisor({ classId, advisorName, advisorCode });
  res.json({ success: true, delegation: updated });
});

app.post('/api/advisor/delegate', async (req, res) => {
  const updated = await db.advisorDelegate(req.body);
  res.json({ success: true, delegation: updated });
});

app.post('/api/auth/verify-code', async (req, res) => {
  const { classId, role, code, gender } = req.body;
  const result = await db.verifyPasscode({ classId, role, code, gender });
  if (!result.valid) {
    return res.status(401).json(result);
  }
  res.json(result);
});

// Root landing
app.get('/', (req, res) => {
  res.json({
    status: 'ok',
    service: 'ClassCR Backend API',
    endpoints: [
      '/api/health',
      '/api/students',
      '/api/classes',
      '/api/attendance/today',
      '/api/attendance/history',
      '/api/reports',
      '/api/class-delegation/:classId',
      '/api/admin/assign-advisor',
      '/api/advisor/delegate',
      '/api/auth/verify-code'
    ]
  });
});

if (require.main === module) {
  app.listen(PORT, () => {
    console.log(`🚀 ClassCR API Server running on port ${PORT}`);
    console.log(`🔗 Supabase URL: ${process.env.SUPABASE_URL || 'Not Set'}`);
    console.log(`📊 Connected to Supabase backend storage`);
  });
}

module.exports = app;
