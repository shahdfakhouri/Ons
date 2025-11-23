// lib/services/auth_service.dart
import 'dart:async';
import 'package:ons_app/models/user.dart';

class AuthService {
  // Singleton
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal();

  User? _currentUser;
  User? get currentUser => _currentUser;

  // ---- TEMP IN-MEMORY USERS (for testing only) ----
  final List<User> _users = [
    User(
      id: '1',
      name: 'Admin User',
      email: 'admin@ons.com',
      password: '123456',
      role: UserRole.admin,
    ),
    User(
      id: '2',
      name: 'Family Member',
      email: 'family@ons.com',
      password: '123456',
      role: UserRole.family,
    ),
    User(
      id: '3',
      name: 'Caregiver',
      email: 'caregiver@ons.com',
      password: '123456',
      role: UserRole.caregiver,
    ),
    User(
      id: '4',
      name: 'Retirement Home Admin',
      email: 'rh@ons.com',
      password: '123456',
      role: UserRole.retirementHome,
    ),
  ];

  // ------------ LOGIN ------------
  Future<User?> login({
    required String email,
    required String password,
  }) async {
    await Future.delayed(const Duration(milliseconds: 600));

    try {
      final user = _users.firstWhere(
        (u) =>
            u.email.toLowerCase().trim() == email.toLowerCase().trim() &&
            u.password == password,
      );
      _currentUser = user;
      return user;
    } catch (_) {
      return null; // not found
    }
  }

  // ------------ REGISTER (dummy) ------------
  Future<User> register({
    required String name,
    required String email,
    required String password,
    required UserRole role,
  }) async {
    await Future.delayed(const Duration(milliseconds: 600));

    final newUser = User(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: name,
      email: email.trim(),
      password: password,
      role: role,
    );

    _users.add(newUser);
    _currentUser = newUser;
    return newUser;
  }

  // ------------ LOGOUT ------------
  void logout() {
    _currentUser = null;
  }
}
