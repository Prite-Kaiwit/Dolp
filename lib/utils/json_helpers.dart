DateTime jsonDateTime(Object? value, [DateTime? fallback]) {
  if (value is String) {
    final parsed = DateTime.tryParse(value);
    if (parsed != null) return parsed.toUtc();
  }
  return (fallback ?? DateTime.fromMillisecondsSinceEpoch(0)).toUtc();
}

DateTime? jsonNullableDateTime(Object? value) {
  if (value is! String) return null;
  return DateTime.tryParse(value)?.toUtc();
}

T jsonEnum<T extends Enum>(List<T> values, Object? value, T fallback) {
  for (final item in values) {
    if (item.name == value) return item;
  }
  return fallback;
}

String jsonString(Object? value, [String fallback = '']) =>
    value is String ? value : fallback;

int jsonInt(Object? value, [int fallback = 0]) =>
    value is num ? value.toInt() : fallback;

double jsonDouble(Object? value, [double fallback = 0]) =>
    value is num && value.toDouble().isFinite ? value.toDouble() : fallback;

bool jsonBool(Object? value, [bool fallback = false]) =>
    value is bool ? value : fallback;

Map<String, dynamic> jsonObject(Object? value) =>
    value is Map<String, dynamic> ? value : const {};

List<dynamic> jsonList(Object? value) => value is List ? value : const [];
