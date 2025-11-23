// lib/models/user.dart
enum UserRole {
  family,
  caregiver,
  retirementHome,
  admin,
}

class User {
  final String id;
  final String name;
  final String email;
  final String password;   // <-- store password here
  final UserRole role;

  User({
    required this.id,
    required this.name,
    required this.email,
    required this.password, // <-- connect constructor
    required this.role,
  });
}
