import 'dart:typed_data';

abstract interface class PersistenceStore {
  Future<String?> load();
  Future<void> save(String payload);
  Future<void> clear();
  Future<void> backupCorrupted(String payload);
  Future<void> saveImage(String key, Uint8List bytes);
  Future<Uint8List?> loadImage(String key);
  Future<void> deleteUnreferencedImages(Set<String> referencedKeys);
}
