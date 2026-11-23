import 'dart:io';
import 'dart:typed_data';

import 'package:path_provider/path_provider.dart';

import 'media_file_store.dart';

MediaFileStore createPlatformMediaFileStore() => _IoMediaFileStore();

class _IoMediaFileStore implements MediaFileStore {
  Future<Directory> _directory() async {
    final root = await getApplicationSupportDirectory();
    final directory = Directory(
      '${root.path}${Platform.pathSeparator}dolp_media',
    );
    await directory.create(recursive: true);
    return directory;
  }

  @override
  Future<void> write(String key, Uint8List bytes) async {
    final file = File(
      '${(await _directory()).path}${Platform.pathSeparator}$key',
    );
    await file.writeAsBytes(bytes, flush: true);
  }

  @override
  Future<Uint8List?> read(String key) async {
    final file = File(
      '${(await _directory()).path}${Platform.pathSeparator}$key',
    );
    return await file.exists() ? file.readAsBytes() : null;
  }

  @override
  Future<void> deleteUnreferenced(Set<String> referencedKeys) async {
    final directory = await _directory();
    await for (final entity in directory.list()) {
      if (entity is File &&
          !referencedKeys.contains(entity.uri.pathSegments.last)) {
        await entity.delete();
      }
    }
  }

  @override
  Future<void> clear() async {
    final directory = await _directory();
    if (await directory.exists()) {
      await directory.delete(recursive: true);
    }
  }
}
