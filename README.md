# Smart Geo-Face Attendance System

Enterprise-grade attendance app with face verification + GPS geofencing.

---

## 🚀 Get Your APK in 10 Minutes (No Install Needed)

You only need a **free GitHub account**. No Flutter, no Android Studio.

### Step 1 — Create a GitHub Repository

1. Go to [github.com](https://github.com) and sign in (or sign up free)
2. Click **"New"** (green button) → name it `smart-attendance`
3. Set to **Public**, click **Create repository**

---

### Step 2 — Upload This Code

**Option A — GitHub Web (easiest, no Git needed):**

1. In your new repo, click **"uploading an existing file"**
2. Drag and drop the entire `smart_attendance` folder contents
3. Click **"Commit changes"**

**Option B — Git command line:**
```bash
cd smart_attendance
git init
git add .
git commit -m "Initial commit"
git branch -M main
git remote add origin https://github.com/YOUR_USERNAME/smart-attendance.git
git push -u origin main
```

---

### Step 3 — Wait for Automatic Build (~8 minutes)

1. Go to your repo on GitHub
2. Click **"Actions"** tab at the top
3. You'll see **"Build APK"** running automatically
4. Wait for the green ✅ checkmark

---

### Step 4 — Download Your APK

1. Click the completed **"Build APK"** workflow run
2. Scroll down to **"Artifacts"** section
3. Click **"smart-attendance-release"** to download
4. Unzip → install `app-release.apk` on your Android phone

> **Enable "Install from unknown sources"** on your phone:  
> Settings → Security → Install unknown apps → Allow

---

## 📱 Demo Login Credentials

| Role | Email | Password |
|------|-------|----------|
| Employee | rajesh@plant.com | emp123 |
| Employee 2 | priya@plant.com | emp123 |
| Admin | admin@plant.com | admin123 |

---

## 🏗 App Features

### Employee App
- ✅ Secure login with JWT tokens
- ✅ Live camera face capture (front camera)
- ✅ ML Kit face detection + liveness check (eyes open, head pose)
- ✅ Real-time GPS location fetch
- ✅ Mock/fake GPS detection (`position.isMocked`)
- ✅ Geo-fence validation (configurable radius per site)
- ✅ Punch In / Punch Out with full verification chain
- ✅ Attendance history (local SQLite)
- ✅ Profile screen

### Admin Panel
- ✅ Dashboard with today's stats (present, failed, sites, users)
- ✅ **Geo-Fence Manager** — set location radius per site (slider + presets)
- ✅ Live monitoring — all today's punches with GPS + face status
- ✅ User management — list, search, add, edit, reset password, deactivate
- ✅ Reports — filter by status/type/site, export to XLSX/CSV/PDF (backend hook)
- ✅ Site active/inactive toggle

### Security
- ✅ Screenshot prevention (`FLAG_SECURE` on all screens)
- ✅ HTTPS-only network config
- ✅ Fake GPS detection
- ✅ Root device detection
- ✅ Face liveness check (eyes must be open, head must face forward)
- ✅ Multi-face rejection
- ✅ Server-side time (never trusts device clock)
- ✅ Proguard code obfuscation on release builds

---

## 🔧 Project Structure

```
lib/
├── main.dart                    # App entry + session check
├── theme/app_theme.dart         # Design system
├── services/
│   ├── auth_service.dart        # Login, token, user storage
│   ├── attendance_service.dart  # SQLite punch records + sites
│   ├── gps_service.dart         # Location + geofence check
│   ├── face_service.dart        # ML Kit face detection
│   ├── device_security_service.dart  # Root/dev mode check
│   └── notification_service.dart    # Local push notifications
└── screens/
    ├── auth/login_screen.dart
    ├── employee/
    │   ├── employee_home.dart   # Main employee screen + punch tab
    │   ├── punch_screen.dart    # Camera + GPS + face verify flow
    │   └── history_screen.dart  # Attendance log list
    └── admin/
        ├── admin_dashboard.dart      # Stats + quick actions
        ├── geofence_screen.dart      # 🎯 Set radius per site
        ├── user_management_screen.dart
        ├── add_user_screen.dart
        ├── live_monitor_screen.dart
        └── reports_screen.dart
```

---

## 🌐 Connect to a Real Backend

The app is structured so you can swap the demo services for real API calls:

1. **Auth** — replace `AuthService.login()` with `POST /api/auth/login`
2. **Attendance** — replace SQLite with `POST /api/attendance/punch`
3. **Sites** — replace seed data with `GET /api/sites`
4. **Reports export** — wire the export buttons to `GET /api/reports/export`

Recommended backend: **Node.js + Express + PostgreSQL** (see full prompt spec)

---

## 🔑 Production Keystore (for signed release)

To sign with your own keystore instead of debug:

```bash
keytool -genkey -v -keystore upload-keystore.jks \
  -keyalg RSA -keysize 2048 -validity 10000 \
  -alias upload
```

Add to GitHub Secrets and update the workflow `build-apk.yml`.

---

## 📋 Permissions Required

| Permission | Why |
|---|---|
| CAMERA | Face selfie capture |
| ACCESS_FINE_LOCATION | GPS punch validation |
| READ_PHONE_STATE | Device binding |
| USE_BIOMETRIC | Future fingerprint auth |
| POST_NOTIFICATIONS | Punch result alerts |

---

Built with Flutter · ML Kit · SQLite · Geolocator
