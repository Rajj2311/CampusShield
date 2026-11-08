# CampusShield

**CampusShield is a multi-college hostel management platform.** A college registers itself, adds its hostels, invites wardens, guards and workers with access codes, and runs daily hostel operations (attendance, leave, gate entry, complaints, notices, mess menu) from one mobile app. Every college gets its own private workspace. The platform owner approves each college and manages subscriptions from a separate Owner app.

> Formerly developed under the working name "Chowkidar". The product name everywhere users can see it is **CampusShield**.

---

## Table of contents
1. [What problem it solves](#what-problem-it-solves)
2. [Main features](#main-features)
3. [How it works (full workflow)](#how-it-works-full-workflow)
4. [Roles and permissions](#roles-and-permissions)
5. [Advantages](#advantages)
6. [Why the name "CampusShield"](#why-the-name-campusshield)
7. [Similar apps that exist](#similar-apps-that-exist)
8. [How CampusShield compares](#how-campusshield-compares)
9. [Payments and subscriptions](#payments-and-subscriptions)
10. [Architecture and data model](#architecture-and-data-model)
11. [Security model](#security-model)
12. [Tech stack](#tech-stack)
13. [Project structure](#project-structure)
14. [Setup, build and deploy](#setup-build-and-deploy)
15. [Known limitations and roadmap](#known-limitations-and-roadmap)
16. [Sources](#sources)

---

## What problem it solves
Most college hostels still run on paper registers, WhatsApp groups and phone calls:

- Night attendance is taken by hand and can be faked (a friend answers "present").
- Leave and outing approvals are slow, and the gate guard has no reliable way to verify them.
- Complaints (water, electricity, cleaning) get lost, and nobody can prove they were fixed.
- Wardens, guards and maintenance staff each keep their own records, so nobody sees the full picture.
- Software that does exist is usually a heavy ERP sold to one college at a time.

CampusShield puts all of this in one app, and lets any college start using it on its own without installing anything on a server.

---

## Main features

### Students
- Register with college code and roll number; log in on an approved device.
- **Location-based attendance**: marked only inside the college's real campus boundary (polygon geofence) and only during the attendance window the college sets.
- **Device binding**: an account works on the approved phone; a new device needs warden approval, which stops proxy attendance from someone else's phone.
- **Leave requests** with a **QR pass** that the gate guard scans.
- **Complaints** with photos, a category (plumbing, electrical, cleaning, ...) and live status; the student verifies the fix before it is closed.
- Notices, mess menu, notifications and profile.

### Wardens
- Dashboard with live counts: students, pending leaves, open complaints, students currently out.
- Attendance view and attendance history.
- Approve or reject leave requests; gate approvals; device-change approvals.
- Complaints management; post notices; edit the mess menu.
- **Import students in bulk** from an Excel or CSV file.
- Activity feed of everything happening in the hostel.

### Guards
- **QR scanner** to check students out and in at the gate.
- Gate history and a list of students currently outside.

### Workers (maintenance staff)
- See complaints assigned to their category (for example electrician, plumber).
- Accept a job, upload a proof photo after fixing it, and mark it resolved; the student confirms.

### College Admin (new in the multi-college version)
- Self-register the college and see approval status.
- Overview counts, add or remove hostels.
- **Access codes** for warden, guard and worker; regenerate any time; remove wardens.
- **People tab**: view, search, edit and delete students, wardens, guards, workers, complaints, leaves and notices across all hostels of the college.
- Set the attendance window; see subscription validity and payment receipts.

### Owner app (separate app, only for the platform owner)
- Review college registration requests with the payment the college submitted.
- **Approve with payment verification**: creates the college, the staff codes, the admin access, a receipt and the expiry date.
- Reject with a reason shown to the applicant.
- Full access to every college: browse, add, edit and delete any data; edit college profile.
- Renew, set or remove expiry, suspend, reactivate, or permanently delete a college.
- Payment settings: UPI ID, bank details, contact numbers, instructions, and the plans and fixed prices.
- Receipts and total received across all colleges.

### Platform features
- Per-college customisation: hostel list, worker categories, campus boundary, attendance hours.
- Nightly automatic reset of daily attendance for all active colleges.
- Notifications inside the app.
- Everything in the app is in English.

---

## How it works (full workflow)

```
COLLEGE ADMIN                        OWNER                         COLLEGE USERS
-------------                        -----                         -------------
1. Install the app
2. Register your college
   (details, hostels, plan)
3. Pay the fixed plan price
   by UPI QR / UPI app / bank
4. Submit payment reference ----->   5. See request + payment
                                     6. Verify payment, Approve
                                        -> college workspace created
                                        -> staff codes generated
                                        -> receipt + expiry date set
7. Admin dashboard opens  <---------
8. Add hostels
9. Share warden / guard /
   worker codes ------------------------------------------------>  10. Staff register with the code
                                                                    11. Warden imports students
                                                                    12. Students create accounts
                                                                    13. Daily operations start

When the subscription expires: everyone in that college is blocked, the admin sees how to renew.
Owner records the new payment -> access returns immediately.
```

---

## Roles and permissions

| Role | Can do | Cannot do |
|---|---|---|
| Student | Own attendance, leave, complaints, notices, mess menu | See other students' data |
| Warden | Hostel operations for the college | Change subscription or other colleges |
| Guard | Scan gate QR, view gate history | Edit records |
| Worker | Handle complaints in own category | See student personal data beyond the complaint |
| College Admin | Everything inside their own college | Change status, expiry or receipts; touch other colleges |
| Owner | Everything, on every college | (full access) |

---

## Advantages
- **Self-serve for colleges**: a college can sign up, pay and start without a sales visit or a server install.
- **One app for every college**: one codebase and one backend serve IILM, NIET, GL Bajaj or any other college, with fully separate data.
- **Harder to cheat**: polygon geofence + time window + device binding for attendance; QR-verified gate passes.
- **Accountable maintenance**: complaint, assignment, proof photo and student verification are all recorded.
- **Simple for the owner**: approve colleges, record payments, issue receipts and fix any data from your phone.
- **Low running cost**: built on Firebase (serverless), so there are no servers to maintain.
- **Per-college control**: each college sets its own hostels, codes, attendance hours and campus boundary.
- **Safe by design**: separate data per college enforced in the database rules, not only in the app.
- **Whole workflow in one place**: students, wardens, guards, workers and the college admin share the same live data.

---

## Why the name "CampusShield"
- **Campus** says what it is for (the whole campus and every college), and is easy to say and spell for any student, parent or administrator across India.
- **Shield** says what it delivers: safety and security of students, a protected gate, a protected boundary, and protected data. It also matches the logo (a shield with a hostel building inside).
- It works for **every role**, not just one. The earlier working name, a Hindi word for a watchman, described only the guard and sounded like a single-gate security tool, not a full hostel platform.
- It is **neutral across languages and regions**, which matters when colleges from different states adopt it.
- It reads as a **product brand**, so it can grow (a parent app, fee module, analytics) without a rename.

> Before publishing on the Play Store or App Store, check that the name is free to use (store search, domain, and the trademark register).

---

## Similar apps that exist
The table below lists products and apps found in public listings and vendor websites (searched November 2026). Features and availability are as the vendors describe them; check each store page for the current state, price and ratings.

| Product | Type | What it offers (per its own site) | Mobile app |
|---|---|---|---|
| **SpaceBasic** | Hostel management for universities, colleges and schools | Student, parent, warden and staff apps; leave, attendance, maintenance tickets, mess, fee payments, multi-hostel | Google Play and Apple App Store |
| **RentOk** | Rental, PG and hostel management | Bookings, rent collection, tenants, accounting | Google Play |
| **FretBox** | University hostel management | Positions itself for university admins and wardens | See vendor site |
| **Camu (MyCamu)** | Campus ERP | Hostel management module inside a larger campus platform | See vendor site |
| **Fedena** | School and college ERP | Hostel management module | See vendor site |
| **OpenEduCat** | Open-source education ERP | Hostel management solution | Web, mobile varies |
| **Odoo education hostel modules** | ERP add-ons | Hostel add-on modules for Odoo | Web |
| **AIMIT Hostels** | Single-institution app | A hostel app for one institute, listed on the App Store | Apple App Store |

Other products on the web such as Cloudbeds, Sirvoy, Beds24 and similar are **travel-hostel booking systems** (reservations and channel managers). They solve a different problem and are not direct alternatives for a college hostel.

---

## How CampusShield compares
- **Versus full ERPs (Camu, Fedena, OpenEduCat, Odoo):** those are large systems sold per institution, where hostel is one module. CampusShield is focused on the hostel, is light, and onboards a college by itself.
- **Versus SpaceBasic and FretBox:** direct competitors for university hostels. CampusShield's focus is the multi-college self-registration with owner approval and subscription control, polygon-geofence attendance with device binding, QR gate pass, and a maintenance workflow with proof photos. SpaceBasic currently lists things CampusShield does not have yet (parent app, in-app fee payments, mess bookings, Smart IDs).
- **Versus RentOk:** RentOk is mainly for rent, bookings and tenants of private hostels and PGs; CampusShield is for institutional hostels with wardens, guards and attendance.

---

## Payments and subscriptions
- The owner sets the plans (for example Basic and Advanced), their **fixed price** and duration in months. Colleges cannot edit the amount.
- The college sees a **UPI QR code and a "Pay with UPI app" button** with the plan amount already filled in, plus bank details and contact numbers.
- After paying, the college submits the payment method and reference (UTR). Payment is **verified by the owner** (there is no payment gateway yet), who then approves and a receipt is created (`CSH-<date>-<code>`).
- Each college has an `expiresAt` date. After expiry or suspension the college is blocked; the admin sees the renewal screen and past receipts.
- Existing colleges without an expiry date keep working until the owner sets one.

---

## Architecture and data model
- One Firebase project; all college data under `colleges/{collegeId}/...` (students, wardens, guards, workers, leaveRequests, complaints, notices, activity, and so on).
- `colleges/{id}`: public profile and config (name, status, hostels, worker categories, geofence, attendance hours, plan, `expiresAt`).
- `colleges/{id}/settings/codes`: role codes. `settings/contact`: admin contact. `settings/billing`: owner-only notes.
- `receipts/{receiptNo}`: payment receipts (owner writes; the college admin can read its own).
- `collegeRequests/{uid}`: registration requests and the submitted payment details.
- `userIndex/{uid}`: maps a login to `{collegeId, role, docId}`; created once and checked by the rules.
- `appConfig/payment`: payment details and plans shown to colleges.
- The code uses `Tenant.col('students')` so every query is automatically scoped to the active college.
- A scheduled Cloud Function resets daily attendance for every active college each night.

---

## Security model
- **Isolation in the database rules**: a signed-in user can only read or write the college stored in their own `userIndex` entry.
- **Role codes are verified by the rules**, not the client, when staff register.
- **The owner is a Firebase user with a custom claim** (`superAdmin`); the Owner app refuses any other account.
- **The college admin cannot change** the status, expiry or receipts of their own college.
- **Subscription is enforced in the rules** (status `approved` and not expired), not just on screen.
- Student login lookups are limited to single-document queries.

---

## Tech stack
- **App:** Flutter (Dart), Material 3. Two apps: the main app and the Owner app.
- **Backend:** Firebase Authentication, Cloud Firestore, Cloud Storage, Cloud Functions (scheduled job).
- **Key packages:** `geolocator` (location), `mobile_scanner` and `qr_flutter` (QR), `excel` and `file_picker` (bulk import), `device_info_plus` (device binding), `url_launcher` (UPI app), `image_picker` (photos).
- **CI:** GitHub Actions builds both Android APKs.

---

## Project structure
```
lib/                    main app
  screens/              student, warden, guard, worker, admin, college (register, status, payment)
  utils/                tenant.dart, payment_config.dart, geofence, device helper
  widgets/              shared UI
owner_app/              separate Owner app (own pubspec, android folder)
functions/              Cloud Functions (nightly reset)
scripts/                migrate_to_multicollege.js, set_owner.js
firestore.rules         security rules (multi-college, roles, subscription)
.github/workflows/      build-apk.yml (builds both apps)
assets/images/          logo and mark
```

---

## Setup, build and deploy
1. **Firebase**: create the project, enable Authentication (email/password) and Firestore. Register two Android apps: the main app (`com.example.chowkidar`) and the Owner app (`com.example.chowkidar_owner`). These internal IDs are kept so existing installs and logins keep working.
2. **Owner account**: create the owner user, then run `node scripts/set_owner.js owner@email.com` (needs a service account key) to give it the `superAdmin` claim. Sign out and in once after that.
3. **Rules**: `firebase deploy --only firestore:rules` (deploy again after any rules change).
4. **GitHub secret**: `GOOGLE_SERVICES_JSON` = the full `google-services.json` that contains both apps.
5. **Build**: push to GitHub; Actions produces `campusshield-debug-apk` and `campusshield-owner-debug-apk`.
6. **First setup**: in the Owner app open Payments, then Payment settings, and enter your UPI ID, bank details, contact details and plan prices.
7. **First college**: register a test college in the main app, approve it from the Owner app, then log in as that college admin.
8. **Legacy data**: `scripts/migrate_to_multicollege.js` moved the original single-college data into `colleges/iilm`.

Local build: `flutter pub get`, then `flutter build apk`. A low-memory machine may need the CI build instead.

---

## Web version (Vercel)
The main app also runs in the browser.
- GitHub Actions (`deploy-web.yml`) builds the web app on every push to `main` and publishes the result to the `vercel-web` branch.
- Deploy that branch to Vercel as a static site (Framework: Other, no build command). `web_deploy/vercel.json` adds the single-page-app rewrite.
- Web notes: location attendance needs HTTPS and the browser's location permission (accuracy is lower than a phone); gate QR scanning is best done in the Android app.

---

## Known limitations and roadmap
**Not built yet**
- Online payment gateway (payments are verified manually by the owner).
- PDF receipts (receipts are shown and can be copied as text).
- Parent app, hostel fee collection inside the app, mess meal booking.
- iOS build and store release; current outputs are Android debug APKs.
- Per-college logo and theme; email or SMS notifications.
- Analytics dashboards for the owner.

**Before going public**
- Create a release build with a proper signing key and publish to the Play Store.
- Set a custom Android package name and Firebase "public-facing name" (so reset emails say CampusShield).
- Add a privacy policy and terms (the app stores location, photos and personal data).
- Check the CampusShield name and trademark availability.

---

## Sources
- SpaceBasic hostel management app: https://www.spacebasic.com/hostel-management-system/apps
- RentOk: https://wb.rentok.com/growth/best-university-hostel-management-system-in-india-2023/
- FretBox: https://www.fretbox.in
- Camu hostel management: https://camu-website.web.app/hostel-management-system
- Fedena hostel management: https://www.fedena.com/feature-tour/hostel-management-system
- OpenEduCat hostel management: https://openeducat.org/zh/solutions/hostel-management-system/
- AIMIT Hostels (App Store): https://apps.apple.com/us/app/-/id6720760547
- Odoo education hostel module: https://apps.odoo.com/apps/modules/16.0/education_hostel
- Travel-hostel software list (Capterra): https://www.capterra.in/directory/31457/hostel-management/software
