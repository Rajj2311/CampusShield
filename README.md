# Chowkidar — Multi-College Hostel Management

Chowkidar is now **multi-tenant**: one app + one Firebase project serve many colleges, each with fully separate data.

## Architecture (Phase 1)
- All college data lives under `colleges/{collegeId}/...` (students, wardens, guards, workers, leaveRequests, complaints, ...). Code uses `Tenant.col('students')` (see `lib/utils/tenant.dart`).
- `colleges/{id}` holds the college profile + config: `name`, `status` (`pending|approved|suspended`), `hostels`, `workerCategories`, `geofence` (list of `{lat,lng}`), `attendanceStartHour/EndHour`.
- `colleges/{id}/settings/codes` holds that college's role codes (`warden`, `guard`, `worker`). Only that college's warden / the owner can read it. Rules verify the code at registration.
- `userIndex/{uid}` maps a login to `{collegeId, role, docId}`. Created once at registration (verified by rules), immutable afterwards.
- Users first enter a **college code** (`CollegeSelectScreen`); the college must be `approved` by the app owner.
- App owner = Firebase user with custom claim `superAdmin` (`node scripts/set_owner.js you@email.com`).

## Setup / migration of existing IILM data
1. Edit `ROLE_CODES` in `scripts/migrate_to_multicollege.js`.
2. `node scripts/migrate_to_multicollege.js --dry-run`, then run without the flag.
3. `firebase deploy --only firestore:rules,functions`
4. Run `flutter pub get && flutter analyze`.

## Phase 2: college self-registration + Owner app
- A college registers in the main app (**Register your college**) -> `collegeRequests/{uid}` (status `pending`).
- The owner approves it in `owner_app/` (login with the account that has the `superAdmin` claim). Approval creates `colleges/{code}`, the staff codes (`settings/codes`), the admin's `userIndex` entry (role `admin`) and marks the request approved.
- The college admin logs in (**College admin login**) and gets the Admin dashboard: overview counts, hostels, registration codes (warden/guard/worker) and wardens, attendance window.
- Wardens register with the warden code; guards and workers with their codes.
- Owner can suspend/reactivate a college and keep private billing notes (`settings/billing`).

### Owner app setup
1. Firebase console -> Project settings -> Add app -> Android, package `com.example.chowkidar_owner`.
2. Download the new `google-services.json` (it now contains both apps) and put its content in the `GOOGLE_SERVICES_JSON` GitHub secret.
3. `firebase deploy --only firestore:rules`
4. Push; GitHub Actions builds `chowkidar-debug-apk` (main) and `chowkidar-owner-debug-apk` (owner).

## Roadmap
- Per-college logo and theme, per-role Firestore rules.
