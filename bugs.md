# StitchFlow — Bugs & Fix Guide (All-in-One)

Last updated: 2026-04-15

This file lists the remaining bugs/problems and exactly how to fix them.  
It includes BOTH:
- Build/installation blockers (APK not building / app not opening)
- Runtime & functional problems (API/Flutter/backend)

---

## 0) CURRENT BLOCKER: APK NOT BUILDING (Android NDK Clang not found)

### Symptom
Running:
- `flutter build apk --debug`
fails with:
- `Android NDK Clang could not be found`

### Root Cause
Your Android NDK is installed (clang.exe exists), but **Gradle/Flutter cannot resolve the NDK path** because `frontend/android/local.properties` contains invalid paths:

Current file shows:
- `sdk.dir=...Android\\sdk` (wrong path)
- `ndk.dir=C\:\\Users...` (invalid because of `C\:`)

### Fix (fastest)
Edit:
`frontend/android/local.properties`

Set these lines EXACTLY:

```properties
sdk.dir=C:\\Users\\MY-Khan\\AppData\\Local\\Android\\Sdk
ndk.dir=C:\\Users\\MY-Khan\\AppData\\Local\\Android\\Sdk\\ndk\\28.2.13676358
```

Then run:

```powershell
cd "E:\PROJECT MANAGEMET\STITCHFLOW\frontend"
flutter clean
flutter pub get
flutter build apk --debug
```

### Fix (recommended long-term)
Gradle warns `ndk.dir` is deprecated. The modern fix is:

- Remove `ndk.dir=...` from `local.properties`
- Add `ndkVersion "28.2.13676358"` in `frontend/android/app/build.gradle` under `android { }`

(Do this after the build works.)

---

## 1) BUG REPORT FILE IS OUTDATED / MISLEADING

### Symptom
`STITCHFLOW_BUG_ANALYSIS_REPORT.md` still lists issues like:
- hardcoded JWT fallback (`|| "supersecret"`)
- plain text passwords
- KHAN backdoor

But your current codebase has changed and several items are now fixed.

### Fix
Update the report by re-scanning current files and marking:
- FIXED
- PARTIALLY FIXED
- STILL OPEN

(If you want, I can provide a “Fixed vs Open” diff list — without editing files.)

---

## 2) BACKEND AUTH MIDDLEWARE: ensure requests do not continue after auth failure

### Risk
If `authenticate` catches an error but does not stop execution, protected routes can execute.

### What to verify
In `backend/src/plugins/jwt.ts`:
- `authenticate` should throw/return after setting reply code.
- `requireRole` should also stop execution on failures.

### Fix
- Use `throw` after setting `reply.code(401)` / `reply.code(403)`
- Or `return reply.code(...).send(...)` and ensure nothing continues.

(Your newer jwt.ts looked improved, but always confirm no route continues after rejection.)

---

## 3) FRONTEND NAVIGATION: Tab vs Route mismatch (common source of 404)

### Symptom
Profile tiles may navigate using `context.push("/client/vault")` etc while your app uses IndexedStack tabs.

### Fix Options
Option A (best UX):
- Change profile tiles to call a tab switch callback (e.g. `onNavigateTab(2)`)

Option B:
- Add missing GoRouter routes `/client/vault`, `/client/orders`, `/client/discover`, `/tailor/staff`, `/tailor/queue`

What to verify
- In `frontend/lib/main.dart`, confirm all pushed routes exist OR all taps switch tabs.

---

## 4) DATA CONSISTENCY BUG: City search using wrong DB column

### Symptom
Searching tailors by city returns wrong/empty results.

### Root Cause
Backend search filters city using `location_address` instead of `location_city`.

### Fix
In backend search query:
- Use `location_city` for city filtering

Also standardize response fields:
- API should return `city` (mapped from `location_city`) consistently.

---

## 5) ENV / CONFIG RISKS

### 5.1 Missing or wrong `.env` values breaks backend startup
#### Symptom
Backend crashes on startup if JWT secret missing or DB URL wrong.

#### Fix
Ensure backend `.env` contains:
- `DATABASE_URL`
- `DIRECT_URL`
- `JWT_ACCESS_SECRET`
- `ALLOWED_ORIGINS`

### 5.2 Frontend `.env` included in assets (security risk)
If Flutter bundles `.env` as an asset, secrets can be extracted.
Fix:
- Do not ship secrets in Flutter assets
- Use build-time config or secure remote config.

---

## 6) DEMO / MOCK FLOWS CAUSING FALSE "APP IS BROKEN" REPORTS

### Symptom
App shows fixed UI but real functionality not working if:
- demo mode stores fake tokens
- tracking uses mock data

### Fix
Either:
- implement real API calls for those screens, OR
- clearly separate "demo mode" screens and prevent real API calls

---

## 7) DATABASE / SEEDING REQUIREMENTS

### Symptom
API works but app appears empty (no orders, no tailors) if database not seeded.

### Fix
Run:
- Prisma generate + db push/migrate
- Seed script (if provided)

---

## 8) PRODUCTION READINESS CHECKLIST (do before release)

- Enforce JWT secrets (no fallback)
- Remove MOCK_FIREBASE / demo bypass for production
- Restrict CORS origins for production domain(s)
- Enable rate limiting in production
- Centralize error responses (avoid leaking stack traces)
- Add structured logging & monitoring (Sentry etc)
- Use HTTPS everywhere
- Ensure DB migrations are repeatable
- Add CI build for backend + android release builds

---

# Quick “Do This Now” (To get APK running)
1) Fix `frontend/android/local.properties` paths exactly (Sdk + ndk dir)
2) Run:
   - `flutter clean`
   - `flutter pub get`
   - `flutter build apk --debug`
3) Install the APK:
   - `frontend/build/app/outputs/flutter-apk/app-debug.apk`

If APK installs but app crashes on phone:
- run `flutter run -d <device>` and capture logs (`adb logcat`) to identify the runtime crash.
