import 'dart:async';
import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import 'persistence_store.dart';

/// Stores AppState's shared data in Cloud Firestore, one document per record,
/// so every device sees the same users, listings, chats and orders.
///
/// Device-only state (the signed-in user, cart and ID sequences) stays in the
/// wrapped [local] store. Writes are diffed against the last data seen from
/// Firestore, so only records that changed on this device are written.
///
/// Prototype only: sign-in is still the local mock, so Firestore security
/// rules cannot tell users apart. Do not put real personal data in it.
class FirestorePersistenceStore implements PersistenceStore {
  FirestorePersistenceStore({
    required FirebaseFirestore firestore,
    required PersistenceStore local,
  }) : _db = firestore,
       _localStore = local;

  final FirebaseFirestore _db;
  final PersistenceStore _localStore;

  /// Envelope keys that hold lists of records with an `id` field.
  static const recordCollections = [
    'users',
    'products',
    'orders',
    'reviews',
    'conversations',
    'meetupAgreements',
    'pickupPoints',
    'reports',
    'notifications',
  ];

  /// Envelope keys that hold maps; each entry becomes one document.
  static const mapCollections = [
    'credentials',
    'privateProductLocations',
    'reservedListingPreviousStatus',
    'suspendedUserReasons',
    'areaAlertSubscriptions',
  ];

  /// Envelope keys that hold lists of strings; each string is one document.
  static const setCollections = ['blockedUserPairs', 'safetyTipsAcknowledgedBy'];

  /// Envelope keys kept only on this device.
  static const localOnlyKeys = [
    'currentUserId',
    'cartItems',
    'notificationSequence',
    'orderSequence',
    'chatSequence',
  ];

  static const imagesCollection = 'images';
  static const _maxBatchWrites = 450;

  /// Last known server state: collection -> doc id -> canonical JSON.
  final Map<String, Map<String, String>> _synced = {};
  final _remoteChanges = StreamController<void>.broadcast();
  final List<StreamSubscription<QuerySnapshot<Map<String, dynamic>>>>
  _subscriptions = [];

  static List<String> get _allCollections => [
    ...recordCollections,
    ...mapCollections,
    ...setCollections,
  ];

  @override
  Stream<void> get remoteChanges {
    if (_subscriptions.isEmpty) _listen();
    return _remoteChanges.stream;
  }

  void _listen() {
    for (final name in _allCollections) {
      _subscriptions.add(
        _db.collection(name).snapshots().listen((snapshot) {
          if (snapshot.metadata.hasPendingWrites) return;
          final known = _synced[name] ?? const {};
          final changed = snapshot.docChanges.any((change) {
            final id = change.doc.id;
            if (change.type == DocumentChangeType.removed) {
              return known.containsKey(id);
            }
            return known[id] != canonicalJson(change.doc.data());
          });
          if (changed) _remoteChanges.add(null);
        }, onError: (Object error) => debugPrint('Firestore listen: $error')),
      );
    }
  }

  @override
  Future<String?> load() async {
    final localRaw = await _localStore.load();
    final localData = localRaw == null
        ? <String, dynamic>{}
        : jsonDecode(localRaw) as Map<String, dynamic>;

    final remote = <String, Map<String, Map<String, dynamic>>>{};
    for (final name in _allCollections) {
      final snapshot = await _db.collection(name).get();
      remote[name] = {for (final doc in snapshot.docs) doc.id: doc.data()};
    }

    // Empty database: keep local data (or seed data) and upload it on save.
    if (remote.values.every((docs) => docs.isEmpty)) {
      _synced.clear();
      // A local payload holding only device keys cannot rebuild the data.
      return localData.containsKey('users') ? localRaw : null;
    }

    _synced
      ..clear()
      ..addAll({
        for (final entry in remote.entries)
          entry.key: {
            for (final doc in entry.value.entries)
              doc.key: canonicalJson(doc.value),
          },
      });

    final data = <String, dynamic>{
      'schemaVersion': localData['schemaVersion'] ?? 1,
      for (final key in localOnlyKeys)
        if (localData.containsKey(key)) key: localData[key],
      for (final name in recordCollections) name: remote[name]!.values.toList(),
      for (final name in mapCollections)
        name: {
          for (final doc in remote[name]!.values) doc['key']: doc['value'],
        },
      for (final name in setCollections)
        name: [for (final doc in remote[name]!.values) doc['value']],
    };
    return jsonEncode(data);
  }

  @override
  Future<void> save(String payload) async {
    final data = jsonDecode(payload) as Map<String, dynamic>;
    await _localStore.save(
      jsonEncode({
        'schemaVersion': data['schemaVersion'],
        for (final key in localOnlyKeys) key: data[key],
      }),
    );

    final writes = <void Function(WriteBatch)>[];
    final pending = <String, Map<String, String?>>{};
    for (final entry in documentsFromEnvelope(data).entries) {
      final name = entry.key;
      final desired = entry.value;
      final known = _synced[name] ?? const {};
      final collection = _db.collection(name);
      for (final doc in desired.entries) {
        final json = canonicalJson(doc.value);
        if (known[doc.key] == json) continue;
        writes.add((batch) => batch.set(collection.doc(doc.key), doc.value));
        (pending[name] ??= {})[doc.key] = json;
      }
      for (final id in known.keys) {
        if (desired.containsKey(id)) continue;
        writes.add((batch) => batch.delete(collection.doc(id)));
        (pending[name] ??= {})[id] = null;
      }
    }

    for (var start = 0; start < writes.length; start += _maxBatchWrites) {
      final batch = _db.batch();
      for (final write in writes.skip(start).take(_maxBatchWrites)) {
        write(batch);
      }
      await batch.commit();
    }

    for (final entry in pending.entries) {
      final known = _synced[entry.key] ??= {};
      for (final doc in entry.value.entries) {
        if (doc.value == null) {
          known.remove(doc.key);
        } else {
          known[doc.key] = doc.value!;
        }
      }
    }
  }

  /// Splits an AppState envelope into collection -> doc id -> document.
  @visibleForTesting
  static Map<String, Map<String, Map<String, dynamic>>> documentsFromEnvelope(
    Map<String, dynamic> data,
  ) {
    final result = <String, Map<String, Map<String, dynamic>>>{};
    for (final name in recordCollections) {
      result[name] = {
        for (final item in (data[name] as List? ?? const []))
          docId((item as Map)['id'] as String): Map<String, dynamic>.from(item),
      };
    }
    for (final name in mapCollections) {
      final map = data[name] as Map? ?? const {};
      result[name] = {
        for (final entry in map.entries)
          docId(entry.key as String): {
            'key': entry.key,
            'value': entry.value,
          },
      };
    }
    for (final name in setCollections) {
      result[name] = {
        for (final value in (data[name] as List? ?? const []))
          docId(value as String): {'value': value},
      };
    }
    return result;
  }

  /// Firestore doc IDs cannot contain `/` or be `.`/`..`.
  @visibleForTesting
  static String docId(String key) {
    final encoded = key.replaceAll('%', '%25').replaceAll('/', '%2F');
    return encoded == '.' || encoded == '..' ? '%$encoded' : encoded;
  }

  /// JSON with sorted keys, so equal documents compare equal.
  @visibleForTesting
  static String canonicalJson(Object? value) => jsonEncode(_sorted(value));

  static Object? _sorted(Object? value) {
    if (value is Map) {
      final keys = value.keys.map((key) => '$key').toList()..sort();
      return {for (final key in keys) key: _sorted(value[key])};
    }
    if (value is List) return value.map(_sorted).toList();
    if (value is Blob) return base64Encode(value.bytes);
    return value;
  }

  @override
  Future<void> clear() async {
    await _localStore.clear();
  }

  @override
  Future<void> backupCorrupted(String payload) =>
      _localStore.backupCorrupted(payload);

  @override
  Future<void> saveImage(String key, Uint8List bytes) async {
    await _localStore.saveImage(key, bytes);
    final doc = _db.collection(imagesCollection).doc(docId(key));
    if ((await doc.get()).exists) return;
    await doc.set({'data': Blob(bytes), 'size': bytes.length});
  }

  @override
  Future<Uint8List?> loadImage(String key) async {
    final cached = await _localStore.loadImage(key);
    if (cached != null) return cached;
    final doc = await _db.collection(imagesCollection).doc(docId(key)).get();
    final blob = doc.data()?['data'];
    if (blob is! Blob) return null;
    await _localStore.saveImage(key, blob.bytes);
    return blob.bytes;
  }

  /// Only the local cache is pruned. Another device may reference an image
  /// this device has not seen yet, so shared images are never deleted here.
  @override
  Future<void> deleteUnreferencedImages(Set<String> referencedKeys) =>
      _localStore.deleteUnreferencedImages(referencedKeys);

  Future<void> dispose() async {
    for (final subscription in _subscriptions) {
      await subscription.cancel();
    }
    await _remoteChanges.close();
  }
}
