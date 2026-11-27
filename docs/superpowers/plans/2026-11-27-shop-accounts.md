# Shop Accounts Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Let users register (or convert to) shop accounts with a public storefront, so buyers can find nearby shops likely to have an item and ask them in chat.

**Architecture:** A shop is still a `UserModel` with `accountType == shop` and a `ShopProfile`. Search gains `shopsNearby`, chat gains product-less "shop inquiry" conversations, and UI adds shop setup, storefront, search toggle and a shop badge. No new Firestore collection.

**Tech Stack:** Flutter/Dart, `AppState` singleton with `part` extensions, `flutter_test`. Package name `moor_market`.

**Spec:** `docs/superpowers/specs/2026-11-27-shop-accounts-design.md`

## Global Constraints
- One phone number = one account. Do not change `isPhoneRegistered` / `signInVerifiedPhone` lookup.
- Old stored JSON without `accountType` / `shop` must load as a person.
- `isShop` is true only when `accountType == shop` AND `shop != null` AND `shop.isComplete`. Everywhere else the account is treated as a person.
- Person → shop only. No shop → person in v1.
- Shops can still buy and start chats as buyers.
- Opening status is computed in Thailand time (UTC+7) and labelled "ตามเวลาที่ร้านแจ้ง".
- Names on cards and chats come from live lookup (`userById(id)?.displayName ?? storedCopy`); never rewrite stored `sellerName` / `peerName`.
- Out of scope: multi-shop broadcast, stock counts, staff, delivery, separate feeds.
- All UI copy in Thai. Follow existing `AppColors` / `AppTheme`.
- The working tree has the user's own uncommitted changes. Stage only files your task touches (`git add <paths>`, never `git add -A`).
- Test command: `flutter test <file>`; full suite `flutter test`.

## Review Focus
1. Overnight hours (e.g. 18:00–02:00): a shop must show open at 01:00 the next day and closed at 03:00. → Task 1 test.
2. Stored user JSON from before this feature, and a shop user whose `shop` JSON is missing or malformed, must load and behave as a person. → Task 1 test.
3. Search query with surrounding spaces or different letter case still matches shop name, description and categories; empty query returns every nearby shop. → Task 3 test.
4. A suspended or blocked shop must not appear in `shopsNearby` and `openShopInquiry` must refuse it; a shop cannot open an inquiry with itself. → Task 3 and Task 4 tests.
5. A guest tapping "ทักถามร้าน" gets no conversation (returns null) and the UI sends them to login, same as product chat. → Task 4 test, Task 7 UI.

---

### Task 1: Shop data model

**Files:**
- Create: `lib/models/shop_profile.dart`, `lib/constants/categories.dart`, `lib/constants/shop_limits.dart`, `lib/utils/thai_time.dart`
- Modify: `lib/models/user.dart`, `lib/screens/home/search_filter_screen.dart:22-30`, `lib/screens/home/create_listing_screen.dart:35-42`
- Test: `test/model_serialization_test.dart`, new `test/shop_profile_test.dart`

**Interfaces:**
- Produces:
  - `const List<String> kListingCategories` (the 6 categories now in `CreateListingScreen._categories`, same order). Both screens use it; search keeps its own `'ทั้งหมด'` entry prepended.
  - `const int kMaxShopNameLength = 60; kMaxShopDescriptionLength = 500; kMinShopCategories = 1; kMaxShopCategories = 5;`
  - `DateTime thaiNow()` → `DateTime.now().toUtc().add(const Duration(hours: 7))`; and `DateTime toThaiTime(DateTime t)` same conversion for any instant.
  - `class DayHours { final int openMinute; final int closeMinute; }` minutes since midnight; `closeMinute <= openMinute` means it closes after midnight.
  - `class OpeningHours { final Map<int, DayHours> days; /* key = DateTime.weekday 1..7 */ bool isOpenAt(DateTime thaiTime); bool get isEmpty; Map<String,Object?> toJson(); factory OpeningHours.fromJson(Map<String,dynamic>); }`
  - `class ShopProfile { shopName, description, List<String> categories, GeoLocation location, String locationLabel, OpeningHours openingHours; bool get isComplete; toJson/fromJson/copyWith }`. `isComplete` = trimmed name non-empty, ≥1 category, `openingHours` not empty.
  - `enum AccountType { person, shop }`; `UserModel.accountType` (default `person`), `UserModel.shop` (`ShopProfile?`), `bool get isShop`, `String get displayName` (shop name when `isShop`, else `name`). `copyWith` gains `accountType`, `shop`.

- [ ] **Step 1: Write failing tests**

`test/shop_profile_test.dart`:
```dart
test('isOpenAt handles same-day hours', () {
  final h = OpeningHours(days: {1: DayHours(openMinute: 540, closeMinute: 1200)});
  expect(h.isOpenAt(DateTime(2026, 11, 23, 10)), isTrue);  // Monday 10:00
  expect(h.isOpenAt(DateTime(2026, 11, 23, 20, 1)), isFalse);
  expect(h.isOpenAt(DateTime(2026, 11, 24, 10)), isFalse); // Tuesday closed
});
test('isOpenAt handles hours past midnight', () {
  final h = OpeningHours(days: {1: DayHours(openMinute: 1080, closeMinute: 120)});
  expect(h.isOpenAt(DateTime(2026, 11, 23, 23)), isTrue);
  expect(h.isOpenAt(DateTime(2026, 11, 24, 1)), isTrue);  // Tue 01:00 from Monday
  expect(h.isOpenAt(DateTime(2026, 11, 24, 3)), isFalse);
});
test('toThaiTime shifts UTC by 7 hours', () {
  expect(toThaiTime(DateTime.utc(2026, 11, 23, 20)).hour, 3);
});
test('ShopProfile JSON round trip and isComplete', ...); // complete profile equal after round trip; empty name or no categories or no hours → isComplete false
```
`test/model_serialization_test.dart`:
```dart
test('user JSON without account fields loads as person', () {
  final u = UserModel.fromJson({'id': 'u1', 'name': 'ก'});
  expect(u.accountType, AccountType.person);
  expect(u.shop, isNull);
  expect(u.isShop, isFalse);
  expect(u.displayName, 'ก');
});
test('shop user with malformed shop JSON behaves as person', () {
  final u = UserModel.fromJson({'id': 'u1', 'name': 'ก', 'accountType': 'shop', 'shop': 'oops'});
  expect(u.isShop, isFalse);
  expect(u.displayName, 'ก');
});
test('shop user round trip keeps shop and displayName', ...); // displayName == shopName
```

- [ ] **Step 2: Run tests, expect FAIL** — `flutter test test/shop_profile_test.dart test/model_serialization_test.dart` (compile errors: types undefined).
- [ ] **Step 3: Implement** the types above. `fromJson` uses `json_helpers`; `shop` parses only when `json['shop'] is Map<String, dynamic>`, else null. `ShopProfile.fromJson` on missing location falls back to `GeoLocation(0, 0)` and the profile is then still judged by `isComplete`. `isOpenAt`: check today's `DayHours` (open ≤ t < close, or for overnight t ≥ open) and yesterday's overnight tail (t < close).
- [ ] **Step 4: Replace both screens' category lists with `kListingCategories`.**
- [ ] **Step 5: Run** `flutter test test/shop_profile_test.dart test/model_serialization_test.dart test/create_listing_screen_test.dart test/nearby_ui_test.dart` → PASS.
- [ ] **Step 6: Commit** `feat: add shop profile model and account type`.

---

### Task 2: Register, convert and edit shops (state)

**Files:**
- Create: `lib/utils/shop_validation.dart`
- Modify: `lib/state/app_state_auth.dart`
- Test: `test/app_state_auth_test.dart`

**Interfaces:**
- Consumes: Task 1 types and limits.
- Produces:
  - `String? validateShopProfile(ShopProfile shop)` → Thai error or null. Errors: empty name `'กรุณากรอกชื่อร้าน'`; name > 60 `'ชื่อร้านยาวเกิน 60 ตัวอักษร'`; description > 500 `'คำอธิบายร้านยาวเกิน 500 ตัวอักษร'`; categories < 1 `'เลือกหมวดสินค้าอย่างน้อย 1 หมวด'`; > 5 `'เลือกหมวดสินค้าได้ไม่เกิน 5 หมวด'`; category not in `kListingCategories` `'หมวดสินค้าไม่ถูกต้อง'`; empty hours `'กรุณาระบุเวลาเปิดอย่างน้อย 1 วัน'`; empty `locationLabel` `'กรุณาเลือกที่ตั้งร้าน'`.
  - `bool registerVerifiedPhone({required String name, required String phone, String authUid = '', AccountType accountType = AccountType.person, ShopProfile? shop})` — returns false when phone taken, or when `accountType == shop` and `shop` is null/invalid. A shop's `homeLat/homeLng/homeLabel` are set from `shop.location` / `locationLabel`.
  - `String? convertCurrentUserToShop(ShopProfile shop)` — error when guest, suspended (via `_expireSuspendedSession`), already a shop (`'บัญชีนี้เป็นร้านค้าอยู่แล้ว'`), or invalid profile. Updates `currentUser` and `users[i]`, `notifyListeners()`. Listings, orders, chats untouched.
  - `String? updateShopProfile(ShopProfile shop)` — error when not `isShop` (`'บัญชีนี้ไม่ใช่ร้านค้า'`) or invalid.

- [ ] **Step 1: Write failing tests** in `test/app_state_auth_test.dart` (reuse its setUp/tearDown pattern; restore `users` in tearDown):
  - `registers a shop account with its profile` → `isShop` true, `displayName == shopName`, `homeLabel == shop.locationLabel`.
  - `refuses shop registration without a valid profile` → `registerVerifiedPhone(accountType: AccountType.shop, shop: null)` false; with empty name false; user count unchanged.
  - `person can convert to shop and keeps listings` → sign in `0800000002`, count products with `sellerId == 'user_02'` before/after equal; `convertCurrentUserToShop` returns null; `currentUser.isShop` true.
  - `converting twice is refused` → second call returns `'บัญชีนี้เป็นร้านค้าอยู่แล้ว'`.
  - `guest cannot convert` → `loginAsGuest()` then non-null error.
  - `updateShopProfile refused for person, applied for shop`.
  - `validateShopProfile` table test covering every error string above.
- [ ] **Step 2: Run** `flutter test test/app_state_auth_test.dart` → FAIL.
- [ ] **Step 3: Implement** validation and the three methods.
- [ ] **Step 4: Run** `flutter test test/app_state_auth_test.dart test/app_state_persistence_test.dart` → PASS.
- [ ] **Step 5: Commit** `feat: register, convert and edit shop accounts`.

---

### Task 3: Nearby shop search

**Files:**
- Create: `lib/models/nearby_shop.dart`
- Modify: `lib/state/app_state_listings.dart`
- Test: `test/app_state_nearby_test.dart`

**Interfaces:**
- Consumes: `UserModel.isShop`, `ShopProfile`, `OpeningHours.isOpenAt`, `toThaiTime`.
- Produces:
  - `class NearbyShop { final UserModel shop; final double distanceKm; final bool isOpenNow; final int matchingListingCount; }`
  - `enum SellerKind { all, shops, people }` (in `app_state_listings.dart` alongside `SortBy` usage, or in `nearby_shop.dart` — export from `app_state.dart` either way).
  - `productsNearby(..., SellerKind sellerKind = SellerKind.all)` — filters by `userById(sellerId)?.isShop`.
  - `List<NearbyShop> shopsNearby({double radiusKm = kDefaultRadiusKm, String? query, String? category, bool openNowOnly = false, DateTime? now})` — `now` defaults to `DateTime.now()`, converted with `toThaiTime`. Distance from `shop.location` to `currentLocation`. Excludes: non-shops, self, suspended, blocked (`_blockedUserIdsFor`), and returns `[]` when current user suspended. A shop matches when query is empty, or trimmed lower-case query is contained in shop name/description/any category, or any of its `active` listings matches by title/description/category. `category` filter: shop's categories contain it or a matching listing has it. `matchingListingCount` = active listings matching query+category (all active listings when query empty). Sort by distance ascending.
  - `String sellerDisplayName(String sellerId, String storedName)` → `userById(sellerId)?.displayName ?? storedName`.

- [ ] **Step 1: Write failing tests** (build test shops by adding `UserModel`s with `ShopProfile` to `appState.users` in the test; restore in tearDown):
  - `finds a shop by its description when it has no matching listing` → `matchingListingCount == 0`, shop present.
  - `finds a shop by a matching listing` → count == number of matching active listings.
  - `query is trimmed and case-insensitive` → `'  USB-C '` matches description `'สายชาร์จ usb-c'`.
  - `empty query returns all nearby shops sorted by distance`.
  - `excludes shops outside radius, suspended, blocked, and self`.
  - `openNowOnly filters by Thai time` → `now: DateTime.utc(2026,11,23,3)` (10:00 Thai Monday) open; `DateTime.utc(2026,11,23,14)` (21:00) closed when hours 09:00–20:00.
  - `productsNearby sellerKind shops / people`.
  - `persons with incomplete shop data never appear`.
- [ ] **Step 2: Run** `flutter test test/app_state_nearby_test.dart` → FAIL.
- [ ] **Step 3: Implement.**
- [ ] **Step 4: Run** `flutter test test/app_state_nearby_test.dart test/app_state_listing_test.dart` → PASS.
- [ ] **Step 5: Commit** `feat: search nearby shops`.

---

### Task 4: Shop inquiry chats (state)

**Files:**
- Modify: `lib/models/chat.dart`, `lib/state/app_state_chat.dart`, `lib/state/app_state_orders.dart` (only if it reads `conversation.productId`)
- Test: `test/app_state_chat_test.dart`

**Interfaces:**
- Produces:
  - `ChatConversation.isShopInquiry` → `productId.isEmpty`.
  - `ChatConversation? openShopInquiry(String shopUserId)` — null when suspended session, guest, shop not found or `!isShop`, `shopUserId == currentUser.id`, blocked either way, or shop suspended. Reuses an existing conversation with empty `productId`, same buyer and seller. New one: `productId: ''`, `productTitle: ''`, `productPrice: 0`, `productImageUrl: ''`, `sellerId/peerId: shop.id`, `peerName: shop.displayName`, same safety system message as `openConversationForProduct`.
  - `proposeMeetup` and `shareExactAddress` return `'แชทสอบถามร้านยังไม่มีสินค้าสำหรับนัดรับ'` for inquiry conversations.

- [ ] **Step 1: Write failing tests:**
  - `opens and reuses a shop inquiry` → second call returns same `id`; `isShopInquiry` true.
  - `refuses inquiry to self, non-shop, blocked, suspended shop, and guest` → each null.
  - `meetup and address sharing are refused in inquiry chats` → exact error string.
  - `inquiry chat appears in conversationsForCurrentUser for both buyer and shop`.
- [ ] **Step 2: Run** `flutter test test/app_state_chat_test.dart` → FAIL.
- [ ] **Step 3: Implement.** Grep `productId` in `lib/state/` and make every lookup tolerate `''` (no product found → skip, never throw).
- [ ] **Step 4: Run** `flutter test test/app_state_chat_test.dart test/app_state_order_test.dart test/app_state_persistence_test.dart test/firestore_persistence_test.dart` → PASS.
- [ ] **Step 5: Commit** `feat: allow product-less shop inquiry chats`.

---

### Task 5: Seed shops

**Files:**
- Modify: `lib/state/app_state_seed.dart`, `docs/TEST_ACCOUNTS.md`
- Test: `test/app_state_persistence_test.dart`

**Interfaces:**
- Produces seed users (both `accountType: shop`, `role: member`, `phoneVerified: true`):
  - `shop_01`, phone `0800000011`, shopName `'ร้านมือถือเจริญ'`, categories `['ไอที & อิเล็กทรอนิกส์']`, description mentioning สายชาร์จ, หูฟัง, เคสมือถือ, location `GeoLocation(12.6150, 102.1050)`, label `'ถนนท่าแฉลบ จันทบุรี'`, open every day 09:00–20:00. 3 active listings.
  - `shop_02`, phone `0800000012`, shopName `'เครื่องเขียนสมใจ'`, categories `['อุปกรณ์และเครื่องเขียน', 'หนังสือ']`, location `GeoLocation(12.6050, 102.1100)`, label `'ตลาดเนินวง จันทบุรี'`, Mon–Sat 08:30–18:00, Sunday closed. 2 active listings.

- [ ] **Step 1: Write failing test** `seed contains two complete shops` → both `isShop`, `shopsNearby(radiusKm: 5)` from `kDefaultCenter` returns both.
- [ ] **Step 2: Run** → FAIL. **Step 3: Implement** seed data; add both numbers to `docs/TEST_ACCOUNTS.md` table (note: register as Firebase test numbers to sign in by OTP; debug sample buttons otherwise).
- [ ] **Step 4: Run** `flutter test` (full suite — seed changes can shift counts in other tests; fix tests that assert exact seed counts by updating the expected numbers, not the seed).
- [ ] **Step 5: Commit** `feat: seed sample shops`.

---

### Task 6: Sign-up type choice, shop setup, profile actions

**Files:**
- Create: `lib/screens/auth/shop_setup_screen.dart`
- Modify: `lib/screens/auth/sign_up_screen.dart`, `lib/screens/auth/phone_otp_screen.dart`, `lib/screens/profile/profile_screen.dart`
- Test: `test/auth_screens_test.dart`

**Interfaces:**
- Consumes: Task 2 methods, `validateShopProfile`, `kListingCategories`, `widgets/location_picker.dart`.
- Produces:
  - `enum ShopSetupMode { register, convert, edit }`
  - `ShopSetupScreen({required ShopSetupMode mode, ShopProfile? initial, ValueChanged<ShopProfile>? onSubmitted})` — fields: ชื่อร้าน, คำอธิบายร้าน, หมวดสินค้า (FilterChips), ที่ตั้งร้าน (location picker), เวลาเปิด-ปิด (per weekday switch + two time pickers). Submit button disabled while `validateShopProfile` returns an error; shows the error text. `register` mode calls `onSubmitted`; `convert` calls `convertCurrentUserToShop`, `edit` calls `updateShopProfile`, then pops; on error shows SnackBar.
  - `PhoneOtpScreen({required String phone, String? name, AccountType accountType = AccountType.person, ShopProfile? shop})` passing both to `registerVerifiedPhone`.
- Sign-up flow: two cards at top `'บุคคลทั่วไป'` / `'ร้านค้า'` (default บุคคลทั่วไป). For ร้านค้า the main button reads `'ถัดไป: ตั้งค่าร้าน'` and pushes `ShopSetupScreen(mode: register)`; its `onSubmitted` pushes `PhoneOtpScreen(..., accountType: shop, shop: profile)`. Person flow unchanged (existing test keeps passing: 2 text fields).
- Profile: when `!isShop` and logged in, tile `'เปลี่ยนเป็นร้านค้า'` → `ShopSetupScreen(mode: convert)`; when `isShop`, tile `'แก้ไขข้อมูลร้าน'` → `ShopSetupScreen(mode: edit, initial: currentUser.shop)`, and the header shows `displayName`.

- [ ] **Step 1: Write failing widget tests:**
  - `sign-up shows account type choice and shop path goes to shop setup`.
  - `shop setup submit stays disabled until name, category, location label and hours are set` (inject an `initial` profile with location to avoid driving the map picker).
  - `profile shows convert tile for person and edit tile for shop`.
  - existing `sign-up remains disabled until required fields are valid` still passes.
- [ ] **Step 2: Run** `flutter test test/auth_screens_test.dart` → FAIL. **Step 3: Implement.**
- [ ] **Step 4: Run** `flutter test test/auth_screens_test.dart test/layout_overflow_test.dart` → PASS.
- [ ] **Step 5: Commit** `feat: shop sign-up, setup and conversion screens`.

---

### Task 7: Storefront, shop badge, live names

**Files:**
- Create: `lib/screens/profile/shop_profile_screen.dart`, `lib/widgets/shop_badge.dart`
- Modify: `lib/screens/profile/public_user_profile_screen.dart`, `lib/widgets/product_card.dart`, `lib/screens/home/product_detail_screen.dart`, `lib/screens/order/cart_screen.dart:112`, `lib/screens/order/order_summary_screen.dart:39`
- Test: new `test/shop_screens_test.dart`

**Interfaces:**
- Consumes: `sellerDisplayName`, `openShopInquiry`, `OpeningHours.isOpenAt`, `thaiNow`.
- Produces:
  - `ShopBadge()` — small pill `'ร้านค้า'` with store icon.
  - `ShopProfileScreen({required String shopUserId, String? inquiryDraft, DateTime Function()? clock})` (`clock` defaults to `DateTime.now`, converted with `toThaiTime`; tests pass a fixed time) — name, ShopBadge, description, category chips, distance, status line `'เปิดอยู่ · ตามเวลาที่ร้านแจ้ง'` / `'ปิดอยู่ · ตามเวลาที่ร้านแจ้ง'`, weekly hours, active listings (ProductCard grid), reviews (reuse layout from public profile), button `'ทักถามร้าน'`. Button: guest → push login screen (same as product chat); else `openShopInquiry` → push `ChatRoomScreen` with draft `inquiryDraft ?? 'สวัสดีครับ สอบถามสินค้าหน่อยครับ'`. Report/block actions same as public profile.
  - `PublicUserProfileScreen` redirects to `ShopProfileScreen` when the user `isShop`.
  - Product card and detail: `ShopBadge` next to seller name when seller `isShop`; all seller names via `sellerDisplayName`. Detail's seller row opens the storefront for shops.

- [ ] **Step 1: Write failing widget tests:** storefront shows name, badge, open/closed text and listings for `shop_01`; product card for a `shop_01` listing shows `'ร้านค้า'` and shop name; renaming via `updateShopProfile` changes the card's name without touching `ProductModel.sellerName`; guest tapping `'ทักถามร้าน'` lands on login screen.
- [ ] **Step 2: Run** `flutter test test/shop_screens_test.dart` → FAIL. **Step 3: Implement.**
- [ ] **Step 4: Run** `flutter test test/shop_screens_test.dart test/nearby_ui_test.dart test/order_flow_screen_test.dart` → PASS.
- [ ] **Step 5: Commit** `feat: shop storefront and badge`.

---

### Task 8: Search shops

**Files:**
- Modify: `lib/screens/home/search_filter_screen.dart`
- Create: `lib/widgets/shop_result_card.dart`
- Test: `test/nearby_ui_test.dart`

**Interfaces:**
- Consumes: `shopsNearby`, `SellerKind`, `ShopProfileScreen`, `openShopInquiry`.
- Produces: `ShopResultCard({required NearbyShop nearbyShop, required VoidCallback onTap, required VoidCallback onAsk})` — name, distance (`x.x กม.`), green/red open status with `'ตามเวลาที่ร้านแจ้ง'`, `'มีสินค้าตรงคำค้น N รายการ'` when N > 0 else `'ร้านขาย: <categories joined by ", ">'`, button `'ทักถามร้าน'`.
- Search screen: `SegmentedButton` `'สินค้า'` / `'ร้านค้า'`. Shops mode: same search box, radius and category; chip `'เปิดอยู่ตอนนี้'`; price/type/sort hidden. Items mode: extra chips `'ทั้งหมด' / 'เฉพาะร้านค้า' / 'เฉพาะบุคคล'` → `sellerKind`. `onAsk` opens inquiry with draft `'สวัสดีครับ มี <query> ไหมครับ'` when query non-empty, else the default draft.

- `SearchFilterScreen({super.key, DateTime Function()? clock})` — `clock` (default `DateTime.now`) is passed as `now:` to `shopsNearby`, so tests fix the time.

- [ ] **Step 1: Write failing widget tests:** switching to ร้านค้า with query `'สายชาร์จ'` shows `'ร้านมือถือเจริญ'`; with `clock: () => DateTime.utc(2026,11,22,14)` (Sunday 21:00 Thai) and `'เปิดอยู่ตอนนี้'` on, neither seed shop shows; with `DateTime.utc(2026,11,23,3)` (Monday 10:00 Thai) both show; items mode `'เฉพาะร้านค้า'` hides person listings.
- [ ] **Step 2: Run** → FAIL. **Step 3: Implement.** **Step 4: Run** `flutter test test/nearby_ui_test.dart test/layout_overflow_test.dart` → PASS.
- [ ] **Step 5: Commit** `feat: search nearby shops in search screen`.

---

### Task 9: Inquiry chats in the chat UI

**Files:**
- Modify: `lib/screens/chat/chat_room_screen.dart`, `lib/screens/chat/chat_list_screen.dart`
- Test: `test/chat_room_screen_test.dart`

**Interfaces:**
- Consumes: `isShopInquiry`, `UserModel.displayName`, `ShopBadge`.
- Produces: `ChatRoomScreen` gains optional `String? initialDraft` that pre-fills the message box once (not sent). Inquiry chats: header shows peer `displayName` + `ShopBadge`, subtitle `'สอบถามร้านค้า'` instead of the product strip, meetup/address/order actions hidden. All peer names use `peer?.displayName ?? conversation.peerName`. Chat list shows `'สอบถามร้านค้า'` instead of product title for inquiries.

- [ ] **Step 1: Write failing widget tests:** inquiry room shows `'สอบถามร้านค้า'`, has no meetup button, and the text field contains `initialDraft`; product chat unchanged.
- [ ] **Step 2: Run** → FAIL. **Step 3: Implement.** **Step 4: Run** `flutter test test/chat_room_screen_test.dart` → PASS.
- [ ] **Step 5: Commit** `feat: show shop inquiry chats`.

---

### Task 10: Overflow checks and full suite

**Files:**
- Modify: `test/layout_overflow_test.dart`, `docs/FEATURE_STATUS.md`, `docs/DATA_MODEL.md`

- [ ] **Step 1:** Add `ShopSetupScreen`, `ShopProfileScreen`, search shops mode and `ShopResultCard` to the overflow test at the sizes it already uses.
- [ ] **Step 2:** Document `accountType` / `shop` in `DATA_MODEL.md` and the feature in `FEATURE_STATUS.md`.
- [ ] **Step 3: Run** `flutter analyze` → no new issues; `flutter test` → all PASS.
- [ ] **Step 4: Commit** `test: cover shop screens for overflow; document shops`.
