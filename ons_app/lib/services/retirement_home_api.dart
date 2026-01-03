import 'package:dio/dio.dart';

class RetirementHomeApi {
  final Dio dio;
  static const String _base = '/api/retirement';

  RetirementHomeApi(this.dio);

  // DASHBOARD
  Future<Map<String, dynamic>> getDashboard() async {
    final res = await dio.get('$_base');
    return Map<String, dynamic>.from(res.data);
  }

  // PROFILE
  Future<void> updateProfile(Map<String, dynamic> body) async {
    await dio.put('$_base/update', data: body);
  }

  // EMERGENCIES
  Future<List<Map<String, dynamic>>> getEmergencies() async {
    final res = await dio.get('$_base/emergencies');
    final list = (res.data['emergencies'] as List?) ?? (res.data as List?) ?? [];
    return list.map((e) => Map<String, dynamic>.from(e)).toList();
  }

  Future<void> acceptEmergency(int emergencyId) async {
    await dio.patch('$_base/emergencies/$emergencyId/accept');
  }

  Future<void> rejectEmergency(int emergencyId) async {
    await dio.patch('$_base/emergencies/$emergencyId/reject');
  }

  // CAREGIVERS
  Future<List<Map<String, dynamic>>> getHomeCaregivers() async {
    final res = await dio.get('$_base/caregivers');
    final list = (res.data['caregivers'] as List?) ?? [];
    return list.map((e) => Map<String, dynamic>.from(e)).toList();
  }

  Future<List<Map<String, dynamic>>> getAvailableCaregivers() async {
    final res = await dio.get('$_base/caregivers/available');
    final list = (res.data['caregivers'] as List?) ?? [];
    return list.map((e) => Map<String, dynamic>.from(e)).toList();
  }

  Future<void> addCaregiverToHome(int caregiverId) async {
    await dio.post('$_base/caregivers/add', data: {'caregiver_id': caregiverId});
  }

  Future<void> removeCaregiverFromHome(int caregiverId) async {
    await dio.delete('$_base/caregivers/$caregiverId');
  }

  // ASSIGNMENTS
  Future<List<Map<String, dynamic>>> getAssignments() async {
    final res = await dio.get('$_base/assignments');
    final list = (res.data['data'] as List?) ?? [];
    return list.map((e) => Map<String, dynamic>.from(e)).toList();
  }

  Future<void> assignCaregiverToElder({required int elderId, required int caregiverId}) async {
    await dio.post('$_base/assignments/add', data: {
      'elder_id': elderId,
      'caregiver_id': caregiverId,
    });
  }

  Future<void> removeAssignment({required int elderId, required int caregiverId}) async {
    await dio.delete('$_base/assignments', data: {
      'elder_id': elderId,
      'caregiver_id': caregiverId,
    });
  }

  // ELDERS
  Future<List<Map<String, dynamic>>> getEldersMonitoring() async {
    final res = await dio.get('$_base/elders');
    final list = (res.data['elders'] as List?) ?? [];
    return list.map((e) => Map<String, dynamic>.from(e)).toList();
  }

  Future<Map<String, dynamic>> getElderDetails(int elderId) async {
    final res = await dio.get('$_base/elders/$elderId');
    return Map<String, dynamic>.from(res.data['elder']);
  }

  Future<List<Map<String, dynamic>>> getElderHealthLogs(int elderId, {int limit = 50}) async {
    final res = await dio.get(
      '$_base/elders/$elderId/health-logs',
      queryParameters: {'limit': limit},
    );
    final list = (res.data['logs'] as List?) ?? [];
    return list.map((e) => Map<String, dynamic>.from(e)).toList();
  }

  Future<List<Map<String, dynamic>>> getElderLocationHistory(int elderId, {int limit = 200}) async {
    final res = await dio.get(
      '$_base/elders/$elderId/location-history',
      queryParameters: {'limit': limit},
    );
    final list = (res.data['history'] as List?) ?? [];
    return list.map((e) => Map<String, dynamic>.from(e)).toList();
  }

  Future<List<Map<String, dynamic>>> getAlerts({String status = 'open', int limit = 100}) async {
    final res = await dio.get('$_base/alerts', queryParameters: {'status': status, 'limit': limit});
    final list = (res.data['alerts'] as List?) ?? [];
    return list.map((e) => Map<String, dynamic>.from(e)).toList();
  }

  // ATTENDANCE
  Future<void> checkInElder(int elderId, {String? notes}) async {
    await dio.patch('$_base/elders/$elderId/check-in', data: {'notes': notes});
  }

  Future<void> checkOutElder(int elderId, {String? notes}) async {
    await dio.patch('$_base/elders/$elderId/check-out', data: {'notes': notes});
  }

  Future<List<Map<String, dynamic>>> getElderAttendance(int elderId, {int limit = 50}) async {
    final res = await dio.get(
      '$_base/elders/$elderId/attendance',
      queryParameters: {'limit': limit},
    );
    final list = (res.data['history'] as List?) ?? [];
    return list.map((e) => Map<String, dynamic>.from(e)).toList();
  }

  // SHIFTS
  Future<void> startShift(int caregiverId, {String? notes}) async {
    await dio.post('$_base/caregivers/$caregiverId/shift/start', data: {'notes': notes});
  }

  Future<void> endShift(int caregiverId, {String? notes}) async {
    await dio.post('$_base/caregivers/$caregiverId/shift/end', data: {'notes': notes});
  }

  Future<List<Map<String, dynamic>>> getActiveShifts() async {
    final res = await dio.get('$_base/shifts/active');
    final list = (res.data['active'] as List?) ?? [];
    return list.map((e) => Map<String, dynamic>.from(e)).toList();
  }

  Future<List<Map<String, dynamic>>> getShiftHistory(int caregiverId, {int limit = 30}) async {
    final res = await dio.get(
      '$_base/caregivers/$caregiverId/shifts',
      queryParameters: {'limit': limit},
    );
    final list = (res.data['shifts'] as List?) ?? [];
    return list.map((e) => Map<String, dynamic>.from(e)).toList();
  }

  // DAILY SUMMARIES
  Future<void> upsertDailySummary(int elderId, Map<String, dynamic> body) async {
    await dio.post('$_base/elders/$elderId/daily-summary', data: body);
  }

  Future<Map<String, dynamic>> getDailySummary(int elderId, {String? date}) async {
    final res = await dio.get('$_base/elders/$elderId/daily-summary', queryParameters: {'date': date});
    return Map<String, dynamic>.from(res.data['summary']);
  }

  Future<List<Map<String, dynamic>>> getHomeDailySummaries({String? date}) async {
    final res = await dio.get('$_base/daily-summaries', queryParameters: {'date': date});
    final list = (res.data['summaries'] as List?) ?? [];
    return list.map((e) => Map<String, dynamic>.from(e)).toList();
  }

  // FINANCE
  Future<List<Map<String, dynamic>>> getPayments({String status = 'all'}) async {
    final res = await dio.get('$_base/payments', queryParameters: {'status': status});
    final list = (res.data['payments'] as List?) ?? [];
    return list.map((e) => Map<String, dynamic>.from(e)).toList();
  }

  Future<Map<String, dynamic>> getPaymentDetails(int paymentId) async {
    final res = await dio.get('$_base/payments/$paymentId');
    return {
      'payment': res.data['payment'],
      'transactions': res.data['transactions'] ?? [],
    };
  }

  Future<List<Map<String, dynamic>>> getTransactions({int limit = 100}) async {
    final res = await dio.get('$_base/transactions', queryParameters: {'limit': limit});
    final list = (res.data['transactions'] as List?) ?? [];
    return list.map((e) => Map<String, dynamic>.from(e)).toList();
  }

  // INCIDENTS
  Future<void> createIncident(Map<String, dynamic> body) async {
    await dio.post('$_base/incidents', data: body);
  }

  Future<List<Map<String, dynamic>>> getIncidents({String status = 'all'}) async {
    final res = await dio.get('$_base/incidents', queryParameters: {'status': status});
    final list = (res.data['incidents'] as List?) ?? [];
    return list.map((e) => Map<String, dynamic>.from(e)).toList();
  }

  Future<Map<String, dynamic>> getIncident(int incidentId) async {
    final res = await dio.get('$_base/incidents/$incidentId');
    return Map<String, dynamic>.from(res.data['incident']);
  }

  Future<void> updateIncidentStatus(int incidentId, String status) async {
    await dio.patch('$_base/incidents/$incidentId/status', data: {'status': status});
  }
}
