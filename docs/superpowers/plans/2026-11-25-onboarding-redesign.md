# Onboarding Redesign Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Replace the hand-drawn onboarding illustrations with real-app
visuals (OSM map, app-style pins, seed listings), sized to the screen.

**Architecture:** A new `lib/widgets/onboarding_visuals.dart` holds a pin
widget, a non-interactive static map with an offline fallback, and one visual
per slide. `SplashOnboardingScreen` swaps `_OnboardingPainter` for those
visuals and gets responsive sizing.

**Tech Stack:** Flutter, flutter_map 8, latlong2, existing `OsmTileLayer`,
`ProductImage`, `AppState`.

**Spec:** `docs/superpowers/specs/2026-11-25-onboarding-redesign-design.md`

## Global Constraints
- Colors come only from `AppColors`. No `Color(0xFF...)` literals in the
  new code.
- Slide copy, button labels, and the guest link text stay unchanged
  (`test/widget_test.dart` asserts them).
- No new packages or assets.
- The visual card is 46% of the available height, clamped to 220–360 px,
  with max width 440 and radius 20. Title is 24 bold, subtitle and
  description are 15, description line height is 1.5, and buttons are 52
  high.
- When screen height is under 640, the visual uses its minimum height and
  the description gets `maxLines: 3`.

## Review Focus
- No network (tests, offline): the fallback grid must show and nothing may
  throw. Covered by pumping in tests, where HTTP returns 400.
- Seed products have no image, or there are fewer than 3 active listings:
  the visual must still render. Task 1 test with an empty product list.
- Narrow phone at 320×568 with text scale 1.3: no overflow. Task 2 test.
- Swiping over the map must change page, not pan the map. Task 2 drag
  test.
- Large phone at 430×932: the visual caps at 360 high. Task 2 test.

---

### Task 1: Onboarding visual widgets

**Files:**
- Create: `lib/widgets/onboarding_visuals.dart`
- Test: `test/onboarding_visuals_test.dart`

**Interfaces:**
- Produces:
  - `enum MapPinKind { home, item, spot }`
  - `class MapPin extends StatelessWidget { const MapPin({required MapPinKind kind, ProductModel? product, double size = 44}); }`
    is a teardrop pin. `home` and `item` use oceanBlue, `spot` uses
    deepNavy. `item` shows the `ProductImage.forProduct` thumbnail in a
    white ring.
  - `class OnboardingVisual extends StatelessWidget { const OnboardingVisual({required int page, required List<ProductModel> products, SuggestedSpot? spot}); }`
    covers pages 0, 1, and 2 as in the spec table. It is wrapped in
    `IgnorePointer`, with `ClipRRect` radius 20.

- [ ] **Step 1: Write the failing tests**: `renders page $p with 3 products`
  for p in 0..2 (expect `FlutterMap` once and `MapPin` at least once), and
  `renders with no products`. Page 1 expects text `3 กม.`. Page 2 expects
  text `ยอมรับแล้ว`.
- [ ] **Step 2:** Run `flutter test test/onboarding_visuals_test.dart`.
  Expected: FAIL (file missing).
- [ ] **Step 3: Implement.** The static map uses
  `MapOptions(initialCenter, initialZoom: 15, interactionOptions: InteractionOptions(flags: InteractiveFlag.none), backgroundColor: AppColors.aquaPale)`.
  A `CustomPaint` road grid in `grayLine` sits under `OsmTileLayer`.
  Item pins go at fixed offsets around the center (about ±0.004°).
  Page 1 has a `CircleMarker` with radius 3000 m and `useRadiusInMeter`,
  plus chips 1/3/5 กม. and a mini product card. The card distance uses
  `distanceKm(center, product.publicLocation)`.
- [ ] **Step 4:** Run the tests. Expected: PASS.
- [ ] **Step 5:** Commit `feat: onboarding map visuals`.

### Task 2: Wire into SplashOnboardingScreen

**Files:**
- Modify: `lib/screens/auth/splash_onboarding_screen.dart` (replace the
  `CustomPaint` block and delete `_OnboardingPainter`)
- Test: `test/onboarding_screen_test.dart`

**Interfaces:**
- Consumes: `OnboardingVisual(page:, products:, spot:)` from Task 1.
  `products` is the first 3 `AppState().products` with
  `status == ListingStatus.active`. `spot` is `AppState().pickupPoints.first`
  or null.

- [ ] **Step 1: Write the failing tests.**
  - `no overflow at 320x568 scale 1.3`: for each of the 3 pages, assert
    `tester.takeException()` is null.
  - `visual caps at 360 on 430x932`: the `OnboardingVisual` height is
    ≤ 360.
  - `swipe over visual changes page`: drag the `OnboardingVisual` by -300
    and expect `ค้นหาสิ่งของใกล้ตัว`.
  - `no CustomPaint painter left`: `find.byType(OnboardingVisual)` finds
    one widget.
- [ ] **Step 2:** Run `flutter test test/onboarding_screen_test.dart`.
  Expected: FAIL.
- [ ] **Step 3: Implement** sizing per Global Constraints using
  `LayoutBuilder` on the PageView item. Make the text block scrollable
  (`SingleChildScrollView`) as an overflow guard.
- [ ] **Step 4:** Run `flutter analyze` and `flutter test`. Expected: no
  issues, and all tests pass, including `widget_test.dart` and
  `layout_overflow_test.dart`.
- [ ] **Step 5:** Capture screenshots of 3 pages at 360×780 with a golden
  helper into the scratchpad, then review them visually.
- [ ] **Step 6:** Commit `feat: redesign onboarding with real-app visuals`.
