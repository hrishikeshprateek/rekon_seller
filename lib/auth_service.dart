// filepath: /Users/hrishikeshprateek/AndroidStudioProjects/reckon_seller_2_0/lib/auth_service.dart
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'dart:async';

class AuthService with ChangeNotifier {
  // API configuration - will be updated with new APIs later
  static const String baseUrl = 'https://your-api-endpoint.com'; // TODO: Update this

  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  Completer<void>? _autoLoginCompleter;

  String? _accessToken;
  String? get accessToken => _accessToken;

  bool get isAuthenticated => _accessToken != null;

  // Simplified login - no API call for now
  Future<void> login(String email, String password) async {
    // TODO: Replace with actual API call when available
    // For now, just simulate login
    await Future.delayed(const Duration(milliseconds: 500));

    // Set a dummy token
    _accessToken = 'dummy_access_token';
    await _storage.write(key: 'access_token', value: _accessToken);
    notifyListeners();
  }

  Future<void> tryAutoLogin() async {
    if (_autoLoginCompleter != null) {
      return _autoLoginCompleter!.future;
    }

    _autoLoginCompleter = Completer();

    try {
      if (await _storage.containsKey(key: 'access_token')) {
        _accessToken = await _storage.read(key: 'access_token');
        notifyListeners();
      }
      _autoLoginCompleter!.complete();
    } catch (e) {
      _autoLoginCompleter!.completeError(e);
    }

    return _autoLoginCompleter!.future;
  }

  Future<void> logout() async {
    _accessToken = null;
    await _storage.deleteAll();
    _autoLoginCompleter = null;
    notifyListeners();
  }

  // Placeholder for future API integration
  Future<void> refreshToken() async {
    // TODO: Implement token refresh when API is available
    logout();
  }
}

