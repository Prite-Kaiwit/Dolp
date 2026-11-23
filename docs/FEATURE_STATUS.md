# dolp feature status

Status snapshot for the phase-7 prototype. The repository has no source SRS
document, so FR-01–FR-11 below are a provisional crosswalk based on the phase
requirements and current code, not a reconstruction of missing SRS wording.
The existing `Seed Conversations (FR-03)` comment supports the FR-03 mapping.

## Functional requirements

| ID | Requirement / phase change | Status |
|---|---|---|
| FR-01 | Phone-based sign-in, registration, and mock OTP | Implemented for prototype. Credentials and OTP are local mocks; no SMS provider or backend. |
| FR-02 | Replace campus zones with location, distance, radius, and nearby filters | Implemented in memory. Public listing locations are obfuscated; device and backend behavior still needs integration testing. |
| FR-03 | Buyer–seller chat and meetup proposals | Implemented in memory, including text, images, agreement responses, and private address sharing after an accepted agreement. |
| FR-04 | Create, edit, hide, reserve, and browse sale/trade/donation listings | Implemented in memory. Listing images may use URLs or bytes; no remote storage. |
| FR-05 | Cart and one order per seller | Implemented in memory. Items are reserved on order creation and restored or sold on terminal transitions. |
| FR-06 | Replace escrow with cash or transfer at handover | Implemented as order metadata only. The app does not collect, transfer, or verify payments. |
| FR-07 | Review the other party after a completed order | Implemented in memory. Seed reviews are represented by `ReviewModel`; displayed ratings are calculated from review records. |
| FR-08 | Replace campus pickup points with flexible meetup agreements | Implemented in memory: seller home, suggested public places, and mutually agreed places. Seller-home agreements do not retain coordinates. |
| FR-09 | Block users, report users/orders, manage disputes, and suspend accounts | Implemented for the prototype. Blocking/suspension do not automatically cancel an existing pending order. |
| FR-10 | In-app notifications and nearby listing subscriptions | In-app delivery and read state are implemented in memory. Push delivery (FCM/APNs) is not implemented. |
| FR-11 | Admin dashboard, user management, and report/dispute actions | Implemented with AppState role checks and UI route guards. Not a server-side authorization boundary. |

## Non-functional requirements

| Area | Status / limitation |
|---|---|
| Privacy | Public product coordinates are offset by about 100–300 m, within a 500 m preview radius. Exact listing location/address is held in an AppState private map and may be shared to the accepted meetup partner only. No exact-address navigation feature is provided. |
| Security | Prototype-only. Data and mock credentials are local/in-memory; admin checks run in the client and are not suitable for production authorization. |
| Persistence | Partially implemented on-device with schema-versioned local JSON. Data does not sync, use PostgreSQL, or encrypt the complete stored payload. |
| Auditability | Order status changes record `OrderEvent`; report decisions record the admin and resolution time. Records persist locally but are not server-audited. |
| Compatibility | Flutter test suite covers core flows. Physical Pixel 6/device validation has not been performed in this environment. |
| Accessibility | Ocean-blue brand theme and contrast tests exist. Screen-reader and physical display validation remain outstanding. |
| Scalability/performance | No backend, pagination, or load testing. Data sets are small local prototype fixtures. |
| Notifications | Nearby and transactional notifications are generated locally and persist on-device. Delivery while the app is closed is not supported. |

### Local persistence limitations

The prototype stores structured state in local device preferences and image
bytes in app support files on Android/iOS. Web builds persist structured state
but keep image bytes in memory only, so image uploads do not survive a web
reload. Local data is not synchronized, is not encrypted as a whole, and is
not a substitute for backend storage or authorization. Mock passwords are
salted and hashed locally; production authentication must verify credentials
server-side. OTP state is temporary and is not persisted.

## Verification

`flutter pub get`, `flutter analyze`, and the complete `flutter test` suite are
the release checks for this snapshot. See the phase-7 completion summary for
the exact results and any device-only checks not performed.
