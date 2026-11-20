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

  @override
  bool operator ==(Object other) =>
      other is GeoLocation && other.lat == lat && other.lng == lng;

  @override
  int get hashCode => Object.hash(lat, lng);
}
