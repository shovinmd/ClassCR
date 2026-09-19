# 📱 ClassCR — College Attendance & CR Management Platform

ClassCR is a college attendance and Class Representative (CR) management platform designed for speed, reliability, and role-based access control.

---

## 🚀 Features Built & Configured

### 1. ⚡ Quick Mark Attendance (CR Workflow)
- **Instant Attendance**: All 52 students are marked **Present** (`✓`) by default.
- **Fast Absentees Tap**: CR taps only the absent students (e.g. 9 absent -> `43 Present / 9 Absent`).
- **Live Counter**: Real-time counter displaying `43 Present / 9 Absent (43 / 52 Students)`.
- **Search by**: Student Name, Roll No (S.No 01–52), or Enrollment No.
- **Filters**: All (52), Present (43), Absent (9).
- **Verification Bottom Sheet**: Summarizes absentees list for instant verification before submission.
- **CR Daily Notes**: Add remarks (e.g. lab sessions, campus drive, prior leaves).

### 2. 📄 52 Preloaded Students (I MCA Batch 2026–2028)
Extracted directly from `MCA Batch 2026-2028 Student List-2.pdf`:
1. `260192 AASIM.S`
2. `260008 ABDUL MALIK A`
3. `260293 ABINAYA D`
...
13. `260311 DHIVYALAKSHMI H`
...
45. `260274 SHOVIN MICHEL DAVID`
...
52. `260738 TASFIYA FARVIN S`

### 3. 💬 Smart Report Generator (WhatsApp & Advisor Export)
Formats the official daily report with one tap:
```
Attendance Report
I MCA
Date: 18/09/2026

Total Students: 52
Present: 43
Absent: 9

Absent Students:

13. DHIVYALAKSHMI H
    260311

25. LOKESHWARAN R
    260435

27. MAHESH KUMAR.R
    260367

28. MANIKANDAN D
    260345

31. MUTHUVEL R
    260320

34. NETHAJI.V
    260333

37. PRITHEEVIRAJ.S
    260405

44. SATHYA.P
    260368

52. TASFIYA FARVIN S
    260738

Generated via ClassCR 📱
```
- **Copy Report**: 1-click clipboard copy with snackbar confirmation.
- **WhatsApp**: Direct web/app sharing intent with formatted text.
- **Share**: System-level export.

### 4. 👥 Role-Based Portals (Interactive Demo Switcher)
Easily switch between all 4 roles using the **"Switch Role"** button:
1. **CR**: Mark attendance, submit reports, manage class history, offline sync.
2. **Class Advisor (Dr. K. Senthil Nathan)**: View live report (`Submitted at 09:18 AM`), correct/verify attendance for any of the 52 students, broadcast announcements, view class tiers (Excellent: 31, 75–90%: 14, Below 75%: 7).
3. **Student (DHIVYALAKSHMI H / 260311)**: View personal attendance (Conducted: 30, Present: 26, Absent: 4, Attendance: **86.67%**, Status: ELIGIBLE), subject breakdown, and announcements.
4. **College Admin**: High-level college stats (1,284 students, 8 departments, 32 classes, 32 CRs, 32 Advisors, 29 submitted / 3 pending) + 3-step hierarchy drill down (MCA -> I MCA -> I MCA A).

### 5. 🔄 Offline Mode & Cloud Sync
- Works 100% offline without internet using local caching and queueing.
- Synchronizes automatically to the Express/Node.js REST backend (`http://localhost:5000/api`) when internet is restored.

---

## 🛠️ Project Structure
```
ClassCR/
├── MCA Batch 2026-2028 Student List-2.pdf    # Source PDF of 52 students
├── server/                                   # Node.js + Express REST API
│   ├── src/
│   │   ├── data/students.json                # Preloaded 52 students
│   │   └── server.js                         # REST endpoints + JWT & RBAC
│   └── package.json
├── mobile/                                   # Flutter Material 3 App
│   ├── lib/
│   │   ├── core/theme.dart                   # Custom theme & color palette
│   │   ├── data/mca_students.dart            # 52 students offline dataset
│   │   ├── models/models.dart                # Student & Attendance models
│   │   ├── providers/classcr_state.dart      # Reactive state & sync logic
│   │   ├── screens/
│   │   │   ├── cr/                           # CR Home, Quick Mark, Smart Report
│   │   │   ├── advisor/                      # Advisor Dashboard & Corrections
│   │   │   ├── student/                      # Student Portal & 86.67% Analytics
│   │   │   └── admin/                        # Admin College Overview & Drill-down
│   │   ├── widgets/                          # Role Switcher, App Header
│   │   └── main.dart
│   └── pubspec.yaml
└── README.md
```

---

## 🏃 How to Run Locally

### 1. Start Node.js Backend:
```bash
cd server
npm start
```
*Runs on `http://localhost:5000`*

### 2. Start Flutter Mobile App:
```bash
cd mobile
flutter run -d chrome
# or for Windows Desktop:
flutter run -d windows
```
