import 'package:flutter/material.dart';
import 'package:ecom_app/services/api_service.dart';

class ProductImageWidget extends StatelessWidget {
  final String imagePath;
  final BoxFit fit;

  const ProductImageWidget({
    Key? key,
    required this.imagePath,
    this.fit = BoxFit.contain,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final cleanPath = imagePath.trim();
    if (cleanPath.startsWith('http://') || cleanPath.startsWith('https://')) {
      return Image.network(
        cleanPath,
        fit: fit,
        errorBuilder: (_, __, ___) => _fallbackIcon(),
      );
    }
    if (cleanPath.startsWith('uploads/')) {
      return Image.network(
        '${ApiService.baseUrl}/$cleanPath',
        fit: fit,
        errorBuilder: (_, __, ___) => _fallbackIcon(),
      );
    }
    return Image.asset(
      cleanPath.isEmpty ? 'assets/images/airpod.png' : cleanPath,
      fit: fit,
      errorBuilder: (_, __, ___) => _fallbackIcon(),
    );
  }

  Widget _fallbackIcon() {
    return Center(
      child: Icon(Icons.devices_other_rounded, size: 42, color: Colors.grey.shade400),
    );
  }
}

