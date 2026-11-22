enum AppNotificationType {
  newListingNearby,
  newMessage,
  meetupProposed,
  meetupResponded,
  orderStatusChanged,
  reportUpdated,
  system,
}

class AppNotification {
  final String id;
  final String userId;
  final AppNotificationType type;
  final String title;
  final String body;
  final String? refType;
  final String? refId;
  final DateTime createdAt;
  final DateTime? readAt;

  const AppNotification({
    required this.id,
    required this.userId,
    required this.type,
    required this.title,
    required this.body,
    required this.createdAt,
    this.refType,
    this.refId,
    this.readAt,
  });

  bool get isRead => readAt != null;

  AppNotification copyWith({
    String? id,
    String? userId,
    AppNotificationType? type,
    String? title,
    String? body,
    String? refType,
    String? refId,
    DateTime? createdAt,
    DateTime? readAt,
  }) {
    return AppNotification(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      type: type ?? this.type,
      title: title ?? this.title,
      body: body ?? this.body,
      refType: refType ?? this.refType,
      refId: refId ?? this.refId,
      createdAt: createdAt ?? this.createdAt,
      readAt: readAt ?? this.readAt,
    );
  }
}
