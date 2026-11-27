# dolp prototype test accounts

Sign-in uses Firebase phone authentication. The numbers below are registered
as **test phone numbers** in the Firebase console, so no SMS is sent and the
code is always `123456`. Sending SMS to real numbers needs the Firebase Blaze
plan.

## Sign-in accounts

| Role | Phone | Firebase test number | Notes |
|---|---|---|---|
| Member / sample buyer | `0800000001` | `+66 80 000 0001` | `user_01`; seeded with home area and enabled 5 km area alerts. |
| Member / sample seller | `0800000002` | `+66 80 000 0002` | `user_02`; seeded with home area. |
| Admin | `0800000009` | `+66 80 000 0009` | `admin_01`; admin-only screens and AppState actions. |

Debug builds also show sample-account buttons on the login screen that skip
the OTP step. The other seeded profiles (`user_03`–`user_07`) provide sample
listings, conversations, reviews, and orders, but have no test number.

## Guest

Choose **guest mode** in the app. A guest can browse prototype listings but
cannot send chat messages, propose meetups, share an address, create an order,
or submit a report.

## Test cautions

- Test numbers are intentionally predictable; remove them before real use.
- Firestore rules admit any signed-in client, so any signed-in user can still
  read and write all data until per-user rules are added.
- Admin role checks are not a substitute for authenticated server-side access
  control.
- Seed fixtures can be changed by tests during a run. Reinitializing AppState
  restores persisted state rather than reseeding it.

## Resetting local data for QA

- In debug builds, open the profile screen and use **Reset sample data**. This
  clears local persistence and returns the app to its seeded Guest state.
- Alternatively, clear the app's storage/data from the device or emulator's
  system app settings, then relaunch to create a fresh seeded state.
- Web image bytes are memory-only and do not survive a reload; structured
  local data persists in browser storage.
