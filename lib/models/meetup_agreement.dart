import 'product.dart';
import 'geo_location.dart';

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
}
