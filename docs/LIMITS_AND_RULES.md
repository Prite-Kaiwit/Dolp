# dolp limits and business rules

These are the current prototype rules. Values are enforced by AppState where
applicable; UI limits are not a substitute for server-side validation.

## Location, listings, and meetups

| Rule | Current value / behavior |
|---|---|
| Public location obfuscation | About 100–300 m offset; the location preview radius is 500 m (`kLocationPreviewRadiusMeters`). |
| Exact location visibility | Owner can access their listing. A buyer can access exact location only after an accepted agreement for that buyer and product. |
| Seller address sharing | Seller/owner only, after an accepted agreement in that conversation; address is sent to the accepted partner as a chat message. If no address was saved, the seller must type it manually. |
| Seller-home meetup | Agreement has no spot coordinates; label is generated from the product's neighborhood label. |
| Meetup scheduling | Future time, no more than 30 days ahead. |
| Place label | Required, maximum 100 characters. |
| Meetup note | Maximum 200 characters. |
| Agreed public spot | Requires a selected `GeoLocation`; it is not the seller's home address. |
| Suggested places | Public sample places (shops/mall/gas station); no campus zone or university place model. |

## Chat and reports

| Rule | Current value / behavior |
|---|---|
| Text message | Trimmed; blank text is rejected; maximum 1,000 characters, not silently truncated. |
| Image message | One image per message, maximum 5 MiB. Bytes use `Uint8List` for web compatibility. |
| Guest access | Guest cannot send messages, images, meetup proposals, or address shares. |
| Block behavior | Blocking either direction hides users' listings from each other and prevents new messages, images, meetups, or orders. Existing chat and pending orders are retained. |
| Report detail | Required and trimmed; maximum 1,000 characters. Order reports are limited to the buyer/seller pair. |
| Dispute window | Pending orders, or completed orders within 7 days, may be reported as a dispute. |
| Admin report note | Required for actions other than dismiss; UI maximum 500 characters. |
| Resolution audit | Records admin ID, note, resolution time, and order status events where order state changes. |

## Orders and accounts

- Order status values: `pending`, `completed`, `cancelled`, `disputed`.
- Payment methods are record-only choices: cash on handover or transfer on
  handover. dolp does not collect or verify payment.
- Only pending orders can be cancelled by a participant. A reason is required,
  with a maximum of 200 characters.
- Each order status transition records an `OrderEvent` with time, actor, and
  new status. A dispute retains the previous state for admin resolution.
- A new order reserves every item in that seller group atomically. Cancellation
  returns reserved listings to their prior visible/hidden state; completion
  marks them sold.
- Suspended users cannot log in, appear in nearby results, or initiate
  protected actions. Their existing pending orders are not auto-cancelled.
- Admin routes and AppState admin operations check the current role. This is
  client-side prototype authorization only.

## Reviews

- Rating must be an integer from 1 through 5.
- Comment maximum: 500 characters.
- Only the buyer or seller of a completed order may review the opposite party,
  once per reviewer per order.
- Profile averages and review counts are recalculated from actual
  `ReviewModel` records (including generated seed review records).

## Area alerts and notifications

- Radius range: 1–20 km; default 5 km.
- Categories may be empty (all categories) or a selected subset.
- New-listing alerts use the obfuscated public product location and skip the
  seller, suspended users, and blocked pairs.
- In-app notifications have per-user read state; unread messages in a chat are
  aggregated to one notification per recipient/conversation.
- Push notifications and background delivery are not implemented. Other
  prototype state persists locally; it does not sync to a backend.

## Other prototype constraints

- Mock phone/password credentials and OTP are not production authentication.
- No payment gateway, durable database, remote image storage, or server-side
  authorization is configured.
- Location, camera/photo permissions, and behavior on a physical device still
  require platform testing.
