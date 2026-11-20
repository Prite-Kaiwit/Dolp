import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moor_market/constants/app_info.dart';
import 'package:moor_market/screens/home/home_feed_screen.dart';
import 'package:moor_market/screens/home/product_detail_screen.dart';
import 'package:moor_market/screens/home/search_filter_screen.dart';
import 'package:moor_market/state/app_state.dart';
import 'package:moor_market/widgets/product_card.dart';

void main() {
  final appState = AppState();

  setUp(() {
    appState.loginWithPhoneAndPassword('0800000001', 'password123');
    appState.updateCurrentUserArea(
      latitude: kDefaultCenter.lat,
      longitude: kDefaultCenter.lng,
      label: 'อำเภอเมืองจันทบุรี',
    );
  });

  tearDown(() {
    appState.loginWithPhoneAndPassword('0800000001', 'password123');
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

      appState.loginWithPhoneAndPassword('0800000002', 'password123');
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
