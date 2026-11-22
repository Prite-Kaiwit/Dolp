# dolp data model

The models are typed Dart objects intended to map to backend records later.
`AppState` is the current in-memory repository and is reset from seed data on
initialization; this is not durable storage.

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
conversations, meetup agreements, suggested spots, and notifications. It also
keeps in-memory phone credentials, private listing locations, prior listing
status while reserved, block pairs, area-alert subscriptions, and the testable
clock. Mutations and their authorization/validation checks are centralized in
AppState methods.

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
