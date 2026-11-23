import 'product.dart';
import 'geo_location.dart';
import '../utils/json_helpers.dart';

enum MeetupStatus { proposed, accepted, declined, superseded }

class MeetupAgreement {
  final String id;
  final String conversationId;
  final String productId;
  final String proposerId;
  final String responderId;
  final PickupType pickupType;
  final String placeLabel;
  final GeoLocation? spotLocation;
  final DateTime scheduledAt;
  final String note;
  final MeetupStatus status;
  final DateTime createdAt;
  final DateTime? respondedAt;

  const MeetupAgreement({
    required this.id,
    required this.conversationId,
    required this.productId,
    required this.proposerId,
    required this.responderId,
    required this.pickupType,
    required this.placeLabel,
    required this.spotLocation,
    required this.scheduledAt,
    required this.note,
    required this.status,
    required this.createdAt,
    this.respondedAt,
  });

  Map<String, Object?> toJson() => {
    'id': id,
    'conversationId': conversationId,
    'productId': productId,
    'proposerId': proposerId,
    'responderId': responderId,
    'pickupType': pickupType.name,
    'placeLabel': placeLabel,
    'spotLocation': spotLocation?.toJson(),
    'scheduledAt': scheduledAt.toUtc().toIso8601String(),
    'note': note,
    'status': status.name,
    'createdAt': createdAt.toUtc().toIso8601String(),
    'respondedAt': respondedAt?.toUtc().toIso8601String(),
  };

  factory MeetupAgreement.fromJson(Map<String, dynamic> json) =>
      MeetupAgreement(
        id: jsonString(json['id'], 'missing-meetup'),
        conversationId: jsonString(json['conversationId']),
        productId: jsonString(json['productId']),
        proposerId: jsonString(json['proposerId']),
        responderId: jsonString(json['responderId']),
        pickupType: jsonEnum(
          PickupType.values,
          json['pickupType'],
          PickupType.discussInChat,
        ),
        placeLabel: jsonString(json['placeLabel']),
        spotLocation: json['spotLocation'] is Map
            ? GeoLocation.fromJson(jsonObject(json['spotLocation']))
            : null,
        scheduledAt: jsonDateTime(json['scheduledAt']),
        note: jsonString(json['note']),
        status: jsonEnum(
          MeetupStatus.values,
          json['status'],
          MeetupStatus.proposed,
        ),
        createdAt: jsonDateTime(json['createdAt']),
        respondedAt: jsonNullableDateTime(json['respondedAt']),
      );
}
