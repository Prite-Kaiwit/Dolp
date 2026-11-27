# dolp — ตลาดมือสองใกล้บ้าน

dolp is a Flutter prototype of a neighborhood marketplace for selling, trading,
and donating second-hand items. Buyers find listings within a chosen radius,
chat with the seller, agree on a meetup, and pay cash or transfer at handover.

> **Prototype only.** Shared data is stored in Cloud Firestore (Android and
> web); the signed-in session stays on the device. The app signs in to
> Firebase anonymously and Firestore rules only admit signed-in clients, but
> dolp's own login is still mocked, so any app install can read and write all
> data. Use test data only.
> Sign-in uses Firebase phone OTP; admin checks still run in the client.
> See [docs/FEATURE_STATUS.md](docs/FEATURE_STATUS.md) for what is and isn't
> implemented.

## Features

- Phone sign-in and registration with Firebase SMS OTP, plus guest browsing
- Nearby listings by distance/radius on an OpenStreetMap map; public listing
  locations are offset ~100–300 m for privacy
- Sale, trade, and donation listings with photos
- Buyer–seller chat with images, meetup proposals, and address sharing after
  an accepted agreement
- Cart with one order per seller; items are reserved until completion or
  cancellation
- Reviews, blocking, reports, disputes, and account suspension
- In-app notifications and area alerts for new nearby listings
- Admin dashboard for users, reports, and disputes

## Getting started

Requires the Flutter SDK (Dart `^3.12.1`).

```sh
flutter pub get
flutter run
```

Test accounts (Firebase test numbers, OTP `123456`): member `0800000001`, seller
`0800000002`, admin `0800000009`. Details in
[docs/TEST_ACCOUNTS.md](docs/TEST_ACCOUNTS.md).

## Checks

```sh
flutter analyze
flutter test
```

## Project layout

| Path | Contents |
|---|---|
| `lib/state/` | `AppState`, the single app-wide `ChangeNotifier`. The core file holds fields, persistence, and lifecycle; feature logic lives in `part` files (`app_state_auth`, `_listings`, `_orders`, `_chat`, `_notifications`, `_trust_safety`, `_seed`). |
| `lib/models/` | Typed models with JSON serialization |
| `lib/persistence/` | Pluggable stores: in-memory (tests) and SharedPreferences + media files (app) |
| `lib/screens/` | UI by area: auth, home, chat, order, profile, review_safety, admin |
| `lib/widgets/` | Shared widgets (product card, map, location picker, …) |
| `lib/constants/` | Limits and app constants |
| `test/` | Unit and widget tests |
| `docs/` | Data model, feature status, business rules, test accounts |

## Documentation

- [Data model](docs/DATA_MODEL.md)
- [Feature status](docs/FEATURE_STATUS.md)
- [Limits and business rules](docs/LIMITS_AND_RULES.md)
- [Test accounts](docs/TEST_ACCOUNTS.md)
- [Survey (24 Nov 2026 snapshot, written under the former name MoorMarket)](docs/MOORMARKET_CURRENT_SURVEY.md)
