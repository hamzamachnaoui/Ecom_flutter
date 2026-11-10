class ReviewModel {
  final int id;
  final int productId;
  final int userId;
  final String userName;
  final int rating;
  final String comment;
  final String createdAt;

  ReviewModel({
    required this.id,
    required this.productId,
    required this.userId,
    required this.userName,
    required this.rating,
    required this.comment,
    required this.createdAt,
  });

  factory ReviewModel.fromJson(Map<String, dynamic> json) {
    return ReviewModel(
      id: int.tryParse(json['id'].toString()) ?? 0,
      productId: int.tryParse(json['product_id'].toString()) ?? 0,
      userId: int.tryParse(json['user_id'].toString()) ?? 0,
      userName: json['user_name'] ?? 'Client vérifié',
      rating: int.tryParse(json['rating'].toString()) ?? 5,
      comment: json['comment'] ?? '',
      createdAt: json['created_at'] ?? '',
    );
  }
}

