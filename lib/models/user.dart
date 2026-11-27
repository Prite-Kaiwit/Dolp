import '../utils/json_helpers.dart';
import 'shop_profile.dart';

enum UserRole { guest, member, admin }

enum AccountType { person, shop }

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

  /// Firebase Authentication user ID of the phone that last verified this
  /// account. Empty for seed accounts that have not signed in yet.
  final String authUid;

  final AccountType accountType;
  final ShopProfile? shop;

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
    this.authUid = '',
    this.accountType = AccountType.person,
    this.shop,
  }) : createdAt = createdAt ?? DateTime.now();

  /// True only for a shop account whose profile is complete; anything else
  /// behaves as a person.
  bool get isShop =>
      accountType == AccountType.shop && shop != null && shop!.isComplete;

  String get displayName => isShop ? shop!.shopName : name;

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
    'authUid': authUid,
    'accountType': accountType.name,
    'shop': shop?.toJson(),
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
    authUid: jsonString(json['authUid']),
    accountType: jsonEnum(
      AccountType.values,
      json['accountType'],
      AccountType.person,
    ),
    shop: json['shop'] is Map<String, dynamic>
        ? ShopProfile.fromJson(json['shop'] as Map<String, dynamic>)
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
    String? authUid,
    AccountType? accountType,
    ShopProfile? shop,
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
      authUid: authUid ?? this.authUid,
      accountType: accountType ?? this.accountType,
      shop: shop ?? this.shop,
    );
  }
}
