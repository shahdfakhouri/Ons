import 'package:ons_app/models/caregiver.dart';

class CaregiverService {
  // Get all caregivers (dummy for now)
  Future<List<Caregiver>> getAllCaregivers() async {
    await Future.delayed(const Duration(milliseconds: 600));

    return [
      Caregiver(
        id: "1",
        name: "Sara Ahmad",
        experienceYears: 2,
        skills: ["Cleaning", "Medication", "Cooking"],
        rating: 4.5,
        isApproved: true,
        isAvailable: true,
      ),
      Caregiver(
        id: "2",
        name: "Mona Youssef",
        experienceYears: 5,
        skills: ["Physiotherapy", "Elderly Care"],
        rating: 4.8,
        isApproved: false,
        isAvailable: false,
      ),
    ];
  }

  // Approve caregiver
  Future<bool> approveCaregiver(String id) async {
    await Future.delayed(const Duration(milliseconds: 400));
    return true;
  }

  // Reject caregiver
  Future<bool> rejectCaregiver(String id) async {
    await Future.delayed(const Duration(milliseconds: 400));
    return true;
  }
}
