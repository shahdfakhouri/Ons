import 'dart:convert';
import 'package:http/http.dart' as http;

import 'package:ons_app/core/constants/api_config.dart';
import 'package:ons_app/services/auth_service.dart';

class CaregiverApi {
  final http.Client _client;
  CaregiverApi({http.Client? client}) : _client = client ?? http.Client();

  Map<String, String> _headers() {
    final token = AuthService().token;
    return {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  Uri _url(String path) => Uri.parse('${ApiConfig.caregiverBase}$path');

  void _throwIfBad(http.Response res) {
    if (res.statusCode >= 200 && res.statusCode < 300) return;
    throw Exception('HTTP ${res.statusCode}: ${res.body}');
  }

  Future<Map<String, dynamic>> get(String path, {Map<String, String>? queryParams}) async {
    var uri = _url(path);
    if (queryParams != null && queryParams.isNotEmpty) {
      uri = uri.replace(queryParameters: queryParams);
    }
    final res = await _client.get(uri, headers: _headers());
    _throwIfBad(res);
    return jsonDecode(res.body) as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> put(String path, {Object? body}) async {
    final res = await _client.put(
      _url(path),
      headers: _headers(),
      body: jsonEncode(body ?? {}),
    );
    _throwIfBad(res);
    return jsonDecode(res.body) as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> post(String path, {Object? body}) async {
    final res = await _client.post(
      _url(path),
      headers: _headers(),
      body: jsonEncode(body ?? {}),
    );
    _throwIfBad(res);
    return jsonDecode(res.body) as Map<String, dynamic>;
  }

  /// ✅ ADD THIS (fixes: "patch isn't defined")
  Future<Map<String, dynamic>> patch(String path, {Object? body}) async {
    final res = await _client.patch(
      _url(path),
      headers: _headers(),
      body: jsonEncode(body ?? {}),
    );
    _throwIfBad(res);
    return jsonDecode(res.body) as Map<String, dynamic>;
  }

  // =======================
  // ✅ DASHBOARD + PROFILE
  // =======================

  Future<Map<String, dynamic>> getDashboard() async {
    return await get('/dashboard');
  }

  Future<Map<String, dynamic>> getMyProfile() async {
    final j = await get('/me');
    return (j['profile'] as Map<String, dynamic>?) ?? {};
  }

  Future<void> updateProfile(Map<String, dynamic> body) async {
    await put('/me', body: body);
  }

  // =======================
  // ✅ ASSIGNED ELDERS
  // =======================

  Future<List<Map<String, dynamic>>> getAssignedElders() async {
    final j = await get('/elders');
    final list = (j['elders'] as List?) ?? [];
    return list.map((e) => Map<String, dynamic>.from(e)).toList();
  }

  Future<Map<String, dynamic>> getElderDetails(int elderId) async {
    final j = await get('/elders/$elderId');
    return (j['elder'] as Map<String, dynamic>?) ?? {};
  }

  Future<Map<String, dynamic>> getElderStatus(int elderId) async {
    final j = await get('/elders/$elderId/status');
    return (j['status'] as Map<String, dynamic>?) ?? {};
  }

  // =======================
  // ✅ HEALTH LOGS
  // =======================

  Future<Map<String, dynamic>> logElderHealth(int elderId, Map<String, dynamic> body) async {
    return await post('/elders/$elderId/health-log', body: body);
  }

  Future<List<Map<String, dynamic>>> getElderHealthLogs(int elderId, {int? limit}) async {
    final queryParams = <String, String>{};
    if (limit != null) queryParams['limit'] = limit.toString();
    final j = await get('/elders/$elderId/health-logs', queryParams: queryParams.isEmpty ? null : queryParams);
    final list = (j['logs'] as List?) ?? [];
    return list.map((e) => Map<String, dynamic>.from(e)).toList();
  }

  // =======================
  // ✅ MEDICATIONS
  // =======================

  Future<List<Map<String, dynamic>>> getElderMedicationPlan(int elderId) async {
    final j = await get('/elders/$elderId/medications');
    final list = (j['medications'] as List?) ?? [];
    return list.map((e) => Map<String, dynamic>.from(e)).toList();
  }

  Future<List<Map<String, dynamic>>> getTodayMedicationChecklist(int elderId) async {
    final j = await get('/elders/$elderId/medications/today');
    final list = (j['checklist'] as List?) ?? [];
    return list.map((e) => Map<String, dynamic>.from(e)).toList();
  }

  Future<List<Map<String, dynamic>>> getMedicationLogs(int elderId, {String? date}) async {
    final queryParams = <String, String>{};
    if (date != null) queryParams['date'] = date;
    final j = await get('/elders/$elderId/medication-logs', queryParams: queryParams.isEmpty ? null : queryParams);
    final list = (j['logs'] as List?) ?? [];
    return list.map((e) => Map<String, dynamic>.from(e)).toList();
  }

  Future<Map<String, dynamic>> getMedicationStats(int elderId, {int? days}) async {
    final queryParams = <String, String>{};
    if (days != null) queryParams['days'] = days.toString();
    return await get('/elders/$elderId/medications/stats', queryParams: queryParams.isEmpty ? null : queryParams);
  }

  // =======================
  // ✅ DAILY SUMMARY
  // =======================

  Future<void> upsertDailySummary(int elderId, Map<String, dynamic> body) async {
    await post('/elders/$elderId/daily-summary', body: body);
  }

  Future<Map<String, dynamic>?> getDailySummary(int elderId) async {
    final j = await get('/elders/$elderId/daily-summary');
    final summary = j['summary'];
    if (summary == null) return null;
    return Map<String, dynamic>.from(summary);
  }

  // =======================
  // ✅ INCIDENTS
  // =======================

  Future<Map<String, dynamic>> createIncident(int elderId, Map<String, dynamic> body) async {
    return await post('/elders/$elderId/incidents', body: body);
  }

  Future<Map<String, dynamic>> getIncidentById(int incidentId) async {
    final j = await get('/incidents/$incidentId');
    return (j['incident'] as Map<String, dynamic>?) ?? {};
  }

  Future<void> updateIncidentStatus(int incidentId, String status) async {
    await put('/incidents/$incidentId/status', body: {'status': status});
  }

  Future<List<Map<String, dynamic>>> getMyIncidents() async {
    final res = await get('/incidents');
    return List<Map<String, dynamic>>.from(res['incidents'] ?? []);
  }

  Future<List<Map<String, dynamic>>> getElderIncidents(int elderId) async {
    final all = await getMyIncidents();
    return all.where((x) => (x['elder_id'] == elderId)).toList();
  }

  // =======================
  // ✅ CHECK-IN + LOCATION
  // =======================

  Future<void> checkInElder(int elderId) async {
    await post('/elders/$elderId/checkin');
  }

  Future<void> updateElderLocation(int elderId, {required double latitude, required double longitude}) async {
    await post('/elders/$elderId/location', body: {
      'latitude': latitude,
      'longitude': longitude,
    });
  }

  Future<List<Map<String, dynamic>>> getElderLocationHistory(int elderId, {int? limit}) async {
    final queryParams = <String, String>{};
    if (limit != null) queryParams['limit'] = limit.toString();
    final j = await get('/elders/$elderId/location/history', queryParams: queryParams.isEmpty ? null : queryParams);
    final list = (j['history'] as List?) ?? [];
    return list.map((e) => Map<String, dynamic>.from(e)).toList();
  }

  // =======================
  // ✅ SHIFTS
  // =======================

  Future<Map<String, dynamic>> startMyShift({String? notes}) async {
    return await post('/shifts/start', body: notes != null ? {'notes': notes} : null);
  }

  Future<void> endMyShift({String? notes}) async {
    await post('/shifts/end', body: notes != null ? {'notes': notes} : null);
  }

  Future<Map<String, dynamic>?> getMyActiveShift() async {
    final j = await get('/shifts/active');
    final shift = j['active_shift'];
    if (shift == null) return null;
    return Map<String, dynamic>.from(shift);
  }

  Future<List<Map<String, dynamic>>> getMyShiftHistory({int? limit}) async {
    final queryParams = <String, String>{};
    if (limit != null) queryParams['limit'] = limit.toString();
    final j = await get('/shifts/history', queryParams: queryParams.isEmpty ? null : queryParams);
    final list = (j['shifts'] as List?) ?? [];
    return list.map((e) => Map<String, dynamic>.from(e)).toList();
  }

  // =======================
  // ✅ ALERTS
  // =======================

  Future<List<Map<String, dynamic>>> getMyAlerts() async {
    final j = await get('/alerts');
    final list = (j['alerts'] as List?) ?? [];
    return list.map((e) => Map<String, dynamic>.from(e)).toList();
  }

  Future<List<Map<String, dynamic>>> getElderAlerts(int elderId) async {
    final j = await get('/elders/$elderId/alerts');
    final list = (j['alerts'] as List?) ?? [];
    return list.map((e) => Map<String, dynamic>.from(e)).toList();
  }

  // =======================
  // ✅ VISITS + FAMILY CONTACTS
  // =======================

  Future<List<Map<String, dynamic>>> getMyUpcomingVisits({
    int? limit,
    String? from,
    String? to,
    String? status,
  }) async {
    final queryParams = <String, String>{};
    if (limit != null) queryParams['limit'] = limit.toString();
    if (from != null) queryParams['from'] = from;
    if (to != null) queryParams['to'] = to;
    if (status != null && status != 'all') queryParams['status'] = status;
    final j = await get('/visits/upcoming', queryParams: queryParams.isEmpty ? null : queryParams);
    final list = (j['visits'] as List?) ?? [];
    return list.map((e) => Map<String, dynamic>.from(e)).toList();
  }

  Future<List<Map<String, dynamic>>> getElderUpcomingVisits(int elderId, {int? limit, String? status}) async {
    final queryParams = <String, String>{};
    if (limit != null) queryParams['limit'] = limit.toString();
    if (status != null && status != 'all') queryParams['status'] = status;
    final j = await get('/elders/$elderId/visits/upcoming', queryParams: queryParams.isEmpty ? null : queryParams);
    final list = (j['visits'] as List?) ?? [];
    return list.map((e) => Map<String, dynamic>.from(e)).toList();
  }

  Future<List<Map<String, dynamic>>> getElderFamilyContacts(int elderId) async {
    final j = await get('/elders/$elderId/family-contacts');
    final list = (j['family'] as List?) ?? [];
    return list.map((e) => Map<String, dynamic>.from(e)).toList();
  }

  Future<Map<String, dynamic>> requestVisit(int elderId, Map<String, dynamic> body) async {
    return await post('/elders/$elderId/visits/request', body: body);
  }

  // =======================
  // ✅ MED LOG (special base)
  // =======================

  Future<Map<String, dynamic>> logMedicationStatus(
    int elderId, {
    required int medicationId,
    required String status,
    String? scheduledTime,
    String? notes,
  }) async {
    final uri = Uri.parse('${ApiConfig.medicationBase}/elders/$elderId/medication-log');

    final res = await _client.post(
      uri,
      headers: _headers(),
      body: jsonEncode({
        'medication_id': medicationId,
        'status': status,
        if (scheduledTime != null && scheduledTime.trim().isNotEmpty) 'scheduled_time': scheduledTime.trim(),
        if (notes != null && notes.trim().isNotEmpty) 'notes': notes.trim(),
      }),
    );

    _throwIfBad(res);
    return jsonDecode(res.body) as Map<String, dynamic>;
  }

  // =======================
  // ✅ EMERGENCY / SOS (if your backend has these routes)
  // =======================

  Future<List<Map<String, dynamic>>> getElderEmergencyRequests(int elderId) async {
    final res = await get('/elders/$elderId/emergency-requests');
    final list = (res['emergencies'] as List?) ?? [];
    return list.map((e) => Map<String, dynamic>.from(e)).toList();
  }

  Future<void> updateEmergencyStatus(int emergencyId, String status) async {
    await patch('/emergency-requests/$emergencyId/status', body: {'status': status});
  }
}
