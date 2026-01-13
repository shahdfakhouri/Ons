import 'dart:convert';
import 'package:http/http.dart' as http;

import 'package:ons_app/core/constants/api_config.dart';
import 'package:ons_app/services/auth_service.dart';

class RetirementHomeApi {
  final http.Client _client;
  RetirementHomeApi({http.Client? client}) : _client = client ?? http.Client();

  Map<String, String> _headers() {
    final token = AuthService().token;
    return {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  Uri _url(String path) => Uri.parse('${ApiConfig.retirementBase}$path');
  Uri _reportsUrl(String path) => Uri.parse('${ApiConfig.retirementReportsBase}$path');

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

  Future<Map<String, dynamic>> post(String path, {Object? body}) async {
    final res = await _client.post(
      _url(path),
      headers: _headers(),
      body: jsonEncode(body ?? {}),
    );
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

  Future<Map<String, dynamic>> patch(String path, {Object? body}) async {
    final res = await _client.patch(
      _url(path),
      headers: _headers(),
      body: jsonEncode(body ?? {}),
    );
    _throwIfBad(res);
    return jsonDecode(res.body) as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> del(String path, {Object? body}) async {
    final res = await _client.delete(
      _url(path),
      headers: _headers(),
      body: jsonEncode(body ?? {}),
    );
    _throwIfBad(res);
    return jsonDecode(res.body) as Map<String, dynamic>;
  }

  // =======================
  // DASHBOARD + PROFILE
  // =======================
  Future<Map<String, dynamic>> getDashboard() => get('/');
  Future<void> updateProfile(Map<String, dynamic> body) async => await put('/update', body: body);

  // =======================
  // EMERGENCIES
  // =======================
  Future<List<Map<String, dynamic>>> getEmergencies() async {
    final j = await get('/emergencies');
    final list = (j['emergencies'] as List?) ?? (j['data'] as List?) ?? [];
    return list.map((e) => Map<String, dynamic>.from(e)).toList();
  }

  Future<void> acceptEmergency(int id) async => await patch('/emergencies/$id/accept');
  Future<void> rejectEmergency(int id) async => await patch('/emergencies/$id/reject');

  // =======================
  // CAREGIVERS
  // =======================
  Future<List<Map<String, dynamic>>> getHomeCaregivers() async {
    final j = await get('/caregivers');
    final list = (j['caregivers'] as List?) ?? [];
    return list.map((e) => Map<String, dynamic>.from(e)).toList();
  }

  Future<List<Map<String, dynamic>>> getAvailableCaregivers() async {
    final j = await get('/caregivers/available');
    final list = (j['caregivers'] as List?) ?? [];
    return list.map((e) => Map<String, dynamic>.from(e)).toList();
  }

  Future<void> addCaregiverToHome(int caregiverId) async =>
      await post('/caregivers/add', body: {'caregiver_id': caregiverId});

  Future<void> removeCaregiverFromHome(int caregiverId) async => await del('/caregivers/$caregiverId');

  // =======================
  // ASSIGNMENTS
  // =======================
  Future<List<Map<String, dynamic>>> getAssignments() async {
    final j = await get('/assignments');
    final list = (j['data'] as List?) ?? [];
    return list.map((e) => Map<String, dynamic>.from(e)).toList();
  }

  Future<void> assignCaregiverToElder({required int elderId, required int caregiverId}) async {
    await post('/assignments/add', body: {'elder_id': elderId, 'caregiver_id': caregiverId});
  }

  Future<void> removeAssignment({required int elderId, required int caregiverId}) async {
    await del('/assignments', body: {'elder_id': elderId, 'caregiver_id': caregiverId});
  }

  // =======================
  // ELDERS MONITORING
  // =======================
  Future<List<Map<String, dynamic>>> getEldersMonitoring() async {
    final j = await get('/elders');
    final list = (j['elders'] as List?) ?? [];
    return list.map((e) => Map<String, dynamic>.from(e)).toList();
  }

  Future<Map<String, dynamic>> getElderDetails(int elderId) async {
    final j = await get('/elders/$elderId');
    return Map<String, dynamic>.from(j['elder'] ?? {});
  }

  Future<List<Map<String, dynamic>>> getElderHealthLogs(int elderId, {int? limit}) async {
    final qp = <String, String>{};
    if (limit != null) qp['limit'] = limit.toString();
    final j = await get('/elders/$elderId/health-logs', queryParams: qp.isEmpty ? null : qp);
    final list = (j['logs'] as List?) ?? [];
    return list.map((e) => Map<String, dynamic>.from(e)).toList();
  }

  Future<List<Map<String, dynamic>>> getElderLocationHistory(int elderId, {int? limit}) async {
    final qp = <String, String>{};
    if (limit != null) qp['limit'] = limit.toString();
    final j = await get('/elders/$elderId/location-history', queryParams: qp.isEmpty ? null : qp);
    final list = (j['history'] as List?) ?? [];
    return list.map((e) => Map<String, dynamic>.from(e)).toList();
  }

  Future<List<Map<String, dynamic>>> getAlerts({String status = 'open', int limit = 100}) async {
    final j = await get('/alerts', queryParams: {'status': status, 'limit': '$limit'});
    final list = (j['alerts'] as List?) ?? [];
    return list.map((e) => Map<String, dynamic>.from(e)).toList();
  }

  // =======================
  // ATTENDANCE
  // =======================
  Future<void> checkInElder(int elderId, {String? notes}) async {
    await patch('/elders/$elderId/check-in', body: {'notes': notes});
  }

  Future<void> checkOutElder(int elderId, {String? notes}) async {
    await patch('/elders/$elderId/check-out', body: {'notes': notes});
  }

  Future<List<Map<String, dynamic>>> getElderAttendance(int elderId, {int? limit}) async {
    final qp = <String, String>{};
    if (limit != null) qp['limit'] = limit.toString();
    final j = await get('/elders/$elderId/attendance', queryParams: qp.isEmpty ? null : qp);
    final list = (j['history'] as List?) ?? [];
    return list.map((e) => Map<String, dynamic>.from(e)).toList();
  }

  // =======================
  // SHIFTS
  // =======================
  Future<void> startShift(int caregiverId, {String? notes}) async {
    await post('/caregivers/$caregiverId/shift/start', body: {'notes': notes});
  }

  Future<void> endShift(int caregiverId, {String? notes}) async {
    await post('/caregivers/$caregiverId/shift/end', body: {'notes': notes});
  }

  Future<List<Map<String, dynamic>>> getActiveShifts() async {
    final j = await get('/shifts/active');
    final list = (j['active'] as List?) ?? [];
    return list.map((e) => Map<String, dynamic>.from(e)).toList();
  }

  Future<List<Map<String, dynamic>>> getCaregiverShiftHistory(int caregiverId, {int? limit}) async {
    final qp = <String, String>{};
    if (limit != null) qp['limit'] = limit.toString();
    final j = await get('/caregivers/$caregiverId/shifts', queryParams: qp.isEmpty ? null : qp);
    final list = (j['shifts'] as List?) ?? [];
    return list.map((e) => Map<String, dynamic>.from(e)).toList();
  }

  // =======================
  // DAILY SUMMARIES
  // =======================
  Future<void> upsertDailySummary(int elderId, Map<String, dynamic> body) async {
    await post('/elders/$elderId/daily-summary', body: body);
  }

  Future<Map<String, dynamic>?> getDailySummary(int elderId, {String? date}) async {
    final qp = <String, String>{};
    if (date != null) qp['date'] = date;
    final j = await get('/elders/$elderId/daily-summary', queryParams: qp.isEmpty ? null : qp);
    final summary = j['summary'];
    if (summary == null) return null;
    return Map<String, dynamic>.from(summary);
  }

  Future<List<Map<String, dynamic>>> getHomeDailySummaries({String? date}) async {
    final qp = <String, String>{};
    if (date != null) qp['date'] = date;
    final j = await get('/daily-summaries', queryParams: qp.isEmpty ? null : qp);
    final list = (j['summaries'] as List?) ?? [];
    return list.map((e) => Map<String, dynamic>.from(e)).toList();
  }

  // =======================
  // PAYMENTS
  // =======================
  Future<List<Map<String, dynamic>>> getPayments({String status = 'all'}) async {
    final j = await get('/payments', queryParams: {'status': status});
    final list = (j['payments'] as List?) ?? [];
    return list.map((e) => Map<String, dynamic>.from(e)).toList();
  }

  Future<Map<String, dynamic>> getPaymentById(int paymentId) async {
    return await get('/payments/$paymentId');
  }

  // =======================
  // TRANSACTIONS
  // =======================
  Future<List<Map<String, dynamic>>> getTransactions({int? limit}) async {
    final qp = <String, String>{};
    if (limit != null) qp['limit'] = limit.toString();
    final j = await get('/transactions', queryParams: qp.isEmpty ? null : qp);
    final list = (j['transactions'] as List?) ?? [];
    return list.map((e) => Map<String, dynamic>.from(e)).toList();
  }

  // =======================
  // INCIDENTS
  // =======================
  Future<void> createIncident(Map<String, dynamic> body) async {
    await post('/incidents', body: body);
  }

  Future<List<Map<String, dynamic>>> getIncidents({String status = 'all'}) async {
    final j = await get('/incidents', queryParams: {'status': status});
    final list = (j['incidents'] as List?) ?? [];
    return list.map((e) => Map<String, dynamic>.from(e)).toList();
  }

  Future<Map<String, dynamic>> getIncidentById(int incidentId) async {
    final j = await get('/incidents/$incidentId');
    return Map<String, dynamic>.from(j['incident'] ?? {});
  }

  Future<void> updateIncidentStatus(int incidentId, String status) async {
    await patch('/incidents/$incidentId/status', body: {'status': status});
  }

  // =======================
  // ✅ REPORTS (NEW)
  // Base: /api/retirement/reports
  // =======================

  Future<Map<String, dynamic>> getWeeklyReport({required String startYYYYMMDD}) async {
    final uri = _reportsUrl('/weekly').replace(queryParameters: {'start': startYYYYMMDD});
    final res = await _client.get(uri, headers: _headers());
    _throwIfBad(res);
    return jsonDecode(res.body) as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> getMonthlyReport({required String monthYYYYMM}) async {
    final uri = _reportsUrl('/monthly').replace(queryParameters: {'month': monthYYYYMM});
    final res = await _client.get(uri, headers: _headers());
    _throwIfBad(res);
    return jsonDecode(res.body) as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> saveReport({
    required String periodType, // weekly | monthly
    required String periodStart, // YYYY-MM-DD
    required String periodEnd, // YYYY-MM-DD
    required Map<String, dynamic> payload, // the "report" object
  }) async {
    final res = await _client.post(
      _reportsUrl('/save'),
      headers: _headers(),
      body: jsonEncode({
        'period_type': periodType,
        'period_start': periodStart,
        'period_end': periodEnd,
        'payload': payload,
      }),
    );
    _throwIfBad(res);
    return jsonDecode(res.body) as Map<String, dynamic>;
  }

  Future<List<Map<String, dynamic>>> getSavedReports() async {
    final res = await _client.get(_reportsUrl('/saved'), headers: _headers());
    _throwIfBad(res);
    final j = jsonDecode(res.body) as Map<String, dynamic>;
    final list = (j['reports'] as List?) ?? [];
    return list.map((e) => Map<String, dynamic>.from(e)).toList();
  }

  // =======================
  // ✅ STAFF NOTES (NEW)
  // Base: /api/retirement/notes
  // =======================

  Uri _notesUrl(String path) => Uri.parse('${ApiConfig.retirementNotesBase}$path');

  Future<List<Map<String, dynamic>>> getHomeNotes() async {
    final res = await _client.get(_notesUrl('/'), headers: _headers());
    _throwIfBad(res);
    final j = jsonDecode(res.body) as Map<String, dynamic>;
    final list = (j['notes'] as List?) ?? [];
    return list.map((e) => Map<String, dynamic>.from(e)).toList();
  }

  Future<List<Map<String, dynamic>>> getElderNotes(int elderId) async {
    final res = await _client.get(_notesUrl('/elders/$elderId'), headers: _headers());
    _throwIfBad(res);
    final j = jsonDecode(res.body) as Map<String, dynamic>;
    final list = (j['notes'] as List?) ?? [];
    return list.map((e) => Map<String, dynamic>.from(e)).toList();
  }

  Future<void> createNote({
    int? elderId,
    int? caregiverId,
    String? title,
    required String note,
  }) async {
    final res = await _client.post(
      _notesUrl('/'),
      headers: _headers(),
      body: jsonEncode({
        'elder_id': elderId,
        'caregiver_id': caregiverId,
        'title': title,
        'note': note,
      }),
    );
    _throwIfBad(res);
  }

  Future<void> updateNote({
    required int noteId,
    String? title,
    String? note,
  }) async {
    final res = await _client.put(
      _notesUrl('/$noteId'),
      headers: _headers(),
      body: jsonEncode({
        'title': title,
        'note': note,
      }),
    );
    _throwIfBad(res);
  }

  Future<void> deleteNote(int noteId) async {
    final res = await _client.delete(_notesUrl('/$noteId'), headers: _headers());
    _throwIfBad(res);
  }




}
