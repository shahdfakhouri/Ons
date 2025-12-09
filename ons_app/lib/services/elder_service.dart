// services/elder_service.dart
import 'package:ons_app/models/elder.dart';

class ElderService {
  /// Later this will call the backend. For now we return mock data.
  Future<List<Elder>> getAllElders() async {
    await Future.delayed(const Duration(milliseconds: 600));

    return [
      // Elder living at home with their family
      Elder(
        id: "e1",
        name: "Abu Ahmad",
        age: 77,
        medicalCondition: "Diabetes",
        livingType: "home",
        familyId: "fam1",
        retirementHomeId: null,
        caregiverId: "caregiver_1", // primary caregiver
      ),

      // Elder living in a retirement home
      Elder(
        id: "e2",
        name: "Um Omar",
        age: 82,
        medicalCondition: "Heart condition",
        livingType: "retirement_home",
        familyId: null,
        retirementHomeId: "home1", // id of the retirement home
        caregiverId: "caregiver_2",
      ),
    ];
  }

  Future<bool> addElder(Elder elder) async {
    // later: send POST to backend
    await Future.delayed(const Duration(milliseconds: 400));
    return true;
  }

  /// (Optional) helper to get elders for a specific caregiver
  Future<List<Elder>> getEldersForCaregiver(String caregiverId) async {
    final all = await getAllElders();
    return all.where((e) => e.caregiverId == caregiverId).toList();
  }
}
