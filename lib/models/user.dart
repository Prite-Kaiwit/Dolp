enum UserRole { guest, member, admin }

class UserModel {
  final String id;
  final String name;
  final String email;
  final String studentId;
  final String faculty;
  final String avatarUrl;
  final double rating;
  final int reviewCount;
  final int successfulDeals;
  final bool isVerified;
  final UserRole role;

  UserModel({
    required this.id,
    required this.name,
    required this.email,
    this.studentId = '6610110001',
    this.faculty = 'คณะวิศวกรรมศาสตร์ มอ.',
    this.avatarUrl = 'https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=150',
    this.rating = 4.9,
    this.reviewCount = 38,
    this.successfulDeals = 24,
    this.isVerified = true,
    this.role = UserRole.member,
  });

  UserModel copyWith({
    String? id,
    String? name,
    String? email,
    String? studentId,
    String? faculty,
    String? avatarUrl,
    double? rating,
    int? reviewCount,
    int? successfulDeals,
    bool? isVerified,
    UserRole? role,
  }) {
    return UserModel(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      studentId: studentId ?? this.studentId,
      faculty: faculty ?? this.faculty,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      rating: rating ?? this.rating,
      reviewCount: reviewCount ?? this.reviewCount,
      successfulDeals: successfulDeals ?? this.successfulDeals,
      isVerified: isVerified ?? this.isVerified,
      role: role ?? this.role,
    );
  }
}
