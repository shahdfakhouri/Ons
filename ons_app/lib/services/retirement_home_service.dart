// services/retirement_home_service.dart
import 'package:ons_app/models/retirement_home.dart';

class RetirementHomeService {
  Future<List<RetirementHome>> getAllHomes() async {
    await Future.delayed(const Duration(milliseconds: 600));

    return [
      RetirementHome(
        id: "rh1",
        name: "Al Rahma Home",
        location: "Nablus",
        capacity: 40,
        elders: ["e2"], // ids of elders staying here
        isApproved: true,
      ),
      RetirementHome(
        id: "rh2",
        name: "Elder Care House",
        location: "Ramallah",
        capacity: 30,
        elders: [],
        isApproved: false,
      ),
    ];
  }

  Future<bool> approveHome(String id) async {
    await Future.delayed(const Duration(milliseconds: 400));
    // later: call backend API
    return true;
  }

  Future<bool> rejectHome(String id) async {
    await Future.delayed(const Duration(milliseconds: 400));
    // later: call backend API
    return true;
  }
}
