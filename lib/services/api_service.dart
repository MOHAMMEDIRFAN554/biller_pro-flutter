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

  Future<bool> login(String email, String password) async {
    _isLoading = true;
    notifyListeners();

    try {
      final response = await http.post(
        Uri.parse('$baseUrl/users/auth'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'email': email, 'password': password}),
      );

      if (response.statusCode == 200) {
        _userInfo = json.decode(response.body);
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
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<void> logout() async {
    _userInfo = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('userInfo');
    notifyListeners();
  }

  // Common GET helper with Auth header (simulated, as original server uses cookies)
  // Note: For mobile, you might need to adjust the backend to support Header-based Auth 
  // if cookies are not handled automatically by the platform.
  Future<dynamic> get(String endpoint) async {
    // Add logic here to include credentials/cookies if needed
    final response = await http.get(Uri.parse('$baseUrl/$endpoint'));
    if (response.statusCode == 200) {
      return json.decode(response.body);
    }
    throw Exception('Failed to load data');
  }
}
