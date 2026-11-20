import 'dart:math' as math;

import '../models/geo_location.dart';

const double _earthRadiusKm = 6371.0;

double distanceKm(GeoLocation a, GeoLocation b) {
  final lat1 = _toRadians(a.lat);
  final lat2 = _toRadians(b.lat);
  final deltaLat = lat2 - lat1;
  final deltaLng = _toRadians(b.lng - a.lng);

  final haversine =
      math.pow(math.sin(deltaLat / 2), 2) +
      math.cos(lat1) * math.cos(lat2) * math.pow(math.sin(deltaLng / 2), 2);
  final boundedHaversine = haversine.clamp(0.0, 1.0).toDouble();
  final centralAngle =
      2 *
      math.atan2(math.sqrt(boundedHaversine), math.sqrt(1 - boundedHaversine));
  return _earthRadiusKm * centralAngle;
}

String formatDistance(double km) {
  if (!km.isFinite || km < 0) {
    throw ArgumentError.value(km, 'km', 'Must be a finite non-negative value.');
  }
  if (km < 1) {
    final meters = (km * 1000 / 50).round() * 50;
    return 'ห่าง $meters ม.';
  }
  return 'ห่าง ${km.toStringAsFixed(1)} กม.';
}

GeoLocation obfuscate(GeoLocation exact, String productId) {
  final seed = _fnv1a(productId);
  final angleFraction = _unitInterval(_mix(seed));
  final distanceFraction = _unitInterval(_mix(seed ^ 0x9e3779b9));
  final bearing = angleFraction * 2 * math.pi;
  final offsetKm = 0.1 + distanceFraction * 0.2;
  final angularDistance = offsetKm / _earthRadiusKm;
  final latitude = _toRadians(exact.lat);
  final longitude = _toRadians(exact.lng);

  final resultLat = math.asin(
    math.sin(latitude) * math.cos(angularDistance) +
        math.cos(latitude) * math.sin(angularDistance) * math.cos(bearing),
  );
  final resultLng =
      longitude +
      math.atan2(
        math.sin(bearing) * math.sin(angularDistance) * math.cos(latitude),
        math.cos(angularDistance) - math.sin(latitude) * math.sin(resultLat),
      );
  final normalizedLng = (resultLng + 3 * math.pi) % (2 * math.pi) - math.pi;
  return GeoLocation(_toDegrees(resultLat), _toDegrees(normalizedLng));
}

double _toRadians(double degrees) => degrees * math.pi / 180;

double _toDegrees(double radians) => radians * 180 / math.pi;

int _fnv1a(String value) {
  var hash = 0x811c9dc5;
  for (final byte in value.codeUnits) {
    hash = ((hash ^ byte) * 0x01000193) & 0xffffffff;
  }
  return hash;
}

int _mix(int value) {
  var mixed = value & 0xffffffff;
  mixed = ((mixed ^ (mixed >> 16)) * 0x7feb352d) & 0xffffffff;
  mixed = ((mixed ^ (mixed >> 15)) * 0x846ca68b) & 0xffffffff;
  return (mixed ^ (mixed >> 16)) & 0xffffffff;
}

double _unitInterval(int value) => value / 0xffffffff;
