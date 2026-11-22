import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image_picker/image_picker.dart';
import 'package:moor_market/constants/app_info.dart';
import 'package:moor_market/constants/listing_limits.dart';
import 'package:moor_market/screens/home/create_listing_screen.dart';
import 'package:moor_market/state/app_state.dart';
import 'package:moor_market/widgets/product_image.dart';

void main() {
  final appState = AppState();
  final transparentPng = Uint8List.fromList(
    base64.decode(
      'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mP8/x8AAwMCAO+jf5sAAAAASUVORK5CYII=',
    ),
  );

  setUp(() {
    appState.loginWithPhoneAndPassword('0800000001', 'password123');
    appState.updateCurrentUserArea(
      latitude: kDefaultCenter.lat,
      longitude: kDefaultCenter.lng,
      label: 'อำเภอเมืองจันทบุรี',
    );
  });

  testWidgets(
    'publishing stays disabled until title, price, category, image, and location are valid',
    (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: CreateListingScreen(
            pickImages: (_, {required limit}) async => [
              XFile.fromData(transparentPng, name: 'listing.png'),
            ],
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(_publishButton(tester).onPressed, isNull);

      await tester.enterText(
        find.byKey(const ValueKey('listing-title')),
        'โต๊ะทำงาน',
      );
      await tester.ensureVisible(find.byKey(const ValueKey('listing-price')));
      await tester.enterText(
        find.byKey(const ValueKey('listing-price')),
        '99.99',
      );
      await tester.ensureVisible(
        find.byKey(const ValueKey('listing-category')),
      );
      await tester.tap(find.byKey(const ValueKey('listing-category')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('หนังสือ').last);
      await tester.pumpAndSettle();

      final areaChip = find.widgetWithText(ActionChip, 'อำเภอเมืองจันทบุรี');
      await tester.ensureVisible(areaChip);
      await tester.tap(areaChip);
      await tester.pumpAndSettle();

      await tester.ensureVisible(
        find.byKey(const ValueKey('add-listing-image')),
      );
      await tester.tap(find.byKey(const ValueKey('add-listing-image')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('เลือกจากแกลเลอรี่'));
      await tester.pumpAndSettle();

      await tester.ensureVisible(find.byKey(const ValueKey('publish-listing')));
      await tester.pumpAndSettle();
      expect(_publishButton(tester).onPressed, isNotNull);
    },
  );

  testWidgets(
    'image picker enforces five images and supports cover and delete',
    (tester) async {
      final imageBytes = List<Uint8List>.generate(
        7,
        (index) => Uint8List.fromList([...transparentPng, index]),
      );
      var pickerLimit = 0;
      await tester.pumpWidget(
        MaterialApp(
          home: CreateListingScreen(
            pickImages: (_, {required limit}) async {
              pickerLimit = limit;
              return imageBytes
                  .map(
                    (bytes) => XFile.fromData(
                      bytes,
                      name: 'listing-${bytes.last}.png',
                    ),
                  )
                  .toList();
            },
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const ValueKey('add-listing-image')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('เลือกจากแกลเลอรี่'));
      await tester.pumpAndSettle();

      expect(pickerLimit, kMaxListingImages);
      expect(find.byKey(const ValueKey('listing-image-4')), findsOneWidget);
      expect(find.byKey(const ValueKey('listing-image-5')), findsNothing);

      await tester.tap(find.byKey(const ValueKey('listing-image-2')));
      await tester.pumpAndSettle();
      final coverTile = find.byKey(const ValueKey('listing-image-0'));
      final coverImage = tester.widget<ProductImage>(
        find.descendant(of: coverTile, matching: find.byType(ProductImage)),
      );
      expect(coverImage.source!.bytes, orderedEquals(imageBytes[2]));

      await tester.tap(find.byTooltip('ลบรูป 1'));
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('listing-image-3')), findsOneWidget);
      expect(find.byKey(const ValueKey('listing-image-4')), findsNothing);
    },
  );

  testWidgets('donate hides price and exchange requires a trade description', (
    tester,
  ) async {
    await tester.pumpWidget(const MaterialApp(home: CreateListingScreen()));
    await tester.pumpAndSettle();

    await tester.tap(find.text('บริจาค'));
    await tester.pumpAndSettle();
    expect(find.text('ฟรี · ไม่มีค่าใช้จ่าย'), findsOneWidget);
    expect(find.byKey(const ValueKey('listing-price')), findsNothing);

    await tester.tap(find.text('แลกเปลี่ยน'));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('listing-price')), findsOneWidget);
    expect(find.byKey(const ValueKey('listing-trade-for')), findsOneWidget);
    expect(_publishButton(tester).onPressed, isNull);
  });
}

ElevatedButton _publishButton(WidgetTester tester) => tester
    .widget<ElevatedButton>(find.byKey(const ValueKey('publish-listing')));
