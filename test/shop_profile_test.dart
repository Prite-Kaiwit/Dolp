import 'package:flutter_test/flutter_test.dart';
import 'package:moor_market/models/geo_location.dart';
import 'package:moor_market/models/shop_profile.dart';
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
