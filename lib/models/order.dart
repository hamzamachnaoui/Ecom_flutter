class OrderModel {
  final int id;
  final int userId;
  final double totalAmount;
  final double discountAmount;
  final String? couponCode;
  final String shippingName;
  final String shippingPhone;
  final String shippingAddress;
  final String paymentMethod;
  final String status;
  final String createdAt;
  final List<dynamic> items;

  OrderModel({
    required this.id,
    required this.userId,
    required this.totalAmount,
    required this.discountAmount,
    this.couponCode,
    required this.shippingName,
    required this.shippingPhone,
    required this.shippingAddress,
    this.paymentMethod = 'cod',
    required this.status,
    required this.createdAt,
    this.items = const [],
  });

  factory OrderModel.fromJson(Map<String, dynamic> json) {
    return OrderModel(
      id: int.tryParse(json['id'].toString()) ?? 0,
      userId: int.tryParse(json['user_id'].toString()) ?? 0,
      totalAmount: double.tryParse(json['total_amount'].toString()) ?? 0.0,
      discountAmount: double.tryParse(json['discount_amount'].toString()) ?? 0.0,
      couponCode: json['coupon_code'],
      shippingName: json['shipping_name'] ?? '',
      shippingPhone: json['shipping_phone'] ?? '',
      shippingAddress: json['shipping_address'] ?? '',
      paymentMethod: json['payment_method'] ?? 'cod',
      status: json['status'] ?? 'confirmed',
      createdAt: json['created_at'] ?? '',
      items: json['items'] ?? [],
    );
  }
}
