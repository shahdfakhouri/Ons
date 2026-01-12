import 'dart:convert';
import 'package:http/http.dart' as http;

import 'package:ons_app/core/constants/api_config.dart';
import 'package:ons_app/services/auth_service.dart';

class FamilyApi {
  final String _base = ApiConfig.familyBase;

  Map<String, String> _headers() {
    final token = AuthService().token;
    final h = <String, String>{
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };
    if (token != null && token.isNotEmpty) {
      h['Authorization'] = 'Bearer $token';
    }
    return h;
  }

  Future<Map<String, dynamic>> _get(String path, {Map<String, String>? query}) async {
    final uri = Uri.parse('$_base$path').replace(queryParameters: query);
    final res = await http.get(uri, headers: _headers());
    return _decode(res);
  }

  Future<Map<String, dynamic>> _post(String path, {Object? body}) async {
    final uri = Uri.parse('$_base$path');
    final res = await http.post(uri, headers: _headers(), body: jsonEncode(body ?? {}));
    return _decode(res);
  }

  Future<Map<String, dynamic>> _put(String path, {Object? body}) async {
    final uri = Uri.parse('$_base$path');
    final res = await http.put(uri, headers: _headers(), body: jsonEncode(body ?? {}));
    return _decode(res);
  }

  Future<Map<String, dynamic>> _delete(String path) async {
    final uri = Uri.parse('$_base$path');
    final res = await http.delete(uri, headers: _headers());
    return _decode(res);
  }

  Map<String, dynamic> _decode(http.Response res) {
    final dynamic decoded = res.body.isNotEmpty ? jsonDecode(res.body) : {};
    if (res.statusCode >= 200 && res.statusCode < 300) {
      return decoded is Map<String, dynamic> ? decoded : {'data': decoded};
    }
    final msg = (decoded is Map && decoded['msg'] != null)
        ? decoded['msg'].toString()
        : 'Request failed (${res.statusCode})';
    throw Exception(msg);
  }

  // ---------------- Dashboard + Profile ----------------
  Future<Map<String, dynamic>> getDashboard() => _get('/');
  Future<Map<String, dynamic>> getMyProfile() => _get('/me');
  Future<Map<String, dynamic>> updateProfile(Map<String, dynamic> body) => _put('/update', body: body);

  // ---------------- Elders ----------------
  Future<Map<String, dynamic>> createElder(Map<String, dynamic> body) => _post('/elders', body: body);
  Future<Map<String, dynamic>> listMyElders() => _get('/elders');
  Future<Map<String, dynamic>> getOneElder(int elderId) => _get('/elders/$elderId');
  Future<Map<String, dynamic>> updateElder(int elderId, Map<String, dynamic> body) => _put('/elders/$elderId', body: body);

  Future<Map<String, dynamic>> resetElderPin(int elderId, String pin) =>
      _put('/elders/$elderId/reset-pin', body: {'pin': pin});
  Future<Map<String, dynamic>> setElderConsent(int elderId, {bool? consent}) =>
      _put('/elders/$elderId/consent', body: consent == null ? {} : {'consent': consent});

  // ---------------- Matching + Assignments ----------------
  Future<Map<String, dynamic>> runMatch() => _post('/match');
  Future<Map<String, dynamic>> getMatches() => _get('/matches');
  Future<Map<String, dynamic>> assignCaregiver({required int elderId, required int caregiverId}) =>
      _post('/assign-caregiver', body: {'elder_id': elderId, 'caregiver_id': caregiverId});
  Future<Map<String, dynamic>> selectHome({required int elderId, required int homeId}) =>
      _post('/select-home', body: {'elder_id': elderId, 'home_id': homeId});
  Future<Map<String, dynamic>> getAssignments() => _get('/assignments');

  // ---------------- Monitoring ----------------
  Future<Map<String, dynamic>> getHealthLogs(int elderId) => _get('/elders/$elderId/health-logs');
  Future<Map<String, dynamic>> getMedications(int elderId) => _get('/elders/$elderId/medications');
  Future<Map<String, dynamic>> getMedicationLogs(int elderId) => _get('/elders/$elderId/medication-logs');
  Future<Map<String, dynamic>> getMedicationStats(int elderId, {String? from, String? to}) =>
      _get('/elders/$elderId/medication-stats', query: {
        if (from != null) 'from': from,
        if (to != null) 'to': to,
      });

  // ---------------- Alerts ----------------
  Future<Map<String, dynamic>> getAlertsAll() => _get('/alerts');
  Future<Map<String, dynamic>> getElderAlerts(int elderId) => _get('/elders/$elderId/alerts');

  // ---------------- Location ----------------
  Future<Map<String, dynamic>> getLatestLocation(int elderId) => _get('/elders/$elderId/location/latest');
  Future<Map<String, dynamic>> getLocationHistory(int elderId) => _get('/elders/$elderId/location/history');
  Future<Map<String, dynamic>> getSafeZones(int elderId) => _get('/elders/$elderId/safe-zones');

  // ---------------- Visits ----------------
  Future<Map<String, dynamic>> requestVisit(int elderId, Map<String, dynamic> body) =>
      _post('/elders/$elderId/visits', body: body);
  Future<Map<String, dynamic>> getMyVisits() => _get('/visits');
  Future<Map<String, dynamic>> getElderVisits(int elderId) => _get('/elders/$elderId/visits');

  // ---------------- Summaries + Comments ----------------
  Future<Map<String, dynamic>> getTodaySummary(int elderId) => _get('/elders/$elderId/daily-summary/today');
  Future<Map<String, dynamic>> getSummariesRange(int elderId, {String? from, String? to}) =>
      _get('/elders/$elderId/daily-summaries', query: {
        if (from != null) 'from': from,
        if (to != null) 'to': to,
      });

  Future<Map<String, dynamic>> addDailySummaryComment(int elderId, int summaryId, String text) =>
      _post('/elders/$elderId/daily-summary/$summaryId/comment', body: {'comment_text': text});

  Future<Map<String, dynamic>> getDailySummaryComments(int elderId, int summaryId) =>
      _get('/elders/$elderId/daily-summary/$summaryId/comments');

  // ---------------- Notes ----------------
  Future<Map<String, dynamic>> addFamilyNote(int elderId, String text) =>
      _post('/elders/$elderId/notes', body: {'note_text': text});
  Future<Map<String, dynamic>> getFamilyNotes(int elderId) => _get('/elders/$elderId/notes');

  // ---------------- Contacts ----------------
  Future<Map<String, dynamic>> getCaregiverContact(int elderId) => _get('/elders/$elderId/caregiver-contact');
  Future<Map<String, dynamic>> getHomeContact(int elderId) => _get('/elders/$elderId/home-contact');

  // ---------------- Calls ----------------
  Future<Map<String, dynamic>> requestCall(Map<String, dynamic> body) => _post('/calls/request', body: body);
  Future<Map<String, dynamic>> getCallHistory({String? elderId, String? from, String? to}) =>
      _get('/calls/history', query: {
        if (elderId != null && elderId.isNotEmpty) 'elder_id': elderId,
        if (from != null && to != null) 'from': from,
        if (to != null && from != null) 'to': to,
      });

  // ---------------- Payments ----------------
  Future<Map<String, dynamic>> getPayments() => _get('/payments');
  Future<Map<String, dynamic>> getTransactions() => _get('/transactions');

  // ---------------- Reviews ----------------
  Future<Map<String, dynamic>> createReview(Map<String, dynamic> body) => _post('/reviews', body: body);
  Future<Map<String, dynamic>> getMyReviews() => _get('/reviews');

  // ---------------- Emergency ----------------
  Future<Map<String, dynamic>> createEmergencyRequest(Map<String, dynamic> body) => _post('/emergency', body: body);
  Future<Map<String, dynamic>> getEmergencyHistory({String? elderId, String? status, String? from, String? to}) =>
      _get('/emergency/history', query: {
        if (elderId != null && elderId.isNotEmpty) 'elder_id': elderId,
        if (status != null && status.isNotEmpty) 'status': status,
        if (from != null && to != null) 'from': from,
        if (to != null && from != null) 'to': to,
      });
  Future<Map<String, dynamic>> cancelEmergencyRequest(int emergencyId) =>
      _put('/emergency/$emergencyId/cancel');

  // ---------------- Events + Calendar feed ----------------
  Future<Map<String, dynamic>> createEvent(Map<String, dynamic> body) => _post('/events', body: body);
  Future<Map<String, dynamic>> getEvents({String? from, String? to, String? elderId}) =>
      _get('/events', query: {
        if (from != null && to != null) 'from': from,
        if (to != null && from != null) 'to': to,
        if (elderId != null && elderId.isNotEmpty) 'elder_id': elderId,
      });
  Future<Map<String, dynamic>> updateEvent(int eventId, Map<String, dynamic> body) => _put('/events/$eventId', body: body);
  Future<Map<String, dynamic>> deleteEvent(int eventId) => _delete('/events/$eventId');

  Future<Map<String, dynamic>> getCalendar({required String from, required String to, String? elderId}) =>
      _get('/calendar', query: {
        'from': from,
        'to': to,
        if (elderId != null && elderId.isNotEmpty) 'elder_id': elderId,
      });

  // ---------------- Gallery (list + delete) ----------------
  // Upload needs multipart + file picker; we keep list/delete for now
  Future<Map<String, dynamic>> getElderGallery(int elderId) => _get('/elders/$elderId/gallery');
  Future<Map<String, dynamic>> deleteGalleryMedia(int mediaId) => _delete('/gallery/$mediaId');
}
