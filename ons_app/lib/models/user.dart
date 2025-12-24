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
  final UserRole role;
  final String token;     

  User({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    required this.token,
  });
}

UserRole userRoleFromString(String role) {
  switch (role.toLowerCase()) {
    case 'admin':
      return UserRole.admin;
    case 'caregiver':
      return UserRole.caregiver;
    case 'family':
      return UserRole.family;
    case 'retirement_home':
    case 'retirementhome':
      return UserRole.retirementHome;
    default:
      return UserRole.family;
  }
}
