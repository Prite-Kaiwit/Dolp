import 'package:flutter_test/flutter_test.dart';
import 'package:moor_market/models/geo_location.dart';
import 'package:moor_market/models/shop_profile.dart';
import 'package:moor_market/utils/shop_validation.dart';
import 'package:moor_market/utils/thai_time.dart';

ShopProfile completeShop() => ShopProfile(
  shopName: 'ร้านมือสอง',
  description: 'ขายของมือสอง',
  categories: const ['หนังสือ', 'เสื้อผ้า & เครื่องแต่งกาย'],
  location: GeoLocation(13.75, 100.5),
  locationLabel: 'ตลาดนัด',
  openingHours: OpeningHours(
    days: {
      1: const DayHours(openMinute: 540, closeMinute: 1200),
      6: const DayHours(openMinute: 1080, closeMinute: 120),
    },
  ),
);

void main() {
  test('isOpenAt handles same-day hours', () {
    final h = OpeningHours(
      days: {1: const DayHours(openMinute: 540, closeMinute: 1200)},
    );
    expect(h.isOpenAt(DateTime(2026, 11, 23, 10)), isTrue); // Monday 10:00
    expect(h.isOpenAt(DateTime(2026, 11, 23, 20, 1)), isFalse);
    expect(h.isOpenAt(DateTime(2026, 11, 24, 10)), isFalse); // Tuesday closed
  });

  test('isOpenAt handles hours past midnight', () {
    final h = OpeningHours(
      days: {1: const DayHours(openMinute: 1080, closeMinute: 120)},
    );
    expect(h.isOpenAt(DateTime(2026, 11, 23, 23)), isTrue);
    expect(h.isOpenAt(DateTime(2026, 11, 24, 1)), isTrue); // Tue 01:00
    expect(h.isOpenAt(DateTime(2026, 11, 24, 3)), isFalse);
  });

  test('Sunday overnight tail carries into Monday', () {
    final h = OpeningHours(
      days: {7: const DayHours(openMinute: 1080, closeMinute: 120)},
    );
    expect(h.isOpenAt(DateTime(2026, 11, 30, 1)), isTrue); // Mon 01:00
  });

  test('isOpenAt boundaries: open at openMinute, closed at closeMinute', () {
    final h = OpeningHours(
      days: {1: const DayHours(openMinute: 540, closeMinute: 1200)},
    );
    expect(h.isOpenAt(DateTime(2026, 11, 23, 8, 59)), isFalse);
    expect(h.isOpenAt(DateTime(2026, 11, 23, 9)), isTrue);
    expect(h.isOpenAt(DateTime(2026, 11, 23, 19, 59)), isTrue);
    expect(h.isOpenAt(DateTime(2026, 11, 23, 20)), isFalse);
  });

  test('overnight tail is closed exactly at closeMinute', () {
    final h = OpeningHours(
      days: {1: const DayHours(openMinute: 1080, closeMinute: 120)},
    );
    expect(h.isOpenAt(DateTime(2026, 11, 24, 1, 59)), isTrue);
    expect(h.isOpenAt(DateTime(2026, 11, 24, 2)), isFalse);
  });

  test('malformed opening-hours day is dropped, not read as 00:00-00:00', () {
    final hours = OpeningHours.fromJson({
      '1': {'openMinute': 540},
      '2': {'openMinute': 'x', 'closeMinute': 600},
      '3': {'openMinute': 540, 'closeMinute': 1080},
    });
    expect(hours.days.keys, [3]);
    expect(
      OpeningHours.fromJson({
        '1': {'openMinute': 540},
      }).isEmpty,
      isTrue,
    );
  });

  test('validateShopProfile rejects open == close', () {
    final bad = completeShop().copyWith(
      openingHours: OpeningHours(
        days: {1: const DayHours(openMinute: 600, closeMinute: 600)},
      ),
    );
    expect(validateShopProfile(bad), 'เวลาเปิดและปิดต้องไม่ตรงกัน');
    expect(validateShopProfile(completeShop()), isNull);
  });

  test('toThaiTime shifts UTC by 7 hours', () {
    expect(toThaiTime(DateTime.utc(2026, 11, 23, 20)).hour, 3);
  });

  test('ShopProfile JSON round trip and isComplete', () {
    final shop = completeShop();
    expect(shop.isComplete, isTrue);
    final copy = ShopProfile.fromJson(shop.toJson());
    expect(copy.toJson(), shop.toJson());
    expect(
      copy.openingHours.days[6],
      const DayHours(openMinute: 1080, closeMinute: 120),
    );
    expect(shop.copyWith(shopName: '  ').isComplete, isFalse);
    expect(shop.copyWith(categories: const []).isComplete, isFalse);
    expect(
      shop.copyWith(openingHours: const OpeningHours()).isComplete,
      isFalse,
    );
  });

  test('ShopProfile.fromJson without location falls back and stays valid', () {
    final shop = ShopProfile.fromJson({'shopName': 'ก'});
    expect(shop.location.lat, 0);
    expect(shop.isComplete, isFalse);
  });
}
