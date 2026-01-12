import 'dart:convert';
import 'package:http/http.dart' as http;

import 'package:ons_app/core/constants/api_config.dart';
import 'package:ons_app/services/auth_service.dart';

import 'dart:typed_data';



class AdminApi {
  final http.Client _client;
  AdminApi({http.Client? client}) : _client = client ?? http.Client();

  Map<String, String> _headers() {
    final token = AuthService().token;
    return {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  Uri _url(String path) => Uri.parse('${ApiConfig.adminBase}$path');

  void _throwIfBad(http.Response res) {
    if (res.statusCode >= 200 && res.statusCode < 300) return;
    throw Exception('HTTP ${res.statusCode}: ${res.body}');
  }

  Future<Map<String, dynamic>> get(String path) async {
    final res = await _client.get(_url(path), headers: _headers());
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

  // =======================
  // ✅ ENDPOINTS (your routes)
  // =======================

  Future<Map<String, dynamic>> overviewFull() async {
    final j = await get('/dashboard/overview-full');
    return (j['overview'] as Map<String, dynamic>?) ?? {};
  }

  Future<List> getApprovals() async {
    final j = await get('/approvals');
    return (j['pending'] as List?) ?? [];
  }

  Future<void> approveUser(String role, String id) async {
    await put('/approve/$role/$id');
  }

  Future<void> rejectUser(String role, String id) async {
    await put('/reject/$role/$id');
  }

  Future<List> getHealthSummary() async {
    final j = await get('/health-summary');
    return (j['summaries'] as List?) ?? [];
  }

  Future<List> getMatches(String familyId) async {
    final j = await get('/matches/$familyId');
    return (j['matches'] as List?) ?? [];
  }

  Future<void> approveMatch(String matchId) async {
    await post('/matches/$matchId/approve');
  }

  Future<void> rejectMatch(String matchId) async {
    await post('/matches/$matchId/reject');
  }

  // finance
  Future<Map<String, dynamic>> getFinanceOverview({String? from, String? to}) async {
    final j = await get('/dashboard/overview${_qs({"from": from, "to": to})}');
    return (j['overview'] as Map<String, dynamic>?) ?? {};
  }

  Future<List> getRevenueByRole({String? from, String? to}) async {
    final j = await get('/dashboard/revenue-by-role${_qs({"from": from, "to": to})}');
    return (j['results'] as List?) ?? [];
  }

  Future<List> getPaymentStats({String? from, String? to}) async {
    final j = await get('/dashboard/payments${_qs({"from": from, "to": to})}');
    return (j['results'] as List?) ?? [];
  }

  // reports
  Future<List> getReports({String? caregiverId, String? from, String? to}) async {
    final j = await get('/reports${_qs({"caregiver_id": caregiverId, "from": from, "to": to})}');
    return (j['reports'] as List?) ?? [];
  }

  Future<void> analyzeReport(String reportId) async {
    await post('/reports/analyze/$reportId');
  }


Future<Uint8List> getBytes(String path) async {
  final res = await _client.get(_url(path), headers: _headers());
  _throwIfBad(res);
  return res.bodyBytes;
}

// Weekly reports export (CSV from backend)
Future<Uint8List> exportWeeklyReportsCsv() async {
  return getBytes('/reports/export');
}



  // gps
  Future<List> getGpsOverview() async {
    final j = await get('/gps/overview');
    return (j['data'] as List?) ?? [];
  }

  Future<List> getGpsHistory(String elderId) async {
    final j = await get('/gps/history/$elderId');
    return (j['history'] as List?) ?? [];
  }

  // analytics
  Future<List> healthAlertsTimeline() async {
    final j = await get('/analytics/health-alerts');
    return (j['data'] as List?) ?? [];
  }

  Future<List> revenueTimeline() async {
    final j = await get('/analytics/revenue');
    return (j['data'] as List?) ?? [];
  }

  Future<List> usersTimeline() async {
    final j = await get('/analytics/users');
    return (j['data'] as List?) ?? [];
  }

  String _qs(Map<String, String?> m) {
    final entries = m.entries.where((e) => (e.value ?? '').isNotEmpty).toList();
    if (entries.isEmpty) return '';
    final q = entries.map((e) => '${e.key}=${Uri.encodeComponent(e.value!)}').join('&');
    return '?$q';
  }




Future<List> getActiveUsers() async {
  final j = await get('/active-users');
  return (j['users'] as List?) ?? [];
}

Future<void> updateUserStatus({
  required String role,
  required String id,
  required String newStatus,
}) async {
  await put('/user/$role/$id', body: {
    'new_status': newStatus,
  });
}


Future<List> getElderAssignments() async {
  final j = await get('/assignments');
  return (j['data'] as List?) ?? [];
}



Future<Map<String, dynamic>> getAdminAnalytics() async {
  final j = await get('/analytics');
  return Map<String, dynamic>.from((j['analytics'] as Map?) ?? {});
}

Future<List> getHealthAlertsTimeline() async {
  final j = await get('/analytics/health-alerts');
  return (j['data'] as List?) ?? [];
}

Future<List> getRevenueTimeline() async {
  final j = await get('/analytics/revenue');
  return (j['data'] as List?) ?? [];
}

Future<List> getUserGrowthTimeline() async {
  final j = await get('/analytics/users');
  return (j['data'] as List?) ?? [];
}






}
