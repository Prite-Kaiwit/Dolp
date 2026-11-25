# Onboarding screen redesign

## Intent
The welcome screen (`lib/screens/auth/splash_onboarding_screen.dart`) looks
AI-generated. The hand-drawn `CustomPaint` house, map, and pin are the main
cause. They are built from basic shapes, use off-palette red and orange, and
stretch because positions follow screen width while the height is fixed at
170 px. Replace them with pieces of the real app so the first screen looks
like the actual product.

## Goals
- Keep the current palette (`AppColors`: oceanBlue, aqua, aquaPale, deepNavy).
- Replace all three illustrations with real-app visuals: an OSM map, app-style
  pins, and real seed listings.
- Size the visuals to the screen without distortion or overflow.

## Non-goals
- No changes to other screens, the theme, navigation, or the login and
  sign-up flows.
- No new packages or image assets.

## Anti-goals
- Clip-art feel: generic blobs, or shapes that stand in for objects.
- Colors outside the palette.
- A blank or broken-tile look when offline.

## Approaches
1. **Real app UI (chosen by user).** Reuse `flutter_map` with `OsmTileLayer`,
   a proper pin widget, and seed product cards.
2. Redraw the illustrations in `CustomPaint` with a consistent style. Rejected
   because the result is still illustration, not the product.
3. Designer-supplied SVGs. Rejected because no assets exist yet.

## Design
**Shared pieces (new `lib/widgets/onboarding_visuals.dart`)**
- `MapPin`: a teardrop pin in oceanBlue with a white glyph and a soft shadow.
  Variants are home (`Icons.home_rounded`), item (product thumbnail inside a
  white ring), and meetup spot (`Icons.storefront_rounded`, deepNavy).
- `_StaticMap`: a `FlutterMap` centered on `kDefaultCenter`, with every
  interaction off, wrapped in `IgnorePointer` so the PageView still swipes.
  Behind the tiles sits a fallback: aquaPale fill plus a faint road grid in
  `grayLine`, so the area never looks broken offline.

**Slides**

| # | Visual | Copy |
|---|---|---|
| 1 | Map with a home pin at the center, a 500 m aqua "approximate area" circle, and 3 item pins showing real seed product photos nearby | unchanged |
| 2 | Map with a 3 km radius ring, distance chips `1 กม. · 3 กม. · 5 กม.` (3 selected) on top, and a floating mini product card at the bottom (photo, title, price, distance), all built from a real seed listing | unchanged |
| 3 | Map around a public meetup spot pin, with a chat-style meetup proposal card overlaid: place, time, and an "ยอมรับแล้ว" status chip in success green | unchanged |

**Sizing**
- The visual area is a rounded (20) card sized to 46% of the available
  height, clamped to 220–360 px. Width is at most 440 px, centered.
- Title 24 bold, subtitle 15, description 15 with line height 1.5. Buttons
  are 52 high. Page indicator unchanged.
- On short screens (height < 640) the visual drops to its minimum and the
  description is limited to 3 lines.
- *Revised during build (builder's call, after screenshots at 320×568):* the
  copy takes priority. The visual shrinks to fit the space left after the
  copy, never below 140 px. Short screens hide the badge. Below 200 px the
  map card drops the product peek (slide 2) and the meetup detail line
  (slide 3). Map zoom scales with the card height so the same area stays in
  frame.

**Cleanup**
- Delete `_OnboardingPainter` and all its off-palette colors.

## Left to the builder
Exact pin offsets, map zoom (about 15), shadow values, and which seed
products to show (first active listings that have an image).

## Verification
- `flutter analyze` is clean, and `flutter test` passes, including
  `layout_overflow_test` and `widget_test`.
- Add a widget test that renders the three slides at 320×568 and 430×932
  with no overflow.
- Capture screenshots at both sizes to check the look.
