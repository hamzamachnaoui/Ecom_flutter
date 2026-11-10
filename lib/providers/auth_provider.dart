import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:ecom_app/models/user.dart';
import 'package:ecom_app/services/api_service.dart';

class AuthProvider extends ChangeNotifier {
  User? _currentUser;
  String? _token;
  bool _isLoading = false;

  User? get currentUser => _currentUser;
  String? get token => _token;
  bool get isLoading => _isLoading;
  bool get isAuthenticated => _currentUser != null;

  AuthProvider() {
    _loadUserFromPrefs();
  }

  Future<void> _loadUserFromPrefs() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userJson = prefs.getString('user');
      _token = prefs.getString('token');
      if (userJson != null) {
        _currentUser = User.fromJson(jsonDecode(userJson));
        notifyListeners();
      }
    } catch (_) {}
  }

  Future<Map<String, dynamic>> login(String email, String password) async {
    _isLoading = true;
    notifyListeners();

    final res = await ApiService.login(email: email, password: password);
    _isLoading = false;

    if (res['success'] == true && res['data'] != null) {
      _currentUser = User.fromJson(res['data']['user']);
      _token = res['data']['token'];

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('user', jsonEncode(_currentUser!.toJson()));
      await prefs.setString('token', _token ?? '');

      notifyListeners();
      return {'success': true, 'message': res['message']};
    } else {
      notifyListeners();
      return {'success': false, 'message': res['message'] ?? 'Échec de connexion.'};
    }
  }

  Future<Map<String, dynamic>> register({
    required String name,
    required String email,
    required String password,
    String? referralCode,
  }) async {
    _isLoading = true;
    notifyListeners();

    final res = await ApiService.register(
      name: name,
      email: email,
      password: password,
      referralCode: referralCode,
    );
    _isLoading = false;
    notifyListeners();

    return res;
  }

  Future<Map<String, dynamic>> verifyEmail(String email, String code) async {
    _isLoading = true;
    notifyListeners();

    final res = await ApiService.verifyEmail(email: email, code: code);
    _isLoading = false;

    if (res['success'] == true && _currentUser != null && _currentUser!.email == email) {
      _currentUser = User(
        id: _currentUser!.id,
        name: _currentUser!.name,
        email: _currentUser!.email,
        referralCode: _currentUser!.referralCode,
        referredBy: _currentUser!.referredBy,
        isVerified: true,
      );
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('user', jsonEncode(_currentUser!.toJson()));
    }

    notifyListeners();
    return res;
  }

  Future<Map<String, dynamic>> forgotPassword(String email) async {
    _isLoading = true;
    notifyListeners();
    final res = await ApiService.forgotPassword(email);
    _isLoading = false;
    notifyListeners();
    return res;
  }

  Future<Map<String, dynamic>> resetPassword({
    required String email,
    required String code,
    required String newPassword,
  }) async {
    _isLoading = true;
    notifyListeners();
    final res = await ApiService.resetPassword(
      email: email,
      code: code,
      newPassword: newPassword,
    );
    _isLoading = false;
    notifyListeners();
    return res;
  }

  Future<void> logout() async {
    _currentUser = null;
    _token = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('user');
    await prefs.remove('token');
    notifyListeners();
  }
}

