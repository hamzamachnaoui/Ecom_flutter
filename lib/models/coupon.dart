class CouponModel {
  final String code;
  final String discountType; // 'percent' or 'fixed'
  final double discountValue;
  final double discountAmount;
  final double finalAmount;

  CouponModel({
    required this.code,
    required this.discountType,
    required this.discountValue,
    required this.discountAmount,
    required this.finalAmount,
  });

  factory CouponModel.fromJson(Map<String, dynamic> json) {
    return CouponModel(
      code: json['code'] ?? '',
      discountType: json['discount_type'] ?? 'percent',
      discountValue: double.tryParse(json['discount_value'].toString()) ?? 0.0,
      discountAmount: double.tryParse(json['discount_amount'].toString()) ?? 0.0,
      finalAmount: double.tryParse(json['final_amount'].toString()) ?? 0.0,
    );
  }
}

