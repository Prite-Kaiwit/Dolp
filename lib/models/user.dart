enum UserRole { guest, member, admin }

class UserModel {
  final String id;
  final String name;
  final String phone;
  final bool phoneVerified;
  final double? homeLat;
  final double? homeLng;
  final String homeLabel;
  final String avatarUrl;
  final double rating;
  final int reviewCount;
  final int successfulDeals;
  final UserRole role;
  final DateTime createdAt;
  final bool isSuspended;
  final String? suspensionReason;

  UserModel({
    required this.id,
    required this.name,
    this.phone = '',
    this.phoneVerified = false,
    this.homeLat,
    this.homeLng,
    this.homeLabel = '',
    this.avatarUrl =
        'https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=150',
    this.rating = 4.9,
    this.reviewCount = 38,
    this.successfulDeals = 24,
    this.role = UserRole.member,
    DateTime? createdAt,
    this.isSuspended = false,
    this.suspensionReason,
  }) : createdAt = createdAt ?? DateTime.now();

  UserModel copyWith({
    String? id,
    String? name,
    String? phone,
    bool? phoneVerified,
    double? homeLat,
    double? homeLng,
    String? homeLabel,
    String? avatarUrl,
    double? rating,
    int? reviewCount,
    int? successfulDeals,
    UserRole? role,
    DateTime? createdAt,
    bool? isSuspended,
    String? suspensionReason,
    bool clearSuspensionReason = false,
  }) {
    return UserModel(
      id: id ?? this.id,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      phoneVerified: phoneVerified ?? this.phoneVerified,
      homeLat: homeLat ?? this.homeLat,
      homeLng: homeLng ?? this.homeLng,
      homeLabel: homeLabel ?? this.homeLabel,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      rating: rating ?? this.rating,
      reviewCount: reviewCount ?? this.reviewCount,
      successfulDeals: successfulDeals ?? this.successfulDeals,
      role: role ?? this.role,
      createdAt: createdAt ?? this.createdAt,
      isSuspended: isSuspended ?? this.isSuspended,
      suspensionReason: clearSuspensionReason
          ? null
          : suspensionReason ?? this.suspensionReason,
    );
  }
}
