class Caregiver {
  final String id;
  final String name;
  final int experienceYears;
  final List<String> skills;
  final double rating;
  final bool isApproved;
  final bool isAvailable;

  Caregiver({
    required this.id,
    required this.name,
    required this.experienceYears,
    required this.skills,
    required this.rating,
    required this.isApproved,
    required this.isAvailable,
  });
}
