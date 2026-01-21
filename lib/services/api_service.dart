import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class ApiService extends ChangeNotifier {
  // Use Render URL for production, and your local IP (e.g., 192.168.1.X:5000) for local testing
  final String baseUrl = 'https://biller-pro-backend.onrender.com/api';
  
  Map<String, dynamic>? _userInfo;
  bool _isLoading = false;

  Map<String, dynamic>? get userInfo => _userInfo;
  bool get isLoading => _isLoading;
  bool get isAuthenticated => _userInfo != null;

  ApiService() {
    _loadUserInfo();
  }

  Future<void> _loadUserInfo() async {
    final prefs = await SharedPreferences.getInstance();
    final userString = prefs.getString('userInfo');
    if (userString != null) {
      _userInfo = json.decode(userString);
      notifyListeners();
    }
  }

  Future<String?> _getCookie() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('cookie');
  }

  Future<void> _saveCookie(String? cookie) async {
    if (cookie == null) return;
    final prefs = await SharedPreferences.getInstance();
    // Only save the jwt part
    final jwtCookie = cookie.split(';').firstWhere((element) => element.trim().startsWith('jwt='), orElse: () => '');
    if (jwtCookie.isNotEmpty) {
      await prefs.setString('cookie', jwtCookie);
    }
  }

  Future<bool> login(String email, String password) async {
    _isLoading = true;
    notifyListeners();

    try {
      final cookie = await _getCookie();
      final response = await http.post(
        Uri.parse('$baseUrl/users/login'), // Fixed endpoint from /auth to /login
        headers: {
          'Content-Type': 'application/json',
          if (cookie != null) 'cookie': cookie,
        },
        body: json.encode({'email': email, 'password': password}),
      );

      if (response.statusCode == 200) {
        _userInfo = json.decode(response.body);
        
        // Manual Cookie Handling
        final setCookie = response.headers['set-cookie'];
        if (setCookie != null) {
          await _saveCookie(setCookie);
        }

        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('userInfo', response.body);
        
        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        _isLoading = false;
        notifyListeners();
        return false;
      }
    } catch (e) {
      debugPrint('Login Error: $e');
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<void> logout() async {
    _userInfo = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('userInfo');
    await prefs.remove('cookie');
    notifyListeners();
  }

  Future<dynamic> get(String endpoint) async {
    final cookie = await _getCookie();
    final response = await http.get(
      Uri.parse('$baseUrl/$endpoint'),
      headers: {
        if (cookie != null) 'cookie': cookie,
      },
    );
    if (response.statusCode == 200) {
      return json.decode(response.body);
    }
    throw Exception('Failed to load data: ${response.statusCode}');
  }

  Future<dynamic> post(String endpoint, dynamic data) async {
    final cookie = await _getCookie();
    final response = await http.post(
      Uri.parse('$baseUrl/$endpoint'),
      headers: {
        'Content-Type': 'application/json',
        if (cookie != null) 'cookie': cookie,
      },
      body: json.encode(data),
    );
    if (response.statusCode == 200 || response.statusCode == 201) {
      return json.decode(response.body);
    }
    throw Exception('Failed to post data: ${response.statusCode}');
  }

  Future<dynamic> delete(String endpoint) async {
    final cookie = await _getCookie();
    final response = await http.delete(
      Uri.parse('$baseUrl/$endpoint'),
      headers: {
        if (cookie != null) 'cookie': cookie,
      },
    );
    if (response.statusCode == 200) {
      return json.decode(response.body);
    }
    throw Exception('Failed to delete data: ${response.statusCode}');
  }
}
