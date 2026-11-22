import 'package:flutter_test/flutter_test.dart';
import 'package:moor_market/constants/app_info.dart';
import 'package:moor_market/utils/distance.dart';
import 'package:moor_market/models/geo_location.dart';
import 'package:moor_market/models/product.dart';
import 'package:moor_market/state/app_state.dart';

void main() {
  final appState = AppState();
  late List<ProductModel> originalProducts;

  setUp(() {
    originalProducts = List<ProductModel>.from(appState.products);
    appState.loginWithPhoneAndPassword('0800000001', 'password123');
  });

  tearDown(() {
    appState.deleteProduct('nearby-own-test');
    appState.products = originalProducts;
    appState.loginAsGuest();
  });

  test('seed data covers nearby radius ranges and all listing types', () {
    expect(appState.products, hasLength(15));
    expect(
      appState.products.map((product) => product.type).toSet(),
      containsAll(ListingType.values),
    );
    expect(
      appState.products.map((product) => product.category).toSet().length,
      greaterThanOrEqualTo(3),
    );
    final seedDistances = appState.products
        .map(
          (product) =>
              distanceKm(appState.currentLocation, product.publicLocation),
        )
        .toList();
    expect(seedDistances.reduce((a, b) => a < b ? a : b), lessThan(1));
    final farthestSeedDistance = seedDistances.reduce(
      (a, b) => a > b ? a : b,
    );
    expect(farthestSeedDistance, greaterThan(13));
    expect(farthestSeedDistance, lessThan(15.5));

    final nearby = appState.productsNearby(radiusKm: 1);
    final fiveKm = appState.productsNearby(radiusKm: 5);
    final tenKm = appState.productsNearby(radiusKm: 20);
    expect(fiveKm.length, greaterThan(nearby.length));
    expect(tenKm.length, greaterThan(fiveKm.length));
  });

  test('category and price filters combine, while donations ignore price', () {
    final booksInPriceRange = appState.productsNearby(
      radiusKm: 20,
      category: 'หนังสือ',
      minPrice: 100,
      maxPrice: 200,
    );
    expect(
      booksInPriceRange.map((item) => item.product.id),
      contains('prod_15'),
    );

    final freeClothing = appState.productsNearby(
      radiusKm: 5,
      category: 'เสื้อผ้า & เครื่องแต่งกาย',
      type: ListingType.donate,
      minPrice: 1000,
      maxPrice: 2000,
    );
    expect(freeClothing.map((item) => item.product.id), ['prod_3']);
  });

  test('excludes own and unavailable listings and sorts by nearest', () {
    appState.addProduct(
      ProductModel(
        id: 'nearby-own-test',
        title: 'ประกาศของฉัน',
        description: '',
        price: 10,
        type: ListingType.sell,
        category: 'หนังสือ',
        condition: 'สภาพดี',
        publicLocation: GeoLocation(12.6112, 102.1031),
        locationLabel: 'เขตเมือง',
        imageUrl: '',
        sellerId: 'user_01',
        sellerName: 'ผู้ใช้ทดสอบ',
        sellerAreaLabel: 'เขตเมือง',
      ),
    );
    final sold = appState.products.firstWhere(
      (product) => product.id == 'prod_1',
    );
    final hidden = appState.products.firstWhere(
      (product) => product.id == 'prod_2',
    );
    appState.products[appState.products.indexOf(sold)] = sold.copyWith(
      status: ListingStatus.sold,
    );
    appState.products[appState.products.indexOf(hidden)] = hidden.copyWith(
      status: ListingStatus.hidden,
    );

    final results = appState.productsNearby(radiusKm: 15);
    final resultIds = results.map((item) => item.product.id).toSet();
    expect(resultIds, isNot(contains('nearby-own-test')));
    expect(resultIds, isNot(contains('prod_1')));
    expect(resultIds, isNot(contains('prod_2')));
    for (var index = 1; index < results.length; index++) {
      expect(
        results[index - 1].distanceKm,
        lessThanOrEqualTo(results[index].distanceKm),
      );
    }
  });

  test('exact location is visible to owner only before meetup agreements', () {
    appState.loginWithPhoneAndPassword('0800000002', 'password123');
    final ownerLocation = appState.getExactLocationFor('prod_1', 'user_02');
    expect(ownerLocation, isNotNull);
    expect(ownerLocation!.exactAddress, contains('ตัวอย่าง'));
    final product = appState.products.firstWhere(
      (item) => item.id == 'prod_1',
    );
    expect(
      distanceKm(
            GeoLocation(ownerLocation.exactLat, ownerLocation.exactLng),
            product.publicLocation,
          ) *
          1000,
      inInclusiveRange(100, 300),
    );
    expect(appState.getExactLocationFor('prod_1', 'admin_01'), isNull);

    appState.loginWithPhoneAndPassword('0800000001', 'password123');
    expect(appState.getExactLocationFor('prod_1', 'user_01'), isNull);
  });

  test('guest location falls back to approximate default center', () {
    appState.loginAsGuest();
    expect(appState.currentLocation, kDefaultCenter);
    expect(appState.isLocationApproximate, isTrue);
  });
}
