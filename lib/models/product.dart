import 'dart:convert';
import 'package:flutter/material.dart';

class ProductColor {
  final String name;
  final String hex;
  final String? image;

  ProductColor({required this.name, required this.hex, this.image});

  factory ProductColor.fromJson(Map<String, dynamic> json) {
    final img = json['image']?.toString().trim() ?? '';
    return ProductColor(
      name: json['name']?.toString() ?? 'Standard',
      hex: json['hex']?.toString() ?? '#1E293B',
      image: img.isNotEmpty ? img : null,
    );
  }

  Color toFlutterColor() {
    try {
      final buffer = StringBuffer();
      final clean = hex.replaceFirst('#', '');
      if (clean.length == 6) buffer.write('ff');
      buffer.write(clean);
      return Color(int.parse(buffer.toString(), radix: 16));
    } catch (_) {
      return const Color(0xFF1E293B);
    }
  }

  Map<String, dynamic> toJson() => {
        'name': name,
        'hex': hex,
        if (image != null && image!.isNotEmpty) 'image': image,
      };
}

class ProductModel {
  final int id;
  final int? categoryId;
  final String title;
  final String subtitle;
  final double price;
  final double? originalPrice;
  final String description;
  final String image;
  final List<String> images;
  final List<ProductColor> colors;
  final int stock;
  final String? categoryName;
  final bool isFlashSale;
  final int flashDiscountPercent;
  final int itemsSold;
  final double avgRating;
  final int reviewCount;

  ProductModel({
    required this.id,
    this.categoryId,
    required this.title,
    required this.subtitle,
    required this.price,
    this.originalPrice,
    required this.description,
    required this.image,
    List<String>? images,
    List<ProductColor>? colors,
    this.stock = 50,
    this.categoryName,
    this.isFlashSale = false,
    this.flashDiscountPercent = 0,
    this.itemsSold = 5,
    this.avgRating = 5.0,
    this.reviewCount = 0,
  })  : images = _mergeGalleryImages(image, images, colors),
        colors = colors ?? [];

  static List<String> _mergeGalleryImages(
    String primary,
    List<String>? rawImgs,
    List<ProductColor>? cols,
  ) {
    final merged = <String>[];
    if (rawImgs != null) {
      for (final img in rawImgs) {
        if (img.isNotEmpty && !merged.contains(img)) merged.add(img);
      }
    }
    if (merged.isEmpty && primary.isNotEmpty) {
      merged.add(primary);
    }
    if (cols != null) {
      for (final c in cols) {
        if (c.image != null && c.image!.isNotEmpty && !merged.contains(c.image)) {
          merged.add(c.image!);
        }
      }
    }
    return merged;
  }

  factory ProductModel.fromJson(Map<String, dynamic> json) {
    final primaryImg = json['image']?.toString() ?? 'assets/images/airpod.png';

    List<String> parsedImgs = [];
    final rawImgs = json['images'];
    if (rawImgs is List) {
      parsedImgs = rawImgs.map((e) => e.toString()).where((s) => s.isNotEmpty).toList();
    } else if (rawImgs is String && rawImgs.trim().startsWith('[')) {
      try {
        final decoded = jsonDecode(rawImgs) as List;
        parsedImgs = decoded.map((e) => e.toString()).where((s) => s.isNotEmpty).toList();
      } catch (_) {}
    }
    if (parsedImgs.isEmpty) parsedImgs = [primaryImg];

    List<ProductColor> parsedCols = [];
    final rawCols = json['colors'];
    if (rawCols is List) {
      parsedCols = rawCols.whereType<Map>().map((e) => ProductColor.fromJson(Map<String, dynamic>.from(e))).toList();
    } else if (rawCols is String && rawCols.trim().startsWith('[')) {
      try {
        final decoded = jsonDecode(rawCols) as List;
        parsedCols = decoded.whereType<Map>().map((e) => ProductColor.fromJson(Map<String, dynamic>.from(e))).toList();
      } catch (_) {}
    }

    return ProductModel(
      id: int.tryParse(json['id'].toString()) ?? 0,
      categoryId: json['category_id'] != null ? int.tryParse(json['category_id'].toString()) : null,
      title: json['title'] ?? '',
      subtitle: json['subtitle'] ?? '',
      price: double.tryParse(json['price'].toString()) ?? 0.0,
      originalPrice: json['original_price'] != null ? double.tryParse(json['original_price'].toString()) : null,
      description: json['description'] ?? '',
      image: primaryImg,
      images: parsedImgs,
      colors: parsedCols,
      stock: int.tryParse(json['stock']?.toString() ?? '50') ?? 50,
      categoryName: json['category_name'],
      isFlashSale: json['is_flash_sale'] == 1 || json['is_flash_sale'] == '1' || json['is_flash_sale'] == true,
      flashDiscountPercent: int.tryParse(json['flash_discount_percent']?.toString() ?? '0') ?? 0,
      itemsSold: int.tryParse(json['items_sold']?.toString() ?? '5') ?? 5,
      avgRating: double.tryParse(json['avg_rating']?.toString() ?? '5.0') ?? 5.0,
      reviewCount: int.tryParse(json['review_count']?.toString() ?? '0') ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'category_id': categoryId,
      'title': title,
      'subtitle': subtitle,
      'price': price,
      'original_price': originalPrice,
      'description': description,
      'image': image,
      'images': images,
      'colors': colors.map((c) => c.toJson()).toList(),
      'stock': stock,
      'category_name': categoryName,
      'is_flash_sale': isFlashSale,
      'flash_discount_percent': flashDiscountPercent,
      'items_sold': itemsSold,
      'avg_rating': avgRating,
      'review_count': reviewCount,
    };
  }
}
