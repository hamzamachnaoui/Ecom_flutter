import 'package:flutter/material.dart';
import 'package:ecom_app/models/cart_item.dart';
import 'package:ecom_app/models/coupon.dart';
import 'package:ecom_app/models/product.dart';
import 'package:ecom_app/services/api_service.dart';

class CartProvider extends ChangeNotifier {
  final Map<String, CartItem> _items = {};
  CouponModel? _appliedCoupon;
  String? _couponError;
  bool _isCheckingCoupon = false;

  Map<String, CartItem> get items => {..._items};
  List<CartItem> get cartList => _items.values.toList();
  int get itemCount => _items.values.fold(0, (sum, item) => sum + item.quantity);
  CouponModel? get appliedCoupon => _appliedCoupon;
  String? get couponError => _couponError;
  bool get isCheckingCoupon => _isCheckingCoupon;

  double get subtotal {
    return _items.values.fold(0.0, (sum, item) => sum + item.totalPrice);
  }

  double get discountAmount {
    if (_appliedCoupon == null) return 0.0;
    if (_appliedCoupon!.discountType == 'percent') {
      return (subtotal * _appliedCoupon!.discountValue) / 100.0;
    } else {
      return _appliedCoupon!.discountValue > subtotal
          ? subtotal
          : _appliedCoupon!.discountValue;
    }
  }

  double get totalAmount {
    final res = subtotal - discountAmount;
    return res > 0 ? res : 0.0;
  }

  void addToCart(ProductModel product, {int quantity = 1, String? selectedColor, String? selectedImage}) {
    final defaultColor = product.colors.isNotEmpty ? product.colors.first : null;
    final colorName = (selectedColor != null && selectedColor.isNotEmpty)
        ? selectedColor
        : (defaultColor?.name ?? '');
    final colorImage = (selectedImage != null && selectedImage.isNotEmpty)
        ? selectedImage
        : (defaultColor?.image);
    final key = '${product.id}_$colorName';

    if (_items.containsKey(key)) {
      _items[key]!.quantity += quantity;
    } else {
      _items[key] = CartItem(
        product: product,
        quantity: quantity,
        selectedColor: colorName,
        selectedImage: colorImage,
      );
    }
    notifyListeners();
  }

  void updateQuantity(int productId, int quantity, {String selectedColor = ''}) {
    final key = '${productId}_$selectedColor';
    final targetKey = _items.containsKey(key)
        ? key
        : _items.keys.firstWhere((k) => k.startsWith('${productId}_'), orElse: () => '');

    if (targetKey.isNotEmpty && _items.containsKey(targetKey)) {
      if (quantity <= 0) {
        _items.remove(targetKey);
      } else {
        _items[targetKey]!.quantity = quantity;
      }
      notifyListeners();
    }
  }

  void removeFromCart(int productId, {String selectedColor = ''}) {
    final key = '${productId}_$selectedColor';
    if (_items.containsKey(key)) {
      _items.remove(key);
    } else {
      _items.removeWhere((k, _) => k.startsWith('${productId}_'));
    }
    notifyListeners();
  }

  void clearCart() {
    _items.clear();
    _appliedCoupon = null;
    _couponError = null;
    notifyListeners();
  }

  Future<bool> applyCoupon(String code) async {
    if (code.trim().isEmpty) return false;
    _isCheckingCoupon = true;
    _couponError = null;
    notifyListeners();

    final res = await ApiService.validateCoupon(
      code: code.trim(),
      amount: subtotal,
    );

    _isCheckingCoupon = false;
    if (res['success'] == true) {
      _appliedCoupon = res['coupon'];
      _couponError = null;
      notifyListeners();
      return true;
    } else {
      _appliedCoupon = null;
      _couponError = res['message'];
      notifyListeners();
      return false;
    }
  }

  void removeCoupon() {
    _appliedCoupon = null;
    _couponError = null;
    notifyListeners();
  }
}
