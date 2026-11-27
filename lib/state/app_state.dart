import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;

import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../constants/chat_limits.dart';
import '../constants/app_info.dart';
import '../constants/trust_safety_limits.dart';
import '../models/area_alert_subscription.dart';
import '../models/notification.dart';
import '../models/user.dart';
import '../models/product.dart';
import '../models/product_image_data.dart';
import '../models/geo_location.dart';
import '../models/nearby_product.dart';
import '../models/nearby_shop.dart';
import '../utils/thai_time.dart';
export '../models/nearby_shop.dart';
import '../models/order.dart';
import '../models/review.dart';
import '../models/chat.dart';
import '../models/meetup_agreement.dart';
import '../models/pickup_point.dart';
import '../models/report.dart';
import '../utils/distance.dart';
import '../utils/shop_validation.dart';
import '../models/shop_profile.dart';
import '../utils/json_helpers.dart';
import '../auth/phone_auth_service.dart';
import '../persistence/in_memory_persistence_store.dart';
import '../persistence/persistence_store.dart';

part 'app_state_seed.dart';
part 'app_state_auth.dart';
part 'app_state_notifications.dart';
part 'app_state_listings.dart';
part 'app_state_trust_safety.dart';
part 'app_state_orders.dart';
part 'app_state_chat.dart';

class ExactProductLocation {
  final String exactAddress;
  final double exactLat;
  final double exactLng;

  const ExactProductLocation({
    required this.exactAddress,
    required this.exactLat,
    required this.exactLng,
  });
}

class _PrivateProductLocation {
  final String address;
  final double exactLat;
  final double exactLng;

  const _PrivateProductLocation({
    required this.address,
    required this.exactLat,
    required this.exactLng,
  });
}

class AdminQueryResult<T> {
  final T? value;
  final String? error;

  const AdminQueryResult.success(T result) : value = result, error = null;
  const AdminQueryResult.failure(String message)
    : value = null,
      error = message;

  bool get isSuccess => value != null;
}

class AppState extends ChangeNotifier with WidgetsBindingObserver {
  static AppState? _instance;
  static PersistenceStore? _configuredStore;
  static PhoneAuthService? _configuredPhoneAuth;

  factory AppState() => _instance ??= AppState._internal(
    _configuredStore ?? InMemoryPersistenceStore(),
    _configuredPhoneAuth ?? LocalPhoneAuthService(),
  );

  static void configurePersistenceStore(PersistenceStore store) {
    if (_instance != null) {
      throw StateError(
        'Persistence must be configured before AppState access.',
      );
    }
    _configuredStore = store;
  }

  static void configurePhoneAuth(PhoneAuthService service) {
    if (_instance != null) {
      throw StateError('Phone auth must be configured before AppState access.');
    }
    _configuredPhoneAuth = service;
  }

  @visibleForTesting
  factory AppState.createForTesting({
    required PersistenceStore store,
    PhoneAuthService? phoneAuth,
  }) => AppState._internal(store, phoneAuth ?? LocalPhoneAuthService());

  AppState._internal(PersistenceStore store, this.phoneAuth) : _store = store {
    _initMockData();
  }

  static const int schemaVersion = 1;
  static const Duration _saveDebounce = Duration(milliseconds: 300);
  final PersistenceStore _store;

  /// Sends and checks SMS codes for sign-in and registration.
  final PhoneAuthService phoneAuth;
  Timer? _saveTimer;
  Timer? _remoteReloadTimer;
  StreamSubscription<void>? _remoteChangesSubscription;
  Future<void> _writeQueue = Future<void>.value();
  bool _initialized = false;
  String? lastPersistenceError;
  String? _persistenceWarning;

  List<UserModel> users = [];
  UserModel currentUser = UserModel(
    id: 'guest_01',
    name: 'ผู้เยี่ยมชม',
    role: UserRole.guest,
  );

  bool get isLoggedIn => currentUser.role != UserRole.guest;
  bool get isAdmin => currentUser.role == UserRole.admin;
  String? lastLoginError;

  // Cart
  List<ProductModel> cartItems = [];

  // Products
  List<ProductModel> products = [];
  final Map<String, _PrivateProductLocation> _exactLocationsByProductId = {};

  GeoLocation get currentLocation {
    final latitude = currentUser.homeLat;
    final longitude = currentUser.homeLng;
    if (latitude == null || longitude == null) return kDefaultCenter;
    return GeoLocation(latitude, longitude);
  }

  bool get isLocationApproximate =>
      currentUser.homeLat == null || currentUser.homeLng == null;

  // Orders and reviews
  List<OrderModel> orders = [];
  List<ReviewModel> reviews = [];
  final Map<String, ListingStatus> _reservedListingPreviousStatus = {};
  int _orderSequence = 0;

  // Chats
  List<ChatConversation> conversations = [];
  List<MeetupAgreement> meetupAgreements = [];
  int _chatSequence = 0;

  // Suggested public meeting points.
  List<SuggestedSpot> pickupPoints = [];

  // Reports (Trust & Safety / Admin)
  List<ReportModel> reports = [];
  final Set<String> _blockedUserPairs = {};
  final Map<String, String> _suspendedUserReasons = {};
  final Set<String> _safetyTipsAcknowledgedBy = {};

  // Notifications
  List<AppNotification> notifications = [];
  final Map<String, AreaAlertSubscription> _areaAlertSubscriptions = {};
  int _notificationSequence = 0;
  DateTime Function() _clock = DateTime.now;

  @visibleForTesting
  void setClockForTesting(DateTime Function() clock) {
    _clock = clock;
  }

  @override
  void notifyListeners() {
    super.notifyListeners();
    if (_initialized) _schedulePersistence();
  }

  Future<void> initialize() async {
    if (_initialized) return;
    WidgetsBinding.instance.addObserver(this);
    _remoteChangesSubscription = _store.remoteChanges.listen(
      (_) => _scheduleRemoteReload(),
    );
    String? raw;
    try {
      raw = await _store.load();
    } catch (error, stackTrace) {
      lastPersistenceError = '$error';
      _persistenceWarning =
          'โหลดข้อมูลในเครื่องไม่สำเร็จ จึงเริ่มข้อมูลตัวอย่าง';
      debugPrint('Persistence load failed: $error\n$stackTrace');
    }

    if (raw == null) {
      currentUser = _guestUser();
      _initialized = true;
      await flush();
      return;
    }

    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map<String, dynamic>) {
        throw const FormatException('Persistence root must be a JSON object.');
      }
      await _restoreFromJson(_migrate(decoded));
      _initialized = true;
      if (_sessionUserMissing) {
        _persistenceWarning = 'ไม่พบบัญชีที่บันทึกไว้ กรุณาเข้าสู่ระบบอีกครั้ง';
      }
      if (_sessionUserSuspended) {
        _persistenceWarning = 'บัญชีนี้ถูกระงับ กรุณาติดต่อผู้ดูแลระบบ';
      }
      await flush();
    } on Object catch (error, stackTrace) {
      lastPersistenceError = '$error';
      _persistenceWarning = 'ข้อมูลในเครื่องเสียหาย จึงสำรองข้อมูลและเริ่มใหม่';
      debugPrint('Persistence restore failed: $error\n$stackTrace');
      try {
        await _store.backupCorrupted(raw);
      } catch (backupError, backupStackTrace) {
        lastPersistenceError = '$backupError';
        debugPrint(
          'Persistence backup failed: $backupError\n$backupStackTrace',
        );
      }
      _initMockData();
      currentUser = _guestUser();
      _initialized = true;
      await flush();
    }
  }

  bool _sessionUserMissing = false;
  bool _sessionUserSuspended = false;

  String? takePersistenceWarning() {
    final warning = _persistenceWarning;
    _persistenceWarning = null;
    return warning;
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.inactive ||
        state == AppLifecycleState.paused ||
        state == AppLifecycleState.detached ||
        state == AppLifecycleState.hidden) {
      unawaited(flush());
    }
  }

  void _schedulePersistence() {
    _saveTimer?.cancel();
    _saveTimer = Timer(_saveDebounce, () => unawaited(flush()));
  }

  Future<void> flush() async {
    _saveTimer?.cancel();
    if (!_initialized) return;
    _writeQueue = _writeQueue.then((_) async {
      try {
        final referencedImages = <String>{};
        final data = await _toPersistenceJson(referencedImages);
        await _store.save(jsonEncode(data));
        await _store.deleteUnreferencedImages(referencedImages);
        lastPersistenceError = null;
      } catch (error, stackTrace) {
        lastPersistenceError = '$error';
        debugPrint('Persistence write failed: $error\n$stackTrace');
      }
    });
    await _writeQueue;
  }

  static const Duration _remoteReloadDebounce = Duration(milliseconds: 500);

  void _scheduleRemoteReload() {
    _remoteReloadTimer?.cancel();
    _remoteReloadTimer = Timer(
      _remoteReloadDebounce,
      () => unawaited(reloadFromStore()),
    );
  }

  /// Saves this device's pending edits, then reloads data changed elsewhere.
  Future<void> reloadFromStore() async {
    if (!_initialized) return;
    await flush();
    try {
      final raw = await _store.load();
      if (raw == null) return;
      final decoded = jsonDecode(raw);
      if (decoded is! Map<String, dynamic>) return;
      await _restoreFromJson(_migrate(decoded));
      lastPersistenceError = null;
      notifyListeners();
    } catch (error, stackTrace) {
      lastPersistenceError = '$error';
      debugPrint('Remote reload failed: $error\n$stackTrace');
    }
  }

  Future<bool> resetSampleData() async {
    if (!kDebugMode) return false;
    try {
      await _store.clear();
      _initMockData();
      currentUser = _guestUser();
      _initialized = true;
      await flush();
      notifyListeners();
      return true;
    } catch (error, stackTrace) {
      lastPersistenceError = '$error';
      debugPrint('Sample data reset failed: $error\n$stackTrace');
      return false;
    }
  }

  @override
  void dispose() {
    _saveTimer?.cancel();
    _remoteReloadTimer?.cancel();
    unawaited(_remoteChangesSubscription?.cancel());
    if (_initialized) WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  Map<String, dynamic> _migrate(Map<String, dynamic> source) {
    final data = Map<String, dynamic>.of(source);
    final version = data['schemaVersion'] is num
        ? (data['schemaVersion'] as num).toInt()
        : 0;
    if (version < 0 || version > schemaVersion) {
      throw FormatException('Unsupported persistence schema version: $version');
    }
    if (version == 0) {
      data['schemaVersion'] = 1;
    }
    return data;
  }

  Future<Map<String, Object?>> _toPersistenceJson(
    Set<String> referencedImages,
  ) async {
    Future<ProductImageData?> saveImage(ProductImageData? image) async {
      if (image == null) return null;
      if (kIsWeb && image.bytes != null) {
        return const ProductImageData.network(null);
      }
      if (image.bytes == null) {
        if (image.storageKey != null) referencedImages.add(image.storageKey!);
        return image;
      }
      final key = 'img_${sha256.convert(image.bytes!).toString()}.bin';
      referencedImages.add(key);
      await _store.saveImage(key, image.bytes!);
      return ProductImageData.local(storageKey: key);
    }

    final persistedProducts = <ProductModel>[];
    for (final product in products) {
      final images = <ProductImageData>[];
      for (final image in product.productImages) {
        final saved = await saveImage(image);
        if (saved != null) images.add(saved);
      }
      persistedProducts.add(product.copyWith(productImages: images));
    }
    final persistedOrders = <OrderModel>[];
    for (final order in orders) {
      final items = <OrderItemSnapshot>[];
      for (final item in order.items) {
        items.add(
          OrderItemSnapshot(
            productId: item.productId,
            title: item.title,
            price: item.price,
            coverImage: await saveImage(item.coverImage),
            listingType: item.listingType,
          ),
        );
      }
      persistedOrders.add(order.copyWith(items: items));
    }
    final persistedConversations = <ChatConversation>[];
    for (final conversation in conversations) {
      final messages = <ChatMessage>[];
      for (final message in conversation.messages) {
        messages.add(
          ChatMessage(
            id: message.id,
            senderId: message.senderId,
            text: message.text,
            timestamp: message.timestamp,
            isMe: message.isMe,
            isSystemPrompt: message.isSystemPrompt,
            type: message.type,
            image: await saveImage(message.image),
            meetupId: message.meetupId,
            recipientId: message.recipientId,
          ),
        );
      }
      persistedConversations.add(
        conversation.copyWith(
          productImage: await saveImage(conversation.productImage),
          messages: messages,
        ),
      );
    }

    return {
      'schemaVersion': schemaVersion,
      'currentUserId': isLoggedIn ? currentUser.id : null,
      'users': users.map((user) => user.toJson()).toList(),
      'products': persistedProducts.map((item) => item.toJson()).toList(),
      'privateProductLocations': {
        for (final entry in _exactLocationsByProductId.entries)
          entry.key: {
            'address': entry.value.address,
            'exactLat': entry.value.exactLat,
            'exactLng': entry.value.exactLng,
          },
      },
      'cartItems': cartItems.map((item) => item.id).toList(),
      'orders': persistedOrders.map((item) => item.toJson()).toList(),
      'reservedListingPreviousStatus': {
        for (final entry in _reservedListingPreviousStatus.entries)
          entry.key: entry.value.name,
      },
      'reviews': reviews.map((item) => item.toJson()).toList(),
      'conversations': persistedConversations
          .map((item) => item.toJson())
          .toList(),
      'meetupAgreements': meetupAgreements
          .map((item) => item.toJson())
          .toList(),
      'pickupPoints': pickupPoints.map((item) => item.toJson()).toList(),
      'reports': reports.map((item) => item.toJson()).toList(),
      'blockedUserPairs': _blockedUserPairs.toList(),
      'suspendedUserReasons': _suspendedUserReasons,
      'safetyTipsAcknowledgedBy': _safetyTipsAcknowledgedBy.toList(),
      'notifications': notifications.map((item) => item.toJson()).toList(),
      'areaAlertSubscriptions': {
        for (final entry in _areaAlertSubscriptions.entries)
          entry.key: entry.value.toJson(),
      },
      'notificationSequence': _notificationSequence,
      'orderSequence': _orderSequence,
      'chatSequence': _chatSequence,
    };
  }

  Future<ProductImageData?> _restoreImage(ProductImageData? image) async {
    if (image?.storageKey == null) return image;
    final bytes = await _store.loadImage(image!.storageKey!);
    return ProductImageData.local(storageKey: image.storageKey, bytes: bytes);
  }

  Future<void> _restoreFromJson(Map<String, dynamic> data) async {
    users = jsonList(
      data['users'],
    ).map((item) => UserModel.fromJson(jsonObject(item))).toList();
    products = jsonList(
      data['products'],
    ).map((item) => ProductModel.fromJson(jsonObject(item))).toList();
    final productIds = products.map((product) => product.id).toSet();
    final productImages = <ProductModel>[];
    for (final product in products) {
      final images = <ProductImageData>[];
      for (final image in product.productImages) {
        final restored = await _restoreImage(image);
        if (restored != null) images.add(restored);
      }
      productImages.add(product.copyWith(productImages: images));
    }
    products = productImages;
    cartItems = jsonList(data['cartItems'])
        .whereType<String>()
        .map((id) => products.where((product) => product.id == id).firstOrNull)
        .whereType<ProductModel>()
        .toList();

    _exactLocationsByProductId.clear();
    for (final entry in jsonObject(data['privateProductLocations']).entries) {
      if (!productIds.contains(entry.key)) continue;
      final value = jsonObject(entry.value);
      if (value['exactLat'] is! num || value['exactLng'] is! num) continue;
      _exactLocationsByProductId[entry.key] = _PrivateProductLocation(
        address: jsonString(value['address']),
        exactLat: jsonDouble(value['exactLat']),
        exactLng: jsonDouble(value['exactLng']),
      );
    }
    _reservedListingPreviousStatus
      ..clear()
      ..addAll({
        for (final entry in jsonObject(
          data['reservedListingPreviousStatus'],
        ).entries)
          entry.key: jsonEnum(
            ListingStatus.values,
            entry.value,
            ListingStatus.active,
          ),
      });

    orders = jsonList(
      data['orders'],
    ).map((item) => OrderModel.fromJson(jsonObject(item))).toList();
    final ordersWithImages = <OrderModel>[];
    for (final order in orders) {
      final items = <OrderItemSnapshot>[];
      for (final item in order.items) {
        items.add(
          OrderItemSnapshot(
            productId: item.productId,
            title: item.title,
            price: item.price,
            coverImage: await _restoreImage(item.coverImage),
            listingType: item.listingType,
          ),
        );
      }
      ordersWithImages.add(order.copyWith(items: items));
    }
    orders = ordersWithImages;
    reviews = jsonList(
      data['reviews'],
    ).map((item) => ReviewModel.fromJson(jsonObject(item))).toList();
    conversations = jsonList(
      data['conversations'],
    ).map((item) => ChatConversation.fromJson(jsonObject(item))).toList();
    final restoredConversations = <ChatConversation>[];
    for (final conversation in conversations) {
      final messages = <ChatMessage>[];
      for (final message in conversation.messages) {
        messages.add(
          ChatMessage(
            id: message.id,
            senderId: message.senderId,
            text: message.text,
            timestamp: message.timestamp,
            isMe: message.isMe,
            isSystemPrompt: message.isSystemPrompt,
            type: message.type,
            image: await _restoreImage(message.image),
            meetupId: message.meetupId,
            recipientId: message.recipientId,
          ),
        );
      }
      restoredConversations.add(
        conversation.copyWith(
          productImage: await _restoreImage(conversation.productImage),
          messages: messages,
        ),
      );
    }
    conversations = restoredConversations;
    meetupAgreements = jsonList(
      data['meetupAgreements'],
    ).map((item) => MeetupAgreement.fromJson(jsonObject(item))).toList();
    pickupPoints = jsonList(
      data['pickupPoints'],
    ).map((item) => SuggestedSpot.fromJson(jsonObject(item))).toList();
    reports = jsonList(
      data['reports'],
    ).map((item) => ReportModel.fromJson(jsonObject(item))).toList();
    notifications = jsonList(
      data['notifications'],
    ).map((item) => AppNotification.fromJson(jsonObject(item))).toList();
    _areaAlertSubscriptions
      ..clear()
      ..addAll({
        for (final entry in jsonObject(data['areaAlertSubscriptions']).entries)
          entry.key: AreaAlertSubscription.fromJson(jsonObject(entry.value)),
      });
    _blockedUserPairs
      ..clear()
      ..addAll(jsonList(data['blockedUserPairs']).whereType<String>());
    _suspendedUserReasons
      ..clear()
      ..addAll({
        for (final entry in jsonObject(data['suspendedUserReasons']).entries)
          if (entry.value is String) entry.key: entry.value as String,
      });
    _safetyTipsAcknowledgedBy
      ..clear()
      ..addAll(jsonList(data['safetyTipsAcknowledgedBy']).whereType<String>());
    _notificationSequence = jsonInt(data['notificationSequence']);
    _orderSequence = jsonInt(data['orderSequence']);
    _chatSequence = jsonInt(data['chatSequence']);

    _recalculateRatings();
    _recalculateSuccessfulDeals();
    final sessionUserId = data['currentUserId'];
    _sessionUserMissing = false;
    _sessionUserSuspended = false;
    if (sessionUserId is String) {
      final user = users.where((item) => item.id == sessionUserId).firstOrNull;
      if (user == null) {
        _sessionUserMissing = true;
        currentUser = _guestUser();
      } else if (user.isSuspended) {
        _sessionUserSuspended = true;
        currentUser = _guestUser();
      } else {
        currentUser = user;
      }
    } else {
      currentUser = _guestUser();
    }
  }

  UserModel _guestUser() => UserModel(
    id: 'guest_01',
    name: 'ผู้เยี่ยมชม',
    role: UserRole.guest,
    rating: 0,
    reviewCount: 0,
    successfulDeals: 0,
  );
}
