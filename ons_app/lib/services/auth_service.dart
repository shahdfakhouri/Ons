import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:jwt_decoder/jwt_decoder.dart';

import 'package:ons_app/models/user.dart';
import 'package:ons_app/core/constants/api_config.dart';

class AuthService {
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal();

  final String _baseUrl = ApiConfig.authBase;

  User? _currentUser;
  User? get currentUser => _currentUser;

  String? _token;
  String? get token => _token;

  static const _tokenKey = 'auth_token';
  static const _roleKey = 'auth_role';
  static const _emailKey = 'auth_email';

  // --- helpers ---
  int? _extractIdFromToken(String token) {
    try {
      final Map<String, dynamic> d = JwtDecoder.decode(token);

      // try common keys (adjust if your backend uses different key)
      final candidates = [
        d['id'],
        d['user_id'],
        d['caregiver_id'],
        d['family_id'],
      ];

      for (final v in candidates) {
        if (v == null) continue;
        final n = int.tryParse(v.toString());
        if (n != null) return n;
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  void _setCurrentUserFromToken({
    required String token,
    required UserRole role,
    required String email,
  }) {
    final id = _extractIdFromToken(token);
    _currentUser = User(
      id: id?.toString() ?? '',
      name: 'Ons User',
      email: email,
      role: role,
      token: token,
    );
  }

  /// Preferred: integer ID for the logged-in user (decoded from token if needed)
  int? get myIdInt {
    final idStr = _currentUser?.id ?? '';
    final n = int.tryParse(idStr);
    if (n != null) return n;

    final t = _token;
    if (t == null) return null;
    return _extractIdFromToken(t);
  }

  /// ✅ Fix: some pages call AuthService().myId
  int? get myId => myIdInt;

  /// Optional aliases (safe to keep)
  int? get userId => myIdInt;
  String? get myIdStr {
    final n = myIdInt;
    return n == null ? null : n.toString();
  }

  // ------------ LOAD SESSION ------------
  Future<void> loadSession() async {
    final sp = await SharedPreferences.getInstance();
    final savedToken = sp.getString(_tokenKey);
    final savedRole = sp.getString(_roleKey);
    final savedEmail = sp.getString(_emailKey);

    if (savedToken == null || savedToken.isEmpty) return;
    if (savedRole == null || savedRole.isEmpty) return;

    _token = savedToken;

    final role = _backendStringToRole(savedRole);
    _setCurrentUserFromToken(
      token: savedToken,
      role: role,
      email: savedEmail ?? '',
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

  // ------------ LOGIN ------------
  Future<User?> login({
    required String email,
    required String password,
    required UserRole role,
  }) async {
    final url = Uri.parse('$_baseUrl/signin');

    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': email.trim(),
          'password': password,
          'role': _roleToBackendString(role),
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        final token = data['token'] as String?;
        if (token == null || token.isEmpty) return null;

        _token = token;

        await _saveSession(token: token, role: role, email: email.trim());
        _setCurrentUserFromToken(token: token, role: role, email: email.trim());

        return _currentUser;
      }

      return null;
    } catch (_) {
      return null;
    }
  }

  // ------------ REGISTER ------------
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

      return response.statusCode == 201;
    } catch (_) {
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
