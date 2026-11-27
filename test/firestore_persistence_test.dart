import 'dart:typed_data';

import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moor_market/models/geo_location.dart';
import 'package:moor_market/models/product.dart';
import 'package:moor_market/models/product_image_data.dart';
import 'package:moor_market/persistence/firestore_persistence_store.dart';
import 'package:moor_market/persistence/in_memory_persistence_store.dart';
import 'package:moor_market/state/app_state.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Future<AppState> device(FakeFirebaseFirestore db) async {
    final state = AppState.createForTesting(
      store: FirestorePersistenceStore(
        firestore: db,
        local: InMemoryPersistenceStore(),
      ),
    );
    await state.initialize();
    return state;
  }

  ProductModel addListing(AppState state, String title) => state.addListing(
    title: title,
    description: 'Shared through Firestore',
    price: 150,
    tradeFor: '',
    type: ListingType.sell,
    category: 'อื่น ๆ',
    condition: 'สภาพดี',
    exactLocation: GeoLocation(12.6112, 102.1031),
    locationLabel: 'ย่านตัวอย่าง',
    exactAddress: 'บ้านเลขที่ 9',
    pickupType: PickupType.discussInChat,
    imageUrl: '',
    productImages: [
      ProductImageData.memory(Uint8List.fromList([1, 2, 3])),
    ],
  );

  test('first device uploads seed data as one document per record', () async {
    final db = FakeFirebaseFirestore();
    final a = await device(db);

    final users = await db.collection('users').get();
    expect(users.docs.length, a.users.length);
    expect(
      (await db.collection('users').doc('user_02').get()).data()?['id'],
      'user_02',
    );
    final products = await db.collection('products').get();
    expect(products.docs.length, a.products.length);
    a.dispose();
  });

  test('a listing made on one device shows on another device', () async {
    final db = FakeFirebaseFirestore();
    final a = await device(db);
    expect(
      a.signInVerifiedPhone('0800000002') == PhoneSignInResult.signedIn,
      isTrue,
    );
    final product = addListing(a, 'Shared listing');
    await a.flush();

    final b = await device(db);
    final shared = b.products.where((item) => item.id == product.id);
    expect(shared, hasLength(1));
    expect(shared.single.title, 'Shared listing');
    expect(shared.single.productImages.single.bytes, [1, 2, 3]);
    // The session stays on its own device.
    expect(b.currentUser.role.name, 'guest');
    a.dispose();
    b.dispose();
  });

  test('reloadFromStore picks up changes made elsewhere', () async {
    final db = FakeFirebaseFirestore();
    final a = await device(db);
    final b = await device(db);
    expect(
      a.signInVerifiedPhone('0800000002') == PhoneSignInResult.signedIn,
      isTrue,
    );
    final product = addListing(a, 'Late listing');
    await a.flush();

    expect(b.products.any((item) => item.id == product.id), isFalse);
    await b.reloadFromStore();
    expect(b.products.any((item) => item.id == product.id), isTrue);
    a.dispose();
    b.dispose();
  });

  test('unchanged data is not written again', () async {
    final db = FakeFirebaseFirestore();
    final store = FirestorePersistenceStore(
      firestore: db,
      local: InMemoryPersistenceStore(),
    );
    const payload =
        '{"schemaVersion":1,"users":[{"id":"u1","name":"A"}],'
        '"blockedUserPairs":["u1|u2"],"suspendedUserReasons":{"u/1":"spam"}}';
    await store.save(payload);
    await db.collection('users').doc('u1').update({'name': 'edited'});
    await store.save(payload);
    // The second save saw no local change, so the edit made elsewhere stays.
    expect(
      (await db.collection('users').doc('u1').get()).data()?['name'],
      'edited',
    );
    expect(
      (await db.collection('suspendedUserReasons').doc('u%2F1').get())
          .data()?['key'],
      'u/1',
    );
  });

  test('records deleted locally are deleted remotely', () async {
    final db = FakeFirebaseFirestore();
    final store = FirestorePersistenceStore(
      firestore: db,
      local: InMemoryPersistenceStore(),
    );
    await store.save('{"schemaVersion":1,"users":[{"id":"u1"},{"id":"u2"}]}');
    await store.save('{"schemaVersion":1,"users":[{"id":"u1"}]}');
    final users = await db.collection('users').get();
    expect(users.docs.map((doc) => doc.id), ['u1']);
  });
}
