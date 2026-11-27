import '../utils/json_helpers.dart';
import 'geo_location.dart';

class DayHours {
  /// Minutes since midnight. `closeMinute <= openMinute` means the shop
  /// closes after midnight, on the following day.
  final int openMinute;
  final int closeMinute;

  const DayHours({required this.openMinute, required this.closeMinute});

  bool get isOvernight => closeMinute <= openMinute;

  Map<String, Object?> toJson() => {
    'openMinute': openMinute,
    'closeMinute': closeMinute,
  };

  /// Returns null when either minute is missing or not a number, so a
  /// malformed day is dropped instead of reading as 00:00-00:00.
  static DayHours? tryFromJson(Map<String, dynamic> json) {
    final open = json['openMinute'];
    final close = json['closeMinute'];
    if (open is! num || close is! num) return null;
    return DayHours(
      openMinute: open.toInt().clamp(0, 1439),
      closeMinute: close.toInt().clamp(0, 1439),
    );
  }

  @override
  bool operator ==(Object other) =>
      other is DayHours &&
      other.openMinute == openMinute &&
      other.closeMinute == closeMinute;

  @override
  int get hashCode => Object.hash(openMinute, closeMinute);
}

class OpeningHours {
  /// Key is [DateTime.weekday], 1 (Monday) to 7 (Sunday).
  final Map<int, DayHours> days;

  const OpeningHours({this.days = const {}});

  bool get isEmpty => days.isEmpty;

  /// [thaiTime] must already be in Thailand time (see `toThaiTime`).
  bool isOpenAt(DateTime thaiTime) {
    final minute = thaiTime.hour * 60 + thaiTime.minute;
    final today = days[thaiTime.weekday];
    if (today != null) {
      if (today.isOvernight) {
        if (minute >= today.openMinute) return true;
      } else if (minute >= today.openMinute && minute < today.closeMinute) {
        return true;
      }
    }
    final previousDay = thaiTime.weekday == DateTime.monday
        ? DateTime.sunday
        : thaiTime.weekday - 1;
    final yesterday = days[previousDay];
    return yesterday != null &&
        yesterday.isOvernight &&
        minute < yesterday.closeMinute;
  }

  Map<String, Object?> toJson() => {
    for (final entry in days.entries) '${entry.key}': entry.value.toJson(),
  };

  factory OpeningHours.fromJson(Map<String, dynamic> json) {
    final days = <int, DayHours>{};
    for (final entry in json.entries) {
      final weekday = int.tryParse(entry.key);
      final value = entry.value;
      if (weekday == null || weekday < 1 || weekday > 7) continue;
      if (value is! Map<String, dynamic>) continue;
      final day = DayHours.tryFromJson(value);
      if (day != null) days[weekday] = day;
    }
    return OpeningHours(days: days);
  }
}

class ShopProfile {
  final String shopName;
  final String description;
  final List<String> categories;
  final GeoLocation location;
  final String locationLabel;
  final OpeningHours openingHours;

  const ShopProfile({
    required this.shopName,
    this.description = '',
    this.categories = const [],
    required this.location,
    this.locationLabel = '',
    this.openingHours = const OpeningHours(),
  });

  bool get isComplete =>
      shopName.trim().isNotEmpty &&
      categories.isNotEmpty &&
      !openingHours.isEmpty;

  Map<String, Object?> toJson() => {
    'shopName': shopName,
    'description': description,
    'categories': categories,
    'location': location.toJson(),
    'locationLabel': locationLabel,
    'openingHours': openingHours.toJson(),
  };

  factory ShopProfile.fromJson(Map<String, dynamic> json) => ShopProfile(
    shopName: jsonString(json['shopName']),
    description: jsonString(json['description']),
    categories: [
      for (final item in jsonList(json['categories']))
        if (item is String) item,
    ],
    location: json['location'] is Map<String, dynamic>
        ? GeoLocation.fromJson(json['location'] as Map<String, dynamic>)
        : GeoLocation(0, 0),
    locationLabel: jsonString(json['locationLabel']),
    openingHours: OpeningHours.fromJson(jsonObject(json['openingHours'])),
  );

  ShopProfile copyWith({
    String? shopName,
    String? description,
    List<String>? categories,
    GeoLocation? location,
    String? locationLabel,
    OpeningHours? openingHours,
  }) => ShopProfile(
    shopName: shopName ?? this.shopName,
    description: description ?? this.description,
    categories: categories ?? this.categories,
    location: location ?? this.location,
    locationLabel: locationLabel ?? this.locationLabel,
    openingHours: openingHours ?? this.openingHours,
  );
}
