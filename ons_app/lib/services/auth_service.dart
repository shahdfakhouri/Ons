import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import 'package:ons_app/models/user.dart';
import 'package:ons_app/core/constants/api_config.dart';

class AuthService {
  // Singleton
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal();

  final String _baseUrl = ApiConfig.authBase;

  User? _currentUser;
  User? get currentUser => _currentUser;

  String? _token;
  String? get token => _token;

  // 🔒 SharedPrefs keys
  static const _tokenKey = 'auth_token';
  static const _roleKey = 'auth_role';
  static const _emailKey = 'auth_email';

  // ------------ LOAD SESSION (call on app start) ------------
  Future<void> loadSession() async {
    final sp = await SharedPreferences.getInstance();
    final savedToken = sp.getString(_tokenKey);
    final savedRole = sp.getString(_roleKey);
    final savedEmail = sp.getString(_emailKey);

    if (savedToken == null || savedToken.isEmpty) return;
    if (savedRole == null || savedRole.isEmpty) return;

    _token = savedToken;

    _currentUser = User(
      id: '',
      name: 'Ons User',
      email: savedEmail ?? '',
      role: _backendStringToRole(savedRole),
      token: savedToken,
    );
  }

  Future<void> _saveSession({
    required String token,
    required UserRole role,
    required String email,
  }) async {
    final sp = await SharedPreferences.getInstance();
    await sp.setString(_tokenKey, token);
    await sp.setString(_roleKey, _roleToBackendString(role));
    await sp.setString(_emailKey, email);
  }

  // ------------ LOGIN (via backend) ------------
  Future<User?> login({
    required String email,
    required String password,
    required UserRole role,
  }) async {
    final url = Uri.parse('$_baseUrl/signin');

    try {
      print('🔐 Sending login request to $url');
      print('Body: email=$email, role=${_roleToBackendString(role)}');

      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': email.trim(),
          'password': password,
          'role': _roleToBackendString(role),
        }),
      );

      print('➡️ Status: ${response.statusCode}');
      print('➡️ Body: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        final token = data['token'] as String?;
        if (token == null || token.isEmpty) {
          print('❌ No token in response');
          return null;
        }

        _token = token;

        // ✅ Save token so it persists after restart
        await _saveSession(token: token, role: role, email: email.trim());

        final user = User(
          id: '', // fill later if backend returns id
          name: 'Ons User', // placeholder
          email: email.trim(),
          role: role,
          token: token,
        );

        _currentUser = user;
        return user;
      } else {
        return null;
      }
    } catch (e) {
      print('❌ Login error: $e');
      return null;
    }
  }

  // ------------ REGISTER (backend signup, optional now) ------------
  Future<bool> register({
    required String name,
    required String email,
    required String password,
    required String telephone,
    required UserRole role,
  }) async {
    final url = Uri.parse('$_baseUrl/signup');

    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'name': name.trim(),
          'email': email.trim(),
          'password': password,
          'telephone': telephone,
          'role': _roleToBackendString(role),
        }),
      );

      if (response.statusCode == 201) {
        return true;
      } else {
        final body = jsonDecode(response.body);
        print('Register failed: ${body['msg']}');
        return false;
      }
    } catch (e) {
      print('Register error: $e');
      return false;
    }
  }

  // ------------ LOGOUT ------------
  Future<void> logout() async {
    _currentUser = null;
    _token = null;

    final sp = await SharedPreferences.getInstance();
    await sp.remove(_tokenKey);
    await sp.remove(_roleKey);
    await sp.remove(_emailKey);
  }

  String _roleToBackendString(UserRole role) {
    switch (role) {
      case UserRole.admin:
        return 'admin';
      case UserRole.family:
        return 'family';
      case UserRole.caregiver:
        return 'caregiver';
      case UserRole.retirementHome:
        return 'retirement_home';
    }
  }

  UserRole _backendStringToRole(String role) {
    switch (role) {
      case 'admin':
        return UserRole.admin;
      case 'family':
        return UserRole.family;
      case 'caregiver':
        return UserRole.caregiver;
      case 'retirement_home':
        return UserRole.retirementHome;
      default:
        return UserRole.family;
    }
  }

  bool get isAdmin => _currentUser?.role == UserRole.admin;





  
}
