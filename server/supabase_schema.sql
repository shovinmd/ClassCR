-- ==========================================================
-- ClassCR Supabase Database Schema & Initial Data
-- Run this in your Supabase SQL Editor:
-- https://supabase.com/dashboard/project/fbqafmahrhykcpojprrh/sql
-- ==========================================================

-- 0. Migrations — safely add columns that may be missing from older deployments
-- Drop stale unique constraint on enrollment_no (roll_no is the real PK)
ALTER TABLE public.students DROP CONSTRAINT IF EXISTS students_enrollment_no_key;

ALTER TABLE public.students ADD COLUMN IF NOT EXISTS gender TEXT DEFAULT 'M';
ALTER TABLE public.students ADD COLUMN IF NOT EXISTS dob TEXT;
ALTER TABLE public.students ADD COLUMN IF NOT EXISTS ccr_code TEXT;
ALTER TABLE public.students ADD COLUMN IF NOT EXISTS department TEXT DEFAULT 'MCA';

ALTER TABLE public.attendance_records ADD COLUMN IF NOT EXISTS asst_cr_verified BOOLEAN DEFAULT false;
ALTER TABLE public.attendance_records ADD COLUMN IF NOT EXISTS asst_cr_verified_by TEXT;
ALTER TABLE public.attendance_records ADD COLUMN IF NOT EXISTS asst_cr_verified_at TEXT;
ALTER TABLE public.attendance_records ADD COLUMN IF NOT EXISTS period_no INTEGER;
ALTER TABLE public.attendance_records ADD COLUMN IF NOT EXISTS period_subject TEXT;
ALTER TABLE public.attendance_records ADD COLUMN IF NOT EXISTS faculty_acknowledgment_status TEXT;
ALTER TABLE public.attendance_records ADD COLUMN IF NOT EXISTS faculty_acknowledged_by TEXT;
ALTER TABLE public.attendance_records ADD COLUMN IF NOT EXISTS faculty_acknowledged_at TEXT;
ALTER TABLE public.attendance_records ADD COLUMN IF NOT EXISTS faculty_rejection_reason TEXT;
-- Allow multiple period records per day by dropping stale class_id,date constraint
ALTER TABLE public.attendance_records DROP CONSTRAINT IF EXISTS attendance_records_class_id_date_key;
CREATE UNIQUE INDEX IF NOT EXISTS attendance_records_class_date_period_idx ON public.attendance_records(class_id, date, (COALESCE(period_no, 1)));

-- 1. Create Tables


CREATE TABLE IF NOT EXISTS public.classes (
  id TEXT PRIMARY KEY,
  name TEXT NOT NULL,
  batch TEXT NOT NULL,
  department TEXT NOT NULL,
  total_students INTEGER DEFAULT 0,
  advisor_name TEXT,
  cr_name TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS public.students (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  roll_no INTEGER UNIQUE NOT NULL,
  enrollment_no TEXT NOT NULL,
  name TEXT NOT NULL,
  dob TEXT,
  gender TEXT DEFAULT 'M',
  ccr_code TEXT,
  class_id TEXT REFERENCES public.classes(id) ON DELETE SET NULL,
  department TEXT DEFAULT 'MCA',
  created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS public.app_users (
  id TEXT PRIMARY KEY,
  name TEXT NOT NULL,
  email TEXT UNIQUE NOT NULL,
  password TEXT NOT NULL,
  role TEXT NOT NULL,
  college_id TEXT,
  department_id TEXT,
  class_id TEXT,
  student_id TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS public.attendance_records (
  id TEXT PRIMARY KEY,
  class_id TEXT NOT NULL,
  date TEXT NOT NULL,
  total_students INTEGER NOT NULL,
  present_count INTEGER NOT NULL,
  absent_count INTEGER NOT NULL,
  absent_rolls JSONB NOT NULL DEFAULT '[]'::jsonb,
  marked_by TEXT,
  marked_by_name TEXT,
  marked_by_role TEXT,
  is_locked BOOLEAN DEFAULT true,
  last_modified_by TEXT,
  status TEXT DEFAULT 'submitted',
  submitted_at TIMESTAMPTZ DEFAULT NOW(),
  notes TEXT,
  UNIQUE(class_id, date)
);

-- Migrations for existing deployments
ALTER TABLE public.attendance_records ADD COLUMN IF NOT EXISTS marked_by_name TEXT;
ALTER TABLE public.attendance_records ADD COLUMN IF NOT EXISTS marked_by_role TEXT;
ALTER TABLE public.attendance_records ADD COLUMN IF NOT EXISTS is_locked BOOLEAN DEFAULT true;
ALTER TABLE public.attendance_records ADD COLUMN IF NOT EXISTS last_modified_by TEXT;

CREATE TABLE IF NOT EXISTS public.reports (
  id TEXT PRIMARY KEY,
  class_id TEXT NOT NULL,
  date TEXT NOT NULL,
  total_students INTEGER NOT NULL,
  present_count INTEGER NOT NULL,
  absent_count INTEGER NOT NULL,
  absent_students JSONB NOT NULL DEFAULT '[]'::jsonb,
  submitted_at TEXT,
  status TEXT DEFAULT 'sent',
  formatted_text TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- 2. Row Level Security (RLS) - Permissive policies for ClassCR
ALTER TABLE public.classes ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.students ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.app_users ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.attendance_records ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.reports ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Allow all access to classes" ON public.classes;
CREATE POLICY "Allow all access to classes" ON public.classes FOR ALL USING (true) WITH CHECK (true);

DROP POLICY IF EXISTS "Allow all access to students" ON public.students;
CREATE POLICY "Allow all access to students" ON public.students FOR ALL USING (true) WITH CHECK (true);

DROP POLICY IF EXISTS "Allow all access to app_users" ON public.app_users;
CREATE POLICY "Allow all access to app_users" ON public.app_users FOR ALL USING (true) WITH CHECK (true);

DROP POLICY IF EXISTS "Allow all access to attendance_records" ON public.attendance_records;
CREATE POLICY "Allow all access to attendance_records" ON public.attendance_records FOR ALL USING (true) WITH CHECK (true);

DROP POLICY IF EXISTS "Allow all access to reports" ON public.reports;
CREATE POLICY "Allow all access to reports" ON public.reports FOR ALL USING (true) WITH CHECK (true);

-- 3. Seed Classes
INSERT INTO public.classes (id, name, batch, department, total_students, advisor_name, cr_name)
VALUES
  ('I-MCA-A', 'I MCA A', '2026–2028', 'MCA', 52, 'Dr. K. Senthil Nathan', 'MUTHUVEL R'),
  ('I-MCA-B', 'I MCA B', '2026–2028', 'MCA', 48, 'Prof. R. Priya', 'K. Karthik'),
  ('II-MCA', 'II MCA', '2025–2027', 'MCA', 50, 'Dr. M. Ramanathan', 'V. Anand'),
  ('I-BCA', 'I BCA', '2026–2029', 'BCA', 55, 'Prof. S. Meena', 'R. Rajesh')
ON CONFLICT (id) DO UPDATE SET
  name = EXCLUDED.name,
  batch = EXCLUDED.batch,
  total_students = EXCLUDED.total_students,
  advisor_name = EXCLUDED.advisor_name,
  cr_name = EXCLUDED.cr_name;

-- 4. Seed Users
INSERT INTO public.app_users (id, name, email, password, role, college_id, department_id, class_id, student_id)
VALUES
  ('user_cr_1', 'MUTHUVEL R (CR)', 'cr@classcr.edu', 'password123', 'cr', 'COL-001', 'MCA', 'I-MCA-A', '260320'),
  ('user_adv_1', 'Dr. K. Senthil Nathan', 'advisor@classcr.edu', 'password123', 'advisor', 'COL-001', 'MCA', 'I-MCA-A', NULL),
  ('user_stu_1', 'DHIVYALAKSHMI H', 'student@classcr.edu', 'password123', 'student', 'COL-001', 'MCA', 'I-MCA-A', '260311'),
  ('user_adm_1', 'College Dean / Administrator', 'admin@classcr.edu', 'password123', 'admin', 'COL-001', 'MCA', NULL, NULL)
ON CONFLICT (id) DO UPDATE SET
  name = EXCLUDED.name,
  email = EXCLUDED.email,
  password = EXCLUDED.password,
  role = EXCLUDED.role;

-- 5. Seed 52 MCA Students
INSERT INTO public.students (roll_no, enrollment_no, name, dob, gender, ccr_code, class_id, department)
VALUES
  (1, '260192', 'AASIM S', '21/09/2004', 'M', 'CCR-0001', 'I-MCA-A', 'MCA'),
  (2, '260008', 'ABDUL MALIK A', NULL, 'M', 'CCR-0002', 'I-MCA-A', 'MCA'),
  (3, '260293', 'ABINAYA D', NULL, 'M', 'CCR-0003', 'I-MCA-A', 'MCA'),
  (4, '260363', 'ABIRAJ V', NULL, 'M', 'CCR-0004', 'I-MCA-A', 'MCA'),
  (5, '260288', 'ABITHA S', NULL, 'F', 'CCR-0005', 'I-MCA-A', 'MCA'),
  (6, '260065', 'AFROZUNNISA A', NULL, 'F', 'CCR-0006', 'I-MCA-A', 'MCA'),
  (7, '260263', 'AJAY V', NULL, 'M', 'CCR-0007', 'I-MCA-A', 'MCA'),
  (8, '260444', 'ARAVINDAN E', NULL, 'M', 'CCR-0008', 'I-MCA-A', 'MCA'),
  (9, '260455', 'ARUN B', NULL, 'M', 'CCR-0009', 'I-MCA-A', 'MCA'),
  (10, '260203', 'ARUSELVI A', NULL, 'F', 'CCR-0010', 'I-MCA-A', 'MCA'),
  (11, '260403', 'DHARSHINI T', NULL, 'F', 'CCR-0011', 'I-MCA-A', 'MCA'),
  (12, '260350', 'DHIVYA S', NULL, 'F', 'CCR-0012', 'I-MCA-A', 'MCA'),
  (13, '260311', 'DHIVYALAKSHMI H', NULL, 'F', 'CCR-0013', 'I-MCA-A', 'MCA'),
  (14, '260226', 'ESHWARAN N', NULL, 'M', 'CCR-0014', 'I-MCA-A', 'MCA'),
  (15, '260300', 'HARINI S', NULL, 'F', 'CCR-0015', 'I-MCA-A', 'MCA'),
  (16, '260323', 'HARIPRASATH G', NULL, 'M', 'CCR-0016', 'I-MCA-A', 'MCA'),
  (17, '260052', 'HARISH KUMAR V', NULL, 'M', 'CCR-0017', 'I-MCA-A', 'MCA'),
  (18, '260222', 'HEMNATH V', NULL, 'M', 'CCR-0018', 'I-MCA-A', 'MCA'),
  (19, '260457', 'JAYARAJ R', NULL, 'M', 'CCR-0019', 'I-MCA-A', 'MCA'),
  (20, '260168', 'KARTHIGA S', NULL, 'F', 'CCR-0020', 'I-MCA-A', 'MCA'),
  (21, '260169', 'KAYALVIZHI R', NULL, 'F', 'CCR-0021', 'I-MCA-A', 'MCA'),
  (22, '260357', 'KEERTHIGA K', NULL, 'F', 'CCR-0022', 'I-MCA-A', 'MCA'),
  (23, '260312', 'KEERTHIVASAN A', NULL, 'M', 'CCR-0023', 'I-MCA-A', 'MCA'),
  (24, '260211', 'KISHORI R', NULL, 'F', 'CCR-0024', 'I-MCA-A', 'MCA'),
  (25, '260364', 'LOKESH V', NULL, 'M', 'CCR-0025', 'I-MCA-A', 'MCA'),
  (26, '260989', 'MAGESH R', NULL, 'M', 'CCR-0026', 'I-MCA-A', 'MCA'),
  (27, '260367', 'MAHESH KUMAR R', NULL, 'M', 'CCR-0027', 'I-MCA-A', 'MCA'),
  (28, '260345', 'MANIKANDAN D', NULL, 'M', 'CCR-0028', 'I-MCA-A', 'MCA'),
  (29, '260356', 'MANISHA P', NULL, 'F', 'CCR-0029', 'I-MCA-A', 'MCA'),
  (30, '260390', 'MOHAMED NIYAS M', NULL, 'M', 'CCR-0030', 'I-MCA-A', 'MCA'),
  (31, '260320', 'MUTHUVEL R', NULL, 'M', 'CCR-0031', 'I-MCA-A', 'MCA'),
  (32, '260355', 'NANDHINI G', NULL, 'F', 'CCR-0032', 'I-MCA-A', 'MCA'),
  (33, '260107', 'NASREEN M', NULL, 'F', 'CCR-0033', 'I-MCA-A', 'MCA'),
  (34, '260333', 'NETHAJI V', NULL, 'M', 'CCR-0034', 'I-MCA-A', 'MCA'),
  (35, '260163', 'NOORA A', NULL, 'F', 'CCR-0035', 'I-MCA-A', 'MCA'),
  (36, '260663', 'PRATHEESWARAN K', NULL, 'M', 'CCR-0036', 'I-MCA-A', 'MCA'),
  (37, '260405', 'PRITHEEVIRAJ S', NULL, 'M', 'CCR-0037', 'I-MCA-A', 'MCA'),
  (38, '260280', 'PRIYANKA A', NULL, 'F', 'CCR-0038', 'I-MCA-A', 'MCA'),
  (39, '260478', 'RAKESH P', NULL, 'M', 'CCR-0039', 'I-MCA-A', 'MCA'),
  (40, '260742', 'RUTHRAN M', NULL, 'M', 'CCR-0040', 'I-MCA-A', 'MCA'),
  (41, '260338', 'SAHANA S', NULL, 'F', 'CCR-0041', 'I-MCA-A', 'MCA'),
  (42, '260319', 'SAKTHIVEL R', NULL, 'M', 'CCR-0042', 'I-MCA-A', 'MCA'),
  (43, 'Pending', 'SANJAY VIGNESHWARAN J', NULL, 'M', 'CCR-0043', 'I-MCA-A', 'MCA'),
  (44, '260368', 'SATHYA P', NULL, 'M', 'CCR-0044', 'I-MCA-A', 'MCA'),
  (45, '260274', 'SHOVIN MICHEL DAVID', '12-08-2005', 'M', 'CCR-0045', 'I-MCA-A', 'MCA'),
  (46, '260366', 'SIVAPRASATH N', NULL, 'M', 'CCR-0046', 'I-MCA-A', 'MCA'),
  (47, '260197', 'SOMAPRIYA M', NULL, 'F', 'CCR-0047', 'I-MCA-A', 'MCA'),
  (48, '260213', 'SRI RATH PRIYA S', NULL, 'F', 'CCR-0048', 'I-MCA-A', 'MCA'),
  (49, '260359', 'SURENDAR', NULL, 'M', 'CCR-0049', 'I-MCA-A', 'MCA'),
  (50, '260304', 'SUSHMITHA S', NULL, 'F', 'CCR-0050', 'I-MCA-A', 'MCA'),
  (51, '260216', 'SWETHA P', NULL, 'F', 'CCR-0051', 'I-MCA-A', 'MCA'),
  (52, '260738', 'TASFIYA FARVIN S', NULL, 'F', 'CCR-0052', 'I-MCA-A', 'MCA')
ON CONFLICT (roll_no) DO UPDATE SET
  enrollment_no = EXCLUDED.enrollment_no,
  name = EXCLUDED.name,
  dob = EXCLUDED.dob,
  gender = EXCLUDED.gender,
  ccr_code = EXCLUDED.ccr_code,
  class_id = EXCLUDED.class_id,
  department = EXCLUDED.department;

-- 6. Clean Database for Production (Ready for fresh, real attendance data only)
-- No past dummy attendance records are added.
TRUNCATE TABLE public.attendance_records CASCADE;
TRUNCATE TABLE public.reports CASCADE;

