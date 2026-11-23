import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'media_file_store_platform.dart';
import 'persistence_store.dart';

class SharedPreferencesPersistenceStore implements PersistenceStore {
  static const storageKey = 'dolp.persistence.v1';
  final SharedPreferencesAsync _preferences;
  final _media = createPlatformMediaFileStore();

  SharedPreferencesPersistenceStore({SharedPreferencesAsync? preferences})
    : _preferences = preferences ?? SharedPreferencesAsync();

  @override
  Future<String?> load() => _preferences.getString(storageKey);

  @override
  Future<void> save(String payload) async {
    await _preferences.setString(storageKey, payload);
  }

  @override
  Future<void> clear() async {
    final keys = await _preferences.getKeys();
    for (final key in keys.where(
      (key) => key.startsWith('dolp.persistence.'),
    )) {
      await _preferences.remove(key);
    }
    if (!kIsWeb) await _media.clear();
  }

  @override
  Future<void> backupCorrupted(String payload) async {
    await _preferences.setString(
      'dolp.persistence.corrupted.${DateTime.now().toUtc().microsecondsSinceEpoch}',
      payload,
    );
  }

  @override
  Future<void> saveImage(String key, Uint8List bytes) async {
    if (!kIsWeb) await _media.write(key, bytes);
  }

  @override
  Future<Uint8List?> loadImage(String key) async =>
      kIsWeb ? null : _media.read(key);

  @override
  Future<void> deleteUnreferencedImages(Set<String> referencedKeys) async {
    if (!kIsWeb) await _media.deleteUnreferenced(referencedKeys);
  }
}
