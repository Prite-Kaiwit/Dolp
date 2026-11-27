/// Thailand has no daylight saving time; it is always UTC+7.
const Duration _thaiOffset = Duration(hours: 7);

DateTime toThaiTime(DateTime t) => t.toUtc().add(_thaiOffset);

DateTime thaiNow() => toThaiTime(DateTime.now());
