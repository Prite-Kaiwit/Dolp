import '../utils/json_helpers.dart';

class ReviewModel {
  final String id;
  final String orderId;
  final String reviewerId;
  final String revieweeId;
  final int rating;
  final List<String> tags;
  final String comment;
  final DateTime createdAt;

  const ReviewModel({
    required this.id,
    required this.orderId,
    required this.reviewerId,
    required this.revieweeId,
    required this.rating,
    required this.tags,
    required this.comment,
    required this.createdAt,
  });

  Map<String, Object?> toJson() => {
    'id': id,
    'orderId': orderId,
    'reviewerId': reviewerId,
    'revieweeId': revieweeId,
    'rating': rating,
    'tags': tags,
    'comment': comment,
    'createdAt': createdAt.toUtc().toIso8601String(),
  };

  factory ReviewModel.fromJson(Map<String, dynamic> json) => ReviewModel(
    id: jsonString(json['id'], 'missing-review'),
    orderId: jsonString(json['orderId']),
    reviewerId: jsonString(json['reviewerId']),
    revieweeId: jsonString(json['revieweeId']),
    rating: jsonInt(json['rating'], 1).clamp(1, 5).toInt(),
    tags: jsonList(json['tags']).whereType<String>().toList(),
    comment: jsonString(json['comment']),
    createdAt: jsonDateTime(json['createdAt']),
  );
}
