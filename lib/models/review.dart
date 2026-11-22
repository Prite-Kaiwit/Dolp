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
}
