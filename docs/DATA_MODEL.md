# dolp data model

The models are typed Dart objects intended to map to backend records later.
`AppState` is the in-memory repository facade backed by an injectable local
persistence store. Local storage is prototype-only: it does not sync to a
backend/PostgreSQL and the complete payload is not encrypted.

## Identity and trust

- **`UserModel`**: `id`, `name`, `phone`, `phoneVerified`, optional private
  home coordinates and `homeLabel`, avatar, computed `rating`/`reviewCount`,
  `successfulDeals`, `role` (`guest`, `member`, `admin`), `createdAt`,
  `isSuspended`, and optional `suspensionReason`.
- **`ReportModel`**: reporter/reported user IDs, optional order/product IDs,
  typed reason and detail, status (`open`, `dismissed`, `actioned`), creation
  time, optional admin ID/note, and resolution time.
- **`ReviewModel`**: order, reviewer and reviewee IDs, 1–5 rating, tags,
  comment, and creation time. User ratings and review counts are recalculated
  from these records.

## Listings and locations

- **`ProductModel`**: descriptive listing fields, price/trade type/category/
  condition, `publicLocation`, area label, pickup preference, image data,
  seller ID/name, listing status (`active`, `reserved`, `sold`, `hidden`),
  creation time, and display counters. It has no exact coordinates/address
  field.
- **`GeoLocation`**: validated latitude/longitude value object.
- **`NearbyProduct`**: product plus calculated distance.
- **`SuggestedSpot`** (`PickupPointModel` typedef): public suggested place
  identity, label/description, coordinates, type, active flag, and hours.
- **`ProductImageData`**: either a URL or `Uint8List` memory data.
- Exact listing coordinates/address and observation notes are held separately
  in AppState's private `_exactLocationsByProductId` map. Public listing
  coordinates are obfuscated by roughly 100–300 m (within the 500 m preview
  radius); meetup agreement records do not store a seller's home coordinates.

## Conversations and meetups

- **`ChatConversation`**: one buyer/seller/product thread, product snapshot,
  peer display data, last message/time, per-user unread counters, and messages.
- **`ChatMessage`**: sender, text, timestamp, type (`text`, `image`,
  `meetupProposal`, `addressShare`, `system`), optional image bytes, meetup ID,
  and optional recipient ID for address sharing.
- **`MeetupAgreement`**: conversation/product and proposer/responder IDs,
  pickup type, place label, optional public agreed-spot location, scheduled
  time, note, status (`proposed`, `accepted`, `declined`, `superseded`), and
  response timestamps. `sellerHome` agreements have no `spotLocation`.

## Orders and notifications

- **`OrderModel`**: buyer/seller IDs, item snapshots, total, handover payment
  method, pickup type, optional agreed place/time/meetup ID, handover and
  completion timestamps, status, cancellation metadata, prior status during a
  dispute, and ordered `OrderEvent` history.
- **`OrderItemSnapshot`**: product ID, title, price, cover image, and listing
  type captured at order creation.
- **`AppNotification`**: recipient, typed category, title/body, optional
  reference, creation time, and read time.
- **`AreaAlertSubscription`**: user ID, enabled state, radius, categories, and
  center location.

## AppState collections and private state

`AppState` owns users, products, cart items, orders, reviews, reports,
conversations, meetup agreements, suggested spots, notifications, phone
credentials, private listing locations, prior listing status while reserved,
block pairs, suspension reasons, safety acknowledgments, area-alert
subscriptions, and sequence counters. Mutations and their
authorization/validation checks are centralized in AppState methods, which
are grouped by feature into `part` files under `lib/state/` (auth,
notifications, listings, orders, chat, trust & safety, and seed data). A
logged-in user ID is restored on restart; Guest sessions are not persisted.
OTP state is temporary and is never stored.

## Local persistence format

- The SharedPreferences key is `dolp.persistence.v1`; its JSON envelope has
  `schemaVersion: 1`. Missing schema versions are treated as version 0 and
  migrated through the version-1 migration hook. Unsupported future versions
  are backed up and cause the app to start from seed data.
- The envelope stores users, salted mock credential hashes, the optional
  signed-in user ID, public product data, a separate `privateProductLocations`
  map, cart product IDs, orders and events, reviews, conversations/messages,
  meetups, suggested spots, reports, blocks, suspension reasons, safety-tip
  acknowledgments, notifications, alert subscriptions, and sequence counters.
- Product and chat image bytes are stored separately from the JSON. On
  Android/iOS, image files live under the application-support
  `dolp_media` directory and JSON stores their generated file keys. On web,
  image bytes are memory-only and are lost on reload; other JSON-backed data
  remains persisted.
- A failed JSON restore backs up the original payload under a
  `dolp.persistence.corrupted.<timestamp>` preference key, then seeds the
  prototype. Writes are debounced and flushed when the app enters the
  background.
- Private exact listing addresses/coordinates are never serialized inside a
  `ProductModel`; they are stored only in the separate private-location map.
- There are no passwords. Accounts are found by phone number after Firebase
  verifies an SMS OTP, and `UserModel.authUid` records the Firebase user ID.
  Local app data is not encrypted as a whole.
- There is no backend synchronization, PostgreSQL integration, or real push
  notification delivery (FCM/APNs).

## Important relationships

- One conversation is keyed by buyer + seller + product; new opens reuse it.
- One order is created per seller and contains item snapshots for that seller.
- Creating an order reserves its products. Completion marks them sold;
  cancellation restores them, including admin cancellation after a dispute.
- An accepted meetup may be copied onto an order at creation time.
- Reviews belong to an order and may be submitted once per participant after
  completion; profile ratings are derived from reviews.
- Reports can reference a product or an order. An order dispute records the
  previous order status so an admin can restore it when closing the issue.
- Notifications reference the relevant product, chat, order, or report. Chat
  notifications aggregate while unread; opening the conversation marks its
  pending message notification read.
