class User {
  final int id;
  final String name;
  final String email;
  final String referralCode;
  final String? referredBy;
  final bool isVerified;

  User({
    required this.id,
    required this.name,
    required this.email,
    required this.referralCode,
    this.referredBy,
    required this.isVerified,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: int.tryParse(json['id'].toString()) ?? 0,
      name: json['name'] ?? '',
      email: json['email'] ?? '',
      referralCode: json['referral_code'] ?? '',
      referredBy: json['referred_by'],
      isVerified: json['is_verified'] == true || json['is_verified'] == 1 || json['is_verified'] == '1',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'referral_code': referralCode,
      'referred_by': referredBy,
      'is_verified': isVerified,
    };
  }
}

