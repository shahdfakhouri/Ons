import 'dart:convert';
import 'package:http/http.dart' as http;

import 'package:ons_app/core/constants/api_config.dart';
import 'package:ons_app/services/elder_auth_service.dart';

class ElderApi {
  final _auth = ElderAuthService();

  Map<String, String> _headersJson() {
    final h = {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };
    final token = _auth.token;
    if (token != null && token.isNotEmpty) h['Authorization'] = 'Bearer $token';
    return h;
  }

  Map<String, String> _headersNoContentType() {
    final h = {'Accept': 'application/json'};
    final token = _auth.token;
    if (token != null && token.isNotEmpty) h['Authorization'] = 'Bearer $token';
    return h;
  }

  Map<String, dynamic> _decodeObj(http.Response res) {
    final dynamic body = res.body.isNotEmpty ? jsonDecode(res.body) : {};
    if (res.statusCode >= 200 && res.statusCode < 300) {
      return body is Map<String, dynamic> ? body : {'data': body};
    }
    final msg = (body is Map && body['msg'] != null) ? body['msg'].toString() : 'Request failed (${res.statusCode})';
    throw Exception(msg);
  }

  List<dynamic> _decodeList(http.Response res) {
    final dynamic body = res.body.isNotEmpty ? jsonDecode(res.body) : [];
    if (res.statusCode >= 200 && res.statusCode < 300) {
      if (body is List) return body;
      if (body is Map && body['data'] is List) return (body['data'] as List);
      return [];
    }
    final msg = (body is Map && body['msg'] != null) ? body['msg'].toString() : 'Request failed (${res.statusCode})';
    throw Exception(msg);
  }

  // AUTH
  Future<Map<String, dynamic>> changePin(String newPin) async {
    final url = Uri.parse('${ApiConfig.elderBase}/auth/pin');
    final res = await http.patch(url, headers: _headersJson(), body: jsonEncode({'newPin': newPin}));
    return _decodeObj(res);
  }

  // PROFILE
  Future<Map<String, dynamic>> getMe() async {
    final url = Uri.parse('${ApiConfig.elderBase}/me');
    final res = await http.get(url, headers: _headersJson());
    return _decodeObj(res);
  }

  Future<Map<String, dynamic>> updateMe({double? fontSize, String? language, bool? voiceMode}) async {
    final url = Uri.parse('${ApiConfig.elderBase}/me');
    final res = await http.patch(
      url,
      headers: _headersJson(),
      body: jsonEncode({'font_size': fontSize, 'language': language, 'voice_mode': voiceMode}),
    );
    return _decodeObj(res);
  }

  // CONSENT
  Future<Map<String, dynamic>> getConsent() async {
    final url = Uri.parse('${ApiConfig.elderBase}/consent');
    final res = await http.get(url, headers: _headersJson());
    return _decodeObj(res);
  }

  Future<Map<String, dynamic>> updateConsent(Map<String, dynamic> body) async {
    final url = Uri.parse('${ApiConfig.elderBase}/consent');
    final res = await http.patch(url, headers: _headersJson(), body: jsonEncode(body));
    return _decodeObj(res);
  }

  // MOOD
  Future<Map<String, dynamic>> addMood({required int moodLevel, String? notes}) async {
    final url = Uri.parse('${ApiConfig.elderBase}/mood');
    final res = await http.post(url, headers: _headersJson(), body: jsonEncode({'mood_level': moodLevel, 'notes': notes}));
    return _decodeObj(res);
  }

  Future<List<dynamic>> moodHistory() async {
    final url = Uri.parse('${ApiConfig.elderBase}/mood');
    final res = await http.get(url, headers: _headersJson());
    return _decodeList(res);
  }

  // SYMPTOMS
  Future<Map<String, dynamic>> addSymptom({required String symptom, String? severity, String? notes}) async {
    final url = Uri.parse('${ApiConfig.elderBase}/symptoms');
    final res = await http.post(
      url,
      headers: _headersJson(),
      body: jsonEncode({'symptom': symptom, 'severity': severity, 'notes': notes}),
    );
    return _decodeObj(res);
  }

  Future<List<dynamic>> symptomsHistory() async {
    final url = Uri.parse('${ApiConfig.elderBase}/symptoms');
    final res = await http.get(url, headers: _headersJson());
    return _decodeList(res);
  }

  // CALLS
  Future<Map<String, dynamic>> requestCall({required int targetUserId, required String targetRole}) async {
    final url = Uri.parse('${ApiConfig.elderBase}/calls/request');
    final res = await http.post(url, headers: _headersJson(), body: jsonEncode({'target_user_id': targetUserId, 'target_role': targetRole}));
    return _decodeObj(res);
  }

  Future<List<dynamic>> callHistory() async {
    final url = Uri.parse('${ApiConfig.elderBase}/calls');
    final res = await http.get(url, headers: _headersJson());
    return _decodeList(res);
  }

  Future<Map<String, dynamic>> acceptCall(int callId) async {
    final url = Uri.parse('${ApiConfig.elderBase}/calls/$callId/accept');
    final res = await http.patch(url, headers: _headersJson());
    return _decodeObj(res);
  }

  Future<Map<String, dynamic>> declineCall(int callId) async {
    final url = Uri.parse('${ApiConfig.elderBase}/calls/$callId/decline');
    final res = await http.patch(url, headers: _headersJson());
    return _decodeObj(res);
  }

  Future<Map<String, dynamic>> contacts() async {
    final url = Uri.parse('${ApiConfig.elderBase}/contacts');
    final res = await http.get(url, headers: _headersJson());
    return _decodeObj(res);
  }

  // GALLERY
  Future<List<dynamic>> gallery() async {
    final url = Uri.parse('${ApiConfig.elderBase}/gallery');
    final res = await http.get(url, headers: _headersJson());
    return _decodeList(res);
  }

  Future<Map<String, dynamic>> deleteMedia(int mediaId) async {
    final url = Uri.parse('${ApiConfig.elderBase}/gallery/$mediaId');
    final res = await http.delete(url, headers: _headersJson());
    return _decodeObj(res);
  }

  Future<Map<String, dynamic>> uploadMedia({required List<int> bytes, required String filename, String? caption}) async {
    final url = Uri.parse('${ApiConfig.elderBase}/gallery/upload');
    final req = http.MultipartRequest('POST', url);
    req.headers.addAll(_headersNoContentType());
    req.files.add(http.MultipartFile.fromBytes('file', bytes, filename: filename));
    if (caption != null && caption.isNotEmpty) req.fields['caption'] = caption;

    final streamed = await req.send();
    final res = await http.Response.fromStream(streamed);
    return _decodeObj(res);
  }

  // CONTENT
  Future<List<dynamic>> contentFeed() async {
    final url = Uri.parse('${ApiConfig.elderBase}/content/feed');
    final res = await http.get(url, headers: _headersJson());
    return _decodeList(res);
  }

  // EMERGENCY
  Future<Map<String, dynamic>> panic() async {
    final url = Uri.parse('${ApiConfig.elderBase}/panic');
    final res = await http.post(url, headers: _headersJson());
    return _decodeObj(res);
  }

  Future<List<dynamic>> myEmergencies() async {
    final url = Uri.parse('${ApiConfig.elderBase}/emergencies');
    final res = await http.get(url, headers: _headersJson());
    return _decodeList(res);
  }

  Future<Map<String, dynamic>> cancelEmergency(int emergencyId) async {
    final url = Uri.parse('${ApiConfig.elderBase}/emergencies/$emergencyId/cancel');
    final res = await http.patch(url, headers: _headersJson());
    return _decodeObj(res);
  }

  // MEDICATION
  Future<List<dynamic>> medsToday() async {
    final url = Uri.parse('${ApiConfig.elderBase}/medication/today');
    final res = await http.get(url, headers: _headersJson());
    return _decodeList(res);
  }

  Future<List<dynamic>> medsHistory() async {
    final url = Uri.parse('${ApiConfig.elderBase}/medication/history');
    final res = await http.get(url, headers: _headersJson());
    return _decodeList(res);
  }

  /// Controller fields vary by your backend.
  /// We send {medication_id, schedule_id, log_id} if they exist.
  Future<Map<String, dynamic>> confirmMedTaken(Map<String, dynamic> body) async {
    final url = Uri.parse('${ApiConfig.elderBase}/medication/confirm');
    final res = await http.post(url, headers: _headersJson(), body: jsonEncode(body));
    return _decodeObj(res);
  }

  // LOCATION
  Future<Map<String, dynamic>> locationCurrent() async {
    final url = Uri.parse('${ApiConfig.elderBase}/location/current');
    final res = await http.get(url, headers: _headersJson());
    return _decodeObj(res);
  }

  Future<List<dynamic>> safeZones() async {
    final url = Uri.parse('${ApiConfig.elderBase}/safe-zones');
    final res = await http.get(url, headers: _headersJson());
    return _decodeList(res);
  }

  Future<Map<String, dynamic>> requestHelp() async {
    final url = Uri.parse('${ApiConfig.elderBase}/location/request-help');
    final res = await http.post(url, headers: _headersJson());
    return _decodeObj(res);
  }

  // NOTIFICATIONS (elder inbox from /api/notifications)
  Future<List<dynamic>> elderNotifications() async {
    final url = Uri.parse('${ApiConfig.notificationsBase}/');
    final res = await http.get(url, headers: _headersJson());
    return _decodeList(res);
  }

  Future<Map<String, dynamic>> markElderNotificationRead(int notificationId) async {
    final url = Uri.parse('${ApiConfig.notificationsBase}/$notificationId/read');
    final res = await http.patch(url, headers: _headersJson());
    return _decodeObj(res);
  }
}
