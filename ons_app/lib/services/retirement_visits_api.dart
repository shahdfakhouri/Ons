import 'dart:convert';
import 'package:http/http.dart' as http;

import 'package:ons_app/core/constants/api_config.dart';
import 'package:ons_app/services/auth_service.dart';

class RetirementVisitsApi {
  final http.Client _client;
  RetirementVisitsApi({http.Client? client}) : _client = client ?? http.Client();

  Map<String, String> _headers() {
    final token = AuthService().token;
    return {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  Uri _url(String path) => Uri.parse('${ApiConfig.retirementBase}$path');

  void _throwIfBad(http.Response res) {
    if (res.statusCode >= 200 && res.statusCode < 300) return;
    throw Exception('HTTP ${res.statusCode}: ${res.body}');
  }

  Future<Map<String, dynamic>> _get(String path, {Map<String, String>? query}) async {
    var uri = _url(path);
    if (query != null && query.isNotEmpty) {
      uri = uri.replace(queryParameters: query);
    }
    final res = await _client.get(uri, headers: _headers());
    _throwIfBad(res);
    return jsonDecode(res.body) as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> _post(String path, {Object? body}) async {
    final res = await _client.post(
      _url(path),
      headers: _headers(),
      body: jsonEncode(body ?? {}),
    );
    _throwIfBad(res);
    return jsonDecode(res.body) as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> _put(String path, {Object? body}) async {
    final res = await _client.put(
      _url(path),
      headers: _headers(),
      body: jsonEncode(body ?? {}),
    );
    _throwIfBad(res);
    return jsonDecode(res.body) as Map<String, dynamic>;
  }

  // =======================
  // 1) GET /elders/:elder_id/family
  // =======================
  Future<List<Map<String, dynamic>>> getElderFamily(int elderId) async {
    final j = await _get('/elders/$elderId/family');
    final list = (j['family'] as List?) ?? [];
    return list.map((e) => Map<String, dynamic>.from(e)).toList();
  }

  // =======================
  // 2) POST /elders/:elder_id/visits
  // =======================
  Future<int> createVisit({
    required int elderId,
    int? familyId,
    required String scheduledAt, // 'YYYY-MM-DD HH:MM:SS'
    int durationMinutes = 60,
    String? notes,
  }) async {
    final j = await _post('/elders/$elderId/visits', body: {
      'family_id': familyId,
      'scheduled_at': scheduledAt,
      'duration_minutes': durationMinutes,
      'notes': notes,
    });

    final id = j['visit_id'];
    return (id is int) ? id : int.parse(id.toString());
  }

  // =======================
  // 3) GET /elders/:elder_id/visits
  // =======================
  Future<List<Map<String, dynamic>>> getElderVisits(int elderId) async {
    final j = await _get('/elders/$elderId/visits');
    final list = (j['visits'] as List?) ?? [];
    return list.map((e) => Map<String, dynamic>.from(e)).toList();
  }

  // =======================
  // 4) GET /visits?from=&to=&status=
  // =======================
  Future<List<Map<String, dynamic>>> getHomeVisits({
    String from = '2000-01-01',
    String to = '2100-01-01',
    String status = 'all',
  }) async {
    final j = await _get('/visits', query: {
      'from': from,
      'to': to,
      'status': status,
    });
    final list = (j['visits'] as List?) ?? [];
    return list.map((e) => Map<String, dynamic>.from(e)).toList();
  }

  // =======================
  // 5) PUT /visits/:visit_id/status
  // =======================
  Future<void> updateVisitStatus({
    required int visitId,
    required String status, // pending|approved|cancelled|completed
  }) async {
    await _put('/visits/$visitId/status', body: {'status': status});
  }
}
