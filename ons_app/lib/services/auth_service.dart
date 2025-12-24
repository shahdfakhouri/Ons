import 'dart:convert';
import 'package:http/http.dart' as http;
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
      if (token == null) {
        print('❌ No token in response');
        return null;
      }

      _token = token;

      final user = User(
        id: '',               // we can fill this later if backend returns id
        name: 'Ons Admin',    // placeholder name for now
        email: email.trim(),
        role: role,
        token: token,
      );

      _currentUser = user;
      return user;
    } else {
      // non-200 from backend (e.g. Invalid email or password)
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
  final url = Uri.parse('$_baseUrl/signup');  // 👈 fixed

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
  void logout() {
    _currentUser = null;
    _token = null;
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

  bool get isAdmin => _currentUser?.role == UserRole.admin;
}
