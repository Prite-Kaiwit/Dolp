import '../utils/json_helpers.dart';

class GeoLocation {
  final double lat;
  final double lng;

  factory GeoLocation(double lat, double lng) {
    if (!lat.isFinite || lat < -90 || lat > 90) {
      throw ArgumentError.value(lat, 'lat', 'Must be between -90 and 90.');
    }
    if (!lng.isFinite || lng < -180 || lng > 180) {
      throw ArgumentError.value(lng, 'lng', 'Must be between -180 and 180.');
    }
    return GeoLocation._(lat, lng);
  }

  const GeoLocation._(this.lat, this.lng);

  Map<String, Object> toJson() => {'lat': lat, 'lng': lng};

  factory GeoLocation.fromJson(Map<String, dynamic> json) {
    final latitude = jsonDouble(json['lat']);
    final longitude = jsonDouble(json['lng']);
    if (latitude < -90 ||
        latitude > 90 ||
        longitude < -180 ||
        longitude > 180) {
      return GeoLocation(0, 0);
    }
    return GeoLocation(latitude, longitude);
  }

  @override
  bool operator ==(Object other) =>
      other is GeoLocation && other.lat == lat && other.lng == lng;

  @override
  int get hashCode => Object.hash(lat, lng);
}
