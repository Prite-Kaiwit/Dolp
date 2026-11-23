import 'dart:typed_data';

import 'persistence_store.dart';

class InMemoryPersistenceStore implements PersistenceStore {
  String? payload;
  final Map<String, Uint8List> images = {};
  final List<String> corruptedBackups = [];
  Object? failure;

  void _throwIfConfigured() {
    if (failure case final error?) throw error;
  }

  @override
  Future<String?> load() async {
    _throwIfConfigured();
    return payload;
  }

  @override
  Future<void> save(String payload) async {
    _throwIfConfigured();
    this.payload = payload;
  }

  @override
  Future<void> clear() async {
    _throwIfConfigured();
    payload = null;
    images.clear();
    corruptedBackups.clear();
  }

  @override
  Future<void> backupCorrupted(String payload) async {
    corruptedBackups.add(payload);
  }

  @override
  Future<void> saveImage(String key, Uint8List bytes) async {
    images[key] = Uint8List.fromList(bytes);
  }

  @override
  Future<Uint8List?> loadImage(String key) async {
    final bytes = images[key];
    return bytes == null ? null : Uint8List.fromList(bytes);
  }

  @override
  Future<void> deleteUnreferencedImages(Set<String> referencedKeys) async {
    images.removeWhere((key, _) => !referencedKeys.contains(key));
  }
}
