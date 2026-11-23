import '../constants/app_info.dart';
import 'geo_location.dart';
import '../utils/json_helpers.dart';

enum SuggestedSpotType { gasStation, mall, convenienceStore, other }

class SuggestedSpot {
  final String id;
  final String name;
  final String description;
  final GeoLocation location;
  final SuggestedSpotType type;
  final bool isActive;
  final String openHours;

  SuggestedSpot({
    required this.id,
    required this.name,
    required this.description,
    GeoLocation? location,
    this.type = SuggestedSpotType.other,
    this.isActive = true,
    this.openHours = '08:00 - 20:00 น.',
  }) : location = location ?? kDefaultCenter;

  SuggestedSpot copyWith({
    String? id,
    String? name,
    String? description,
    GeoLocation? location,
    SuggestedSpotType? type,
    bool? isActive,
    String? openHours,
  }) {
    return SuggestedSpot(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      location: location ?? this.location,
      type: type ?? this.type,
      isActive: isActive ?? this.isActive,
      openHours: openHours ?? this.openHours,
    );
  }

  Map<String, Object?> toJson() => {
    'id': id,
    'name': name,
    'description': description,
    'location': location.toJson(),
    'type': type.name,
    'isActive': isActive,
    'openHours': openHours,
  };

  factory SuggestedSpot.fromJson(Map<String, dynamic> json) => SuggestedSpot(
    id: jsonString(json['id'], 'missing-spot'),
    name: jsonString(json['name'], 'จุดแนะนำ'),
    description: jsonString(json['description']),
    location: GeoLocation.fromJson(jsonObject(json['location'])),
    type: jsonEnum(
      SuggestedSpotType.values,
      json['type'],
      SuggestedSpotType.other,
    ),
    isActive: jsonBool(json['isActive'], true),
    openHours: jsonString(json['openHours'], '08:00 - 20:00 น.'),
  );
}

typedef PickupPointModel = SuggestedSpot;
