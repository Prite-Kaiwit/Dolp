class PickupPointModel {
  final String id;
  final String name;
  final String description;
  final String zone;
  final bool isActive;
  final String openHours;

  PickupPointModel({
    required this.id,
    required this.name,
    required this.description,
    required this.zone,
    this.isActive = true,
    this.openHours = '08:00 - 20:00 น.',
  });

  PickupPointModel copyWith({
    String? id,
    String? name,
    String? description,
    String? zone,
    bool? isActive,
    String? openHours,
  }) {
    return PickupPointModel(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      zone: zone ?? this.zone,
      isActive: isActive ?? this.isActive,
      openHours: openHours ?? this.openHours,
    );
  }
}
