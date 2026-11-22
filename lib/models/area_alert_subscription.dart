import 'geo_location.dart';

class AreaAlertSubscription {
  final String userId;
  final bool enabled;
  final double radiusKm;
  final List<String> categories;
  final GeoLocation center;

  const AreaAlertSubscription({
    required this.userId,
    required this.center,
    this.enabled = false,
    this.radiusKm = 5,
    this.categories = const [],
  });

  AreaAlertSubscription copyWith({
    String? userId,
    bool? enabled,
    double? radiusKm,
    List<String>? categories,
    GeoLocation? center,
  }) {
    return AreaAlertSubscription(
      userId: userId ?? this.userId,
      enabled: enabled ?? this.enabled,
      radiusKm: radiusKm ?? this.radiusKm,
      categories: categories ?? this.categories,
      center: center ?? this.center,
    );
  }
}
