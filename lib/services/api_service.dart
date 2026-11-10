import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:ecom_app/models/product.dart';
import 'package:ecom_app/models/coupon.dart';
import 'package:ecom_app/models/order.dart';
import 'package:ecom_app/models/review.dart';
import 'package:ecom_app/models/support_ticket.dart';

class ApiService {
  // Optional compile-time override for Vercel / cloud deployments:
  // flutter build web --release --base-href "/" --dart-define=API_BASE_URL=https://your-api-host/ecom_api
  static const String _envBaseUrl = String.fromEnvironment('API_BASE_URL');

  // Dynamically use current browser host on Web so localhost and LAN IP both work
  static String get baseUrl {
    if (_envBaseUrl.isNotEmpty) {
      return _envBaseUrl.endsWith('/')
          ? _envBaseUrl.substring(0, _envBaseUrl.length - 1)
          : _envBaseUrl;
    }
    if (kIsWeb) {
      final scheme = Uri.base.scheme.isNotEmpty ? Uri.base.scheme : 'http';
      final host = Uri.base.host.isNotEmpty ? Uri.base.host : 'localhost';
      return '$scheme://$host/ecom_api';
    }
    if (defaultTargetPlatform == TargetPlatform.android) {
      return 'http://10.0.2.2/ecom_api';
    }
    return 'http://localhost/ecom_api';
  }

  static final Map<String, String> _headers = {
    'Content-Type': 'application/json; charset=UTF-8',
    'Accept': 'application/json',
  };

  // --- AUTHENTICATION ---

  static Future<Map<String, dynamic>> register({
    required String name,
    required String email,
    required String password,
    String? referralCode,
  }) async {
    final url = Uri.parse('$baseUrl/auth/register.php');
    try {
      final response = await http.post(
        url,
        headers: _headers,
        body: jsonEncode({
          'name': name,
          'email': email,
          'password': password,
          if (referralCode != null && referralCode.isNotEmpty)
            'referral_code': referralCode,
        }),
      );
      final json = jsonDecode(response.body);
      return json;
    } catch (e) {
      return {'success': false, 'message': 'Erreur réseau : $e'};
    }
  }

  static Future<Map<String, dynamic>> verifyEmail({
    required String email,
    required String code,
  }) async {
    final url = Uri.parse('$baseUrl/auth/verify_email.php');
    try {
      final response = await http.post(
        url,
        headers: _headers,
        body: jsonEncode({'email': email, 'code': code}),
      );
      return jsonDecode(response.body);
    } catch (e) {
      return {'success': false, 'message': 'Erreur réseau : $e'};
    }
  }

  static Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    final url = Uri.parse('$baseUrl/auth/login.php');
    try {
      final response = await http.post(
        url,
        headers: _headers,
        body: jsonEncode({'email': email, 'password': password}),
      );
      return jsonDecode(response.body);
    } catch (e) {
      return {'success': false, 'message': 'Erreur réseau : $e'};
    }
  }

  static Future<Map<String, dynamic>> forgotPassword(String email) async {
    final url = Uri.parse('$baseUrl/auth/forgot_password.php');
    try {
      final response = await http.post(
        url,
        headers: _headers,
        body: jsonEncode({'email': email}),
      );
      return jsonDecode(response.body);
    } catch (e) {
      return {'success': false, 'message': 'Erreur réseau : $e'};
    }
  }

  static Future<Map<String, dynamic>> resetPassword({
    required String email,
    required String code,
    required String newPassword,
  }) async {
    final url = Uri.parse('$baseUrl/auth/reset_password.php');
    try {
      final response = await http.post(
        url,
        headers: _headers,
        body: jsonEncode({
          'email': email,
          'code': code,
          'new_password': newPassword,
        }),
      );
      return jsonDecode(response.body);
    } catch (e) {
      return {'success': false, 'message': 'Erreur réseau : $e'};
    }
  }

  // --- PRODUCTS ---

  static Future<Map<String, dynamic>> getProducts({
    int? categoryId,
    String? search,
  }) async {
    var uriStr = '$baseUrl/products.php?';
    if (categoryId != null && categoryId > 1) {
      uriStr += 'category_id=$categoryId&';
    }
    if (search != null && search.isNotEmpty) {
      uriStr += 'search=${Uri.encodeComponent(search)}&';
    }

    try {
      final response = await http.get(Uri.parse(uriStr), headers: _headers);
      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);
        if (json['success'] == true) {
          final rawProducts = json['data']['products'] as List;
          final rawCategories = json['data']['categories'] as List;
          final rawBanners = (json['data']['banners'] as List?) ?? [];
          final rawFlashSales = (json['data']['flash_sales'] as List?) ?? [];

          final products = rawProducts.map((p) => ProductModel.fromJson(p)).toList();
          final flashSales = rawFlashSales.map((p) => ProductModel.fromJson(p)).toList();

          return {
            'success': true,
            'products': products,
            'categories': rawCategories,
            'banners': rawBanners,
            'flash_sales': flashSales,
          };
        }
      }
      return {'success': false, 'products': <ProductModel>[], 'categories': [], 'banners': [], 'flash_sales': <ProductModel>[]};
    } catch (e) {
      return {'success': false, 'message': e.toString(), 'products': <ProductModel>[], 'categories': [], 'banners': [], 'flash_sales': <ProductModel>[]};
    }
  }

  // --- COUPONS ---

  static Future<Map<String, dynamic>> validateCoupon({
    required String code,
    required double amount,
  }) async {
    final url = Uri.parse('$baseUrl/coupons/validate.php');
    try {
      final response = await http.post(
        url,
        headers: _headers,
        body: jsonEncode({'code': code, 'amount': amount}),
      );
      final json = jsonDecode(response.body);
      if (json['success'] == true) {
        return {
          'success': true,
          'coupon': CouponModel.fromJson(json['data']),
          'message': json['message'],
        };
      }
      return {'success': false, 'message': json['message'] ?? 'Coupon invalide.'};
    } catch (e) {
      return {'success': false, 'message': 'Erreur coupon : $e'};
    }
  }

  // --- REFERRAL ---

  static Future<Map<String, dynamic>> getReferralStats(int userId) async {
    final url = Uri.parse('$baseUrl/referral/stats.php?user_id=$userId');
    try {
      final response = await http.get(url, headers: _headers);
      return jsonDecode(response.body);
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  // --- FAVORITES ---

  static Future<bool> toggleFavorite(int userId, int productId) async {
    final url = Uri.parse('$baseUrl/favorites/toggle.php');
    try {
      final response = await http.post(
        url,
        headers: _headers,
        body: jsonEncode({'user_id': userId, 'product_id': productId}),
      );
      final json = jsonDecode(response.body);
      return json['success'] == true && json['data']['is_favorite'] == true;
    } catch (e) {
      return false;
    }
  }

  static Future<List<ProductModel>> getFavorites(int userId) async {
    final url = Uri.parse('$baseUrl/favorites/list.php?user_id=$userId');
    try {
      final response = await http.get(url, headers: _headers);
      final json = jsonDecode(response.body);
      if (json['success'] == true) {
        final list = json['data'] as List;
        return list.map((p) => ProductModel.fromJson(p)).toList();
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  // --- ORDERS ---

  static Future<Map<String, dynamic>> createOrder({
    required int userId,
    required List<Map<String, dynamic>> items,
    required String shippingName,
    required String shippingPhone,
    required String shippingAddress,
    String? couponCode,
    String paymentMethod = 'cod',
  }) async {
    final url = Uri.parse('$baseUrl/orders/create.php');
    try {
      final response = await http.post(
        url,
        headers: _headers,
        body: jsonEncode({
          'user_id': userId,
          'items': items,
          'shipping_name': shippingName,
          'shipping_phone': shippingPhone,
          'shipping_address': shippingAddress,
          'payment_method': paymentMethod,
          if (couponCode != null && couponCode.isNotEmpty)
            'coupon_code': couponCode,
        }),
      );
      return jsonDecode(response.body);
    } catch (e) {
      return {'success': false, 'message': 'Erreur commande : $e'};
    }
  }

  static Future<List<OrderModel>> getOrders(int userId) async {
    final url = Uri.parse('$baseUrl/orders/list.php?user_id=$userId');
    try {
      final response = await http.get(url, headers: _headers);
      final json = jsonDecode(response.body);
      if (json['success'] == true) {
        final list = json['data'] as List;
        return list.map((o) => OrderModel.fromJson(o)).toList();
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  // --- REVIEWS & RATINGS ---

  static Future<Map<String, dynamic>> getReviews(int productId) async {
    final url = Uri.parse('$baseUrl/reviews/list.php?product_id=$productId');
    try {
      final response = await http.get(url, headers: _headers);
      final json = jsonDecode(response.body);
      if (json['success'] == true) {
        final rawList = json['data']['reviews'] as List;
        final list = rawList.map((r) => ReviewModel.fromJson(r)).toList();
        return {
          'success': true,
          'average_rating': double.tryParse(json['data']['average_rating'].toString()) ?? 5.0,
          'total_reviews': int.tryParse(json['data']['total_reviews'].toString()) ?? 0,
          'reviews': list,
        };
      }
      return {'success': false, 'average_rating': 5.0, 'total_reviews': 0, 'reviews': <ReviewModel>[]};
    } catch (e) {
      return {'success': false, 'average_rating': 5.0, 'total_reviews': 0, 'reviews': <ReviewModel>[]};
    }
  }

  static Future<Map<String, dynamic>> addReview({
    required int productId,
    required int userId,
    required String userName,
    required int rating,
    required String comment,
  }) async {
    final url = Uri.parse('$baseUrl/reviews/add.php');
    try {
      final response = await http.post(
        url,
        headers: _headers,
        body: jsonEncode({
          'product_id': productId,
          'user_id': userId,
          'user_name': userName,
          'rating': rating,
          'comment': comment,
        }),
      );
      return jsonDecode(response.body);
    } catch (e) {
      return {'success': false, 'message': 'Erreur avis : $e'};
    }
  }

  // --- SUPPORT / SAV ---

  static Future<Map<String, dynamic>> createSupportTicket({
    int? userId,
    required String userName,
    required String userEmail,
    required String category,
    String priority = 'normale',
    required String subject,
    int? orderId,
    int? productId,
    String? productTitle,
    required String message,
  }) async {
    final url = Uri.parse('$baseUrl/support/create.php');
    try {
      final response = await http.post(
        url,
        headers: _headers,
        body: jsonEncode({
          if (userId != null) 'user_id': userId,
          'user_name': userName,
          'user_email': userEmail,
          'category': category,
          'priority': priority,
          'subject': subject,
          if (orderId != null) 'order_id': orderId,
          if (productId != null) 'product_id': productId,
          if (productTitle != null && productTitle.isNotEmpty) 'product_title': productTitle,
          'message': message,
        }),
      );
      return jsonDecode(response.body);
    } catch (e) {
      return {'success': false, 'message': 'Erreur réseau : $e'};
    }
  }

  static Future<Map<String, dynamic>> sendSupportFollowup({
    required int ticketId,
    String action = 'followup',
    String message = '',
  }) async {
    final url = Uri.parse('$baseUrl/support/followup.php');
    try {
      final response = await http.post(
        url,
        headers: _headers,
        body: jsonEncode({
          'ticket_id': ticketId,
          'action': action,
          'message': message,
        }),
      );
      return jsonDecode(response.body);
    } catch (e) {
      return {'success': false, 'message': 'Erreur réseau : $e'};
    }
  }

  static Future<List<SupportTicketModel>> getSupportTickets({int? userId, String? email}) async {
    final query = userId != null
        ? 'user_id=$userId'
        : (email != null && email.isNotEmpty ? 'email=${Uri.encodeComponent(email)}' : '');
    if (query.isEmpty) return [];
    final url = Uri.parse('$baseUrl/support/list.php?$query');
    try {
      final response = await http.get(url, headers: _headers);
      final json = jsonDecode(response.body);
      if (json['success'] == true) {
        final list = json['data'] as List;
        return list.map((t) => SupportTicketModel.fromJson(t)).toList();
      }
      return [];
    } catch (e) {
      return [];
    }
  }
}
