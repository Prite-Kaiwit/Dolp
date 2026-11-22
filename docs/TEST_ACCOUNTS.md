# dolp prototype test accounts

All data below is local mock data. It is not a real account system. The app
resets its state to seed fixtures when AppState is initialized.

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
- Passwords and account state are held only in the local AppState mock.
- Admin role checks are not a substitute for authenticated server-side access
  control.
- Seed fixtures can be changed by tests during a run and are restored by
  reinitializing AppState.
