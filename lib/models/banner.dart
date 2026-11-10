class BannerModel {
  final int id;
  final String title;
  final String subtitle;
  final String badge;
  final String colorStart;
  final String colorEnd;

  BannerModel({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.badge,
    required this.colorStart,
    required this.colorEnd,
  });

  factory BannerModel.fromJson(Map<String, dynamic> json) {
    return BannerModel(
      id: int.tryParse(json['id'].toString()) ?? 0,
      title: json['title'] ?? '',
      subtitle: json['subtitle'] ?? '',
      badge: json['badge'] ?? 'PROMO',
      colorStart: json['bg_color_start'] ?? '#023047',
      colorEnd: json['bg_color_end'] ?? '#219EBC',
    );
  }
}

