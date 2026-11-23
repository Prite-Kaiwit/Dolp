# dolp prototype test accounts

All data below is local mock data. It is not a real account system. On first
launch the app initializes from seed fixtures; later launches restore saved
local data instead of overwriting it.

## Sign-in accounts

| Role | Phone | Password | Notes |
|---|---|---|---|
| Member / sample buyer | `0800000001` | `password123` | `user_01`; seeded with home area and enabled 5 km area alerts. |
| Member / sample seller | `0800000002` | `password123` | `user_02`; seeded with home area. |
| Admin | `0800000009` | `password123` | `admin_01`; admin-only screens and AppState actions. |

The mock OTP shown by the OTP screen is `123456`. No SMS is sent. The other
seeded profiles (`user_03`–`user_07`) provide sample listings, conversations,
reviews, and orders, but have no phone credential configured for sign-in.

## Guest

Choose **guest mode** in the app. A guest can browse prototype listings but
cannot send chat messages, propose meetups, share an address, create an order,
or submit a report.

## Test cautions

- These credentials are intentionally predictable and must never be reused in
  production.
- Mock password credentials are salted hashes in local storage; this is not
  production authentication. Account state is stored on the device.
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
