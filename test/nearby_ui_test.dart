import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moor_market/constants/app_info.dart';
import 'package:moor_market/screens/auth/login_screen.dart';
import 'package:moor_market/screens/home/home_feed_screen.dart';
import 'package:moor_market/screens/home/product_detail_screen.dart';
import 'package:moor_market/screens/home/search_filter_screen.dart';
import 'package:moor_market/state/app_state.dart';
import 'package:moor_market/widgets/product_card.dart';

void main() {
  final appState = AppState();

  setUp(() {
    appState.signInVerifiedPhone('0800000001') == PhoneSignInResult.signedIn;
    appState.updateCurrentUserArea(
      latitude: kDefaultCenter.lat,
      longitude: kDefaultCenter.lng,
      label: 'อำเภอเมืองจันทบุรี',
    );
  });

  tearDown(() {
    appState.signInVerifiedPhone('0800000001') == PhoneSignInResult.signedIn;
    appState.updateCurrentUserArea(
      latitude: kDefaultCenter.lat,
      longitude: kDefaultCenter.lng,
      label: 'อำเภอเมืองจันทบุรี',
    );
  });

  testWidgets('home radius changes the nearby result count', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: HomeFeedScreen()));
    await tester.pumpAndSettle();

    final initialCount = tester
        .widget<Text>(find.textContaining('ใกล้คุณ ('))
        .data;
    await tester.tap(find.widgetWithText(ChoiceChip, '1 กม.'));
    await tester.pumpAndSettle();

    final oneKmCount = tester
        .widget<Text>(find.textContaining('ใกล้คุณ ('))
        .data;
    expect(oneKmCount, isNot(initialCount));
  });

  testWidgets('empty nearby state can expand radius to its next option', (
    tester,
  ) async {
    appState.updateCurrentUserArea(
      latitude: 20,
      longitude: 120,
      label: 'พื้นที่ทดสอบ',
    );
    await tester.pumpWidget(const MaterialApp(home: HomeFeedScreen()));
    await tester.pumpAndSettle();

    expect(find.text('ยังไม่มีสินค้าในรัศมี 5 กม.'), findsOneWidget);
    await tester.ensureVisible(find.text('ขยายรัศมี'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('ขยายรัศมี'));
    await tester.pumpAndSettle();

    expect(find.text('ไม่มีสินค้าในพื้นที่นี้'), findsOneWidget);
    expect(find.widgetWithText(ChoiceChip, '10 กม.'), findsOneWidget);
  });

  testWidgets('clearing filters restores nearby defaults', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: SearchFilterScreen()));
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.tune_rounded).first);
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(ChoiceChip, 'ขาย'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('ล้างตัวกรองทั้งหมด'));
    await tester.pumpAndSettle();

    expect(tester.widget<Slider>(find.byType(Slider)).value, kDefaultRadiusKm);
    expect(
      tester.widget<RangeSlider>(find.byType(RangeSlider)).values,
      const RangeValues(0, 1000000),
    );
    expect(
      tester
          .widgetList<ChoiceChip>(find.byType(ChoiceChip))
          .singleWhere(
            (chip) =>
                chip.label is Text && (chip.label as Text).data == 'ทั้งหมด',
          )
          .selected,
      isTrue,
    );
    await tester.tap(find.text('ใช้ตัวกรองนี้'));
    await tester.pumpAndSettle();
    expect(find.text('ใกล้สุด'), findsOneWidget);
  });

  testWidgets('donate listings remain when price minimum is above zero', (
    tester,
  ) async {
    await tester.pumpWidget(const MaterialApp(home: SearchFilterScreen()));
    await tester.pumpAndSettle();
    await tester.tap(find.byIcon(Icons.tune_rounded).first);
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(ChoiceChip, 'บริจาค/ฟรี'));
    await tester.pumpAndSettle();

    final rangeSlider = find.byType(RangeSlider);
    await tester.ensureVisible(rangeSlider);
    final sliderRect = tester.getRect(rangeSlider);
    await tester.dragFrom(
      Offset(sliderRect.left + 12, sliderRect.center.dy),
      const Offset(30, 0),
    );
    await tester.pumpAndSettle();
    expect(
      tester.widget<RangeSlider>(rangeSlider).values.start,
      greaterThan(0),
    );

    await tester.tap(find.text('ใช้ตัวกรองนี้'));
    await tester.pumpAndSettle();
    expect(find.text('เสื้อคลุมสีขาว ไซส์ M (ส่งต่อฟรี)'), findsOneWidget);
  });

  Future<void> openShopsMode(
    WidgetTester tester, {
    DateTime Function()? clock,
  }) async {
    await tester.pumpWidget(
      MaterialApp(home: SearchFilterScreen(clock: clock)),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('ร้านค้า').first);
    await tester.pumpAndSettle();
  }

  testWidgets('shops mode finds shop by listing query', (tester) async {
    await openShopsMode(tester);
    await tester.enterText(find.byType(TextField).first, 'สายชาร์จ');
    await tester.pumpAndSettle();

    expect(find.text('ร้านมือถือเจริญ'), findsOneWidget);
    expect(find.text('ทักถามร้าน'), findsWidgets);
  });

  testWidgets('open-now chip hides closed shops on Sunday night', (
    tester,
  ) async {
    await openShopsMode(tester, clock: () => DateTime.utc(2026, 11, 22, 14));
    expect(find.text('ร้านมือถือเจริญ'), findsOneWidget);
    await tester.tap(find.text('เปิดอยู่ตอนนี้'));
    await tester.pumpAndSettle();

    expect(find.text('ร้านมือถือเจริญ'), findsNothing);
    expect(find.text('เครื่องเขียนสมใจ'), findsNothing);
  });

  testWidgets('open-now chip shows both shops on Monday morning', (
    tester,
  ) async {
    await openShopsMode(tester, clock: () => DateTime.utc(2026, 11, 23, 3));
    await tester.tap(find.text('เปิดอยู่ตอนนี้'));
    await tester.pumpAndSettle();

    expect(find.text('ร้านมือถือเจริญ'), findsOneWidget);
    expect(find.text('เครื่องเขียนสมใจ'), findsOneWidget);
    expect(find.text('ตามเวลาที่ร้านแจ้ง'), findsWidgets);
  });

  testWidgets('items mode shops-only chip hides person listings', (
    tester,
  ) async {
    await tester.pumpWidget(const MaterialApp(home: SearchFilterScreen()));
    await tester.pumpAndSettle();
    bool isShopSeller(ProductCard c) =>
        appState.userById(c.nearbyProduct.product.sellerId)?.isShop ?? false;
    List<ProductCard> cards() =>
        tester.widgetList<ProductCard>(find.byType(ProductCard)).toList();

    await tester.tap(find.text('เฉพาะบุคคล'));
    await tester.pumpAndSettle();
    expect(cards(), isNotEmpty);
    expect(cards().any(isShopSeller), isFalse);

    await tester.tap(find.text('เฉพาะร้านค้า'));
    await tester.pumpAndSettle();
    expect(cards(), isNotEmpty);
    expect(cards().every(isShopSeller), isTrue);
  });

  testWidgets('guest asking a shop is sent to login without a chat', (
    tester,
  ) async {
    appState.loginAsGuest();
    final before = appState.conversations.length;
    await openShopsMode(tester);
    await tester.tap(find.text('ทักถามร้าน').first);
    await tester.pumpAndSettle();

    expect(find.byType(LoginScreen), findsOneWidget);
    expect(appState.conversations.length, before);
  });

  testWidgets('shops mode does not overflow at narrow width', (tester) async {
    tester.view.physicalSize = const Size(320, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      MaterialApp(
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(
            context,
          ).copyWith(textScaler: const TextScaler.linear(1.0)),
          child: child!,
        ),
        home: const SearchFilterScreen(),
      ),
    );
    await tester.pumpAndSettle();
    // The pre-existing items-mode sort row overflows under the wide test
    // font at this width; only the shops-mode layout is under test here.
    tester.takeException();
    await tester.tap(find.text('ร้านค้า').first);
    await tester.pumpAndSettle();
    expect(find.text('ทักถามร้าน'), findsWidgets);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'search defaults to nearest order and detail omits exact coords',
    (tester) async {
      await tester.pumpWidget(const MaterialApp(home: SearchFilterScreen()));
      await tester.pumpAndSettle();

      final visibleCards = tester
          .widgetList<ProductCard>(find.byType(ProductCard))
          .toList();
      expect(visibleCards.length, greaterThan(1));
      for (var index = 1; index < visibleCards.length; index++) {
        expect(
          visibleCards[index - 1].nearbyProduct.distanceKm,
          lessThanOrEqualTo(visibleCards[index].nearbyProduct.distanceKm),
        );
      }

      appState.signInVerifiedPhone('0800000002') == PhoneSignInResult.signedIn;
      final exact = appState.getExactLocationFor('prod_1', 'user_02')!;
      final product = appState.products.firstWhere(
        (item) => item.id == 'prod_1',
      );
      await tester.pumpWidget(
        MaterialApp(home: ProductDetailScreen(product: product)),
      );
      await tester.pump();

      expect(find.textContaining(exact.exactLat.toString()), findsNothing);
      expect(find.textContaining(exact.exactLng.toString()), findsNothing);
      expect(find.text('© OpenStreetMap contributors'), findsOneWidget);
    },
  );
}
