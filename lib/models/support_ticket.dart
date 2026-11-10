class SupportTicketModel {
  final int id;
  final int? userId;
  final String userName;
  final String userEmail;
  final String category;
  final String priority;
  final String subject;
  final int? orderId;
  final int? productId;
  final String productTitle;
  final String message;
  final String? clientFollowup;
  final String? adminReply;
  final String status;
  final String createdAt;

  SupportTicketModel({
    required this.id,
    this.userId,
    required this.userName,
    required this.userEmail,
    required this.category,
    this.priority = 'normale',
    required this.subject,
    this.orderId,
    this.productId,
    this.productTitle = '',
    required this.message,
    this.clientFollowup,
    this.adminReply,
    required this.status,
    required this.createdAt,
  });

  factory SupportTicketModel.fromJson(Map<String, dynamic> json) {
    return SupportTicketModel(
      id: int.tryParse(json['id'].toString()) ?? 0,
      userId: json['user_id'] != null ? int.tryParse(json['user_id'].toString()) : null,
      userName: json['user_name'] ?? '',
      userEmail: json['user_email'] ?? '',
      category: json['category'] ?? 'Question produit',
      priority: json['priority'] ?? 'normale',
      subject: json['subject'] ?? '',
      orderId: json['order_id'] != null ? int.tryParse(json['order_id'].toString()) : null,
      productId: json['product_id'] != null ? int.tryParse(json['product_id'].toString()) : null,
      productTitle: json['product_title'] ?? '',
      message: json['message'] ?? '',
      clientFollowup: json['client_followup'],
      adminReply: json['admin_reply'],
      status: json['status'] ?? 'open',
      createdAt: json['created_at'] ?? '',
    );
  }
}
