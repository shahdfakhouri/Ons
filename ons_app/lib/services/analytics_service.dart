// services/analytics_service.dart

class AnalyticsService {
  Future<Map<String, int>> getSummary() async {
    await Future.delayed(const Duration(milliseconds: 400));
    return {
      "caregivers": 24,
      "elders": 19,
      "homes": 4,
      "matches": 12,
    };
  }
}
