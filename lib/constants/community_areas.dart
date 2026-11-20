import '../models/geo_location.dart';

class CommunityArea {
  final String label;
  final GeoLocation location;

  CommunityArea({required this.label, required this.location});
}

final List<CommunityArea> kDemoCommunityAreas = [
  CommunityArea(
    label: 'อำเภอเมืองจันทบุรี',
    location: GeoLocation(12.6112, 102.1031),
  ),
  CommunityArea(
    label: 'อำเภอท่าใหม่',
    location: GeoLocation(12.6230, 101.9990),
  ),
  CommunityArea(label: 'อำเภอขลุง', location: GeoLocation(12.4600, 102.2200)),
  CommunityArea(
    label: 'อำเภอแหลมสิงห์',
    location: GeoLocation(12.4810, 102.0720),
  ),
  CommunityArea(
    label: 'อำเภอนายายอาม',
    location: GeoLocation(12.7800, 101.8300),
  ),
];
