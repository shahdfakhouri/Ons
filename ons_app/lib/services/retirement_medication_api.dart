import 'dart:convert';
import 'package:http/http.dart' as http;

import 'package:ons_app/core/constants/api_config.dart';
import 'package:ons_app/services/auth_service.dart';

class RetirementMedicationApi {
  final http.Client _client;
  RetirementMedicationApi({http.Client? client}) : _client = client ?? http.Client();

  Map<String, String> _headers() {
    final token = AuthService().token;
    return {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      if (token != null && token.isNotEmpty) 'Authorization': 'Bearer $token',
    };
  }

  Uri _url(String path) => Uri.parse('${ApiConfig.medicationBase}$path');

  dynamic _decode(http.Response res) {
    final body = res.body.isNotEmpty ? jsonDecode(res.body) : null;
    if (res.statusCode >= 200 && res.statusCode < 300) return body;

    final msg = (body is Map && body['msg'] != null)
        ? body['msg'].toString()
        : 'HTTP ${res.statusCode}: ${res.body}';
    throw Exception(msg);
  }

  /// POST /api/medication/elders/:elder_id/medications
  Future<int?> createMedicationPlan(int elderId, Map<String, dynamic> body) async {
    final res = await _client.post(
      _url('/elders/$elderId/medications'),
      headers: _headers(),
      body: jsonEncode(body),
    );
    final data = _decode(res);
    if (data is Map && data['medication_id'] != null) {
      return int.tryParse(data['medication_id'].toString());
    }
    return null;
  }

  /// GET /api/medication/elders/:elder_id/medications
  Future<List<Map<String, dynamic>>> getElderMedications(int elderId) async {
    final res = await _client.get(
      _url('/elders/$elderId/medications'),
      headers: _headers(),
    );
    final data = _decode(res);

    final list = (data is Map ? (data['medications'] as List?) : null) ?? const [];
    return list.map((e) => Map<String, dynamic>.from(e)).toList();
  }

  /// GET /api/medication/elders/:elder_id/medication-logs?date=YYYY-MM-DD
  Future<List<Map<String, dynamic>>> getMedicationLogs(int elderId, {String? date}) async {
    var uri = _url('/elders/$elderId/medication-logs');
    if (date != null && date.trim().isNotEmpty) {
      uri = uri.replace(queryParameters: {'date': date.trim()});
    }

    final res = await _client.get(uri, headers: _headers());
    final data = _decode(res);

    final list = (data is Map ? (data['logs'] as List?) : null) ?? const [];
    return list.map((e) => Map<String, dynamic>.from(e)).toList();
  }
}
