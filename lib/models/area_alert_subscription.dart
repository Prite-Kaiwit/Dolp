import 'geo_location.dart';
import '../utils/json_helpers.dart';

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

  Map<String, Object?> toJson() => {
    'userId': userId,
    'enabled': enabled,
    'radiusKm': radiusKm,
    'categories': categories,
    'center': center.toJson(),
  };

  factory AreaAlertSubscription.fromJson(Map<String, dynamic> json) =>
      AreaAlertSubscription(
        userId: jsonString(json['userId']),
        enabled: jsonBool(json['enabled']),
        radiusKm: jsonDouble(json['radiusKm'], 5).clamp(1, 20).toDouble(),
        categories: jsonList(json['categories']).whereType<String>().toList(),
        center: GeoLocation.fromJson(jsonObject(json['center'])),
      );
}
