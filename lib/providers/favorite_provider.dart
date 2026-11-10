import 'package:flutter/material.dart';
import 'package:ecom_app/models/product.dart';
import 'package:ecom_app/services/api_service.dart';

class FavoriteProvider extends ChangeNotifier {
  final Map<int, ProductModel> _favorites = {};
  bool _isLoading = false;

  Map<int, ProductModel> get favorites => _favorites;
  List<ProductModel> get favoriteList => _favorites.values.toList();
  bool get isLoading => _isLoading;

  bool isFavorite(int productId) => _favorites.containsKey(productId);

  Future<void> loadFavorites(int userId) async {
    _isLoading = true;
    notifyListeners();
    try {
      final list = await ApiService.getFavorites(userId);
      _favorites.clear();
      for (final p in list) {
        _favorites[p.id] = p;
      }
    } catch (_) {}
    _isLoading = false;
    notifyListeners();
  }

  Future<void> toggleFavorite(ProductModel product, int? userId) async {
    final isFav = _favorites.containsKey(product.id);
    if (isFav) {
      _favorites.remove(product.id);
    } else {
      _favorites[product.id] = product;
    }
    notifyListeners();

    if (userId != null && userId > 0) {
      await ApiService.toggleFavorite(userId, product.id);
    }
  }
}

