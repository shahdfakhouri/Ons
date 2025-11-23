// services/elder_service.dart
import 'package:ons_app/models/elder.dart';

class ElderService {
  Future<List<Elder>> getAllElders() async {
    await Future.delayed(const Duration(milliseconds: 600));

    return [
      Elder(
        id: "e1",
        name: "Abu Ahmad",
        age: 77,
        medicalCondition: "Diabetes",
        familyId: "fam1",
        careType: "daily visit",
        assignedCaregiverId: null,
      ),
      Elder(
        id: "e2",
        name: "Um Omar",
        age: 82,
        medicalCondition: "Heart Condition",
        familyId: "fam2",
        careType: "retirement home",
        assignedCaregiverId: "1",
      ),
    ];
  }

  Future<bool> addElder(Elder elder) async {
    await Future.delayed(const Duration(milliseconds: 400));
    return true;
  }
}
