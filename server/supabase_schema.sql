-- ==========================================================
-- ClassCR Supabase Database Schema & Initial Data (Clean Production)
-- Run this in your Supabase SQL Editor:
-- https://supabase.com/dashboard/project/fbqafmahrhykcpojprrh/sql
-- ==========================================================

-- 1. DROP OLD TABLES
DROP TABLE IF EXISTS public.attendance_records CASCADE;
DROP TABLE IF EXISTS public.reports CASCADE;
DROP TABLE IF EXISTS public.app_users CASCADE;
DROP TABLE IF EXISTS public.students CASCADE;
DROP TABLE IF EXISTS public.classes CASCADE;

-- 2. CREATE CLASSES TABLE
-- Holds official class delegation: Advisor (Mrs. V. Nandhini), CR, and Asst. CRs with passcodes.
CREATE TABLE public.classes (
  id TEXT PRIMARY KEY,
  name TEXT NOT NULL,
  batch TEXT NOT NULL,
  department TEXT NOT NULL,
  total_students INTEGER DEFAULT 52,
  advisor_name TEXT NOT NULL DEFAULT 'Mrs. V. Nandhini, AP/CA',
  advisor_code TEXT NOT NULL DEFAULT 'ADV2026',
  cr_roll INTEGER,
  cr_name TEXT,
  cr_code TEXT DEFAULT 'CR2026',
  male_asst_roll INTEGER,
  male_asst_name TEXT,
  male_asst_code TEXT DEFAULT 'MACR2026',
  female_asst_roll INTEGER,
  female_asst_name TEXT,
  female_asst_code TEXT DEFAULT 'FACR2026',
  student_code TEXT DEFAULT 'STU2026',
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- 3. CREATE STUDENTS TABLE
-- 52 MCA Department Students Roster
CREATE TABLE public.students (
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

-- 4. CREATE ATTENDANCE RECORDS TABLE
-- Individual lecture/period sessions marked in real-time
CREATE TABLE public.attendance_records (
  id TEXT PRIMARY KEY,
  class_id TEXT NOT NULL REFERENCES public.classes(id) ON DELETE CASCADE,
  date TEXT NOT NULL,
  period_no INTEGER DEFAULT 1,
  period_subject TEXT,
  is_daily_class_record BOOLEAN DEFAULT false,
  total_students INTEGER NOT NULL DEFAULT 52,
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
  asst_cr_verified BOOLEAN DEFAULT false,
  asst_cr_verified_by TEXT,
  asst_cr_verified_at TEXT,
  faculty_acknowledgment_status TEXT,
  faculty_acknowledged_by TEXT,
  faculty_acknowledged_at TEXT,
  faculty_rejection_reason TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Enable multiple periods per date without conflict
CREATE UNIQUE INDEX IF NOT EXISTS attendance_records_class_date_period_idx 
  ON public.attendance_records(class_id, date, (COALESCE(period_no, 1)));

-- Trigger to guarantee Period 1 is always flagged as the Official Daily Class Record
CREATE OR REPLACE FUNCTION set_daily_class_record_flag()
RETURNS TRIGGER AS $$
BEGIN
  IF NEW.period_no = 1 THEN
    NEW.is_daily_class_record := true;
  END IF;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trg_set_daily_class_record ON public.attendance_records;
CREATE TRIGGER trg_set_daily_class_record
BEFORE INSERT OR UPDATE ON public.attendance_records
FOR EACH ROW
EXECUTE FUNCTION set_daily_class_record_flag();

-- 5. ROW LEVEL SECURITY (RLS) - Permissive policies for mobile app PostgREST
ALTER TABLE public.classes ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.students ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.attendance_records ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Allow public all access on classes" ON public.classes FOR ALL USING (true) WITH CHECK (true);
CREATE POLICY "Allow public all access on students" ON public.students FOR ALL USING (true) WITH CHECK (true);
CREATE POLICY "Allow public all access on attendance_records" ON public.attendance_records FOR ALL USING (true) WITH CHECK (true);

-- 6. SEED OFFICIAL CLASS (I-MCA-A)
-- Advisor is Mrs. V. Nandhini, AP/CA exclusively
INSERT INTO public.classes (
  id, name, batch, department, total_students,
  advisor_name, advisor_code,
  cr_roll, cr_name, cr_code,
  male_asst_roll, male_asst_name, male_asst_code,
  female_asst_roll, female_asst_name, female_asst_code,
  student_code
)
VALUES (
  'I-MCA-A', 'I MCA A', '2026–2028', 'MCA', 52,
  'Mrs. V. Nandhini, AP/CA', 'ADV2026',
  31, 'MUTHUVEL R', 'CR2026',
  45, 'SHOVIN MICHEL DAVID', 'MACR2026',
  13, 'DHIVYALAKSHMI H', 'FACR2026',
  'STU2026'
);

-- 7. SEED OFFICIAL 52 MCA STUDENTS ROSTER
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
  (52, '260738', 'TASFIYA FARVIN S', NULL, 'F', 'CCR-0052', 'I-MCA-A', 'MCA'),
  (53, 'Pending', 'DEEPAK RAJA S', NULL, 'M', 'CCR-0053', 'I-MCA-A', 'MCA')
ON CONFLICT (roll_no) DO UPDATE SET
  enrollment_no = EXCLUDED.enrollment_no,
  name = EXCLUDED.name,
  dob = EXCLUDED.dob,
  gender = EXCLUDED.gender,
  ccr_code = EXCLUDED.ccr_code,
  class_id = EXCLUDED.class_id,
  department = EXCLUDED.department;
