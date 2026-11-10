import 'package:ecom_app/models/product.dart';

class CartItem {
  final ProductModel product;
  int quantity;
  final String selectedColor;
  final String? selectedImage;

  CartItem({
    required this.product,
    this.quantity = 1,
    this.selectedColor = '',
    this.selectedImage,
  });

  String get displayImage => (selectedImage != null && selectedImage!.isNotEmpty) ? selectedImage! : product.image;
  String get key => '${product.id}_$selectedColor';
  double get totalPrice => product.price * quantity;
}
