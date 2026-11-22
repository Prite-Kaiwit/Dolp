import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:moor_market/constants/app_info.dart';
import 'package:moor_market/models/geo_location.dart';
import 'package:moor_market/models/product.dart';
import 'package:moor_market/models/order.dart';
import 'package:moor_market/models/product_image_data.dart';
import 'package:moor_market/state/app_state.dart';
import 'package:moor_market/utils/distance.dart';

void main() {
  final appState = AppState();
  late List<ProductModel> originalProducts;
  late List<OrderModel> originalOrders;
  late List<ProductModel> originalCart;
  late List<Map<String, dynamic>> originalNotifications;

  setUp(() {
    originalProducts = List<ProductModel>.of(appState.products);
    originalOrders = List<OrderModel>.of(appState.orders);
    originalCart = List<ProductModel>.of(appState.cartItems);
    originalNotifications = List<Map<String, dynamic>>.of(
      appState.notifications,
    );
    appState.loginWithPhoneAndPassword('0800000001', 'password123');
    appState.updateCurrentUserArea(
      latitude: kDefaultCenter.lat,
      longitude: kDefaultCenter.lng,
      label: 'อำเภอเมืองจันทบุรี',
    );
  });

  tearDown(() {
    appState.products = originalProducts;
    appState.orders = originalOrders;
    appState.cartItems = originalCart;
    appState.notifications = originalNotifications;
    appState.loginWithPhoneAndPassword('0800000001', 'password123');
    appState.updateCurrentUserArea(
      latitude: kDefaultCenter.lat,
      longitude: kDefaultCenter.lng,
      label: 'อำเภอเมืองจันทบุรี',
    );
  });

  test('addListing stores public offset and keeps exact data owner-only', () {
    final exact = GeoLocation(12.6112, 102.1031);
    final listing = addListing(appState, exact);

    expect(
      distanceKm(exact, listing.publicLocation) * 1000,
      inInclusiveRange(100, 300),
    );
    expect(
      appState.getExactLocationFor(listing.id, 'user_01')?.exactLat,
      exact.lat,
    );
    appState.loginWithPhoneAndPassword('0800000002', 'password123');
    expect(appState.getExactLocationFor(listing.id, 'user_02'), isNull);
  });

  test('updateListing re-obfuscates the new exact point with the same id', () {
    final listing = addListing(appState, GeoLocation(12.6112, 102.1031));
    final oldPublicLocation = listing.publicLocation;
    final newExact = GeoLocation(12.6200, 102.1100);

    final updated = appState.updateListing(
      id: listing.id,
      title: 'Updated listing',
      description: '',
      price: 99.99,
      tradeFor: '',
      type: ListingType.sell,
      category: 'หนังสือ',
      condition: 'สภาพดี',
      exactLocation: newExact,
      locationLabel: 'ต.ท่าช้าง',
      exactAddress: 'ที่อยู่ใหม่',
      pickupType: PickupType.sellerHome,
      imageUrl: '',
      productImages: const [],
    );

    expect(updated.id, listing.id);
    expect(updated.publicLocation, isNot(oldPublicLocation));
    expect(
      distanceKm(newExact, updated.publicLocation) * 1000,
      inInclusiveRange(100, 300),
    );
    expect(
      appState.getExactLocationFor(listing.id, 'user_01')?.exactAddress,
      'ที่อยู่ใหม่',
    );
  });

  test(
    'other users see new listing; owner does not; hidden and sold disappear',
    () {
      final listing = addListing(appState, kDefaultCenter);
      expect(
        appState.productsNearby(radiusKm: 1).map((item) => item.product.id),
        isNot(contains(listing.id)),
      );

      appState.loginWithPhoneAndPassword('0800000002', 'password123');
      appState.updateCurrentUserArea(
        latitude: kDefaultCenter.lat,
        longitude: kDefaultCenter.lng,
        label: 'อำเภอเมืองจันทบุรี',
      );
      expect(
        appState.productsNearby(radiusKm: 1).map((item) => item.product.id),
        contains(listing.id),
      );
      appState.loginWithPhoneAndPassword('0800000001', 'password123');
      appState.setListingStatus(listing.id, ListingStatus.sold);
      appState.loginWithPhoneAndPassword('0800000002', 'password123');
      expect(
        appState.productsNearby(radiusKm: 1).map((item) => item.product.id),
        isNot(contains(listing.id)),
      );

      appState.loginWithPhoneAndPassword('0800000001', 'password123');
      appState.setListingStatus(listing.id, ListingStatus.hidden);
      appState.loginWithPhoneAndPassword('0800000002', 'password123');
      expect(
        appState.productsNearby(radiusKm: 1).map((item) => item.product.id),
        isNot(contains(listing.id)),
      );
    },
  );

  test('guest cannot create a listing', () {
    appState.loginAsGuest();
    expect(
      () => addListing(appState, kDefaultCenter),
      throwsA(isA<StateError>()),
    );
  });

  test('deleteListing blocks products with unfinished orders', () {
    final listing = addListing(appState, kDefaultCenter);
    appState.loginWithPhoneAndPassword('0800000002', 'password123');
    expect(appState.addToCart(listing), isNull);
    final result = appState.createOrderForSeller(
      'user_01',
      paymentMethod: PaymentMethod.cashOnHandover,
    );
    expect(result.isSuccess, isTrue);
    appState.loginWithPhoneAndPassword('0800000001', 'password123');

    expect(appState.deleteListing(listing.id), contains('ออเดอร์'));
    expect(
      appState.products.any((product) => product.id == listing.id),
      isTrue,
    );
    appState.loginWithPhoneAndPassword('0800000002', 'password123');
    expect(appState.cancelOrder(result.order!.id, 'ยกเลิกในชุดทดสอบ'), isNull);
  });
}

ProductModel addListing(AppState appState, GeoLocation exactLocation) {
  return appState.addListing(
    title: 'Test listing',
    description: '',
    price: 99.99,
    tradeFor: '',
    type: ListingType.sell,
    category: 'หนังสือ',
    condition: 'สภาพดี',
    exactLocation: exactLocation,
    locationLabel: 'ต.ท่าช้าง',
    exactAddress: 'ที่อยู่ส่วนตัว',
    pickupType: PickupType.discussInChat,
    imageUrl: '',
    productImages: [
      ProductImageData.memory(Uint8List.fromList([1, 2, 3])),
    ],
  );
}
