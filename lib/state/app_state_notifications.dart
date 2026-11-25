part of 'app_state.dart';

/// Area-alert subscriptions and in-app notifications.
extension AppStateNotifications on AppState {
  AreaAlertSubscription areaAlertSubscriptionFor(String userId) {
    final user = userById(userId);
    final center = user?.homeLat != null && user?.homeLng != null
        ? GeoLocation(user!.homeLat!, user.homeLng!)
        : kDefaultCenter;
    return _areaAlertSubscriptions[userId] ??
        AreaAlertSubscription(userId: userId, center: center);
  }

  String? updateAreaAlertSubscription({
    required bool enabled,
    required double radiusKm,
    required List<String> categories,
  }) {
    final sessionError = _expireSuspendedSession();
    if (sessionError != null) return sessionError;
    if (!isLoggedIn) return 'เข้าสู่ระบบก่อนตั้งค่าการแจ้งเตือน';
    if (!radiusKm.isFinite ||
        radiusKm < kAreaAlertMinRadiusKm ||
        radiusKm > kAreaAlertMaxRadiusKm) {
      return 'รัศมีต้องอยู่ระหว่าง 1 ถึง 20 กิโลเมตร';
    }
    final user = currentUser;
    final center = user.homeLat != null && user.homeLng != null
        ? GeoLocation(user.homeLat!, user.homeLng!)
        : kDefaultCenter;
    _areaAlertSubscriptions[user.id] = AreaAlertSubscription(
      userId: user.id,
      enabled: enabled,
      radiusKm: radiusKm,
      categories: List.unmodifiable(categories.toSet()),
      center: center,
    );
    notifyListeners();
    return null;
  }

  List<AppNotification> notificationsForCurrentUser() {
    if (!isLoggedIn) return const [];
    return notifications
        .where((notification) => notification.userId == currentUser.id)
        .toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  int get unreadNotificationCount => !isLoggedIn
      ? 0
      : notifications
            .where(
              (notification) =>
                  notification.userId == currentUser.id && !notification.isRead,
            )
            .length;

  void markNotificationRead(String notificationId) {
    final index = notifications.indexWhere(
      (notification) =>
          notification.id == notificationId &&
          notification.userId == currentUser.id,
    );
    if (index == -1 || notifications[index].isRead) return;
    notifications[index] = notifications[index].copyWith(
      readAt: DateTime.now(),
    );
    notifyListeners();
  }

  void markAllNotificationsRead() {
    if (!isLoggedIn) return;
    final now = DateTime.now();
    notifications = notifications
        .map(
          (notification) =>
              notification.userId == currentUser.id && !notification.isRead
              ? notification.copyWith(readAt: now)
              : notification,
        )
        .toList();
    notifyListeners();
  }

  void deleteNotification(String notificationId) {
    notifications.removeWhere(
      (notification) =>
          notification.id == notificationId &&
          notification.userId == currentUser.id,
    );
    notifyListeners();
  }

  void _notifyUser({
    required String userId,
    required AppNotificationType type,
    required String title,
    required String body,
    String? refType,
    String? refId,
    String? aggregateKey,
  }) {
    // TODO: replace this in-memory delivery with FCM when the backend exists.
    if (userId == currentUser.id || userId.startsWith('guest_')) return;
    if (aggregateKey != null) {
      final existingIndex = notifications.indexWhere(
        (notification) =>
            notification.userId == userId &&
            notification.type == type &&
            notification.refId == aggregateKey &&
            !notification.isRead,
      );
      if (existingIndex != -1) {
        notifications[existingIndex] = notifications[existingIndex].copyWith(
          title: title,
          body: body,
          createdAt: DateTime.now(),
        );
        return;
      }
    }
    notifications.insert(
      0,
      AppNotification(
        id: 'notif_${DateTime.now().microsecondsSinceEpoch}_${_notificationSequence++}',
        userId: userId,
        type: type,
        title: title,
        body: body,
        refType: refType,
        refId: aggregateKey ?? refId,
        createdAt: DateTime.now(),
      ),
    );
  }

  void _notifyOrderParticipants(OrderModel order, {required String body}) {
    for (final userId in {order.buyerId, order.sellerId}) {
      _notifyUser(
        userId: userId,
        type: AppNotificationType.orderStatusChanged,
        title: 'อัปเดตคำสั่งซื้อ',
        body: body,
        refType: 'order',
        refId: order.id,
      );
    }
  }
}
