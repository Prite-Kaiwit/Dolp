import 'package:flutter_test/flutter_test.dart';
import 'package:moor_market/auth/phone_auth_service.dart';
import 'package:moor_market/constants/categories.dart';
import 'package:moor_market/models/geo_location.dart';
import 'package:moor_market/models/shop_profile.dart';
import 'package:moor_market/models/user.dart';
import 'package:moor_market/utils/shop_validation.dart';
import 'package:moor_market/state/app_state.dart';

void main() {
  final appState = AppState();

  late List<UserModel> savedUsers;

  setUp(() {
    savedUsers = List.of(appState.users);
    appState.loginAsGuest();
  });

  tearDown(() {
    appState.users
      ..clear()
      ..addAll(savedUsers);
    appState.loginAsGuest();
  });

  ShopProfile validShop({String name = 'ร้านมือสองทดสอบ'}) => ShopProfile(
    shopName: name,
    description: 'ขายของมือสอง',
    categories: [kListingCategories.first],
    location: GeoLocation(13.75, 100.5),
    locationLabel: 'ตลาดนัด',
    openingHours: const OpeningHours(
      days: {1: DayHours(openMinute: 540, closeMinute: 1080)},
    ),
  );

  test('verified phone signs in to its account and reads the role', () {
    expect(
      appState.signInVerifiedPhone('0899999999'),
      PhoneSignInResult.needsRegistration,
    );
    expect(appState.currentUser.role, UserRole.guest);

    expect(
      appState.signInVerifiedPhone('0800000009', authUid: 'uid-admin'),
      PhoneSignInResult.signedIn,
    );
    expect(appState.currentUser.role, UserRole.admin);
    expect(appState.currentUser.authUid, 'uid-admin');
    expect(appState.userById('admin_01')!.authUid, 'uid-admin');
  });

  test('suspended accounts cannot sign in', () {
    final index = appState.users.indexWhere((user) => user.id == 'user_02');
    final original = appState.users[index];
    appState.users[index] = original.copyWith(isSuspended: true);
    expect(
      appState.signInVerifiedPhone('0800000002'),
      PhoneSignInResult.suspended,
    );
    expect(appState.currentUser.role, UserRole.guest);
    appState.users[index] = original;
  });

  test('registration rejects duplicate phones and adds verified accounts', () {
    expect(
      appState.registerVerifiedPhone(name: 'ชื่อซ้ำ', phone: '0800000001'),
      isFalse,
    );

    const phone = '0891234567';
    expect(
      appState.registerVerifiedPhone(
        name: 'ผู้ใช้ใหม่',
        phone: phone,
        authUid: 'uid-new',
      ),
      isTrue,
    );
    expect(appState.currentUser.phoneVerified, isTrue);
    expect(appState.currentUser.authUid, 'uid-new');

    appState.loginAsGuest();
    expect(appState.signInVerifiedPhone(phone), PhoneSignInResult.signedIn);
    expect(appState.currentUser.name, 'ผู้ใช้ใหม่');
  });

  test('Thai numbers convert to international format', () {
    expect(toThaiE164('0812345678'), '+66812345678');
    expect(toThaiE164('081-234-5678'), '+66812345678');
    expect(toThaiE164('66812345678'), '+66812345678');
  });

  test('local phone auth accepts only its fixed code', () async {
    final service = LocalPhoneAuthService();
    final request = await service.sendCode('0812345678');
    await expectLater(
      service.verifyCode(request, '000000'),
      throwsA(isA<PhoneAuthFailure>()),
    );
    expect(await service.verifyCode(request, '123456'), isNotEmpty);
  });

  group('shop accounts', () {
    test('registers a shop account with its profile', () {
      final shop = validShop();
      expect(
        appState.registerVerifiedPhone(
          name: 'เจ้าของ',
          phone: '0895550001',
          accountType: AccountType.shop,
          shop: shop,
        ),
        isTrue,
      );
      expect(appState.currentUser.isShop, isTrue);
      expect(appState.currentUser.displayName, shop.shopName);
      expect(appState.currentUser.homeLabel, shop.locationLabel);
      expect(appState.currentUser.homeLat, shop.location.lat);
      expect(appState.currentUser.homeLng, shop.location.lng);
    });

    test('refuses shop registration without a valid profile', () {
      final count = appState.users.length;
      expect(
        appState.registerVerifiedPhone(
          name: 'x',
          phone: '0895550002',
          accountType: AccountType.shop,
        ),
        isFalse,
      );
      expect(
        appState.registerVerifiedPhone(
          name: 'x',
          phone: '0895550002',
          accountType: AccountType.shop,
          shop: validShop(name: ''),
        ),
        isFalse,
      );
      expect(appState.users.length, count);
    });

    test('person can convert to shop and keeps listings', () {
      appState.signInVerifiedPhone('0800000002');
      int mine() =>
          appState.products.where((p) => p.sellerId == 'user_02').length;
      final before = mine();
      expect(appState.convertCurrentUserToShop(validShop()), isNull);
      expect(mine(), before);
      expect(appState.currentUser.isShop, isTrue);
      expect(appState.userById('user_02')!.isShop, isTrue);
    });

    test('converting twice is refused', () {
      appState.signInVerifiedPhone('0800000002');
      expect(appState.convertCurrentUserToShop(validShop()), isNull);
      expect(
        appState.convertCurrentUserToShop(validShop()),
        'บัญชีนี้เป็นร้านค้าอยู่แล้ว',
      );
    });

    test('guest cannot convert', () {
      appState.loginAsGuest();
      expect(appState.convertCurrentUserToShop(validShop()), isNotNull);
    });

    test('updateShopProfile refused for person, applied for shop', () {
      appState.signInVerifiedPhone('0800000002');
      expect(appState.updateShopProfile(validShop()), 'บัญชีนี้ไม่ใช่ร้านค้า');
      appState.convertCurrentUserToShop(validShop());
      expect(appState.updateShopProfile(validShop(name: 'ชื่อใหม่')), isNull);
      expect(appState.currentUser.displayName, 'ชื่อใหม่');
      expect(appState.userById('user_02')!.displayName, 'ชื่อใหม่');
    });

    test('validateShopProfile reports each error', () {
      final ok = validShop();
      expect(validateShopProfile(ok), isNull);
      expect(
        validateShopProfile(ok.copyWith(shopName: '  ')),
        'กรุณากรอกชื่อร้าน',
      );
      expect(
        validateShopProfile(ok.copyWith(shopName: 'ก' * 61)),
        'ชื่อร้านยาวเกิน 60 ตัวอักษร',
      );
      expect(
        validateShopProfile(ok.copyWith(description: 'ก' * 501)),
        'คำอธิบายร้านยาวเกิน 500 ตัวอักษร',
      );
      expect(
        validateShopProfile(ok.copyWith(categories: [])),
        'เลือกหมวดสินค้าอย่างน้อย 1 หมวด',
      );
      expect(
        validateShopProfile(
          ok.copyWith(categories: kListingCategories.take(6).toList()),
        ),
        'เลือกหมวดสินค้าได้ไม่เกิน 5 หมวด',
      );
      expect(
        validateShopProfile(ok.copyWith(categories: ['ไม่มีหมวดนี้'])),
        'หมวดสินค้าไม่ถูกต้อง',
      );
      expect(
        validateShopProfile(ok.copyWith(openingHours: const OpeningHours())),
        'กรุณาระบุเวลาเปิดอย่างน้อย 1 วัน',
      );
      expect(
        validateShopProfile(ok.copyWith(locationLabel: ' ')),
        'กรุณาเลือกที่ตั้งร้าน',
      );
    });
  });
}
