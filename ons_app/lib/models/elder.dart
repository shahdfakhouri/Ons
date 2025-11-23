class Elder {
  final String id;
  final String name;
  final int age;
  final String medicalCondition;
  final String familyId; // linked to User.id
  final String careType; // daily visit, live-in, retirement home
  final String? assignedCaregiverId;

  Elder({
    required this.id,
    required this.name,
    required this.age,
    required this.medicalCondition,
    required this.familyId,
    required this.careType,
    this.assignedCaregiverId,
  });
}
