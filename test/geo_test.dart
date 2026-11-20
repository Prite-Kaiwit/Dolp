import 'package:flutter_test/flutter_test.dart';
import 'package:moor_market/models/geo_location.dart';
import 'package:moor_market/utils/distance.dart';

void main() {
  test('GeoLocation validates coordinates and compares by value', () {
    final first = GeoLocation(12.5, 102.1);
    final same = GeoLocation(12.5, 102.1);
    expect(first, same);
    expect(first.hashCode, same.hashCode);
    expect(() => GeoLocation(90.1, 0), throwsArgumentError);
    expect(() => GeoLocation(0, -180.1), throwsArgumentError);
  });

  test('Haversine distance matches known one-degree distances', () {
    expect(
      distanceKm(GeoLocation(0, 0), GeoLocation(0, 1)),
      closeTo(111.195, 1),
    );
    expect(
      distanceKm(GeoLocation(0, 0), GeoLocation(1, 0)),
      closeTo(111.195, 1),
    );
    expect(distanceKm(GeoLocation(12.6, 102.1), GeoLocation(12.6, 102.1)), 0);
  });

  test('distance formatting rounds meters to 50 and switches at one km', () {
    expect(formatDistance(0.3), 'ห่าง 300 ม.');
    expect(formatDistance(0.999), 'ห่าง 1000 ม.');
    expect(formatDistance(1.0), 'ห่าง 1.0 กม.');
    expect(formatDistance(1.24), 'ห่าง 1.2 กม.');
    expect(formatDistance(12.0), 'ห่าง 12.0 กม.');
  });

  test('obfuscation is stable, distinct by product, and within 100-300 m', () {
    final exact = GeoLocation(12.6112, 102.1031);
    final first = obfuscate(exact, 'product-a');
    final repeated = obfuscate(exact, 'product-a');
    final other = obfuscate(exact, 'product-b');

    expect(first, repeated);
    expect(first, isNot(other));
    final offsetMeters = distanceKm(exact, first) * 1000;
    expect(offsetMeters, inInclusiveRange(100, 300));
  });
}
