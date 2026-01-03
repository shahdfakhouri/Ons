import 'package:dio/dio.dart';

class CaregiverApi {
  final Dio dio;
  static const String _base = '/api/caregiver';

  CaregiverApi(this.dio);

  // 1) dashboard + profile
  Future<Map<String, dynamic>> getDashboard() async {
    final res = await dio.get('$_base/dashboard');
    return Map<String, dynamic>.from(res.data);
  }

  Future<Map<String, dynamic>> getMyProfile() async {
    final res = await dio.get('$_base/me');
    return Map<String, dynamic>.from(res.data);
  }

  Future<void> updateProfile(Map<String, dynamic> body) async {
    await dio.put('$_base/me', data: body);
  }

  Future<Map<String, dynamic>> getElderStatus(int elderId) async {
    final res = await dio.get('$_base/elders/$elderId/status');
    return Map<String, dynamic>.from(res.data);
  }

  // 2) assigned elders
  Future<List<Map<String, dynamic>>> getAssignedElders() async {
    final res = await dio.get('$_base/elders');
    final list = (res.data['elders'] as List?) ?? [];
    return list.map((e) => Map<String, dynamic>.from(e)).toList();
  }

  Future<Map<String, dynamic>> getElderDetails(int elderId) async {
    final res = await dio.get('$_base/elders/$elderId');
    return Map<String, dynamic>.from(res.data['elder'] ?? {});
  }

  // 3) health logging & history
  Future<void> createHealthLog(int elderId, Map<String, dynamic> body) async {
    await dio.post('$_base/elders/$elderId/health-log', data: body);
  }

  Future<List<Map<String, dynamic>>> getHealthLogs(int elderId, {int limit = 50}) async {
    final res = await dio.get(
      '$_base/elders/$elderId/health-logs',
      queryParameters: {'limit': limit},
    );
    final list = (res.data['logs'] as List?) ?? [];
    return list.map((e) => Map<String, dynamic>.from(e)).toList();
  }

  // alerts
  Future<List<Map<String, dynamic>>> getMyAlerts() async {
    final res = await dio.get('$_base/alerts');
    final list = (res.data['alerts'] as List?) ?? [];
    return list.map((e) => Map<String, dynamic>.from(e)).toList();
  }

  Future<List<Map<String, dynamic>>> getElderAlerts(int elderId) async {
    final res = await dio.get('$_base/elders/$elderId/alerts');
    final list = (res.data['alerts'] as List?) ?? [];
    return list.map((e) => Map<String, dynamic>.from(e)).toList();
  }

  // 4) medication (read-only here, since your controller snippet doesn’t show a POST log endpoint)
  Future<List<Map<String, dynamic>>> getMedicationPlan(int elderId) async {
    final res = await dio.get('$_base/elders/$elderId/medications');
    final list = (res.data['medications'] as List?) ?? [];
    return list.map((e) => Map<String, dynamic>.from(e)).toList();
  }

  Future<List<Map<String, dynamic>>> getTodayMedicationChecklist(int elderId) async {
    final res = await dio.get('$_base/elders/$elderId/medications/today');
    final list = (res.data['checklist'] as List?) ?? [];
    return list.map((e) => Map<String, dynamic>.from(e)).toList();
  }

  Future<List<Map<String, dynamic>>> getMedicationLogs(int elderId, {String? date}) async {
    final res = await dio.get(
      '$_base/elders/$elderId/medication-logs',
      queryParameters: {'date': date},
    );
    final list = (res.data['logs'] as List?) ?? [];
    return list.map((e) => Map<String, dynamic>.from(e)).toList();
  }

  Future<Map<String, dynamic>> getMedicationStats(int elderId, {int days = 7}) async {
    final res = await dio.get(
      '$_base/elders/$elderId/medications/stats',
      queryParameters: {'days': days},
    );
    return Map<String, dynamic>.from(res.data);
  }

  // 5) daily summary
  Future<void> upsertDailySummary(int elderId, Map<String, dynamic> body) async {
    await dio.post('$_base/elders/$elderId/daily-summary', data: body);
  }

  Future<Map<String, dynamic>?> getDailySummary(int elderId) async {
    final res = await dio.get('$_base/elders/$elderId/daily-summary');
    final summary = res.data['summary'];
    if (summary == null) return null;
    return Map<String, dynamic>.from(summary);
  }

  // 6) incidents
  Future<void> createIncident(int elderId, Map<String, dynamic> body) async {
    await dio.post('$_base/elders/$elderId/incidents', data: body);
  }

  Future<List<Map<String, dynamic>>> getMyIncidents() async {
    final res = await dio.get('$_base/incidents');
    final list = (res.data['incidents'] as List?) ?? [];
    return list.map((e) => Map<String, dynamic>.from(e)).toList();
  }

  Future<Map<String, dynamic>> getIncidentById(int incidentId) async {
    final res = await dio.get('$_base/incidents/$incidentId');
    return Map<String, dynamic>.from(res.data['incident'] ?? {});
  }

  Future<void> updateIncidentStatus(int incidentId, String status) async {
    await dio.put('$_base/incidents/$incidentId/status', data: {'status': status});
  }

  // 7) checkin + location
  Future<void> checkIn(int elderId) async {
    await dio.post('$_base/elders/$elderId/checkin');
  }

  Future<void> updateLocation(int elderId, {required double latitude, required double longitude}) async {
    await dio.post('$_base/elders/$elderId/location', data: {
      'latitude': latitude,
      'longitude': longitude,
    });
  }

  Future<List<Map<String, dynamic>>> getLocationHistory(int elderId, {int limit = 100}) async {
    final res = await dio.get(
      '$_base/elders/$elderId/location/history',
      queryParameters: {'limit': limit},
    );
    final list = (res.data['history'] as List?) ?? [];
    return list.map((e) => Map<String, dynamic>.from(e)).toList();
  }

  // 8) shifts
  Future<void> startShift({String? notes}) async {
    await dio.post('$_base/shifts/start', data: {'notes': notes});
  }

  Future<void> endShift({String? notes}) async {
    await dio.post('$_base/shifts/end', data: {'notes': notes});
  }

  Future<Map<String, dynamic>?> getActiveShift() async {
    final res = await dio.get('$_base/shifts/active');
    final s = res.data['active_shift'];
    if (s == null) return null;
    return Map<String, dynamic>.from(s);
  }

  Future<List<Map<String, dynamic>>> getShiftHistory({int limit = 30}) async {
    final res = await dio.get('$_base/shifts/history', queryParameters: {'limit': limit});
    final list = (res.data['shifts'] as List?) ?? [];
    return list.map((e) => Map<String, dynamic>.from(e)).toList();
  }

  // 9) visits + family contacts
  Future<List<Map<String, dynamic>>> getUpcomingVisits({int limit = 50}) async {
    final res = await dio.get('$_base/visits/upcoming', queryParameters: {'limit': limit});
    final list = (res.data['visits'] as List?) ?? [];
    return list.map((e) => Map<String, dynamic>.from(e)).toList();
  }

  Future<List<Map<String, dynamic>>> getElderUpcomingVisits(int elderId, {int limit = 50}) async {
    final res = await dio.get('$_base/elders/$elderId/visits/upcoming', queryParameters: {'limit': limit});
    final list = (res.data['visits'] as List?) ?? [];
    return list.map((e) => Map<String, dynamic>.from(e)).toList();
  }

  Future<List<Map<String, dynamic>>> getFamilyContacts(int elderId) async {
    final res = await dio.get('$_base/elders/$elderId/family-contacts');
    final list = (res.data['family'] as List?) ?? [];
    return list.map((e) => Map<String, dynamic>.from(e)).toList();
  }

  Future<void> requestVisit(int elderId, Map<String, dynamic> body) async {
    await dio.post('$_base/elders/$elderId/visits/request', data: body);
  }
}
