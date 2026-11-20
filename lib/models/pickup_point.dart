// The legacy zone field remains through the pickup flow and admin migration.
// ignore_for_file: deprecated_member_use

import '../constants/app_info.dart';
import 'geo_location.dart';

enum SuggestedSpotType { gasStation, mall, convenienceStore, other }

class PickupPointModel {
  final String id;
  final String name;
  final String description;
  final GeoLocation location;
  final SuggestedSpotType type;
  @Deprecated(
    'Migrate pickup screens in phase 5 and remove the admin zone in phase 7.',
  )
  final String zone;
  final bool isActive;
  final String openHours;

  PickupPointModel({
    required this.id,
    required this.name,
    required this.description,
    required this.zone,
    GeoLocation? location,
    this.type = SuggestedSpotType.other,
    this.isActive = true,
    this.openHours = '08:00 - 20:00 น.',
  }) : location = location ?? kDefaultCenter;

  PickupPointModel copyWith({
    String? id,
    String? name,
    String? description,
    GeoLocation? location,
    SuggestedSpotType? type,
    String? zone,
    bool? isActive,
    String? openHours,
  }) {
    return PickupPointModel(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      location: location ?? this.location,
      type: type ?? this.type,
      zone: zone ?? this.zone,
      isActive: isActive ?? this.isActive,
      openHours: openHours ?? this.openHours,
    );
  }
}
