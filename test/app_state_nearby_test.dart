import 'package:flutter_test/flutter_test.dart';
import 'package:moor_market/constants/app_info.dart';
import 'package:moor_market/utils/distance.dart';
import 'package:moor_market/models/geo_location.dart';
import 'package:moor_market/models/product.dart';
import 'package:moor_market/models/shop_profile.dart';
import 'package:moor_market/models/user.dart';
import 'package:moor_market/state/app_state.dart';

void main() {
  final appState = AppState();
  late List<ProductModel> originalProducts;
  late List<UserModel> originalUsers;

  setUp(() {
    originalProducts = List<ProductModel>.from(appState.products);
    originalUsers = List<UserModel>.from(appState.users);
    appState.signInVerifiedPhone('0800000001') == PhoneSignInResult.signedIn;
  });

  tearDown(() {
    appState.deleteProduct('nearby-own-test');
    appState.products = originalProducts;
    for (final id in ['shop_a', 'shop_b', 'shop_c', 'shop_d']) {
      appState.unblockUser(id);
    }
    appState.users = originalUsers;
    appState.loginAsGuest();
  });

  GeoLocation offset(double km) => GeoLocation(
    appState.currentLocation.lat + km / 111.0,
    appState.currentLocation.lng,
  );

  UserModel makeShop(
    String id,
    String name, {
    double km = 1,
    String description = '',
    List<String> categories = const ['หนังสือ'],
    bool suspended = false,
    AccountType accountType = AccountType.shop,
  }) {
    final user = UserModel(
      id: id,
      name: 'owner $id',
      accountType: accountType,
      isSuspended: suspended,
      shop: ShopProfile(
        shopName: name,
        description: description,
        categories: categories,
        location: offset(km),
        openingHours: OpeningHours(
          days: {
            for (var d = 1; d <= 7; d++)
              d: const DayHours(openMinute: 540, closeMinute: 1200),
          },
        ),
      ),
    );
    appState.users.add(user);
    return user;
  }

  void makeListing(
    String id,
    String sellerId,
    String title, {
    String category = 'หนังสือ',
    ListingStatus status = ListingStatus.active,
  }) {
    appState.products.add(
      ProductModel(
        id: id,
        title: title,
        description: '',
        price: 10,
        type: ListingType.sell,
        category: category,
        condition: 'สภาพดี',
        publicLocation: offset(1),
        locationLabel: 'เขตเมือง',
        imageUrl: '',
        sellerId: sellerId,
        sellerName: 'x',
        sellerAreaLabel: 'เขตเมือง',
        status: status,
      ),
    );
  }

  test('finds a shop by its description when it has no matching listing', () {
    makeShop('shop_a', 'ร้านเอ', description: 'ขายสายชาร์จ');
    final results = appState.shopsNearby(query: 'สายชาร์จ');
    expect(results.map((r) => r.shop.id), ['shop_a']);
    expect(results.single.matchingListingCount, 0);
  });

  test('finds a shop by a matching listing', () {
    makeShop('shop_a', 'ร้านเอ');
    makeListing('l1', 'shop_a', 'กล้องฟิล์ม Canon');
    makeListing('l2', 'shop_a', 'เลนส์ canon');
    makeListing('l3', 'shop_a', 'canon เก่า', status: ListingStatus.sold);
    makeListing('l4', 'shop_a', 'หนังสือ');
    final results = appState.shopsNearby(query: 'canon');
    expect(results.map((r) => r.shop.id), ['shop_a']);
    expect(results.single.matchingListingCount, 2);
  });

  test('query is trimmed and case-insensitive', () {
    makeShop('shop_a', 'ร้านเอ', description: 'สายชาร์จ usb-c');
    final results = appState.shopsNearby(query: '  USB-C ');
    expect(results.map((r) => r.shop.id), ['shop_a']);
  });

  test('empty query returns all nearby shops sorted by distance', () {
    makeShop('shop_a', 'ไกล', km: 3);
    makeShop('shop_b', 'ใกล้', km: 1);
    makeListing('l1', 'shop_b', 'อะไรก็ได้');
    final results = appState.shopsNearby();
    expect(results.map((r) => r.shop.id), ['shop_b', 'shop_a']);
    expect(results.first.matchingListingCount, 1);
    expect(results.first.distanceKm, lessThan(results.last.distanceKm));
  });

  test('excludes shops outside radius, suspended, blocked, and self', () {
    makeShop('shop_a', 'ในรัศมี', km: 1);
    makeShop('shop_b', 'ไกลเกิน', km: 50);
    makeShop('shop_c', 'ถูกระงับ', km: 1, suspended: true);
    makeShop('shop_d', 'ถูกบล็อก', km: 1);
    makeShop('user_01', 'ร้านตัวเอง', km: 1);
    expect(appState.blockUser('shop_d'), isNull);
    final results = appState.shopsNearby(radiusKm: 5);
    expect(results.map((r) => r.shop.id), ['shop_a']);
  });

  test('openNowOnly filters by Thai time', () {
    makeShop('shop_a', 'ร้านเอ');
    final open = appState.shopsNearby(
      openNowOnly: true,
      now: DateTime.utc(2026, 11, 23, 3),
    );
    expect(open.map((r) => r.shop.id), ['shop_a']);
    expect(open.single.isOpenNow, isTrue);
    expect(
      appState.shopsNearby(
        openNowOnly: true,
        now: DateTime.utc(2026, 11, 23, 14),
      ),
      isEmpty,
    );
    final all = appState.shopsNearby(now: DateTime.utc(2026, 11, 23, 14));
    expect(all.single.isOpenNow, isFalse);
  });

  test('category filter matches shop categories or matching listings', () {
    makeShop('shop_a', 'ร้านเอ', categories: const ['หนังสือ']);
    makeShop('shop_b', 'ร้านบี', categories: const ['อื่นๆ']);
    makeListing('l1', 'shop_b', 'ตุ๊กตา', category: 'ของเล่น');
    makeShop('shop_c', 'ร้านซี', categories: const ['อื่นๆ']);
    expect(appState.shopsNearby(category: 'หนังสือ').map((r) => r.shop.id), [
      'shop_a',
    ]);
    expect(appState.shopsNearby(category: 'ของเล่น').map((r) => r.shop.id), [
      'shop_b',
    ]);
  });

  test('productsNearby sellerKind shops / people', () {
    makeShop('shop_a', 'ร้านเอ');
    makeListing('l_shop', 'shop_a', 'ของร้าน');
    final shops = appState.productsNearby(
      radiusKm: 20,
      sellerKind: SellerKind.shops,
    );
    expect(shops.map((r) => r.product.id), ['l_shop']);
    final people = appState.productsNearby(
      radiusKm: 20,
      sellerKind: SellerKind.people,
    );
    expect(people.map((r) => r.product.id), isNot(contains('l_shop')));
    expect(people, isNotEmpty);
    final all = appState.productsNearby(radiusKm: 20);
    expect(all.length, shops.length + people.length);
  });

  test('persons with incomplete shop data never appear', () {
    makeShop('shop_a', 'ร้านไม่ครบ', categories: const []);
    makeShop('shop_b', 'คนทั่วไป', accountType: AccountType.person);
    makeListing('l1', 'shop_a', 'ของ');
    expect(appState.shopsNearby(), isEmpty);
    final shops = appState.productsNearby(
      radiusKm: 20,
      sellerKind: SellerKind.shops,
    );
    expect(shops, isEmpty);
  });

  test('sellerDisplayName uses the live name, else the stored one', () {
    makeShop('shop_a', 'ร้านเอ');
    expect(appState.sellerDisplayName('shop_a', 'เก่า'), 'ร้านเอ');
    expect(appState.sellerDisplayName('nobody', 'เก่า'), 'เก่า');
  });

  test('shopsNearby is empty for a suspended current user', () {
    makeShop('shop_a', 'ร้านเอ');
    appState.currentUser = appState.currentUser.copyWith(isSuspended: true);
    expect(appState.shopsNearby(), isEmpty);
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
    final farthestSeedDistance = seedDistances.reduce((a, b) => a > b ? a : b);
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
    appState.signInVerifiedPhone('0800000002') == PhoneSignInResult.signedIn;
    final ownerLocation = appState.getExactLocationFor('prod_1', 'user_02');
    expect(ownerLocation, isNotNull);
    expect(ownerLocation!.exactAddress, contains('ตัวอย่าง'));
    final product = appState.products.firstWhere((item) => item.id == 'prod_1');
    expect(
      distanceKm(
            GeoLocation(ownerLocation.exactLat, ownerLocation.exactLng),
            product.publicLocation,
          ) *
          1000,
      inInclusiveRange(100, 300),
    );
    expect(appState.getExactLocationFor('prod_1', 'admin_01'), isNull);

    appState.signInVerifiedPhone('0800000001') == PhoneSignInResult.signedIn;
    expect(appState.getExactLocationFor('prod_1', 'user_01'), isNull);
  });

  test('guest location falls back to approximate default center', () {
    appState.loginAsGuest();
    expect(appState.currentLocation, kDefaultCenter);
    expect(appState.isLocationApproximate, isTrue);
  });
}
