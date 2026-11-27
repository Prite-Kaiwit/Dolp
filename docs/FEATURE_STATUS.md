# dolp feature status

Status snapshot for the current dolp prototype after Phase 8
(local persistence). The repository has no source SRS document, so FR-01–FR-11
below are a provisional crosswalk based on the phase requirements and current
code, not a reconstruction of missing SRS wording. The implementation includes
the community location model, handover orders, review/trust features,
notifications, admin guards, and local persistence.

## Functional requirements

| ID | Requirement / phase change | Status |
|---|---|---|
| FR-01 | Phone-based sign-in, registration, and OTP | Implemented with Firebase phone authentication (Android and web). Tested with Firebase test numbers; real SMS needs the Blaze plan. Builds without Firebase accept the fixed code `123456`. |
| FR-02 | Replace campus zones with location, distance, radius, and nearby filters | Implemented. Public listing locations are obfuscated; GPS is not allowed to override a saved home-area reference silently. |
| FR-03 | Buyer–seller chat and meetup proposals | Implemented locally, including text, images, agreement responses, and private address sharing after an accepted agreement. |
| FR-04 | Create, edit, hide, reserve, and browse sale/trade/donation listings | Implemented locally. Listing images may use URLs or bytes; no remote storage. |
| FR-05 | Cart and one order per seller | Implemented. Items are reserved on order creation and restored or sold on terminal transitions. |
| FR-06 | Replace escrow with cash or transfer at handover | Implemented as order metadata only. The app does not collect, transfer, or verify payments. |
| FR-07 | Review the other party after a completed order | Implemented locally. Seed reviews are represented by `ReviewModel`; displayed ratings are calculated from review records. |
| FR-08 | Replace campus pickup points with flexible meetup agreements | Implemented: seller home, suggested public places, and mutually agreed places. Seller-home agreements do not retain coordinates. |
| FR-09 | Block users, report users/orders, manage disputes, and suspend accounts | Implemented for the prototype. Blocking/suspension do not automatically cancel an existing pending order. |
| FR-10 | In-app notifications and nearby listing subscriptions | In-app delivery and read state persist locally. Push delivery (FCM/APNs) is not implemented. |
| FR-11 | Admin dashboard, user management, and report/dispute actions | Implemented with AppState role checks and UI route guards. Not a server-side authorization boundary. |

## Non-functional requirements

| Area | Status / limitation |
|---|---|
| Privacy | Public product coordinates are offset by about 100–300 m, within a 500 m preview radius. Exact listing location/address is held in an AppState private map and may be shared to the accepted meetup partner only. No exact-address navigation feature is provided. |
| Security | Prototype-only. Firestore rules require Firebase anonymous sign-in, which blocks access from outside the app but cannot tell dolp users apart. Mock credentials use local salted hashes and admin checks run in the client; neither is suitable for production authorization. |
| Persistence | Shared data syncs through Cloud Firestore (project `dolp-app-1696-9fd78`), one document per record, via `FirestorePersistenceStore`. The signed-in user, cart and ID sequences stay on-device. Builds without Firebase config (Windows, macOS, Linux, iOS) fall back to local JSON. |
| Auditability | Order status changes record `OrderEvent`; report decisions record the admin and resolution time. Records persist locally but are not server-audited. |
| Compatibility | Flutter analysis and 86 tests pass. Android debug APK and web builds pass. Pixel 6 and full physical-device validation remain outstanding. |
| Accessibility | Ocean-blue brand theme and contrast tests exist. Screen-reader and physical display validation remain outstanding. |
| Scalability/performance | No backend, pagination, or load testing. Data sets are small local prototype fixtures. |
| Notifications | Nearby and transactional notifications are generated locally and persist on-device. Delivery while the app is closed is not supported. |

### Local persistence limitations

The prototype stores structured state in local device preferences and image
bytes in app support files on Android/iOS. Web builds persist structured state
but keep image bytes in memory only, so image uploads do not survive a web
reload. Local data is not synchronized, is not encrypted as a whole, and is
not a substitute for backend storage or authorization. There are no passwords;
OTP state is temporary and is not persisted.

## Verification

For this snapshot:
- `flutter pub get` succeeds.
- `flutter analyze` reports no issues.
- `flutter test` passes all 86 tests.
- `flutter build apk --debug` and `flutter build web` succeed.
- Full physical-device interaction, permission prompts, real GPS, push delivery,
  SMS OTP, and server authorization remain environment/backend work rather than
  completed local verification.
