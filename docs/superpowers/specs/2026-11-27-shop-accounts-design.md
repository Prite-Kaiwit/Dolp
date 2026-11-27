# Shop accounts

## Intent
When someone needs an item urgently, they don't know whether a shop in their
province or nearby sells it, so they order from a big online platform and wait
for shipping. Dolp should help them find nearby shops that are likely to have
the item, then ask the shop directly in chat. Chat is the source of truth for
"do you have it": the app only has to surface the right shops quickly.

Today every account is a person selling second-hand items one at a time. Shops
sell many items, often have stock they never post, and need a separate identity
so buyers can tell a shop from a neighbour.

## Goals
- At sign-up, the user picks an account type: **person** or **shop**.
- A person account can switch to a shop later from the profile screen.
- A shop has a public profile: shop name, description of what it sells,
  categories it sells in, shop location, opening hours.
- Shops post their own listings with the existing create-listing flow.
- Buyers find shops by:
  - listings the shop posted (title, description, category), and
  - the shop's description and categories, even when no listing matches.
- Search shows nearby shops sorted by distance, with "open now / closed"
  status, and a "ask the shop" button that opens a chat.
- Buyers can chat with a shop **without a specific listing** to ask about
  items that aren't posted.
- Listings and cards show a "shop" badge so buyers can tell shops from people.

## Non-goals
- Asking several shops at once (broadcast). Maybe later if one-by-one is too slow.
- Stock counts on listings. Chat confirms availability.
- Staff accounts, multiple shops per owner, shop verification documents.
- Delivery or shipping. Pickup and walk-in stay the only ways to get items.
- Separating shops and people into different home feeds.

## Anti-goals
- The app claims a shop has an item or is open when it isn't. Opening status
  must come from the hours the shop entered, labelled as such, never implied
  stock.
- Breaking existing person accounts, login, or seed/test accounts.
- A shop's listings getting mixed with a person's personal listings (that is
  why account type is chosen up front). Converting person → shop is the
  user's own choice to turn their account into a shop, so carrying their
  listings over is intended, not a mix.

## Constraints
- Flutter app, state in `AppState` extensions (`lib/state/`), persisted via
  `PersistenceStore` (in-memory, shared_preferences, Firestore).
- **One phone number = one account.** Login looks up the account by phone
  (`AppStateAuth.signInVerifiedPhone`, `isPhoneRegistered`). This stays: a shop
  owner who also wants a personal account uses a second number (shop phone).
- Firestore rules are prototype-wide (`firestore.rules`); no per-user rules to
  update for this feature.
- Chats are currently always tied to a product
  (`AppStateChat.openConversationForProduct`, `ChatConversation.productId`).

## Approaches
1. **Account type on the user (chosen by user).** Add an account type and shop
   profile fields to `UserModel`. Chat, listings, orders and reviews keep
   working because a shop is still a user. Downside (shop and owner are one
   account) is removed by choosing the type at sign-up.
2. Separate `ShopModel` owned by a user, listings carry `shopId`. Cleaner split
   and room for staff/multiple shops, but a new collection and shop-aware chat,
   listings and orders. Rejected: more work than needed now.
3. Throwaway UI spike first. Not chosen.

Phone handling: keep one phone per account (chosen by user) rather than letting
one phone own both a person and a shop account.

## Design

### Data
`lib/models/user.dart`
- `enum AccountType { person, shop }`, field `accountType` (default `person`,
  JSON default `person` so existing data loads unchanged).
- `ShopProfile? shop` (null for people), new model in
  `lib/models/shop_profile.dart`:
  - `shopName` (display name; `UserModel.name` stays the owner's name)
  - `description` (what the shop sells, free text)
  - `categories` (`List<String>`, from the shared category list)
  - `location` (`GeoLocation`) and `locationLabel`
  - `openingHours`: per weekday open/close times or closed
    (`Map<int, ...>` or a small `OpeningHours` class)
- `toJson` / `fromJson` / `copyWith` updated.
- Helper `bool get isShop` and `String get displayName` (shop name for shops,
  name for people).

`lib/models/chat.dart`
- Allow a conversation with no product (`productId` empty) for shop
  inquiries. Add `bool get isShopInquiry`.

### Shared constants
- Move the category list now hard-coded in `SearchFilterScreen._categories`
  and `CreateListingScreen` into `lib/constants/` so sign-up, shop profile,
  search and listing use one list.
- Shop limits (`lib/constants/shop_limits.dart`): max shop name / description
  length, max categories.

### State
`lib/state/app_state_auth.dart`
- `registerVerifiedPhone` takes `accountType` and an optional `ShopProfile`.
- New `convertCurrentUserToShop(ShopProfile)`; existing listings stay and now
  show as the shop's (agreed with user). Open orders, meetups and chats carry
  on unchanged.
- One-way in v1: no shop → person switch (builder's call; can be added later
  because `shop` data is kept on the user).
- Shops can still buy and chat as buyers; no guards added (builder's call).
- Shop setup is mandatory: an account with `accountType == shop` must have a
  complete `ShopProfile` (name, at least one category, location, hours for at
  least one day). Registration as a shop collects the profile before the
  account is created, so `accountType == shop && shop == null` cannot happen
  for new accounts. If it ever occurs in stored data, treat the account as a
  person everywhere (`isShop` requires `shop != null`) (builder's call).
- New `updateShopProfile(ShopProfile)`.

`lib/state/app_state_listings.dart`
- New `shopsNearby({radiusKm, query, category, openNowOnly})` returning shops
  with distance, open-now status and number of matching listings. A shop
  matches when any of its active listings matches the query **or** its name,
  description or categories match.
- `productsNearby` gains an optional `sellerKind` filter (all / shops / people).

`lib/state/app_state_chat.dart`
- New `openShopInquiry(shopUserId)`: reuse an existing inquiry chat with that
  shop or create one with no product. Meetup and order actions are hidden in
  inquiry chats (no product to agree on); if the shop has the item it can post
  it and the buyer orders from the listing, or the buyer walks in.
- Code that reads `conversation.productId` (meetup, address sharing, header)
  must handle the empty case.

`lib/state/app_state_seed.dart`
- Add 2–3 seed shops near the default centre with hours, categories and a
  few listings; document them in `docs/TEST_ACCOUNTS.md`.

Names: `ProductModel.sellerName` and `ChatConversation.peerName` are stored
copies. Screens show the seller/peer name by live lookup
(`userById(...)?.displayName`, falling back to the stored copy), so
converting or renaming a shop needs no rewrite of products or chats
(builder's call).

Persistence: no new collection; shop data lives on the user document. Check
the Firestore and shared_preferences round-trip tests cover the new fields.

### Screens
- `screens/auth/sign_up_screen.dart`: account-type choice (person / shop)
  before the phone step.
- New `screens/auth/shop_setup_screen.dart` (also used for "switch to shop"
  and "edit shop"): shop name, description, categories, location picker
  (reuse `widgets/location_picker.dart`), opening hours.
- Sign-up order for shops: choose type → shop setup → phone + OTP → account
  created with the profile.
- `screens/auth/phone_otp_screen.dart`: pass account type and shop profile to
  `registerVerifiedPhone`.
- Opening status is labelled as the shop's stated hours ("ตามเวลาที่ร้านแจ้ง"),
  computed in Thailand time.
- `screens/profile/profile_screen.dart`: "switch to shop" for people,
  "edit shop" for shops.
- New `screens/profile/shop_profile_screen.dart` (public storefront): name,
  description, categories, hours with open-now, distance, listings, reviews,
  "ask the shop" button. `public_user_profile_screen.dart` routes shops here.
- `screens/home/search_filter_screen.dart`: toggle between items and shops,
  "open now" filter, shop result cards with "ask the shop".
- `widgets/product_card.dart`, `screens/home/product_detail_screen.dart`:
  shop badge and shop name; detail screen links to the storefront.
- `screens/chat/chat_room_screen.dart`, `chat_list_screen.dart`: handle
  inquiry chats (no product header, no meetup/order actions, shop name shown).

### Tests
- Model JSON round trip with and without shop data; old JSON loads as person.
- Register as shop, convert person to shop, edit shop.
- `shopsNearby`: match by listing, by description/category only, radius,
  open-now, suspended/blocked shops excluded.
- Inquiry chat: create, reuse, no meetup/order.
- Widget tests: sign-up type choice, shop setup, search shop results,
  storefront, badge on card. Layout overflow test for new screens.

## Left to the builder
- Exact opening-hours model and editor UI (keep it simple: per weekday
  open/close or closed).
- Visual design of the shop badge and storefront within `AppTheme`.
- Whether search shows items and shops as tabs or a toggle.
- Wording of the auto-filled first inquiry message.
