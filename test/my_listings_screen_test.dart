import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moor_market/constants/app_info.dart';
import 'package:moor_market/models/product.dart';
import 'package:moor_market/models/product_image_data.dart';
import 'package:moor_market/screens/home/my_listings_screen.dart';
import 'package:moor_market/state/app_state.dart';

void main() {
  final appState = AppState();

  testWidgets('owner listings expose exact address only through owner action', (
    tester,
  ) async {
    appState.loginWithPhoneAndPassword('0800000001', 'password123');
    appState.updateCurrentUserArea(
      latitude: kDefaultCenter.lat,
      longitude: kDefaultCenter.lng,
      label: 'อำเภอเมืองจันทบุรี',
    );
    final listing = appState.addListing(
      title: 'Private location listing',
      description: '',
      price: 99,
      tradeFor: '',
      type: ListingType.sell,
      category: 'หนังสือ',
      condition: 'สภาพดี',
      exactLocation: kDefaultCenter,
      locationLabel: 'ต.ท่าช้าง',
      exactAddress: 'บ้านเลขที่ 123 จุดสังเกตเฉพาะเจ้าของ',
      pickupType: PickupType.discussInChat,
      imageUrl: '',
      productImages: [
        ProductImageData.memory(Uint8List.fromList([1, 2, 3])),
      ],
    );

    await tester.pumpWidget(const MaterialApp(home: MyListingsScreen()));
    await tester.pumpAndSettle();
    expect(find.text(listing.title), findsOneWidget);
    expect(find.textContaining('บ้านเลขที่ 123'), findsNothing);
    await tester.ensureVisible(find.text('ดูที่อยู่จริง'));
    await tester.tap(find.text('ดูที่อยู่จริง'));
    await tester.pumpAndSettle();
    expect(find.text('บ้านเลขที่ 123 จุดสังเกตเฉพาะเจ้าของ'), findsOneWidget);

    await tester.tap(find.text('ปิด'));
    await tester.pumpAndSettle();
    appState.loginWithPhoneAndPassword('0800000002', 'password123');
    await tester.pumpAndSettle();
    expect(find.text(listing.title), findsNothing);
    expect(
      appState.getExactLocationFor(listing.id, appState.currentUser.id),
      isNull,
    );

    appState.loginWithPhoneAndPassword('0800000001', 'password123');
    appState.deleteProduct(listing.id);
  });
}
