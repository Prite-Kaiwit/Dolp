import 'dart:typed_data';

abstract interface class MediaFileStore {
  Future<void> write(String key, Uint8List bytes);
  Future<Uint8List?> read(String key);
  Future<void> deleteUnreferenced(Set<String> referencedKeys);
  Future<void> clear();
}

MediaFileStore createPlatformMediaFileStore() => _MemoryMediaFileStore();

class _MemoryMediaFileStore implements MediaFileStore {
  final Map<String, Uint8List> _images = {};

  @override
  Future<void> write(String key, Uint8List bytes) async {
    _images[key] = Uint8List.fromList(bytes);
  }

  @override
  Future<Uint8List?> read(String key) async => _images[key];

  @override
  Future<void> deleteUnreferenced(Set<String> referencedKeys) async {
    _images.removeWhere((key, _) => !referencedKeys.contains(key));
  }

  @override
  Future<void> clear() async => _images.clear();
}
