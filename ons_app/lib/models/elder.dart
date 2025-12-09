// lib/models/elder.dart
class Elder {
  final String id;
  final String name;
  final int age;

  final String? medicalCondition;

  /// 'home' or 'retirement_home'
  final String livingType;

  /// If elder lives at home (with family)
  final String? familyId;

  /// If elder lives in a retirement home
  final String? retirementHomeId;

  /// Primary caregiver assigned to this elder (can be null if not assigned yet)
  final String? caregiverId;

  const Elder({
    required this.id,
    required this.name,
    required this.age,
    this.medicalCondition,
    required this.livingType,
    this.familyId,
    this.retirementHomeId,
    this.caregiverId,
  });
}
