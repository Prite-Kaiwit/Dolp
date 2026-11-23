import '../utils/json_helpers.dart';

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

  Map<String, Object?> toJson() => {
    'id': id,
    'name': name,
    'phone': phone,
    'phoneVerified': phoneVerified,
    'homeLat': homeLat,
    'homeLng': homeLng,
    'homeLabel': homeLabel,
    'avatarUrl': avatarUrl,
    'rating': rating,
    'reviewCount': reviewCount,
    'successfulDeals': successfulDeals,
    'role': role.name,
    'createdAt': createdAt.toUtc().toIso8601String(),
    'isSuspended': isSuspended,
    'suspensionReason': suspensionReason,
  };

  factory UserModel.fromJson(Map<String, dynamic> json) => UserModel(
    id: jsonString(json['id'], 'missing-user'),
    name: jsonString(json['name'], 'ผู้ใช้'),
    phone: jsonString(json['phone']),
    phoneVerified: jsonBool(json['phoneVerified']),
    homeLat: json['homeLat'] is num ? jsonDouble(json['homeLat']) : null,
    homeLng: json['homeLng'] is num ? jsonDouble(json['homeLng']) : null,
    homeLabel: jsonString(json['homeLabel']),
    avatarUrl: jsonString(json['avatarUrl']),
    rating: jsonDouble(json['rating'], 0),
    reviewCount: jsonInt(json['reviewCount']),
    successfulDeals: jsonInt(json['successfulDeals']),
    role: jsonEnum(UserRole.values, json['role'], UserRole.member),
    createdAt: jsonDateTime(json['createdAt']),
    isSuspended: jsonBool(json['isSuspended']),
    suspensionReason: json['suspensionReason'] is String
        ? json['suspensionReason'] as String
        : null,
  );

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
