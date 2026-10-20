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

## Roadmap
- Phase 2: college self-registration (`collegeRequests`), separate **Owner app** (approve / suspend / stats / payments), per-college logo and theme, per-role Firestore rules.
- Phase 3: push notifications, Razorpay, lost & found, emergency alert.
